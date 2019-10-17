env = require('test_run')
test_run = env.new()
engine = test_run:get_cfg('engine')
box.execute('pragma sql_default_engine=\''..engine..'\'')

--
-- gh-4565: Missing foreign key check in case of
--          autoincremented field
--
box.execute("CREATE TABLE t1 (s1 INTEGER PRIMARY KEY);")
box.execute("CREATE TABLE t2 (s1 INTEGER PRIMARY KEY AUTOINCREMENT, FOREIGN KEY (s1) REFERENCES t1);")
box.execute("INSERT INTO t2 VALUES (NULL);")
box.space.T1:count() == 0
box.space.T2:count() == 0
box.execute("INSERT INTO t1 VALUES (1);")
box.execute("INSERT INTO t2 VALUES (NULL);")
box.space.T1:count() == 1
box.space.T2:count() == 1
box.execute("INSERT INTO t2 VALUES (NULL);")
box.space.T1:count() == 1
box.space.T2:count() == 1
box.sequence.T2:set(box.sequence.T2.max)
box.sequence.T2:next()
box.execute("INSERT INTO t2 VALUES (NULL);")
box.space.T1:drop()
box.space.T2:drop()
