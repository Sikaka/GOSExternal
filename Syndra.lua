local SCRIPT_VERSION = 1.16
local SCRIPT_NAME = "Sikaka Syndra";
local LIBRARY_NAME = "Bravo";
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
	if tonumber(ReadFile(SCRIPT_PATH ..SCRIPT_NAME..".version")) > Version then
		print(SCRIPT_NAME..": Found update! Downloading...")
		DownloadFile(GITHUB_PATH..SCRIPT_NAME..".lua", SCRIPT_PATH ..SCRIPT_NAME..".lua")
		print(SCRIPT_NAME..": Successfully updated. Use 2x F6!")
	end

	DownloadFile(GITHUB_PATH..LIBRARY_NAME..".version", SCRIPT_PATH .."Common/"..LIBRARY_NAME..".version")
	if tonumber(ReadFile(SCRIPT_PATH ..LIBRARY_NAME..".version")) > Version then
		print(LIBRARY_NAME..": Found library update! Downloading...")
		DownloadFile(GITHUB_PATH..LIBRARY_NAME..".lua", SCRIPT_PATH .."Common/"..LIBRARY_NAME..".lua")
		print(LIBRARY_NAME..": Successfully updated library. Use 2x F6!")
	end

	--Update prediction requirement?
end

function OnLoad()
	print("Loading "..SCRIPT_NAME.."...")
	DelayAction(function()
		JEvade:__init()
		print(SCRIPT_NAME.."successfully loaded!")
		AutoUpdate()
	end, MathMax(0.07, 30 - GameTimer()))
end


local Syndra = Class()
function Syndra:__init()
	self.NextTick = GameTimer()
	self.Data = _G.SDK.Data
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)

	self.Orbs = {}
	self.PreviousQCd = 0
	self.PreviousWState = 1
	
	self:GenerateMenu()
end

function Syndra:GenerateMenu()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Boomerang Blade", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Draw", name = "Draw Range", value = false, toggle = true })	
	Menu.Skills.Q:MenuElement({id = "Killsteal", name = "Killsteal", value = true, toggle = true })	
	Menu.Skills.Q:MenuElement({id = "AccuracyAuto", name = "Auto Accuracy Required", value = 3, drop = {"Low", "Normal", "High", "Dashing/Channeling", "Immobile", "Never"} })		
	Menu.Skills.Q:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy Required", value = 2, drop = {"Low", "Normal", "High", "Dashing/Channeling", "Immobile"} })
	Menu.Skills.Q:MenuElement({id = "Targets", name = "Auto: Allowed Target List", type = MENU})
	for i = 1, GameHeroCount() do
		local hero = GameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.Q.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true, toggle = true})
		end
	end

	Menu.Skills:MenuElement({id = "W", name = "[W] Ricochet", type = MENU})	
	Menu.Skills.W:MenuElement({id = "ManaAuto", name = "Auto: Mana for AA Reset", value = 30, min = 1, max = 101, step = 1 })
	Menu.Skills.W:MenuElement({id = "ManaCombo", name = "Combo: Mana for AA Reset", value = 10, min = 1, max = 101, step = 1 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Ricochet", type = MENU})
	Menu.Skills.E:MenuElement({id = "DangerAuto", name = "Auto: Cast on Danger Level", value = 4, min = 1, max = 6, step = 1 })
	Menu.Skills.E:MenuElement({id = "DangerCombo", name = "Combo: Cast on Danger Level", value = 1, min = 1, max = 6, step = 1 })			
end


function Syndra:Draw()	
	for _, orb in ipairs(self.Orbs) do
		if not orb or self.CurrentGameTime > orb.expiresAt then TableRemove(self.Orbs, _) end
		DrawCircle(orb.pos, 50)
	end

	if Menu.Skills.Q.Draw:Value() then
		DrawCircle(myHero.pos, self.Q.Range,1)
	end
end

function Syndra:Track_W()
	local currentWState = myHero:GetSpellData(_W).toggleState  
	if currentWState ~= self.PreviousWState then
		--we are holding 'something'
	end
	self.PreviousWState = currentWState
end

function Syndra:Track_Q()
	local currentQCd = myHero:GetSpellData(_Q).currentCd
	if currentQCd > self.PreviousQCd then
		for i = 1, GameObjectCount() do
			local obj = GameObject(i)
			if obj then
				--Get distance to mouse
				if self:GetDistance(mousePos, obj.pos) < 100 and string.find(obj.name, "_aoe_gather") then
					TableInsert(self.Orbs, {pos = obj.pos, expiresAt = self.CurrentGameTime + 6})
				end
			end
		end
	end
	self.PreviousQCd = currentQCd
end

function Syndra:Tick()
	--Cache the current game time for use in the combo logic
	self.CurrentGameTime = GameTimer()

	--Return if the script shouldn't be run
	if BlockSpells() then return end

	--If the script has set a next tick time (artificial delay) dont run logic!
	if self.NextTick > self.CurrentGameTime then return end

	self:Track_Q()
	self:Track_W()
end


function LoadScript()
	Syndra()
end

function Syndra:Distance(p1, p2)
	return MathSqrt(self:DistanceSquared(p1, p2))
end

function Syndra:DistanceSquared(p1, p2)
	return (p2.x - p1.x) ^ 2 + (p2.y - p1.y) ^ 2
end

