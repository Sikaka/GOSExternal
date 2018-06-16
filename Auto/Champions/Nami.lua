Q = {	Range = 875,	Radius = 200,	Delay = 0.95,	Speed = 99999	}
W = {	Range = 725,	Radius = 650,	Delay = 0.25	}
E = {	Range = 800	}
R = {	Range = 2750,	Radius = 215,	Speed = 850,	Delay = 0.5	}
	

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Aqua Prison", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })	
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto cast on Immobile", value = true, toggle = true })	
	Menu.Skills.Q:MenuElement({id = "Count", name = "Auto cast on # Enemies", tooltip = "How many targets we need to be able to hit to auto cast", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Minimum Mana", value = 15, min = 1, max = 100, step = 1 })
	Menu.Skills.Q:MenuElement({id = "Assist", name = "Assist Key",value = false,  key = 0x70})
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Ebb and Flow", type = MENU})
	Menu.Skills.W:MenuElement({id = "BounceTargets", name = "Target Settings [Bounce]", type = MENU})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isAlly then
			Menu.Skills.W.BounceTargets:MenuElement({id = hero.networkID, name = hero.charName, value = 65, min = 1, max = 100, step = 5 })		
		end
	end	
	Menu.Skills.W:MenuElement({id = "BounceMana", name = "Minimum Mana [Bounce]", value = 25, min = 1, max = 100, step = 5 })
	
	Menu.Skills.W:MenuElement({id = "EmergencyTargets", name = "Target Settings [No Bounce]", type = MENU})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isAlly then
			Menu.Skills.W.EmergencyTargets:MenuElement({id = hero.networkID, name = hero.charName, value = 30, min = 1, max = 100, step = 5 })		
		end
	end	
	Menu.Skills.W:MenuElement({id = "EmergencyMana", name = "Minimum Mana [No Bounce]", value = 25, min = 1, max = 100, step = 5 })
	
		
	Menu.Skills:MenuElement({id = "E", name = "[E] Tidecaller's Blessing", type = MENU})
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Buff Allies", value = true, toggle = true })	
	Menu.Skills.E:MenuElement({id = "Targets", name = "Targets", type = MENU})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isAlly  then
			Menu.Skills.E.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = hero.isMe and false or true})
		end
	end	
	Menu.Skills.E:MenuElement({id = "Mana", name = "Minimum Mana", value = 25, min = 1, max = 100, step = 5 })
		
	Menu.Skills:MenuElement({id = "R", name = "[R] Tidal Wave", type = MENU})
	Menu.Skills.R:MenuElement({id = "Count", name = "Combo Target Count", tooltip = "How many targets we need to be able to hit to auto cast", value = 2, min = 1, max = 6, step = 1 })
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	LocalObjectManager:OnBlink(function(target) OnBlink(target) end )
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	Callback.Add("Tick", function() Tick() end)
end

function OnSpellCast(spell)
	if  not spell.isEnemy and Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() and Menu.Skills.E.Auto:Value() then
		local owner = LocalObjectManager:GetHeroByID(spell.owner)
		local target = LocalObjectManager:GetHeroByHandle(spell.data.target)
		if owner and target and LocalGeometry:IsInRange(myHero.pos, owner.pos, E.Range) and Menu.Skills.E.Targets[owner.networkID] and Menu.Skills.E.Targets[owner.networkID]:Value() then		
			CastSpell(HK_E, owner)
		end
	end
end


local NextTick = LocalGameTimer()
function Tick()
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	NextTick = LocalGameTimer() + .1
	if BlockSpells() then return end
	local currentMana = CurrentPctMana(myHero)
	
	--Get R target info
	if ComboActive() and Ready(_R) then
		local target = GetTarget(R.Range)
		if CanTarget(target) then
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, R.Range, R.Delay, R.Speed, R.Radius, R.Collision, R.IsLine)
			if castPosition and accuracy > 1 and LocalGeometry:GetLineTargetCount(myHero.pos, castPosition, R.Delay, R.Speed, R.Radius) >= Menu.Skills.R.Count:Value() then
				CastSpell(HK_R, castPosition)			
			end
		end
	end
	
	if Ready(_Q) then
		local target = GetTarget(Q.Range)
		if CanTarget(target) then
			local accuracyRequired = (ComboActive() or Menu.Skills.Q.Assist:Value()) and Menu.Skills.Q.Accuracy:Value() or Menu.Skills.Q.Auto:Value() and 4 or 6
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
			local hitCount = EnemyCount(castPosition, Q.Radius, LocalGeometry:GetSpellInterceptTime(myHero.pos, castPosition, Q.Delay, Q.Speed))
			if hitCount >= Menu.Skills.Q.Count:Value() then
				accuracyRequired = 3
			end
			if castPosition and accuracy >= accuracyRequired and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
				NextTick = LocalGameTimer() + .25
				if CastSpell(HK_Q, castPosition) then
					return
				end
			end
		end
	end
	
	if Ready(_W) then
		--Check all targets in range if they need to be healed
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if CanTargetAlly(hero) and LocalGeometry:IsInRange(myHero.pos, hero.pos, W.Range) then
				local incomingDamage = LocalDamageManager:RecordedIncomingDamage(hero)
				local remainingLifePct = (hero.health - incomingDamage) / hero.maxHealth * 100
				if Menu.Skills.W.EmergencyTargets[hero.networkID]:Value() >= remainingLifePct and currentMana >= Menu.Skills.W.EmergencyMana:Value() then
					CastSpell(HK_W, hero)
					NextTick = LocalGameTimer() + .25
					return
				end
				if Menu.Skills.W.BounceTargets[hero.networkID]:Value() >= remainingLifePct and currentMana >= Menu.Skills.W.BounceMana:Value() and EnemyCount(hero.pos, W.Radius, W.Delay) > 0 then
					CastSpell(HK_W, hero)
					NextTick = LocalGameTimer() + .25
					return
				end
			end
		end
	end
end



function OnBlink(target)
	if target.isEnemy and CanTarget(target) and Ready(_Q) and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision)
		if accuracy > 0 then
			CastSpell(HK_Q, castPosition)
		end	
	end
end

function OnCC(target, damage, ccType)		
	if target.isEnemy and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then
		if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_Q, target.pos)
			return
		end
	end
end