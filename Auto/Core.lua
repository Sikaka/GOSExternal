local LocalGameTimer				= Game.Timer;
local LocalGameHeroCount 			= Game.HeroCount;
local LocalGameHero 				= Game.Hero;
local LocalGameMinionCount 			= Game.MinionCount;
local LocalGameMinion 				= Game.Minion;
local LocalGameTurretCount 			= Game.TurretCount;
local LocalGameTurret 				= Game.Turret;
local LocalGameWardCount 			= Game.WardCount;
local LocalGameWard 				= Game.Ward;
local LocalGameObjectCount 			= Game.ObjectCount;
local LocalGameObject				= Game.Object;
local LocalGameMissileCount 		= Game.MissileCount;
local LocalGameMissile				= Game.Missile;
local LocalGameParticleCount 		= Game.ParticleCount;
local LocalGameParticle				= Game.Particle;
local CastSpell 					= _G.Control.CastSpell
local LocalGameIsChatOpen			= Game.IsChatOpen;
local LocalGameLatency				= Game.Latency;
local LocalStringSub				= string.sub;
local LocalStringLen				= string.len;
local LocalStringFind				= string.find;
local LocalTableSort				= table.sort;
local LocalPairs					= pairs;
local LocalMathAbs					= math.abs;
local LocalMathMin					= math.min;
local LocalMathMax					= math.max;
local LocalTargetSelector			= nil;
local LocalOrbwalker				= nil;
local LocalHealthPrediction			= nil;

function StringEndsWith(str, word)
	return LocalStringSub(str, - LocalStringLen(word)) == word;
end
function Ready(spellSlot)
	return Game.CanUseSpell(spellSlot) == 0
end
	
function CurrentPctLife(entity)
	local pctLife =  entity.health/entity.maxHealth  * 100
	return pctLife
end

function CurrentPctMana(entity)
	local pctMana =  entity.mana/entity.maxMana * 100
	return pctMana
end

function CanTarget(target)
	return target and target.pos and target.isEnemy and target.alive and target.health > 0 and target.visible and target.isTargetable
end

function CanTargetAlly(target)
	return target and target.pos and target.isAlly and target.alive and target.health > 0 and target.visible and target.isTargetable
end

function GetTarget(range, isAD)
	if isAD then		
		return LocalTargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL);
	else
		return LocalTargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_MAGICAL);
	end
end

function BlockSpells()
	if LocalGameIsChatOpen() then return true end
	if LocalBuffManager:HasBuff(myHero, "recall") then return true end
	if not Game.IsOnTop() then return true end
end

function FarmActive()
	return LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] or LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] or LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR]
end

function ComboActive()
	return LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]
end

function HarassActive()
	return LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]
end


function EnableOrb(bool)
	LocalOrbwalker:SetMovement(bool)
	LocalOrbwalker:SetAttack(bool)
end

function EnableOrbAttacks(bool)   
	LocalOrbwalker:SetAttack(bool)
end


local vectorCast = {}
local mouseReturnPos = mousePos
local mouseCurrentPos = mousePos
local nextVectorCast = 0
function CastVectorSpell(key, pos1, pos2)
	if nextVectorCast > LocalGameTimer() then return end
	nextVectorCast = LocalGameTimer() + 1.5
	EnableOrb(false)
	vectorCast[#vectorCast + 1] = function () 
		mouseReturnPos = mousePos
		mouseCurrentPos = pos1
		Control.SetCursorPos(pos1)
	end
	vectorCast[#vectorCast + 1] = function () 
		Control.KeyDown(key)
	end
	vectorCast[#vectorCast + 1] = function () 
		local deltaMousePos =  mousePos-mouseCurrentPos
		mouseReturnPos = mouseReturnPos + deltaMousePos
		Control.SetCursorPos(pos2)
		mouseCurrentPos = pos2
	end
	vectorCast[#vectorCast + 1] = function ()
		Control.KeyUp(key)
	end
	vectorCast[#vectorCast + 1] = function ()	
		local deltaMousePos =  mousePos -mouseCurrentPos
		mouseReturnPos = mouseReturnPos + deltaMousePos
		Control.SetCursorPos(mouseReturnPos)
	end
	vectorCast[#vectorCast + 1] = function () 
		EnableOrb(true)
	end		
end

function CastSpell(key, pos, isLine)
	if not pos then Control.CastSpell(key) return end
	
	if type(pos) == "userdata" and pos.pos then
		pos = pos.pos
	end
	
	if not pos:ToScreen().onScreen and isLine then			
		pos = myHero.pos + (pos - myHero.pos):Normalized() * 500
	end
	
	if not pos:ToScreen().onScreen then
		return
	end
		
	EnableOrb(false)
	Control.CastSpell(key, pos)
	DelayAction(function() EnableOrb(true)	end, .1)	
	return true
end

function EnemyCount(origin, range, delay)
	local count = 0
	for i  = 1,LocalGameHeroCount(i) do
		local enemy = LocalGameHero(i)
		local enemyPos = enemy.pos
		if delay then
			enemyPos= LocalGeometry:PredictUnitPosition(enemy, delay)
		end
		if enemy and CanTarget(enemy) and LocalGeometry:IsInRange(origin, enemyPos, range) then
			count = count + 1
		end			
	end
	return count
end

function OdysseyEnemyCount(origin, range, delay)
	local count = 0
	for i  = 1,LocalGameHeroCount(i) do
		local enemy = LocalGameHero(i)
		local enemyPos = enemy.pos
		if delay then
			enemyPos= LocalGeometry:PredictUnitPosition(enemy, delay)
		end
		if enemy and CanTarget(enemy) and LocalGeometry:IsInRange(origin, enemyPos, range) then
			count = count + 1
		end			
	end
	for i  = 1,LocalGameMinionCount(i) do
		local enemy = LocalGameMinion(i)
		local enemyPos = enemy.pos
		if delay then
			enemyPos= LocalGeometry:PredictUnitPosition(enemy, delay)
		end
		if enemy and CanTarget(enemy) and LocalGeometry:IsInRange(origin, enemyPos, range) then
			count = count + 1
		end
	end
	return count
end


function NearestAlly(origin, range)
	local ally = nil
	local distance = range
	for i = 1,LocalGameHeroCount()  do
		local hero = LocalGameHero(i)
		if hero and hero ~= myHero and CanTargetAlly(hero) then
			local d =  LocalGeometry:GetDistance(origin, hero.pos)
			if d < range and d < distance then
				distance = d
				ally = hero
			end
		end
	end
	if distance < range then
		return ally, distance
	end
end

function NearestEnemy(origin, range)
	local enemy = nil
	local distance = range
	for i = 1,LocalGameHeroCount()  do
		local hero = LocalGameHero(i)
		if hero and CanTarget(hero) then
			local d =  LocalGeometry:GetDistance(origin, hero.pos)
			if d < range  and d < distance  then
				distance = d
				enemy = hero
			end
		end
	end
	if distance < range then
		return enemy, distance
	end
end

if FileExist(COMMON_PATH .. "Auto/Alpha.lua") then
	require 'Auto/Alpha'
else
	print("ERROR: Auto/Alpha.lua is not present in your Scripts/Common folder. Please re open loader.")
end

if not _G.SDK or not _G.SDK.TargetSelector then
	print("IC Orbwalker MUST be active in order to use this script.")
	return
end

local remaining = 30 - Game.Timer()
print(myHero.charName .. " will load shortly")
DelayAction(function()
	LocalTargetSelector = _G.SDK.TargetSelector
	LocalHealthPrediction = _G.SDK.HealthPrediction
	LocalOrbwalker = _G.SDK.Orbwalker
	
	LocalGeometry = _G.Alpha.Geometry
	LocalBuffManager = _G.Alpha.BuffManager
	LocalObjectManager = _G.Alpha.ObjectManager
	LocalDamageManager = _G.Alpha.DamageManager
	LoadScript()
end, remaining)
