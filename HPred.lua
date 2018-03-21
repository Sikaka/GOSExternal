

class "HPred"

function HPred:GetEnemyNexusPosition()
	--This is slightly wrong. It represents fountain not the nexus. Fix later.
	if myHero.team == 100 then return Vector(14340, 171.977722167969, 14390); else return Vector(396,182.132507324219,462); end
end


function HPred:GetTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius, midDash)

	--TODO: Target whitelist. This will target anyone which is definitely not what we want
	--For now we can handle in the champ script. That will cause issues with multiple people in range who are goood targets though.
	
	
	--Get stunned enemies
	local target, aimPosition =self:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get hourglass enemies
	target, aimPosition =self:GetHourglassTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
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
	
	--Get dashing enemies
	target, aimPosition =self:GetDashingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius, midDash)
	if target and aimPosition then
		return target, aimPosition
	end	
	
	--TODO: Radius based targeting: Slows, range, hitbox radius VS their movespeed to avoid it. Requires movement smoothing 
end

--Finds a target who is dashing and can be hit by our spell before the dash ends
--GetDashingTarget(source, range, delay, speed, dashThreshold, midDash)
	--source : Location from which the spell is cast
	--range : Maximum distance the spell can travel
	--delay : Time it will take before spell leaves the source
	--speed : Speed at which the spell will travel
	--dashThreshold : How long after a dash may our spell land
	--midDash : Can our spell hit before the dash ends?
function HPred:GetDashingTarget(source, range, delay, speed, dashThreshold, checkCollision, radius, midDash)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if t.isEnemy and t.pathing.hasMovePath and t.pathing.isDashing and t.pathing.dashSpeed>500  then
			local dashEndPosition = t.pathing.endPos
			if self:GetDistance(source, dashEndPosition) <= range then				
				--The dash ends within range of our skill. We now need to find if our spell can connect with them very close to the time their dash will end
				local dashTimeRemaining = self:GetDistance(t.pos, dashEndPosition) / t.pathing.dashSpeed
				local skillInterceptTime = self:GetSpellInterceptTime(myHero.pos, dashEndPosition, delay, speed)
				local deltaInterceptTime = skillInterceptTime - dashTimeRemaining
				local interceptPosition = t.pathing.endPos
				if midDash then
					deltaInterceptTime = math.abs(deltaInterceptTime)
					--Find mid dash pos to aim at
				end
				if deltaInterceptTime < dashThreshold and (not checkCollision or self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
					target = t
					aimPosition = interceptPosition
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
		local success, timeRemaining = self:HasBuff(t, "zhonyasringshield")
		if success and t.isEnemy then
			local deltaInterceptTime = self:GetSpellInterceptTime(myHero.pos, t.pos, delay, speed) - timeRemaining
			if deltaInterceptTime > -Game.Latency() / 2000 and deltaInterceptTime < timingAccuracy and (not checkCollision or self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
				target = t
				aimPosition = t.pos
				return target, aimPos
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
		local interceptPosition = HPred:PredictUnitPosition(t, interceptTime)	
		if t.isEnemy and self:IsChannelling(t, interceptTime) and (not checkCollision or self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
			target = t
			aimPosition = interceptPosition	
			return target, aimPosition
		end
	end
end

function HPred:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if self:CanTarget(t) and self:GetDistance(source, t.pos) <= range then
			local immobileTime = self:GetImmobileTime(t)
			local interceptTime = self:GetSpellInterceptTime(source, t.pos, delay, speed)
			if immobileTime - interceptTime > timingAccuracy and (not checkCollision or self:CheckMinionCollision(source, t.pos, delay, speed, radius)) then
				
			print("START")
			
			target = t
				aimPosition = t.pos
				return target, aimPosition
			end
		end
	end
end

function HPred:GetTeleportingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	
	--Get enemies who are teleporting to towers
	for i = 1, Game.TurretCount() do
		local turret = Game.Turret(i);
		if turret.isEnemy and self:GetDistance(source, turret.pos) <= range then
			local hasBuff, expiresAt = self:HasBuff(turret, "teleport_target")
			if hasBuff then
				--TODO: Check distance from towers. Its much further than minions. 400 is a guess
				local interceptPosition = self:GetTeleportOffset(turret.pos,400)
				local skillInterceptTime = self:GetSpellInterceptTime(source, interceptPosition, delay, speed)				
				if expiresAt < skillInterceptTime and skillInterceptTime - expiresAt < timingAccuracy and (not checkCollision or self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
					target = turret
					aimPosition =interceptPosition
					return target, aimPosition
				end
			end
		end
	end	
	
	--Get enemies who are teleporting to wards
	for i = 1, Game.WardCount() do
		local ward = Game.Ward(i);
		if ward.isEnemy and self:GetDistance(source, ward.pos) <= range then
			local hasBuff, expiresAt = self:HasBuff(ward, "teleport_target")
			if hasBuff then
				local interceptPosition = self:GetTeleportOffset(ward.pos,150)
				local skillInterceptTime = self:GetSpellInterceptTime(source, interceptPosition, delay, speed)				
				if expiresAt < skillInterceptTime and skillInterceptTime - expiresAt < timingAccuracy and (not checkCollision or self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
					target = ward
					aimPosition = interceptPosition
					return target, aimPosition
				end
			end
		end
	end
	
	--Get enemies who are teleporting to minions
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i);
		if minion.isEnemy and self:GetDistance(source, minion.pos) <= range then
			local hasBuff, expiresAt = self:HasBuff(minion, "teleport_target")
			if hasBuff then	
				--TODO: Check how far we teleport from minions. Guessing it involves minion.boundingRadius but this will work for now.
				local interceptPosition = self:GetTeleportOffset(minion.pos,150)
				local skillInterceptTime = self:GetSpellInterceptTime(source, interceptPosition, delay, speed)	
				if expiresAt < skillInterceptTime and skillInterceptTime - expiresAt < timingAccuracy and (not checkCollision or self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
					target = minion				
					aimPosition = interceptPosition
					return target, aimPosition
				end
			end
		end
	end
end

function HPred:GetTargetMS(target)
	local ms = target.pathing.isDashing and target.pathing.dashSpeed or target.ms
	return ms
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
	local interceptTime = delay + self:GetDistance(startPos, endPos) / speed
	return interceptTime
end

--Checks if a target can be targeted by abilities or auto attacks currently.
--CanTarget(target)
	--target : gameObject we are trying to hit
function HPred:CanTarget(target)
	return target.isEnemy and target.alive and target.visible and target.isTargetable
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
		frequency = radius / 2
	end
	local directionVector = (endPos - origin):Normalized()
	local checkCount = self:GetDistance(origin, endPos) / frequency
	for i = 1, checkCount do
		local checkPosition = origin + directionVector * i * frequency
		local checkDelay = delay + self:GetDistance(origin, checkPosition) / speed
		if self:IsMinionIntersection(checkPosition, radius, checkDelay) then
			return false
		end
	end
	return true
end

function HPred:IsMinionIntersection(location, radius, delay, maxDistance)
	if not maxDistance then
		maxDistance = 500
	end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion.isEnemy and minion.isTargetable and minion.alive and self:GetDistance(minion.pos, location) < maxDistance then
			local predictedPosition = self:PredictUnitPosition(minion, delay)
			if self:GetDistance(location, predictedPosition) <= radius + minion.boundingRadius then
				return true
			end
		end
	end
	return false
end

function HPred:GetDistanceSqr(p1, p2)	
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function HPred:GetDistance(p1, p2)
	return math.sqrt(self:GetDistanceSqr(p1, p2))
end