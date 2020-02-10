-- Make sure that comparison between numeric types works.
SELECT 2 > 1, 1.5 > 1, 2.5 > 1.5;
SELECT 2 < 1, 1.5 < 1, 2.5 < 1.5;
SELECT 2 >= 1, 1.5 >= 1, 2.5 >= 1.5;
SELECT 2 <= 1, 1.5 <= 1, 2.5 <= 1.5;
SELECT 2 = 1, 1.5 = 1, 2.5 = 1.5;
SELECT 2 != 1, 1.5 != 1, 2.5 != 1.5;

CREATE TABLE tn(i INT PRIMARY KEY, a NUMBER, d DOUBLE, u UNSIGNED);
INSERT INTO tn VALUES (1, 2, 3.3, 4);
INSERT INTO tn VALUES (2, 3.5, 3, 4);
SELECT i > 1, i > 1.5, a > 1, a > 1.5, d > 1, d > 1.5, u > 1, u > 1.5 FROM tn;
SELECT i < 1, i < 1.5, a < 1, a < 1.5, d < 1, d < 1.5, u < 1, u < 1.5 FROM tn;
SELECT i >= 1, i >= 1.5, a >= 1, a >= 1.5, d >= 1, d >= 1.5, u >= 1, u >= 1.5 FROM tn;
SELECT i <= 1, i <= 1.5, a <= 1, a <= 1.5, d <= 1, d <= 1.5, u <= 1, u <= 1.5 FROM tn;
SELECT i = 1, i = 1.5, a = 1, a = 1.5, d = 1, d = 1.5, u = 1, u = 1.5 FROM tn;
SELECT i != 1, i != 1.5, a != 1, a != 1.5, d != 1, d != 1.5, u != 1, u != 1.5 FROM tn;

SELECT 1 > i, 1.5 > i, 1 > a, 1.5 > a, 1 > d, 1.5 > d, 1 > u, 1.5 > u FROM tn;
SELECT 1 < i, 1.5 < i, 1 < a, 1.5 < a, 1 < d, 1.5 < d, 1 < u, 1.5 < u FROM tn;
SELECT 1 >= i, 1.5 >= i, 1 >= a, 1.5 >= a, 1 >= d, 1.5 >= d, 1 >= u, 1.5 >= u FROM tn;
SELECT 1 <= i, 1.5 <= i, 1 <= a, 1.5 <= a, 1 <= d, 1.5 <= d, 1 <= u, 1.5 <= u FROM tn;
SELECT 1 = i, 1.5 = i, 1 = a, 1.5 = a, 1 = d, 1.5 = d, 1 = u, 1.5 = u FROM tn;
SELECT 1 != i, 1.5 != i, 1 != a, 1.5 != a, 1 != d, 1.5 != d, 1 != u, 1.5 != u FROM tn;

SELECT i > i, i > a, i > d, i > u, a > a, a > d, a > u, d > d, d > u, u > u FROM tn;
SELECT i < i, i < a, i < d, i < u, a < a, a < d, a < u, d < d, d < u, u < u FROM tn;
SELECT i >= i, i >= a, i >= d, i >= u, a >= a, a >= d, a >= u, d >= d, d >= u, u >= u FROM tn;
SELECT i <= i, i <= a, i <= d, i <= u, a <= a, a <= d, a <= u, d <= d, d <= u, u <= u FROM tn;
SELECT i = i, i = a, i = d, i = u, a = a, a = d, a = u, d = d, d = u, u = u FROM tn;
SELECT i != i, i != a, i != d, i != u, a != a, a != d, a != u, d != d, d != u, u != u FROM tn;

-- Make sure that comparison between BOOLEAN values works.
SELECT true > false;
SELECT true < false;
SELECT true >= false;
SELECT true <= false;
SELECT true = false;
SELECT true != false;

CREATE TABLE tb(b1 BOOLEAN PRIMARY KEY, b2 BOOLEAN);
INSERT INTO tb VALUES (true, false);
SELECT b1 > true FROM tb;
SELECT b1 < true FROM tb;
SELECT b1 >= true FROM tb;
SELECT b1 <= true FROM tb;
SELECT b1 = true FROM tb;
SELECT b1 != true FROM tb;

SELECT true > b1 FROM tb;
SELECT true < b1 FROM tb;
SELECT true >= b1 FROM tb;
SELECT true <= b1 FROM tb;
SELECT true = b1 FROM tb;
SELECT true != b1 FROM tb;

SELECT b1 > b2 FROM tb;
SELECT b1 < b2 FROM tb;
SELECT b1 >= b2 FROM tb;
SELECT b1 <= b2 FROM tb;
SELECT b1 = b2 FROM tb;
SELECT b1 != b2 FROM tb;

-- Make sure that comparison between STRING values works.
SELECT '123' > '456';
SELECT '123' < '456';
SELECT '123' >= '456';
SELECT '123' <= '456';
SELECT '123' = '456';
SELECT '123' != '456';

CREATE TABLE ts(s1 STRING PRIMARY KEY, s2 STRING);
INSERT INTO ts VALUES ('12', '32');
SELECT s1 > '123' FROM ts;
SELECT s1 < '123' FROM ts;
SELECT s1 >= '123' FROM ts;
SELECT s1 <= '123' FROM ts;
SELECT s1 = '123' FROM ts;
SELECT s1 != '123' FROM ts;

SELECT '123' > s1 FROM ts;
SELECT '123' < s1 FROM ts;
SELECT '123' >= s1 FROM ts;
SELECT '123' <= s1 FROM ts;
SELECT '123' = s1 FROM ts;
SELECT '123' != s1 FROM ts;

SELECT s1 > s2 FROM ts;
SELECT s1 < s2 FROM ts;
SELECT s1 >= s2 FROM ts;
SELECT s1 <= s2 FROM ts;
SELECT s1 = s2 FROM ts;
SELECT s1 != s2 FROM ts;

-- Make sure that comparison between VARBINARY values works.
SELECT X'3139' > X'3537';
SELECT X'3139' < X'3537';
SELECT X'3139' >= X'3537';
SELECT X'3139' <= X'3537';
SELECT X'3139' = X'3537';
SELECT X'3139' != X'3537';

CREATE TABLE tv(v1 VARBINARY PRIMARY KEY, v2 VARBINARY);
INSERT INTO tv VALUES (X'3333', X'3432');
SELECT v1 > X'3139' FROM tv;
SELECT v1 < X'3139' FROM tv;
SELECT v1 >= X'3139' FROM tv;
SELECT v1 <= X'3139' FROM tv;
SELECT v1 = X'3139' FROM tv;
SELECT v1 != X'3139' FROM tv;

SELECT X'3139' > v1 FROM tv;
SELECT X'3139' < v1 FROM tv;
SELECT X'3139' >= v1 FROM tv;
SELECT X'3139' <= v1 FROM tv;
SELECT X'3139' = v1 FROM tv;
SELECT X'3139' != v1 FROM tv;

SELECT v1 > v2 FROM tv;
SELECT v1 < v2 FROM tv;
SELECT v1 >= v2 FROM tv;
SELECT v1 <= v2 FROM tv;
SELECT v1 = v2 FROM tv;
SELECT v1 != v2 FROM tv;

-- Make sure, that comparison with NULL returns NULL.
SELECT NULL > NULL, NULL > 1, NULL > 1.5, NULL > true, NULL > '123', NULL > X'3139';
SELECT NULL < NULL, NULL < 1, NULL < 1.5, NULL < true, NULL < '123', NULL < X'3139';
SELECT NULL >= NULL, NULL >= 1, NULL >= 1.5, NULL >= true, NULL >= '123', NULL >= X'3139';
SELECT NULL <= NULL, NULL <= 1, NULL <= 1.5, NULL <= true, NULL <= '123', NULL <= X'3139';
SELECT NULL = NULL, NULL = 1, NULL = 1.5, NULL = true, NULL = '123', NULL = X'3139';
SELECT NULL != NULL, NULL != 1, NULL != 1.5, NULL != true, NULL != '123', NULL != X'3139';

SELECT 1 > NULL, 1.5 > NULL, true > NULL, '123' > NULL, X'3139' > NULL;
SELECT 1 < NULL, 1.5 < NULL, true < NULL, '123' < NULL, X'3139' < NULL;
SELECT 1 >= NULL, 1.5 >= NULL, true >= NULL, '123' >= NULL, X'3139' >= NULL;
SELECT 1 <= NULL, 1.5 <= NULL, true <= NULL, '123' <= NULL, X'3139' <= NULL;
SELECT 1 = NULL, 1.5 = NULL, true = NULL, '123' = NULL, X'3139' = NULL;
SELECT 1 != NULL, 1.5 != NULL, true != NULL, '123' != NULL, X'3139' != NULL;

SELECT NULL > i, NULL > a, NULL > d, NULL > u, NULL > b1, NULL > s1, NULL > v1 FROM tn, tb, ts, tv;
SELECT NULL < i, NULL < a, NULL < d, NULL < u, NULL < b1, NULL < s1, NULL < v1 FROM tn, tb, ts, tv;
SELECT NULL >= i, NULL >= a, NULL >= d, NULL >= u, NULL >= b1, NULL >= s1, NULL >= v1 FROM tn, tb, ts, tv;
SELECT NULL <= i, NULL <= a, NULL <= d, NULL <= u, NULL <= b1, NULL <= s1, NULL <= v1 FROM tn, tb, ts, tv;
SELECT NULL = i, NULL = a, NULL = d, NULL = u, NULL = b1, NULL = s1, NULL = v1 FROM tn, tb, ts, tv;
SELECT NULL != i, NULL != a, NULL != d, NULL != u, NULL != b1, NULL != s1, NULL != v1 FROM tn, tb, ts, tv;

CREATE TABLE t0(pk INT PRIMARY KEY, i0 INT, a0 NUMBER, d0 DOUBLE, u0 UNSIGNED, b0 BOOLEAN, s0 STRING, v0 VARBINARY, sc0 SCALAR);
INSERT INTO t0 VALUES (1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT i0 > i, i0 > a, i0 > d, i0 > u, i0 > b1, i0 > s1, i0 > v1 FROM t0, tn, tb, ts, tv;
SELECT i0 < i, i0 < a, i0 < d, i0 < u, i0 < b1, i0 < s1, i0 < v1 FROM t0, tn, tb, ts, tv;
SELECT i0 >= i, i0 >= a, i0 >= d, i0 >= u, i0 >= b1, i0 >= s1, i0 >= v1 FROM t0, tn, tb, ts, tv;
SELECT i0 <= i, i0 <= a, i0 <= d, i0 <= u, i0 <= b1, i0 <= s1, i0 <= v1 FROM t0, tn, tb, ts, tv;
SELECT i0 = i, i0 = a, i0 = d, i0 = u, i0 = b1, i0 = s1, i0 = v1 FROM t0, tn, tb, ts, tv;
SELECT i0 != i, i0 != a, i0 != d, i0 != u, i0 != b1, i0 != s1, i0 != v1 FROM t0, tn, tb, ts, tv;

SELECT i > i0, a > i0, d > i0, u > i0, b1 > i0, s1 > i0, v1 > i0 FROM t0, tn, tb, ts, tv;
SELECT i < i0, a < i0, d < i0, u < i0, b1 < i0, s1 < i0, v1 < i0 FROM t0, tn, tb, ts, tv;
SELECT i >= i0, a >= i0, d >= i0, u >= i0, b1 >= i0, s1 >= i0, v1 >= i0 FROM t0, tn, tb, ts, tv;
SELECT i <= i0, a <= i0, d <= i0, u <= i0, b1 <= i0, s1 <= i0, v1 <= i0 FROM t0, tn, tb, ts, tv;
SELECT i = i0, a = i0, d = i0, u = i0, b1 = i0, s1 = i0, v1 = i0 FROM t0, tn, tb, ts, tv;
SELECT i != i0, a != i0, d != i0, u != i0, b1 != i0, s1 != i0, v1 != i0 FROM t0, tn, tb, ts, tv;

SELECT a0 > i, a0 > a, a0 > d, a0 > u, a0 > b1, a0 > s1, a0 > v1 FROM t0, tn, tb, ts, tv;
SELECT a0 < i, a0 < a, a0 < d, a0 < u, a0 < b1, a0 < s1, a0 < v1 FROM t0, tn, tb, ts, tv;
SELECT a0 >= i, a0 >= a, a0 >= d, a0 >= u, a0 >= b1, a0 >= s1, a0 >= v1 FROM t0, tn, tb, ts, tv;
SELECT a0 <= i, a0 <= a, a0 <= d, a0 <= u, a0 <= b1, a0 <= s1, a0 <= v1 FROM t0, tn, tb, ts, tv;
SELECT a0 = i, a0 = a, a0 = d, a0 = u, a0 = b1, a0 = s1, a0 = v1 FROM t0, tn, tb, ts, tv;
SELECT a0 != i, a0 != a, a0 != d, a0 != u, a0 != b1, a0 != s1, a0 != v1 FROM t0, tn, tb, ts, tv;

SELECT i > a0, a > a0, d > a0, u > a0, b1 > a0, s1 > a0, v1 > a0 FROM t0, tn, tb, ts, tv;
SELECT i < a0, a < a0, d < a0, u < a0, b1 < a0, s1 < a0, v1 < a0 FROM t0, tn, tb, ts, tv;
SELECT i >= a0, a >= a0, d >= a0, u >= a0, b1 >= a0, s1 >= a0, v1 >= a0 FROM t0, tn, tb, ts, tv;
SELECT i <= a0, a <= a0, d <= a0, u <= a0, b1 <= a0, s1 <= a0, v1 <= a0 FROM t0, tn, tb, ts, tv;
SELECT i = a0, a = a0, d = a0, u = a0, b1 = a0, s1 = a0, v1 = a0 FROM t0, tn, tb, ts, tv;
SELECT i != a0, a != a0, d != a0, u != a0, b1 != a0, s1 != a0, v1 != a0 FROM t0, tn, tb, ts, tv;

SELECT d0 > i, d0 > a, d0 > d, d0 > u, d0 > b1, d0 > s1, d0 > v1 FROM t0, tn, tb, ts, tv;
SELECT d0 < i, d0 < a, d0 < d, d0 < u, d0 < b1, d0 < s1, d0 < v1 FROM t0, tn, tb, ts, tv;
SELECT d0 >= i, d0 >= a, d0 >= d, d0 >= u, d0 >= b1, d0 >= s1, d0 >= v1 FROM t0, tn, tb, ts, tv;
SELECT d0 <= i, d0 <= a, d0 <= d, d0 <= u, d0 <= b1, d0 <= s1, d0 <= v1 FROM t0, tn, tb, ts, tv;
SELECT d0 = i, d0 = a, d0 = d, d0 = u, d0 = b1, d0 = s1, d0 = v1 FROM t0, tn, tb, ts, tv;
SELECT d0 != i, d0 != a, d0 != d, d0 != u, d0 != b1, d0 != s1, d0 != v1 FROM t0, tn, tb, ts, tv;

SELECT i > d0, a > d0, d > d0, u > d0, b1 > d0, s1 > d0, v1 > d0 FROM t0, tn, tb, ts, tv;
SELECT i < d0, a < d0, d < d0, u < d0, b1 < d0, s1 < d0, v1 < d0 FROM t0, tn, tb, ts, tv;
SELECT i >= d0, a >= d0, d >= d0, u >= d0, b1 >= d0, s1 >= d0, v1 >= d0 FROM t0, tn, tb, ts, tv;
SELECT i <= d0, a <= d0, d <= d0, u <= d0, b1 <= d0, s1 <= d0, v1 <= d0 FROM t0, tn, tb, ts, tv;
SELECT i = d0, a = d0, d = d0, u = d0, b1 = d0, s1 = d0, v1 = d0 FROM t0, tn, tb, ts, tv;
SELECT i != d0, a != d0, d != d0, u != d0, b1 != d0, s1 != d0, v1 != d0 FROM t0, tn, tb, ts, tv;

SELECT u0 > i, u0 > a, u0 > d, u0 > u, u0 > b1, u0 > s1, u0 > v1 FROM t0, tn, tb, ts, tv;
SELECT u0 < i, u0 < a, u0 < d, u0 < u, u0 < b1, u0 < s1, u0 < v1 FROM t0, tn, tb, ts, tv;
SELECT u0 >= i, u0 >= a, u0 >= d, u0 >= u, u0 >= b1, u0 >= s1, u0 >= v1 FROM t0, tn, tb, ts, tv;
SELECT u0 <= i, u0 <= a, u0 <= d, u0 <= u, u0 <= b1, u0 <= s1, u0 <= v1 FROM t0, tn, tb, ts, tv;
SELECT u0 = i, u0 = a, u0 = d, u0 = u, u0 = b1, u0 = s1, u0 = v1 FROM t0, tn, tb, ts, tv;
SELECT u0 != i, u0 != a, u0 != d, u0 != u, u0 != b1, u0 != s1, u0 != v1 FROM t0, tn, tb, ts, tv;

SELECT i > u0, a > u0, d > u0, u > u0, b1 > u0, s1 > u0, v1 > u0 FROM t0, tn, tb, ts, tv;
SELECT i < u0, a < u0, d < u0, u < u0, b1 < u0, s1 < u0, v1 < u0 FROM t0, tn, tb, ts, tv;
SELECT i >= u0, a >= u0, d >= u0, u >= u0, b1 >= u0, s1 >= u0, v1 >= u0 FROM t0, tn, tb, ts, tv;
SELECT i <= u0, a <= u0, d <= u0, u <= u0, b1 <= u0, s1 <= u0, v1 <= u0 FROM t0, tn, tb, ts, tv;
SELECT i = u0, a = u0, d = u0, u = u0, b1 = u0, s1 = u0, v1 = u0 FROM t0, tn, tb, ts, tv;
SELECT i != u0, a != u0, d != u0, u != u0, b1 != u0, s1 != u0, v1 != u0 FROM t0, tn, tb, ts, tv;

SELECT b0 > i, b0 > a, b0 > d, b0 > u, b0 > b1, b0 > s1, b0 > v1 FROM t0, tn, tb, ts, tv;
SELECT b0 < i, b0 < a, b0 < d, b0 < u, b0 < b1, b0 < s1, b0 < v1 FROM t0, tn, tb, ts, tv;
SELECT b0 >= i, b0 >= a, b0 >= d, b0 >= u, b0 >= b1, b0 >= s1, b0 >= v1 FROM t0, tn, tb, ts, tv;
SELECT b0 <= i, b0 <= a, b0 <= d, b0 <= u, b0 <= b1, b0 <= s1, b0 <= v1 FROM t0, tn, tb, ts, tv;
SELECT b0 = i, b0 = a, b0 = d, b0 = u, b0 = b1, b0 = s1, b0 = v1 FROM t0, tn, tb, ts, tv;
SELECT b0 != i, b0 != a, b0 != d, b0 != u, b0 != b1, b0 != s1, b0 != v1 FROM t0, tn, tb, ts, tv;

SELECT i > b0, a > b0, d > b0, u > b0, b1 > b0, s1 > b0, v1 > b0 FROM t0, tn, tb, ts, tv;
SELECT i < b0, a < b0, d < b0, u < b0, b1 < b0, s1 < b0, v1 < b0 FROM t0, tn, tb, ts, tv;
SELECT i >= b0, a >= b0, d >= b0, u >= b0, b1 >= b0, s1 >= b0, v1 >= b0 FROM t0, tn, tb, ts, tv;
SELECT i <= b0, a <= b0, d <= b0, u <= b0, b1 <= b0, s1 <= b0, v1 <= b0 FROM t0, tn, tb, ts, tv;
SELECT i = b0, a = b0, d = b0, u = b0, b1 = b0, s1 = b0, v1 = b0 FROM t0, tn, tb, ts, tv;
SELECT i != b0, a != b0, d != b0, u != b0, b1 != b0, s1 != b0, v1 != b0 FROM t0, tn, tb, ts, tv;

SELECT s0 > i, s0 > a, s0 > d, s0 > u, s0 > b1, s0 > s1, s0 > v1 FROM t0, tn, tb, ts, tv;
SELECT s0 < i, s0 < a, s0 < d, s0 < u, s0 < b1, s0 < s1, s0 < v1 FROM t0, tn, tb, ts, tv;
SELECT s0 >= i, s0 >= a, s0 >= d, s0 >= u, s0 >= b1, s0 >= s1, s0 >= v1 FROM t0, tn, tb, ts, tv;
SELECT s0 <= i, s0 <= a, s0 <= d, s0 <= u, s0 <= b1, s0 <= s1, s0 <= v1 FROM t0, tn, tb, ts, tv;
SELECT s0 = i, s0 = a, s0 = d, s0 = u, s0 = b1, s0 = s1, s0 = v1 FROM t0, tn, tb, ts, tv;
SELECT s0 != i, s0 != a, s0 != d, s0 != u, s0 != b1, s0 != s1, s0 != v1 FROM t0, tn, tb, ts, tv;

SELECT i > s0, a > s0, d > s0, u > s0, b1 > s0, s1 > s0, v1 > s0 FROM t0, tn, tb, ts, tv;
SELECT i < s0, a < s0, d < s0, u < s0, b1 < s0, s1 < s0, v1 < s0 FROM t0, tn, tb, ts, tv;
SELECT i >= s0, a >= s0, d >= s0, u >= s0, b1 >= s0, s1 >= s0, v1 >= s0 FROM t0, tn, tb, ts, tv;
SELECT i <= s0, a <= s0, d <= s0, u <= s0, b1 <= s0, s1 <= s0, v1 <= s0 FROM t0, tn, tb, ts, tv;
SELECT i = s0, a = s0, d = s0, u = s0, b1 = s0, s1 = s0, v1 = s0 FROM t0, tn, tb, ts, tv;
SELECT i != s0, a != s0, d != s0, u != s0, b1 != s0, s1 != s0, v1 != s0 FROM t0, tn, tb, ts, tv;

SELECT v0 > i, v0 > a, v0 > d, v0 > u, v0 > b1, v0 > s1, v0 > v1 FROM t0, tn, tb, ts, tv;
SELECT v0 < i, v0 < a, v0 < d, v0 < u, v0 < b1, v0 < s1, v0 < v1 FROM t0, tn, tb, ts, tv;
SELECT v0 >= i, v0 >= a, v0 >= d, v0 >= u, v0 >= b1, v0 >= s1, v0 >= v1 FROM t0, tn, tb, ts, tv;
SELECT v0 <= i, v0 <= a, v0 <= d, v0 <= u, v0 <= b1, v0 <= s1, v0 <= v1 FROM t0, tn, tb, ts, tv;
SELECT v0 = i, v0 = a, v0 = d, v0 = u, v0 = b1, v0 = s1, v0 = v1 FROM t0, tn, tb, ts, tv;
SELECT v0 != i, v0 != a, v0 != d, v0 != u, v0 != b1, v0 != s1, v0 != v1 FROM t0, tn, tb, ts, tv;

SELECT i > v0, a > v0, d > v0, u > v0, b1 > v0, s1 > v0, v1 > v0 FROM t0, tn, tb, ts, tv;
SELECT i < v0, a < v0, d < v0, u < v0, b1 < v0, s1 < v0, v1 < v0 FROM t0, tn, tb, ts, tv;
SELECT i >= v0, a >= v0, d >= v0, u >= v0, b1 >= v0, s1 >= v0, v1 >= v0 FROM t0, tn, tb, ts, tv;
SELECT i <= v0, a <= v0, d <= v0, u <= v0, b1 <= v0, s1 <= v0, v1 <= v0 FROM t0, tn, tb, ts, tv;
SELECT i = v0, a = v0, d = v0, u = v0, b1 = v0, s1 = v0, v1 = v0 FROM t0, tn, tb, ts, tv;
SELECT i != v0, a != v0, d != v0, u != v0, b1 != v0, s1 != v0, v1 != v0 FROM t0, tn, tb, ts, tv;

SELECT sc0 > i, sc0 > a, sc0 > d, sc0 > u, sc0 > b1, sc0 > s1, sc0 > v1 FROM t0, tn, tb, ts, tv;
SELECT sc0 < i, sc0 < a, sc0 < d, sc0 < u, sc0 < b1, sc0 < s1, sc0 < v1 FROM t0, tn, tb, ts, tv;
SELECT sc0 >= i, sc0 >= a, sc0 >= d, sc0 >= u, sc0 >= b1, sc0 >= s1, sc0 >= v1 FROM t0, tn, tb, ts, tv;
SELECT sc0 <= i, sc0 <= a, sc0 <= d, sc0 <= u, sc0 <= b1, sc0 <= s1, sc0 <= v1 FROM t0, tn, tb, ts, tv;
SELECT sc0 = i, sc0 = a, sc0 = d, sc0 = u, sc0 = b1, sc0 = s1, sc0 = v1 FROM t0, tn, tb, ts, tv;
SELECT sc0 != i, sc0 != a, sc0 != d, sc0 != u, sc0 != b1, sc0 != s1, sc0 != v1 FROM t0, tn, tb, ts, tv;

SELECT i > sc0, a > sc0, d > sc0, u > sc0, b1 > sc0, s1 > sc0, v1 > sc0 FROM t0, tn, tb, ts, tv;
SELECT i < sc0, a < sc0, d < sc0, u < sc0, b1 < sc0, s1 < sc0, v1 < sc0 FROM t0, tn, tb, ts, tv;
SELECT i >= sc0, a >= sc0, d >= sc0, u >= sc0, b1 >= sc0, s1 >= sc0, v1 >= sc0 FROM t0, tn, tb, ts, tv;
SELECT i <= sc0, a <= sc0, d <= sc0, u <= sc0, b1 <= sc0, s1 <= sc0, v1 <= sc0 FROM t0, tn, tb, ts, tv;
SELECT i = sc0, a = sc0, d = sc0, u = sc0, b1 = sc0, s1 = sc0, v1 = sc0 FROM t0, tn, tb, ts, tv;
SELECT i != sc0, a != sc0, d != sc0, u != sc0, b1 != sc0, s1 != sc0, v1 != sc0 FROM t0, tn, tb, ts, tv;

-- Make sure that numbers cannot be compared with BOOLEAN values.
SELECT 3 > true;
SELECT 3 < true;
SELECT 3 >= true;
SELECT 3 <= true;
SELECT 3 = true;
SELECT 3 != true;

SELECT true > 4;
SELECT true < 4;
SELECT true >= 4;
SELECT true <= 4;
SELECT true = 4;
SELECT true != 4;

SELECT 3.5 > true;
SELECT 3.5 < true;
SELECT 3.5 >= true;
SELECT 3.5 <= true;
SELECT 3.5 = true;
SELECT 3.5 != true;

SELECT true > 0.5;
SELECT true < 0.5;
SELECT true >= 0.5;
SELECT true <= 0.5;
SELECT true = 0.5;
SELECT true != 0.5;

SELECT i > true FROM tn;
SELECT i < true FROM tn;
SELECT i >= true FROM tn;
SELECT i <= true FROM tn;
SELECT i = true FROM tn;
SELECT i != true FROM tn;

SELECT true > i FROM tn;
SELECT true < i FROM tn;
SELECT true >= i FROM tn;
SELECT true <= i FROM tn;
SELECT true = i FROM tn;
SELECT true != i FROM tn;

SELECT a > true FROM tn;
SELECT a < true FROM tn;
SELECT a >= true FROM tn;
SELECT a <= true FROM tn;
SELECT a = true FROM tn;
SELECT a != true FROM tn;

SELECT true > a FROM tn;
SELECT true < a FROM tn;
SELECT true >= a FROM tn;
SELECT true <= a FROM tn;
SELECT true = a FROM tn;
SELECT true != a FROM tn;

SELECT d > true FROM tn;
SELECT d < true FROM tn;
SELECT d >= true FROM tn;
SELECT d <= true FROM tn;
SELECT d = true FROM tn;
SELECT d != true FROM tn;

SELECT true > d FROM tn;
SELECT true < d FROM tn;
SELECT true >= d FROM tn;
SELECT true <= d FROM tn;
SELECT true = d FROM tn;
SELECT true != d FROM tn;

SELECT u > true FROM tn;
SELECT u < true FROM tn;
SELECT u >= true FROM tn;
SELECT u <= true FROM tn;
SELECT u = true FROM tn;
SELECT u != true FROM tn;

SELECT true > u FROM tn;
SELECT true < u FROM tn;
SELECT true >= u FROM tn;
SELECT true <= u FROM tn;
SELECT true = u FROM tn;
SELECT true != u FROM tn;

SELECT 3 > b1 FROM tb;
SELECT 3 < b1 FROM tb;
SELECT 3 >= b1 FROM tb;
SELECT 3 <= b1 FROM tb;
SELECT 3 = b1 FROM tb;
SELECT 3 != b1 FROM tb;

SELECT b1 > 4 FROM tb;
SELECT b1 < 4 FROM tb;
SELECT b1 >= 4 FROM tb;
SELECT b1 <= 4 FROM tb;
SELECT b1 = 4 FROM tb;
SELECT b1 != 4 FROM tb;

SELECT 3.5 > b1 FROM tb;
SELECT 3.5 < b1 FROM tb;
SELECT 3.5 >= b1 FROM tb;
SELECT 3.5 <= b1 FROM tb;
SELECT 3.5 = b1 FROM tb;
SELECT 3.5 != b1 FROM tb;

SELECT b1 > 0.5 FROM tb;
SELECT b1 < 0.5 FROM tb;
SELECT b1 >= 0.5 FROM tb;
SELECT b1 <= 0.5 FROM tb;
SELECT b1 = 0.5 FROM tb;
SELECT b1 != 0.5 FROM tb;

SELECT i > b1 FROM tn, tb;
SELECT i < b1 FROM tn, tb;
SELECT i >= b1 FROM tn, tb;
SELECT i <= b1 FROM tn, tb;
SELECT i = b1 FROM tn, tb;
SELECT i != b1 FROM tn, tb;

SELECT b1 > i FROM tn, tb;
SELECT b1 < i FROM tn, tb;
SELECT b1 >= i FROM tn, tb;
SELECT b1 <= i FROM tn, tb;
SELECT b1 = i FROM tn, tb;
SELECT b1 != i FROM tn, tb;

SELECT a > b1 FROM tn, tb;
SELECT a < b1 FROM tn, tb;
SELECT a >= b1 FROM tn, tb;
SELECT a <= b1 FROM tn, tb;
SELECT a = b1 FROM tn, tb;
SELECT a != b1 FROM tn, tb;

SELECT b1 > a FROM tn, tb;
SELECT b1 < a FROM tn, tb;
SELECT b1 >= a FROM tn, tb;
SELECT b1 <= a FROM tn, tb;
SELECT b1 = a FROM tn, tb;
SELECT b1 != a FROM tn, tb;

SELECT d > b1 FROM tn, tb;
SELECT d < b1 FROM tn, tb;
SELECT d >= b1 FROM tn, tb;
SELECT d <= b1 FROM tn, tb;
SELECT d = b1 FROM tn, tb;
SELECT d != b1 FROM tn, tb;

SELECT b1 > d FROM tn, tb;
SELECT b1 < d FROM tn, tb;
SELECT b1 >= d FROM tn, tb;
SELECT b1 <= d FROM tn, tb;
SELECT b1 = d FROM tn, tb;
SELECT b1 != d FROM tn, tb;

SELECT u > b1 FROM tn, tb;
SELECT u < b1 FROM tn, tb;
SELECT u >= b1 FROM tn, tb;
SELECT u <= b1 FROM tn, tb;
SELECT u = b1 FROM tn, tb;
SELECT u != b1 FROM tn, tb;

SELECT b1 > u FROM tn, tb;
SELECT b1 < u FROM tn, tb;
SELECT b1 >= u FROM tn, tb;
SELECT b1 <= u FROM tn, tb;
SELECT b1 = u FROM tn, tb;
SELECT b1 != u FROM tn, tb;

-- Make sure that numbers cannot be compared with STRING values.
SELECT 3 > '123';
SELECT 3 < '123';
SELECT 3 >= '123';
SELECT 3 <= '123';
SELECT 3 = '123';
SELECT 3 != '123';

SELECT '123' > 4;
SELECT '123' < 4;
SELECT '123' >= 4;
SELECT '123' <= 4;
SELECT '123' = 4;
SELECT '123' != 4;

SELECT 3.5 > '123';
SELECT 3.5 < '123';
SELECT 3.5 >= '123';
SELECT 3.5 <= '123';
SELECT 3.5 = '123';
SELECT 3.5 != '123';

SELECT '123' > 0.5;
SELECT '123' < 0.5;
SELECT '123' >= 0.5;
SELECT '123' <= 0.5;
SELECT '123' = 0.5;
SELECT '123' != 0.5;

SELECT i > '123' FROM tn;
SELECT i < '123' FROM tn;
SELECT i >= '123' FROM tn;
SELECT i <= '123' FROM tn;
SELECT i = '123' FROM tn;
SELECT i != '123' FROM tn;

SELECT '123' > i FROM tn;
SELECT '123' < i FROM tn;
SELECT '123' >= i FROM tn;
SELECT '123' <= i FROM tn;
SELECT '123' = i FROM tn;
SELECT '123' != i FROM tn;

SELECT a > '123' FROM tn;
SELECT a < '123' FROM tn;
SELECT a >= '123' FROM tn;
SELECT a <= '123' FROM tn;
SELECT a = '123' FROM tn;
SELECT a != '123' FROM tn;

SELECT '123' > a FROM tn;
SELECT '123' < a FROM tn;
SELECT '123' >= a FROM tn;
SELECT '123' <= a FROM tn;
SELECT '123' = a FROM tn;
SELECT '123' != a FROM tn;

SELECT d > '123' FROM tn;
SELECT d < '123' FROM tn;
SELECT d >= '123' FROM tn;
SELECT d <= '123' FROM tn;
SELECT d = '123' FROM tn;
SELECT d != '123' FROM tn;

SELECT '123' > d FROM tn;
SELECT '123' < d FROM tn;
SELECT '123' >= d FROM tn;
SELECT '123' <= d FROM tn;
SELECT '123' = d FROM tn;
SELECT '123' != d FROM tn;

SELECT u > '123' FROM tn;
SELECT u < '123' FROM tn;
SELECT u >= '123' FROM tn;
SELECT u <= '123' FROM tn;
SELECT u = '123' FROM tn;
SELECT u != '123' FROM tn;

SELECT '123' > u FROM tn;
SELECT '123' < u FROM tn;
SELECT '123' >= u FROM tn;
SELECT '123' <= u FROM tn;
SELECT '123' = u FROM tn;
SELECT '123' != u FROM tn;

SELECT 3 > s1 FROM ts;
SELECT 3 < s1 FROM ts;
SELECT 3 >= s1 FROM ts;
SELECT 3 <= s1 FROM ts;
SELECT 3 = s1 FROM ts;
SELECT 3 != s1 FROM ts;

SELECT s1 > 4 FROM ts;
SELECT s1 < 4 FROM ts;
SELECT s1 >= 4 FROM ts;
SELECT s1 <= 4 FROM ts;
SELECT s1 = 4 FROM ts;
SELECT s1 != 4 FROM ts;

SELECT 3.5 > s1 FROM ts;
SELECT 3.5 < s1 FROM ts;
SELECT 3.5 >= s1 FROM ts;
SELECT 3.5 <= s1 FROM ts;
SELECT 3.5 = s1 FROM ts;
SELECT 3.5 != s1 FROM ts;

SELECT s1 > 0.5 FROM ts;
SELECT s1 < 0.5 FROM ts;
SELECT s1 >= 0.5 FROM ts;
SELECT s1 <= 0.5 FROM ts;
SELECT s1 = 0.5 FROM ts;
SELECT s1 != 0.5 FROM ts;

SELECT i > s1 FROM tn, ts;
SELECT i < s1 FROM tn, ts;
SELECT i >= s1 FROM tn, ts;
SELECT i <= s1 FROM tn, ts;
SELECT i = s1 FROM tn, ts;
SELECT i != s1 FROM tn, ts;

SELECT s1 > i FROM tn, ts;
SELECT s1 < i FROM tn, ts;
SELECT s1 >= i FROM tn, ts;
SELECT s1 <= i FROM tn, ts;
SELECT s1 = i FROM tn, ts;
SELECT s1 != i FROM tn, ts;

SELECT a > s1 FROM tn, ts;
SELECT a < s1 FROM tn, ts;
SELECT a >= s1 FROM tn, ts;
SELECT a <= s1 FROM tn, ts;
SELECT a = s1 FROM tn, ts;
SELECT a != s1 FROM tn, ts;

SELECT s1 > a FROM tn, ts;
SELECT s1 < a FROM tn, ts;
SELECT s1 >= a FROM tn, ts;
SELECT s1 <= a FROM tn, ts;
SELECT s1 = a FROM tn, ts;
SELECT s1 != a FROM tn, ts;

SELECT d > s1 FROM tn, ts;
SELECT d < s1 FROM tn, ts;
SELECT d >= s1 FROM tn, ts;
SELECT d <= s1 FROM tn, ts;
SELECT d = s1 FROM tn, ts;
SELECT d != s1 FROM tn, ts;

SELECT s1 > d FROM tn, ts;
SELECT s1 < d FROM tn, ts;
SELECT s1 >= d FROM tn, ts;
SELECT s1 <= d FROM tn, ts;
SELECT s1 = d FROM tn, ts;
SELECT s1 != d FROM tn, ts;

SELECT u > s1 FROM tn, ts;
SELECT u < s1 FROM tn, ts;
SELECT u >= s1 FROM tn, ts;
SELECT u <= s1 FROM tn, ts;
SELECT u = s1 FROM tn, ts;
SELECT u != s1 FROM tn, ts;

SELECT s1 > u FROM tn, ts;
SELECT s1 < u FROM tn, ts;
SELECT s1 >= u FROM tn, ts;
SELECT s1 <= u FROM tn, ts;
SELECT s1 = u FROM tn, ts;
SELECT s1 != u FROM tn, ts;

--
-- Make sure that numbers cannot be compared with VARBINARY
-- values.
--
SELECT 3 > X'3139';
SELECT 3 < X'3139';
SELECT 3 >= X'3139';
SELECT 3 <= X'3139';
SELECT 3 = X'3139';
SELECT 3 != X'3139';

SELECT X'3139' > 4;
SELECT X'3139' < 4;
SELECT X'3139' >= 4;
SELECT X'3139' <= 4;
SELECT X'3139' = 4;
SELECT X'3139' != 4;

SELECT 3.5 > X'3139';
SELECT 3.5 < X'3139';
SELECT 3.5 >= X'3139';
SELECT 3.5 <= X'3139';
SELECT 3.5 = X'3139';
SELECT 3.5 != X'3139';

SELECT X'3139' > 0.5;
SELECT X'3139' < 0.5;
SELECT X'3139' >= 0.5;
SELECT X'3139' <= 0.5;
SELECT X'3139' = 0.5;
SELECT X'3139' != 0.5;

SELECT i > X'3139' FROM tn;
SELECT i < X'3139' FROM tn;
SELECT i >= X'3139' FROM tn;
SELECT i <= X'3139' FROM tn;
SELECT i = X'3139' FROM tn;
SELECT i != X'3139' FROM tn;

SELECT X'3139' > i FROM tn;
SELECT X'3139' < i FROM tn;
SELECT X'3139' >= i FROM tn;
SELECT X'3139' <= i FROM tn;
SELECT X'3139' = i FROM tn;
SELECT X'3139' != i FROM tn;

SELECT a > X'3139' FROM tn;
SELECT a < X'3139' FROM tn;
SELECT a >= X'3139' FROM tn;
SELECT a <= X'3139' FROM tn;
SELECT a = X'3139' FROM tn;
SELECT a != X'3139' FROM tn;

SELECT X'3139' > a FROM tn;
SELECT X'3139' < a FROM tn;
SELECT X'3139' >= a FROM tn;
SELECT X'3139' <= a FROM tn;
SELECT X'3139' = a FROM tn;
SELECT X'3139' != a FROM tn;

SELECT d > X'3139' FROM tn;
SELECT d < X'3139' FROM tn;
SELECT d >= X'3139' FROM tn;
SELECT d <= X'3139' FROM tn;
SELECT d = X'3139' FROM tn;
SELECT d != X'3139' FROM tn;

SELECT X'3139' > d FROM tn;
SELECT X'3139' < d FROM tn;
SELECT X'3139' >= d FROM tn;
SELECT X'3139' <= d FROM tn;
SELECT X'3139' = d FROM tn;
SELECT X'3139' != d FROM tn;

SELECT u > X'3139' FROM tn;
SELECT u < X'3139' FROM tn;
SELECT u >= X'3139' FROM tn;
SELECT u <= X'3139' FROM tn;
SELECT u = X'3139' FROM tn;
SELECT u != X'3139' FROM tn;

SELECT X'3139' > u FROM tn;
SELECT X'3139' < u FROM tn;
SELECT X'3139' >= u FROM tn;
SELECT X'3139' <= u FROM tn;
SELECT X'3139' = u FROM tn;
SELECT X'3139' != u FROM tn;

SELECT 3 > v1 FROM tv;
SELECT 3 < v1 FROM tv;
SELECT 3 >= v1 FROM tv;
SELECT 3 <= v1 FROM tv;
SELECT 3 = v1 FROM tv;
SELECT 3 != v1 FROM tv;

SELECT v1 > 4 FROM tv;
SELECT v1 < 4 FROM tv;
SELECT v1 >= 4 FROM tv;
SELECT v1 <= 4 FROM tv;
SELECT v1 = 4 FROM tv;
SELECT v1 != 4 FROM tv;

SELECT 3.5 > v1 FROM tv;
SELECT 3.5 < v1 FROM tv;
SELECT 3.5 >= v1 FROM tv;
SELECT 3.5 <= v1 FROM tv;
SELECT 3.5 = v1 FROM tv;
SELECT 3.5 != v1 FROM tv;

SELECT v1 > 0.5 FROM tv;
SELECT v1 < 0.5 FROM tv;
SELECT v1 >= 0.5 FROM tv;
SELECT v1 <= 0.5 FROM tv;
SELECT v1 = 0.5 FROM tv;
SELECT v1 != 0.5 FROM tv;

SELECT i > v1 FROM tn, tv;
SELECT i < v1 FROM tn, tv;
SELECT i >= v1 FROM tn, tv;
SELECT i <= v1 FROM tn, tv;
SELECT i = v1 FROM tn, tv;
SELECT i != v1 FROM tn, tv;

SELECT v1 > i FROM tn, tv;
SELECT v1 < i FROM tn, tv;
SELECT v1 >= i FROM tn, tv;
SELECT v1 <= i FROM tn, tv;
SELECT v1 = i FROM tn, tv;
SELECT v1 != i FROM tn, tv;

SELECT a > v1 FROM tn, tv;
SELECT a < v1 FROM tn, tv;
SELECT a >= v1 FROM tn, tv;
SELECT a <= v1 FROM tn, tv;
SELECT a = v1 FROM tn, tv;
SELECT a != v1 FROM tn, tv;

SELECT v1 > a FROM tn, tv;
SELECT v1 < a FROM tn, tv;
SELECT v1 >= a FROM tn, tv;
SELECT v1 <= a FROM tn, tv;
SELECT v1 = a FROM tn, tv;
SELECT v1 != a FROM tn, tv;

SELECT d > v1 FROM tn, tv;
SELECT d < v1 FROM tn, tv;
SELECT d >= v1 FROM tn, tv;
SELECT d <= v1 FROM tn, tv;
SELECT d = v1 FROM tn, tv;
SELECT d != v1 FROM tn, tv;

SELECT v1 > d FROM tn, tv;
SELECT v1 < d FROM tn, tv;
SELECT v1 >= d FROM tn, tv;
SELECT v1 <= d FROM tn, tv;
SELECT v1 = d FROM tn, tv;
SELECT v1 != d FROM tn, tv;

SELECT u > v1 FROM tn, tv;
SELECT u < v1 FROM tn, tv;
SELECT u >= v1 FROM tn, tv;
SELECT u <= v1 FROM tn, tv;
SELECT u = v1 FROM tn, tv;
SELECT u != v1 FROM tn, tv;

SELECT v1 > u FROM tn, tv;
SELECT v1 < u FROM tn, tv;
SELECT v1 >= u FROM tn, tv;
SELECT v1 <= u FROM tn, tv;
SELECT v1 = u FROM tn, tv;
SELECT v1 != u FROM tn, tv;

--
-- Make sure that BOOLEAN values cannot be compared with STRING
-- values.
--
SELECT true > 'TRUE';
SELECT true < 'TRUE';
SELECT true >= 'TRUE';
SELECT true <= 'TRUE';
SELECT true = 'TRUE';
SELECT true != 'TRUE';

SELECT 'TRUE' > true;
SELECT 'TRUE' < true;
SELECT 'TRUE' >= true;
SELECT 'TRUE' <= true;
SELECT 'TRUE' = true;
SELECT 'TRUE' != true;

SELECT b1 > 'TRUE' FROM tb;
SELECT b1 < 'TRUE' FROM tb;
SELECT b1 >= 'TRUE' FROM tb;
SELECT b1 <= 'TRUE' FROM tb;
SELECT b1 = 'TRUE' FROM tb;
SELECT b1 != 'TRUE' FROM tb;

SELECT 'TRUE' > b1 FROM tb;
SELECT 'TRUE' < b1 FROM tb;
SELECT 'TRUE' >= b1 FROM tb;
SELECT 'TRUE' <= b1 FROM tb;
SELECT 'TRUE' = b1 FROM tb;
SELECT 'TRUE' != b1 FROM tb;

SELECT true > s1 FROM ts;
SELECT true < s1 FROM ts;
SELECT true >= s1 FROM ts;
SELECT true <= s1 FROM ts;
SELECT true = s1 FROM ts;
SELECT true != s1 FROM ts;

SELECT s1 > true FROM ts;
SELECT s1 < true FROM ts;
SELECT s1 >= true FROM ts;
SELECT s1 <= true FROM ts;
SELECT s1 = true FROM ts;
SELECT s1 != true FROM ts;

SELECT b1 > s1 FROM tb, ts;
SELECT b1 < s1 FROM tb, ts;
SELECT b1 >= s1 FROM tb, ts;
SELECT b1 <= s1 FROM tb, ts;
SELECT b1 = s1 FROM tb, ts;
SELECT b1 != s1 FROM tb, ts;

SELECT s1 > b1 FROM tb, ts;
SELECT s1 < b1 FROM tb, ts;
SELECT s1 >= b1 FROM tb, ts;
SELECT s1 <= b1 FROM tb, ts;
SELECT s1 = b1 FROM tb, ts;
SELECT s1 != b1 FROM tb, ts;

--
-- Make sure that BOOLEAN values cannot be compared with VARBINARY
-- values.
--
SELECT true > X'54525545';
SELECT true < X'54525545';
SELECT true >= X'54525545';
SELECT true <= X'54525545';
SELECT true = X'54525545';
SELECT true != X'54525545';

SELECT X'54525545' > true;
SELECT X'54525545' < true;
SELECT X'54525545' >= true;
SELECT X'54525545' <= true;
SELECT X'54525545' = true;
SELECT X'54525545' != true;

SELECT b1 > X'54525545' FROM tb;
SELECT b1 < X'54525545' FROM tb;
SELECT b1 >= X'54525545' FROM tb;
SELECT b1 <= X'54525545' FROM tb;
SELECT b1 = X'54525545' FROM tb;
SELECT b1 != X'54525545' FROM tb;

SELECT X'54525545' > b1 FROM tb;
SELECT X'54525545' < b1 FROM tb;
SELECT X'54525545' >= b1 FROM tb;
SELECT X'54525545' <= b1 FROM tb;
SELECT X'54525545' = b1 FROM tb;
SELECT X'54525545' != b1 FROM tb;

DELETE FROM tv;
INSERT INTO tv VALUES (X'54525545', X'54525545');

SELECT true > v1 FROM tv;
SELECT true < v1 FROM tv;
SELECT true >= v1 FROM tv;
SELECT true <= v1 FROM tv;
SELECT true = v1 FROM tv;
SELECT true != v1 FROM tv;

SELECT v1 > true FROM tv;
SELECT v1 < true FROM tv;
SELECT v1 >= true FROM tv;
SELECT v1 <= true FROM tv;
SELECT v1 = true FROM tv;
SELECT v1 != true FROM tv;

SELECT b1 > v1 FROM tb, tv;
SELECT b1 < v1 FROM tb, tv;
SELECT b1 >= v1 FROM tb, tv;
SELECT b1 <= v1 FROM tb, tv;
SELECT b1 = v1 FROM tb, tv;
SELECT b1 != v1 FROM tb, tv;

SELECT v1 > b1 FROM tb, tv;
SELECT v1 < b1 FROM tb, tv;
SELECT v1 >= b1 FROM tb, tv;
SELECT v1 <= b1 FROM tb, tv;
SELECT v1 = b1 FROM tb, tv;
SELECT v1 != b1 FROM tb, tv;

--
-- Make sure that STRING values cannot be compared with VARBINARY
-- values.
--
SELECT '123' > X'54525545';
SELECT '123' < X'54525545';
SELECT '123' >= X'54525545';
SELECT '123' <= X'54525545';
SELECT '123' = X'54525545';
SELECT '123' != X'54525545';

SELECT X'54525545' > '123';
SELECT X'54525545' < '123';
SELECT X'54525545' >= '123';
SELECT X'54525545' <= '123';
SELECT X'54525545' = '123';
SELECT X'54525545' != '123';

SELECT s1 > X'54525545' FROM ts;
SELECT s1 < X'54525545' FROM ts;
SELECT s1 >= X'54525545' FROM ts;
SELECT s1 <= X'54525545' FROM ts;
SELECT s1 = X'54525545' FROM ts;
SELECT s1 != X'54525545' FROM ts;

SELECT X'54525545' > s1 FROM ts;
SELECT X'54525545' < s1 FROM ts;
SELECT X'54525545' >= s1 FROM ts;
SELECT X'54525545' <= s1 FROM ts;
SELECT X'54525545' = s1 FROM ts;
SELECT X'54525545' != s1 FROM ts;

SELECT '123' > v1 FROM tv;
SELECT '123' < v1 FROM tv;
SELECT '123' >= v1 FROM tv;
SELECT '123' <= v1 FROM tv;
SELECT '123' = v1 FROM tv;
SELECT '123' != v1 FROM tv;

SELECT v1 > '123' FROM tv;
SELECT v1 < '123' FROM tv;
SELECT v1 >= '123' FROM tv;
SELECT v1 <= '123' FROM tv;
SELECT v1 = '123' FROM tv;
SELECT v1 != '123' FROM tv;

SELECT s1 > v1 FROM ts, tv;
SELECT s1 < v1 FROM ts, tv;
SELECT s1 >= v1 FROM ts, tv;
SELECT s1 <= v1 FROM ts, tv;
SELECT s1 = v1 FROM ts, tv;
SELECT s1 != v1 FROM ts, tv;

SELECT v1 > s1 FROM ts, tv;
SELECT v1 < s1 FROM ts, tv;
SELECT v1 >= s1 FROM ts, tv;
SELECT v1 <= s1 FROM ts, tv;
SELECT v1 = s1 FROM ts, tv;
SELECT v1 != s1 FROM ts, tv;
