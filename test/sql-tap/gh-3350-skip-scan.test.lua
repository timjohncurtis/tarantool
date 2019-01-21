#!/usr/bin/env tarantool

-- gh-3350, gh-2859

test = require("sqltester")
test:plan(3)

local function lindex(str, pos)
    return str:sub(pos+1, pos+1)
end

local function int_to_char(i)
    local res = ''
    local char = 'abcdefghij'
    local divs = {1000, 100, 10, 1}
    for _, div in ipairs(divs) do
        res = res .. lindex(char, math.floor(i/div) % 10)
    end
    return res
end

box.internal.sql_create_function("lindex", "TEXT", lindex)
box.internal.sql_create_function("int_to_char", "TEXT", int_to_char)

test:do_execsql_test(
        "skip-scan-1.1",
        [[
            DROP TABLE IF EXISTS t1;
            CREATE TABLE t1(a TEXT COLLATE "unicode_ci", b TEXT, c TEXT,
                d TEXT, e INT, f INT, PRIMARY KEY(c, b, a));
            WITH data(a, b, c, d, e, f) AS
            (SELECT int_to_char(0), 'xyz', 'zyx', '*', 0, 0 UNION ALL
            SELECT int_to_char(f+1), b, c, d, (e+1) % 2, f+1 FROM data WHERE f<1024)
            INSERT INTO t1 SELECT a, b, c, d, e, f FROM data;
            ANALYZE;
            SELECT COUNT(*) FROM t1 WHERE a < 'aaad';
            DROP TABLE t1;
        ]], {
            3
        })

test:do_execsql_test(
        "skip-scan-1.2",
        [[
            DROP TABLE IF EXISTS t2;
            CREATE TABLE t2(a TEXT COLLATE "unicode_ci", b TEXT, c TEXT,
                d TEXT, e INT, f INT, PRIMARY KEY(e, f));
            WITH data(a, b, c, d, e, f) AS
            (SELECT int_to_char(0), 'xyz', 'zyx', '*', 0, 0 UNION ALL
            SELECT int_to_char(f+1), b, c, d, (e+1) % 2, f+1 FROM data WHERE f<1024)
            INSERT INTO t2 SELECT a, b, c, d, e, f FROM data;
            ANALYZE;
            SELECT COUNT(*) FROM t2 WHERE f < 500;
            DROP TABLE t2;
        ]], {
            500
        }
)

test:do_execsql_test(
        "skip-scan-1.3",
        [[
            DROP TABLE IF EXISTS t3;
            CREATE TABLE t3(a TEXT COLLATE "unicode_ci", b TEXT, c TEXT,
                d TEXT, e INT, f INT, PRIMARY KEY(a));
            CREATE INDEX i31 ON t3(e, f);
            WITH data(a, b, c, d, e, f) AS
            (SELECT int_to_char(0), 'xyz', 'zyx', '*', 0, 0 UNION ALL
            SELECT int_to_char(f+1), b, c, d, (e+1) % 2, f+1 FROM data WHERE f<1024)
            INSERT INTO t3 SELECT a, b, c, d, e, f FROM data;
            ANALYZE;
            SELECT COUNT(*) FROM t3 WHERE f < 500;
            DROP INDEX i31 on t3;
            DROP TABLE t3;
        ]], {
            500
        }
)


test:finish_test()
