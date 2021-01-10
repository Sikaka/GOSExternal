local SCRIPT_VERSION = 1
local SCRIPT_NAME = "Syndra";
local LIBRARY_NAME = "Bravo";
local LIBRARY_VERSION = 1
local GITHUB_PATH = "https://raw.githubusercontent.com/Sikaka/GOSExternal/master/";

local MathAbs, MathAtan, MathAtan2, MathAcos, MathCeil, MathCos, MathDeg, MathFloor, MathHuge, MathMax, MathMin, MathPi, MathRad, MathSin, MathSqrt = math.abs, math.atan, math.atan2, math.acos, math.ceil, math.cos, math.deg, math.floor, math.huge, math.max, math.min, math.pi, math.rad, math.sin, math.sqrt
local GameCanUseSpell, GameLatency, GameTimer, GameHeroCount, GameHero, GameMinionCount, GameMinion, GameMissileCount, GameMissile = Game.CanUseSpell, Game.Latency, Game.Timer, Game.HeroCount, Game.Hero, Game.MinionCount, Game.Minion, Game.MissileCount, Game.Missile
local DrawCircle, DrawColor, DrawLine, DrawText, ControlKeyUp, ControlKeyDown, ControlMouseEvent, ControlSetCursorPos = Draw.Circle, Draw.Color, Draw.Line, Draw.Text, Control.KeyUp, Control.KeyDown, Control.mouse_event, Control.SetCursorPos
local TableInsert, TableRemove, TableSort = table.insert, table.remove, table.sort

local function Class()		
	local cls = {}; cls.__index = cls		
	return setmetatable(cls, {__call = function (c, ...)		
		local instance = setmetatable({}, cls)		
		if cls.__init then cls.__init(instance, ...) end		
		return instance		
	end})		
end

local function DownloadFile(site, file)
	DownloadFileAsync(site, file, function() end)
	local timer = os.clock()
	while os.clock() < timer + 1 do end
	while not FileExist(file) do end
end

local function ReadFile(file)
	local txt = io.open(file, "r")
	local result = txt:read()
	txt:close(); return result
end

local function AutoUpdate()
	DownloadFile(GITHUB_PATH..SCRIPT_NAME..".version", SCRIPT_PATH ..SCRIPT_NAME..".version")
	if tonumber(ReadFile(SCRIPT_PATH ..SCRIPT_NAME..".version")) > SCRIPT_VERSION then
		print(SCRIPT_NAME..": Found update! Downloading...")
		DownloadFile(GITHUB_PATH..SCRIPT_NAME..".lua", SCRIPT_PATH ..SCRIPT_NAME..".lua")
		print(SCRIPT_NAME..": Successfully updated. Use 2x F6!")
	end

	DownloadFile(GITHUB_PATH..LIBRARY_NAME..".version", SCRIPT_PATH .."Common/"..LIBRARY_NAME..".version")
	if tonumber(ReadFile(SCRIPT_PATH .."Common/"..LIBRARY_NAME..".version")) > LIBRARY_VERSION then
		print(LIBRARY_NAME..": Found library update! Downloading...")
		DownloadFile(GITHUB_PATH..LIBRARY_NAME..".lua", SCRIPT_PATH .."Common/"..LIBRARY_NAME..".lua")
		print(LIBRARY_NAME..": Successfully updated library. Use 2x F6!")
	end
	Syndra()
end

function OnLoad()
	print("Loading "..SCRIPT_NAME.."...")
	DelayAction(function()
		print("Sikaka" .. SCRIPT_NAME.." loaded!")
		AutoUpdate()
	end, MathMax(0.07, 30 - GameTimer()))
end


local Syndra = Class()
function Syndra:__init()
	self.NextTick = GameTimer()
	self.Data = _G.SDK.Data
	print("SYNDRA ONLINE")
end
