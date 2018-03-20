
class "Velkoz"

local loaded = false
local forcedTarget
local qMissile
local qHitPoints
local lastSpellCast = Game.Timer()
local qPointsUpdatedAt = Game.Timer()
enemyPaths = {}


if myHero.charName ~= "Velkoz" then print("This Script is only compatible with Velkoz") return end
Callback.Add("Load",
function() 	
	Velkoz()
end)

function Velkoz:__init()
	Menu = MenuElement({type = MENU, id = myHero.charName, name = "[Deconstructed Velkoz]"})
	Callback.Add("Draw", function() self:Draw() end)
end

function Velkoz:TryLoad()
	if Game.Timer() < 30 then return end
	self.loaded = true	
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("WndMsg",function(Msg, Key) self:WndMsg(Msg, Key) end)
end

function Velkoz:CreateMenu()	
	Menu:MenuElement({id = "General", name = "General", type = MENU})
	Menu.General:MenuElement({id = "Drawing", name = "Drawing", type = MENU})
	Menu.General.Drawing:MenuElement({id = "DrawAA", name = "Draw AA Range", value = false})
	Menu.General.Drawing:MenuElement({id = "DrawQ", name = "Draw Q Range", value = false})
	Menu.General.Drawing:MenuElement({id = "DrawW", name = "Draw W Range", value = false})	
	Menu.General.Drawing:MenuElement({id = "DrawE", name = "Draw E Range", value = true})
	Menu.General.Drawing:MenuElement({id = "DrawEAim", name = "Draw E Aim", value = true})	
	Menu.General.Drawing:MenuElement({id = "DrawR", name = "Draw R Range", value = true})	
	
	Menu.General:MenuElement({id = "ReactionTime", name = "Enemy Reaction Time",tooltip = "How quickly (seconds) do you expect enemies to react to your spells. Used for predicting enemy movements", value = .25, min = .1, max = 1, step = .05 })		
	Menu.General:MenuElement({id = "DashTime", name = "Dash Time",tooltip = "How long must a dash be to auto cast on it", value = .5, min = .1, max = 2, step = .1 })
	Menu.General:MenuElement({id = "ImmobileTime", name = "Immobile Time",tooltip = "How long must a stun be to auto cast on them", value = .5, min = .1, max = 2, step = .1 })		
	Menu.General:MenuElement({id = "CastFrequency", name = "Cast Frequency Time",tooltip = "How quickly may spells be cast", value = .25, min = .1, max = 1, step = .1 })		
	Menu.General:MenuElement({id = "CheckInterval", name = "Collision Check Interval", value = 50, min = 10, max = 150, step = 10 })
	Menu.General:MenuElement({id = "Active", name = "Auto Skills Enabled",value = true, toggle = true, key = 0x7A })	
	Menu.General:MenuElement({id = "Combo", name = "Combo",value = false,  key = string.byte(" ") })	
	
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "Q", type = MENU})
	
	--By Default target everyone
	Menu.Skills.Q:MenuElement({id = "Targets", name = "Targets", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy then
			Menu.Skills.Q.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
		end
	end
	
	Menu.Skills.Q:MenuElement({id = "Detonate", name = "Auto Detonate", value = true })
	Menu.Skills.Q:MenuElement({id = "TargetImmobile", name = "Auto Q Immobile", value = true })
	Menu.Skills.Q:MenuElement({id = "TargetDashes", name = "Auto Q Dashes", value = true })
	Menu.Skills.Q:MenuElement({id = "Range", name = "Peel Range", value = 400, min = 100, max = 1000, step = 25 })
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 25, min = 1, max = 100, step = 5 })
	
	
	Menu.Skills:MenuElement({id = "W", name = "W", type = MENU})
	Menu.Skills.W:MenuElement({id = "Detonate", name = "Auto Detonate Passive", value = true })
	Menu.Skills.W:MenuElement({id = "TargetImmobile", name = "Auto W Immobile", value = true })
	Menu.Skills.W:MenuElement({id = "TargetDashes", name = "Auto W Dashes", value = false })
	Menu.Skills.W:MenuElement({id = "Mana", name = "Mana Limit", value = 25, min = 1, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "E", name = "E", type = MENU})
	--By Default target everyone
	Menu.Skills.E:MenuElement({id = "Targets", name = "Targets", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy then
			Menu.Skills.E.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
		end
	end
	Menu.Skills.E:MenuElement({id = "TargetImmobile", name = "Auto E Immobile", value = true })
	Menu.Skills.E:MenuElement({id = "TargetDashes", name = "Auto E Dashes", value = true })
	Menu.Skills.E:MenuElement({id = "TargetSlows", name = "Auto E Slows", value = true })
	Menu.Skills.E:MenuElement({id = "Radius", name = "Radius", value = 140, min = 50, max = 200, step = 10 })
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 1, max = 100, step = 5 })	
end

function Velkoz:LoadSpells()

	Q = {Range = 1050, Width = 55,Delay = 0.251, Speed = 1235}
	W = {Range = 1050, Width = 80,Delay = 0.25, Speed = 1500}
	E = {Range = 850, Width = 235,Delay = 0.75, Speed = math.huge}
	R = {Range = 1550,Width = 75, Delay = 0.25, Speed = math.huge}
end

function Velkoz:Draw()	
	if not self.loaded then
		self:TryLoad()
		return
	end
	
	if not Menu.General.Active:Value() then
		local textPos = myHero.pos:To2D()
		Draw.Text("Disabled", 20, textPos.x - 25, textPos.y + 40, Draw.Color(175, 255, 0, 0))
	end
	
	if Menu.General.Drawing.DrawAA:Value() then
		Draw.Circle(myHero.pos, 525, Draw.Color(100, 255, 255,255))
	end
	if KnowsSpell(_Q) and Menu.General.Drawing.DrawQ:Value() then
		Draw.Circle(myHero.pos, Q.Range, Draw.Color(150, 50, 50,50))
	end
	if KnowsSpell(_W) and Menu.General.Drawing.DrawW:Value() then
		Draw.Circle(myHero.pos, W.Range, Draw.Color(100, 0, 0,255))
	end
	if KnowsSpell(_E) then
		if Menu.General.Drawing.DrawE:Value() then
			Draw.Circle(myHero.pos, E.Range, Draw.Color(100, 0, 255,0))
		end
		if self.forcedTarget ~= nil and self:CanAttack(self.forcedTarget) and Menu.General.Drawing.DrawEAim:Value() then
			local targetOrigin = self:PredictUnitPosition(self.forcedTarget, E.Delay)
			local interceptTime = self:GetSpellInterceptTime(myHero.pos, targetOrigin, E.Delay, E.Speed)			
			local origin, radius = self:UnitMovementBounds(self.forcedTarget, interceptTime, Menu.General.ReactionTime:Value())			
			if radius < 25 then
				radius = 25
			end
			Draw.Circle(origin, 25,10)		
			Draw.Circle(origin, radius,1, Draw.Color(50, 255, 255,255))						
		end
	end
	if KnowsSpell(_R) and Menu.General.Drawing.DrawR:Value() then
		Draw.Circle(myHero.pos, R.Range, Draw.Color(100, 255, 0,0))
	end
	
end

function Velkoz:Tick()
	if IsRecalling() or self:IsRActive() or not Menu.General.Active:Value() then return end
	
	if Game.Timer() -lastSpellCast < Menu.General.CastFrequency:Value() then return end
	self:UpdateTargetPaths()
	
	if Ready(_Q) then
		self:UpdateQInfo()		
		if Menu.Skills.Q.Detonate:Value() and self:IsQActive() then
			self:DetonateQ()
		elseif CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and not self:IsEvading() and not self:IsQActive() then
			self:AutoQ()
		end
	end		
	
	if Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() then
		self:AutoW()
	end
	
	if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() and not self:IsEvading() then
		self:AutoE()
	end
end

--Checks if our Q can be detonated to hit a target or if it should be allowed to fly straight
function Velkoz:DetonateQ()
	if Game.Timer() - qPointsUpdatedAt < .25 and self:IsQActive() and qHitPoints then
		for i = 1, #qHitPoints do		
			if qHitPoints[i] then
				if qHitPoints[i].playerHit and Menu.Skills.Q.Targets[qHitPoints[i].playerHit.charName] and Menu.Skills.Q.Targets[qHitPoints[i].playerHit.charName]:Value()then					
					Control.CastSpell(HK_Q)
				end
			end
		end
	end	
end

local qAngles = {0, -15, 15, -30, 30, -45, 45, -60, 60}
local qLastChecked = 1
local qResults = {}

function Velkoz:GetTarget(range)
	if _G.SDK then
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL);
	elseif _G.EOW then
		return _G.EOW:GetTarget(range)
	else
		return _G.GOS:GetTarget(range,"AD")
	end
end

function Velkoz:AutoQ()

	if Menu.General.Combo:Value() and Game.Timer() - qLastChecked > .25 then
		qLastChecked = Game.Timer()
		local target = self:GetTarget(2000)
		if target ~= nil and self:CanAttack(target) then		
			--TODO Check angles towards target for best one and fire Q if possible to hit.
		end
	end
	
	for i = 1, Game:HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.isEnemy and self:CanAttack(enemy) then
			local predictedPosition = self:PredictUnitPosition(enemy,Q.Delay)
				
			if self:GetDistance(myHero.pos, predictedPosition) <= Menu.Skills.Q.Range:Value() then			
				if not self:CheckMinionCollision(myHero, predictedPosition, Q.Delay, Q.Width, Q.Speed, Q.Range, myHero.pos) then				
					Control.CastSpell(HK_Q, predictedPosition)
					lastSpellCast = Game.Timer()
					return
				end
			end
		end
	end
end

function Velkoz:AutoW()
	local hasCast = false		
	
	if Menu.Skills.W.TargetImmobile:Value() then
		hasCast = self:AutoWStasis()		
		if not hasCast then
			hasCast = self:AutoWImmobile()
		end		
	end	
	
	if not hasCast and Menu.Skills.W.TargetDashes:Value() then
		hasCast = self:AutoWDash()
	end
	
	if not hasCast and Menu.Skills.W.Detonate:Value() then
		hasCast = self:AutoWDetonate()
	end
end


function Velkoz:AutoWStasis()
	local enemy, aimPos = self:GetStasisTarget(myHero.pos, W.Range, W.Delay, W.Speed, Menu.General.ReactionTime:Value())
	if enemy and self:GetDistance(myHero.pos, aimPos) <= W.Range then
		Control.CastSpell(HK_W, aimPos)
		lastSpellCast = Game.Timer()
		return true
	end
	return false
end

function Velkoz:AutoWImmobile()
	local enemy, ccTime = self:GetImmobileTarget(myHero.pos, W.Range, Menu.General.ImmobileTime:Value())
	if enemy and self:GetDistance(myHero.pos, enemy.pos) <= W.Range then
		Control.CastSpell(HK_W, enemy.pos)
		lastSpellCast = Game.Timer()
		return true
	end
	return false	
end

function Velkoz:AutoWDash()
	local enemy, aimPos = self:GetInteruptTarget(myHero.pos, W.Range, W.Delay, W.Speed, Menu.General.DashTime:Value())
	if enemy and self:CanAttack(enemy) and self:GetDistance(myHero.pos, aimPos) <= W.Range then
		Control.CastSpell(HK_W, aimPos)
		lastSpellCast = Game.Timer()		
		return true
	end
	return false
end

function Velkoz:AutoWDetonate()
	local enemy = self:Find2PassiveTarget()
	if enemy and self:CanAttack(enemy) then
		local aimLocation = self:PredictUnitPosition(enemy, self:GetSpellInterceptTime(myHero.pos, enemy.pos, W.Delay, W.Speed))
		if self:GetDistance(myHero.pos, aimLocation) < W.Range * 3 / 4 then
			Control.CastSpell(HK_W, aimLocation)
			lastSpellCast = Game.Timer()
			return true
		end
	end
	
	return false
end

function Velkoz:Find2PassiveTarget()
	local target
	for hi = 1, Game:HeroCount() do
		local enemy = Game.Hero(hi)
		if enemy.isEnemy and self:CanAttack(enemy) then
			for i = 0, enemy.buffCount do
				local buff = enemy:GetBuff(i)
				if buff.name == "velkozresearchstack" and buff.count == 2 and buff.duration > 0 and self:GetDistance(myHero.pos, enemy.pos) < W.Range then
					target = enemy
				end
			end
		end
	end
	
	return target
end

function Velkoz:AutoE()
	
	local hasCast = false	
	if Menu.Skills.E.TargetImmobile:Value() then
		hasCast = self:AutoEStasis()		
		if not hasCast then
			hasCast = self:AutoEImmobile()
		end		
	end
	
	
	if not hasCast and Menu.Skills.E.TargetDashes:Value() then
		hasCast = self:AutoEDash()
	end
	
	if not hasCast and Menu.Skills.E.TargetSlows:Value() then	
		for i = 1, Game:HeroCount() do
			local enemy = Game.Hero(i)
			if  self:CanAttack(enemy)  and Menu.Skills.E.Targets[enemy.charName] and Menu.Skills.E.Targets[enemy.charName]:Value() then				
				hasCast = self:AutoERadius(enemy)
			end
		end	
	end	
end

function Velkoz:AutoERadius(enemy)
	--Auto cast E on target if the potential movement radius is small enough (slow target)
	--If the target JUST changed their movement direction dont auto E. This is to stop it wasting on targets who spam click in a circle trying to dodge. Better to wait 
	local deltaTime, endPos = self:PreviousPathDetails(enemy.charName)
	if deltaTime and Game.Timer() - deltaTime < Menu.General.ReactionTime:Value() then
		return false
	end
	local targetOrigin = self:PredictUnitPosition(enemy, E.Delay)
	local interceptTime = self:GetSpellInterceptTime(myHero.pos, targetOrigin, E.Delay, E.Speed)			
	local origin, radius = self:UnitMovementBounds(enemy, interceptTime, Menu.General.ReactionTime:Value())			
	
	--TODO: Lerp the aim position based on time since last movement update/angle of movement change
	if radius < Menu.Skills.E.Radius:Value() and self:GetDistance(myHero.pos, origin) <= E.Range then
		Control.CastSpell(HK_E, origin)
		lastSpellCast = Game.Timer()
		return true
	end
	
	return false
end

function Velkoz:AutoEStasis()
	local enemy,aimPos = self:GetStasisTarget(myHero.pos, E.Range, E.Delay, E.Speed, Menu.General.ReactionTime:Value())
	if enemy and self:GetDistance(myHero.pos, aimPos) <= E.Range then
		Control.CastSpell(HK_E, aimPos)
		lastSpellCast = Game.Timer()
		return true
	end
	return false
end

function Velkoz:AutoEImmobile()
	local enemy, ccTime = self:GetImmobileTarget(myHero.pos, E.Range, Menu.General.ImmobileTime:Value())
	if enemy and self:GetDistance(myHero.pos, enemy.pos) <= E.Range then
		Control.CastSpell(HK_E, enemy.pos)
		lastSpellCast = Game.Timer()
		return true
	end
	return false	
end


function Velkoz:AutoEDash()
	local enemy,aimPos = self:GetInteruptTarget(myHero.pos, E.Range, E.Delay, E.Speed, Menu.General.DashTime:Value())
	if enemy and self:CanAttack(enemy) and self:GetDistance(myHero.pos,aimPos) <= E.Range and Menu.Skills.E.Targets[enemy.charName] and Menu.Skills.E.Targets[enemy.charName]:Value() then
		Control.CastSpell(HK_E, aimPos)
		lastSpellCast = Game.Timer()
		return true
	end
	return false
end

function Velkoz:UpdateQInfo()

	--Check to see if our Q can be detonated to hit any enemys
	if self:IsQActive() then	
		local directionVector = Vector(qMissile.missileData.endPos.x - qMissile.missileData.startPos.x,qMissile.missileData.endPos.y - qMissile.missileData.startPos.y,qMissile.missileData.endPos.z - qMissile.missileData.startPos.z):Normalized()										
		local checkInterval = Menu.General.CheckInterval:Value()
		local pointCount = 600 / checkInterval * 2
		qHitPoints = {}
		
		--Adds the 'up' split points
		for i = 1, pointCount, 2 do
			local result =  self:CalculateNode(qMissile,  qMissile.pos + directionVector:Perpendicular() * i * checkInterval)			
			qHitPoints[i] = result
			if result.collision then
				break
			end
		end
				
		--Adds the 'down' split points
		for i = 2, pointCount, 2 do		
			local result =  self:CalculateNode(qMissile,  qMissile.pos + directionVector:Perpendicular2() * i * checkInterval)			
			qHitPoints[i] = result	
			if result.collision then
				break
			end
		end		
		qPointsUpdatedAt = Game.Timer()
		
	end
	
	--Record our Q data	
	local qData = myHero:GetSpellData(_Q)
	if Game.Timer() - qData.castTime < .1 then
		for i = 1, Game.MissileCount() do
			local missile = Game.Missile(i)
			if missile.name == "VelkozQMissile" and self:GetDistance(missile.pos, myHero.pos) < 400 then
				qMissile = missile
			end
		end
	end
end


function Velkoz:WndMsg(msg,key)
	if msg == 513 then
		local starget = nil
		for i  = 1,Game.HeroCount(i) do
			local enemy = Game.Hero(i)
			if enemy.alive and enemy.isEnemy and self:GetDistance(mousePos, enemy.pos) < 250 then
				starget = enemy
				break
			end
		end
		if starget then
			self.forcedTarget = starget
		else
			self.forcedTarget = nil
		end
	end	
end


--Returns a node for our Q (position, delay, collision and playerHit)
function Velkoz:CalculateNode(missile, nodePos)
	local result = {}
	result["pos"] = nodePos
	result["delay"] = 0.251 + self:GetDistance(missile.pos, nodePos) / Q.Speed
	
	local isCollision = self:CheckMinionIntercection(nodePos, 55, result["delay"])
	local hitEnemy 
	if not isCollision then
		isCollision, hitEnemy = self:CheckEnemyCollision(nodePos, 55, result["delay"])
	end
	
	result["playerHit"] = hitEnemy
	result["collision"] = isCollision
	return result
end


--Returns if our Q is currently active (still flying and not split)
function Velkoz:IsQActive()
	return qMissile and qMissile.name and qMissile.name == "VelkozQMissile"
end


--Returns if our R is currently channeling. If so do not try to move/cast spells
function Velkoz:IsRActive()
	if myHero.activeSpell and myHero.activeSpell.valid and myHero.activeSpell.name == "VelkozR" then
		return true
	else
		return false
	end
end

function Velkoz:IsEvading()	
    if ExtLibEvade and ExtLibEvade.Evading then return true end
	return false
end


--Returns if a minion will be hit
function Velkoz:CheckMinionIntercection(location, radius, delay, maxDistance)
	if not maxDistance then
		maxDistance = 1200
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

function Velkoz:VectorPointProjectionOnLineSegment(v1, v2, v)
	assert(v1 and v2 and v, "VectorPointProjectionOnLineSegment: wrong argument types (3 <Vector> expected)")
	local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
	local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
	local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
	local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	local isOnSegment = rS == rL
	local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
	return pointSegment, pointLine, isOnSegment
end

function Velkoz:CheckCol(source, startPos, minion, endPos, delay, speed, range, radius)
	if source.networkID == minion.networkID then 
		return false
	end
	
	if _G.SDK and startPos and minion and minion.pos and minion.type ~= myHero.type and _G.SDK.HealthPrediction:GetPrediction(minion, delay + self:GetDistance(startPos, minion.pos) / speed - Game.Latency()/1000) < 0 then
		return false
	end
	
	local waypoints = self:GetPathNodes(minion)
	local MPos, CastPosition = #waypoints == 1 and Vector(minion.pos) or self:PredictUnitPosition(minion, delay)
	
	if startPos and MPos and self:GetDistanceSqr(startPos, MPos) <= (range)^2 and self:GetDistanceSqr(startPos, minion.pos) <= (range + 100)^2 then
		local buffer = (#waypoints > 1) and 8 or 0 
		
		if minion.type == myHero.type then
			buffer = buffer + minion.boundingRadius
		end
		
		if #waypoints > 1 then
			local proj1, pointLine, isOnSegment = self:VectorPointProjectionOnLineSegment(startPos, endPos, Vector(MPos))
			if proj1 and isOnSegment and (self:GetDistanceSqr(MPos, proj1) <= (minion.boundingRadius + radius + buffer) ^ 2) then				
				return true		
			end
		end
		
		local proj2, pointLine, isOnSegment = self:VectorPointProjectionOnLineSegment(startPos, endPos, Vector(minion.pos))
		if proj2 and isOnSegment and (self:GetDistanceSqr(minion.pos, proj2) <= (minion.boundingRadius + radius + buffer) ^ 2) then
			return true
		end
	end
end

function Velkoz:CheckMinionCollision(source, endPos, delay, radius, speed, range, start)
	if (_G.SDK) then
		return self:CheckMinionCollisionIC(source, endPos, delay, radius, speed, range, start)
	else
		return self:CheckMinionCollisionNoOrb(source, endPos, delay, radius, speed, range, start)
	end
end

function Velkoz:CheckMinionCollisionNoOrb(source, endPos, delay, radius, speed, range, start)
	local startPos = myHero.pos
	if start then
		startPos = start
	end
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion.alive and minion.isEnemy and self:GetDistance(startPos, minion.pos) < range then
			if self:CheckCol(source, startPos, minion, endPos, delay, speed, range, radius) then
				return true
			end
		end
	end
end


function Velkoz:CheckMinionCollisionIC(source, endPos, delay, radius, speed, range, start)
	local startPos = myHero.pos
	if start then
		startPos = start
	end
		
	for i, minion in ipairs(_G.SDK.ObjectManager:GetEnemyMinions(range)) do
		if self:CheckCol(source, startPos, minion, endPos, delay, speed ,range,  radius) then
			return true
		end
	end
	for i, minion in ipairs(_G.SDK.ObjectManager:GetMonsters(range)) do
		if self:CheckCol(source, startPos, minion, endPos, delay, speed ,range,  radius) then
			return true
		end
	end
	for i, minion in ipairs(_G.SDK.ObjectManager:GetOtherEnemyMinions(range)) do
		if minion.team ~= myHero.team and self:CheckCol(source, startPos, minion, endPos, delay, speed ,range,  radius) then
			return true
		end
	end
	
	return false
end

--Returns if an enemy will be hit and optionally will return the enemy
function Velkoz:CheckEnemyCollision(location, radius, delay, maxDistance)
	if not maxDistance then
		maxDistance = 1200
	end
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if self:CanAttack(hero) and hero.visible and hero.alive and self:GetDistance(hero.pos, location) < maxDistance then
			local predictedPosition = self:PredictUnitPosition(hero, delay)
			if self:GetDistance(location, predictedPosition) < radius + hero.boundingRadius then
				return true, hero
			end
		end
	end
	
	return false
end

function Velkoz:GetTargetMS(target)
	local ms = target.pathing.isDashing and target.pathing.dashSpeed or target.ms
	return ms
end

--Returns where the unit will be when the delay has passed given current pathing information. This assumes the target makes NO CHANGES during the delay.
function Velkoz:PredictUnitPosition(unit, delay)
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

--Returns a position and radius in which the target could potentially move before the delay ends. ReactionTime defines how quick we expect the target to be able to change their current path
function Velkoz:UnitMovementBounds(unit, delay, reactionTime)
	local startPosition = self:PredictUnitPosition(unit, delay)
	
	local radius = 0
	local deltaDelay = delay -reactionTime- self:GetImmobileTime(unit)	
	if (deltaDelay >0) then
		radius = self:GetTargetMS(unit) * deltaDelay	
	end
	return startPosition, radius	
end

--Returns how long (in seconds) the target will be unable to move from their current location
function Velkoz:GetImmobileTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.count > 0 and buff.duration> duration and (buff.type == 5 or buff.type == 8 or buff.type == 21 or buff.type == 22 or buff.type == 24 or buff.type == 11) then
			duration = buff.duration
		end
	end
	return duration		
end

--Returns how long (in seconds) the target will be slowed for
function Velkoz:GetSlowedTime(unit)
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
function Velkoz:GetPathNodes(unit)
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
function Velkoz:GetPathLength(nodes)
	local result = 0
	for i = 1, #nodes -1 do
		result = result + self:GetDistance(nodes[i], nodes[i + 1])
	end
	return result
end

function Velkoz:GetDistanceSqr(p1, p2)
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function Velkoz:GetDistance(p1, p2)
	return math.sqrt(self:GetDistanceSqr(p1, p2))
end


function Velkoz:GetSpellInterceptTime(startPos, endPos, delay, speed)	
	local interceptTime = delay + self:GetDistance(startPos, endPos) / speed
	return interceptTime
end


function Velkoz:TryGetBuff(unit, buffname)	
	for i = 1, unit.buffCount do 
		local Buff = unit:GetBuff(i)
		if Buff.name == buffname and Buff.duration > 0 then
			return Buff, true
		end
	end
	return nil, false
end

function Velkoz:GetStasisTarget(source, range, delay, speed, timingAccuracy)
	local target	
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		local buff, success = self:TryGetBuff(t, "zhonyasringshield")
		if success and t.isEnemy and buff ~= nil then
			local deltaInterceptTime = self:GetSpellInterceptTime(myHero.pos, t.pos, delay, speed) - buff.duration
			if deltaInterceptTime > -Game.Latency() / 2000 and deltaInterceptTime < timingAccuracy then
				target = t
				return target, target.pos
			end
		end
	end
	--Get teleporting enemies to wards
	for i = 1, Game.WardCount() do
		local ward = Game.Ward(i);
		if ward.isEnemy and self:GetDistance(source, ward.pos) <= range then
			for i = 1, ward.buffCount do 
				local Buff = ward:GetBuff(i)
				if Buff.duration > 0 and Buff.name == "teleport_target" then
					local skillInterceptTime = self:GetSpellInterceptTime(myHero.pos, ward.pos, delay, speed)
					if Buff.duration < skillInterceptTime and skillInterceptTime - Buff.duration < timingAccuracy then
						--Return a dummy target to hit. We wont be checking their distance, only that they are a valid person to attack. Means less re-writes elsewhere
						print("TELEPORT WARD")
						return ward, ward.pos
					end
				end
			end
		end
	end
	
	--Get teleporting enemies to minions
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i);
		if minion.isEnemy and self:GetDistance(source, minion.pos) <= range then
			for i = 1, minion.buffCount do 
				local Buff = minion:GetBuff(i)
				if Buff.duration > 0 and Buff.name == "teleport_target" then
					local skillInterceptTime = self:GetSpellInterceptTime(myHero.pos, minion.pos, delay, speed)
					if Buff.duration < skillInterceptTime and skillInterceptTime - Buff.duration < timingAccuracy then
						--Return a dummy target to hit. We wont be checking their distance, only that they are a valid person to attack. Means less re-writes elsewhere
						print("TELEPORT MINION")
						return minion, minion.pos
					end
				end
			end
		end
	end
end

function Velkoz:GetImmobileTarget(source, range, minimumCCTime)
	--TODO: Give priority to certain targets in case of tie. Right now I prioritize based on maximum CC effect (not over stunning)	
	local bestTarget
	local bestCCTime = 0
	for heroIndex = 1,Game.HeroCount()  do
		local enemy = Game.Hero(heroIndex)
		if enemy and self:CanAttack(enemy) and self:GetDistance(source, enemy.pos) <= range then
			for buffIndex = 0, enemy.buffCount do
				local buff = enemy:GetBuff(buffIndex)
				
				if (buff.type == 5 or buff.type == 8 or buff.type == 21 or buff.type == 22 or buff.type == 24 or buff.type == 11) then					
					if(buff.duration > minimumCCTime and buff.duration > bestCCTime) then
						bestTarget = enemy
						bestCCTime = buff.duration
					end
				end
			end
		end
	end	
	return bestTarget, bestCCTime
end

function Velkoz:GetInteruptTarget(source, range, delay, speed, timingAccuracy)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if t.isEnemy and t.pathing.hasMovePath and t.pathing.isDashing and t.pathing.dashSpeed>500  then
			local dashEndPosition = t:GetPath(1)
			if self:GetDistance(source, dashEndPosition) <= range then				
				--The dash ends within range of our skill. We now need to find if our spell can connect with them very close to the time their dash will end
				local dashTimeRemaining = self:GetDistance(t.pos, dashEndPosition) / t.pathing.dashSpeed
				local skillInterceptTime = self:GetSpellInterceptTime(myHero.pos, dashEndPosition, delay, speed)
				local deltaInterceptTime = math.abs(skillInterceptTime - dashTimeRemaining)
				if deltaInterceptTime < timingAccuracy then
					target = t
					aimPosition = enemy.pathing.endPos
					return target, aimPosition
				end
			end			
		end
	end
	
	
end

function Velkoz:CanAttack(target)
	return target.isEnemy and target.alive and target.visible and target.isTargetable and not target.isImmortal
end


function Velkoz:UpdateTargetPaths()
	for i = 1, Game:HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.isEnemy then
			if not enemyPaths[enemy.charName] then
				enemyPaths[enemy.charName] = {}
			end
			
			if enemy.pathing and enemy.pathing.hasMovePath and enemyPaths[enemy.charName] and self:GetDistance(enemy.pathing.endPos, Vector(enemyPaths[enemy.charName].endPos)) > 56 then
				
				enemyPaths[enemy.charName]["time"] = Game.Timer()
				enemyPaths[enemy.charName]["endPos"] = enemy.pathing.endPos					
			end
		end
	end
end

function Velkoz:PreviousPathDetails(charName)
	local deltaTime = 0
	local pathEnd
	
	if enemyPaths and enemyPaths[charName] and enemyPaths[charName]["time"] then
		deltaTime = enemyPaths[charName]["time"]
		pathEnd = enemyPaths[charName]["endPos"]
	end
	return deltaTime, pathEnd
end


function Ready(spellSlot)
	return IsReady(spellSlot)
end

function IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function IsRecalling()
	for K, Buff in pairs(GetBuffs(myHero)) do
		if Buff.name == "recall" and Buff.duration > 0 then
			return true
		end
	end
	return false
end

function KnowsSpell(spell)
	local spellInfo = myHero:GetSpellData(spell)
	if spellInfo and spellInfo.level > 0 then
		return true
	end
	return false
end


 		
function CurrentPctLife(entity)
	local pctLife =  entity.health/entity.maxHealth  * 100
	return pctLife
end

function CurrentPctMana(entity)
	local pctMana =  entity.mana/entity.maxMana * 100
	return pctMana
end
