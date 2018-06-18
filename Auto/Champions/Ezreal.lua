Q = {	Range = 1200,	Radius = 60,	Delay = 0.25,	Speed = 2000,	Collision = true,	IsLine = true	}
W = {	Range = 1050,	Radius = 50,	Delay = 0.25,	Speed = 1600,	IsLine = true	}
E = {	Range = 475,	Radius = 275,	Delay = 0.25,	Speed = 999999	}
R = {	Range = 20000,	Radius = 160,	Delay = 1,	Speed = 2000,	IsLine = true	}


function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({	id = "Q",	name = "[Q] Mystic Shot",	type = MENU	})
	Menu.Skills.Q:MenuElement({	id = "Auto",	name = "Auto AA Reset",	value = true	})
	Menu.Skills.Q:MenuElement({	id = "Killsteal",	name = "Killsteal",	value = true	})
	Menu.Skills.Q:MenuElement({	id = "AutoAccuracy",	name = "Auto Accuracy",	value = 3,	min = 1,	max = 6,	step = 1	})
	Menu.Skills.Q:MenuElement({	id = "Accuracy",	name = "Combo Accuracy",	value = 2,	min = 1,	max = 6,	step = 1	})
	Menu.Skills.Q:MenuElement({	id = "Farm",	name = "Use in Farm",	value = false	})
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 1, max = 100, step = 1 })
		
	Menu.Skills:MenuElement({	id = "W",	name = "[W] Essence Flux",	type = MENU	})
	Menu.Skills.W:MenuElement({	id = "Auto",	name = "Use after AA",	value = false	})
	Menu.Skills.W:MenuElement({	id = "Immobile",	name = "Auto cast on Immobile",	value = false	})
	Menu.Skills.W:MenuElement({	id = "Killsteal",	name = "Killsteal",	value = true	})
	Menu.Skills.W:MenuElement({	id = "Accuracy",	name = "Combo Accuracy",	value = 3,	min = 1,	max = 6,	step = 1	})
	Menu.Skills.W:MenuElement({id = "Mana", name = "Mana Limit", value = 30, min = 1, max = 100, step = 1 })
		
	Menu.Skills:MenuElement({id = "E",	name = "[E] Arcane Shift",	type = MENU})
	Menu.Skills.E:MenuElement({id = "EvadeCC",	name = "Auto Evade CC",	value = true	})
	Menu.Skills.E:MenuElement({id = "EvadeDanger",	name = "Combo Evade Danger Level",	value = 2,	min = 1,	max = 6,	step = 1	})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 20, min = 1, max = 100, step = 1 })	
		
	Menu.Skills:MenuElement({id = "R", name = "[R] Trueshot Barrage", type = MENU})
	Menu.Skills.R:MenuElement({id = "Count", name = "Combo Target Count", value = 3, min = 1, max = 6,	step = 1 })
	Menu.Skills.R:MenuElement({id = "Radius", name = "Combo Min Enemy Range", value = 700, min = 100, max = 2000,	step = 100 })
	Menu.Skills.R:MenuElement({id = "Assist", name = "Assist Key",value = false,  key = 0x73})
	
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	_G.SDK.Orbwalker:OnPostAttack(function(args) OnPostAttack() end)
	
	Callback.Add("Tick", function() Tick() end)
end

function OnPostAttack()
	--Check for E AA reset
	if not myHero.activeSpell.target then return end
	local target = LocalObjectManager:GetHeroByHandle(myHero.activeSpell.target)
	if not target then return end
	
	if Ready(_W) and not Ready(_Q) and Menu.Skills.W.Auto:Value() or ComboActive() then
		local target = GetTarget(W.Range)
		if CanTarget(target) then
			local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay, W.Speed, W.Radius, W.Collision, W.IsLine)
			if aimPosition and hitChance >= Menu.Skills.W.Accuracy:Value() then
				if CastSpell(HK_W, aimPosition, true) then
					return
				end
			end
		end
	end
	
	if Ready(_Q) and Menu.Skills.Q.Auto:Value() or ComboActive() then	
		local target = GetTarget(Q.Range, true)
		if CanTarget(target) then
			local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay,Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
			if aimPosition and hitChance >= Menu.Skills.Q.Accuracy:Value() then
				if CastSpell(HK_Q, aimPosition, true) then
					return
				end
			end
		end
	end
end

function OnSpellCast(spell)
	if spell.isEnemy and Ready(_E) then
		local hitDetails = LocalDamageManager:GetSpellHitDetails(spell,myHero)
		if hitDetails and hitDetails.Hit and hitDetails.Path then
			if Menu.Skills.E.EvadeCC:Value() and hitDetails.CC or hitDetails.Danger >= Menu.Skills.E.EvadeDanger:Value() and ComboActive() then
				local dashPos = myHero.pos + hitDetails.Path * E.Range
				CastSpell(HK_E, dashPos)
			end
		end
	end
end


local NextTick = LocalGameTimer()
function Tick()
	local currentTime = LocalGameTimer()
	if myHero.activeSpell and myHero.activeSpell.valid and not myHero.activeSpell.spellWasCast then return end	
	if NextTick > currentTime then return end
	if BlockSpells() then return end
	NextTick = currentTime + .05
	
	if Ready(_R) then
		if Menu.Skills.R.Assist:Value() then			
			local target = Menu.Skills.R.Assist:Value() and NearestEnemy(mousePos, 800) and GetTarget(R.Range)
			if CanTarget(target) then
				--get cast position and cast that shit				
				local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, R.Range, R.Delay,R.Speed, R.Radius, R.Collision, R.IsLine)
				if aimPosition and hitChance > 1 then
					if CastSpell(HK_R, aimPosition, true) then
						NextTick = currentTime + 1
						return
					end
				end
			end
		end
		if ComboActive() and EnemyCount(myHero.pos, Menu.Skills.R.Radius:Value(), R.Delay) == 0 then
			for i = 1, LocalGameHeroCount() do
				local hero = LocalGameHero(i)
				if CanTarget(hero) then
					local castPosition = LocalGeometry:PredictUnitPosition(hero, R.Delay + LocalGeometry:GetDistance(myHero.pos, hero.pos)/R.Speed)
					local endPosition = myHero.pos + (castPosition-myHero.pos):Normalized() * R.Range			
					local targetCount = LocalGeometry:GetLineTargetCount(myHero.pos, endPosition, R.Delay, R.Speed, R.Radius)
					if targetCount >= Menu.Skills.R.Count:Value() then
						if CastSpell(HK_R, castPosition, true) then
							NextTick = LocalGameTimer() + 1
							return
						end
					end
				end
			end
		end
		
	end
	
	if Ready(_Q) then
		local target = GetTarget(Q.Range, true)
		if CanTarget(target) then			
			local thisDmg = LocalDamageManager:CalculateDamage(myHero, target, "EzrealMysticShot")
			local accuracyRequired = Menu.Skills.Q.Killsteal:Value() and thisDmg >= target.health + target.hpRegen and 1 or ComboActive() and Menu.Skills.Q.Accuracy:Value() or Menu.Skills.Q.AutoAccuracy:Value()
			local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay,Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
			if aimPosition and hitChance >= accuracyRequired then
				CastSpell(HK_Q, aimPosition, true)
				NextTick = currentTime + .25	
				return
			end
		end
	end
	
	if Ready(_W) then
		local target = GetTarget(W.Range, true)
		if CanTarget(target) then			
			local thisDmg = LocalDamageManager:CalculateDamage(myHero, target, "EzrealEssenceFlux")
			local accuracyRequired = Menu.Skills.W.Killsteal:Value() and thisDmg >= target.health + target.hpRegen and 1 or ComboActive() and Menu.Skills.W.Accuracy:Value() or Menu.Skills.W.Immobile:Value() and 4 or 6
			local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay,W.Speed, W.Radius, W.Collision, W.IsLine)
			if aimPosition and hitChance >= accuracyRequired then
				CastSpell(HK_W, aimPosition, true)
				NextTick = currentTime + .25	
				return
			end
		end
	end
		
	if Ready(_Q) and FarmActive() and Menu.Skills.Q.Farm:Value() then
		for i = 1, LocalGameMinionCount() do
			local minion = LocalGameMinion(i)
			if CanTarget(minion) and LocalGeometry:IsInRange(myHero.pos, minion.pos, Q.Range) and not LocalGeometry:IsInRange(myHero.pos, minion.pos, myHero.range) then			
				local interceptTime = LocalGeometry:InterceptTime(myHero, minion, Q.Delay, Q.Speed)
				local predictedHealth = LocalHealthPrediction:GetPrediction(minion, interceptTime)
				local predictedDamage = LocalDamageManager:CalculateDamage(myHero, minion, "EzrealMysticShot")
				if predictedHealth > 0 and predictedDamage > predictedHealth then				
					local predictedPosition = LocalGeometry:PredictUnitPosition(minion, interceptTime)
					if CastSpell(HK_Q, predictedPosition, true) then					
						NextTick = currentTime + .25
						return
					end
				end
			end
		end
	end
end


function OnCC(target, damage, ccType, canDodge)
	if target == myHero then
		if canDodge and Menu.Skills.E.EvadeCC:Value() then
			CastSpell(HK_E, mousePos)
		end
	end
end