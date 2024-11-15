--[[
Setup package.path and load expected lua modules.
]]--

return function(darktide_lua)
    if jit then
        -- Change default to increase performance (hopefully).
        --
        -- Improves speed of check_damage_distribution by a magnitude.
        jit.opt.start("maxirconst=100")
    end

    if not darktide_lua then
        error("no path to darktide lua was given")
    end

    local last = darktide_lua:sub(#darktide_lua)
    if last ~= "/" and last ~= "\\" then
        darktide_lua = darktide_lua .. "/"
    end

    DEBUG_CALLS = false

    if package.path:sub(#package.path) ~= ";" then
        print("WARNING: adding missing \";\" to end of package.path")
        package.path = package.path .. ";"
    end

    package.path = package.path .. darktide_lua .. "?.lua;"
    package.load_order = {}

    -- loaded in scripts/main.lua
    require("scripts/foundation/utilities/class")
    require("scripts/foundation/utilities/settings")
    require("scripts/foundation/utilities/table")

    -- loaded in scripts/game_states/state_require_scripts.lua
    require("scripts/foundation/utilities/math")

    -- loaded in scripts/foundation/utilities/script_unit.lua
    require("scripts/foundation/utilities/script_unit")
end
