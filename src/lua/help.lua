local doc = require('help.en_US')

-- The built-in tutorial contains links to the online
-- documentation with a <version> placeholder like
-- https://tarantool.io/en/doc/<version>/<...>. We should replace
-- the placeholders with a version of a documentation page that
-- corresponds to a tarantool version a user runs.
local DOCUMENTATION_VERSION = '2.1'

help = { doc.help }
tutorial = {}
tutorial[1] = help[1] -- luacheck: ignore 113

local help_function_data = {}; -- luacheck: ignore 211
local help_object_data = {} -- luacheck: ignore 211

local function help_call(table, param) -- luacheck: ignore 212
    return help -- luacheck: ignore 113
end

setmetatable(help, { __call = help_call }) -- luacheck: ignore 113

local screen_id = 1;

local function tutorial_call(table, action) -- luacheck: ignore 212
    if action == 'start' then
        screen_id = 1;
    elseif action == 'next' or action == 'more' then
        screen_id = screen_id + 1
    elseif action == 'prev' then
        screen_id = screen_id - 1
    elseif type(action) == 'number' and action % 1 == 0 then
        screen_id = tonumber(action)
    elseif action ~= nil then
        error('Usage: tutorial("start" | "next" | "prev" | 1 .. '..
            #doc.tutorial..')')
    end
    if screen_id < 1 then
        screen_id = 1
    elseif screen_id > #doc.tutorial then
        screen_id = #doc.tutorial
    end
    local res = doc.tutorial[screen_id]
    -- The parentheses are to discard return values except first
    -- one.
    return (res:gsub('<version>', DOCUMENTATION_VERSION))
end

setmetatable(tutorial, { __call = tutorial_call }) -- luacheck: ignore 113

return {
    help = help; -- luacheck: ignore 113
    tutorial = tutorial; -- luacheck: ignore 113
}
