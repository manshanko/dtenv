local function path_parent(path)
    local len = path:find("/[^/]*$")
    local len2 = path:find("\\[^\\]*$")
    if len == nil
        or (len2 ~= nil and len2 > len)
    then
        len = len2
    end
    if len == nil or len < 1 then
        len = 0
    elseif len > 0 then
        len = len
    end
    return path:sub(1, len)
end

local shell = debug.getinfo(2) == nil or (debug.getinfo(2).source == "=[C]" and debug.getinfo(3) == nil)
local location = ...
local path = debug.getinfo(1, "S").source:sub(2)
local init
if shell or location then
    -- use require when possible

    local dir = (location and path_parent(location)) or ""
    init = require(dir .. "dtenv/init")
    require(dir .. "dtenv/stingray")
else
    -- fallback if loaded with dofile()

    local dir = path_parent(path)
    init = dofile(dir .. "dtenv/init.lua")
    dofile(dir .. "dtenv/stingray.lua")
end

if shell then
    -- started from shell

    local lua_path = os.getenv("DARKTIDE_LUA")
    if not lua_path then
        error("environment variable DARKTIDE_LUA not set")
    end
    init(lua_path)

    if arg[1] then
        local dir = path_parent(path)
        dir = dir .. "examples/"
        local examples = {
            check_damage_distribution = true,
            flamer = true,
        }

        if examples[arg[1]] then
            local file = arg[1] .. ".lua"
            dofile(dir .. file)
        else
            print("no example \"" .. arg[1] .. "\"")
            print()

            print("examples:")
            local keys = table.keys(examples)
            table.sort(keys)
            for i, k in ipairs(keys) do
                print("    " .. k)
            end
        end
    end
end

return {
    init = init,
}
