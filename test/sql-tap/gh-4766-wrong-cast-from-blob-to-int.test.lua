#!/usr/bin/env tarantool
test = require("sqltester")
test:plan(15)

--
-- Make sure that STRING or BLOB that contains DOUBLE value cannot
-- be cast to INTEGER.
--
test:do_catchsql_test(
    "gh-4766-1",
    [[
        SELECT CAST('1.1' AS INTEGER)
    ]], {
        1, "Type mismatch: can not convert 1.1 to integer"
    })

test:do_catchsql_test(
    "gh-4766-2",
    [[
        SELECT CAST(x'312e31' AS INTEGER)
    ]], {
        1, "Type mismatch: can not convert varbinary to integer"
    })

test:do_catchsql_test(
    "gh-4766-3",
    [[
        SELECT CAST('2.0' AS INTEGER)
    ]], {
        1, "Type mismatch: can not convert 2.0 to integer"
    })

test:do_catchsql_test(
    "gh-4766-4",
    [[
        SELECT CAST(x'322e30' AS INTEGER)
    ]], {
        1, "Type mismatch: can not convert varbinary to integer"
    })

test:do_catchsql_test(
    "gh-4766-5",
    [[
        SELECT CAST('2.' AS INTEGER)
    ]], {
        1, "Type mismatch: can not convert 2. to integer"
    })

test:do_catchsql_test(
    "gh-4766-6",
    [[
        SELECT CAST(x'322e' AS INTEGER)
    ]], {
        1, "Type mismatch: can not convert varbinary to integer"
    })

--
-- Make sure that STRING or BLOB that contains DOUBLE value cannot
-- be implicitly cast to INTEGER.
--
test:do_catchsql_test(
    "gh-4766-7",
    [[
        CREATE TABLE t(i INT PRIMARY KEY);
        INSERT INTO t VALUES ('1.1');
    ]], {
        1, "Type mismatch: can not convert 1.1 to integer"
    })

test:do_catchsql_test(
    "gh-4766-8",
    [[
        INSERT INTO t VALUES (x'312e31');
    ]], {
        1, "Type mismatch: can not convert varbinary to integer"
    })

test:do_catchsql_test(
    "gh-4766-9",
    [[
        INSERT INTO t VALUES ('2.0');
    ]], {
        1, "Type mismatch: can not convert 2.0 to integer"
    })

test:do_catchsql_test(
    "gh-4766-10",
    [[
        INSERT INTO t VALUES (x'322e30');
    ]], {
        1, "Type mismatch: can not convert varbinary to integer"
    })

test:do_catchsql_test(
    "gh-4766-11",
    [[
        INSERT INTO t VALUES ('2.');
    ]], {
        1, "Type mismatch: can not convert 2. to integer"
    })

test:do_catchsql_test(
    "gh-4766-12",
    [[
        INSERT INTO t VALUES (x'322e');
    ]], {
        1, "Type mismatch: can not convert varbinary to integer"
    })

--
-- Make sure that a blob as part of a tuple can be cast to NUMBER,
-- INTEGER and UNSIGNED. Prior to this patch, an error could
-- appear due to the absence of '\0' at the end of the BLOB.
--
test:do_execsql_test(
    "gh-4766-13",
    [[
        CREATE TABLE t1 (a VARBINARY PRIMARY KEY);
        INSERT INTO t1 VALUES (X'33'), (X'372020202020');
        SELECT a, CAST(a AS NUMBER), CAST(a AS INTEGER), CAST(a AS UNSIGNED) FROM t1;
    ]], {
        '3', 3, 3, 3, '7     ', 7, 7, 7
    })

--
-- Make sure that BLOB longer than 12287 bytes cannot be cast to
-- INTEGER.
--
long_str = string.rep('0', 12284)
test:do_execsql_test(
    "gh-4766-14",
    "SELECT CAST('" .. long_str .. "123'" .. " AS INTEGER);", {
        123
    })


test:do_catchsql_test(
    "gh-4766-15",
    "SELECT CAST('" .. long_str .. "1234'" .. " AS INTEGER);", {
        1, "Type mismatch: can not convert 000000000000000000000000000000000" ..
        "0000000000000000000000000000000000000000000000000000000000000000000" ..
        "0000000000000000000000000000000000000000000000000000000000000000000" ..
        "0000000000000000000000000000000000000000000000000000000000000000000" ..
        "0000000000000000000000000000000000000000000000000000000000000000000" ..
        "0000000000000000000000000000000000000000000000000000000000000000000" ..
        "0000000000000000000000000000000000000000000000000000000000000000000" ..
        "000000000000000000000000000000000000000000000"
    })

test:finish_test()
