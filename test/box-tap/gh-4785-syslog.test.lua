#!/usr/bin/env tarantool
test_run = require('test_run').new()

local socket = require('socket')
local log = require('log')
local fio = require('fio')

path = fio.pathjoin(fio.cwd(), 'log_unix_socket_test.sock')
unix_socket = socket('AF_UNIX', 'SOCK_DGRAM', 0)
unix_socket:bind('unix/', path)

opt = string.format("syslog:server=unix:%s,identity=tarantool", path)
local buf = ''
box.cfg{log = opt}
buf = buf .. unix_socket:recv(100)
str = string.format(buf)
-- Check syslog format: TIMESTAMP IDENTATION[PID]
--<>TIMESTAMP tarantool[PID]: main//gh.test.lua C> Tarantool
print(((((str:gsub("%d", "")):gsub("%p%p--%w+", "")):gsub("%w+  ::", "TIMESTAMP")):gsub("]", "PID]")))
unix_socket:close()
os.remove(path)
os.exit(0)
