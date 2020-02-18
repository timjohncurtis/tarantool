# Tarantool box.error evolution

* **Status**: In progress
* **Start date**: 13-01-2020
* **Authors**: Leonid Vasilyev @LeonidVas lvasiliev@tarantool.org
* **Issues**: [#4398](https://github.com/tarantool/tarantool/issues/4398)

## Summary

The document describes the extension of the ability to work with box.error errors.
This is needed because the current features of the box.errors module don't meet the needs of consumers, as a result of which some workarounds has been created, like https://github.com/tarantool/errors

According to https://github.com/tarantool/tarantool/issues/4398 box.error module should be expanded by:
1) Adding the ability to create a new errors type from the application
2) Adding lua stack trace and payload to all types of errors
3) Changing the transmission format through net.box

## Background and motivation

Currently errors of the box.error module can't have a customized type, don't provide detailed information about the cause of occurence and have two different kinds of representation after transmission through net.box.
As result: consumers create a workaround for work with application errors, like https://github.com/tarantool/errors

We have three extension points:
1) Problem: create a new error type from an application
	Decision: add new type of error with a custom subtype
2) Problem: small verbosity of the error cause
	Decision: add lua stack trace and payload to all types of errors
3) Problem: after transferring through net.box (with using IPROTO_OK) the error becomes a string
	Decision: change net.box transmission format for errors

## Detailed design

### Create an error with custom type

Add the CustomError class, derived from the ClientError class, with the custom_type field (string) which is something like an error subtype.
Now consumers can create an error with a custom type (subtype) and check this type in the application.

### Add verbosity to an error

Add the ability to add a payload to the error and add lua stack trace to the error when it is creating or throwing (into luaT_pusherror). After transfering through net.box, stack trace will be squashed with the new one (with stack trace on the side of the caller).

### Change the transmission format

The error can be transmited through net.box by two ways:
1) With using IPROTO_ERROR (if an error has been thrown on remote) - the error is an object (cdata) on the caller side
2) With using IPROTO_OK (if an error has been transmitted as an object) - the error is string (error message) on the caller side

The purpose of changing the transmission format is to add details (like payload, backtrace and custom type) to an error representation, in case of IPROTO_ERROR transmission, and transmit an error as object (cdata), not a string, in case of IPROTO_OK transmission.

The new IPROTO_ERROR representation (using an array(MP_ARRAY) is useful for the stacked diagnostics task):
```
0      5
+------++================+================++===================+
|      ||                |                ||                   |
| BODY ||   0x00: 0x8XXX |   0x01: SYNC   ||   0x31: ERROR     |
|HEADER|| MP_INT: MP_INT | MP_INT: MP_INT || MP_INT: MP_ARRAY  |
| SIZE ||                |                ||                   |
+------++================+================++===================+
 MP_INT                MP_MAP                      MP_MAP
```
Every error is a map with keys like ERROR_MSG, ERROR_BT ...

When transmit as an object (case IPROTO_OK):
Using the new msgpack type, after parsing on the client - cdata (with the corresponding struct error)

For backward compatibility, a negotiation phase has been added to IPROTO.
A new key (IPROTO_NEGOTIATION) has been added to IPROTO command codes.

NEGOTIATION BODY: CODE = 0x0E
```
+==========================+
|                          |
|  NEGOTIATION PARAMETERS  |
|                          |
+==========================+
           MP_MAP
```
Session negotiation parameters are a map with keys like ERROR_FORMAT_VERSION ...
The response is a map with all stated negotiation parameters.
So, for work with the new format of errors, it is necessary to perform the negotiation phase, otherwise errors will be transmitted in the old format (by default).

## Rationale and alternatives

Creating a new error using the old error as a cause may be used as an alternative
of stack trace squashing.

As an alternative to adding of negotiation phase to IPROTO may be used something like:
case IPROTO_ERROR
	look at the trick that is used in the stacked diagnostics task (https://github.com/tarantool/tarantool/blob/np/gh-1148-stacked-diag/doc/rfc/1148-stacked-diagnostics.md)

case IPROTO_OK
	transmit a table with some special field and create an error from it

But for the IPROTO_OK case, it looks like an unsafe crutch without the possibility switching between old/new formats.
