fio = require('fio')
xlog = require('xlog').pairs
env = require('test_run')
test_run = env.new()

test_run:cmd("setopt delimiter ';'")
function read_xlog(file)
    local val = {}
    for k, v in xlog(file) do
        table.insert(val, setmetatable(v, { __serialize = "map"}))
    end
    return val
end;
test_run:cmd("setopt delimiter ''");

old_snapshot = box.snapshot
box.snapshot = function () box.internal.wal_rotate() old_snapshot() return 'ok' end

-- gh-2798 check for journal transaction encoding
_ = box.schema.space.create('test'):create_index('pk')
-- generate a new xlog
box.snapshot()
lsn = box.info.lsn
-- autocommit transaction
box.space.test:replace({1})
-- one row transaction
box.begin() box.space.test:replace({2}) box.commit()
-- two row transaction
box.begin() for i = 3, 4 do box.space.test:replace({i}) end box.commit()
-- four row transaction
box.begin() for i = 5, 8 do box.space.test:replace({i}) end box.commit()
-- open a new xlog
box.snapshot()
-- read a previous one
lsn_str = tostring(lsn)
data = read_xlog(fio.pathjoin(box.cfg.wal_dir, string.rep('0', 20 - #lsn_str) .. tostring(lsn_str) .. '.xlog'))
-- check nothing changed for single row transactions
data[1].HEADER.tsn == nil and data[1].HEADER.commit == nil
data[2].HEADER.type == 13 -- WAL ACK
data[3].HEADER.tsn == nil and data[3].HEADER.commit == nil
data[4].HEADER.type == 13 -- WAL ACK
-- check two row transaction
data[5].HEADER.tsn == data[5].HEADER.lsn and data[5].HEADER.commit == nil
data[6].HEADER.tsn == data[6].HEADER.tsn and data[6].HEADER.commit == true
data[7].HEADER.type == 13 -- WAL ACK
-- check four row transaction
data[8].HEADER.tsn == data[8].HEADER.lsn and data[8].HEADER.commit == nil
data[9].HEADER.tsn == data[9].HEADER.tsn and data[9].HEADER.commit == nil
data[10].HEADER.tsn == data[10].HEADER.tsn and data[10].HEADER.commit == nil
data[11].HEADER.tsn == data[11].HEADER.tsn and data[11].HEADER.commit == true
data[12].HEADER.type == 13 -- WAL ACK
box.space.test:drop()

box.snapshot = old_snapshot
