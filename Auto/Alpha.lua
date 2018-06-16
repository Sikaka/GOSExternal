if _G.Alpha then return end
_G.Alpha =
{
	Menu = nil,
	Geometry = nil,
	ObjectManager = nil,
	DamageManager = nil,
	ItemManager = nil,
	BuffManager = nil,
}

local LocalOSClock					= os.clock;
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
local LocalGameTurretCount 			= Game.TurretCount;
local LocalGameTurret				= Game.Turret;
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
local LocalRandom					= math.random
local LocalCos						= math.cos
local LocalSin						= math.sin	


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
local TARGET_TYPE_RING				= 5


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

function __Geometry:RotateAroundPoint(v1,v2, angle)
	local c, s = LocalCos(angle), LocalSin(angle)
	local x = ((v1.x - v2.x) * c) - ((v1.z - v2.z) * s) + v2.x
	local z = ((v1.z - v2.z) * c) + ((v1.x - v2.x) * s) + v2.z
	return Vector(x, v1.y, z or 0)
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
	if not p1 or not p2 or not p1.x or not p2.x then
		local dInfo = debug.getinfo(2)
		print("Undefined IsInRange target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return false
	end
	return (p1.x - p2.x) *  (p1.x - p2.x) + ((p1.z or p1.y) - (p2.z or p2.y)) * ((p1.z or p1.y) - (p2.z or p2.y)) < range * range 
end

function __Geometry:GetLineTargetCount(source, aimPos, delay, speed, width, targetAllies)
	local targetCount = 0
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t and t.pos and t.alive and t.health > 0 and t.visible and t.isTargetable and ( targetAllies or t.isEnemy) then			
			local predictedPos = self:PredictUnitPosition(t, delay+ self:GetDistance(source, t.pos) / speed)			
			local proj1, pointLine, isOnSegment = self:VectorPointProjectionOnLineSegment(source, aimPos, predictedPos)
			if proj1 and isOnSegment and self:IsInRange(predictedPos, proj1, t.boundingRadius + width) then
				targetCount = targetCount + 1
			end
		end
	end
	return targetCount
end

function __Geometry:GetCastPosition(source, target, range, delay, speed, radius, checkCollision, isLine)
	local hitChance = 1
	if not self:IsInRange(source.pos, target.pos, range) then hitChance = -1 end
	local aimPosition = target.pos
	if hitChance > 0 then
	
		local reactionTime = self:PredictReactionTime(target, .15)			

		local interceptTime = self:InterceptTime(source, target, delay, speed)
		aimPosition = self:PredictUnitPosition(target, interceptTime)
		
		if not target.pathing or not target.pathing.hasMovePath then
			hitChance = 2
		end
		
		if isLine then
			local pathVector = aimPosition - target.pos
			local castVector = (aimPosition - myHero.pos):Normalized()
			if pathVector.x + pathVector.z ~= 0 then
				pathVector = pathVector:Normalized()
				if pathVector:DotProduct(castVector) < -.85 or pathVector:DotProduct(castVector) > .85 then
					hitChance = 3
				end
			end
		end
		
		local origin,movementRadius = self:UnitMovementBounds(target, interceptTime, reactionTime)
		if movementRadius <= radius  then
			if target.activeSpell and target.activeSpell.valid and not target.activeSpell.spellWasCast then
				adjustedDelay = LocalGameTimer() - target.activeSpell.startTime + target.activeSpell.windup
				if adjustedDelay > 0 then
					aimPosition = self:PredictUnitPosition(target, interceptTime- adjustedDelay)
				end
			end
			hitChance = 3
		end
		
		--Check if the cast time wont let them walk out before the spell lands and isn't an auto attack. If so consider it accuracy 4 for shit sake
				
		if target.pathing.hasMovePath and target.pathing.isDashing and target.pathing.dashSpeed>500 then
			hitChance = 4
		end
		
		if self:GetImmobileTime(target) >= interceptTime then
			hitChance = 5
		end
		
		if not self:IsInRange(source.pos, aimPosition, range) then hitChance = -1 end
		if checkCollision then
			if self:CheckMinionCollision(source.pos, aimPosition, delay, speed, radius) then
				hitChance = -1
			end
		end
	end
	
	return aimPosition, hitChance	
end




function __Geometry:InterceptTime(source, target, delay, speed)
	local relativePosition = target.pos - source.pos
	local relativeVelocity = (self:NextPath(source) - source.pos):Normalized() * self:GetTargetMS(source) -(self:NextPath(target) - target.pos):Normalized() * self:GetTargetMS(target)
	
	if relativeVelocity.x ~= relativeVelocity.x then
		relativeVelocity = LocalVector(0,0,0)
	end
	local velocitySquared = self:GetSqrMagnitude(relativeVelocity)
	
	local a = velocitySquared - speed * speed
	if LocalAbs(a)  < .001 then
		local t = - self:GetSqrMagnitude(relativePosition) / (2*relativeVelocity:DotProduct(relativePosition))
		return delay + LocalMax(t, 0)
	end
	
	local b = 2*relativeVelocity:DotProduct(relativePosition)
	local c = self:GetSqrMagnitude(relativePosition)
	local d = b * b - 4*a*c
	if d > 0 then
		local t1 = (-b + LocalSqrt(d)) / (2*a)
		local t2 = (-b - LocalSqrt(d)) / (2*a)
		if t1 > 0 then
			if t2 > 0 then
				return delay+ LocalMin(t1, t2)
			else
				return delay+ t1
			end
		else
			return delay + LocalMax(t2, 0)
		end
	elseif d < 0 then
		return delay
	else
		return delay + LocalMax(-b/2*a, 0)
	end	
end

function __Geometry:NextPath(unit)
	if unit.pathing.hasMovePath then
		return unit:GetPath(1)
	else
		return unit.pos
	end
end

function __Geometry:GetSqrMagnitude(vector)
	return vector.x * vector.x + vector.y * vector.y + vector.z * vector.z
end

function __Geometry:GetImmobileTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.count > 0 and buff.duration> duration and (buff.type == BUFF_STUN or buff.type == BUFF_ROOT or buff.type == BUFF_SURPRESS or buff.type == BUFF_KNOCKUP ) then
			duration = buff.duration
		end
	end
	return duration
end

function __Geometry:PredictReactionTime(unit, minimumReactionTime)
	if not minimumReactionTime then minimumReactionTime = .15 end
	local reactionTime = minimumReactionTime
	if unit.activeSpell and unit.activeSpell.valid then
		local windupRemaining = unit.activeSpell.startTime + unit.activeSpell.windup - Game.Timer()
		if windupRemaining > 0 then
			reactionTime = windupRemaining
			if unit.activeSpell.isAutoAttack then
				reactionTime = reactionTime / 3
			end
		end
	end
	
	if unit.pathing.hasMovePath and unit.pathing.isDashing and unit.pathing.dashSpeed>500 then
		reactionTime = self:GetDistance(unit.pos, unit:GetPath(1)) / unit.pathing.dashSpeed
	end
	return reactionTime
end

function __Geometry:UnitMovementBounds(unit, delay, reactionTime)
	local startPosition = self:PredictUnitPosition(unit, delay)
	
	local radius = 0
	local deltaDelay = delay -reactionTime- self:GetImmobileTime(unit)	
	if (deltaDelay >0) then
		radius = self:GetTargetMS(unit) * deltaDelay	
	end
	return startPosition, radius	
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
	nodes[#nodes+1] = unit.pos	
	if unit.pathing.hasMovePath then
		for i = unit.pathing.pathIndex, unit.pathing.pathCount do
			path = unit:GetPath(i)
			nodes[#nodes+1] = path
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
	--LocalCallbackAdd('Draw',  function() self:Draw() end)
	
	self.CachedBuffs = {}
	self.OnBuffAddedCallbacks = {}
	self.OnBuffRemovedCallbacks = {}
	
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
	
	self.NextCacheMissiles = GetTickCount()
	self.LastMissileCount = 0
	self.NextCacheParticles = GetTickCount()
	self.LastParticleCount = 0
	self.NextCacheBuffs = GetTickCount()
end

--Register Buff Added Event
function __ObjectManager:OnBuffAdded(cb)
	ObjectManager.OnBuffAddedCallbacks[#ObjectManager.OnBuffAddedCallbacks+1] = cb
end

--Trigger Buff Added Event
function __ObjectManager:BuffAdded(target, buff)
	for i = 1, #self.OnBuffAddedCallbacks do
		self.OnBuffAddedCallbacks[i](target, buff);
	end
end

--Register Buff Removed Event
function __ObjectManager:OnBuffRemoved(cb)
	ObjectManager.OnBuffRemovedCallbacks[#ObjectManager.OnBuffRemovedCallbacks+1] = cb
end

--Trigger Buff Removed Event
function __ObjectManager:BuffRemoved(target, buff)
	for i = 1, #self.OnBuffRemovedCallbacks do
		self.OnBuffRemovedCallbacks[i](target, buff);
	end
end


--Register Missile Create Event
function __ObjectManager:OnMissileCreate(cb)
	ObjectManager.OnMissileCreateCallbacks[#ObjectManager.OnMissileCreateCallbacks+1] = cb
end

--Trigger Missile Create Event
function __ObjectManager:MissileCreated(missile)
	for i = 1, #self.OnMissileCreateCallbacks do
		self.OnMissileCreateCallbacks[i](missile);
	end
end

--Register Missile Destroy Event
function __ObjectManager:OnMissileDestroy(cb)
	ObjectManager.OnMissileDestroyCallbacks[#ObjectManager.OnMissileDestroyCallbacks+1] = cb
end

--Trigger Missile Destroyed Event
function __ObjectManager:MissileDestroyed(missile)
	for i = 1, #self.OnMissileDestroyCallbacks do
		self.OnMissileDestroyCallbacks[i](missile);
	end
end

--Register Particle Create Event
function __ObjectManager:OnParticleCreate(cb)
	ObjectManager.OnParticleCreateCallbacks[#ObjectManager.OnParticleCreateCallbacks+1] = cb
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
	ObjectManager.OnParticleDestroyCallbacks[#ObjectManager.OnParticleDestroyCallbacks+1] = cb
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
	ObjectManager.OnBlinkCallbacks[#ObjectManager.OnBlinkCallbacks+1] = cb
end

--Trigger Blink Event
function __ObjectManager:Blinked(target)
	for i = 1, #self.OnBlinkCallbacks do
		self.OnBlinkCallbacks[i](target);
	end
end

--Register On Spell Cast Event
function __ObjectManager:OnSpellCast(cb)
	ObjectManager.OnSpellCastCallbacks[#ObjectManager.OnSpellCastCallbacks+1] = cb
end

--Trigger Spell Cast Event
function __ObjectManager:SpellCast(data)
	for i = 1, #self.OnSpellCastCallbacks do
		self.OnSpellCastCallbacks[i](data);
	end
end

local particleDuration = 0
local missileDuration= 0
local buffDuration= 0
function __ObjectManager:Draw()
	Draw.Text("PARTICLES: " .. particleDuration, 14, 200, 100)
	Draw.Text("MISSILES: " .. missileDuration, 14, 200, 125)
	Draw.Text("BUFFS: " .. buffDuration, 14, 200, 150)
end

--Search for changes in particle or missiles in game. trigger the appropriate events.
function __ObjectManager:Tick()	
	--Check if we have any buff added/removed callbacks before querying
	if (#self.OnBuffAddedCallbacks > 0 or #self.OnBuffRemovedCallbacks  > 0) and GetTickCount() > self.NextCacheBuffs then
		local t = LocalOSClock()
		self.NextCacheBuffs = GetTickCount() + BUFF_CACHE_DELAY
		--KNOWN ISSUE: Certain skills use buffs... but constantly tweak their start/end time: EG Aatrox Q. I have no way to reliably handle this currently.
		for _, buff in LocalPairs(self.CachedBuffs) do
			if not buff or not buff.valid then
				if buff and buff.owner and buff.data then				
					self:BuffRemoved(buff.owner, buff.data)
				end
				self.CachedBuffs[_] = nil
			else
				buff.valid = false
			end
		end
		for i = 1, LocalGameHeroCount() do
			local target = LocalGameHero(i)
			if target and LocalType(target) == "userdata" then
				for i = 0, target.buffCount do
					local buff = target:GetBuff(i)
					if buff.duration >0 and buff.expireTime > LocalGameTimer() and buff.startTime <= LocalGameTimer() then
						local key = target.networkID..buff.name
						if self.CachedBuffs[key] then
							self.CachedBuffs[key].valid = true
						else
							local buffData = {valid = true, owner = target, data = buff, expireTime = buff.expireTime}
							self.CachedBuffs[key] = buffData
							self:BuffAdded(target, buff)
						end
					end
				end
			end
		end
		buffDuration = LocalOSClock() - t;
	end
	
	if #self.OnSpellCastCallbacks > 0 then
		for i = 1, LocalGameHeroCount() do
			local target = LocalGameHero(i)
			if target and LocalType(target) == "userdata" then    
				if target.activeSpell and target.activeSpell.valid then
					if not self.CachedSpells[target.networkID] or self.CachedSpells[target.networkID].name ~= target.activeSpell.name then
						local spellData = {owner = target.networkID, isEnemy = target.isEnemy,handle = target.handle, name = target.activeSpell.name, data = target.activeSpell, windupEnd = target.activeSpell.startTime + target.activeSpell.windup}
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
	if (#self.OnParticleCreateCallbacks > 0 or #self.OnParticleDestroyCallbacks > 0) and GetTickCount() > self.NextCacheParticles then
		
		local t = LocalOSClock()
		self.NextCacheParticles = GetTickCount() + PARTICLE_CACHE_DELAY
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
					local particleData = { valid = true, networkID = particle.networkID,  pos = particle.pos, name = particle.name, data = particle}
					self.CachedParticles[particle.networkID] =particleData
					self:ParticleCreated(particleData)
				end
			end
		end
		particleDuration = LocalOSClock() - t
	end
	
	--Cache Missiles ONLY if a create or destroy event is registered: If not it's a waste of processing
	if (#self.OnMissileCreateCallbacks > 0 or #self.OnMissileDestroyCallbacks > 0) and GetTickCount() > self.NextCacheMissiles then
		local t = LocalOSClock()
		self.NextCacheMissiles = GetTickCount() + MISSILE_CACHE_DELAY
		for _, missile in LocalPairs(self.CachedMissiles) do
			if not missile or not missile.data or missile.dead or not missile.valid then
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
					if DamageManager.MissileNames[missile.name] and DamageManager.MissileNames[missile.name].MissileTime then
						missileData.endTime = LocalGameTimer() + DamageManager.MissileNames[missile.name].MissileTime
					end
					self.CachedMissiles[missile.networkID] =missileData
					self:MissileCreated(missileData)
				end
			end
		end
		missileDuration = LocalOSClock() - t
	end	
	
end

function __ObjectManager:CheckIfBlinkParticle(particle)
	for i = 1, #self.BlinkParticleLookupTable do
		if self.BlinkParticleLookupTable[i] == particle.name then
			local target = self:GetPlayerByPosition(particle.pos)
			if target then 
				self:Blinked(target)
			end
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

function __ObjectManager:GetHeroByID(id)
	for i = 1, LocalGameHeroCount() do
		local target = LocalGameHero(i)
		if target and target.networkID == id then
			return target
		end
	end
end

function __ObjectManager:GetHeroByHandle(handle)
	for i = 1, LocalGameHeroCount() do
		local target = LocalGameHero(i)
		if target and target.handle == handle then
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
	for i = 1, LocalGameTurretCount() do
		local target = LocalGameTurret(i)
		if target and target.handle == handle then
			return target
		end
	end
end

class "__DamageManager"
--Credits LazyXerath for extra dmg reduction methods
function __DamageManager:__init()
	self.IMMOBILE_TYPES = {[BUFF_KNOCKUP]="true",[BUFF_SURPRESS]="true",[BUFF_ROOT]="true",[BUFF_STUN]="true", [BUFF_CHARM] = "true"}
	
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
	
	self.IgnoredCollisions = {}
	
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
	
	--Simple table for buffs we want to track
	self.BuffNames = {}
	
	--Simple table for skills we want to track
	self.Skills = {}
	
	--Collection for all skills loaded
	self.AllSkills = {}
	
	--Master lookup table. NOT WHAT IS USED FOR ACTUAL MATCHING. It's used for loading
	self.MasterSkillLookupTable =
	{	
		--[Item calculations]--
		
		--Bilgewater Cutlass: 3144
		[3144] =
		{
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = 100,
			Range = 550,
		},
		--Blade of the Ruined King: 3153
		[3153] =
		{
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = 100,
			Range = 550,
		},
		--Hextech Gunblade: 3146
		[3146] =
		{
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {175,180,184,189,193,198,203,207,212,216,221,225,230,235,239,244,248,253},
			APScaling = .3,
			Range = 700,
		},
		--Tiamat: 3077
		[3077] =
		{
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Damage = 0,
			ADScaling = .6,
			Range = 400,
		},
		--Ravenous Hydra: 3074
		[3074] =
		{
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Damage = 0,
			ADScaling = .6,
			Range = 400,
		},
		
		--Titanic Hydra: 3748
		[3748] =
		{
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_ARC,
			Damage = 40,
			MaximumHealth = .1,
			Range = 700,
		},
		
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
			BuffName = "AatroxQDescent"
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
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 100,
			Damage = {40,65,90,115,140},
			APScaling = .35,
			Danger = 2,
		},
		["AhriFoxFire"] = 
		{
			HeroName = "Ahri", 
			SpellName = "Fox-Fire",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,
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
			MissileName="AhriSeduceMissile",
			DamageType = DAMAGE_TYPE_MAGICAL,
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
			DamageType = DAMAGE_TYPE_MAGICAL,
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
			DamageType = DAMAGE_TYPE_MAGICAL,
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
			DamageType = DAMAGE_TYPE_MAGICAL,
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
			DamageType = DAMAGE_TYPE_MAGICAL,
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
			DamageType = DAMAGE_TYPE_MAGICAL,
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
			DamageType = DAMAGE_TYPE_MAGICAL,
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
			DamageType = DAMAGE_TYPE_MAGICAL,
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
			DamageType = DAMAGE_TYPE_MAGICAL,
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
			DamageType = DAMAGE_TYPE_MAGICAL,
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
			BuffScalingName = "aniviaiced",
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
			BuffScalingName = "BrandAblaze",
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
			DamageType = DAMAGE_TYPE_MAGICAL,
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
		
		--[EKKO SKILLS]--
		["EkkoQ"] = 
		{
			HeroName = "Ekko",
			SpellName = "Timewinder",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			MissileName = "EkkoQMis",
			Damage = {60,75,90,105,120},
			APScaling = .3,
			Danger = 2,
		},
		["EkkoW"] = 
		{
			HeroName = "Ekko",
			SpellName = "Parallel Convergence",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			MissileName = "EkkoWMis",
			Radius = 400,
			Danger = 3,
			CCType = STATUS_SLOW,
		},
		["EkkoR"] = 
		{
			HeroName = "Ekko",
			SpellName = "Chronobreak",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 375,
			Damage = {150,300,450},
			APScaling = 1.5,
			Danger = 3,
		},
		
		--[ELISE SKILLS]--
		["EliseHumanQ"] = 
		{
			--Only active skillset on load are monitored so this gives us a way to reference skills from our other form. Each needs to reference the other.
			Alternate = {"EliseSpiderQCast"},
			HeroName = "Elise",
			SpellName = "Neurotoxin",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			MissileName = "EliseHumanQ",
			Damage = {40,75,110,145,180},
			CurrentHealth = .04,
			CurrentHealthAPScaling = .03,
			Danger = 2,
		},
		["EliseSpiderQCast"] = 
		{
			--Only active skillset on load are monitored so this gives us a way to reference skills from our other form. Each needs to reference the other.
			HeroName = "Elise",
			SpellName = "Venomous Bite",
			Alternate = {"EliseHumanQ"},
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {70,110,150,190,230},
			MissingHealth = .08,
			MissingHealthAPScaling = .03,
			Danger = 2,
		},
		["EliseSpiderEInitial"] = 
		{
			HeroName = "Elise",
			SpellName = "Wrapper",
			Alternate = {"EliseHumanE"},
			SpellSlot = _E,
		},
		["EliseHumanE"] = 
		{
			HeroName = "Elise",
			SpellName = "Cocoon",
			SpellSlot = _E,
			TargetType = TARGET_TYPE_LINE,
			Radius = 55,
			MissileName = "EliseHumanE",
			Danger = 3,
			CCType = STATUS_STUN,
		},
		
		--[EVELYNN SKILLS]--
		["EvelynnQ"] = 
		{
			HeroName = "Evelynn",
			SpellName = "Hate Spike",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 90,
			MissileName = "EvelynnQ",
			Damage = {25,30,35,40,45},
			APScaling = .3,
			Danger = 1,
		},
		["EvelynnW"] = 
		{
			HeroName = "Evelynn",
			SpellName = "Allure",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Danger = 3,			
			CCType = STATUS_SLOW,
		},
		["EvelynnE"] = 
		{
			Alternate = {"EvelynnE2"},
			HeroName = "Evelynn",
			SpellName = "Whiplash",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {55,70,85,100,115},
			MaximumHealth = .03,
			MaximumHealthAPScaling = .015,
			Danger = 2,
		},
		["EvelynnE2"] = 
		{
			Alternate = {"EvelynnE"},
			HeroName = "Evelynn",
			SpellName = "Whiplash",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {95,115,135,155,175},
			MaximumHealth = .04,
			MaximumHealthAPScaling = .025,
			Danger = 3,
		},
		["EvelynnR"] = 
		{
			HeroName = "Evelynn",
			SpellName = "Last Caress",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_ARC,
			Damage = {150,275,400},
			APScaling = .75,
			Danger = 3,
			
			--This overrides the default arc calculations
			Radius = 450,
			Angle = 180,
		},
		
		--[EZREAL SKILLS]--
		["EzrealMysticShot"] = 
		{
			HeroName = "Ezreal",
			SpellName = "Mystic Shot",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			Collision = 1,
			MissileName = "EzrealMysticShotMissile",
			Radius = 80,
			Damage = {15,40,65,90,115},
			ADScaling = 1.1,
			APScaling = .4,
			Danger = 1,
		},
		
		["EzrealEssenceFlux"] = 
		{
			HeroName = "Ezreal",
			SpellName = "Essence Flux",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "EzrealEssenceFluxMissile",
			Radius = 80,
			Damage = {70,115,160,205,250},
			APScaling = .8,
			Danger = 1,
		},
		
		["EzrealArcaneShift"] = 
		{
			HeroName = "Ezreal",
			SpellName = "Arcane Shift",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			MissileName = "EzrealArcaneShiftMissile",
			Damage = {80,130,180,230,280},
			ADScaling = .5,
			APScaling = .75,
			Danger = 1,
		},
		
		["EzrealTrueshotBarrage"] = 
		{
			HeroName = "Ezreal",
			SpellName = "Essence Flux",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "EzrealTrueshotBarrage",
			Radius = 160,
			Damage = {350,500,650},
			BonusADScaling = 1,
			APScaling = .9,
			Danger = 3,
		},
		
		--[FIORA SKILLS]--
		--She has no active spells or meaningful missiles. Leave her for now
				
		--[FIZZ SKILLS]--
		["FizzR"] = 
		{
			HeroName = "Fizz",
			SpellName = "Chum the Waters",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			Collision = 1,
			MissileName = "FizzRMissile",
			Radius = 120,
			Damage = {225,325,425},
			APScaling = .8,
			Danger = 4,
		},
		
		--[GALIO SKILLS]--
		["GalioQ"] = 
		{
			HeroName = "Galio",
			SpellName = "Winds of War",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 150,
			Damage = {50,80,110,140,170},
			APScaling = .8,
			Danger = 2,
		},		
		
		["GalioE"] = 
		{
			HeroName = "Galio",
			SpellName = "Justice Punch",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			Radius = 160,
			Collision = 1,
			Damage = {100,130,160,190,220},
			APScaling = .9,
			Danger = 3,
			CCType = BUFF_KNOCKUP,
		},
		
		--[GANGPLANK SKILLS]--
		["GangplankQWrapper"] = 
		{
			Alias = "GangplankQProceed",
			SpellName = "Gangplank",
			HeroName = "Parrrley", 
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,						
			Damage = {20,45,70,95,120},
			ADScaling = 1, 
			Danger = 2,
		},
		
		["GangplankR"] = 
		{
			HeroName = "Gangplank",
			SpellName = "Cannon Barrage",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 600,
			Damage = {35,60,85},
			APScaling = .1,
			Danger = 3,
		},
		
		--[GAREN SKILLS]--
		["GarenQ"] = 
		{
			Alias = "GarentQAttack",
			SpellName = "Garen",
			HeroName = "Decisive Strike",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,						
			Damage = {30,65,100,135,170},
			ADScaling = 1.4,
			Danger = 1,
			CCType = BUFF_SILENCE,
		},
		["GarenR"] = 
		{
			SpellName = "Garen",
			HeroName = "Demacian Justice",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,						
			Damage = {175,350,525},
			MissingHealth = {.286,.333,.4},
			Danger = 4,
		},
		
		--[GNAR SKILLS]--
		["GnarQ"] = 
		{
			Alternate = {"GnarBigQ"},
			HeroName = "Gnar",
			SpellName = "Boomerang Throw",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "gnarqmissile",
			Radius = 60,
			Damage = {5,45,85,125,165},
			ADScaling = 1.15,
			Danger = 1,
			CCType = BUFF_SLOW,
		},
		["GnarBigQ"] = 
		{
			Alternate = {"GnarQ"},
			HeroName = "Gnar",
			SpellName = "Boulder Toss",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "GnarBigQMissile",
			Radius = 60,
			Damage = {5,45,85,125,165},
			ADScaling = 1.2,
			Danger = 1,
			CCType = BUFF_SLOW,
		},
		["GnarW"] = 
		{
			Alternate = {"GnarBigW"},
		},
		["GnarBigW"] = 
		{
			HeroName = "Gnar",
			SpellName = "Wallop",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "GnarBigW",
			Radius = 80,
			Damage = {25,45,65,85,105},
			ADScaling = 1,
			Danger = 3,
			CCType = BUFF_STUN,
		},
		
		["GnarE"] = 
		{
			Alternate = {"GnarBigE"},
			HeroName = "Gnar",
			SpellName = "Hop",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 150,
			Damage = {50,85,120,155,190},
			MaximumHealth = .06,
			Danger = 2,
			CCType = BUFF_SLOW,
		},
		["GnarBigE"] = 
		{
			Alternate = {"GnarE"},
			HeroName = "Gnar",
			SpellName = "Crunch",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 200,
			Damage = {50,85,120,155,190},
			MaximumHealth = .06,
			Danger = 2,
			CCType = BUFF_SLOW,
		},
		["GnarR"] = 
		{
			HeroName = "Gnar",
			SpellName = "GNAR!",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 500,
			Damage = {200,300,400},
			ADScaling = .2,
			APScaling = .5,
			Danger = 4,
			CCType = BUFF_KNOCKBACK,
		},
		
		--[GRAGAS SKILLS]--
		
		["GragasQ"] = 
		{
			HeroName = "Gragas",
			SpellName = "Barrel Roll",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			MissileName = "GragasQMissile",
			Radius = 275,
			Damage = {300,400,500},
			APScaling = .75,
			Danger = 2,
			CCType = BUFF_SLOW,
		},	
		
		["GragasW"] = 
		{
			Alias = "GragasWAttack",
			HeroName = "Gragas",
			SpellName = "Body Slam",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {20,50,80,110,140},
			MaximumHealth = .08,
			Danger = 1,
			CCType = BUFF_STUN,
		},
		
		--Not handled properly by bot
		["GragasE"] = 
		{
			HeroName = "Gragas",
			SpellName = "Body Slam",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			Radius = 200,
			Collision = 1,
			Damage = {80,130,180,230,280},
			APScaling = .9,
			Danger = 3,
			CCType = BUFF_STUN,
		},
		
		["GragasR"] = 
		{
			HeroName = "Gragas",
			SpellName = "Explosive Cask",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			MissileName = "GragasRBoom",
			Radius = 375,
			Damage = {200,300,400},
			APScaling = .7,
			Danger = 5,
			CCType = BUFF_KNOCKBACK,
		},
		
		
		--[GRAVES SKILLS]--		
		["GravesQLineSpell"] = 
		{
			HeroName = "Graves",
			SpellName = "End of the Line",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "GravesQLineMis",
			Radius = 60,
			Damage = {45,60,75,90,105},
			ADScaling = 1,
			Danger = 2,
		},
		
		["GravesSmokeGrenade"] = 
		{
			HeroName = "Graves",
			SpellName = "Smoke Screen",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Damage = {60,110,160,210,260},
			APScaling = .6,
			Danger = 1,
			CCType = BUFF_SLOW,
			Radius = 250,
		},
		
		["GravesChargeShot"] = 
		{
			HeroName = "Graves",
			SpellName = "Collateral Damage",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "GravesChargeShotShot",
			Radius = 100,
			Damage = {250,400,550},
			ADScaling = 1.5,
			Danger = 5,
		},
		
		--[HECARIM SKILLS]--
		--not an active skill
		["HecarimRapidSlash"] = 
		{
			HeroName = "Hecarim",
			SpellName = "Rampage",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Damage = {55,90,125,160,195},
			ADScaling = .6,
			Danger = 1,
			Radius = 350,
		},
		["HecarimRamp"] = 
		{
			Alias = "HecarimRampAttack",
			HeroName = "Hecarim",
			SpellName = "Devastating Charge",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {45,80,115,150,185},
			ADScaling = .5,
			Danger = 1,
			CCType = BUFF_KNOCKBACK,
		},
		
		--not an active skill
		["HecarimUlt"] = 
		{
			HeroName = "Hecarim",
			SpellName = "Onslaught of Shadows",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Damage = {150,250,350},
			APScaling =  1,
			Danger = 5,
			Radius = 400,
			CCType = BUFF_FEAR,
		},
		
		
		--[HEIMERDINGER SKILLS]--
		
		["HeimerdingerW"] = 
		{
			HeroName = "Heimerdinger",
			SpellName = "Hextech Micro-Rockets",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = {"HeimerdingerWAttack2", "HeimerdingerWAttack2Ult"},
			Radius = 70,
			Damage = {60,90,120,150,180},
			APScaling = .45,
			Danger = 1,
		},
		
		["HeimerdingerE"] = 
		{
			Alternate = {"HeimerdingerEUlt"},
			HeroName = "Heimerdinger",
			SpellName = "CH-2 Electron Storm Grenade",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			MissileName = "HeimerdingerESpell",
			Radius = 200,
			Damage = {60,100,140,180,220},
			APScaling = .6,
			Danger = 2,
			CCType = BUFF_STUN,
		},
		
		["HeimerdingerEUlt"] = 
		{
			Alternate = "HeimerdingerEUlt",
			HeroName = "Heimerdinger",
			SpellName = "CH-2 Electron Storm Grenade",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			MissileName ={ "HeimerdingerESpell_ult", "HeimerdingerESpell_ult2", "HeimerdingerESpell_ult3"},
			Radius = 200,
			Damage = {60,100,140,180,220},
			APScaling = .6,
			Danger = 3,
			CCType = BUFF_STUN,
		},
		
		--[ILLAOI SKILLS]--
		["IllaoiQ"] = 
		{
			HeroName = "Illaoi",
			SpellName = "Tentacle Smash",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			--MissileName = "IllaoiQMis",
			Radius = 100,
			SpecialDamage = 
				function (owner, target)
					return owner.levelData.lvl * 10 + owner.totalDamage * 1.2
				end,
			Danger = 3,
		},
		
		["IllaoiW"] = 
		{
			Alias = "IllaoiWAttack",
			HeroName = "Illaoi",
			SpellName = "Harsh Lesson",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {0,0,0,0,0},
			MaximumHealth = {.03, .035, .04, .045, .05},
			MaximumHealthADScaling = .02,
			Danger = 1,
		},
		["IllaoiE"] = 
		{
			HeroName = "Illaoi",
			SpellName = "Test of Spirit",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "IllaoiEMis",
			Radius = 50,
			Damage = {0,0,0,0,0},
			Danger = 3,
		},
		["IllaoiR"] = 
		{
			HeroName = "Illaoi",
			SpellName = "Leap of Faith",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 450,
			Damage = {150,250,350},
			ADScaling = .5,
			Danger = 3,
		},
		
		
		--[IRELLIA SKILLS]--

		
		["IreliaW"] = 
		{
			Alias = "IreliaW2",
			HeroName = "Irelia",
			SpellName = "Defiant Dance",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 120,
			Damage = {10,30,50,70,90},
			ADScaling = .6, 
			APScaling = .4,
			Danger = 1,
		},
		["IreliaE"] = 
		{
			HeroName = "Irelia",
			SpellName = "Flawless Duet",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			MissileName = "IreliaESecondary", 
			Radius = 70,
			Damage = {80,120,160,200,240}, 
			APScaling = .8,
			CCType = BUFF_STUN,
			Danger = 3,
		},
		
		["IreliaR"] = 
		{
			HeroName = "Irelia",
			SpellName = "Vanguard's Edge",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			MissileName = "IreliaR", 
			Radius = 70,
			Damage = {125,225,325}, 
			APScaling = .7,
			CCType = BUFF_DISARM,
			Danger = 5,
		},
		
		--[IVERN SKILLS]--
		["IvernQ"] = 
		{
			HeroName = "Ivern",
			SpellName = "Rootcaller",
			MissileName = "IvernQ",
			SpellSlot = _Q,
			Collision = 1,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 80,
			Damage = {80,125,170,215,260},
			APScaling = .7,
			CCType = BUFF_SNARE,
			Danger = 3,
		},
		
		["IvernR"] = 
		{
			HeroName = "Ivern",
			SpellName = "Rootcaller",
			MissileName = "IvernRMissile",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 100,
			Damage = {70,100,170},
			APScaling = .3,
			CCType = BUFF_KNOCKUP,
			Danger = 3,
		},
		
		--[JANNA SKILLS]--		
		["HowlingGale"] = 
		{
			HeroName = "Janna",
			SpellName = "Howling Gale",
			MissileName = {"HowlingGaleSpell", "HowlingGaleSpell1","HowlingGaleSpell2","HowlingGaleSpell3","HowlingGaleSpell4","HowlingGaleSpell5","HowlingGaleSpell6","HowlingGaleSpell7","HowlingGaleSpell8","HowlingGaleSpell9","HowlingGaleSpell10","HowlingGaleSpell11","HowlingGaleSpell12","HowlingGaleSpell13","HowlingGaleSpell14","HowlingGaleSpell15","HowlingGaleSpell16"},
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 120,
			Damage = {60,85,110,135,160},
			APScaling = .35,
			CCType = BUFF_KNOCKUP,
			Danger = 3,
		},
		["SowTheWind"] = 
		{
			HeroName = "Janna",
			SpellName = "Zephyr",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {55,100,145,190,235},
			CCType = BUFF_SLOW,
			Danger = 1,
		},
		["ReapTheWhirlwind"] = 
		{
			HeroName = "Janna",
			SpellName = "Monsoon",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 725,
			Damage = {0,0,0,0,0},
			CCType = BUFF_KNOCKBACK,
			Danger = 1,
		},
		--[JarvanIV Skills]--				
		["JarvanIVDragonStrike"] = 
		{
			HeroName = "JarvanIV",
			SpellName = "Dragon Strike",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 80,
			Damage = {80,120,160,200,240},
			ADScaling = 1.2,
			Danger = 3,
		},
		
		["JarvanIVCataclysm"] = 
		{
			HeroName = "JarvanIV",
			SpellName = "Cataclysm",
			BuffName = "JarvanIVCataclysm",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 325,
			Damage = {200,325,450},
			ADScaling = 1.5,
			Danger = 3,
		},
				
		--[JAYCE SKILLS]--
		["JayceToTheSkies"] = 
		{
			Alternate = {"JayceShockBlast"},
			HeroName = "Jayce",
			SpellName = "To The Skies",
			SpellSlot = _Q,
		},
		["JayceShockBlast"] = 
		{
			HeroName = "Jayce",
			SpellName = "Shock Blast",
			MissileName = {"JayceShockBlastMis","JayceShockBlastWallMis"},
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Collision = 1,
			Radius = 70,
			Damage = {70,120,170,220,270,320},
			ADScaling = 1.2,
			Danger = 3,
		},
		
		
		["JayceHyperCharge"] = 
		{
			Alternate = {"JayceThunderingBlow"},
			HeroName = "Jayce",
			SpellName = "Hyper Charge",
			SpellSlot = _E,
		},
		["JayceThunderingBlow"] = 
		{
			HeroName = "Jayce",
			SpellName = "Thundering Blow",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {0,0,0,0,0},
			MaximumHealth = {.08,.104,.128,.152,.176,.2},
			ADScaling = 1,
			Danger = 1,			
			CCType = BUFF_KNOCKBACK,
		},
			
		--[Jhin]--	
		
		["JhinQ"] = 
		{
			HeroName = "Jhin",
			SpellName = "Dancing Grenade",
			MissileName = {"JhinQ", "JhinQMisBounce"},
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {40,70,95,120,145},
			ADScaling = {.4,.475,.55,.625,.7},
			APScaling = .6,
			Danger = 1,
		},
		
		["JhinW"] = 
		{
			HeroName = "Jhin",
			SpellName = "Deadly Flourish",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 40,
			Collision =1,
			Damage = {50,85,120,155,190},
			ADScaling =.5,
			Danger = 3,
		},
		
		["JhinR"] = 
		{
			HeroName = "Jhin",
			SpellName = "Curtain Call",
			SpellSlot = _R,
			MissileName = {"JhinRShotMis", "JhinRShotMis4"},
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 80,
			Collision =1,
			Damage = {50,125,200},
			ADScaling =.2,
			CCType = BUFF_SLOW,
		},
		
		--[Jinx Skills]--		
		
		["JinxW"] = 
		{
			HeroName = "Jinx",
			SpellName = "Zap!",
			MissileName = "JinxWMissile",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 60,
			Collision =1,
			Damage = {10,60,110,160,210},
			ADScaling =1.4,
			Danger = 3,
			CCType = BUFF_SLOW,
		},
		["JinxE"] = 
		{
			HeroName = "Jinx",
			SpellName = "Flame Chompers!",
			MissileName = "JinxEHit",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 50,
			Damage = {70,120,170,220,270},
			APScaling =1,
			Danger = 1,
			CCType = BUFF_SNARE,
		},
		["JinxR"] = 
		{
			HeroName = "Jinx",
			SpellName = "Super Mega Death Rocket!",
			MissileName = "JinxR",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 140,
			Damage = {25,35,45},
			ADScaling =.15,
			MissingHealth = {.25,.3,.35},
			Danger = 5,
		},
		
		--[Kalista Skills]--
		["KalistaMysticShot"] = 
		{
			HeroName = "Kalista",
			SpellName = "Pierce",
			MissileName ="kalistamysticshotmis",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Collision = 1,
			Radius = 40,			
			Damage = {10,70,130,190,250},
			ADScaling = 1,
			Danger = 1,
		},
		
		--[KaiSa Skills]--
		["KaisaQ"] = 
		{
			HeroName = "Kaisa",
			SpellName = "Icathian Rain",
			MissileName ={"KaisaQLeftMissile1","KaisaQRightMissile1","KaisaQLeftMissile2","KaisaQRightMissile2","KaisaQLeftMissile3","KaisaQRightMissile3",},
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {45,61.25,77.5,93.75,110},
			ADScaling = .35,
			APScaling = .5,
			Danger = 1,
		},
		["KaisaW"] = 
		{
			HeroName = "Kaisa",
			SpellName = "Void Seeker",
			MissileName ="KaisaW",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius =100,
			Damage = {20,45,70,95,120},
			ADScaling = 1.5,
			APScaling = .45,
			Danger = 3,
		},
		
		--[Karma Skills]--
		["KarmaQ"] = 
		{
			HeroName = "Karma",
			SpellName = "Inner Flame",
			MissileName = {"KarmaQMissile","KarmaQMissileMantra"},
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Collision = 1,
			Radius = 60,			
			Damage = {180,125,170,215,260},
			APScaling = .6,
			Danger = 2,
		},
		["KarmaSpiritBind"] = 
		{
			HeroName = "Karma",
			SpellName = "Focused Resolve",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {30,55,80,150,130},
			APScaling = .45,
			Danger = 2,
		},
		
		--[Karthus Skills]--		
		["KarthusLayWasteA1"] = 
		{
			HeroName = "Karthus",
			SpellName = "LayWaste",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 160,			
			Damage = {50,70,90,110,130},
			APScaling = .3,
			Danger = 2,
		},
		
		--W is a different targeting type, leave it for now
		--R is delayed damage, leave it for now
		
		--[Kassadin skills]--		
		["NullLance"] = 
		{
			HeroName = "Kassadin",
			SpellName = "Null Sphere",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {65,95,125,155,185},
			APScaling = .7,
			Danger = 1,
		},	
		["ForcePulse"] = 
		{
			HeroName = "Kassadin",
			SpellName = "Force Pulse",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_ARC,
			Damage = {65,95,125,155,185},
			APScaling = .7,
			Danger = 3,
			CCType = BUFF_SLOW
		},	
		["RiftWalk"] = 
		{
			HeroName = "Kassadin",
			SpellName = "Riftwalk",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 270,
			Damage = {80,100,120},
			APScaling = .3,
			Danger = 3,
		},
		
		--[Katarina Skills]--
		["KatarinaQ"] = 
		{
			HeroName = "Katarina",
			SpellName = "Bouncing Blade",
			MissileName = {"KatarinaQ", "KatarinaQMis"},
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {75,105,135,165,195},
			APScaling = .3,
			Danger = 1,
		},
		["KatarinaEWrapper"] = 
		{
			Alias = "KatarinaE",
			HeroName = "Katarina",
			SpellName = "Shunpo",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {15,30,45,60,75},
			APScaling = .25,
			ADScaling = 1.5,
			Danger = 1,
		},
		["KatarinaR"] = 
		{
			HeroName = "Katarina",
			SpellName = "Death Lotus",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			MissileName ="KatarinaRMis",
			Damage = {25,37.5,50},
			APScaling = .19,
			ADScaling = .22,
			Danger = 1,
		},
		
		--[Kayle Skills]--
		["JudicatorReckoning"] = 
		{
			HeroName = "Kayle",
			SpellName = "Reckoning",
			MissileName = "JudicatorReckoning",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {60,110,160,210,260},
			APScaling = .6,
			ADScaling = 1,
			Danger = 1,
			CCType = BUFF_SLOW
		},
		
		--[Kayne Skills]--
		
		["KaynW"] = 
		{
			HeroName = "Kayn",
			SpellName = "Blade's Reach",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 50,
			Damage = {90,135,180,225,270},
			ADScaling = 1.3,
			Danger = 2,
			CCType = BUFF_SLOW
		},
		["KaynR"] = 
		{
			HeroName = "Kayn",
			SpellName = "Umbral Trespass",
			BuffName = "KaynR",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {150,250,350},
			ADScaling = 1.75,
			Danger = 4,
		},
		
		--[Kennen Skills]--
		
		["KennenShurikenHurlMissile1"] = 
		{
			HeroName = "Kennen",
			SpellName = "Thundering Shuriken",
			MissileName = "KennenShurikenHurlMissile1",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 50,
			Damage = {75,115,155,195,235},
			APScaling = .75,
			Danger = 1,
		},
		
		["KennenBringTheLight"] = 
		{
			HeroName = "Kennen",
			SpellName = "Electrical Surge",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {60,85,110,135,160},
			APScaling = .8,
			Danger = 1,
		},
		
		["KennenShurikenStorm"] = 
		{
			HeroName = "Kennen",
			SpellName = "Electrical Surge",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 500,
			Damage = {40,75,110},
			APScaling = .2,
			Danger = 3,
		},
		
		--[Khazix Skills]--
		
		["KhazixQ"] = 
		{
			HeroName = "Khazix",
			Alternate = {"KhazixQLong"},
			SpellName = "Taste Their Fear",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {50,75,100,125,150},
			ADScaling = 1.3,
			Danger = 1,
		},
		
		["KhazixQLong"] = 
		{
			HeroName = "Khazix",
			Alternate = {"KhazixQ"},
			SpellName = "Taste Their Fear",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {50,75,100,125,150},
			ADScaling = 1.3,
			Danger = 1,
		},
		
		["KhazixW"] = 
		{
			HeroName = "Khazix",
			SpellName = "Void Spike",
			MissileName = "KhazixWMissile",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 73,
			Damage = {85,115,145,175,205},
			ADScaling = 1,
			Danger = 1,
		},
		
		--Can't get kha E to work... it has a missile associated but I cant seem to get it to work
		["KhazixE"] = 
		{
			HeroName = "Khazix",
			SpellName = "Void Spike",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 300,
			Damage = {65,100,135,170,205},
			ADScaling = .2,
			Danger = 1,
			MissileName = "KhazixEInvisMissile",
			MissileTime = .5
		},
		
		--[Kindred Skills]--
		["KindredQ"] = 
		{
			HeroName = "Kindred",
			SpellName = "Dance of Arrows",
			MissileName = "KindredQMissile",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {60,80,100,120,140},
			ADScaling = .65,
			Danger = 1,
		},
		
		["KindredEWrapper"] = 
		{
			Alias = "KindredE",
			HeroName = "Kindred",
			SpellName = "Mounting Dread",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {65,85,105,125,145},
			ADScaling = .8,
			Danger = 1,
			CCType = BUFF_SLOW
		},
		
		
		--[Kled Skills]--
		["KledQ"] = 
		{
			HeroName = "Kled",
			Alternate = {"KledRiderQ"},
			SpellName = "Beartrap on a Rope",
			MissileName = "KledQMissile",
			Radius = 70,
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Damage = {30,55,80,105,130},
			ADScaling = .6,
			Danger = 1,
		},
		["KledRiderQ"] = 
		{
			HeroName = "Kled",
			Alternate = {"KledQ"},
			SpellName = "Pocket Pistol",
			MissileName = "KledRiderQMissile",
			Radius = 45,
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			Damage = {30,50,65,80,95},
			ADScaling = .8,
			Danger = 1,
		},
		["KledR"] = 
		{
			HeroName = "Kled",
			SpellName = "Chaaaaaaaarge!!!",
			BuffName = "KledRDash",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 300,
			Damage = {200,300,400},
			ADScaling = 3,
			Danger = 4,
		},
		--[Leblanc Skills]--
		
		["LeblancQ"] = 
		{
			HeroName = "Leblanc",
			Alternate = {"LeblancRQ"},
			SpellName = "Sigil of Malice",
			MissileName = "LeblancQ",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {55,80,105,130,155},
			APScaling = .4,
			Danger = 1,
		},
		["LeblancRQ"] = 
		{
			HeroName = "Leblanc",
			Alternate = {"LeblancQ"},
			SpellName = "Sigil of Malice",
			MissileName = "LeblancRQ",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {55,80,105,130,155},
			APScaling = .4,
			Danger = 1,
		},
		["LeblancW"] = 
		{
			HeroName = "Leblanc",
			Alternate = {"LeblancRW"},
			BuffName = "LeblancW",
			Radius = 65,
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 220,
			Damage = {85,125,165,205,245},
			APScaling = .6,
			Danger = 3,
		},
		
		["LeblancRW"] = 
		{
			HeroName = "Leblanc",
			Alternate = {"LeblancW"},
			BuffName = "LeblancRW",
			Radius = 65,
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 220,
			Damage = {85,125,165,205,245},
			APScaling = .6,
			Danger = 3,
		},
		
		["LeblancRE"] = 
		{
			HeroName = "Leblanc",
			Alternate = {"LeblancE"},
			SpellName = "Ethereal Chains",
			MissileName = "LeblancRE",
			Radius = 65,
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Damage = {40,60,80,100,120},
			APScaling = .3,
			Danger = 2,
		},
		
		["LeblancE"] = 
		{
			HeroName = "Leblanc",
			Alternate = {"LeblancRE"},
			SpellName = "Ethereal Chains",
			MissileName = "LeblancEMissile",
			Radius = 65,
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Damage = {40,60,80,100,120},
			APScaling = .3,
			Danger = 3,
		},
		
		--[Kogmaw Skills]--
		["KogMawQ"] = 
		{
			HeroName = "Kogmaw",
			SpellName = "Caustic Spittle",
			MissileName = "KogMawQ",
			Radius = 70,
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Damage = {80,130,180,230,280},
			APScaling = .5,
			Danger = 1,
		},
		["KogMawVoidOoze"] = 
		{
			HeroName = "Kogmaw",
			SpellName = "Void Ooze",
			MissileName = "KogMawVoidOozeMissile",
			Radius = 120,
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Damage = {60,105,150,195,240},
			APScaling = .5,
			Danger = 2,
			CCType = BUFF_SLOW
		},
		["KogMawLivingArtillery"] = 
		{
			HeroName = "Kogmaw",
			SpellName = "Living Artillery",
			Radius = 225,
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Damage = {100,140,180},
			APScaling = .25,
			ADScaling = .65,
			Danger = 2,
		},
		
		--[LeeSin Skills]--
		["BlindMonkQOne"] = 
		{
			Alternate = {"BlindMonkQTwo"},
			HeroName = "Leesin",
			SpellName = "Sonic Wave",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,			
			MissileName = "BlindMonkQOne",
			Collision = 1,
			Radius = 60,
			Damage = {55,85,115,145,175},
			ADScaling = .9,
			Danger = 1,
		},
		
		["BlindMonkQTwo"] = 
		{
			Alternate = {"BlindMonkQOne"},
			HeroName = "Leesin",
			SpellName = "Resonating Strike",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			BuffName = "BlindMonkQTwoDash",
			Damage = {55,85,115,145,175},
			ADScaling = .9,
			MissingHealth = .6,
			Danger = 2,
		},
		
		["BlindMonkEOne"] = 
		{
			HeroName = "Leesin",
			SpellName = "Tempest",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 350,
			Damage = {70,105,140,175,210},
			ADScaling = 1,
			Danger = 2,
		},
		
		["BlindMonkRKick"] = 
		{
			HeroName = "Leesin",
			SpellName = "Dragon's Rage",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {150,375,600},
			ADScaling = 2,
			Danger = 4,
			CCType = BUFF_KNOCKBACK,
		},
		
		--[Leona Skills]--
		["LeonaShieldOfDaybreak"] = 
		{
			Alias = "LeonaShieldOfDaybreakAttack",
			HeroName = "Leona",
			SpellName = "Shield of Daybreak",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {10,35,60,85,110},
			APScaling = .3,
			ADScaling = 1,
			Danger = 3,
			CCType = BUFF_STUN
		},
		
		["LeonaZenithBlade"] = 
		{
			HeroName = "Leona",
			SpellName = "Zenith Blade",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,			
			MissileName = "LeonaZenithBladeMissile",
			Radius = 70,
			Damage = {60,100,140,180,220},
			APScaling = .4,
			Danger = 3,
			CCType = BUFF_ROOT
		},
		["LeonaSolarFlare"] = 
		{
			HeroName = "Leona",
			SpellName = "Solar Flare",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 300,
			Damage = {100,175,250},
			APScaling = .8,
			Danger = 5,
			CCType = BUFF_STUN
		},
		
		
		--[Lissandra Skills]--
		
		["LissandraQ"] = 
		{
			Alias = "LissandraQMissile",
			HeroName = "Lissandra",
			SpellName = "Ice Shard",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = {"LissandraQMissile", "LissandraQShards"},
			Radius = 75,
			Damage = {70,100,130,160,190},
			APScaling = .7,
			Danger = 1,
			CCType = BUFF_SLOW
		},
		["LissandraE"] = 
		{
			Alias = "LissandraEMissile",
			HeroName = "Lissandra",
			SpellName = "Glacial Path",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "LissandraEMissile",
			Radius = 125,
			Damage = {70,115,160,205,250},
			APScaling = .6,
			Danger = 1,
		},
		["LissandraR"] = 
		{
			Alias = "LissandraREnemy",
			HeroName = "Lissandra",
			SpellName = "Frozen Tomb",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {150,250,350},
			APScaling = .7,
			Danger = 5,
			CCType = BUFF_STUN
		},
		
		--[Lucian Skills]--
		
		["LucianQ"] = 
		{
			HeroName = "Lucian",
			SpellName = "Piercing Light",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {85,120,155,190,225},
			ADScaling = {.6,.7,.8,.9,1.0},
			Danger = 1,
		},
		["LucianW"] = 
		{
			HeroName = "Lucian",
			SpellName = "Ardent Blaze",
			MissileName = "LucianWMissile",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			Radius = 55,
			Collision = 1,
			Damage = {85,125,165,205,245},
			APScaling = .9,
			Danger = 1,
		},
		["LucianR"] = 
		{
			HeroName = "Lucian",
			SpellName = "The Culling",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = {"LucianRMissile", "LucianRMissileOffhand"},
			Radius = 110,
			Collision = 1,
			Damage = {20,35,50},
			APScaling = .1,
			ADScaling = .25,
			Danger = 1,
		},
		
		--[Lulu Skills]--
		
		["LuluQ"] = 
		{
			HeroName = "Lulu",
			SpellName = "Glitterlance",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = {"LuluQMissile", "LuluQMissileTwo"},
			Radius = 60,
			Damage = {80,125,170,215,260},
			APScaling = .5,
			Danger = 3,
			CCType = BUFF_SLOW
		},
		
		["LuluW"] = 
		{
			Alias = "LuluWTwo",
			HeroName = "Lulu",
			SpellName = "Whimsy",
			SpellSlot = _Q,		
			TargetType = TARGET_TYPE_SINGLE,
			CCType = BUFF_CHARM
		},
		
		--[LUX SKILLS]--
		["LuxLightBinding"] = 
		{
			HeroName = "Lux",
			SpellName = "Light Binding",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "LuxLightBindingMis",
			Collision = 2,
			Radius = 60,
			Damage = {50,100,150,200,250},
			APScaling = .7,
			Danger = 3,
			CCType = BUFF_ROOT
		},
		
		
		["LuxLightStrikeKugel"] = 
		{
			HeroName = "Lux",
			SpellName = "Lucent Singularity",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 350,
			Damage = {60,105,150,195,240},
			APScaling = .6,
			Danger = 2,
			CCType = BUFF_SLOW
		},
		
		["LuxMaliceCannon"] = 
		{
			Alias = "LuxMaliceCannonMis",
			HeroName = "Lux",
			SpellName = "Final Spark",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Radius = 115,
			Damage = {300,400,500},
			APScaling = .75,
			Danger = 5,
		},
		
		--[Malzahar Skills]--
		["MalzaharQ"] = 
		{
			HeroName = "Malzahar",
			SpellName = "Call of the Void",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "MalzaharQMissile",
			Radius = 85,
			Damage = {70,105,140,175,210},
			APScaling = .65,
			Danger = 2,
			CCType = BUFF_SILENCE
		},
		["MalzaharE"] = 
		{
			HeroName = "Malzahar",
			SpellName = "Malefic Visions",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {80,115,150,185,220},
			APScaling = .8,
			Danger = 2,
		},
		["MalzaharR"] = 
		{
			HeroName = "Malzahar",
			SpellName = "Nether Grasp",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {125,200,275},
			APScaling = .8,
			Danger = 5,
			CCType = BUFF_SURPRESS,
		},
		
		--[Maokai skills]--
		["MaokaiQ"] = 
		{
			HeroName = "Maokai",
			SpellName = "Bramble Smash",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "MaokaiQMissile",
			Radius = 110,
			Damage = {65,105,145,185,225},
			APScaling = .4,
			Danger = 2,
			CCType = BUFF_SLOW
		},
		["MaokaiE"] = 
		{
			HeroName = "Maokai",
			SpellName = "Sapling Toss",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			MissileName = "MaokaiEMissile",
			Radius = 120,
			Damage = {25,50,75,100,125},
			MaximumHealth = {.06,.065,.07,.075,.08},
			MaximumHealthAP = .01,
			Danger = 2,
			CCType = BUFF_SLOW
		},
		["MaokaiR"] = 
		{
			HeroName = "Maokai",
			SpellName = "Nature's Grasp",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = {"MaokaiRMis","MaokaiRMisExtra"},
			Radius = 120,
			Damage = {150,225,300},
			APScaling = .75,
			Danger = 4,
			CCType = BUFF_ROOT
		},
		
		--[MALPHITE SKILLS]--
		["SeismicShard"] = 
		{
			HeroName = "Malphite",
			SpellName = "Seismic Shard",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			MissileName = "SeismicShard",
			Damage = {70,120,170,220,270},
			APScaling = .6,
			Danger = 1,
			CCType = BUFF_SLOW
		},
		["Landslide"] = 
		{
			HeroName = "Malphite",
			SpellName = "Ground Slam",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 300,
			Damage = {60,95,130,165,200},
			APScaling = .6,
			Danger = 1,
			CCType = BUFF_SLOW
		},
		--Malphite ult is not active skill, missile or buff... 
		["UFSlash"] = 
		{
			HeroName = "Malphite",
			SpellName = "Unstoppable Force",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 270,
			Damage = {200,300,400},
			APScaling = 1,
			Danger = 5,
			CCType = BUFF_KNOCKUP
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
		
		--[Master Yi Skills]--
		
		["AlphaStrike"] = 
		{
			HeroName = "Master Yi",
			SpellName = "AlphaStrike",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {25,60,95,130,165},
			ADScaling = 1.0,
			Danger = 1,
		},
		
		--[Miss Fortune Skills]--
		["MissFortuneRicochetShot"] = 
		{
			HeroName = "MissFortune",
			SpellName = "Double Up",
			SpellSlot = _Q,
			MissileName = {"MissFortuneRicochetShot", "MissFortuneRShotExtra"},
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {20,40,60,80,100},
			ADScaling = 1.0,
			APScaling = .35,
			Danger = 1,
		},
		["MissFortuneScattershot"] = 
		{
			HeroName = "MissFortune",
			SpellName = "Make It Rain",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 200,
			Damage = {10,14.375,18.75,23.125,27.5},
			APScaling = .1,
			Danger = 1,
			CCType = BUFF_SLOW
		},
		["MissFortuneScattershot"] = 
		{
			HeroName = "MissFortune",
			SpellName = "Bullet Time",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_LINE,
			MissileName = "MissFortuneBullets",
			Radius = 20,
			Damage = {0,0,0},
			APScaling = .2,
			ADScaling = .75,
			Danger = 1,
		},
		
		--[Nami Skills]--
		
		["NamiQ"] = 
		{
			HeroName = "Nami",
			SpellName = "Aqua Prison",
			SpellSlot = _Q,
			MissileName = "NamiQMissile",
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 120,
			Damage = {75,130,185,240,295},
			APScaling = .5,
			Danger = 3,
			CCType = BUFF_KNOCKUP
		},
		
		["NamiW"] = 
		{
			HeroName = "Nami",
			SpellName = "Aqua Prison",
			SpellSlot = _W,
			MissileName = {"NamiWMissileEnemy", "NamiWEnemy"},
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {65,95,125,155,185},
			APScaling = .3,
			Danger = 1,
		},
		
		["NamiE"] = 
		{
			Alias = "NamiCritAttack",
			HeroName = "Nami",
			SpellName = "Tidecaller's Blessing",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {25,40,55,70,85},
			APScaling = .2,
			ADScaling = 1,
			Danger = 1,
			CCType = BUFF_SLOW
		},
		
		["NamiR"] = 
		{
			Alias = "NamiRMissile",
			HeroName = "Nami",
			SpellName = "Tidal Wave",
			SpellSlot = _R,
			MissileName = "NamiRMissile",
			Radius = 250,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,
			Damage = {150,250,350},
			APScaling = .6,
			Danger = 3,
			CCType = BUFF_KNOCKUP
		},
		
		
		--[Nasus Skills]--
		
		["NasusQ"] = 
		{
			Alias = "NasusQAttack",
			HeroName = "Nasus",
			SpellName = "Siphoning Strike",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			SpecialDamage = 
			function (owner, target)
				local buff = BuffManager:GetBuffByName(owner, "NasusQStacks")
				local damage = ({30,50,70,90,110})[owner:GetSpellData(SpellSlot).level] + owner.totalDamage
				if buff then damage = damage + buff.stacks end
				return damage
			end,
			Danger = 1,
		},
		["NasusW"] = 
		{
			HeroName = "Nasus",
			SpellName = "Wither",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			SpecialDamage = 
			function (owner, target)
				return 0
			end,
			Danger = 3,
			CCType = BUFF_SLOW
		},
		["NasusE"] = 
		{
			HeroName = "Nasus",
			SpellName = "Spirit Fire",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 400,
			Damage = {55,95,135,175,215},
			APScaling = .6,
			Danger = 1,
		},
		
		--[Nautilus Skills]--		
		["NautilusAnchorDrag"] = 
		{
			Alternate = {"NautilusRavageStrikeAttack"},
			HeroName = "Nautilus",
			SpellName = "Dredge Line",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "NautilusAnchorDragMissile",
			Radius = 90,
			Collision = 1,
			Damage = {80,120,160,200,240},
			APScaling = .75,
			Danger = 3,			
			CCType = BUFF_SNARE,
		},	
		["NautilusRavageStrikeAttack"] = 
		{
			HeroName = "Nautilus",
			SpellName = "Snare Auto Attack",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			SpecialDamage = 
			function (owner, target)
				return  ({8,14,20,26,32,38,44,50,56,662,68,75,80,86,92,98,104,110})[owner.levelData.lvl] + owner.totalDamage
			end,
			Danger = 1,
			CCType = BUFF_SNARE,
		},	
		["NautilusSplashZone"] = 
		{
			HeroName = "Nautilus",
			SpellName = "Riptide",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 400,
			Damage = {55,85,115,145,175},
			APScaling = .3,
			Danger = 1,			
			CCType = BUFF_SLOW,
		},
		["NautilusGrandLine"] = 
		{
			HeroName = "Nautilus",
			SpellName = "Depth Charge",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {200,325,450},
			APScaling = .8,
			Danger = 5,			
			CCType = BUFF_STUN,
		},
		
		--[Nidalee Skills]--
		["JavelinToss"] = 
		{
			Alternate = {"Takedown"},
			HeroName = "Nidalee",
			SpellName = "Javelin Toss",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "JavelinToss",
			Radius = 45,
			Collision = 1,
			Damage = {70,85,100,115,130},
			APScaling = .4,
			Danger = 2,
		},
		["Takedown"] = 
		{
			Alias = "NidaleeTakedownAttack",
			Alternate = {"JavelinToss"},
			HeroName = "Nidalee",
			SpellName = "Takedown",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {5,30,55,80},
			APScaling = .4,
			ADScaling = .75,
			Danger = 2,
		},
		["PrimalSurge"] = 
		{
			Alternate = {"Swipe"},
			HeroName = "Nidalee",
			SpellName = "Swipe",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {0,0,0,0},
			Danger = 0,
		},
		["Swipe"] = 
		{
			HeroName = "Nidalee",
			SpellName = "Swipe",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_ARC,
			Damage = {70,130,190,250},
			APScaling = .45,
			Danger = 1,
		},
		
		--[Nocturne Skills]--
		["NocturneDuskbringer"] = 
		{
			HeroName = "Nocturne",
			SpellName = "Duskbringer",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "NocturneDuskbringer",
			Radius = 60,
			Damage = {65,110,155,200,245},
			ADScaling = .75,
			Danger = 1,
		},
		
		["NocturneParanoia"] = 
		{
			HeroName = "Nocturne",
			SpellName = "Paranoia",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,		
			--Does not have target... not much I can do here. Trying with low radius circle target instead. 	
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 200,
			BuffName = "nocturneparanoiadash",
			Damage = {150,275,400},
			ADScaling = 1.5,
			Danger = 3,
		},
		
		--[Nunu skills]--
		
		["IceBlast"] = 
		{
			HeroName = "Nunu",
			SpellName = "Ice Blast",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {80,120,160,200,240,280},
			APScaling = .9,
			Danger = 2,
			CCType = BUFF_SLOW,
		},
		["AbsoluteZero"] = 
		{
			HeroName = "Nunu",
			SpellName = "Absolute Zero",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 650,
			Damage = {78,110,140,171},
			APScaling = .31,
			Danger = 2,
			CCType = BUFF_SLOW,
		},
		
		--[Olaf Skills]--
		
		["OlafAxeThrowCast"] = 
		{
			HeroName = "Olaf",
			SpellName = "Undertow",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "OlafAxeThrow",
			Radius = 90,
			Damage = {80,125,170,215,260},
			ADScaling = 1,
			Danger = 1,
			CCType = BUFF_SLOW,
		},
		["OlafRecklessStrike"] = 
		{
			HeroName = "Olaf",
			SpellName = "Reckless Swing",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_TRUE,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {70,115,160,205,250},
			ADScaling = .5,
			Danger = 2,
		},
		
		--[Oriana Skills]--
		
		["OrianaIzunaCommand"] = 
		{
			HeroName = "Oriana",
			SpellName = "Command: Attack",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "OrianaIzuna",
			Radius = 90,
			Damage = {60,90,120,150,180},
			APScaling = .5,
			Danger = 1,
		},
		["OrianaRedactCommand"] = 
		{
			HeroName = "Oriana",
			SpellName = "Command: Protect",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "OrianaRedact",
			Radius = 90,
			Damage = {60,90,120,150,180},
			APScaling = .3,
			Danger = 1,
		},
		--["OrianaDetonateCommand"] = 
		--{
			--The cast position is always at oriana's location not the ball's location... currently there is no graceful way to handle this
		--	HeroName = "Oriana",
		--	SpellName = "Command: Shockwave",
		--	SpellSlot = _R,
		--	DamageType = DAMAGE_TYPE_MAGICAL,			
		--	TargetType = TARGET_TYPE_CIRCLE,
		--	Radius = 410,
		--	Damage = {60,90,120,150,180},
		--	APScaling = .3,
		--	Danger = 1,
		--},
		
		--[Ornn skills]--
		
		["OrnnQ"] = 
		{
			HeroName = "Ornn",
			SpellName = "Volcanic Rupture",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "OrnnQ",
			Radius = 65,
			Damage = {20,50,80,110,140},
			ADScaling = 1,
			Danger = 1,
			CCType = BUFF_SLOW,
		},
		["OrnnE"] = 
		{
			HeroName = "Ornn",
			SpellName = "Searing Charge",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			Radius = 150,
			Damage = {80,125,170,215,260},
			Danger = 3,
			CCType = BUFF_KNOCKUP,
		},
		["OrnnR"] = 
		{
			Alternate = {"OrnnR2"},
			HeroName = "Ornn",
			SpellName = "Call of the Forge God",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "OrnnRWave",
			Radius = 250,
			Damage = {125,175,225},
			APScaling = .2,
			Danger = 3,
			CCType = BUFF_SLOW,
		},
		["OrnnR2"] = 
		{
			HeroName = "Ornn",
			SpellName = "Call of the Forge God",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "OrnnRWave2",
			Radius = 250,
			Damage = {125,175,225},
			APScaling = .2,
			Danger = 3,
			CCType = BUFF_KNOCKUP,
		},
		
		--[Pantheon Skills]--
		
		["PantheonQ"] = 
		{
			HeroName = "Pantheon",
			SpellName = "Spear Shot",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {75,115,155,195,235},
			BonusADScaling = 1.4,
			Danger = 1,
		},
		["PantheonE"] = 
		{
			HeroName = "Pantheon",
			SpellName = "Heartseeker Strike",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_ARC,
			Damage = {50,75,100,125,150},
			BonusADScaling = 1.5,
			Danger = 1,
		},
		
		--[Poppy Skills]--
		["PoppyQ"] = 
		{
			Alias = "PoppyQSpell",
			HeroName = "Poppy",
			SpellName = "Hammer Shock",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			Radius = 100,
			Damage = {40,60,80,100,120},
			BonusADScaling = .8,
			MaximumHealth = .08,
			Danger = 1,
		},
		["PoppyR"] = 
		{
			Alias = "PoppyRSpell",
			Alternate = {"PoppyRSpellInstant"},
			HeroName = "Poppy",
			SpellName = "Keeper's Verdict",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			Radius = 100,
			MissileName = "PoppyRMissile",
			Damage = {200,300,400},
			BonusADScaling = .9,
			Danger = 4,
			CCType = BUFF_KNOCKUP,
		},
		["PoppyRSpellInstant"] = 
		{
			HeroName = "Poppy",
			SpellName = "Keeper's Verdict",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 200,
			Damage = {200,300,400},
			BonusADScaling = .9,
			Danger = 4,
			CCType = BUFF_KNOCKUP,
		},
		
		--[Pyke Skills]--
		["PykeQ"] = 
		{
			Alternate = {"PykeQMelee","PykeQRange"},
			HeroName = "Pyke",
			SpellName = "Bone Skewer",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {0,0,0,0,0},
			Danger = 1,
		},
		
		["PykeQMelee"] = 
		{
			HeroName = "Pyke",
			SpellName = "Bone Skewer",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			Radius = 100,
			Length = 400,
			Damage = {86.25,143.75,201.25,258.75,315.25},
			BonusADScaling = .69,
			Danger = 2,
			SetOrigin = true,
			CCType = BUFF_SLOW,
		},
		
		["PykeQRange"] = 
		{
			HeroName = "Pyke",
			SpellName = "Bone Skewer",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			Radius = 70,
			Collision = 1,
			Damage = {75,125,175,225,275},
			BonusADScaling = .6,
			Danger = 3,
			CCType = BUFF_KNOCKBACK,
		},
		["PykeR"] = 
		{
			HeroName = "Pyke",
			SpellName = "Death from Below",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_TRUE,
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 300,
			SpecialDamage = 
				function (owner, target)
					return ({190,190,190,190,190,190,240,290,340,390,440,475,510,545,580,615,635,655})[owner.levelData.lvl] + owner.bonusDamage * .6
				end,
			Danger = 3,
		},
		
		--[Quinn Skills]--
		["QuinnQ"] = 
		{
			HeroName = "Quinn",
			SpellName = "Blinding Assault",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName = "QuinnQ",
			Radius = 60,
			Damage = {20,45,70,95,120},
			ADScaling = {.8,.9,1.0,1.1,1.2},
			Danger = 1,
			CCType = BUFF_BLIND,
		},
		["QuinnW"] = 
		{
			Alias = "QuinnWEnhanced",
			HeroName = "Quinn",
			SpellName = "Harrier",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			SpecialDamage = 
			function (owner, target)
				return 10 + owner.levelData.lvl * 5 + ({1.16, 1.18,1.2,1.22,1.26,1.28,1.3,1.32,1.34,1.36,1.38,1.4,1.42,1.44,1.46,1.48,1.5})[owner.levelData.lvl] * owner.totalDamage 
			end,
			Danger = 1,
		},
		
		["QuinnE"] = 
		{
			HeroName = "Quinn",
			SpellName = "Vault",
			BuffName = "QuinnE",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {40,70,100,130,160},
			BonusADScaling = .2,
			Danger = 1,
			CCType = BUFF_SLOW,
		},
		
		--[Rakan Skills]--
		["RakanQ"] = 
		{
			HeroName = "Rakan",
			SpellName = "Gleaming Quill",
			MissileName = "RakanQMis",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			Radius = 65,
			Collision = 1,
			Damage = {70,115,160,205,250},
			APScaling = .6,
			Danger = 1,
		},
		["RakanW"] = 
		{
			Alias = "RakanWCast",
			HeroName = "Rakan",
			SpellName = "Grand Entrance",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Damage = {70,115,160,205,250},
			Radius = 250,
			APScaling = .7,
			Danger = 3,			
            CCType = BUFF_KNOCKUP,
		},
		
		--[Rammus Skills]--		
		["PuncturingTaunt"] = 
		{
			HeroName = "Rammus",
			SpellName = "Frenzying Taunt",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {0,0,0,0,0},
			Danger = 5,			
            CCType = BUFF_TAUNT,
		},
		
		--[RekSai Skills]--
		
		["RekSaiQ"] = 
		{
			Alternate = {"RekSaiQBurrowed"},
			HeroName = "RekSai",
			SpellName = "Frenzying Taunt",
			SpellSlot = _Q,
		},
		
		["RekSaiQBurrowed"] = 
		{
			HeroName = "RekSai",
			SpellName = "Prey Seeker",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			Collision = 1,
			MissileName="RekSaiQBurrowedMis",
			Radius = 65,
			Damage = {60,90,120,150,180},
			BonusADScaling = .4,
			APScaling = .7,
			Danger = 1,			
		},
		["RekSaiE"] = 
		{
			HeroName = "RekSai",
			SpellName = "Frenzying Taunt",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {55,65,75,85,95},
			BonusADScaling = .85,
			Danger = 1,			
		},
		
		--Doesn't work sadly...
		["RekSaiRWrapper"] = 
		{
			HeroName = "RekSai",
			SpellName = "Void Rush",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			BuffName = "RekSaiR2",
			Damage = {100,250,400},
			BonusADScaling = 1.85,
			MissingHealth = {.2,.25,.3},
			Danger = 3,			
		},
		
		
		--[Renekton Skills]--		
		
		["RenektonPreExecute"] = 
		{
			Alternate = {"RenektonSuperExecute"},
			Alias = "RenektonExecute",
			HeroName = "Renekton",
			SpellName = "Ruthless Predator",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {10,30,50,70,90},
			ADScaling = 1.5,
			Danger = 3,
			CCType = BUFF_STUN,	
		},
		["RenektonSuperExecute"] = 
		{
			HeroName = "Renekton",
			SpellName = "Ruthless Predator",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {15,45,75,105,135},
			ADScaling = 2.25,
			Danger = 4,
			CCType = BUFF_STUN,	
		},
		
		--[Rengar Skills]--
		
		["RengarQ"] = 
		{
			Alternate = {"RengarQEmpAttack"},
			Alias = "RengarQAttack",
			HeroName = "Rengar",
			SpellName = "Savagery",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {30,60,90,120,150},
			ADScaling = {1,1.05,1.1,1.15,1.2},
			Danger = 1,
		},
		["RengarQEmpAttack"] = 
		{
			HeroName = "Rengar",
			SpellName = "Savagery",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {30,60,90,120,150},
			ADScaling = 1.5,
			Danger = 1,
		},
		["RengarE"] = 
		{
			Alternate = {"RengarEEmp"},
			HeroName = "Rengar",
			SpellName = "Bola Strike",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName="RengarEMis",
			Collision = 1,
			Radius = 70,
			Damage = {50,100,145,190,235},
			BonusADScaling = .8,
			Danger = 1,
			CCType = BUFF_SLOW,
		},
		["RengarEEmp"] = 
		{
			HeroName = "Rengar",
			SpellName = "Bola Strike",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName="RengarEEmpMis",
			Collision = 1,
			Radius = 70,
			Damage = {50,100,145,190,235},
			BonusADScaling = .8,
			Danger = 1,
			CCType = BUFF_SNARE,
		},
		
		--[Riven Skills]--
		
		["RivenMartyr"] = 
		{
			HeroName = "Riven",
			SpellName = "Ki Burst",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 125,
			Damage = {55,85,115,145,175},
			BonusADScaling = 1,
			Danger = 2,
			CCType = BUFF_STUN,
		},
		["RivenFengShuiEngine"] = 
		{
			Alias = "RivenIzunaBlade",
			HeroName = "Riven",
			SpellName = "Blade of the Exile",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_ARC,
			Damage = {100,150,200},
			BonusADScaling = .6,
			Danger = 4,
		},
		
		--[Rumble Skills]--
		
		["RumbleGrenade"] = 
		{
			Alternate = {"RumbleGrenadeEmp"},
			HeroName = "Rumble",
			SpellName = "Electro Harpoon",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName="RumbleGrenadeMissile",
			Collision = 1,
			Radius = 60,
			Damage = {60,85,110,135,160},
			APScaling = .4,
			Danger = 2,
			CCType = BUFF_SLOW,
		},
		["RumbleGrenadeEmp"] = 
		{
			HeroName = "Rumble",
			SpellName = "Electro Harpoon",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName="RumbleGrenadeMissileDangerZone",
			Collision = 1,
			Radius = 60,
			Damage = {90,127,165,202,240},
			APScaling = .6,
			Danger = 3,
			CCType = BUFF_SLOW,
		},
		["RumbleCarpetBomb"] = 
		{
			HeroName = "Rumble",
			SpellName = "The Equalizer",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName="RumbleCarpetBombMissile",
			Radius = 200,
			Damage = {200,300,400},
			APScaling = .45,
			Danger = 5,
			CCType = BUFF_SLOW,
		},
		
		
		--[Ryze Skills]--
		
		["RyzeQWrapper"] = 
		{
			HeroName = "Ryze",
			SpellName = "Overload",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName="RyzeQ",
			Collision = 1,
			Radius = 55,
			Damage = {60,75,110,135,160,185},
			APScaling = .45,
			Danger = 1,
		},
		["RyzeW"] = 
		{
			HeroName = "Ryze",
			SpellName = "Rune Prison",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {80,100,120,140,160},
			APScaling = .6,
			Danger = 2,
			CCType = BUFF_ROOT,
		},
		["RyzeE"] = 
		{
			HeroName = "Ryze",
			SpellName = "Overload",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {70,90,110,130,150},
			APScaling = .3,
			Danger = 1,
		},
		
		--[Sejuani Skills]--
		["SejuaniW"] = 
		{
			--wont work because cast position is wrong. Dummy skill is the follow up
			Alias = "SyndraWDummy",
			HeroName = "Sejuani",
			SpellName = "Winter's Wrath",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_ARC,
			Radius = 65,
			Length = 600,
			Damage = {30,65,100,135,170},
			MaximumHealth = .045,
			Danger = 1,
		},
		["SejuaniE"] = 
		{
			Alias = "SejuaniE2",
			HeroName = "Sejuani",
			SpellName = "Permafrost",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {20,30,40,50,60},
			APScaling = .3,
			Danger = 3,			
			CCType = BUFF_STUN,
		},
		["SejuaniR"] = 
		{
			HeroName = "Sejuani",
			SpellName = "Glacial Prison",			
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			Radius = 120,
			Damage = {100,125,150},
			APScaling = .4,
			Danger = 4,			
			CCType = BUFF_STUN,
		},
		
		--[Syndra Skills]--
		["SyndraQ"] = 
		{
			HeroName = "Syndra",
			SpellName = "Dark Sphere",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,			
			MissileName = "SyndraQSpell",
			Radius = 200,
			Damage = {50,95,140,185,230, 264.5},
			APScaling ={.65, .65, .65, .65, .65, .7475},
			Danger = 1,
		},
		
		["SyndraE"] = 
		{
			HeroName = "Syndra",
			Alternate = {"SyndraEMis"},
			SpellName = "Scatter the Weak",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_ARC,
			Damage = {70,115,160,205,250},
			APScaling =.6,
			Danger = 3,
			CCType = BUFF_KNOCKBACK,
		},
		
		["SyndraEMis"] = 
		{
			HeroName = "Syndra",
			SpellName = "Scatter the Weak",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			TargetType = TARGET_TYPE_LINE,		
			MissileName = "SyndraESphereMissile",
			Radius = 75,
			Damage = {70,115,160,205,250},
			APScaling =.6,
			Danger = 4,
			CCType = BUFF_STUN,
		},
		
		["SyndraR"] = 
		{
			HeroName = "Syndra",
			Alias = "SyndraRCastTime",
			SpellName = "Unleashed Power",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {270,405,540},
			APScaling =.6,
			Danger = 4,
		},
		
		
		--[Volibear Skills]--
		
		["VolibearQ"] = 
		{
			Alias = "VolibearQAttack",
			HeroName = "Volibear",
			SpellName = "Rolling Thunder",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {30,60,90,120,150},
			ADScaling = 1,
			Danger = 3,
			CCType = BUFF_KNOCKBACK,
		},
		["VolibearW"] = 
		{
			HeroName = "Volibear",
			SpellName = "Frenzy",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {60,110,160,210,260},
			BonusHealth = .15,
			Danger = 1,
		},
		["VolibearR"] = 
		{
			HeroName = "Volibear",
			SpellName = "Thunder Claws",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 500,
			Damage = {75,115,155},
			APScaling = .3,
			Danger = 1,
		},
		
		--[Veigar Skills]--
		
		["VeigarBalefulStrike"] = 
		{
			HeroName = "Veigar",
			SpellName = "Baleful Strike",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			Collision = 2,
			Radius = 70,
			Damage = {70,110,150,190,230},
			APScaling = .6,
			Danger = 1,
		},
		["VeigarEventHorizon"] = 
		{
			HeroName = "Veigar",
			SpellName = "Event Horizon",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_RING,
			Radius = 300,
			Ring = 80,
			Damage = {0,0,0,0,0},
			Danger = 4,
			CCType = BUFF_STUN,
		},
		["VeigarR"] = 
		{
			HeroName = "Veigar",
			SpellName = "Primordial Burst",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_SINGLE,
			Damage = {175,250,325},
			APScaling = .75,
			Danger = 4,
		},
		
		--[Warwick Skills]--
		
		["WarwickQ"] =
        {
            HeroName = "Warwick",
            SpellName = "Jaws of the Beast",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_SINGLE,
            Damage = {0,0,0,0,0},
            ADScaling = 1.2,
			APScaling = .9,
			MaximumHealth = {.06,.065,.08,.075,.08},
            Danger = 1,
        },
		
		["WarwickR"] =
        {
            HeroName = "Warwick",
            SpellName = "Infinite Duress",
            SpellSlot = _R,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_LINE,
			BuffName = "WarwickR",
			Radius = 100,
            Damage = {175,350,525},
            BonusADScaling = 1.67,
            Danger = 5,
			CCType = BUFF_SURPRESS,
        },
		
		--[Wukong Skills]--
		["MonkeyKingDoubleAttack"] =
        {
			Alias = "MonkeyKingQAttack",
            HeroName = "MonkeyKing",
            SpellName = "Crushing Blow",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_SINGLE,
            Damage = {30,60,90,120,150},
            ADScaling = {1.10,1.20,1.30,1.40,1.50},
            Danger = 1,
        },
		
		["MonkeyKingNimbus"] =
        {
            HeroName = "MonkeyKing",
            SpellName = "Nimbus Strike",
            SpellSlot = _E,
            BuffName = "MonkeyKingNimbusKick",
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_SINGLE,
            Damage = {65,110,155,200,245},
            BonusADScaling = .8,
            Danger = 1,
        },
		
		["MonkeyKingSpinToWin"] =
        {
            HeroName = "MonkeyKing",
            SpellName = "Cyclone",
            SpellSlot = _R,
            BuffName = "MonkeyKingSpinToWin",
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_CIRCLE,
            Radius = 375,
            Damage = {20,120,200},
            ADScaling = 1.1,
            CCType = BUFF_KNOCKUP,
            Danger = 5,
        },
		
		--[Xayah Skills]--
        ["XayahQ"] = 
        {
            HeroName = "Xayah",
            SpellName = "Double Daggers",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_PHYSICAL, 
            TargetType = TARGET_TYPE_LINE,
			Length=  1100,
            Radius = 45,
            Damage = {90,130,150,210,250},
            BonusADScaling = 1,
            Danger = 1,
        },
		--Can't work currently because it will not show as correct team. Missile doesnt have proper owner data
		
        --["XayahE"] = 
        --{
        --    HeroName = "Xayah",
        --   SpellName = "Bladecaller",
        --    SpellSlot = _E,
        --    DamageType = DAMAGE_TYPE_PHYSICAL, 
        --    TargetType = TARGET_TYPE_LINE,
		--	MissileName = "XayahEMissile",
        --    Radius = 45,
        --    Damage = {55,65,75,85,95},
        --    BonusADScaling = .6,
        --    Danger = 2,
        --},
        ["XayahR"] = 
        {
            HeroName = "Xayah",
            SpellName = "Featherstorm",
            SpellSlot = _R,
            DamageType = DAMAGE_TYPE_PHYSICAL, 
            TargetType = TARGET_TYPE_ARC,
			BuffName = "XayahR",
			--MissileName = "XayahRMissile",
            --Radius = 45,
			Angle = 30,
			Radius = 1100,
            Damage = {100,150,200},
            BonusADScaling = 1,
            Danger = 3,
        },
		
		--[XERATH SKILLS]--
        ["XerathArcanopulseChargeUp"] = 
        {
            HeroName = "Xerath",
            SpellName = "Arcanopulse",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_LINE,
            Radius = 125,
            Damage = {80,120,160,200,240},
            APScaling = .75,
            Danger = 2,
        },
        ["XerathArcaneBarrage2"] = 
        {
            HeroName = "Xerath",
            SpellName = "Eye of Destruction",
            SpellSlot = _W,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_CIRCLE,
            Radius = 200,
            Damage = {60,90,120,150,180},
            APScaling = .6,
            Danger = 2,
			CCType = BUFF_SLOW,
        },
        ["XerathMageSpear"] = 
        {
            HeroName = "Xerath",
            SpellName = "Shocking Orb",
			MissileName = "XerathMageSpearMissile",
            SpellSlot = _E,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_LINE,
			Collision = 1,
            Radius = 60,
            Damage = {80,110,140,170,200},
            APScaling = .45,
            Danger = 2,
			CCType = BUFF_STUN,
        },
        ["XerathLocusOfPower2"] = 
        {
            HeroName = "Xerath",
            SpellName = "Rite of the Arcane",
			MissileName = "XerathLocusPulse",
            SpellSlot = _E,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_CIRCLE,
            Radius = 120,
            Damage = {200,240,280},
            APScaling = .43,
            Danger = 4,
			MissileTime = .5
        },
		
		--[Xin Zhao Skills]--
		["XinZhaoQ"] = 
        {
			Alias = "XinZhaoQThrust1",
			Alternate = {"XinZhaoQThrust2","XinZhaoQThrust3"},
            HeroName = "XinZhao",
            SpellName = "Three Talon Strike",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_SINGLE,
            Damage = {20,25,30,35,40},
			BonusADScaling = .4,
			ADScaling = 1,
            Danger = 1,
        },
		["XinZhaoQThrust2"] = 
        {
            HeroName = "XinZhao",
            SpellName = "Three Talon Strike",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_SINGLE,
            Damage = {20,25,30,35,40},
			BonusADScaling = .4,
			ADScaling = 1,
            Danger = 1,
        },
		["XinZhaoQThrust3"] = 
        {
            HeroName = "XinZhao",
            SpellName = "Three Talon Strike",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_SINGLE,
            Damage = {20,25,30,35,40},
			BonusADScaling = .4,
			ADScaling = 1,
            Danger = 3,
			CCType = BUFF_KNOCKUP,
        },
		["XinZhaoW"] = 
        {
            HeroName = "XinZhao",
            SpellName = "Wind Becomes Lightning",
            SpellSlot = _W,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_LINE,
			Radius = 45,
            Damage = {30,40,50,60,70},
			ADScaling = .31,
            Danger = 2,
			CCType = BUFF_SLOW,
        },
		["XinZhaoR"] = 
        {
            HeroName = "XinZhao",
            SpellName = "Crescent Guard",
            SpellSlot = _R,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_CIRCLE,
			Radius = 550,
            Damage = {70,175,275},
			BonusADScaling = 1,
			CurrentHealth = .15,
            Danger = 2,
			CCType = BUFF_KNOCKBACK,
        },
		
		--[Yasuo Skills]--
		["YasuoQW"] = 
        {
			Alias = "YasuoQ",
			Alternate = {"YasuoQ2", "YasuoQ3","YasuoQ3Mis"},
            HeroName = "Yasuo",
            SpellName = "Steel Tempest",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_LINE,
			Radius = 50,
            Damage = {20,45,75,95,120},
			ADScaling = 1,
            Danger = 1,
        },
		["YasuoQ2"] = 
        {
            HeroName = "Yasuo",
            SpellName = "Steel Tempest",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_LINE,
			Radius = 45,
            Damage = {20,45,75,95,120},
			ADScaling = 1,
            Danger = 1,
        },
		["YasuoQ3"] = 
        {
            HeroName = "Yasuo",
            SpellName = "Steel Tempest",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_LINE,
			Radius = 45,
            Damage = {20,45,75,95,120},
			ADScaling = 1,
            Danger = 3,
			CCType = BUFF_KNOCKUP,
        },
		["YasuoQ3Mis"] = 
        {
            HeroName = "Yasuo",
            SpellName = "Steel Tempest",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_LINE,
			MissileName = "YasuoQ3Mis",
			Radius = 90,
            Damage = {20,45,75,95,120},
			ADScaling = 1,
            Danger = 3,
			CCType = BUFF_KNOCKUP,
        },
		["YasuoRKnockUpComboW"] = 
        {
            HeroName = "Yasuo",
            SpellName = "Steel Tempest",
            SpellSlot = _R,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_SINGLE,
			MissileName = "TempYasuoRMissile",
            Damage = {200,300,400},
			BonusADScaling = 1.5,
            Danger = 3,
        },
		["YorickE"] = 
        {
            HeroName = "Yorick",
            SpellName = "Mourning Mist",
            SpellSlot = _E,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_ARC,
			Radius = 600,
            Damage = {70,105,140,175,210},
			CurrentHealth = .15,
            APScaling = .7,
            Danger = 3,
			CCType = BUFF_KNOCKUP,
        },
		
		--[Zac Skills]--
		["ZacQ"] = 
        {
            HeroName = "Zac",
            SpellName = "Stretching Strikes",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_LINE,
            Radius = 80,
            Damage = {30,40,50,60,70},
			MyHealth = .025, 
            APScaling = .3,
            Danger = 2,
			CCType = BUFF_SLOW,
        },
		["ZacE"] = 
        {
            HeroName = "Zac",
            SpellName = "Elastic Slingshot",
            SpellSlot = _E,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_CIRCLE,
			BuffName = "zacemove",
            Radius = 300,
            Damage = {60,110,160,210,260},
            APScaling = .9,
            Danger = 3,
			CCType = BUFF_KNOCKUP,
        },
		["ZacR"] = 
        {
            HeroName = "Zac",
            SpellName = "Let's Bounce!",
            SpellSlot = _R,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_CIRCLE,
			BuffName = "ZacR",
            Radius = 300,
            Damage = {150,250,350},
            APScaling = .9,
            Danger = 3,
			CCType = BUFF_KNOCKUP,
        },
		
		
		--[ZED SKILLS]--
        ["ZedQ"] = 
        {
            HeroName = "Zed",
            SpellName = "Razor Shuriken",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_LINE,
            MissileName = "ZedQMissile",
            Radius = 50,
            Damage = {80,115,150,185,220},
            APScaling = .9,
            Danger = 2,
        },
        ["ZedR"] = 
        {
            HeroName = "Zed",
            SpellName = "Death Mark",
            SpellSlot = _R,
            DamageType = DAMAGE_TYPE_PHYSICAL,
            TargetType = TARGET_TYPE_SINGLE,
            BuffName = "ZedR2",
            Damage = {0,0,0},
            ADScaling = 1,
            Danger = 5,
        },
		
		
		--[ZIGGS SKILLS]--
        ["ZiggsQ"] = 
        {
            HeroName = "Ziggs",
            SpellName = "Bouncing Bomb",
			MissileName = {"ZiggsQSpell", "ZiggsQSpell2", "ZiggsQSpell3"},
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_CIRCLE,
            Radius = 140,
            Damage = {75,120,165,210,255},
            APScaling = .65,
            Danger = 2,
        },
        ["ZiggsW"] = 
        {
            HeroName = "Ziggs",
            SpellName = "Satchel Charge",
            SpellSlot = _W,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_CIRCLE,
            Radius = 275,
            Damage = {70,105,140,175,210},
            APScaling = .35,
            Danger = 2,
        },
        ["ZiggsE"] = 
        {
            HeroName = "Ziggs",
            SpellName = "Hexplosive Minefield",
			MissileName = "ZiggsE3",
            SpellSlot = _E,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_CIRCLE,
            Radius = 120,
            Damage = {40,75,110,145,180},
            APScaling = .30,
            Danger = 2,
			CCType = BUFF_SLOW,
        },
        ["ZiggsR"] = 
        {
            HeroName = "Ziggs",
            SpellName = "Mega Inferno Bomb",
			MissileName = "ZiggsRBoom",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_CIRCLE,
            Radius = 500,
            Damage = {200,300,400},
            APScaling = .733,
            Danger = 5,
        },
		
		
		--[ZILEAN SKILLS]--
		["ZileanQ"] = 
		{
			HeroName = "Zilean",
			SpellName = "Time Bomb",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			MissileName = "ZileanQMissile",
			Radius = 120,
			Damage = {75,115,165,230,300},
			APScaling = .9,
			Danger = 3,
		},
		
		--[Zoe Skills]--
		["ZoeBasicAttackSpecial"] = 
		{
            HeroName = "Zoe",
            SpellName = "More Sparkles!",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_SINGLE,
            Damage = {0,0,0,0,0},
			ADScaling = 1,
            APScaling = .325,
            Danger = 1,
        },
		["ZoeQ"] = 
		{
			Alias = "ZoeQMissile",
			Alternate = {"ZoeBasicAttackSpecial"},
            HeroName = "Zoe",
            SpellName = "PaddleStar",
            SpellSlot = _Q,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_LINE,
			Radius = 70,
            MissileName = {"ZoeQMissile","ZoeQMis2"},
            Damage = {50,75,100,125,150},
            APScaling = .6,
            Danger = 2,
        },
		["ZoeW"] = 
		{
            HeroName = "Zoe",
            SpellName = "Spell Thief",
            SpellSlot = _W,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_SINGLE,
			BuffName = "ZoeWPassive",
            Damage = {75,120,165,210,255},
            APScaling = .75,
            Danger = 1,
        },
		["ZoeE"] = 
		{
            HeroName = "Zoe",
            SpellName = "Sleepy Trouble Bubble",
            SpellSlot = _E,
            DamageType = DAMAGE_TYPE_MAGICAL,
            TargetType = TARGET_TYPE_LINE,
			Radius = 70,
			MissileName = {"ZoeEMis"},
            Damage = {120,200,280,350,360,440},
            APScaling = .4,
            Danger = 4,
        },
		
		
		--[Zyra Skills]--
		["ZyraQ"] = 
		{
			HeroName = "Zyra",
			SpellName = "Deadly Spines",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_BOX,
			Radius = 85,
			Length = 375,
			Damage = {60,95,130,165,200},
			APScaling = .6,
			Danger = 2,
		},
		["ZyraE"] = 
		{
			HeroName = "Zyra",
			SpellName = "Grasping Roots",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_LINE,
			MissileName="ZyraE",
			Radius = 70,
			Damage = {60,105,150,195,240},
			APScaling = .5,
			Danger = 3,
			CCType = BUFF_ROOT,
		},
		["ZyraR"] = 
		{
			HeroName = "Zyra",
			SpellName = "Stranglethorns",
			SpellSlot = _R,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			TargetType = TARGET_TYPE_CIRCLE,
			Radius = 500,
			Damage = {180,265,350},
			APScaling = .7,
			Danger = 4,
			CCType = BUFF_KNOCKUP,
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
				if spellData.Alias then spellName = spellData.Alias end
				self:LoadSpell(spellName, spellData, target)
				--Load all alternate versions of spell
				if spellData.Alternate then
					for _, x in LocalPairs(spellData.Alternate) do
						spellName = x
						spellData = self.MasterSkillLookupTable[spellName]
						if spellData.Alias then spellName = spellData.Alias end
						self:LoadSpell(spellName, spellData, target)
					end					
				end
			else
				print("Unhandled skill: " .. spellName .. " on " .. target.charName)
			end
		end
	end	
	self.CallbacksInitialized = false
	
end

--Helper method to enable all the callbacks needed to calculate damage. By default we dont need to track all this shit.
function __DamageManager:InitializeCallbacks()
	DamageManager.CallbacksInitialized = true
	ObjectManager:OnMissileCreate(function(args) DamageManager:MissileCreated(args) end)
	ObjectManager:OnMissileDestroy(function(args) DamageManager:MissileDestroyed(args) end)	
	ObjectManager:OnBuffAdded(function(owner, buff) DamageManager:BuffAdded(owner, buff) end)
	LocalCallbackAdd('Tick',  function() DamageManager:Tick() end)
	ObjectManager:OnSpellCast(function(args) DamageManager:SpellCast(args) end)
end

function __DamageManager:LoadSpell(spellName, spellData, target)				
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
	elseif spellData.BuffName then
		self.BuffNames[spellData.BuffName] = spellData
	else
		self.Skills[spellName] = spellData
	end
	
	if not self.AllSkills[spellName] then
		self.AllSkills[spellName] = spellData
	end
	print("Loaded skill: " .. spellName .. " on " .. target.charName)
end

local nextDamageTick = LocalGameTimer()
function __DamageManager:Tick()
	local currentTime = LocalGameTimer()	
	if nextDamageTick > currentTime then return end
	nextDamageTick = currentTime + .1
	
	for _, expires in LocalPairs(self.IgnoredCollisions) do
		if currentTime > expires then
			self.IgnoredCollisions[_] = nil
		end
	end
	
	for _, skillshot in LocalPairs(self.EnemySkillshots) do
		if skillshot and skillshot.data and not self.IgnoredCollisions[skillshot.networkID] then
			if skillshot.Sort == TARGET_TYPE_LINE then
				self:CheckLineMissileCollision(skillshot, self.AlliedHeroes)
			elseif skillshot.Sort ==TARGET_TYPE_CIRCLE then
				self:CheckCircleMissileCollision(skillshot, self.AlliedHeroes)
			end
		end
	end
	for _, skillshot in LocalPairs(self.AlliedSkillshots) do
		if skillshot and skillshot.data  and not self.IgnoredCollisions[skillshot.networkID] then
			if skillshot.Sort == TARGET_TYPE_LINE then
				self:CheckLineMissileCollision(skillshot, self.EnemyHeroes)
			elseif skillshot.Sort ==TARGET_TYPE_CIRCLE then			
				self:CheckCircleMissileCollision(skillshot, self.EnemyHeroes)
			end
		end
	end
end


function __DamageManager:IncomingDamage(owner, target, damage, ccType, canDodge)		
	if AlphaMenu.PrintDmg:Value() then
		if owner and target then
			print(owner.charName .. " will hit " .. target.charName .. " for " .. damage .. " Damage")
		else
			print("No owner/target __DamageManager:IncomingDamage")
		end
	end		
	--Trigger any registered OnCC callbacks. Send them the target, damage and type of cc so we can choose our actions
	if ccType and #self.OnIncomingCCCallbacks then
		self:IncomingCC(target, damage, ccType, canDodge)
	end
end

function __DamageManager:CheckLineMissileCollision(skillshot, targetList)
	local distRemaining = Geometry:GetDistance(skillshot.data.pos, skillshot.data.missileData.endPos)	
	local step = LocalMin(distRemaining, skillshot.data.missileData.speed  * .5)
	local nextPosition = skillshot.data.pos + skillshot.forward * step
	local owner = ObjectManager:GetObjectByHandle(skillshot.data.missileData.owner)
	for _, target in LocalPairs(targetList) do
		if target~= nil and LocalType(target) == "userdata" then
			local nextTargetPos = Geometry:PredictUnitPosition(target, .5)
			local proj1, pointLine, isOnSegment = Geometry:VectorPointProjectionOnLineSegment(skillshot.data.pos, nextPosition, nextTargetPos)
			if isOnSegment and Geometry:IsInRange(nextTargetPos, pointLine, skillshot.data.missileData.width + target.boundingRadius) then
				local damage = self:CalculateSkillDamage(owner, target, self.MissileNames[skillshot.name])
				self:IncomingDamage(owner, target, damage, self.MissileNames[skillshot.name].CCType,true)
				self.IgnoredCollisions[skillshot.networkID] = LocalGameTimer() + 1
			end
		end
	end
end

function __DamageManager:CheckCircleMissileCollision(skillshot, targetList)
	if skillshot.endTime - LocalGameTimer() < .25 then
		local owner = ObjectManager:GetObjectByHandle(skillshot.data.missileData.owner)		
		for _, target in LocalPairs(targetList) do
			if target~= nil and LocalType(target) == "userdata" then
				local nextTargetPos = Geometry:PredictUnitPosition(target, .2)
				if Geometry:IsInRange(nextTargetPos, skillshot.data.missileData.endPos, skillshot.Radius or( skillshot.data.missileData.width + target.boundingRadius)) then
					local damage = self:CalculateSkillDamage(owner, target, self.MissileNames[skillshot.name])
					self:IncomingDamage(owner, target, damage, self.MissileNames[skillshot.name].CCType,true)
					self.IgnoredCollisions[skillshot.networkID] = LocalGameTimer() + 1
				end
			end
		end
	end
end

function __DamageManager:SpellCast(spell)
	if AlphaMenu.PrintSkill:Value() then print(spell.name) end
	
	if self.Skills[spell.name] then
		local owner = ObjectManager:GetObjectByHandle(spell.handle)
		if owner == nil then return end
		
		local collection = self.EnemyHeroes
		if owner.isEnemy then
			collection = self.AlliedHeroes
		end
		
		local spellInfo = self.Skills[spell.name]
		if spellInfo.TargetType == TARGET_TYPE_SINGLE then			
			local target = ObjectManager:GetHeroByHandle(spell.data.target)
			if target then
				local damage = self:CalculateSkillDamage(owner, target, spellInfo)
				self:IncomingDamage(owner, target, damage, spellInfo.CCType)
			end
		elseif spellInfo.TargetType == TARGET_TYPE_CIRCLE and spellInfo.Radius then
			local castPos = LocalVector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z)			
			for _, target in LocalPairs(collection) do
				if target ~= nil and LocalType(target) == "userdata" then
					if Geometry:IsInRange(castPos, target.pos, spellInfo.Radius + target.boundingRadius) then
						local damage = self:CalculateSkillDamage(owner, target, spellInfo)
						self:IncomingDamage(owner, target, damage, spellInfo.CCType,true)
					end
				end
			end
		elseif spellInfo.TargetType == TARGET_TYPE_ARC then
			local arcAngle = spellInfo.Angle or spell.data.coneAngle
			local arcDistance = spellInfo.Radius or spell.data.coneDistance
			local angleOffset = Geometry:Angle(spell.data.startPos,LocalVector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z))
			for _, target in LocalPairs(collection) do
				if target ~= nil and LocalType(target) == "userdata" then
					local deltaAngle = LocalAbs(Geometry:Angle(spell.data.startPos,target.pos) - angleOffset)
					if deltaAngle < arcAngle and Geometry:IsInRange(spell.data.startPos, target.pos, arcDistance) then
						local damage = self:CalculateSkillDamage(owner, target, spellInfo)
						self:IncomingDamage(owner, target, damage, spellInfo.CCType,true)
					end
				end
			end
		elseif spellInfo.TargetType == TARGET_TYPE_BOX and spellInfo.Length then		
			--This is the direction between the box and our hero. We can then use Perpendicular to get the offsets we need
			local origin = LocalVector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z)
			local directionVector = (origin- spell.data.startPos):Normalized():Perpendicular()			
			local p1 = origin - directionVector * spellInfo.Length			
			local p2 = origin + directionVector * spellInfo.Length
			for _, target in LocalPairs(collection) do
				if target ~= nil and LocalType(target) == "userdata" then					
					local proj1, pointLine, isOnSegment =Geometry:VectorPointProjectionOnLineSegment(p1, p2, target.pos)
					if isOnSegment and Geometry:IsInRange(target.pos, pointLine, spellInfo.Radius + target.boundingRadius) then
						local damage = self:CalculateSkillDamage(owner, target, spellInfo)
						self:IncomingDamage(owner, target, damage, spellInfo.CCType,true)
					end
				end
			end
		elseif spellInfo.TargetType == TARGET_TYPE_RING and spellInfo.Ring then
			local castPos = LocalVector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z)			
			for _, target in LocalPairs(collection) do
				if target ~= nil and LocalType(target) == "userdata" then
					local dist =  Geometry:GetDistance(castPos, target.pos)
					if dist > spellInfo.Radius and dist < spellInfo.Radius + spellInfo.Ring + target.boundingRadius then						
						local damage = self:CalculateSkillDamage(owner, target, spellInfo)
						self:IncomingDamage(owner, target, damage, spellInfo.CCType,true)
					end
				end
			end
		elseif spellInfo.TargetType == TARGET_TYPE_LINE and spellInfo.Radius then
		
			local startPos = LocalVector(spell.data.startPos.x, spell.data.startPos.y, spell.data.startPos.z)
			if spellInfo.SetOrigin then
				startPos = owner.pos
			end
			
			local dirVector = (LocalVector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z)-startPos):Normalized()
			if dirVector.x ~= dirVector.x then
				dirVector = owner.dir
			end
			local castPos = startPos + dirVector * (spellInfo.Length or spell.data.range)
			for _, target in LocalPairs(collection) do
					if target ~= nil and LocalType(target) == "userdata" then
					local proj1, pointLine, isOnSegment =Geometry:VectorPointProjectionOnLineSegment(startPos, castPos, target.pos)
					if isOnSegment and Geometry:IsInRange(target.pos, pointLine, spellInfo.Radius + target.boundingRadius) then
						local damage = self:CalculateSkillDamage(owner, target, spellInfo)
						self:IncomingDamage(owner, target, damage, spellInfo.CCType,true)
					end
				end
			end
		else
			print("Unhandled targeting type: " .. spellInfo.TargetType)
		end
	elseif spell.data.target > 0 then
		
		local owner = ObjectManager:GetHeroByHandle(spell.handle)
		local target = ObjectManager:GetHeroByHandle(spell.data.target)
		if owner and owner.range < 275 and target then
			local targetCollection = self.EnemyDamage
			if target.isAlly then
				targetCollection = self.AlliedDamage
			end
			if not targetCollection[target.handle] then return end
			local damage = owner.totalDamage
			if LocalStringFind(spell.name, "CritAttack") then
				damage = damage * 1.5
			end
			damage = self:CalculatePhysicalDamage(owner, target, damage)
			targetCollection[target.handle][owner.networkID] = 
			{
				Name = spell.name,
				Damage = damage,
				Danger = 0,
				Expires = spell.windupEnd + .25,
			}
			self:IncomingDamage(owner, target, damage)
		end
	end
end

function __DamageManager:GetSpellHitDetails(spell, target)
	local hitDetails = {Hit = false}
	if not target or not self.AllSkills[spell.name] then return hitDetails end
	local spellInfo = self.AllSkills[spell.name]
	local owner = ObjectManager:GetHeroByID(spell.owner)
	local spellCastPos = LocalVector(spell.data.placementPos.x, spell.data.placementPos.y,spell.data.placementPos.z)
	local spellSpeed = spell.data.speed or 999999	
	
	local predictedTargetPos = Geometry:PredictUnitPosition(target, spell.windupEnd- LocalGameTimer() + Geometry:GetDistance(owner.pos, target.pos))
	local hitTime = spell.windupEnd - LocalGameTimer() + Geometry:GetDistance(owner.pos, predictedTargetPos) / spellSpeed
	local willHit = false
	if spellInfo.TargetType == TARGET_TYPE_LINE and spellInfo.Radius then	
		spellCastPos = spell.data.startPos + (LocalVector(spell.data.placementPos.x, spell.data.placementPos.y,spell.data.placementPos.z) - spell.data.startPos):Normalized() * spell.data.range
		local proj1, pointLine, isOnSegment =Geometry:VectorPointProjectionOnLineSegment(spell.data.startPos, spellCastPos, predictedTargetPos)		
		if isOnSegment and Geometry:IsInRange(predictedTargetPos, pointLine, spellInfo.Radius + target.boundingRadius) then
			willHit = true
		end
	end
	
	if spellInfo.TargetType == TARGET_TYPE_CIRCLE and spellInfo.Radius then
		if Geometry:IsInRange(spellCastPos, predictedTargetPos, spellInfo.Radius + target.boundingRadius) then
			willHit = true
		end
	end
	
	if spellInfo.TargetType == TARGET_TYPE_ARC  then
		local arcAngle = spellInfo.Angle or spell.data.coneAngle
		local arcDistance = spellInfo.Radius or spell.data.coneDistance
		local angleOffset = Geometry:Angle(spell.data.startPos,spellCastPos)
		if LocalAbs(Geometry:Angle(spell.data.startPos, predictedTargetPos) - angleOffset) < arcAngle and Geometry:IsInRange(spell.startPos, predictedTargetPos, arcDistance) then			
			willHit = true
		end
	end
	
	local Avoid = nil
	if target.isMe then
		local deltaAngle = Geometry:Angle(target.pos, spell.data.startPos) - Geometry:Angle(target.pos, mousePos)
		Avoid = (spell.data.startPos-target.pos):Normalized()		
		if deltaAngle < 0 then
			Avoid = Geometry:RotateAroundPoint(Avoid, Vector(), -45)
		else
			Avoid = Geometry:RotateAroundPoint(Avoid, Vector(), 45)
		end
	end
	
	return 
	{
		Hit = willHit, 
		Danger = spellInfo.Danger,
		
		Forward = (spellCastPos-spell.data.startPos):Normalized(),
		
		CC = spellInfo.CCType,
		
		Damage = DamageManager:CalculateSkillDamage(owner, target, spellInfo),
		
		HitTime = hitTime,
		
		Path = Avoid,
		
		Collision = spellInfo.Collision,
	}
end

function __DamageManager:DodgeSpell(spell, target, danger, dist)
	if not self.AllSkills[spell.name] then  return end
	local spellInfo = self.AllSkills[spell.name]
	if spellInfo.Danger < danger then
		--calculate damage it will deal and if it will kill then check if we want to dodge on kill. 
			--Note: to do that we need the source as well.. Leave it for now.
		return
	end
		
	local nextTargetPos = Geometry:PredictUnitPosition(target, .25)
	
	--TODO: Re-add offsetting dodge based on mouse position... this is messy AF
	local castPos = LocalVector(spell.placementPos.x, spell.placementPos.y,spell.placementPos.z)
	local dodgePos = nextTargetPos + (castPos - spell.startPos):Normalized():Rotated(0,math.random(75, 90),0) * LocalMax(Dist or 0, (spellInfo.Radius or 100 + target.boundingRadius) * 2)
	if spellInfo.TargetType == TARGET_TYPE_LINE and spellInfo.Radius then
		castPos = spell.startPos + (LocalVector(spell.placementPos.x, spell.placementPos.y,spell.placementPos.z) - spell.startPos):Normalized() * spell.range				
		local proj1, pointLine, isOnSegment =Geometry:VectorPointProjectionOnLineSegment(spell.startPos, castPos, nextTargetPos)		
		if isOnSegment and Geometry:IsInRange(nextTargetPos, pointLine, spellInfo.Radius + target.boundingRadius) then
			return true, dodgePos
		end
	end
	if spellInfo.TargetType == TARGET_TYPE_CIRCLE and spellInfo.Radius then
		if Geometry:IsInRange(castPos, nextTargetPos, spellInfo.Radius + target.boundingRadius) then						
			return true, dodgePos
		end
	end
	if spellInfo.TargetType == TARGET_TYPE_ARC  then
		local arcAngle = spellInfo.Angle or spell.data.coneAngle
		local arcDistance = spellInfo.Radius or spell.data.coneDistance
		local angleOffset = Geometry:Angle(spell.startPos,castPos)
		if LocalAbs(Geometry:Angle(spell.startPos, nextTargetPos) - angleOffset) < arcAngle and Geometry:IsInRange(spell.startPos, nextTargetPos, arcDistance) then			
			return true, dodgePos
		end
	end
end

function __DamageManager:MissileCreated(missile)
	if self.MissileNames[missile.name] then
		missile.Sort = self.MissileNames[missile.name].TargetType
		missile.Radius = self.MissileNames[missile.name].Radius
		if missile.Sort == TARGET_TYPE_CIRCLE then
			self:OnUntargetedMissileTable(missile)
		elseif missile.data.missileData.target > 0 then
			--Unable currently to handle line skillshots that have a target (IE: Oriana E)			
			self:OnTargetedMissileTable(missile)			
		else
			self:OnUntargetedMissileTable(missile)
		end
	elseif missile.data.missileData.target > 0 and (LocalStringFind(missile.name, "BasicAttack") or LocalStringFind(missile.name, "CritAttack")) then
		self:OnAutoAttackMissile(missile)			
	elseif AlphaMenu.PrintMissile:Value() then
		print("Unhandled missile: " .. missile.name .. " Width: " ..missile.data.missileData.width .. " Speed: " .. missile.data.missileData.speed)
	end
end

function __DamageManager:OnAutoAttackMissile(missile)
	local owner = ObjectManager:GetObjectByHandle(missile.data.missileData.owner)
	local target = ObjectManager:GetHeroByHandle(missile.data.missileData.target)
	if owner and target then
		local targetCollection = self.EnemyDamage
		if target.isAlly then
			targetCollection = self.AlliedDamage
		end
		if not targetCollection[target.handle] then return end
		
		--This missile is already added - ignore it cause something went wrong. 
		if targetCollection[target.handle][missile.networkID] then return end
		
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
		self:IncomingDamage(owner, target, damage)
	end
end

function __DamageManager:OnTargetedMissileTable(missile)
	local skillInfo = self.MissileNames[missile.name]		
	local owner = ObjectManager:GetObjectByHandle(missile.data.missileData.owner)
	local target = ObjectManager:GetHeroByHandle(missile.data.missileData.target)
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


function __DamageManager:RecordedIncomingDamage(target)
	local damage = 0
	local targetCollection = self.EnemyDamage
	local currentTime = LocalGameTimer()
	if target.isAlly then
		targetCollection = self.AlliedDamage
	end
	if targetCollection[target.handle] then
		for _, dmg in LocalPairs(targetCollection[target.handle]) do			
			if dmg then
				if dmg.Expires and currentTime > dmg.Expires then
					targetCollection[target.handle][_] = nil
				else				
					damage = damage + dmg.Damage
				end
			end
		end
	end	
	return damage
end
function __DamageManager:PredictDamage(owner, target, spellName)
	local damage = 0
	local skillInfo = self.MasterSkillLookupTable[spellName]
	if skillInfo then damage =self:CalculateSkillDamage(owner, target, skillInfo) end
	
	local targetCollection = self.EnemyDamage
	if target.isAlly then
		targetCollection = self.AlliedDamage
	end
	if targetCollection[target.handle] then
		for _, dmg in LocalPairs(targetCollection[target.handle]) do
			if dmg then
				damage = damage + dmg.Damage
			end
		end
	end	
	return damage
end

function __DamageManager:CalculateDamage(owner, target, spellName)
	return self:CalculateSkillDamage(owner, target, self.MasterSkillLookupTable[spellName])	
end
function __DamageManager:CalculateSkillDamage(owner, target, skillInfo)
	local damage = 0
	if not skillInfo or not owner or not target then return damage end
	if skillInfo.Damage or skillInfo.SpecialDamage or skillInfo.CurrentHealth then
		if skillInfo.SpecialDamage then
			damage = skillInfo.SpecialDamage(owner, target)
		elseif not skillInfo.SpellSlot and skillInfo.Damage then
			damage = LocalType(skillInfo.Damage) == "table" and skillInfo.Damage[owner.levelData.lvl] or skillInfo.Damage
		else
			--TODO: Make sure this handles nil values like a champ
			
			damage = (skillInfo.Damage and skillInfo.Damage[owner:GetSpellData(skillInfo.SpellSlot).level] or 0 )+ 
			(skillInfo.APScaling and (LocalType(skillInfo.APScaling) == "table" and skillInfo.APScaling[owner:GetSpellData(skillInfo.SpellSlot).level] or skillInfo.APScaling) * owner.ap or 0) + 
			(skillInfo.ADScaling and (LocalType(skillInfo.ADScaling) == "table" and skillInfo.ADScaling[owner:GetSpellData(skillInfo.SpellSlot).level] or skillInfo.ADScaling) * owner.totalDamage or 0) + 
			(skillInfo.BonusADScaling and (LocalType(skillInfo.BonusADScaling) == "table" and skillInfo.BonusADScaling[owner:GetSpellData(skillInfo.SpellSlot).level] or skillInfo.BonusADScaling) * owner.bonusDamage or 0) + 
			(skillInfo.CurrentHealth and (LocalType(skillInfo.CurrentHealth) == "table" and skillInfo.CurrentHealth[owner:GetSpellData(skillInfo.SpellSlot).level] or skillInfo.CurrentHealth) * target.health or 0) + 
			(skillInfo.CurrentHealthAPScaling and (target.maxHealth-target.health) * skillInfo.CurrentHealthAPScaling * owner.ap/100 or 0) + 
			(skillInfo.MissingHealth and (LocalType(skillInfo.MissingHealth) == "table" and skillInfo.MissingHealth[owner:GetSpellData(skillInfo.SpellSlot).level] or skillInfo.MissingHealth) * (target.maxHealth -target.health) or 0) +
			(skillInfo.MissingHealthAPScaling and (target.maxHealth-target.health) * skillInfo.MissingHealthAPScaling * owner.ap/100 or 0) + 	
			(skillInfo.MyHealth and (LocalType(skillInfo.MyHealth) == "table" and skillInfo.MyHealth[owner:GetSpellData(skillInfo.SpellSlot).level] or skillInfo.MyHealth) * owner.maxHealth or 0) +
			(skillInfo.MaximumHealth and (LocalType(skillInfo.MaximumHealth) == "table" and skillInfo.MaximumHealth[owner:GetSpellData(skillInfo.SpellSlot).level] or skillInfo.MaximumHealth) * target.maxHealth or 0) +
			(skillInfo.MaximumHealthAPScaling and (LocalType(skillInfo.MaximumHealthAPScaling) == "table" and skillInfo.MaximumHealthAPScaling[owner:GetSpellData(skillInfo.SpellSlot).level] or skillInfo.MaximumHealthAPScaling) * target.maxHealth or 0)* owner.ap/100 +
			(skillInfo.MaximumHealthADScaling and (LocalType(skillInfo.MaximumHealthADScaling) == "table" and skillInfo.MaximumHealthADScaling[owner:GetSpellData(skillInfo.SpellSlot).level] or skillInfo.MaximumHealthADScaling) * target.maxHealth or 0)* owner.totalDamage/100
		end
		if skillInfo.DamageType == DAMAGE_TYPE_MAGICAL then
			damage = self:CalculateMagicDamage(owner, target, damage)
		elseif skillInfo.DamageType == DAMAGE_TYPE_PHYSICAL then
			damage = self:CalculatePhysicalDamage(owner, target, damage)				
		end
		
		if skillInfo.BuffScalingName and BuffManager:HasBuff(target, skillInfo.BuffScalingName) then
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
	if not self.CallbacksInitialized then
		self.InitializeCallbacks()
	end
	
	DamageManager.OnIncomingCCCallbacks[#DamageManager.OnIncomingCCCallbacks+1] = cb
end

--Trigger Incoming CC Event
function __DamageManager:IncomingCC(target, damage, ccType, canDodge)
	for i = 1, #self.OnIncomingCCCallbacks do
		self.OnIncomingCCCallbacks[i](target, damage, ccType, canDodge);
	end
end

--Check for buff based skills
function __DamageManager:BuffAdded(owner, buff)
	if self.BuffNames[buff.name] then
		local spellInfo = self.BuffNames[buff.name]
		local origin = owner.pos
		if owner.pathing and owner.pathing.isDashing then
			origin = owner:GetPath(1)
		end
		local collection = self.EnemyHeroes
		if owner.isEnemy then
			collection = self.AlliedHeroes
		end
		
		if spellInfo.TargetType == TARGET_TYPE_CIRCLE and spellInfo.Radius then		
			for _, target in LocalPairs(collection) do
				if target ~= nil and LocalType(target) == "userdata" then
					if Geometry:IsInRange(origin, target.pos, spellInfo.Radius) then
						local damage = self:CalculateSkillDamage(owner, target, spellInfo)
						self:IncomingDamage(owner, target, damage, spellInfo.CCType)
					end
				end
			end
		elseif spellInfo.TargetType == TARGET_TYPE_LINE and spellInfo.Radius then
			
			for _, target in LocalPairs(collection) do
				if target ~= nil and LocalType(target) == "userdata" then
					local endPos = origin + (origin - owner.pos):Normalized() * (spellInfo.Radius + owner.boundingRadius)
					local proj1, pointLine, isOnSegment =Geometry:VectorPointProjectionOnLineSegment(owner.pos, endPos, target.pos)
					if isOnSegment and Geometry:IsInRange(target.pos, pointLine, spellInfo.Radius + target.boundingRadius) then
							local damage = self:CalculateSkillDamage(owner, target, spellInfo)
						self:IncomingDamage(owner, target, damage, spellInfo.CCType,true)
					end
				end
			end
		elseif spellInfo.TargetType == TARGET_TYPE_ARC and spellInfo.Angle and spellInfo.Radius then
			local angleOffset = Geometry:Angle(owner.pos, owner.pos+owner.dir)
			for _, target in LocalPairs(collection) do
				if target ~= nil and LocalType(target) == "userdata" then
					local deltaAngle = LocalAbs(Geometry:Angle(owner.pos,target.pos) - angleOffset)
					if deltaAngle < spellInfo.Angle and Geometry:IsInRange(owner.pos, target.pos, spellInfo.Radius) then
						local damage = self:CalculateSkillDamage(owner, target, spellInfo)
						self:IncomingDamage(owner, target, damage, spellInfo.CCType,true)
					end
				end
			end
		elseif spellInfo.TargetType == TARGET_TYPE_SINGLE then
			local target = ObjectManager:GetObjectByHandle(owner.attackData.target)
			if target then
				local damage = self:CalculateSkillDamage(owner, target, spellInfo)
				self:IncomingDamage(owner, target, damage, spellInfo.CCType)
			end
		else
			print("Unhandled buff targeting type: " .. spellInfo.TargetType)
		end		
	end
	if #buff.name < 64 and AlphaMenu.PrintBuff:Value() then
		print(owner.charName .. " Gained Buff: " .. buff.name)
	end
end

--Remove from local collections on destroy
function __DamageManager:MissileDestroyed(missile)
	--Check if they need to be destroyed
	
	for _, dmgCollection in LocalPairs(self.AlliedDamage) do
		if dmgCollection[missile.networkID] then
			dmgCollection[missile.networkID] = nil
		end
	end
	
	for _, dmgCollection in LocalPairs(self.EnemyDamage) do
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
function __BuffManager:GetBuffByName(target, buffName)
	for i = 1, target.buffCount do 
		local buff = target:GetBuff(i)
		if buff.duration > 0 and buff.name == buffName then
			return buff
		end
	end
end
function __BuffManager:GetBuffByType(target, buffType)
	for i = 1, target.buffCount do 
		local buff = target:GetBuff(i)
		if buff.duration > 0 and buff.type == buffType then
			return buff
		end
	end
end
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

print("Loaded Auto3.0: Alpha")
--Initialization
AlphaMenu = MenuElement({type = MENU, id = "Alpha", name = "[ALPHA]"})
AlphaMenu:MenuElement({id = "Performance", name = "Performance", type = MENU})
AlphaMenu.Performance:MenuElement({id = "MissileCache", name = "Missile Cache Time", value = _G.missileRecacheTimeOut, min = 10, max = 1000, step = 10, callback = function(delay) MISSILE_CACHE_DELAY = delay end })
AlphaMenu.Performance:MenuElement({id = "ParticleCache", name = "Particle Cache Time", value = _G.particleRecacheTimeOut, min = 10, max = 1000, step = 10, callback = function(delay) PARTICLE_CACHE_DELAY = delay end })
AlphaMenu.Performance:MenuElement({id = "BuffCache", name = "Buff Cache Time", value = 150, min = 10, max = 1000, step = 10, callback = function(delay) BUFF_CACHE_DELAY = delay end })

AlphaMenu:MenuElement({id = "PrintDmg", name = "Print Damage Warnings", value = false})
AlphaMenu:MenuElement({id = "PrintBuff", name = "Print Buff Create", value = false})
AlphaMenu:MenuElement({id = "PrintMissile", name = "Print Missile Create", value = false})
AlphaMenu:MenuElement({id = "PrintSkill", name = "Print Skill Used", value = false})

MISSILE_CACHE_DELAY =AlphaMenu.Performance.BuffCache:Value()
PARTICLE_CACHE_DELAY =AlphaMenu.Performance.ParticleCache:Value()
BUFF_CACHE_DELAY =AlphaMenu.Performance.BuffCache:Value()

_G.Alpha.Menu = Menu
	
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