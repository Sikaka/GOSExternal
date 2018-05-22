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
local LocalStringSub				= string.sub;
local LocalStringLen				= string.len;
local LocalPairs					= pairs;

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
	if forcedTarget and LocalGeometry:IsInRange(myHero.pos, forcedTarget.pos, range) then return forcedTarget end
	if isAD then		
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL);
	else
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_MAGICAL);
	end
end

function WndMsg(msg,key)
	if msg == 513 then
		local starget = nil
		local dist = 10000
		for i  = 1,LocalGameHeroCount(i) do
			local enemy = LocalGameHero(i)
			if enemy and enemy.alive and enemy.isEnemy and LocalGeometry:GetDistanceSqr(mousePos, enemy.pos) < dist then
				starget = enemy
				dist = LocalGeometry:GetDistanceSqr(mousePos, enemy.pos)
			end
		end
		if starget then
			forcedTarget = starget
		else
			forcedTarget = nil
		end
	end	
end

function EnableOrb(bool)
    if _G.EOWLoaded then
        EOW:SetMovements(bool)
        EOW:SetAttacks(bool)
    elseif _G.SDK and _G.SDK.Orbwalker then
        _G.SDK.Orbwalker:SetMovement(bool)
        _G.SDK.Orbwalker:SetAttack(bool)
    else
        GOS.BlockMovement = not bool
        GOS.BlockAttack = not bool
    end
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
		pos = myHero.pos + (pos - myHero.pos):Normalized() * 250
	end
	
	if not pos:ToScreen().onScreen then
		return
	end
		
	EnableOrb(false)
	Control.CastSpell(key, pos)
	EnableOrb(true)		
end

function EnemyCount(origin, range)
	local count = 0
	for i  = 1,LocalGameHeroCount(i) do
		local enemy = LocalGameHero(i)
		if enemy and CanTarget(enemy) and LocalGeometry:IsInRange(origin, enemy.pos, range) then
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
	LocalGeometry = _G.Alpha.Geometry
	LocalBuffManager = _G.Alpha.BuffManager
	LocalObjectManager = _G.Alpha.ObjectManager
	LocalDamageManager = _G.Alpha.DamageManager
	Callback.Add("WndMsg",function(Msg, Key) WndMsg(Msg, Key) end)
	LoadScript()
end, remaining)
Q = {Range = 1050, Radius = 80, Delay = 0.25, Speed = 1550, Collision = true}
W = {Range = 900, Radius = 250, Delay = 0.875, Speed = 99999}
E = {Range = 600, Delay = 0.25, Speed = 99999}
R = {Range = 750, Radius = 600, Delay = 0.25, Speed = 1700}

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})

	Menu.Skills:MenuElement({id = "Q", name = "[Q] Sear", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Stun", value = true})
	
	Menu.Skills:MenuElement({id = "W", name = "[W] Pillar of Flame", type = MENU})
	Menu.Skills.W:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.W:MenuElement({id = "AccuracyAuto", name = "Auto Cast Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.W:MenuElement({id = "Mana", name = "Auto Cast Mana", value = 30, min = 1, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Conflagration", type = MENU})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Auto Cast Mana", value = 15, min = 1, max = 100, step = 5 })
	Menu.Skills.E:MenuElement({id = "Targets", name = "Auto Harass Targets", type = MENU})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.E.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true, toggle = true})
		end
	end
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Pyroclasm", type = MENU})
	Menu.Skills.R:MenuElement({id = "Count", name = "Auto Cast On Enemy Count", value = 3, min = 1, max = 6, step = 1 })	
	Menu.Skills.R:MenuElement({id = "Auto", name = "Auto Cast", value = false})
	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	LocalObjectManager:OnBlink(function(target) OnBlink(target) end )
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	Callback.Add("Tick", function() Tick() end)
end

local WPos = nil
local WHitTime = 0

function OnSpellCast(spell)
	if spell.data.name == "BrandW" then
		WPos = Vector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z)
		WHitTime = LocalGameTimer() + W.Delay
	end
end


local NextTick = LocalGameTimer()
function Tick()
	if LocalGameIsChatOpen() then return end
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	
	local target = GetTarget(Q.Range)
	if target and Ready(_Q) and  CanTarget(target) and (Menu.Skills.Combo:Value() or Menu.Skills.Q.Auto:Value()) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
		if castPosition and accuracy >= Menu.Skills.Q.Accuracy:Value() then
			local timeToIntercept = LocalGeometry:GetSpellInterceptTime(myHero.pos, castPosition, Q.Delay, Q.Speed)
			if LocalBuffManager:HasBuff(target, "BrandAblaze", timeToIntercept) then
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_Q, castPosition)
				return
			elseif WHitTime > LocalGameTimer() and LocalGameTimer() + timeToIntercept >  WHitTime and LocalGeometry:IsInRange(WPos, castPosition, W.Radius) then				
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_Q, castPosition)
				return
			end
			
		end
	end
	
	local target = GetTarget(W.Range)
	if target and Ready(_W) and CanTarget(target) and (CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() or Menu.Skills.Combo:Value()) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay, W.Speed, W.Radius, W.Collision, W.IsLine)
		if accuracy >= Menu.Skills.W.AccuracyAuto:Value() or (Menu.Skills.Combo:Value() and accuracy >= Menu.Skills.W.AccuracyCombo:Value()) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_W, castPosition)
			return
		end
	end
	
	local target = GetTarget(E.Range)
	if target and Ready(_E) and Menu.Skills.E.Targets[target.networkID] and Menu.Skills.E.Targets[target.networkID]:Value() and CanTarget(target) and (CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() or Menu.Skills.Combo:Value()) then
		NextTick = LocalGameTimer() + .25
		CastSpell(HK_E, target)
		return
	end
	local target = GetTarget(R.Range)
	if target and Ready(_R) and CanTarget(target) and (Menu.Skills.Combo:Value() or Menu.Skills.R.Auto:Value())then
		local radius = R.Radius
		if LocalBuffManager:HasBuff(target, "BrandAblaze", 1) then
			radius = 725
		end
		if EnemyCount(target.pos, radius) >= Menu.Skills.R.Count:Value() then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_R, target)
			return
		end
	end
	NextTick = LocalGameTimer() + .1
end


function OnBlink(target)
	if target.isEnemy and CanTarget(target) and Ready(_W) and Menu.Skills.W.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, W.Range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay, W.Speed, W.Radius, W.Collision)
		if accuracy > 0 then
			CastSpell(HK_E, castPosition)
		end
	end
end

function OnCC(target, damage, ccType)
	if target.isEnemy and CanTarget(target) and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then
		if target.isEnemy and CanTarget(target) and Ready(_W) and Menu.Skills.W.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, W.Range) then
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay, W.Speed, W.Radius, W.Collision)
			if accuracy > 0 then
				CastSpell(HK_E, target.pos)
			end
		end
	end
end