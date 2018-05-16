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


function GetTarget(range)
	if forcedTarget and LocalGeometry:IsInRange(myHero.pos, forcedTarget.pos, range) then return forcedTarget end
	return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_MAGICAL);
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

if FileExist(COMMON_PATH .. "Auto/Alpha.lua") then
	require 'Auto/Alpha'
else
	print("ERROR: Auto/Alpha.lua is not present in your Scripts/Common folder. Please re open loader.")
end

local remaining = 30 - Game.Timer()
print(myHero.charName .. " will load shortly")
DelayAction(function()
	LocalGeometry = _G.Alpha.Geometry
	LocalBuffManager = _G.Alpha.BuffManager
	LocalObjectManager = _G.Alpha.ObjectManager
	LocalDamageManager = _G.Alpha.DamageManager
	LocalDamageManager:InitializeCallbacks()
	Callback.Add("WndMsg",function(Msg, Key) WndMsg(Msg, Key) end)
	LoadScript()
end, remaining)Q = {Range = 1075, Radius = 50,Delay = 0.25, Speed = 1200, Collision = true}
W = {Range = 1075, Radius = 120,Delay = 0.25, Speed = 1400}
E = {Range = 1100, Radius = 310,Delay = 0.25, Speed = 1200}
R = {Range = 3340, Radius = 110, Delay = 1, Speed = 999999}
	

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Light Binding", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })	
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })	
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Prismatic Barrier", type = MENU})
	Menu.Skills.W:MenuElement({id = "Damage", name = "Recent Damage Received", value = 15, min = 5, max = 60, step = 5 })
	Menu.Skills.W:MenuElement({id = "Count", name = "Minimum Targets", value = 1, min = 1, max = 6, step = 1 })
	Menu.Skills.W:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
		
	Menu.Skills:MenuElement({id = "E", name = "[E] Lucent Singularity", type = MENU})
	Menu.Skills.E:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })
	Menu.Skills.E:MenuElement({id = "Targets", name = "Burst Targets", type = MENU})	
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.E.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true })
		end
	end
	Menu.Skills.E:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
		
	Menu.Skills:MenuElement({id = "R", name = "[R] Final Spark", type = MENU})	
	Menu.Skills.R:MenuElement({id = "Count", name = "Combo Target Count", tooltip = "How many targets we need to be able to hit to auto cast", value = 2, min = 1, max = 6, step = 1 })	
	Menu.Skills.R:MenuElement({id = "Killsteal", name = "Auto Killsteal", value = true, toggle = true })
	Menu.Skills.R:MenuElement({id = "Targets", name = "Burst Targets", type = MENU})	
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.R.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true })
		end
	end
		
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	LocalObjectManager:OnBlink(function(target) OnBlink(target) end )
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	Callback.Add("Tick", function() Tick() end)
end

local EPos = nil
local EExpiresAt = 0

function OnSpellCast(spell)
	if spell.data.name == "LuxLightStrikeKugel" then
		EPos = Vector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z)
		EExpiresAt = LocalGameTimer() + 5
	end
end


local NextTick = LocalGameTimer()
function Tick()
	if LocalGameIsChatOpen() then return end
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end	
	if EPos and EExpiresAt> currentTime  then
		DetonateE()
	end
	
	--Check for killsteal or target count R
	if Ready(_R) and Menu.Skills.R.Killsteal:Value() then
		local rDamage= 200 + (myHero:GetSpellData(_R).level) * 100 + myHero.ap * 0.75
		for i = 1, LocalGameHeroCount() do
			local target = LocalGameHero(i)
			if CanTarget(target) and LocalGeometry:IsInRange(myHero.pos, target.pos, R.Range) then
				
				local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, R.Range, R.Delay, R.Speed, R.Radius, R.Collision, R.IsLine)
				if castPosition and accuracy > 0  then					
					local thisRDamage = rDamage
					if LocalBuffManager:HasBuff(target, "LuxIlluminatingFraulein",R.Delay) then
						thisRDamage = thisRDamage + 20 + myHero.levelData.lvl * 10 + myHero.ap * 0.2
					end
					local predictedHealth = target.health + target.hpRegen * R.Delay					
					thisRDamage = LocalDamageManager:CalculateMagicDamage(myHero,target, thisRDamage)
					if predictedHealth > 0 and thisRDamage > predictedHealth then
						NextTick = LocalGameTimer() + .25
						CastSpell(HK_R, castPosition, true)
						return
					end
				end
			end
		end
	end
	
	if Menu.Skills.Combo:Value() then
		local target = GetTarget(Q.Range)
		if target and CanTarget(target) then
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, R.Range, R.Delay, R.Speed, R.Radius, R.Collision, R.IsLine)
			if castPosition and LocalGeometry:IsInRange(myHero.pos, castPosition, R.Range) then
				if accuracy > 1 then
					local endPosition = myHero.pos + (castPosition-myHero.pos):Normalized() * R.Range
					local targetCount = LocalGeometry:GetLineTargetCount(myHero.pos, endPosition, R.Delay, R.Speed, R.Radius)
					if targetCount >= Menu.Skills.R.Count:Value() then
						NextTick = LocalGameTimer() + .25
						CastSpell(HK_R, castPosition)
						return
					end
				end
			end
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
			if castPosition and accuracy >= Menu.Skills.Q.Accuracy:Value() and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_Q, castPosition)
				return
			end	
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay, E.Speed, E.Radius, E.Collision, E.IsLine)
			if castPosition and accuracy >= Menu.Skills.E.Accuracy:Value() and LocalGeometry:IsInRange(myHero.pos, castPosition, E.Range) then
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_E, castPosition)
				return
			end	
		end
	end
	NextTick = LocalGameTimer() + .1
end


function DetonateE()
	local eData = myHero:GetSpellData(_E)
	if eData.toggleState == 2 then
		for i = 1, LocalGameHeroCount() do
			local target = LocalGameHero(i)
			if CanTarget(target) and LocalGeometry:IsInRange(EPos, target.pos, E.Radius) then
				if Menu.Skills.E.Targets[target.networkID] and Menu.Skills.E.Targets[target.networkID]:Value() then
					CastSpell(HK_E)
					EExpiresAt = 0
					break
				else
					local nextPosition = LocalGeometry:PredictUnitPosition(target, .1)
					if not LocalGeometry:IsInRange(EPos, nextPosition, E.Radius) then
						CastSpell(HK_E)
						EExpiresAt = 0
						break
					end
				end
			end
		end
	end
end

function OnBlink(target)
	if target.isEnemy and CanTarget(target) and Ready(_Q) and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision)
		if accuracy > 0 then
			CastSpell(HK_Q, target.pos,true)
		end	
	end
	if target.isEnemy and CanTarget(target) and Ready(_E) and Menu.Skills.E.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay, E.Speed, E.Radius, E.Collision)
		if accuracy > 0 then
			CastSpell(HK_E, target.pos)
		end	
	end
end

function OnCC(target, damage, ccType)
	if target.isAlly and Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, W.Range) then
		--if ally is myself then find a nearby ally to shield, if none in range then we should shield in the direction we're running to return it faster
		CastSpell(HK_W)
	end
	
	if target.isEnemy and CanTarget(target) and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then
		
		if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_Q, target.pos,true)
			return
		end
		
		if Ready(_E) and CanTarget(target) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() and Menu.Skills.E.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
			NextTick = LocalGameTimer() +.25
			CastSpell(HK_E, target.pos)
			return
		end
	end
end