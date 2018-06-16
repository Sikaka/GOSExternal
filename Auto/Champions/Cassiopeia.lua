Q = {Range = 850, Radius = 150,Delay = 0.4, Speed = 999999}
W = {Range = 800, Radius = 150,Delay = 0.25, Speed = 999999}
E = {Range = 690, Delay = 0.125, Speed = 2500, SpellName = "CassiopeiaE" }
R = {Range = 750,Delay = 0.5, Angle = 80}

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Noxious Blast", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast On Immobile", value = true})
	Menu.Skills.Q:MenuElement({id = "AccuracyAuto", name = "Auto Accuracy", value = 4, min = 1, max = 6, step = 1})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1})
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Miasma", type = MENU})
	Menu.Skills.W:MenuElement({id = "Auto", name = "Auto Cast On Immobile", value = true})
	Menu.Skills.W:MenuElement({id = "Count", name = "Auto Cast On Target #", value = 2, min = 1, max = 6, step = 1})
	Menu.Skills.W:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1})
	Menu.Skills.W:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Twin Fang", type = MENU})
	Menu.Skills.E:MenuElement({id = "Poison", name = "Only cast on poisoned enemies", value = false})
	Menu.Skills.E:MenuElement({id = "FarmPoison", name = "Only cast on poisoned minions", value = false, toggle = true})
	Menu.Skills.E:MenuElement({id = "Farm", name = "E Last Hit (Toggle)", value = false, toggle = true, key = 0x72})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Petrifying Gaze", type = MENU})
	Menu.Skills.R:MenuElement({id = "Assist", name = "Manual Ult Key",value = false,  key = 0x73})	
	Menu.Skills.R:MenuElement({id = "Targets", name = "Stun Targets", type = MENU})	
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.R.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = false })
		end
	end
	Menu.Skills.R:MenuElement({id = "Auto", name = "Auto Ult", value = false})
	Menu.Skills.R:MenuElement({id = "Count", name = "Ult on # of enemies", value = 2, min = 1, max = 6, step = 1 })	
	
	Menu.Skills:MenuElement({id = "AA", name = "Use Auto Attacks In Combo", value = true})
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType, canDodge) OnCC(target, damage, ccType, canDodge) end)	
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	
	
	Callback.Add("Tick", function() Tick() end)	
end

local qTime
local qPos
function OnSpellCast(spell)
	if spell.owner == myHero.networkID and spell.data.name == "CassiopeiaQ" then
		qTime = LocalGameTimer() + Q.Delay
		qPos = Vector(spell.data.placementPos.x, spell.data.placementPos.y,spell.data.placementPos.z)
	end
end

local _nextTick = LocalGameTimer()
function Tick()
	if BlockSpells() then return end
	local currrentTime = LocalGameTimer()
	local attacks = not ComboActive() or Menu.Skills.AA:Value() or  CurrentPctMana(myHero) < 15
	EnableOrbAttacks(attacks)
	if _nextTick > currrentTime then  return end
	if myHero.activeSpell and myHero.activeSpell.valid and not myHero.activeSpell.spellWasCast then return end

	_nextTick = currrentTime + .05
	local myMana = CurrentPctMana(myHero)
	
	if Ready(_R) then
		--Average out the position of all enemies nearby to get cast direction
		if Menu.Skills.R.Assist:Value() then
			local castPosition, targets, stuns = GetRCastDetails()
			if castPosition and targets > 0 then
				CastSpell(HK_R, castPosition)
				_nextTick = currrentTime + .25
				return
			end
		end
		if Menu.Skills.R.Auto:Value() or ComboActive() then
			local castPosition, targets, stuns = GetRCastDetails()
			if castPosition and 
				(targets >= Menu.Skills.R.Count:Value() or stuns > 0 and ComboActive()) then
				CastSpell(HK_R, castPosition)
				_nextTick = currrentTime + .25
				return
			end
		end
	end
	
	local target = GetTarget(Q.Range)
	if target and Ready(_Q) and myMana >= Menu.Skills.Q.Mana:Value() then
		local accuracyRequired = ComboActive() and Menu.Skills.Q.Accuracy:Value() or Menu.Skills.Q.AccuracyAuto:Value() 
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
		if castPosition and accuracy >= accuracyRequired and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
			CastSpell(HK_Q, castPosition)
			_nextTick = currrentTime + .25
		end
	end
	
	target = GetTarget(E.Range)
	
	if not ComboActive() then
		if (FarmActive() or Menu.Skills.E.Farm:Value()) and Ready(_E) and myMana >= Menu.Skills.E.Mana:Value() then	
			for i = 1, LocalGameMinionCount() do
				local minion = LocalGameMinion(i)
				if CanTarget(minion) and LocalGeometry:IsInRange(myHero.pos, minion.pos, E.Range) then
				
				
					local predictedHealth = _G.SDK.HealthPrediction:GetPrediction(minion, LocalGeometry:InterceptTime(myHero, minion, E.Delay, E.Speed))
					local predictedDamage = LocalDamageManager:CalculateDamage(myHero, minion, E.SpellName)
					if predictedHealth > 0 and predictedDamage > predictedHealth then
						CastSpell(HK_E, minion)
						_nextTick = currrentTime + .15
						break
					end
				end
			end
		end
	end
	if CanTarget(target) and Ready(_E) and myMana >= Menu.Skills.E.Mana:Value() then
		if qTime and qTime > currrentTime and currrentTime > qTime - .25 then
			local predictedPosition = LocalGeometry:PredictUnitPosition(target, qTime - currrentTime)
			if LocalGeometry:IsInRange(qPos, predictedPosition, Q.Radius) then
				CastSpell(HK_E, target)
				_nextTick = currrentTime + .15
			end
		end
		if ComboActive() or HarassActive() then
			if IsTargetPoisoned(target) or not Menu.Skills.E.Poison:Value() and ComboActive() then
				CastSpell(HK_E, target)
				_nextTick = currrentTime + .15
			end
		end
	end
	
	if Ready(_W) then
		local accuracyRequired = ComboActive() and Menu.Skills.W.Accuracy:Value() or Menu.Skills.W.Auto:Value() and 4
		
		local aimPosition = Vector()
		local aimCount = 0
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if CanTarget(hero) then
				local predictedPosition = LocalGeometry:PredictUnitPosition(hero, W.Delay)
				if LocalGeometry:IsInRange(myHero.pos, predictedPosition, W.Range) and not LocalGeometry:IsInRange(myHero.pos, predictedPosition, 500) then
					aimPosition = aimPosition + predictedPosition
					aimCount = aimCount + 1
					
					if Menu.Skills.W.Auto:Value() then					
						local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, hero, W.Range, W.Delay, W.Speed, W.Radius, W.Collision, W.IsLine)
						if LocalGeometry:IsInRange(myHero.pos, castPosition, W.Range) and not LocalGeometry:IsInRange(myHero.pos, castPosition, 500) and accuracy > 3 then
							CastSpell(HK_W, castPosition)
							_nextTick = currrentTime + .15
							break
						end
					end
				end
			end
		end
		
		aimPosition = aimPosition / aimCount
		local directionVector = (aimPosition - myHero.pos):Normalized():Perpendicular()
		local p1 = aimPosition - directionVector * 300		
		local p2 = aimPosition + directionVector * 300
		local hitCount = LocalGeometry:GetLineTargetCount(p1, p2, W.Delay, W.Speed, W.Radius)
		
		if hitCount >= Menu.Skills.W.Count:Value() then
			CastSpell(HK_W, aimPosition)
			_nextTick = LocalGameTimer() + .15
		end		
	end
	
end


function GetRCastDetails()
	local aimPosition = Vector()
	local aimCount = 0
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if CanTarget(hero) then
			local predictedPosition = LocalGeometry:PredictUnitPosition(hero, R.Delay)
			if LocalGeometry:IsInRange(myHero.pos, predictedPosition, R.Range) then
				aimPosition = aimPosition + predictedPosition
				aimCount = aimCount + 1
			end
		end
	end		
	aimPosition = aimPosition / aimCount
	
	--Now we loop through adjacent angles to get the best target/stun count
	local castOffset = (aimPosition - myHero.pos):Normalized()		
	local targetCount = 0
	local stunCount = 0
	for i = -60, 60, 10 do
		local castDir = castOffset:Rotated(0,i,0)
		local castTargets, castStuns = PredictRTargets(castDir)
		if castStuns > stunCount or castTargets > targetCount then
			--New best score. Save it
			aimPosition = myHero.pos + castDir * 600
			targetCount = castTargets
			stunCount = castStuns
		end
	end
	
	return aimPosition, targetCount, stunCount
end
function PredictRTargets(directionVector)	
	local hitCount = 0
	local stunCount = 0
	local castPos = myHero.pos + directionVector * R.Range
	local castAngle = LocalGeometry:Angle(myHero.pos, castPos)
	for i = 1, LocalGameHeroCount() do
		local target = LocalGameHero(i)
		if target and CanTarget(target) then
			local predictedPosition = LocalGeometry:PredictUnitPosition(target, R.Delay)
			if LocalGeometry:IsInRange(myHero.pos, predictedPosition, R.Range) then
				local deltaAngle = LocalMathAbs(LocalGeometry:Angle(myHero.pos, predictedPosition) - castAngle)
				if deltaAngle <= 37 then
					hitCount = hitCount + 1
					--Count the stuns on targets we've selected as priority only.
					if Menu.Skills.R.Targets[target.networkID] and Menu.Skills.R.Targets[target.networkID]:Value() then
						local dot = (myHero.pos-predictedPosition):Normalized():DotProduct(target.dir)
						if dot > .1 then
							stunCount = stunCount + 1
						end
					end
				end
			end
		end
	end
	return hitCount, stunCount
end


function IsTargetPoisoned(target, duration)
	if not duration then
		duration = 0
	end
	for i = 1, target.buffCount do 
		local buff = target:GetBuff(i)
		if buff.duration > duration and buff.type == 23 then
			return true
		end
	end
end


function OnCC(target, damage, ccType, canDodge)
	if target.isEnemy and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then	
		if Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() and Menu.Skills.W.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, W.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_W, target.pos)
			return
		end
		if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_Q, target.pos)
			return
		end
	end
end