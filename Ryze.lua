
class "Ryze"

local LastSpellCast = Game.Timer()
local forcedTarget

if myHero.charName ~= "Ryze" then print("This Script is only compatible with Ryze") return end
Callback.Add("Load",
function() 	
	Ryze()
end)

function Ryze:__init()
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	Callback.Add("WndMsg",function(Msg, Key) self:WndMsg(Msg, Key) end)
end

function Ryze:CreateMenu()
	Menu = MenuElement({type = MENU, id = myHero.charName, name = "[Rune-Forged Ryze]"})
	
	Menu:MenuElement({id = "General", name = "General", type = MENU})
	Menu.General:MenuElement({id = "DrawAA", name = "Draw AA Range", value = false})
	Menu.General:MenuElement({id = "DrawQ", name = "Draw Q Range", value = false})
	Menu.General:MenuElement({id = "DrawW", name = "Draw W Range", value = false})	
	Menu.General:MenuElement({id = "DrawE", name = "Draw E Range", value = true})
	Menu.General:MenuElement({id = "ReactionTime", name = "Enemy Reaction Time",tooltip = "How quickly (seconds) do you expect enemies to react to your spells. Used for predicting enemy movements", value = .25, min = .1, max = 1, step = .05 })	
	Menu.General:MenuElement({id = "SpellDelay", name = "SpellDelay", value = .5, min = .25, max = 1, step =.1})	
	
	
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Overload", type = MENU})
	Menu.Skills.Q:MenuElement({id = "LastHit", name = "Use for Last Hit", value = true })
	Menu.Skills.Q:MenuElement({id = "HarassMana", name = "Harass Mana Limit", value = 30, min = 1, max = 100, step = 5 })	
	Menu.Skills.Q:MenuElement({id = "HitChance", name = "Combo Hit Chance", value = 3, min = 1, max = 5, step =1 })
	Menu.Skills.Q:MenuElement({id = "MinimumCooldown", name = "Minimum Reset Cooldown", value = 1, min = .25, max = 5, step =.25 })
	
	Menu.Skills:MenuElement({id = "W", name = "[W] Rune Prison", type = MENU})
	
	
	Menu.Skills.W:MenuElement({id = "AutoPeel", name = "Auto Peel", value = true })
	Menu.Skills.W:MenuElement({id = "PeelRadius", name = "Peel Radius", value = 300, min = 100, max = 500, step = 25 })
	Menu.Skills.W:MenuElement({id = "Mana", name = "Peel Mana Limit", value = 15, min = 1, max = 100, step = 5 })
	
	Menu.Skills.W:MenuElement({id = "Harass", name = "Use In Harass", value = true })
	Menu.Skills.W:MenuElement({id = "HarassMana", name = "Harass Mana Limit", value = 25, min = 1, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Spell Flux", type = MENU})
	Menu.Skills.E:MenuElement({id = "Harass", name = "Use In Harass", value = true })
	Menu.Skills.E:MenuElement({id = "HarassMana", name = "Harass Mana Limit", value = 25, min = 1, max = 100, step = 5 })
	
end

function Ryze:LoadSpells()

	Q = {Range = 1000, Width = 50,Delay = 0.25, Speed = 1700,  Sort = "line"}
	W = {Range = 615, Delay = 0.25, Speed = math.huge}
	E = {Range = 615,Delay = 0.75, Speed = 2000}
end

function Ryze:Draw()		
	if Menu.General.DrawAA:Value() then
		Draw.Circle(myHero.pos, 550, Draw.Color(100, 255, 255,255))
	end	
	if KnowsSpell(_Q) and Menu.General.DrawQ:Value() then
		Draw.Circle(myHero.pos, Q.Range, Draw.Color(150, 50, 50,50))
	end
	if KnowsSpell(_W) and Menu.General.DrawW:Value() then
		Draw.Circle(myHero.pos, W.Range, Draw.Color(100, 0, 0,255))
	end
	if KnowsSpell(_E) and Menu.General.DrawE:Value() then
			Draw.Circle(myHero.pos, E.Range, Draw.Color(100, 0, 255,0))		
	end
end



function Ryze:Tick()
	if IsRecalling() then return end
	
	--Should work to turn off the orbwalker and auto skills while evade is dodging
	if self:IsEvading() then
		self:DisableOrbWalk()
		return
	else
		self:EnableOrbWalk()
	end
	
	--Orbwalker says we're in combo mode
	if self:IsComboActive() then 
		self:Combo()		
	end	
	
	if self:IsHarassActive() then 
		self:Harass()		
	end
	
	if Menu.Skills.W.AutoPeel:Value() then
		self:Peel()
	end
end

function Ryze:Peel()
	local target = self:GetInteruptTarget(myHero.pos, W.Range, Q.Delay, Q.Speed, .0)	
	if target == nil then
		target = self:GetImmobileTarget(myHero.pos, W.Range, Q.Delay)
	end
	
	if target == nil then
		local distance = Menu.Skills.W.PeelRadius:Value()
		for i  = 1,Game.HeroCount(i) do
			local enemy = Game.Hero(i)
			if enemy.alive and enemy.isEnemy and self:GetDistance(myHero.pos, enemy.pos) < distance then
				distance = self:GetDistance(myHero.pos, enemy.pos)
				target = enemy
			end
		end
	end
	
	if Ready(_W)  and target ~= nil and self:CanAttack(target) and self:GetDistance(myHero.pos, target.pos) <=  Menu.Skills.W.PeelRadius:Value() then
		--Hit target with E W combo
		if Ready(_E) then	
			self:CastSpell(HK_E, target.pos)
			LastSpellCast = Game.Timer() + .5
			DelayAction(function() Control.CastSpell(HK_W, target.pos) end,0.35)			
		else
			self:CastSpell(HK_W, target.pos)
		end	
	end	
end


function Ryze:Harass()	
	--E minions near death if player is adjacent
	self:EBounceMinions()
	
	--Q enemy if they have RyzeE buff on them
	--Q minion if it has RyzeE buff on it and is standing next to a player with RyzeE buff on them (detonate all)	
end
function Ryze:Combo()


	--Pick the highest hitchance target within Q range to cast on.	
	if Ready(_Q) then
		local target
		local hitChance = 0 
		local aimPosition
		for i  = 1,Game.HeroCount(i) do
			local enemy = Game.Hero(i)
			if enemy.alive and enemy.isEnemy and self:GetDistance(myHero.pos, enemy.pos) < Q.Range then
				local tHitChance, tAimPosition = self:GetTargetHitChance(enemy, Q.Delay, Q.Speed, Q.Width, Q.Range, true, "Line")
				if tHitChance > hitChance and self:GetDistance(myHero.pos, tAimPosition) < Q.Range then				
					hitChance = tHitChance
					aimPosition = tAimPosition
					target = enemy
					
					--If we've forced a target and they are in range: don't choose anyone else! 
					--This will stop us wasting Qs on random higher hitrate targets if we've clicked a specific enemy
					if self.forcedTarget and enemy ==  self.forcedTarget then
						break
					end
				end				
			end
		end
		if target ~= nil and hitChance >= Menu.Skills.Q.HitChance:Value() then
			self:CastSpell(HK_Q, aimPosition)		
		end
	end
	
	--Q is on cooldown, cast E or W instead	
	if myHero:GetSpellData(_Q).currentCd > Menu.Skills.Q.MinimumCooldown:Value() then
		local target = self:GetTarget(W.Range)
		if target ~= nil then
			if Ready(_E) and self:CanAttack(target) and self:GetDistance(myHero.pos, target.pos) < E.Range then		
				self:CastSpell(HK_E, target.pos)	
			elseif Ready(_W) and self:CanAttack(target) and self:GetDistance(myHero.pos, target.pos) < W.Range then		
				self:CastSpell(HK_W, target.pos)
			end
		end
	end
	
	self:EBounceMinions() 
end

function Ryze:EBounceMinions()
	if Menu.Skills.E.Harass:Value() and Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.HarassMana:Value() then	
		for i, minion in ipairs(_G.SDK.ObjectManager:GetEnemyMinions(range)) do
			if self:GetDistance(myHero.pos, minion.pos) < E.Range then
				if self:GetEDamage(minion) > minion.health then
					local distance, enemy = self:NearestEnemy(minion)
					if distance < 300 then
						self:CastSpell(HK_E, minion.pos)	
					end
				end
			end
		end
	end
end

function Ryze:GetEDamage(target)
	--E.Level * 20 + 70 + .3AP + 1% Bonus Mana
	local damage = 70 + myHero:GetSpellData(_E).level * 20 + myHero.ap * .3
	return damage
end
function Ryze:IsHarassActive()
	if _G.SDK and _G.SDK.Orbwalker then		
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then 
			if myHero.activeSpell and 
				myHero.activeSpell.valid and 
				myHero.activeSpell.startTime + myHero.activeSpell.windup - Game.Timer() > 0 
			then
				return false
			else
				return true
			end
		end
	end	
	if _G.GOS and _G.GOS.GetMode() == "Harass" and not _G.GOS:IsAttacking() then
		return true
	end	
end

function Ryze:IsComboActive()
	if _G.SDK and _G.SDK.Orbwalker then		
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then 
			if myHero.activeSpell and 
				myHero.activeSpell.valid and 
				myHero.activeSpell.startTime + myHero.activeSpell.windup - Game.Timer() > 0 
			then
				return false
			else
				return true
			end
		end
	end	
	if _G.GOS and _G.GOS.GetMode() == "Combo" and not _G.GOS:IsAttacking() then
		return true
	end	
end

function Ryze:NearestEnemy(entity)
	local distance = 999999
	local enemy = nil
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if self:CanAttack(hero) then
			local d = self:GetDistance(entity.pos, hero.pos)
			if d < distance then
				distance = d
				enemy = hero
			end
		end
	end
	return distance, enemy
end

function Ryze:CastSpell(spell,pos)
	if Game.Timer() - LastSpellCast < Menu.General.SpellDelay:Value() then return end
	LastSpellCast = Game.Timer()
	self:DisableOrbWalk()
	self:DisableOrbAttack()
	DelayAction(function() Control.CastSpell(spell, pos) end,0.05)	
	DelayAction(function() self:EnableOrbWalk() end,0.1)
	DelayAction(function() self:EnableOrbAttack() end,Menu.General.SpellDelay:Value())
end

function Ryze:EnableOrbAttack()
	if _G.SDK and _G.SDK.Orbwalker then
		_G.SDK.Orbwalker:SetAttack(true)
	end
	if _G.GOS then
		_G.GOS.BlockAttack  = false
	end
end

function Ryze:EnableOrbWalk()
	if _G.SDK and _G.SDK.Orbwalker then
		_G.SDK.Orbwalker:SetMovement(true)
	end
	if _G.GOS then
		_G.GOS.BlockMovement = false
	end
end

function Ryze:DisableOrbAttack()
	if _G.SDK and _G.SDK.Orbwalker then
		_G.SDK.Orbwalker:SetAttack(false)
	end
	if _G.GOS then
		_G.GOS.BlockAttack  = true
	end
end


function Ryze:DisableOrbWalk()
	if _G.SDK and _G.SDK.Orbwalker then
		_G.SDK.Orbwalker:SetMovement(false)
	end
	if _G.GOS then
		_G.GOS.BlockMovement = true
	end
end


function Ryze:GetTarget(range)
	if self.forcedTarget and self:GetDistance(myHero.pos, self.forcedTarget.pos) <= range then
		return self.forcedTarget		
	end
	if _G.SDK then
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL);
	elseif _G.EOW then
		return _G.EOW:GetTarget(range)
	else
		return _G.GOS:GetTarget(range,"AD")
	end
end


function Ryze:WndMsg(msg,key)
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


function Ryze:IsEvading()	
    if ExtLibEvade and ExtLibEvade.Evading then return true end
	return false
end

--Returns where the unit will be when the delay has passed given current pathing information. This assumes the target makes NO CHANGES during the delay.
function Ryze:PredictUnitPosition(unit, delay)
	local predictedPosition = unit.pos
	local timeRemaining = delay
	local pathNodes = self:GetPathNodes(unit)
	for i = 1, #pathNodes -1 do
		local nodeDistance = self:GetDistance(pathNodes[i], pathNodes[i +1])
		local nodeTraversalTime = nodeDistance / unit.ms
			
		if timeRemaining > nodeTraversalTime then
			--This node of the path will be completed before the delay has finished. Move on to the next node if one remains
			timeRemaining =  timeRemaining - nodeTraversalTime
			predictedPosition = pathNodes[i + 1]
		else
			local directionVector = (pathNodes[i+1] - pathNodes[i]):Normalized()
			predictedPosition = pathNodes[i] + directionVector *  unit.ms * timeRemaining
			break;
		end
	end
	return predictedPosition
end

--Returns a position and radius in which the target could potentially move before the delay ends. ReactionTime defines how quick we expect the target to be able to change their current path
function Ryze:UnitMovementBounds(unit, delay, reactionTime)
	local startPosition = self:PredictUnitPosition(unit, delay)
	
	local radius = 0
	local deltaDelay = delay -reactionTime- self:GetImmobileTime(unit)	
	if (deltaDelay >0) then
		radius = unit.ms * deltaDelay	
	end
	return startPosition, radius	
end

--Returns how long (in seconds) the target will be unable to move from their current location
function Ryze:GetImmobileTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.count > 0 and buff.duration> duration and (buff.type == 5 or buff.type == 8 or buff.type == 21 or buff.type == 22 or buff.type == 24 or buff.type == 11) then
			duration = buff.duration
		end
	end
	return duration		
end

function Ryze:HasBuff(unit, buffName)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.duration> 0 and buff.name == buffName then
			return true
		end
	end	
end

--Returns how long (in seconds) the target will be slowed for
function Ryze:GetSlowedTime(unit)
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
function Ryze:GetPathNodes(unit)
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
function Ryze:GetPathLength(nodes)
	local result = 0
	for i = 1, #nodes -1 do
		result = result + self:GetDistance(nodes[i], nodes[i + 1])
	end
	return result
end

function Ryze:GetDistanceSqr(p1, p2)
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function Ryze:GetDistance(p1, p2)
	return math.sqrt(self:GetDistanceSqr(p1, p2))
end


function Ryze:GetSpellInterceptTime(startPos, endPos, delay, speed)	
	local interceptTime = delay + self:GetDistance(startPos, endPos) / speed
	return interceptTime
end


function Ryze:TryGetBuff(unit, buffname)	
	for i = 1, unit.buffCount do 
		local Buff = unit:GetBuff(i)
		if Buff.name == buffname and Buff.duration > 0 then
			return Buff, true
		end
	end
	return nil, false
end


function Ryze:GetStasisTarget(source, range, delay, speed, timingAccuracy)
	local target	
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		local buff, success = self:TryGetBuff(t, "zhonyasringshield")
		if success and t.isEnemy and buff ~= nil then
			local deltaInterceptTime = self:GetSpellInterceptTime(myHero.pos, t.pos, delay, speed) - buff.duration
			if deltaInterceptTime > -Game.Latency() / 2000 and deltaInterceptTime < timingAccuracy then
				target = t
				return target
			end
		end
	end
end

function Ryze:GetImmobileTarget(source, range, minimumCCTime)
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

function Ryze:GetInteruptTarget(source, range, delay, speed, timingAccuracy)
	local target	
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
					return target
				end
			end			
		end
	end
end

function Ryze:CanAttack(target)
	return target.isEnemy and target.alive and target.visible and target.isTargetable and not target.isImmortal
end

function Ryze:GetTargetHitChance(target, delay, speed, width, range, collision, sort)
	local accuracy = 1	
	local aimPosition = self:PredictUnitPosition(target, delay + self:GetDistance(myHero.pos, target.pos) / speed)	
	local angletemp = Vector(myHero.pos):AngleBetween(Vector(target.pos), Vector(aimPosition))
	local interceptTime = self:GetSpellInterceptTime(myHero.pos, aimPosition, delay, speed)
	
	if angletemp > 60 then
		accuracy = 2
	end
		
	if target.aliveSpell and target.activeSpell.valid then
		accuracy = 2		
		local windupTimeRemaining = target.activeSpell.startTime + target.activeSpell.windup - Game.Timer()
		if windupTimeRemaining > .2 then
			accuracy = 3
		end
	end	
	
	
	local origin,radius = self:UnitMovementBounds(target, interceptTime, .25)
	if radius < width then
		accuracy = 3
	end
	
	if self:GetSlowedTime(target) >= interceptTime then
		accuracy = accuracy + 1
	end	
	
	if self:GetDistance(myHero.pos, aimPosition) < 400 then
		accuracy = accuracy + 1
	end
	
	if self:GetImmobileTime(target) >= interceptTime then
		accuracy = 5
	end
		
	--Check range
	if self:GetDistance(myHero.pos, aimPosition) >= range then
		accuracy = -1
	end
	
	--Check minion block
	if collision then
		if self:CheckMinionCollision(myHero, aimPosition, delay, width, range, speed, myHero.pos) then
			accuracy = -1
		end
	end
	
	return accuracy, aimPosition
end

function Ryze:VectorPointProjectionOnLineSegment(v1, v2, v)
	assert(v1 and v2 and v, "VectorPointProjectionOnLineSegment: wrong argument types (3 <Vector> expected)")
	local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
	local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
	local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
	local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	local isOnSegment = rS == rL
	local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
	return pointSegment, pointLine, isOnSegment
end

function Ryze:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw)
	if unit.networkID == minion.networkID then 
		return false
	end
	
	if from and minion and minion.pos and minion.type ~= myHero.type and _G.SDK.HealthPrediction:GetPrediction(minion, delay + self:GetDistance(from, minion.pos) / speed - Game.Latency()/1000) < 0 then
		return false
	end
	
	local waypoints = self:GetPathNodes(minion)
	local MPos, CastPosition = #waypoints == 1 and Vector(minion.pos) or self:PredictUnitPosition(minion, delay)
	
	if from and MPos and self:GetDistanceSqr(from, MPos) <= (range)^2 and self:GetDistanceSqr(from, minion.pos) <= (range + 100)^2 then
		local buffer = (#waypoints > 1) and 8 or 0 
		
		if minion.type == myHero.type then
			buffer = buffer + minion.boundingRadius
		end
		
		if #waypoints > 1 then
			local proj1, pointLine, isOnSegment = self:VectorPointProjectionOnLineSegment(from, Position, Vector(MPos))
			if proj1 and isOnSegment and (self:GetDistanceSqr(MPos, proj1) <= (minion.boundingRadius + radius + buffer) ^ 2) then				
				return true		
			end
		end
		
		local proj2, pointLine, isOnSegment = self:VectorPointProjectionOnLineSegment(from, Position, Vector(minion.pos))
		if proj2 and isOnSegment and (self:GetDistanceSqr(minion.pos, proj2) <= (minion.boundingRadius + radius + buffer) ^ 2) then
			return true
		end
	end
end

function Ryze:CheckMinionCollision(unit, Position, delay, radius, range, speed, from)
	if (not _G.SDK) then
		return false
	end
	Position = Vector(Position)
	from = from and Vector(from) or myHero.pos
	local result = false
	for i, minion in ipairs(_G.SDK.ObjectManager:GetEnemyMinions(range)) do
		if self:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
			return true
		end
	end
	for i, minion in ipairs(_G.SDK.ObjectManager:GetMonsters(range)) do
		if self:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
			return true
		end
	end
	for i, minion in ipairs(_G.SDK.ObjectManager:GetOtherEnemyMinions(range)) do
		if minion.team ~= myHero.team and self:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
			return true
		end
	end
	
	return false
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
