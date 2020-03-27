#!/usr/bin/env tarantool

local tap = require('tap')

local test = tap.test('gh-4427-ffi-sandwich')

local vars = {
  PATH   = os.getenv('BUILDDIR') .. '/test/luajit-tap/gh-4427-ffi-sandwich',
  SUFFIX = package.cpath:match('?.(%a+);'),
}

local cmd = string.gsub('LUA_CPATH=<PATH>/?.<SUFFIX> LD_LIBRARY_PATH=<PATH> '
  .. 'tarantool 2>&1 <PATH>/test.lua %d %d', '%<(%w+)>', vars)

local checks = {
  { hotloop = 1, trigger = 1, success = true  },
  { hotloop = 1, trigger = 2, success = false },
}

test:plan(#checks)

for _, ch in pairs(checks) do
  local res
  local proc = io.popen(cmd:format(ch.hotloop, ch.trigger))
  for s in proc:lines('*l') do res = s end
  assert(res, 'proc:lines failed')
  if ch.success then
    test:is(tonumber(res), ch.hotloop + ch.trigger + 1)
  else
    test:is(res, 'Lua VM re-entrancy is detected while executing the trace')
  end
end

os.exit(test:check() and 0 or 1)
