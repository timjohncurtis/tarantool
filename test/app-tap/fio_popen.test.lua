#!/usr/bin/env tarantool

local tap = require('tap')
local fio = require('fio')
local errno = require('errno')
local signal = require('signal')
local fiber = require('fiber')
local test = tap.test()

test:plan(7+11+13+11+10+8+5+4+8+6)

-- Preliminaries
local function read_stdout(app)
    local ss = ""

    local s,src,err = app:read(128, 0.1)

    while s ~= nil and s ~= "" do
        ss = ss .. s

        s,src,err = app:read(128, 0.1)
    end

    return ss
end

-- Test 1. Run application, check its status, kill and wait
local app1 = fio.popen({'/bin/sh', '-c', 'cat'},
        {stdout=fio.STDOUT, stderr=fio.STDOUT})
test:isnt(app1, nil, "#1. Starting a existing application")

local rc = app1:status()
test:is(rc, nil, "#1. Process is running")

rc,err = app1:kill()
test:is(rc, true, "#1. Sending kill(15)")

rc,err = app1:wait(5)
test:is(rc, true, "#1. Process was killed")

rc = app1:status()
test:is(rc, -signal.SIGTERM, "#1. Process was killed 2")

rc,src,err = app1:read(128,0.1)
test:is(rc, nil, "#1. Cant read from the dead process")

rc,err = app1:shutdown()
test:is(rc, true, "#1. Release resources")

app1 = nil

-- Test 2. Run application, write to stdin, read from stdout
app1 = fio.popen({'/bin/sh', '-c', 'cat'},{stdout=fio.PIPE,
                                           stdin=fio.PIPE,
                                           stderr=fio.STDOUT})
test:isnt(app1, nil, "#2. Starting a existing application")

rc = app1:status()
test:is(rc, nil, "#2. Process is running")

local test2str = '123\n456\n789'

app1:write(test2str)
rc,src,err = app1:read(256)

test:is(src, fio.STDOUT, "#2. Read from STDOUT")
test:is(rc, test2str, "#2. Received exact string")

test2str = 'abc\ndef\ngh'

app1:write(test2str, 4)

rc,err = app1:kill()
test:is(rc, true, "#2. Sending kill(15)")

rc,err = app1:wait()
test:is(rc, true, "#2. Process is terminated")

local rc2,src2,err = app1:read(6)

test:is(err, nil, "#2. Reading ok after wait()")
test:is(src2, fio.STDOUT, "#2. Read from STDOUT 2")
test:is(rc2, 'abc\n', "#2. Received exact string 2")

rc,err = app1:shutdown()
test:is(rc, true, "#2. Release resources")

rc = app1:status()
test:is(rc, -signal.SIGTERM, "#2. Process was killed")

app1 = nil

-- Test 3. read from stdout with timeout
app1 = fio.popen({'/bin/sh', '-c', 'cat'},{stdout=fio.PIPE,
                                           stdin=fio.PIPE,
                                           stderr=fio.STDOUT})
test:isnt(app1, nil, "#3. Starting a existing application")
test:is(app1:stderr(), nil, "#3. STDERR is redirected")
test:isnt(app1:stdout(), nil, "#3. STDOUT is available")
test:isnt(app1:stdin(), nil, "#3. STDIN is available")


rc = app1:status()
test:is(rc, nil, "#3. Process is running")

rc,src,err = app1:read({size=256,timeout=0.5})

local e = errno()
test:is(e, errno.ETIMEDOUT, "#3. Timeout")


local test2str = '123\n456\n789'

app1:write(test2str)
rc,src,err = app1:read(256, 0.5)

test:is(err, nil, "#3. Reading ok")
test:is(src, fio.STDOUT, "#3. Read from STDOUT")
test:is(rc, test2str, "#3. Received exact string")

rc,err = app1:kill(signal.SIGHUP)
test:is(rc, true, "#3. Sending kill(1)")

rc,err = app1:wait()
test:is(rc, true, "#3. Process was killed")

rc,err = app1:shutdown()
test:is(rc, true, "#3. Release resources")

rc = app1:status()
test:is(rc, -signal.SIGHUP, "#3. Process was killed")

app1 = nil

-- Test 4. Redirect from file
local tmpdir = fio.tempdir()
local txt_filename = fio.pathjoin(tmpdir, 'fio_popen.sample.txt')
fh1 = fio.open(txt_filename, { 'O_RDWR', 'O_TRUNC', 'O_CREAT' }, tonumber('0777', 8))

local test2str = 'AAA\nBBB\nCCC\nDDD\n\n'

fh1:write(test2str)
fh1:close()

local txt_file = fio.open(txt_filename, {'O_RDONLY'})
test:isnt(txt_file, nil, "#4. Open existing file for reading")

app1 = fio.popen({'/bin/sh', '-c', 'cat'},{stdout=fio.PIPE,
                                           stdin=txt_file,
                                           stderr=fio.STDOUT})
test:isnt(app1, nil, "#4. Starting a existing application")
test:is(app1:stderr(), nil, "#4. STDERR is redirected")
test:isnt(app1:stdout(), nil, "#4. STDOUT is available")
test:is(app1:stdin(), nil, "#4. STDIN is redirected")

rc = app1:status()
test:is(rc, nil, "#4. Process is running")

rc,src,err = app1:read(256, 0.5)

test:is(src, fio.STDOUT, "#4. Read from STDOUT")
test:is(rc, test2str, "#4. Received exact string")

rc,err = app1:wait()
test:is(rc, true, "#4. Process is terminated")

rc,err = app1:shutdown()
test:is(rc, true, "#4. Release resources")

rc = app1:status()
test:is(rc, 0, "#4. Process's exited")

app1 = nil
txt_file:close()
fio.unlink(txt_filename)

-- Test 5. Redirect output from one process to another
local build_path = os.getenv("BUILDDIR")
local app_path = fio.pathjoin(build_path, 'test/app-tap/fio_popen_test1.sh')

app1 = fio.popen({'/bin/sh', '-c', app_path},{stdout=fio.PIPE,
                                              stderr=fio.STDOUT})

test:isnt(app1, nil, "#5. Starting application 1")
test:is(app1:stderr(), nil, "#5. STDERR is redirected")
test:isnt(app1:stdout(), nil, "#5. STDOUT is available")
test:isnt(app1:stdin(), nil, "#5. STDIN is available")

fiber.sleep(1)

local app2 = fio.popen({'/bin/sh', '-c', 'cat'},
        {stdout=fio.PIPE, stdin=app1:stdout()})

test:isnt(app2, nil, "#5. Starting application 2")

local test2str = '1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n'

rc = read_stdout(app2)

test:is(rc, test2str, "#5. Received exact string")

rc,err = app1:wait()
test:is(rc, true, "#5. Process's exited 1")

rc,err = app2:wait()
test:is(rc, true, "#5. Process's exited 2")

rc,err = app1:shutdown()
test:is(rc, true, "#5. Release resources 1")
rc,err = app2:shutdown()
test:is(rc, true, "#5. Release resources 2")

app1 = nil
app2 = nil

-- Test 6. Write a lot
app1 = fio.popen({'/bin/sh', '-c', 'cat'},
        { stdout=fio.PIPE,
          stdin=fio.PIPE,
          stderr=fio.STDOUT})
test:isnt(app1, nil, "#6. Starting a existing application")

rc = app1:status()
test:is(rc, nil, "#6. Process is running")

local expected_length = 0
local received_length = 0
local str_to_send = ''
local str_to_receive = ''

for i=0,1000 do

    local ss = ''
    for j = 0,100 do
        local s = tostring(i*100+j) .. '\n'
        ss = ss .. s
    end

    str_to_send = str_to_send .. ss
    app1:write({buf=ss, timeout=1})
    rc,src,err = app1:read(1024, 1)
    if rc ~= nil then
        received_length = received_length + string.len(rc)
        str_to_receive = str_to_receive .. rc
    end
end

expected_length = string.len(str_to_send)

-- Read the rest data
str_to_receive = str_to_receive .. read_stdout(app1)
received_length = string.len(str_to_receive)

test:is(received_length, expected_length, "#6. Received number of bytes")
test:is(str_to_receive, str_to_send, "#6. Received exact string")

rc,err = app1:kill()
test:is(rc, true, "#6. Sending kill(15)")

rc,err = app1:wait()
test:is(rc, true, "#6. Process is terminated")

rc,err = app1:shutdown()
test:is(rc, true, "#6. Release resources")

rc = app1:status()
test:is(rc, -signal.SIGTERM, "#6. Process was killed")

app1 = nil

-- Test 7. Read both STDOUT & STDERR
local app_path = fio.pathjoin(build_path, 'test/app-tap/fio_popen_test2.sh')

app1 = fio.popen({'/bin/sh', '-c', app_path},{stdin=fio.STDIN,
                                              stdout=fio.PIPE,
                                              stderr=fio.PIPE})

test:isnt(app1, nil, "#7. Starting application")

local result = {}
result[fio.STDOUT] = ''
result[fio.STDERR] = ''

while rc ~= nil and rc ~= '' do
    rc,src,err = app1:read(64, 0.5)
    if rc ~= nil then
        result[src] = result[src] .. rc
    end
end

local test2str = '1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n'

test:is(result[fio.STDOUT], test2str, "#7. Received STDOUT")
test:is(result[fio.STDERR], test2str, "#7. Received STDERR")

rc,err = app1:wait()
test:is(rc, true, "#7. Process's exited")
rc,err = app1:shutdown()
test:is(rc, true, "#7. Release resources")

app1 = nil


-- Test 8. Use custom environment variables
local app_path = fio.pathjoin(build_path, 'test/app-tap/fio_popen_test3.sh')

app1 = fio.popen({'/bin/sh', '-c', app_path},{
    env = {'VAR1=Variable1', 'VAR2=Variable2','VAR3=Variable3'},
    stdout=fio.PIPE,
    stderr=fio.STDOUT})

test:isnt(app1, nil, "#8. Starting a existing application")

rc = read_stdout(app1)

local test2str = 'Variable1\nVariable2\nVariable3\n'
test:is(rc, test2str, "#8. Received values of env. variables")

rc,err = app1:wait()
test:is(rc, true, "#8. Process was killed")
rc,err = app1:shutdown()
test:is(rc, true, "#8. Release resources")

app1 = nil

-- Test 9. Run application, use close()
app1 = fio.popen({'/bin/sh', '-c', 'cat'},{stdout=fio.PIPE,
                                           stdin=fio.PIPE,
                                           stderr=fio.STDOUT})
test:isnt(app1, nil, "#9. Starting a existing application")

rc = app1:status()
test:is(rc, nil, "#9. Process is running")

local test2str = '123\n456\n789'

app1:write(test2str)
rc,src,err = app1:read(256)

test:is(src, fio.STDOUT, "#9. Read from STDOUT")
test:is(rc, test2str, "#9. Received exact string")

rc,err = app1:close(fio.STDIN)
test:is(rc, true, "#9. Close STDIN")

rc,err = app1:wait()
test:is(rc, true, "#9. Process is terminated")

rc,err = app1:shutdown()
test:is(rc, true, "#9. Release resources")

rc = app1:status()
test:is(rc, 0, "#9. Process has exited")

app1 = nil
-- Test 10. Run application, redirect stdout to dev/null
app1 = fio.popen({'/bin/sh', '-c', 'cat'},{stdout=fio.DEVNULL,
                                           stdin=fio.PIPE,
                                           stderr=fio.STDOUT})
test:isnt(app1, nil, "#10. Starting a existing application")

rc = app1:status()
test:is(rc, nil, "#10. Process is running")

for i=0,1000 do

    local ss = ''
    for j = 0,100 do
        local s = tostring(i*100+j) .. '\n'
        ss = ss .. s
    end

    app1:write(ss)
end

rc,err = app1:close(fio.STDIN)
test:is(rc, true, "#10. Close STDIN")

rc,err = app1:wait()
test:is(rc, true, "#10. Process is terminated")

rc,err = app1:shutdown()
test:is(rc, true, "#10. Release resources")

rc = app1:status()
test:is(rc, 0, "#10. Process has exited")

app1 = nil
-- --------------------------------------------------------------
test:check()
os.exit(0)

