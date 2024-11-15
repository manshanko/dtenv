--[[
API stubs for loading lua from Darktide or other Stingray games.
]]--

local function file_exists(path)
    local f = io.open(path, "r")
    if f then
        io.close(f)
        return true
    else
        return false
    end
end

local old_require = require
rawset(_G, "require", function(path)
    -- old workaround, not sure if it's still necessary
    if path == "scripts/extension_systems/weapon/special_classes/weapon_special_explode_on_impact" then
        return function() end
    else
        return old_require(path)
    end
end)

local FakeString = "dtenv"
local FakeNumber = 42
local FakeFunction = function() return FakeNumber end

local lookup = {}
local FakeTable_mt
local FakeTable = function(key)
    local t = {}
    lookup[t] = key
    setmetatable(t, FakeTable_mt)
    return t
end
FakeTable_mt = {
    __index = function(t, k)
        if DEBUG_CALLS then
            if lookup[t] then
                print(lookup[t] .. " was indexed with " .. k)
                if k == "new" then
                    return FakeTable(polyfill_lookup[t] .. "." .. k)
                end
            else
                print("unknown table indexed with " .. k)
            end
        end

        return rawget(t, k) or FakeFunction
    end,
    __call = function(t)
        if DEBUG_CALLS then
            if lookup[t] then
                print(lookup[t] .. " was called")
            else
                print("unknown table called")
            end
        end

        return FakeNumber
    end
}



-- data type stubs --

Color = Color or FakeTable("Color")

Quaternion = Quaternion or FakeTable("Quaternion")
QuaternionBox = QuaternionBox or FakeTable("QuaternionBox")

Matrix4x4 = FakeFunction
Matrix4x4Box = FakeFunction

Vector2 = Vector2 or FakeTable("Vector2")

Vector3 = Vector3 or FakeTable("Vector3")
Vector3Box = Vector3Box or FakeTable("Vector3Box")

-- global stubs --

BLACKBOARDS = {}
CLASSES = {}
LEVEL_EDITOR_TEST = true
LOCAL_BACKEND_AVAILABLE = false
RESOLUTION_LOOKUP = {}
UPDATE_RESOLUTION_LOOKUP = function() end

Actor = Actor or {}

local application_settings = {
    language_id = "en",
}
Application = Application or FakeTable("Application")
Application.bundled = function() return false end
Application.argv = function() return FakeString end
Application.build = function() return "dev" end
Application.platform = function() return "win32" end
Application.settings = function(str) return application_settings end
Application.is_dedicated_server = function() return false end
Application.user_setting = function(setting) return application_settings[setting] end
Application.resolution = function()
    return 640, 480
end

callback = callback or function(t, k)
    return function(...) t[k](...) end
end

Camera = Camera or FakeTable("Camera")

cjson = cjson or FakeTable("cjson")

EngineOptimized = EngineOptimized or FakeTable("EngineOptimized")
EngineOptimized.closest_point_on_line = rawget(EngineOptimized, "closest_point_on_line") or function() return FakeNumber end

GameSession = GameSession or FakeTable("GameSession")

Gui = Gui or FakeTable("Gui")
Gui.MultiColor = rawget(Gui, "MultiColor") or FakeNumber
Gui.ForceSuperSampling = rawget(Gui, "ForceSuperSampling") or FakeNumber
Gui.FormatDirectives = rawget(Gui, "FormatDirectives") or FakeNumber
Gui.Masked = rawget(Gui, "Masked") or FakeNumber

GwNavQueries = GwNavQueries or FakeTable("GwNavQueries")

Keyboard = Keyboard or FakeTable("Keyboard")

Localizer = Localizer or FakeTable("Localizer")

-- based on "scripts/foundation/managers/managers.lua"
Managers = Managers or setmetatable({
    state = {},
    venture = {}
}, {
    __newindex = function (managers, alias, manager)
        if alias == "localizer" then
            local ret = FakeTable("Managers.localizer")
            rawset(managers, alias, ret)
        else
    		rawset(ManagersCreationOrder.global, #ManagersCreationOrder.global + 1, alias)
    		rawset(managers, alias, manager)

    		if manager and PROFILE_MANAGERS then
    			local scope_name = alias .. "_update"
    			local mt = getmetatable(manager)

    			if mt then
    				function manager.update(...)
    					local ret1, ret2, ret3 = mt.update(...)

    					return ret1, ret2, ret3
    				end
    			end
    		end
        end
	end,
	__tostring = function (managers)
		local s = "\n"

		for alias, manager in pairs(managers) do
			if type(manager) == "table" and alias ~= "state" and alias ~= "venture" then
				s = s .. "\t" .. alias .. "\n"
			end
		end

		return s
	end,
    -- end of source
    __metatable = false,
})

Math = Math or {}
Math.next_random = Math.next_random or function(seed, min, max)
    return seed, min
end

Mover = Mover or {}

Network = Network or FakeTable("Network")

PhysicsWorld = PhysicsWorld or FakeTable("PhysicsWorld")

Presence = Presense or FakeTable("Presence")

Profiler = Profiler or FakeTable("Profiler")

ResourcePackage = ResourcePackage or FakeTable("ResourcePackage")

Renderer = Renderer or FakeTable("Renderer")

RuleDatabase = RuleDatabase or FakeTable("RuleDatabase")

Script = Script or FakeTable("Script")

ShadingEnvironmentBlendMask = ShadingEnvironmentBlendMask or FakeTable("ShadingEnvironmentBlendMask")

SoundQualitySettings = SoundQualitySettings or FakeTable("SoundQualitySettings")

Steam = Steam or {}
Steam.app_id = Steam.app_id or function() return FakeNumber end
Steam.user_id = Steam.user_id or function() return FakeNumber end
Steam.user_name = Steam.user_name or function() return FakeString end
Steam.owns_app = Steam.owns_app or FakeFunction
Steam.is_installed = Steam.is_installed or function() return true end
Steam.connected = Steam.connected or FakeFunction
Steam.run_callbacks = Steam.run_callbacks or FakeFunction

SteamGameServer = SteamGameServer or FakeTable("SteamGameServer")

stingray = stingray or _G

Unit = Unit or FakeTable("Unit")

Viewport = Viewport or FakeTable("Viewport")
Viewport.get_data = rawget(Viewport, "get_data") or function() return {} end

Window = Window or FakeTable("Window")

local wget_data = {
    layer = 42
}
World = World or FakeTable("World")
World.get_data = rawget(World, "get_data") or function(t, str) return wget_data[str] or {} end

Wwise = Wwise or FakeTable("Wwise")
