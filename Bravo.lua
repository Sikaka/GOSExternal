if _G.Bravo then return end

local MathAbs, MathAtan, MathAtan2, MathAcos, MathCeil, MathCos, MathDeg, MathFloor, MathHuge, MathMax, MathMin, MathPi, MathRad, MathSin, MathSqrt = math.abs, math.atan, math.atan2, math.acos, math.ceil, math.cos, math.deg, math.floor, math.huge, math.max, math.min, math.pi, math.rad, math.sin, math.sqrt
local GameCanUseSpell, GameLatency, GameTimer, GameHeroCount, GameHero, GameMinionCount, GameMinion, GameMissileCount, GameMissile = Game.CanUseSpell, Game.Latency, Game.Timer, Game.HeroCount, Game.Hero, Game.MinionCount, Game.Minion, Game.MissileCount, Game.Missile
local DrawCircle, DrawColor, DrawLine, DrawText, ControlKeyUp, ControlKeyDown, ControlMouseEvent, ControlSetCursorPos = Draw.Circle, Draw.Color, Draw.Line, Draw.Text, Control.KeyUp, Control.KeyDown, Control.mouse_event, Control.SetCursorPos
local TableInsert, TableRemove, TableSort = table.insert, table.remove, table.sort
local BUFF_STUN,BUFF_SILENCE,BUFF_TAUNT,BUFF_SLOW,BUFF_ROOT,BUFF_FEAR,BUFF_CHARM,BUFF_POISON,BUFF_SURPRESS,BUFF_BLIND,BUFF_KNOCKUP,BUFF_KNOCKBACK,BUFF_DISARM = 5,7,8,10,11,21,22,23,24,25,29,30,31
local IMMOBILE_TYPES = {[BUFF_STUN]="true",[BUFF_SURPRESS]="true",[BUFF_ROOT]="true", [BUFF_KNOCKUP] = "true", [BUFF_KNOCKBACK] = "true", [BUFF_CHARM] = "true", [BUFF_TAUNT] = "true"}

local function Class()		
	local cls = {}; cls.__index = cls		
	return setmetatable(cls, {__call = function (c, ...)		
		local instance = setmetatable({}, cls)		
		if cls.__init then cls.__init(instance, ...) end		
		return instance		
	end})		
end


local Geometry = Class()
function Geometry:__init()

end

function Geometry:VectorPointProjectionOnLineSegment(v1, v2, v)
	assert(v1 and v2 and v, "VectorPointProjectionOnLineSegment: wrong argument types (3 <Vector> expected)")
	local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
	local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
	local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
	local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	local isOnSegment = rS == rL
	local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
	return pointSegment, pointLine, isOnSegment
end

function Geometry:RotateAroundPoint(v1,v2, angle)
	local c, s = MathCos(angle), MathSin(angle)
	local x = ((v1.x - v2.x) * c) - ((v1.z - v2.z) * s) + v2.x
	local z = ((v1.z - v2.z) * c) + ((v1.x - v2.x) * s) + v2.z
	return Vector(x, v1.y, z or 0)
end

function Geometry:GetDistanceSqr(p1, p2)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		print("Undefined GetDistanceSqr target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return MathHuge
	end
	return (p1.x - p2.x) *  (p1.x - p2.x) + ((p1.z or p1.y) - (p2.z or p2.y)) * ((p1.z or p1.y) - (p2.z or p2.y)) 
end

function Geometry:GetDistance(p1, p2)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		print("Undefined GetDistance target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return MathHuge
	end
	return MathSqrt(self:GetDistanceSqr(p1, p2))
end

function Geometry:IsPointInArc(source, origin, target, angle, range)
	local deltaAngle = MathAbs(self:Angle(origin, target) - self:Angle(source, origin))
	return deltaAngle < angle and self:IsInRange(origin,target,range)
end

function Geometry:Angle(A, B)
	local deltaPos = A - B
	local angle = MathAtan2(deltaPos.x, deltaPos.z) *  180 / MathPi	
	if angle < 0 then angle = angle + 360 end
	return angle
end

function Geometry:IsInRange(p1, p2, range)
	if not p1 or not p2 or not p1.x or not p2.x then
		local dInfo = debug.getinfo(2)
		print("Undefined IsInRange target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return false
	end
	return (p1.x - p2.x) *  (p1.x - p2.x) + ((p1.z or p1.y) - (p2.z or p2.y)) * ((p1.z or p1.y) - (p2.z or p2.y)) < range * range 
end

function Geometry:GetLineTargetCount(source, aimPos, delay, speed, width, targetAllies)
	local targetCount = 0
	for i = 1, GameHeroCount() do
		local t = GameHero(i)
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
function Geometry:GetLineMinionTargetCount(source, aimPos, delay, speed, width)
	local targetCount = 0
	for i = 1, GameMinionCount() do
		local t = GameMinion(i)
		if t and t.pos and t.alive and t.health > 0 and t.visible and t.isTargetable then			
			local predictedPos = self:PredictUnitPosition(t, delay+ self:GetDistance(source, t.pos) / speed)			
			local proj1, pointLine, isOnSegment = self:VectorPointProjectionOnLineSegment(source, aimPos, predictedPos)
			if proj1 and isOnSegment and self:IsInRange(predictedPos, proj1, t.boundingRadius + width) then
				targetCount = targetCount + 1
			end
		end
	end
	return targetCount
end

function Geometry:GetLineFarmCastPosition(source, range, delay, speed, width)
	local castOffset = (mousePos - myHero.pos):Normalized()		
	local targetCount = 0
	local aimPosition = source
	--Check 20 possible angles for best target count
	for i = 0, 360, 18 do	
		local castDir = castOffset:Rotated(0,i,0)
		local castTargets = self:GetLineMinionTargetCount(source, source + castDir*range, delay, speed, width)
		if castTargets > targetCount then
			aimPosition = myHero.pos + castDir * 500
			targetCount = castTargets
		end
	end	
	return targetCount, aimPosition
end

function Geometry:GetArcFarmCastPosition(range, delay, speed, width)
	local castOffset = (mousePos - myHero.pos):Normalized()		
	local targetCount = 0
	local castPosition = myHero.pos
	--Check 20 possible angles for best target count
	for i = 0, 360, 18 do	
		local castDir = castOffset:Rotated(0,i,0)
		local castPos = myHero.pos + castDir * range
		local castAngle = LocalGeometry:Angle(myHero.pos, castPos)
		local hitCount = 0
		for i = 1, GameMinionCount() do
			local t = GameMinion(i)
			if t and t.pos and t.alive and t.health > 0 and t.visible and t.isTargetable then			
				local predictedPosition = self:PredictUnitPosition(t, delay+ self:GetDistance(myHero.pos, t.pos) / speed)	
				if self:IsInRange(myHero.pos, predictedPosition, range) then
					local deltaAngle = MathAbs(self:Angle(myHero.pos, predictedPosition) - castAngle)
					if deltaAngle <= 15 then
						hitCount = hitCount + 1
					end
				end
			end
		end
		
		if hitCount > targetCount then
			targetCount = hitCount
			castPosition = castPos
		end
	end
	
	return targetCount, castPosition
end

function Geometry:GetCastPosition(source, target, range, delay, speed, radius, checkCollision, isLine)
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
		
		local origin, movementRadius = self:UnitMovementBounds(target, interceptTime, reactionTime)
		if movementRadius <= radius  then
			if target.activeSpell and target.activeSpell.valid and not target.activeSpell.spellWasCast then
				adjustedDelay = LocalGameTimer() - target.activeSpell.startTime + target.activeSpell.windup
				if adjustedDelay > 0 then
					aimPosition = self:PredictUnitPosition(target, interceptTime- adjustedDelay)
				end
			end
			hitChance = 3
		end
					
		if not self:IsInRange(source.pos, aimPosition, range) then hitChance = -1 return end
		if checkCollision and self:CheckMinionCollision(source.pos, aimPosition, delay, speed, radius) then hitChance = -1 return end

		if target.pathing.hasMovePath and target.pathing.isDashing and target.pathing.dashSpeed>500 then
			hitChance = 4
		end
		
		if self:GetImmobileTime(target) >= interceptTime then
			hitChance = 5
		end
		
	end
	
	return aimPosition, hitChance	
end

function Geometry:InterceptTime(source, target, delay, speed)
	local relativePosition = target.pos - source.pos
	local relativeVelocity = (self:NextPath(source) - source.pos):Normalized() * self:GetTargetMS(source) -(self:NextPath(target) - target.pos):Normalized() * self:GetTargetMS(target)	

	local velocitySquared = self:GetSqrMagnitude(relativeVelocity)
	
	local a = velocitySquared - speed * speed
	if MathAbs(a)  < .001 then
		local t = - self:GetSqrMagnitude(relativePosition) / (2*relativeVelocity:DotProduct(relativePosition))
		return delay + MathMax(t, 0)
	end
	
	local b = 2 * relativeVelocity:DotProduct(relativePosition)
	local c = self:GetSqrMagnitude(relativePosition)
	local d = b * b - 4*a*c
	if d > 0 then
		local t1 = (-b + MathSqrt(d)) / (2*a)
		local t2 = (-b - MathSqrt(d)) / (2*a)
		if t1 > 0 then
			if t2 > 0 then
				return delay+ MathMin(t1, t2)
			else
				return delay+ t1
			end
		else
			return delay + MathMax(t2, 0)
		end
	elseif d < 0 then
		return delay
	else
		return delay + MathMax(-b/2*a, 0)
	end	
end

function Geometry:NextPath(unit)
	if unit.pathing.hasMovePath then
		return unit:GetPath(1)
	else
		return unit.pos
	end
end

function Geometry:GetSqrMagnitude(vector)
	return vector.x * vector.x + vector.y * vector.y + vector.z * vector.z
end

function Geometry:GetImmobileTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.count > 0 and buff.duration > duration and IMMOBILE_TYPES[buff.type] then
			duration = buff.duration
		end
	end
	return duration
end

function Geometry:PredictReactionTime(unit, minimumReactionTime)
	if not minimumReactionTime then minimumReactionTime = .15 end
	local reactionTime = minimumReactionTime
	if unit.activeSpell and unit.activeSpell.valid then
		local windupRemaining = unit.activeSpell.startTime + unit.activeSpell.windup - GameTimer()
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
	local interceptTime = GameLatency()/2000 + delay + self:GetDistance(startPos, endPos) / speed
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
		if self:IsMinionIntersection(checkPosition, radius, checkDelay, radius * 2.5) then
			return true
		end
	end
	return false
end

function __Geometry:IsMinionIntersection(location, radius, delay, maxDistance)
	if not maxDistance then
		maxDistance = 650
	end
	for i = 1, GameMinionCount() do
		local minion = GameMinion(i)
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
	return target.isEnemy and target.isTargetable and target.alive and target.health > 0 and (target.visible or allowInvisible) 
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
	return target.pathing.isDashing and target.pathing.dashSpeed or target.ms
end


_G.Bravo =
{
	Geometry = Geometry()
}