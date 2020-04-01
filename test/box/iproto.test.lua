net_box = require('net.box')
urilib = require('uri')
msgpack = require('msgpack')
test_run = require('test_run').new()

IPROTO_REQUEST_TYPE   = 0x00

IPROTO_SYNC           = 0x01
IPROTO_CALL           = 0x0A
IPROTO_FUNCTION_NAME  = 0x22
IPROTO_TUPLE          = 0x21
IPROTO_ERROR          = 0x31
IPROTO_ERROR_STACK    = 0x52
IPROTO_ERROR_CODE     = 0x01
IPROTO_ERROR_MESSAGE  = 0x02

-- gh-1148: test capabilities of stacked diagnostics bypassing net.box.
--
test_run:cmd("setopt delimiter ';'")
stack_err = function()
    local e1 = box.error.new({code = 111, reason = "e1"})
    local e2 = box.error.new({code = 111, reason = "e2"})
    local e3 = box.error.new({code = 111, reason = "e3"})
    assert(e1 ~= nil)
    e2:set_prev(e1)
    assert(e2.prev == e1)
    e3:set_prev(e2)
    box.error(e3)
end;
test_run:cmd("setopt delimiter ''");
box.schema.user.grant('guest', 'read, write, execute', 'universe')

next_request_id = 16
header = { \
    [IPROTO_REQUEST_TYPE] = IPROTO_CALL, \
    [IPROTO_SYNC]         = next_request_id, \
}

body = { \
    [IPROTO_FUNCTION_NAME] = 'stack_err', \
    [IPROTO_TUPLE]    = box.tuple.new({nil}) \
}

uri = urilib.parse(box.cfg.listen)
sock = net_box.establish_connection(uri.host, uri.service)

response = iproto_request(sock, header, body)
sock:close()

-- Both keys (obsolete and stack ones) are present in response.
--
assert(response.body[IPROTO_ERROR_STACK] ~= nil)
assert(response.body[IPROTO_ERROR] ~= nil)

err = response.body[IPROTO_ERROR_STACK][1]
assert(err[IPROTO_ERROR_MESSAGE] == response.body[IPROTO_ERROR])
assert(err[IPROTO_ERROR_MESSAGE] == 'e3')
assert(err[IPROTO_ERROR_CODE] == 111)
err = response.body[IPROTO_ERROR_STACK][2]
assert(err[IPROTO_ERROR_MESSAGE] == 'e2')
assert(err[IPROTO_ERROR_CODE] == 111)
err = response.body[IPROTO_ERROR_STACK][3]
assert(err[IPROTO_ERROR_MESSAGE] == 'e1')
assert(err[IPROTO_ERROR_CODE] == 111)

box.schema.user.revoke('guest', 'read,write,execute', 'universe')
