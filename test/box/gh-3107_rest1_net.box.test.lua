fiber = require 'fiber'
net = require('net.box')

--
-- gh-3107: fiber-async netbox.
--
cond = nil
box.schema.func.create('long_function')
box.schema.user.grant('guest', 'execute', 'function', 'long_function')
function long_function(...) cond = fiber.cond() cond:wait() return ... end
function finalize_long() while not cond do fiber.sleep(0.01) end cond:signal() cond = nil end
s = box.schema.create_space('test')
pk = s:create_index('pk')
s:replace{1}
s:replace{2}
s:replace{3}
s:replace{4}
c = net:connect(box.cfg.listen)

--
-- Check infinity timeout.
--
ret = nil
_ = fiber.create(function() ret = c:call('long_function', {1, 2, 3}, {is_async = true}):wait_result() end)
finalize_long()
while not ret do fiber.sleep(0.01) end
ret
c:close()
box.schema.user.grant('guest', 'execute', 'universe')
c = net:connect(box.cfg.listen)
future = c:eval('return long_function(...)', {1, 2, 3}, {is_async = true})
future:result()
future:wait_result(0.01) -- Must fail on timeout.
finalize_long()
future:wait_result(100)

c:close()
--
-- Check that is_async does not work on a closed connection.
--
c:call('any_func', {}, {is_async = true})

box.schema.user.revoke('guest', 'execute', 'universe')
c = net:connect(box.cfg.listen)

c:close()
s:drop()
