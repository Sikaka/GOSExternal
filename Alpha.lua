if _G.Alpha then return end
_G.Alpha = 
{
	Geometry = nil,
	ObjectManager = nil,
	DamageManager = nil,
	ItemManager = nil,
	BuffManager = nil,
}

local LocalVector					= Vector;
local LocalCallbackAdd				= Callback.Add;
local LocalCallbackDel				= Callback.Del;
local LocalGameTimer				= Game.Timer;
local LocalGameHeroCount 			= Game.HeroCount;
local LocalGameHero					= Game.Hero;
local LocalGameMinionCount 			= Game.MinionCount;
local LocalGameMinion				= Game.Minion;
local LocalGameParticleCount 		= Game.ParticleCount;
local LocalGameParticle				= Game.Particle;
local LocalGameMissileCount 		= Game.MissileCount;
local LocalGameMissile				= Game.Missile;
local LocalPairs 					= pairs;
local LocalType						= type;

local LocalStringFind				= string.find

local LocalInsert					= table.insert
local LocalSort						= table.sort

local LocalSqrt						= math.sqrt
local LocalAtan2					= math.atan2
local LocalAbs						= math.abs
local LocalHuge						= math.huge
local LocalPi						= math.pi
local LocalMax						= math.max
local LocalMin						= math.min
local LocalFloor					= math.floor


local DAMAGE_TYPE_TRUE				= 0
local DAMAGE_TYPE_PHYSICAL			= 1
local DAMAGE_TYPE_MAGICAL 			= 2



local BUFF_STUN						= 5
local BUFF_SILENCE					= 7
local BUFF_TAUNT					= 8
local BUFF_SLOW						= 10
local BUFF_ROOT						= 11
local BUFF_FEAR						= 21
local BUFF_CHARM					= 22
local BUFF_POISON					= 23
local BUFF_SURPRESS					= 24
local BUFF_BLIND					= 25
local BUFF_KNOCKUP					= 29
local BUFF_KNOCKBACK				= 30
local BUFF_DISARM					= 31



local TARGET_TYPE_SINGLE			= 0
local TARGET_TYPE_LINE				= 1
local TARGET_TYPE_CIRCLE			= 2
local TARGET_TYPE_ARC				= 3
local TARGET_TYPE_BOX				= 4


local Geometry = nil
local ObjectManager = nil
local DamageManager = nil
local ItemManager = nil
local BuffManager = nil

class "__Geometry"

function __Geometry:VectorPointProjectionOnLineSegment(v1, v2, v)
	assert(v1 and v2 and v, "VectorPointProjectionOnLineSegment: wrong argument types (3 <Vector> expected)")
	local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
	local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
	local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
	local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	local isOnSegment = rS == rL
	local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
	return pointSegment, pointLine, isOnSegment
end

function __Geometry:GetDistanceSqr(p1, p2)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		print("Undefined GetDistanceSqr target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return LocalHuge
	end
	return (p1.x - p2.x) *  (p1.x - p2.x) + ((p1.z or p1.y) - (p2.z or p2.y)) * ((p1.z or p1.y) - (p2.z or p2.y)) 
end

function __Geometry:GetDistance(p1, p2)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		print("Undefined GetDistance target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return LocalHuge
	end
	return LocalSqrt(self:GetDistanceSqr(p1, p2))
end

function __Geometry:IsPointInArc(source, origin, target, angle, range)
	local deltaAngle = LocalAbs(self:Angle(origin, target) - self:Angle(source, origin))
	print(deltaAngle)
	if deltaAngle < angle and self:IsInRange(origin,target,range) then
		return true
	end
	return false
end

function __Geometry:Angle(A, B)
	local deltaPos = A - B
	local angle = LocalAtan2(deltaPos.x, deltaPos.z) *  180 / LocalPi	
	if angle < 0 then angle = angle + 360 end
	return angle
end

function __Geometry:IsInRange(p1, p2, range)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		print("Undefined IsInRange target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return false
	end
	return (p1.x - p2.x) *  (p1.x - p2.x) + ((p1.z or p1.y) - (p2.z or p2.y)) * ((p1.z or p1.y) - (p2.z or p2.y)) < range * range 
end

function __Geometry:GetCastPosition(source, target, range, delay, speed, radius, checkCollision)
	local hitChance = 1
	if not self:IsInRange(source.pos, target.pos, range) then hitChance = -1 end
	if hitChance > 0 then
		local aimPosition = self:PredictUnitPosition(target, delay + self:GetDistance(source.pos, target.pos) / speed)	
		local interceptTime = self:GetSpellInterceptTime(source.pos, aimPosition, delay, speed)
		
		if not target.pathing or not target.pathing.hasMovePath then
			hitChance = 2
		end
		
		--Leaving all the stun/slow/dash logic out for now. Not important
	
		if checkCollision then
			if self:CheckMinionCollision(source.pos, aimPosition, delay, speed, radius) then
				hitChance = -1
			end
		end
	end
	
	return aimPosition, hitChance	
end

function __Geometry:GetSpellInterceptTime(startPos, endPos, delay, speed)	
	local interceptTime = Game.Latency()/2000 + delay + self:GetDistance(startPos, endPos) / speed
	return interceptTime
end

function __Geometry:CheckMinionCollision(origin, endPos, delay, speed, radius, frequency)
		
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

function __Geometry:IsMinionIntersection(location, radius, delay, maxDistance)
	if not maxDistance then
		maxDistance = 500
	end
	for i = 1, LocalGameMinionCount() do
		local minion = LocalGameMinion(i)
		if minion and self:CanTarget(minion) and self:IsInRange(minion.pos, location, maxDistance) then
			local predictedPosition = self:PredictUnitPosition(minion, delay)
			if self:IsInRange(location, predictedPosition, radius + minion.boundingRadius) then
				return true
			end
		end
	end
	return false
end

function __Geometry:CanTarget(target, allowInvisible)
	return target.isEnemy and target.alive and target.health > 0 and target.visible and target.isTargetable
end

--Returns where the unit will be when the delay has passed given current pathing information. This assumes the target makes NO CHANGES during the delay.
function __Geometry:PredictUnitPosition(unit, delay)
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

--Returns all existing path nodes
function __Geometry:GetPathNodes(unit)
	local nodes = {}
	LocalInsert(nodes, unit.pos)
	if unit.pathing.hasMovePath then
		for i = unit.pathing.pathIndex, unit.pathing.pathCount do
			path = unit:GetPath(i)
			LocalInsert(nodes, path)
		end
	end		
	return nodes
end

function __Geometry:GetTargetMS(target)
	local ms = target.pathing.isDashing and target.pathing.dashSpeed or target.ms
	return ms
end


class "__ObjectManager"
--Initialize the object manager
function __ObjectManager:__init()
	LocalCallbackAdd('Tick',  function() self:Tick() end)
	
	self.CachedMissiles = {}	
	self.OnMissileCreateCallbacks = {}
	self.OnMissileDestroyCallbacks = {}
	
	self.CachedParticles = {}
	self.OnParticleCreateCallbacks = {}
	self.OnParticleDestroyCallbacks = {}
	
	self.OnBlinkCallbacks = {}	
	self.BlinkParticleLookupTable = 
	{
		"global_ss_flash_02.troy",
		"Lissandra_Base_E_Arrival.troy",
		"LeBlanc_Base_W_return_activation.troy",
		"Zed_Base_CloneSwap",
	}
	
	self.CachedSpells = {}
	self.OnSpellCastCallbacks = {}
end

--Register Missile Create Event
function __ObjectManager:OnMissileCreate(cb)
	LocalInsert(ObjectManager.OnMissileCreateCallbacks, cb)
end

--Trigger Missile Create Event
function __ObjectManager:MissileCreated(missile)
	for i = 1, #self.OnMissileCreateCallbacks do
		self.OnMissileCreateCallbacks[i](missile);
	end
end

--Register Missile Destroy Event
function __ObjectManager:OnMissileDestroy(cb)
	LocalInsert(ObjectManager.OnMissileDestroyCallbacks, cb)
end

--Trigger Missile Destroyed Event
function __ObjectManager:MissileDestroyed(missile)
	for i = 1, #self.OnMissileDestroyCallbacks do
		self.OnMissileDestroyCallbacks[i](missile);
	end
end

--Register Particle Create Event
function __ObjectManager:OnParticleCreate(cb)
	LocalInsert(ObjectManager.OnParticleCreateCallbacks, cb)
end

--Trigger Particle Created Event
function __ObjectManager:ParticleCreated(particle)
	--print("particle: " .. particle.name)
	for i = 1, #self.OnParticleCreateCallbacks do
		self.OnParticleCreateCallbacks[i](particle);
	end
end

--Register Particle Destroy Event
function __ObjectManager:OnParticleDestroy(cb)
	LocalInsert(ObjectManager.OnParticleDestroyCallbacks, cb)
end

--Trigger particle Destroyed Event
function __ObjectManager:ParticleDestroyed(particle)
	for i = 1, #self.OnParticleDestroyCallbacks do
		self.OnParticleDestroyCallbacks[i](particle);
	end
end

--Register On Blink Event
function __ObjectManager:OnBlink(cb)
	--If there are no on particle callbacks we need to add one or it might never run!
	if #self.OnBlinkCallbacks == 0 then		
		self:OnParticleCreate(function(particle) self:CheckIfBlinkParticle(particle) end)
	end
	LocalInsert(ObjectManager.OnBlinkCallbacks, cb)
end

--Trigger Blink Event
function __ObjectManager:Blinked(target)
	for i = 1, #self.OnBlinkCallbacks do
		self.OnBlinkCallbacks[i](target);
	end
end

--Register On Spell Cast Event
function __ObjectManager:OnSpellCast(cb)
	LocalInsert(ObjectManager.OnSpellCastCallbacks, cb)
end

--Trigger Spell Cast Event
function __ObjectManager:SpellCast(data)
	for i = 1, #self.OnSpellCastCallbacks do
		self.OnSpellCastCallbacks[i](data);
	end
end

local lookupTable = {"one", "two", "three", "four", "five"}

--Search for changes in particle or missiles in game. trigger the appropriate events.
function __ObjectManager:Tick()	
	if #self.OnSpellCastCallbacks > 0 then
		for i = 1, LocalGameHeroCount() do
			local target = LocalGameHero(i)
			if target and LocalType(target) == "userdata" then				
    
				if target.activeSpell and target.activeSpell.valid then
					if not self.CachedSpells[target.networkID] or self.CachedSpells[target.networkID].name ~= target.activeSpell.name then
						local spellData = {owner = target.networkID, handle = target.handle, name = target.activeSpell.name, data = target.activeSpell, windupEnd = target.activeSpell.startTime + target.activeSpell.windup}
						self.CachedSpells[target.networkID] =spellData
						self:SpellCast(spellData)
					end
				elseif self.CachedSpells[target.networkID] then
					self.CachedSpells[target.networkID] = nil
				end
			end
		end
	end

	--Cache Particles ONLY if a create or destroy event is registered: If not it's a waste of processing
	if #self.OnParticleCreateCallbacks > 0 or #self.OnParticleDestroyCallbacks > 0 then
		for _, particle in LocalPairs(self.CachedParticles) do
			if not particle or not particle.valid then
				if particle then					
					self:ParticleDestroyed(particle)
				end
				self.CachedParticles[_] = nil
			else
				particle.valid = false
			end
		end	
		
		for i = 1, LocalGameParticleCount() do 
			local particle = LocalGameParticle(i)
			if particle ~= nil and LocalType(particle) == "userdata" then
				if self.CachedParticles[particle.networkID] then
					self.CachedParticles[particle.networkID].valid = true
				else
					local particleData = { valid = true, pos = particle.pos, name = particle.name}
					self.CachedParticles[particle.networkID] =particleData
					self:ParticleCreated(particleData)
				end
			end
		end		
	end
	
	--Cache Missiles ONLY if a create or destroy event is registered: If not it's a waste of processing
	if #self.OnMissileCreateCallbacks > 0 or #self.OnMissileDestroyCallbacks > 0 then
		for _, missile in LocalPairs(self.CachedMissiles) do
			if not missile or not missile.data or not missile.valid then
				if missile and missile.data then
					self:MissileDestroyed(missile)
				end
				self.CachedMissiles[_] = nil
			else		
				missile.valid = false
			end
		end	
		
		for i = 1, LocalGameMissileCount() do 
			local missile = LocalGameMissile(i)
			if missile ~= nil and LocalType(missile) == "userdata" and missile.missileData then
				if self.CachedMissiles[missile.networkID] then
					self.CachedMissiles[missile.networkID].valid = true
				else
					--We need a direct reference to the missile so we can query its current position later. If not we'd have to calculate it using speed/start/end data
					local missileData = 
					{ 
						valid = true,
						name = missile.name,
						forward = Vector(
							missile.missileData.endPos.x -missile.missileData.startPos.x,
							missile.missileData.endPos.y -missile.missileData.startPos.y,
							missile.missileData.endPos.z -missile.missileData.startPos.z):Normalized(),
						networkID = missile.networkID,
						data = missile,
						
						endTime = LocalGameTimer() + Geometry:GetDistance(missile.missileData.endPos, missile.missileData.startPos) / missile.missileData.speed,
					}
					self.CachedMissiles[missile.networkID] =missileData
					self:MissileCreated(missileData)
				end
			end
		end
	end
end

function __ObjectManager:CheckIfBlinkParticle(particle)
	if table.contains(self.BlinkParticleLookupTable,particle.name) then
		local target = self:GetPlayerByPosition(particle.pos)
		if target then 
			self:Blinked(target)
		end
	end
end

--Lets us find a particle's owner because the particle and the player will have the same position (IE: Flash)
function __ObjectManager:GetPlayerByPosition(position)
	for i = 1, LocalGameHeroCount() do
		local target = LocalGameHero(i)
		if target and target.pos and Geometry:IsInRange(position, target.pos,50) then
			return target
		end
	end
end

function __ObjectManager:GetObjectByHandle(handle)
	for i = 1, LocalGameHeroCount() do
		local target = LocalGameHero(i)
		if target and target.handle == handle then
			return target
		end
	end
	for i = 1, LocalGameMinionCount() do
		local target = LocalGameMinion(i)
		if target and target.handle == handle then
			return target
		end
	end
end

class "__DamageManager"
--Credits LazyXerath for extra dmg reduction methods
function __DamageManager:__init()


	self.IMMOBILE_TYPES = {[BUFF_KNOCKUP]="true",[BUFF_SURPRESS]="true",[BUFF_ROOT]="true",[BUFF_STUN]="true"}
	ObjectManager:OnMissileCreate(function(args) self:MissileCreated(args) end)
	ObjectManager:OnMissileDestroy(function(args) self:MissileDestroyed(args) end)
	
	self.OnIncomingCCCallbacks = {}
	
	self.SiegeMinionList = {"Red_Minion_MechCannon", "Blue_Minion_MechCannon"}
	self.NormalMinionList = {"Red_Minion_Wizard", "Blue_Minion_Wizard", "Red_Minion_Basic", "Blue_Minion_Basic"}
	self.DamageReductionTable = 
	{
	  ["Braum"] = {buff = "BraumShieldRaise", amount = function(target) return 1 - ({0.3, 0.325, 0.35, 0.375, 0.4})[target:GetSpellData(_E).level] end},
	  ["Urgot"] = {buff = "urgotswapdef", amount = function(target) return 1 - ({0.3, 0.4, 0.5})[target:GetSpellData(_R).level] end},
	  ["Alistar"] = {buff = "Ferocious Howl", amount = function(target) return ({0.5, 0.4, 0.3})[target:GetSpellData(_R).level] end},
	  ["Galio"] = {buff = "GalioIdolOfDurand", amount = function(target) return 0.5 end},
	  ["Garen"] = {buff = "GarenW", amount = function(target) return 0.7 end},
	  ["Gragas"] = {buff = "GragasWSelf", amount = function(target) return ({0.1, 0.12, 0.14, 0.16, 0.18})[target:GetSpellData(_W).level] end},
	  ["Annie"] = {buff = "MoltenShield", amount = function(target) return 1 - ({0.16,0.22,0.28,0.34,0.4})[target:GetSpellData(_E).level] end},
	  ["Malzahar"] = {buff = "malzaharpassiveshield", amount = function(target) return 0.1 end}
	}
	
	self.AlliedHeroes = {}
	self.AlliedDamage = {}
	
	self.EnemyHeroes = {}
	self.EnemyDamage = {}
	
	for i = 1, Game.HeroCount() do
		local target = Game.Hero(i)
		if target.isAlly then
			self.AlliedDamage[target.handle] = {}
			self.AlliedHeroes[target.handle] = target
		else
			self.EnemyDamage[target.handle] = {}
			self.EnemyHeroes[target.handle] = target
		end
	end
	
	
	--Stores the missile instances of active skillshots
	self.EnemySkillshots = {}
	self.AlliedSkillshots = {}
		
	--Simple table for missile names we want to track
	self.MissileNames = {}
	
	--Simple table for particles we want to track
	self.ParticleNames = {}
	
	--Simple table for skills we want to track
	self.Skills = {}
	
	--Master lookup table. NOT WHAT IS USED FOR ACTUAL MATCHING. It's used for loading
	self.MasterSkillLookupTable =
	{	
		--[AATROX SKILLS]--
		--AatroxQ can't be handled properly. It's dealt with using a BUFF (to make him untargetable I guess) AatroxQDescent triggers when he's attacking
		["AatroxQ"] = 
		{
			HeroName = "Aatrox", 
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 275,
			Damage = {25,50,80,110,150},
			ADScaling = 1.10,
			Danger = 3,			
		},
		["AatroxE"] = 
		{
			HeroName = "Aatrox", 
			SpellSlot = _Q,
			MissileName = "AatroxEConeMissile",
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 120,
			Damage = {80,120,160,200,240},
			ADScaling = .7,
			Danger = 2,
			CCType = BUFF_SLOW,
		},
		["AatroxR"] = 
		{
			HeroName = "Aatrox", 
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 550,
			Damage = {200,300,400},
			APScaling = 1.0,
			Danger = 3,			
		},
		--[AHRI SKILLS]--
		["AhriOrbofDeception"] = 
		{
			HeroName = "Ahri",
			SpellName = "Orb of Deception",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGIC,
			TargetType = TARGET_TYPE_LINE,
			Radius = 80,
			Damage = {40,65,90,115,140},
			APScaling = .35,
			Danger = 2,
		},
		["AhriFoxFire"] = 
		{
			HeroName = "Ahri", 
			SpellName = "Fox-Fire",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGIC,
			TargetType = TARGET_TYPE_SINGLE,
			MissileName = "AhriFoxFireMissileTwo",
			Damage = {40,65,90,115,140},
			APScaling = .3,
			Danger = 1,	
		},
		["AhriSeduce"] = 
		{
			HeroName = "Ahri", 
			SpellName = "Charm",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGIC,
			TargetType = TARGET_TYPE_LINE,
			Collision = 1,
			Radius = 80,
			Damage = {60,90,120,150,180},
			APScaling = .4,
			Danger = 4,
			CCType = BUFF_CHARM,
		},
		["AhriTumble"] = 
		{
			HeroName = "Ahri", 
			SpellName = "Spirit Rush",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGIC,
			TargetType = TARGET_TYPE_SINGLE,
			MissileName = "AhriTumbleMissile",
			Damage = {60,90,120},
			APScaling = .35,
			Danger = 2,		
		},
		
		--[AKALI SKILLS]--
		["AkaliMota"] = 
		{
			HeroName = "Akali",
			SpellName = "Mark of the Assassin",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGIC,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {35,55,75,95,115},
			APScaling = .4,
			Danger = 1,
		},
		["AkaliShadowSwipe"] = 
		{
			HeroName = "Akali", 
			SpellName = "Crescent Slash",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGIC,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 300,
			Damage = {70,100,130,160,190},
			ADScaling = .8,
			APScaling = .6,
			Danger = 2,	
		},
		["AkaliShadowDance"] = 
		{
			HeroName = "Akali", 
			SpellName = "Shadow Dance",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGIC,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {50,100,150},
			APScaling = .35,
			Danger = 2,		
		},
		
		--[ALISTAR SKILLS]--
		["Pulverize"] = 
		{
			HeroName = "Alistar",
			SpellName = "Pulverize",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGIC,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 365,
			Damage = {60,105,150,195,240},
			APScaling = .5,
			Danger = 4,
			CCType = BUFF_KNOCKUP,
		},
		["Headbut"] = 
		{
			HeroName = "Alistar", 
			SpellName = "Headbut",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGIC,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {50,110,165,220,275},
			APScaling = .7,
			Danger = 4,
			CCType = BUFF_KNOCKBACK
		},
		
		--[AMUMU SKILLS]--
		["BandageToss"] = 
		{
			HeroName = "Amumu",
			SpellName = "Bandage Toss",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGIC,
			TargetType = TARGET_TYPE_LINE,
			Collision = 1,
			Radius = 70,
			Damage = {80,130,180,230,280},
			APScaling = .7,
			Danger = 4,
			CCType = BUFF_STUN,
		},
		["Tantrum"] = 
		{
			HeroName = "Amumu", 
			SpellName = "Tantrum",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGIC,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 350,
			Damage = {75,100,125,150,175},
			APScaling = .5,
			Danger = 1,
		},
		["CurseoftheSadMummy"] = 
		{
			HeroName = "Amumu",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 550,					
			Damage = {150,250,350},
			APScaling = .8,
			Danger = 5,
			CCType = BUFF_ROOT,
		},
		
		
		--[ANIVIA SKILLS]--
		["FlashFrost"] = 
		{
			HeroName = "Anivia",
			SpellName = "Flash Frost",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGIC,
			TargetType = TARGET_TYPE_LINE,
			Radius = 225,
			Damage = {60,85,110,135,160},
			APScaling = .4,
			Danger = 3,
			--Stun is on detonate. We cant 'block' the stun portion with external so wait for the buff to be added for cleanse instead
		},
		
		["Frostbite"] = 
		{
			HeroName = "Anivia", 
			SpellName = "Frostbite",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL, 
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {50,75,100,125,150},
			APScaling = .5,
			BuffScaling = 2.0,
			BuffName = "aniviaiced",
			Danger = 3,
		},
		
		["GlacialStorm"] = 
		{
			HeroName = "Anivia",
			SpellName = "Glacial Storm",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 400,					
			Damage = {40,60,80},
			APScaling = .125,
			Danger = 1,
			CCType = BUFF_SLOW,
		},		
		
		--[ANNIE SKILLS]--
		["Disintegrate"] = 
		{
			HeroName = "Annie", 
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,						
			Damage = {80,115,150,185,220},
			APScaling = .8,
			Danger = 3,
			
			--Not necessary because it's a targeted ability. I've left it in because it can let us calculate time until the missile hits us (better shields!)
			MissileName = "Disintegrate",
		},
		["Incinerate"] = 
		{
			HeroName = "Annie", 
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_ARC,						
			Damage = {70,115,160,205,250},
			APScaling = .85,
			Danger = 3,
		},
		["InfernalGuardian"] = 
		{
			HeroName = "Annie",
			SpellName = "Tibbers",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 290,					
			Damage = {150,275,400},
			APScaling = .65,
			Danger = 5,
		},
		
		--[ASHE SKILLS]--
		["Volley"] = 
		{
			HeroName = "Ashe", 
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			MissileName = "VolleyAttack",
			Radius = 20,
			Collision = 1,
			Damage = {25,35,50,65,80},
			ADScaling = 1.0,
			Danger = 1,
		},
		["EnchantedCrystalArrow"] = 
		{
			HeroName = "Ashe", 
			SpellName = "Enchanted Crystal Arrow",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			MissileName = "EnchantedCrystalArrow",
			Radius = 125,
			Collision = 1,
			Damage = {200,400,600},
			APScaling = 1.0,
			Danger = 5,
		},
		
		--[AURELION SOL SKILLS]--
		["AurelionSolQ"] = 
		{
			HeroName = "AurelionSol",
			SpellName = "Starsurge",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			MissileName = "AurelionSolQMissile",
			Radius = 210,
			Damage = {70,110,150,190,230},
			APScaling = .65,
			Danger = 3,
		},
		["AurelionSolR"] = 
		{
			HeroName = "AurelionSol", 
			SpellName = "Voice of Light",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 120,
			Damage = {150,250,250},
			APScaling = .7,
			CCType = BUFF_KNOCKBACK,
			Danger = 4,
		},
		
		--[BARD SKILLS]--
		["BardQ"] = 
		{
			HeroName = "Bard",
			SpellName = "Cosmic Binding",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Collision = 2,
			MissileName = "BardQMissile",
			Radius = 80,
			Damage = {70,110,150,190,230},
			APScaling = .65,
			Danger = 3,
		},
		["BardR"] = 
		{
			HeroName = "Bard", 
			SpellName = "Tempered Fate",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 350,
			CCType = BUFF_STASIS,
			Danger = 4,
		},
		
		--[BLITZCRANK SKILLS]--
		["RocketGrab"] = 
		{
			HeroName = "Blitzcrank",
			SpellName = "Rocket Grab",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Collision = 1,
			MissileName = "RocketGrabMissile",
			Radius = 60,
			Damage = {80,135,190,245,300},
			APScaling = 1.0,
			Danger = 5,
			CCType = BUFF_STUN
		},
		["StaticField"] = 
		{
			HeroName = "Blitzcrank", 
			SpellName = "Static Field",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			CCType = BUFF_SILENCE,
			Radius = 600,
			Damage = {250,375,500},
			APScaling = 1.0,
			Danger = 3,
		},
		
		
		--[BRAND SKILLS]--
		["BrandQ"] = 
		{
			HeroName = "Brand", 
			SpellName = "Sear",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Collision = 1,
			
			MissileName = "BrandQMissile",
			
			--This is optional and used to calculate current damage target will take. Ideally we'd have it for every skill but not necessary!
			Damage = {80,110,140,170,200},
			APScaling = .55,
			Danger = 3,
		},
		
		["BrandW"] = 
		{
			HeroName = "Brand", 
			SpellName = "Pillar of Flame",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 250,
			
			--This is optional and used to calculate current damage target will take. Ideally we'd have it for every skill but not necessary!
			Damage = {75,120,165,210,255},
			APScaling = .6,
			Danger = 3,
			
			--Damage is multiplied by 1.5 when the target has BrandAblaze buff applied. This is OPTIONAL but appreciated for accuracy
			BuffScaling = 1.5,
			BuffName = "BrandAblaze",
		},
		["BrandE"] = 
		{
			HeroName = "Brand", 
			SpellName = "Conflagration",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,						
			Damage = {70,90,110,130,150},
			APScaling = .35,
			Danger = 2,			
		},
		
		["BrandR"] = 
		{
			HeroName = "Brand", 
			SpellName = "Conflagration",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			MissileName = {"BrandR","BrandRMissile"},
			Damage = {100,200,300},
			APScaling = .25,
			Danger = 4,
		},
		
		--[BRAUM SKILLS]--
		["BraumQ"] = 
		{
			HeroName = "Braum",
			SpellName = "Winter's Bite",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Collision = 1,
			MissileName = "BraumQMissile",
			Radius = 60,
			Damage = {60,105,150,195,240},
			Danger = 2,
			CCType = BUFF_SLOW
		},
		["BraumRWrapper"] = 
		{
			HeroName = "Braum", 
			SpellName = "Glacial Fissure",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			MissileName = "BraumRMissile",
			Radius = 115,
			Damage = {150,250,350},
			APScaling = .6,
			Danger = 4,
			CCType = BUFF_KNOCKUP,
		},
		
		--[CAITLYN SKILLS]--
		
		["CaitlynPiltoverPeacemaker"] = 
		{
			HeroName = "Caitlyn",
			SpellName = "Piltover Peacemaker",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 90,			
			MissileName = {"CaitlynPiltoverPeacemaker","CaitlynPiltoverPeacemaker2"},
			Damage = {30,70,110,150,190},
			APScaling = 1.5,
			Danger = 2,
		},
		["CaitlynYordleTrap"] = 
		{
			HeroName = "Caitlyn",
			SpellName = "Yordle Snap Trap",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 75,
			Danger = 2,
		},
		["CaitlynEntrapment"] = 
		{
			HeroName = "Caitlyn",
			SpellName = "90 Caliber Net",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGIC,
			TargetType = TARGET_TYPE_LINE,
			Radius = 60,
			MissileName = "CaitlynEntrapmentMissile",
			Damage = {70,110,150,190,230},
			APScaling = .8,
			Danger = 3,
			CCType = BUFF_SLOW,
		},
		["CaitlynAceintheHole"] = 
		{
			HeroName = "Caitlyn",
			SpellName = "Ace in the Hole",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			MissileName = "CaitlynAceintheHoleMissile",
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {250,475,700},
			ADScaling = 2.0,
			Danger = 3,
		},
		--[Camille Skills]--
		--She has no active spell data or player targeted missiles... its all player statuses and auto attack modifiers/buffs...
		
		--[CASSIOPEIA SKILLS]--
		
		["CassiopeiaQ"] = 
		{
			HeroName = "Cassiopeia",
			SpellName = "Noxious Blast",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 150,					
			Damage = {24,40,55,70,85},
			APScaling = .2333,
			Danger = 2,
		},
		
		["CassiopeiaW"] = 
		{
			HeroName = "Cassiopeia",
			SpellName = "Miasma",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 160,					
			Damage = {20,35,50,65,80},
			APScaling = .15,
			CCType = BUFF_SLOW,
			Danger = 2,
		},
		
		["CassiopeiaE"] = 
		{
			HeroName = "Cassiopeia",
			SpellName = "Twin Fang",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			SpecialDamage = 
			function (owner, target)
				return 48 + 4 * owner.levelData.lvl + 0.1 * owner.ap + (BuffManager:HasBuffType(target, 23) and ({10, 30, 50, 70, 90})[owner:GetSpellData(SpellSlot).level] + 0.60 * owner.ap or 0)
			end,
			Danger = 1,
		},
		
		["CassiopeiaR"] = 
		{
			HeroName = "Cassiopeia", 
			SpellName = "Petrifying Gaze",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_ARC,						
			Damage = {150,250,350},
			APScaling = .5,
			Danger = 5,
		},
		
		--[CHO'GATH SKILLS]--
		["Rupture"] = 
		{
			HeroName = "ChoGath",
			SpellName = "Rupture",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 175,
			Damage = {80,135,190,245,300},
			APScaling = 1.0,
			Danger = 4,
		},
		
		["FeralScream"] = 
		{
			HeroName = "ChoGath",
			SpellName = "FeralScream",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_ARC,
			Damage = {75,125,175,225,275},
			APScaling = .7,
			CCType = BUFF_SILENCE,
			Danger = 3,
		},
		
		["Feast"] = 
		{
			HeroName = "ChoGath", 
			SpellName = "Feast",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,						
			Damage = {300,475,650},
			APScaling = .5,
			Danger = 4,
		},
		
		--[CORKI SKILLS]--
		["PhosphorusBomb"] = 
		{
			HeroName = "Corki",
			SpellName = "Phosphorus Bomb",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			MissileName = "PhosphorusBombMissile",
			Radius = 250,
			Damage = {75,120,165,210,255},
			APScaling = .5,
			ADSCaling = .5,
			Danger = 2,
		},
		
		--W doesnt have activeSpell and isnt a real skillshot
		--E is a status
		
		["MissileBarrage"] = 
		{
			HeroName = "Corki", 
			SpellName = "Missile Barrage",
			MissileName = {"MissileBarrageMissile", "MissileBarrageMissile2"},
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Collision = 1,
			Damage = {75,100,125},
			APScaling = .2,
			ADScaling = .45,
			Danger = 1,
		},
		
		
		--[DARIUS SKILLS]--
		["DariusCleave"] = 
		{
			HeroName = "Darius",
			SpellName = "Decimate",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 425,
			Damage = {40,70,100,130,160},
			ADSCaling = 1.2,
			Danger = 2,
		},
		["DariusNoxianTacticsONH"] = 
		{
			HeroName = "Darius",
			SpellName = "Crippling Strike",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {0,0,0,0,0},--Gives bonus ADScaling, not bonus dmg
			ADSCaling = .5,
			Danger = 2,
		},
		["DariusAxeGrabCone"] = 
		{
			HeroName = "Darius",
			SpellName = "Apprehend",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_ARC,
			Danger = 4,
			CCType = BUFF_STUN,
		},
		["DariusExecute"] = 
		{
			HeroName = "Darius",
			SpellName = "Noxian Guillotine",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {100,200,300},
			--Could do custom damage for this. Increase dmg based on hemorage count
			ADSCaling = .75,
			Danger = 4,
		},
		
		--[DIANA SKILLS]--
		["DianaArc"] = 
		{
			HeroName = "Diana",
			SpellName = "Crescent Strike",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 205,
			Damage = {60,95,130,165,200},
			APScaling = 0.7,
			Danger = 2,
		},
		
		--Diana W is a buff: Don't include
		
		["DianaVortex"] = 
		{
			HeroName = "Diana",
			SpellName = "Moonfall",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 450,
			Danger = 3,
			CCType = BUFF_SLOW,
		},
		
		--Diana R is not an active spell/missile: Don't include
		
		
		--[DRMUNDO SKILLS]--
		["InfectedCleaverMissileCast"] = 
		{
			HeroName = "DrMundo",
			SpellName = "Infected Cleaver",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			MissileName = "InfectedCleaverMissile",
			Collision = 1,
			Radius = 60,
			CurrentHealth = {.15, .175, .20, .225, .25},
			Danger = 2,
		},
		
		--[DRAVEN SKILLS]--
		["DravenSpinning"] = 
		{
			HeroName = "Draven",
			SpellName = "Spinning Axe",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			MissileName = "DravenSpinningAttack",
			Damage = {35,40,45,50,55},
			ADScaling = {.65,.75,.85,.95,1.05},
			Danger = 1,
		},
		["DravenDoubleShot"] = 
		{
			HeroName = "Draven",
			SpellName = "Infected Cleaver",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			MissileName = "DravenDoubleShotMissile",
			Damage = {75,110,145,180,215},
			ADScaling = .5,
			Danger = 3,
			CCType = STATUS_KNOCKBACK,
		},
		["DravenRCast"] = 
		{
			HeroName = "Draven",
			SpellName = "Infected Cleaver",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			MissileName = "DravenR",
			Damage = {175,275,375},
			ADScaling = 1,
			Danger = 3,
		},
		
		
		--[MORGANA SKILLS]--
		["DarkBindingMissile"] = 
		{
			HeroName = "Morgana",
			SpellName = "Dark Binding",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Collision = 1,
			MissileName = "DarkBindingMissile",
			Radius = 60,
			Damage = {80,135,190,245,300},
			APScaling = .9,
			Danger = 4,
			CCType = BUFF_ROOT
		},
		["TormentedSoil"] = 
		{
			HeroName = "Morgana", 
			SpellName = "Tormented Soil",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 325,
			Damage = {8,16,24,32,40},
			APScaling = .11,
			Danger = 1,
		},
		["SoulShackles"] = 
		{
			HeroName = "Morgana", 
			SpellName = "Soul Shackles",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 625,
			Damage = {150,225,300},
			APScaling = .7,
			Danger = 4,
			CCType = BUFF_ROOT
		},
		
	}
	
	--Dirty fix so we can loop skills...
	local slotLookupTable = {_Q, _W, _E, _R}	
	
	for i = 1, LocalGameHeroCount() do
		local target = LocalGameHero(i)		
		for _, s in LocalPairs(slotLookupTable) do
			local spellName = target:GetSpellData(s).name
			if spellName == "BaseSpell" then
			
			elseif self.MasterSkillLookupTable[spellName] then
				local spellData = self.MasterSkillLookupTable[spellName]			
				if spellData.MissileName then
					if LocalType(spellData.MissileName) == "table" then						
						for i = 1, #spellData.MissileName do
							self.MissileNames[spellData.MissileName[i]] = spellData
						end
					else
						self.MissileNames[spellData.MissileName] = spellData
					end
				elseif spellData.ParticleNames then
					for i = 1, #spellData.ParticleNames do
						self.ParticleNames[spellData.ParticleNames[i]] = spellData
					end
				else
					self.Skills[spellName] = spellData
				end
				print("Loaded skill: " .. spellName .. " on " .. target.charName)
			else
				print("Unhandled skill: " .. spellName .. " on " .. target.charName)
			end
		end
	end
	
	LocalCallbackAdd('Tick',  function() self:Tick() end)
	ObjectManager:OnSpellCast(function(args) self:SpellCast(args) end)
end

function __DamageManager:Tick()
	for _, skillshot in LocalPairs(self.EnemySkillshots) do
		if skillshot.Sort == TARGET_TYPE_LINE then
			self:CheckLineMissileCollision(skillshot, self.AlliedHeroes)
		elseif skillshot.Sort ==TARGET_TYPE_CIRCLE then			
			self:CheckCircleMissileCollision(skillshot, self.AlliedHeroes)
		end
	end
	for _, skillshot in LocalPairs(self.AlliedSkillshots) do
		if skillshot.Sort == TARGET_TYPE_LINE then
			self:CheckLineMissileCollision(skillshot, self.EnemyHeroes)
		elseif skillshot.Sort ==TARGET_TYPE_CIRCLE then			
			self:CheckCircleMissileCollision(skillshot, self.EnemyHeroes)
		end
	end
end


function __DamageManager:IncomingDamage(owner, target, damage, ccType)
	
	if owner and target then
		print(owner.charName .. " will hit " .. target.charName .. " for " .. damage .. " Damage")
	else
		print("No owner/target __DamageManager:IncomingDamage")
	end
	
	--Trigger any registered OnCC callbacks. Send them the target, damage and type of cc so we can choose our actions
	if ccType and #self.OnIncomingCCCallbacks then
		self:IncomingCC(target, damage, ccType)
	end
end

function __DamageManager:CheckLineMissileCollision(skillshot, targetList)
	local nextPosition = skillshot.data.pos + skillshot.forward* skillshot.data.missileData.speed * (Game.Latency() * 0.001 + .25)	
	local owner = ObjectManager:GetObjectByHandle(skillshot.data.missileData.owner)
	for _, target in LocalPairs(targetList) do
		if target~= nil and LocalType(target) == "userdata" then
			local proj1, pointLine, isOnSegment = Geometry:VectorPointProjectionOnLineSegment(skillshot.data.pos, nextPosition, target.pos)
			if isOnSegment and Geometry:IsInRange(target.pos, pointLine, skillshot.data.missileData.width + target.boundingRadius) then
				local damage = self:CalculateSkillDamage(owner, target, self.MissileNames[skillshot.name])
				self:IncomingDamage(owner, target, damage, self.MissileNames[skillshot.name].CCType)
			end
		end
	end
end

function __DamageManager:CheckCircleMissileCollision(skillshot, targetList)
	if skillshot.endTime - LocalGameTimer() < .25 then
		local owner = ObjectManager:GetObjectByHandle(skillshot.data.missileData.owner)
		for _, target in LocalPairs(targetList) do
			if target~= nil and LocalType(target) == "userdata" then
				if Geometry:IsInRange(target.pos, skillshot.data.missileData.endPos, skillshot.data.missileData.width + target.boundingRadius) then
					local damage = self:CalculateSkillDamage(owner, target, self.MissileNames[skillshot.name])
					self:IncomingDamage(owner, target, damage, self.MissileNames[skillshot.name].CCType)
				end
			end
		end
	end
end

function __DamageManager:SpellCast(spell)
	if self.Skills[spell.name] then
		local owner = ObjectManager:GetObjectByHandle(spell.handle)
		if owner == nil then return end
		
		local collection = self.EnemyHeroes
		if owner.isEnemy then
			collection = self.AlliedHeroes
		end
		
		local spellInfo = self.Skills[spell.name]
		if spellInfo.TargetType == TARGET_TYPE_SINGLE then
			local target = ObjectManager:GetObjectByHandle(spell.data.target)
			if target then
				local damage = self:CalculateSkillDamage(owner, target, self.Skills[spell.name])
				self:IncomingDamage(owner, target, damage, self.Skills[spell.name].CCType)
			end
		elseif spellInfo.TargetType == TARGET_TYPE_CIRCLE and spellInfo.Radius then
			local castPos = LocalVector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z)			
			for _, target in LocalPairs(collection) do
				if target ~= nil and LocalType(target) == "userdata" then					
					if Geometry:IsInRange(castPos, target.pos, spellInfo.Radius) then
						local damage = self:CalculateSkillDamage(owner, target, self.Skills[spell.name])
						self:IncomingDamage(owner, target, damage, self.Skills[spell.name].CCType)
					end
				end
			end
		elseif spellInfo.TargetType == TARGET_TYPE_ARC then
			local angleOffset = Geometry:Angle(spell.data.startPos,LocalVector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z))
			for _, target in LocalPairs(collection) do
				if target ~= nil and LocalType(target) == "userdata" then
					local deltaAngle = LocalAbs(Geometry:Angle(spell.data.startPos,target.pos) - angleOffset)
					if deltaAngle < spell.data.coneAngle and Geometry:IsInRange(spell.data.startPos, target.pos, spell.data.coneDistance) then
						local damage = self:CalculateSkillDamage(owner, target, self.Skills[spell.name])
						self:IncomingDamage(owner, target, damage, self.Skills[spell.name].CCType)
					end
				end
			end
		elseif spellInfo.TargetType == TARGET_TYPE_LINE and spellInfo.Radius then
			local castPos = spell.data.startPos + (LocalVector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z) - spell.data.startPos):Normalized() * spell.data.range		
			for _, target in LocalPairs(collection) do
					if target ~= nil and LocalType(target) == "userdata" then			
					local proj1, pointLine, isOnSegment =Geometry:VectorPointProjectionOnLineSegment(spell.data.startPos, castPos, target.pos)
					if isOnSegment and Geometry:IsInRange(target.pos, pointLine, spellInfo.Radius + target.boundingRadius) then
						local damage = self:CalculateSkillDamage(owner, target, self.Skills[spell.name])
						self:IncomingDamage(owner, target, damage, self.Skills[spell.name].CCType)
					end
				end
			end
		else
			print("Unhandled targeting type: " .. spellInfo.TargetType)
		end		
	end
end

function __DamageManager:MissileCreated(missile)
	if self.MissileNames[missile.name] then
		missile.Sort = self.MissileNames[missile.name].TargetType
		if missile.Sort == TARGET_TYPE_CIRCLE then
			self:OnUntargetedMissileTable(missile)
		elseif missile.data.missileData.target > 0 then
			if LocalStringFind(missile.name, "BasicAttack") or LocalStringFind(missile.name, "CritAttack") then
				self:OnAutoAttackMissile(missile)
			else
				self:OnTargetedMissileTable(missile)
			end
		else
			self:OnUntargetedMissileTable(missile)
		end
	else
		print("Unhandled missile: " .. missile.name)
	end
end

function __DamageManager:OnAutoAttackMissile(missile)	
	local owner = ObjectManager:GetObjectByHandle(missile.data.missileData.owner)
	local target = ObjectManager:GetObjectByHandle(missile.data.missileData.target)
	if owner and target then
		local targetCollection = self.EnemyDamage
		if target.isAlly then
			targetCollection = self.AlliedDamage
		end
		if not targetCollection[target.handle] then return end
		
		--This missile is already added - ignore it cause something went wrong. 
		if targetCollection[target.handle][missile.networkID] then print("Duplicate targeted missile creation: " .. missile.name) return end
		
		local damage = owner.totalDamage
		if LocalStringFind(missile.name, "CritAttack") then
			damage = damage * 1.5
		end
		damage = self:CalculatePhysicalDamage(owner, target, damage)	
		targetCollection[target.handle][missile.networkID] = 
		{
			Name = missile.name,
			Damage = damage,
			--0 Danger means auto attack. It's because we dont want to spell shield it.
			--Barrier/seraph/etc can still do it based on incoming dmg calculation though!
			Danger = 0,
		}
	end
end

function __DamageManager:OnTargetedMissileTable(missile)
	local skillInfo = self.MissileNames[missile.name]		
	local owner = ObjectManager:GetObjectByHandle(missile.data.missileData.owner)
	local target = ObjectManager:GetObjectByHandle(missile.data.missileData.target)
	if skillInfo and owner and target then
		
		local targetCollection = self.EnemyDamage
		if target.isAlly then
			targetCollection = self.AlliedDamage
		end
					
		--This should not be happening. it's a sign the script isn't populating the enemy/ally collections (delayed load needed IMO)
		if not targetCollection[target.handle] then return end
		
		--This missile is already added - ignore it cause something went wrong. 
		if targetCollection[target.handle][missile.networkID] then print("Duplicate targeted missile creation: " .. missile.name) return end
			
		local damage = self:CalculateSkillDamage(owner, target, skillInfo)
		
		local damageRecord = 
		{
			Damage = damage,
			Danger = skillInfo.Danger or 1,
			CC = skillInfo.CC or nil,
			Name = missile.name,
		}		
		targetCollection[target.handle][missile.networkID] = damageRecord
		self:IncomingDamage(owner, target, damage, damageRecord.CC)
	end
end

function __DamageManager:CalculateSkillDamage(owner, target, skillInfo)
	local damage = 0
	if skillInfo.Damage or skillInfo.SpecialDamage or skillInfo.CurrentHealth then
		if skillInfo.SpecialDamage then
			damage = skillInfo.SpecialDamage(owner, target)
		else
			print("STARTING")
			--TODO: Make sure this handles nil values like a champ
			damage = (skillInfo.Damage and skillInfo.Damage[owner:GetSpellData(skillInfo.SpellSlot).level] or 0 )+ 
			(skillInfo.APScaling and (LocalType(skillInfo.APScaling) == "table" and skillInfo.APScaling[owner:GetSpellData(skillInfo.SpellSlot).level] or skillInfo.APScaling) * owner.totalDamage or 0) + 
			(skillInfo.ADScaling and (LocalType(skillInfo.ADScaling) == "table" and skillInfo.ADScaling[owner:GetSpellData(skillInfo.SpellSlot).level] or skillInfo.ADScaling) * owner.totalDamage or 0) + 
			(skillInfo.CurrentHealth and (LocalType(skillInfo.CurrentHealth) == "table" and skillInfo.CurrentHealth[owner:GetSpellData(skillInfo.SpellSlot).level] or skillInfo.CurrentHealth) * target.health or 0) + 
			(skillInfo.CurrentHealthAPScaling and target.health * skillInfo.CurrentHealthAPScaling * owner.ap/100 or 0)
			
		end		
		if skillInfo.DamageType == DAMAGE_TYPE_MAGICAL then
			damage = self:CalculateMagicDamage(owner, target, damage)
		elseif skillInfo.DamageType == DAMAGE_TYPE_PHYSICAL then
			damage = self:CalculatePhysicalDamage(owner, target, damage)				
		end
		
		if skillInfo.BuffName and BuffManager:HasBuff(target, skillInfo.BuffName) then
			damage = damage * skillInfo.BuffScaling
		end
	end
	return damage
end

function __DamageManager:OnUntargetedMissileTable(missile)
	local owner = ObjectManager:GetObjectByHandle(missile.data.missileData.owner)
	if owner then
		if owner.isEnemy then
			if self.EnemySkillshots[missile.networkID] then return end
			self.EnemySkillshots[missile.networkID] = missile
		else
			if self.AlliedSkillshots[missile.networkID] then return end
			self.AlliedSkillshots[missile.networkID] = missile
		end
	end
end

--Register Incoming CC Event
function __DamageManager:OnIncomingCC(cb)
	LocalInsert(DamageManager.OnIncomingCCCallbacks, cb)
end

--Trigger Incoming CC Event
function __DamageManager:IncomingCC(target, damage, ccType)
	for i = 1, #self.OnIncomingCCCallbacks do
		self.OnIncomingCCCallbacks[i](target, damage, ccType);
	end
end

--Remove from local collections on destroy
function __DamageManager:MissileDestroyed(missile)
	for _, dmgCollection in LocalPairs(self.AlliedHeroes) do
		if dmgCollection[missile.networkID] then
			dmgCollection[missile.networkID] = nil
		end
	end
	
	for _, dmgCollection in LocalPairs(self.EnemyHeroes) do
		if dmgCollection[missile.networkID] then
			dmgCollection[missile.networkID] = nil
		end
	end
	
	for _, skillshot in LocalPairs(self.EnemySkillshots) do
		if self.EnemySkillshots[missile.networkID] then
			self.EnemySkillshots[missile.networkID] = nil
		end
	end
	
	for _, skillshot in LocalPairs(self.AlliedSkillshots) do
		if self.AlliedSkillshots[missile.networkID] then
			self.AlliedSkillshots[missile.networkID] = nil
		end
	end
	
end

function __DamageManager:CalculatePhysicalDamage(source, target, damage)	
	local ArmorPenPercent = source.armorPenPercent
	local ArmorPenFlat = (0.4 + target.levelData.lvl / 30) * source.armorPen
	local BonusArmorPen = source.bonusArmorPenPercent

	if source.type == Obj_AI_Minion then
		ArmorPenPercent = 1
		ArmorPenFlat = 0
		BonusArmorPen = 1
	elseif source.type == Obj_AI_Turret then
		ArmorPenFlat = 0
		BonusArmorPen = 1
		if source.charName:find("3") or source.charName:find("4") then
		  ArmorPenPercent = 0.25
		else
		  ArmorPenPercent = 0.7
		end
	end

	if source.type == Obj_AI_Turret then
		if target.type == Obj_AI_Minion then
		  damage = amount * 1.25
		  if string.ends(target.charName, "MinionSiege") then
			damage = damage * 0.7
		  end
		  return damage
		end
	end

	local armor = target.armor
	local bonusArmor = target.bonusArmor
	local value = 100 / (100 + (armor * ArmorPenPercent) - (bonusArmor * (1 - BonusArmorPen)) - ArmorPenFlat)

	if armor < 0 then
		value = 2 - 100 / (100 - armor)
	elseif (armor * ArmorPenPercent) - (bonusArmor * (1 - BonusArmorPen)) - ArmorPenFlat < 0 then
		value = 1
	end
	return LocalMax(0, LocalFloor(self:DamageReductionMod(source, target, self:PassivePercentMod(source, target, value) * damage, 1)))
end

function __DamageManager:CalculateMagicDamage(source, target, damage)
	local targetMR = target.magicResist - target.magicResist * source.magicPenPercent - source.magicPen	
	local damageReduction = 100 / ( 100 + targetMR)
	if targetMR < 0 then
		damageReduction = 2 - (100 / (100 - targetMR))
	end	
	return LocalMax(0, LocalFloor(self:DamageReductionMod(source, target, self:PassivePercentMod(source, target, damageReduction) * damage, 2)))
end

function __DamageManager:DamageReductionMod(source,target,amount,DamageType)
  if source.type == Obj_AI_Hero then
    if BuffManager:HasBuff(source, "Exhaust") then
      amount = amount * 0.6
    end
  end

  if target.type == Obj_AI_Hero then
    for i = 0, target.buffCount do
      if target:GetBuff(i).count > 0 then
        local buff = target:GetBuff(i)
        if buff.name == "MasteryWardenOfTheDawn" then
          amount = amount * (1 - (0.06 * buff.count))
        end
    
        if self.DamageReductionTable[target.charName] then
          if buff.name == self.DamageReductionTable[target.charName].buff and (not self.DamageReductionTable[target.charName].damagetype or self.DamageReductionTable[target.charName].damagetype == DamageType) then
            amount = amount * self.DamageReductionTable[target.charName].amount(target)
          end
        end

        if target.charName == "Maokai" and source.type ~= Obj_AI_Turret then
          if buff.name == "MaokaiDrainDefense" then
            amount = amount * 0.8
          end
        end

        if target.charName == "MasterYi" then
          if buff.name == "Meditate" then
            amount = amount - amount * ({0.5, 0.55, 0.6, 0.65, 0.7})[target:GetSpellData(_W).level] / (source.type == Obj_AI_Turret and 2 or 1)
          end
        end
      end
    end

    if ItemManager:GetItemSlot(target, 1054) > 0 then
      amount = amount - 8
    end

    if target.charName == "Kassadin" and DamageType == 2 then
      amount = amount * 0.85
    end
  end

  return amount
end

function __DamageManager:PassivePercentMod(source, target, amount, damageType)
  if source.type == Obj_AI_Turret then
    if table.contains(self.SiegeMinionList, target.charName) then
      amount = amount * 0.7
    elseif table.contains(self.NormalMinionList, target.charName) then
      amount = amount * 1.14285714285714
    end
  end
  if source.type == Obj_AI_Hero then 
    if target.type == Obj_AI_Hero then
      if (ItemManager:GetItemSlot(source, 3036) > 0 or ItemManager:GetItemSlot(source, 3034) > 0) and source.maxHealth < target.maxHealth and damageType == 1 then
        amount = amount * (1 + LocalMin(target.maxHealth - source.maxHealth, 500) / 50 * (ItemManager:GetItemSlot(source, 3036) > 0 and 0.015 or 0.01))
      end
    end
  end
  return amount
end

class "__ItemManager"
function __ItemManager:GetItemSlot(unit, id)
	for i = ITEM_1, ITEM_7 do
		if unit:GetItemData(i).itemID == id then
			return i
		end
	end
	return 0
end

class "__BuffManager"
function __BuffManager:HasBuff(target, buffName, minimumDuration)

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
function __BuffManager:HasBuffType(target, buffType, minimumDuration)
	local duration = minimumDuration
	if not minimumDuration then
		duration = 0
	end
	local durationRemaining
	for i = 1, target.buffCount do 
		local buff = target:GetBuff(i)
		if buff.duration > duration and buff.type == buffType then
			durationRemaining = buff.duration
			return true, durationRemaining
		end
	end
end



--Initialization
Geometry = __Geometry()
_G.Alpha.Geometry = Geometry

ObjectManager = __ObjectManager()
_G.Alpha.ObjectManager = ObjectManager

DamageManager = __DamageManager()
_G.Alpha.DamageManager = DamageManager

ItemManager = __ItemManager()
_G.Alpha.ItemManager = ItemManager

BuffManager = __BuffManager()
_G.Alpha.BuffManager = BuffManager


ObjectManager:OnBlink(function(args) print(args.charName .. " used a blink!") end)
ObjectManager:OnSpellCast(function(args) print(args.data.name .. " cast!") end)
