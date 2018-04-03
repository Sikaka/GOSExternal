class "DPred"


--if myHero.charName ~= "Sivir" then print("Only Sivir is Supported!") return end
DANGER_LEVEL_MAXIMUM = 5
DANGER_LEVEL_HIGH = 4
DANGER_LEVEL_MEDIUM = 3
DANGER_LEVEL_SMALL = 2
DANGER_LEVEL_TINY = 1

SKILLSHOT_SORT_LINEAR = 1
SKILLSHOT_SORT_CIRCULAR = 2
SKILLSHOT_SORT_ARC = 3

SkillshotDatabase =
{
	["Ahri"] = 
	{
		["Q"] = {["Name"] = "AhriOrbofDeception", ["Missile"] = "AhriOrbMissile",  ["Danger"] = DANGER_LEVEL_MEDIUM, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = false, ["AOE"] = true},
		["W"] = {["Name"] = "AhriSeduce", ["Missile"] = "AhriSeduceMissile",  ["Danger"] = DANGER_LEVEL_MAXIMUM, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true, ["CrowdControl"] = true}
	},
	["Amumu"] = 
	{
		["Q"] = {["Name"] = "BandageToss", ["Missile"] = "SadMummyBandageToss",  ["Danger"] = DANGER_LEVEL_MAXIMUM, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true, ["CrowdControl"] = true},
	},
	["Anivia"] = 
	{
		["Q"] = {["Name"] = "FlashFrostSpell", ["Missile"] = "FlashFrostSpell",  ["Danger"] = DANGER_LEVEL_HIGH, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["AOE"] = true, ["CrowdControl"] = true},
	},
	["Ashe"] = 
	{
		["R"] = {["Name"] = "EnchantedCrystalArrow", ["Missile"] = "EnchantedCrystalArrow",  ["Danger"] = DANGER_LEVEL_MAXIMUM, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true, ["AOE"] = true, ["CrowdControl"] = true},
	},
	["AurelionSol"] = 
	{
		["Q"] = {["Name"] = "AurelionSolQ", ["Missile"] = "AurelionSolQMissile",  ["Danger"] = DANGER_LEVEL_HIGH, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true, ["AOE"] = true, ["CrowdControl"] = true},
		["R"] = {["Name"] = "AurelionSolR", ["Missile"] = "AurelionSolRBeamMissile",  ["Danger"] = DANGER_LEVEL_HIGH, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["CrowdControl"] = true},
	},
	["Bard"] = 
	{
		["Q"] = {["Name"] = "BardQ", ["Missile"] = "BardQMissile",  ["Danger"] = DANGER_LEVEL_HIGH, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true, ["CrowdControl"] = true},
	},
	["Brand"] = 
	{
		["Q"] = {["Name"] = "BrandQ", ["Missile"] = "BrandQMissile",  ["Danger"] = DANGER_LEVEL_MEDIUM, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true},
	},
	["Braum"] = 
	{
		["Q"] = {["Name"] = "BraumQ", ["Missile"] = "BraumQMissile",  ["Danger"] = DANGER_LEVEL_MEDIUM, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true, ["CrowdControl"] = true},
		["R"] = {["Name"] = "BraumRWrapper", ["Missile"] = "BraumRMissile",  ["Danger"] = DANGER_LEVEL_MEDIUM, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["CrowdControl"] = true},
	},
	["Blitzcrank"] = 
	{
		["Q"] = {["Name"] = "RocketGrab", ["Missile"] = "RocketGrabMissile",  ["Danger"] = DANGER_LEVEL_MAXIMUM, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true, ["CrowdControl"] = true}
	},
	["Caitlyn"] = 
	{
		["Q"] = {["Name"] = "CaitlynPiltoverPeacemaker", ["Missile"] = "CaitlynPiltoverPeacemaker",  ["Danger"] = DANGER_LEVEL_SMALL, ["Sort"] = SKILLSHOT_SORT_LINEAR},
		["Q2"] = {["Name"] = "CaitlynPiltoverPeacemaker2", ["Missile"] = "CaitlynPiltoverPeacemaker2",  ["Danger"] = DANGER_LEVEL_MEDIUM, ["Sort"] = SKILLSHOT_SORT_LINEAR}
	},
		
	["Lux"] = 
	{
		["Q"] = {["Name"] = "LuxLightBinding", ["Missile"] = "LuxLightBindingMis",  ["Danger"] = DANGER_LEVEL_HIGH, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true, ["CrowdControl"] = true},
	},
	
	["Morgana"] = 
	{
		["Q"] = {["Name"] = "DarkBindingMissile", ["Missile"] = "DarkBindingMissile",  ["Danger"] = DANGER_LEVEL_MAXIMUM, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true, ["CrowdControl"] = true},
	},
	["Rengar"] = 
	{
		["E"] = {["Name"] = "RengarE", ["Missile"] = "RengarEMis",  ["Danger"] = DANGER_LEVEL_MEDIUM, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true},
		["E2"] = {["Name"] = "RengarEEmp", ["Missile"] = "RengarEEmpMis",  ["Danger"] = DANGER_LEVEL_HIGH, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true, ["CrowdControl"] = true},
	},
	["Thresh"] = 
	{
		["Q"] = {["Name"] = "ThreshQ", ["Missile"] = "ThreshQMissile",  ["Danger"] = DANGER_LEVEL_MAXIMUM, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true, ["CrowdControl"] = true},
		["E"] = {["Name"] = "ThreshE", ["Missile"] = "ThreshEMissile1",  ["Danger"] = DANGER_LEVEL_MEDIUM, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["CrowdControl"] = true},
	},
	["Varus"] = 
	{
		["Q"] = {["Name"] = "VarusQ", ["Missile"] = "VarusQMissile",  ["Danger"] = DANGER_LEVEL_MEDIUM, ["Sort"] = SKILLSHOT_SORT_LINEAR},
		["R"] = {["Name"] = "VarusR", ["Missile"] = "VarusRMissile",  ["Danger"] = DANGER_LEVEL_MAXIMUM, ["Sort"] = SKILLSHOT_SORT_LINEAR, ["Collision"] = true, ["CrowdControl"] = true}
	},
}



Callback.Add("Load",
function()	

	--Load from common folder OR let us use it if its already activated as its own script
	if FileExist(COMMON_PATH .. "HPred.lua") then
		require 'HPred'
	else
		HPred()
	end	
	
	--Set up the initial menu for drawing and reaction time
	Menu = MenuElement({type = MENU, id = myHero.charName, name = "[Auto] "..myHero.charName})	
	Menu:MenuElement({id = "General", name = "General", type = MENU})
	Menu.General:MenuElement({id = "DrawQ", name = "Draw Q Range", value = false})
	Menu.General:MenuElement({id = "DrawW", name = "Draw W Range", value = false})
	Menu.General:MenuElement({id = "DrawE", name = "Draw E Range", value = false})
	Menu.General:MenuElement({id = "DrawR", name = "Draw R Range", value = false})
	Menu.General:MenuElement({id = "AutoInTurret", name = "Auto Cast While In Enemy Turret Range", value = true})
	Menu.General:MenuElement({id = "SkillFrequency", name = "Skill Frequency", value = .3, min = .1, max = 1, step = .1})
	Menu.General:MenuElement({id = "ReactionTime", name = "Reaction Time", value = .5, min = .1, max = 1, step = .1})	
	
	
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})

	Menu.Skills:MenuElement({id = "Q", name = "[Q] Boomerang Blade", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast On Immobile", value = true })
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 5, step = 1 })
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 20, min = 0, max = 10, step = 5 })

	Menu.Skills:MenuElement({id = "W", name = "[W] Ricochet", type = MENU})
	Menu.Skills.W:MenuElement({id = "Auto", name = "Auto Cast In Combo", value = true })
	Menu.Skills.W:MenuElement({id = "Mana", name = "Mana Limit", value = 10, min = 0, max = 10, step = 5 })

	Menu.Skills:MenuElement({id = "E", name = "[E] Spell Shield", type = MENU})
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Cast", value = true })
	Menu.Skills.E:MenuElement({id = "Spells", name = "Block List", type = MENU})

	for i  = 1,Game.HeroCount(i) do
		local t = Game.Hero(i)
		if t.isEnemy and SkillshotDatabase[t.charName] then		
			for _, skillshot in pairs(SkillshotDatabase[t.charName]) do
				Menu.Skills.E.Spells:MenuElement({id = skillshot.Missile, name = "[".. t.charName .. "] ".. _, value = (skillshot.Danger >= DANGER_LEVEL_MEDIUM)})		
			end
		end
	end

	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
	
	Callback.Add("Draw", function() DPred:Draw() end)
	Callback.Add("Tick", function() DPred:Tick() end)	
	
	if _G.SDK and _G.SDK.Orbwalker then
		_usePostAttack = true
		_G.SDK.Orbwalker:OnPostAttack(function(args) DPred:OnPostAttack() end)
	end
end)


function CurrentTarget(range)
	if _G.SDK then
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL);
	elseif _G.EOW then
		return _G.EOW:GetTarget(range)
	else
		return _G.GOS:GetTarget(range,"AD")
	end
end

function CurrentPctLife(entity)
	local pctLife =  entity.health/entity.maxHealth  * 100
	return pctLife
end

function CurrentPctMana(entity)
	local pctMana =  entity.mana/entity.maxMana * 100
	return pctMana
end

local _usePostAttack = false

function Ready(spellSlot)
	return Game.CanUseSpell(spellSlot) == 0
end

NextSpellCast = 0
function SpecialCast(key, pos)
	if NextSpellCast > Game.Timer() then return end	
	if pos and pos.x and not pos:To2D().onScreen then return end
	if  _G.SDK and _G.Control then
		_G.Control.CastSpell(key, pos)
	else
		Control.CastSpell(key, pos)
	end	
	NextSpellCast = Menu.General.SkillFrequency:Value() + Game.Timer()
end

function DPred:OnPostAttack()
	if Menu.Skills.Combo:Value() then 
		local currentMana = CurrentPctMana(myHero)
		if Ready(_W) and Menu.Skills.W.Auto:Value() and currentMana >= Menu.Skills.W.Mana:Value() then
			Control.CastSpell(HK_W) 
		elseif Ready(_Q) and currentMana >= Menu.Skills.Q.Mana:Value() then
			local target = CurrentTarget(1100)
			if target then				
				local hitChance, aimPosition = HPred:GetHitchance(myHero.pos, target, 1250, .25, 1350, 75, false)
				if hitChance >= Menu.Skills.Q.Accuracy:Value() then
					SpecialCast(HK_Q, aimPosition)
				end
			end
		end
	end
end

local _targetedMissiles = {}
local _activeSkillshots = {}


function DPred:Draw()
	if myHero.activeSpell and myHero.activeSpell.valid then
		--print(myHero.activeSpell.name)
	end

	local currentTime = Game.Timer()
	
	if Menu.Skills.E.Auto:Value() and Ready(_E) then
		for _, missile in pairs(_activeSkillshots) do
			if currentTime > missile.expiresAt then
				_activeSkillshots[_] = nil
			elseif missile.owner.isEnemy then		
				local leadTime = math.min(missile.expiresAt-currentTime, .125 + Game.Latency() / 2000)
				local nextPosition = missile.data.pos + missile.direction * missile.speed * leadTime
				
				--local drawPos = missile.data.pos:To2D()
				--Draw.Text(missile.data.missileData.name, 15, drawPos.x, drawPos.y)
				--Draw.Circle(nextPosition, missile.width, 10, Draw.Color(100, 255, 0,0))
				
				--Check if it will intersect with us!
				local distance = DPred:GetDistance(myHero.pos, nextPosition)	
				if distance <= missile.width *2 + myHero.boundingRadius then
					print(distance)
					Control.CastSpell(HK_E)
				end
			end
		end
	end
end

function DPred:IncomingDamage(target)
	local currentTime = Game.Timer()
	local totalDamage = 0
	for _, missile in pairs(_targetedMissiles) do
		--Need a better way to determine if a missle still exists... this shouldn't be needed....		
		if missile.data.name ~= missile.name or missile.lastSeen -currentTime > .5 then
			_targetedMissiles[_] = nil
		elseif missile.target.networkID == target.networkID then
			totalDamage = totalDamage + missile.damage
		end
	end	
	return totalDamage
end


function DPred:Tick()
	local currentTime = Game.Timer()
	for i = 1, Game.MissileCount() do
		local missile = Game.Missile(i)
		
		if not _activeSkillshots[missile.networkID] and missile.missileData.target == 0 then
			local owner =  self:GetObjectByHandle(missile.missileData.owner)
			if owner and owner.isEnemy then
				--Check if its in our menu and turned on				
				if Menu.Skills.E.Spells[missile.missileData.name] and Menu.Skills.E.Spells[missile.missileData.name]:Value() then
					_activeSkillshots[missile.networkID] = {}
					_activeSkillshots[missile.networkID].owner = owner
					_activeSkillshots[missile.networkID].data = missile
					_activeSkillshots[missile.networkID].direction = Vector(missile.missileData.endPos.x -missile.missileData.startPos.x,missile.missileData.endPos.y -missile.missileData.startPos.y,missile.missileData.endPos.z -missile.missileData.startPos.z):Normalized()
					_activeSkillshots[missile.networkID].speed = missile.missileData.speed
					_activeSkillshots[missile.networkID].width = missile.missileData.width
					_activeSkillshots[missile.networkID].expiresAt = Game.Timer() + self:GetDistance(missile.missileData.startPos, missile.missileData.endPos) / missile.missileData.speed
				end		
			end
		end
		
		if not _activeSkillshots[missile.networkID] and missile.missileData.target > 0 then
			local target =  self:GetObjectByHandle(missile.missileData.owner)
			if target.networkID == myHero.networkID then
				print(missile.missileData.name)
			end
		end
		--if _targetedMissiles[missile.networkID] and _targetedMissiles[missile.networkID].data.name == missile.name then	
		--	_targetedMissiles[missile.networkID].lastSeen = currentTime
		--elseif string.match(missile.missileData.name, "BasicAttack") then
		--	local owner =  self:GetObjectByHandle(missile.missileData.owner)
		--	local target =  self:GetObjectByHandle(missile.missileData.target)			
		--	if owner and target and missile.missileData then
		--		_targetedMissiles[missile.networkID] = {}		
		--		_targetedMissiles[missile.networkID].lastSeen = currentTime	
		--		_targetedMissiles[missile.networkID].data = missile
		--		_targetedMissiles[missile.networkID].name = missile.missileData.name
		--		_targetedMissiles[missile.networkID].owner = owner
		--		_targetedMissiles[missile.networkID].target = target
		--		_targetedMissiles[missile.networkID].damage = self:CalculatePhysicalDamage(target, owner.totalDamage)				
		--	end
		--end
	end
	
	--Cast Q on immobile enemies
	if Menu.Skills.Q.Auto:Value() and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() then
	--(source, range, delay, speed, timingAccuracy, checkCollision, radius)
		local target, aimPosition =HPred:GetImmobileTarget(myHero.pos, 1250,.25, 1350,.25)
		if target and aimPosition then
			SpecialCast(HK_Q, aimPosition)
		end
	end	
end

function DPred:GetDistanceSqr(p1, p2)	
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function DPred:GetDistance(p1, p2)
	return math.sqrt(self:GetDistanceSqr(p1, p2))
end

function DPred:CalculatePhysicalDamage(target, damage)			
	local targetArmor = target.armor * myHero.armorPenPercent - myHero.armorPen
	local damageReduction = 100 / ( 100 + targetArmor)
	if targetArmor < 0 then
		damageReduction = 2 - (100 / (100 - targetArmor))
	end		
	damage = damage * damageReduction	
	return damage
end


function DPred:GetObjectByHandle(handle)
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.handle == handle then
			target = enemy
			return target
		end
	end
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion.handle == handle then
			target = minion
			return target
		end
	end
	
	for i = 1, Game.WardCount() do
		local ward = Game.Ward(i);
		if ward.handle == handle then
			target = ward
			return target
		end
	end
	
	for i = 1, Game.TurretCount() do
		local turret = Game.Turret(i);
		if turret.handle == handle then
			target = turret
			return target
		end
	end
	
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		if particle.handle == handle then
			target = particle
			return target
		end
	end
end




class "HPred"

Callback.Add("Tick", function() HPred:Tick() end)

local _reviveQueryFrequency = .2
local _lastReviveQuery = Game.Timer()
local _reviveLookupTable = 
	{ 
		["LifeAura.troy"] = 4, 
		["ZileanBase_R_Buf.troy"] = 3,
		["Aatrox_Base_Passive_Death_Activate"] = 3
		
		--TwistedFate_Base_R_Gatemarker_Red
			--String match would be ideal.... could be different in other skins
	}

--Stores a collection of spells that will cause a character to blink
	--Ground targeted spells go towards mouse castPos with a maximum range
	--Hero/Minion targeted spells have a direction type to determine where we will land relative to our target (in front of, behind, etc)
	
--Key = Spell name
--Value = range a spell can travel, OR a targeted end position type, OR a list of particles the spell can teleport to	
local _blinkSpellLookupTable = 
	{ 
		["EzrealArcaneShift"] = 475, 
		["RiftWalk"] = 500,
		
		--Ekko and other similar blinks end up between their start pos and target pos (in front of their target relatively speaking)
		["EkkoEAttack"] = 0,
		["AlphaStrike"] = 0,
		
		--Katarina E ends on the side of her target closest to where her mouse was... 
		["KatarinaE"] = -255,
		
		--Katarina can target a dagger to teleport directly to it: Each skin has a different particle name. This should cover all of them.
		["KatarinaEDagger"] = { "Katarina_Base_Dagger_Ground_Indicator","Katarina_Skin01_Dagger_Ground_Indicator","Katarina_Skin02_Dagger_Ground_Indicator","Katarina_Skin03_Dagger_Ground_Indicator","Katarina_Skin04_Dagger_Ground_Indicator","Katarina_Skin05_Dagger_Ground_Indicator","Katarina_Skin06_Dagger_Ground_Indicator","Katarina_Skin07_Dagger_Ground_Indicator" ,"Katarina_Skin08_Dagger_Ground_Indicator","Katarina_Skin09_Dagger_Ground_Indicator"  }, 
	}

local _blinkLookupTable = 
	{ 
		"global_ss_flash_02.troy",
		"Lissandra_Base_E_Arrival.troy",
		"LeBlanc_Base_W_return_activation.troy"
		--TODO: Check if liss/leblanc have diff skill versions. MOST likely dont but worth checking for completion sake
		
		--Zed uses 'switch shadows'... It will require some special checks to choose the shadow he's going TO not from...
		--Shaco deceive no longer has any particles where you jump to so it cant be tracked (no spell data or particles showing path)
		
	}

local _cachedRevives = {}
local _cachedTeleports = {}
local _movementHistory = {}

function HPred:Tick()
	--Check for revives and record them	
	if Game.Timer() - _lastReviveQuery < _reviveQueryFrequency then return end
	_lastReviveQuery=Game.Timer()
	
	--Remove old cached revives
	for _, revive in pairs(_cachedRevives) do
		if Game.Timer() > revive.expireTime + .5 then
			_cachedRevives[_] = nil
		end
	end
	
	--Cache new revives
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		if not _cachedRevives[particle.networkID] and  _reviveLookupTable[particle.name] then
			_cachedRevives[particle.networkID] = {}
			_cachedRevives[particle.networkID]["expireTime"] = Game.Timer() + _reviveLookupTable[particle.name]			
			local target = self:GetHeroByPosition(particle.pos)
			if target.isEnemy then				
				_cachedRevives[particle.networkID]["target"] = target
				_cachedRevives[particle.networkID]["pos"] = target.pos
				_cachedRevives[particle.networkID]["isEnemy"] = target.isEnemy	
			end
		end
	end
	
	--Update hero movement history	
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		self:UpdateMovementHistory(t)
	end
	
	--Remove old cached teleports	
	for _, teleport in pairs(_cachedTeleports) do
		if Game.Timer() > teleport.expireTime + .5 then
			_cachedTeleports[_] = nil
		end
	end	
	
	--Update teleport cache
	self:CacheTeleports()
	
	
end

function HPred:GetEnemyNexusPosition()
	--This is slightly wrong. It represents fountain not the nexus. Fix later.
	if myHero.team == 100 then return Vector(14340, 171.977722167969, 14390); else return Vector(396,182.132507324219,462); end
end


function HPred:GetReliableTarget(source, range, delay, speed, radius, timingAccuracy, checkCollision)
	--TODO: Target whitelist. This will target anyone which is definitely not what we want
	--For now we can handle in the champ script. That will cause issues with multiple people in range who are goood targets though.
	
	
	--Get hourglass enemies
	target, aimPosition =self:GetHourglassTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get reviving target
	target, aimPosition =self:GetRevivingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get channeling enemies
	target, aimPosition =self:GetChannelingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
		if target and aimPosition then
		return target, aimPosition
	end
	
	--Get teleporting enemies
	target, aimPosition =self:GetTeleportingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)	
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get instant dash enemies
	target, aimPosition =self:GetInstantDashTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end	
	
	--Get dashing enemies
	target, aimPosition =self:GetDashingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius, midDash)
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get stunned enemies
	local target, aimPosition =self:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get blink targets
	--target, aimPosition =self:GetBlinkTarget(source, range, speed, delay, checkCollision, radius)
	--if target and aimPosition then
	--	return target, aimPosition
	--end	
end

--Will return how many allies or enemies will be hit by a linear spell based on current waypoint data.
function HPred:GetLineTargetCount(source, aimPos, delay, speed, width, targetAllies)
	local targetCount = 0
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if self:CanTargetALL(t) and ( targetAllies or t.isEnemy) then
			local predictedPos = self:PredictUnitPosition(t, delay+ self:GetDistance(source, t.pos) / speed)
			if predictedPos:To2D().onScreen then
				local proj1, pointLine, isOnSegment = self:VectorPointProjectionOnLineSegment(source, aimPos, predictedPos)
				if proj1 and isOnSegment and (self:GetDistanceSqr(predictedPos, proj1) <= (t.boundingRadius + width) ^ 2) then
					targetCount = targetCount + 1
				end
			end
		end
	end
	return targetCount
end

--Will return the valid target who has the highest hit chance and meets all conditions (minHitChance, whitelist check, etc)
function HPred:GetUnreliableTarget(source, range, delay, speed, radius, checkCollision, minimumHitChance, whitelist)
	local _validTargets = {}
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if self:CanTarget(t) and (not whitelist or whitelist[t.charName]) then			
			local hitChance, aimPosition = self:GetHitchance(source, t, range, delay, speed, radius, checkCollision)		
			if hitChance >= minimumHitChance and aimPosition:To2D().onScreen then
				_validTargets[t.charName] = {["hitChance"] = hitChance, ["aimPosition"] = aimPosition}
			end
		end
	end
	
	local rHitChance = 0
	local rAimPosition
	for targetName, targetData in pairs(_validTargets) do
		if targetData.hitChance > rHitChance then
			rHitChance = targetData.hitChance
			rAimPosition = targetData.aimPosition
		end		
	end
	
	if rHitChance >= minimumHitChance then
		return rHitChance, rAimPosition
	end	
end

function HPred:GetHitchance(source, target, range, delay, speed, radius, checkCollision)	
	local hitChance = 1	
	
	local aimPosition = self:PredictUnitPosition(target, delay + self:GetDistance(source, target.pos) / speed)	
	local interceptTime = self:GetSpellInterceptTime(source, aimPosition, delay, speed)
	local reactionTime = self:PredictReactionTime(target, .1)
	
	--If they just now changed their path then assume they will keep it for at least a short while... slightly higher chance
	if _movementHistory and _movementHistory[target.charName] and Game.Timer() - _movementHistory[target.charName]["ChangedAt"] < .25 then
		hitChance = 2
	end

	--If they are standing still give a higher accuracy because they have to take actions to react to it
	if not target.pathing or not target.pathing.hasMovePath then
		hitChance = 2
	end	
	
	
	local origin,movementRadius = self:UnitMovementBounds(target, interceptTime, reactionTime)
	--Our spell is so wide or the target so slow or their reaction time is such that the spell will be nearly impossible to avoid
	if movementRadius - target.boundingRadius <= radius /2 then
		origin,movementRadius = self:UnitMovementBounds(target, interceptTime, 0)
		if movementRadius - target.boundingRadius <= radius /2 then
			hitChance = 4
		else		
			hitChance = 3
		end
	end	
	
	--If they are casting a spell then the accuracy will be fairly high. if the windup is longer than our delay then it's quite likely to hit. 
	--Ideally we would predict where they will go AFTER the spell finishes but that's beyond the scope of this prediction
	if target.activeSpell and target.activeSpell.valid then
		if target.activeSpell.startTime + target.activeSpell.windup - Game.Timer() >= delay then
			hitChance = 5
		else			
			hitChance = 3
		end
	end
	
	--Check for out of range
	if self:GetDistance(myHero.pos, aimPosition) >= range then
		hitChance = -1
	end
	
	--Check minion block
	if hitChance > 0 and checkCollision then	
		if self:CheckMinionCollision(source, aimPosition, delay, speed, radius) then
			hitChance = -1
		end
	end
	
	return hitChance, aimPosition
end

function HPred:PredictReactionTime(unit, minimumReactionTime)
	local reactionTime = minimumReactionTime
	
	--If the target is auto attacking increase their reaction time by .15s - If using a skill use the remaining windup time
	if unit.activeSpell and unit.activeSpell.valid then
		local windupRemaining = unit.activeSpell.startTime + unit.activeSpell.windup - Game.Timer()
		if windupRemaining > 0 then
			reactionTime = windupRemaining
		end
	end
	
	--If the target is recalling and has been for over .25s then increase their reaction time by .25s
	local isRecalling, recallDuration = self:GetRecallingData(unit)	
	if isRecalling and recallDuration > .25 then
		reactionTime = .25
	end
	
	return reactionTime
end

function HPred:GetDashingTarget(source, range, delay, speed, dashThreshold, checkCollision, radius, midDash)

	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if t.isEnemy and t.pathing.hasMovePath and t.pathing.isDashing and t.pathing.dashSpeed>500  then
			local dashEndPosition = t:GetPath(1)
			if self:GetDistance(source, dashEndPosition) <= range  and dashEndPosition:To2D().onScreen then				
				--The dash ends within range of our skill. We now need to find if our spell can connect with them very close to the time their dash will end
				local dashTimeRemaining = self:GetDistance(t.pos, dashEndPosition) / t.pathing.dashSpeed
				local skillInterceptTime = self:GetSpellInterceptTime(myHero.pos, dashEndPosition, delay, speed)
				local deltaInterceptTime =skillInterceptTime - dashTimeRemaining
				if deltaInterceptTime > 0 and deltaInterceptTime < dashThreshold and (not checkCollision or not self:CheckMinionCollision(source, dashEndPosition, delay, speed, radius)) then
					target = t
					aimPosition = dashEndPosition
					return target, aimPosition
				end
			end			
		end
	end
end

function HPred:GetHourglassTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if t.isEnemy and t.pos:To2D().onScreen then		
			local success, timeRemaining = self:HasBuff(t, "zhonyasringshield")
			if success then
				local spellInterceptTime = self:GetSpellInterceptTime(myHero.pos, t.pos, delay, speed)
				local deltaInterceptTime = spellInterceptTime - timeRemaining
				if spellInterceptTime > timeRemaining and deltaInterceptTime < timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
					target = t
					aimPosition = t.pos
					return target, aimPosition
				end
			end
		end
	end
end

function HPred:GetRevivingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for _, revive in pairs(_cachedRevives) do	
		if revive.isEnemy and revive.pos:To2D().onScreen then
			local interceptTime = self:GetSpellInterceptTime(source, revive.pos, delay, speed)
			if interceptTime > revive.expireTime - Game.Timer() and interceptTime - revive.expireTime - Game.Timer() < timingAccuracy then
				target = revive.target
				aimPosition = revive.pos
				return target, aimPosition
			end
		end
	end	
end

function HPred:GetInstantDashTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if t.isEnemy and t.activeSpell and t.activeSpell.valid and _blinkSpellLookupTable[t.activeSpell.name] then
			local windupRemaining = t.activeSpell.startTime + t.activeSpell.windup - Game.Timer()
			if windupRemaining > 0 then
				local endPos
				local blinkRange = _blinkSpellLookupTable[t.activeSpell.name]
				if type(blinkRange) == "table" then
					--Find the nearest matching particle to our mouse
					--local target, distance = self:GetNearestParticleByNames(t.pos, blinkRange)
					--if target and distance < 250 then					
					--	endPos = target.pos		
					--end
				elseif blinkRange > 0 then
					endPos = Vector(t.activeSpell.placementPos.x, t.activeSpell.placementPos.y, t.activeSpell.placementPos.z)					
					endPos = t.activeSpell.startPos + (endPos- t.activeSpell.startPos):Normalized() * math.min(self:GetDistance(t.activeSpell.startPos,endPos), range)
				else
					local blinkTarget = self:GetObjectByHandle(t.activeSpell.target)
					if blinkTarget then				
						local offsetDirection						
						
						--We will land in front of our target relative to our starting position
						if blinkRange == 0 then						
							offsetDirection = (blinkTarget.pos - t.pos):Normalized()
						--We will land behind our target relative to our starting position
						elseif blinkRange == -1 then						
							offsetDirection = (t.pos-blinkTarget.pos):Normalized()
						--They can choose which side of target to come out on , there is no way currently to read this data so we will only use this calculation if the spell radius is large
						elseif blinkRange == -255 then
							if radius > 250 then
								endPos = blinkTarget.pos
							end							
						end
						
						if offsetDirection then
							endPos = blinkTarget.pos - offsetDirection * 150
						end
						
					end
				end	
				
				local interceptTime = self:GetSpellInterceptTime(myHero.pos, endPos, delay,speed)
				local deltaInterceptTime = interceptTime - windupRemaining
				if self:GetDistance(source, endPos) <= range and endPos:To2D().onScreen and deltaInterceptTime < timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, endPos, delay, speed, radius)) then
					target = t
					aimPosition = endPos
					return target,aimPosition					
				end
			end
		end
	end
end

function HPred:GetBlinkTarget(source, range, speed, delay, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		if particle and _blinkLookupTable[particle.name] and self:GetDistance(source, particle.pos) < range and particle.pos:To2D().onScreen then
			local pPos = particle.pos
			for k,v in pairs(self:GetEnemyHeroes()) do
				local t = v
				if t and t.isEnemy and self:GetDistance(t.pos, pPos) < t.boundingRadius then
					if (not checkCollision or not self:CheckMinionCollision(source, pPos, delay, speed, radius)) then
						target = t
						aimPosition = pPos
						return target,aimPosition
					end
				end
			end
		end
	end
end

function HPred:GetChannelingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		local interceptTime = self:GetSpellInterceptTime(myHero.pos, t.pos, delay, speed)
		if self:CanTarget(t) and self:GetDistance(source, t.pos) <= range and t.pos:To2D().onScreen and self:IsChannelling(t, interceptTime) and (not checkCollision or not self:CheckMinionCollision(source, t.pos, delay, speed, radius)) then
			target = t
			aimPosition = t.pos	
			return target, aimPosition
		end
	end
end

function HPred:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if self:CanTarget(t) and self:GetDistance(source, t.pos) <= range and t.pos:To2D().onScreen then
			local immobileTime = self:GetImmobileTime(t)
			
			local interceptTime = self:GetSpellInterceptTime(source, t.pos, delay, speed)
			if immobileTime - interceptTime > timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, t.pos, delay, speed, radius)) then
				target = t
				aimPosition = t.pos
				return target, aimPosition
			end
		end
	end
end

function HPred:RecordTeleport(target, aimPos, endTime)
	_cachedTeleports[target.networkID] = {}
	_cachedTeleports[target.networkID]["target"] = target
	_cachedTeleports[target.networkID]["aimPos"] = aimPos
	_cachedTeleports[target.networkID]["expireTime"] = endTime + Game.Timer()
end

function HPred:CacheTeleports()
	--Get enemies who are teleporting to towers
	for i = 1, Game.TurretCount() do
		local turret = Game.Turret(i);
		if turret.isEnemy and not _cachedTeleports[turret.networkID] then
			local hasBuff, expiresAt = self:HasBuff(turret, "teleport_target")
			if hasBuff then
				self:RecordTeleport(turret, self:GetTeleportOffset(turret.pos,223.31),expiresAt)
			end
		end
	end	
	
	--Get enemies who are teleporting to wards	
	for i = 1, Game.WardCount() do
		local ward = Game.Ward(i);
		if ward.isEnemy and not _cachedTeleports[ward.networkID] then
			local hasBuff, expiresAt = self:HasBuff(ward, "teleport_target")
			if hasBuff then
				self:RecordTeleport(ward, self:GetTeleportOffset(ward.pos,100.01),expiresAt)
			end
		end
	end
	
	--Get enemies who are teleporting to minions
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i);
		if minion.isEnemy and not _cachedTeleports[minion.networkID] then
			local hasBuff, expiresAt = self:HasBuff(minion, "teleport_target")
			if hasBuff then
				self:RecordTeleport(minion, self:GetTeleportOffset(minion.pos,143.25),expiresAt)
			end
		end
	end	
end

function HPred:GetTeleportingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)

	local target
	local aimPosition
	for _, teleport in pairs(_cachedTeleports) do
		if teleport.expireTime > Game.Timer() and self:GetDistance(source, teleport.aimPos) <= range and teleport.aimPos:To2D().onScreen then			
			local spellInterceptTime = self:GetSpellInterceptTime(source, teleport.aimPos, delay, speed)
			local teleportRemaining = teleport.expireTime - Game.Timer()
			if spellInterceptTime > teleportRemaining and spellInterceptTime - teleportRemaining <= timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, teleport.aimPos, delay, speed, radius)) then								
				target = teleport.target
				aimPosition = teleport.aimPos
				return target, aimPosition
			end
		end
	end		
end

function HPred:GetTargetMS(target)
	local ms = target.pathing.isDashing and target.pathing.dashSpeed or target.ms
	return ms
end

function HPred:Angle(A, B)
	local deltaPos = A - B
	local angle = math.atan2(deltaPos.x, deltaPos.z) *  180 / math.pi	
	if angle < 0 then angle = angle + 360 end
	return angle
end

function HPred:UpdateMovementHistory(unit)
	if not _movementHistory[unit.charName] then
		_movementHistory[unit.charName] = {}
		_movementHistory[unit.charName]["EndPos"] = unit.pathing.endPos
		_movementHistory[unit.charName]["StartPos"] = unit.pathing.endPos
		_movementHistory[unit.charName]["PreviousAngle"] = 0
		_movementHistory[unit.charName]["ChangedAt"] = Game.Timer()
	end
	
	if _movementHistory[unit.charName]["EndPos"].x ~=unit.pathing.endPos.x or _movementHistory[unit.charName]["EndPos"].y ~=unit.pathing.endPos.y or _movementHistory[unit.charName]["EndPos"].z ~=unit.pathing.endPos.z then				
		_movementHistory[unit.charName]["PreviousAngle"] = self:Angle(Vector(_movementHistory[unit.charName]["StartPos"].x, _movementHistory[unit.charName]["StartPos"].y, _movementHistory[unit.charName]["StartPos"].z), Vector(_movementHistory[unit.charName]["EndPos"].x, _movementHistory[unit.charName]["EndPos"].y, _movementHistory[unit.charName]["EndPos"].z))
		_movementHistory[unit.charName]["EndPos"] = unit.pathing.endPos
		_movementHistory[unit.charName]["StartPos"] = unit.pos
		_movementHistory[unit.charName]["ChangedAt"] = Game.Timer()
	end
	
end

--Returns where the unit will be when the delay has passed given current pathing information. This assumes the target makes NO CHANGES during the delay.
function HPred:PredictUnitPosition(unit, delay)
	local predictedPosition = unit.pos
	local timeRemaining = delay
	local pathNodes = self:GetPathNodes(unit)
	for i = 1, #pathNodes -1 do
		local nodeDistance = self:GetDistance(pathNodes[i], pathNodes[i +1])
		local nodeTraversalTime = nodeDistance / self:GetTargetMS(unit)
			
		if timeRemaining > nodeTraversalTime then
			--This node of the path will be completed before the delay has finished. Move on to the next node if one remains
			timeRemaining =  timeRemaining - nodeTraversalTime
			predictedPosition = pathNodes[i + 1]
		else
			local directionVector = (pathNodes[i+1] - pathNodes[i]):Normalized()
			predictedPosition = pathNodes[i] + directionVector *  self:GetTargetMS(unit) * timeRemaining
			break;
		end
	end
	return predictedPosition
end

function HPred:IsChannelling(target, interceptTime)
	if target.activeSpell and target.activeSpell.valid and target.activeSpell.isChanneling then
		return true
	end
end

function HPred:HasBuff(target, buffName, minimumDuration)
	local duration = minimumDuration
	if not minimumDuration then
		duration = 0
	end
	local durationRemaining
	for i = 1, target.buffCount do 
		local buff = target:GetBuff(i)
		if buff.duration > duration and buff.name == buffName then
			durationRemaining = buff.duration
			return true, durationRemaining
		end
	end
end

--Moves an origin towards the enemy team nexus by magnitude
function HPred:GetTeleportOffset(origin, magnitude)
	local teleportOffset = origin + (self:GetEnemyNexusPosition()- origin):Normalized() * magnitude
	return teleportOffset
end

function HPred:GetSpellInterceptTime(startPos, endPos, delay, speed)	
	local interceptTime = Game.Latency()/2000 + delay + self:GetDistance(startPos, endPos) / speed
	return interceptTime
end

--Checks if a target can be targeted by abilities or auto attacks currently.
--CanTarget(target)
	--target : gameObject we are trying to hit
function HPred:CanTarget(target)
	return target.isEnemy and target.alive and target.visible and target.isTargetable
end

--Derp: dont want to fuck with the isEnemy checks elsewhere. This will just let us know if the target can actually be hit by something even if its an ally
function HPred:CanTargetALL(target)
	return target.alive and target.visible and target.isTargetable
end

--Returns a position and radius in which the target could potentially move before the delay ends. ReactionTime defines how quick we expect the target to be able to change their current path
function HPred:UnitMovementBounds(unit, delay, reactionTime)
	local startPosition = self:PredictUnitPosition(unit, delay)
	
	local radius = 0
	local deltaDelay = delay -reactionTime- self:GetImmobileTime(unit)	
	if (deltaDelay >0) then
		radius = self:GetTargetMS(unit) * deltaDelay	
	end
	return startPosition, radius	
end

--Returns how long (in seconds) the target will be unable to move from their current location
function HPred:GetImmobileTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.count > 0 and buff.duration> duration and (buff.type == 5 or buff.type == 8 or buff.type == 21 or buff.type == 22 or buff.type == 24 or buff.type == 11 or buff.type == 29 or buff.type == 30 or buff.type == 39 ) then
			duration = buff.duration
		end
	end
	return duration		
end

--Returns how long (in seconds) the target will be slowed for
function HPred:GetSlowedTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.count > 0 and buff.duration > duration and buff.type == 10 then
			duration = buff.duration			
			return duration
		end
	end
	return duration		
end

--Returns all existing path nodes
function HPred:GetPathNodes(unit)
	local nodes = {}
	table.insert(nodes, unit.pos)
	if unit.pathing.hasMovePath then
		for i = unit.pathing.pathIndex, unit.pathing.pathCount do
			path = unit:GetPath(i)
			table.insert(nodes, path)
		end
	end		
	return nodes
end

--Finds any game object with the correct handle to match (hero, minion, wards on either team)
function HPred:GetObjectByHandle(handle)
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.handle == handle then
			target = enemy
			return target
		end
	end
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion.handle == handle then
			target = minion
			return target
		end
	end
	
	for i = 1, Game.WardCount() do
		local ward = Game.Ward(i);
		if ward.handle == handle then
			target = ward
			return target
		end
	end
	
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		if particle.handle == handle then
			target = particle
			return target
		end
	end
end

function HPred:GetHeroByPosition(position)
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
end

function HPred:GetObjectByPosition(position)
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
	
	for i = 1, Game.MinionCount() do
		local enemy = Game.Minion(i)
		if enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
	
	for i = 1, Game.WardCount() do
		local enemy = Game.Ward(i);
		if enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
	
	for i = 1, Game.ParticleCount() do 
		local enemy = Game.Particle(i)
		if enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
end

function HPred:GetEnemyHeroByHandle(handle)	
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.handle == handle then
			target = enemy
			return target
		end
	end
end

--Finds the closest particle to the origin that is contained in the names array
function HPred:GetNearestParticleByNames(origin, names)
	local target
	local distance = math.max
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		local d = self:GetDistance(origin, particle.pos)
		if d < distance then
			distance = d
			target = particle
		end
	end
	return target, distance
end

--Returns the total distance of our current path so we can calculate how long it will take to complete
function HPred:GetPathLength(nodes)
	local result = 0
	for i = 1, #nodes -1 do
		result = result + self:GetDistance(nodes[i], nodes[i + 1])
	end
	return result
end


--I know this isn't efficient but it works accurately... Leaving it for now.
function HPred:CheckMinionCollision(origin, endPos, delay, speed, radius, frequency)
		
	if not frequency then
		frequency = radius
	end
	local directionVector = (endPos - origin):Normalized()
	local checkCount = self:GetDistance(origin, endPos) / frequency
	for i = 1, checkCount do
		local checkPosition = origin + directionVector * i * frequency
		local checkDelay = delay + self:GetDistance(origin, checkPosition) / speed
		if self:IsMinionIntersection(checkPosition, radius, checkDelay, radius * 3) then
			return true
		end
	end
	return false
end


function HPred:IsMinionIntersection(location, radius, delay, maxDistance)
	if not maxDistance then
		maxDistance = 500
	end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if self:CanTarget(minion) and self:GetDistance(minion.pos, location) < maxDistance then
			local predictedPosition = self:PredictUnitPosition(minion, delay)
			if self:GetDistance(location, predictedPosition) <= radius + minion.boundingRadius then
				return true
			end
		end
	end
	return false
end

function HPred:VectorPointProjectionOnLineSegment(v1, v2, v)
	assert(v1 and v2 and v, "VectorPointProjectionOnLineSegment: wrong argument types (3 <Vector> expected)")
	local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
	local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
	local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
	local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	local isOnSegment = rS == rL
	local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
	return pointSegment, pointLine, isOnSegment
end


function HPred:GetRecallingData(unit)
	for K, Buff in pairs(GetBuffs(unit)) do
		if Buff.name == "recall" and Buff.duration > 0 then
			return true, Game.Timer() - Buff.startTime
		end
	end
	return false
end

function HPred:GetEnemyByName(name)
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.isEnemy and enemy.charName == name then
			target = enemy
			return target
		end
	end
end

function HPred:IsPointInArc(source, origin, target, angle, range)
	local deltaAngle = math.abs(HPred:Angle(origin, target) - HPred:Angle(source, origin))
	if deltaAngle < angle and self:GetDistance(origin, target) < range then
		return true
	end
end

function HPred:GetEnemyHeroes()
	local _EnemyHeroes = {}
  	for i = 1, Game.HeroCount() do
    	local enemy = Game.Hero(i)
    	if enemy and enemy.isEnemy then
	  		table.insert(_EnemyHeroes, enemy)
  		end
  	end
  	return _EnemyHeroes
end

function HPred:GetDistanceSqr(p1, p2)	
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function HPred:GetDistance(p1, p2)
	return math.sqrt(self:GetDistanceSqr(p1, p2))
end
