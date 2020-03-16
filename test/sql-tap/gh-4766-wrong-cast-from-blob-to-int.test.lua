#!/usr/bin/env tarantool
test = require("sqltester")
test:plan(6)

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

test:finish_test()
