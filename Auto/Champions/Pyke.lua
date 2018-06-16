Q = {	Range = 650,	Delay = 0.25,	Speed = 2000,	Radius = 70,	IsLine = true, Collision = true	}
W = {	Range = 900,	Delay = 0.25	}
E = {	Range = 525,	Delay = 0.25,	Speed = 1700,	Radius = 150	}
R = {	Range = 900,	Radius = 250,	Delay = 0.25,	Speed = 90000,	SpellName = "PykeR"	}
	

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({	id = "Skills",	name = "Skills", type = MENU})
	Menu.Skills:MenuElement({	id = "Q",	name = "[Q] Bone Skewer", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Targets", name = "Pull Targets", type = MENU})	
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.Q.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true })
		end
	end
	Menu.Skills.Q:MenuElement({id = "Combo", name = "Use in Combo", value = true	})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Pull", value = true	})
	Menu.Skills.Q:MenuElement({	id = "Mana",	name = "Minimum Mana",	value = 20,	min = 1,	max = 100	})
		
	Menu.Skills:MenuElement({	id = "W",	name = "[W] Ghostwater Dive",	type = MENU	})
	Menu.Skills.W:MenuElement({id = "Evade", name = "Use on Incoming CC", value = true })
	Menu.Skills.W:MenuElement({id = "Combo", name = "Gapclose in Combo", value = true })
	Menu.Skills.W:MenuElement({id = "Mana", name = "Mana Limit", value = 20, min = 5, max = 100, step = 5 })
		
		
	Menu.Skills:MenuElement({id = "E", name = "[E] Phantom Undertow", type = MENU})
	Menu.Skills.E:MenuElement({id = "Count", name = "Use to hit # enemies (Combo)", value = 2, min = 1, max = 6, step = 1 })
	Menu.Skills.E:MenuElement({id = "Auto", name = "Hit Immobile Targets", value = true	})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 20, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Death from Below", type = MENU})
	Menu.Skills.R:MenuElement({id = "Count", name = "Use to hit # enemies (Combo)", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.R:MenuElement({id = "Killsteal", name = "Killsteal", value = true })
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	Callback.Add("Tick", function() Tick() end)
end

local QStartTime = 0
local RTarget = nil
local RCastTime = LocalGameTimer()
function OnSpellCast(spell)
	if spell.owner == myHero.networkID then
		if spell.name == "PykeQ" then
			QStartTime = LocalGameTimer()
		end
	end
end

local NextTick = LocalGameTimer()
function Tick()	
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	if BlockSpells() then return end
	
	if Ready(_Q) then	
		if myHero.activeSpell.valid and myHero.activeSpell.name == "PykeQ" then
			local qChargeDuration = LocalGameTimer() - QStartTime
			if qChargeDuration > 3 then return end
			
			if ComboActive() or Menu.Skills.Q.Auto:Value() then
				local range = LocalMathMax(LocalMathMin(qChargeDuration, 1.25) * 880, 400)
				if range > 400 then
					for i = 1, LocalGameHeroCount() do
						local hero = LocalGameHero(i)
						if CanTarget(hero) and Menu.Skills.Q.Targets[hero.networkID] and Menu.Skills.Q.Targets[hero.networkID]:Value() and LocalGeometry:IsInRange(myHero.pos, hero.pos, range) then				
							local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, hero, range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
							if castPosition and accuracy > 0 then
								NextTick = LocalGameTimer() + .25
								CastSpell(HK_Q, castPosition)
								break
							end
						end
					end
				else
					local target = GetTarget(Q.Range)
					if CanTarget(target) and Menu.Skills.Q.Targets[target.networkID] and not Menu.Skills.Q.Targets[target.networkID]:Value() then
						local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, false, Q.IsLine)
						if castPosition and accuracy > 0 then
							NextTick = LocalGameTimer() + .25
							CastSpell(HK_Q, castPosition)
						end
					end
					
				end
			end
		elseif ComboActive() then
			local target = GetTarget(Q.Range)
			if CanTarget(target) then				
				Control.KeyDown(HK_Q)
			end
		end
	end
	
	if myHero.activeSpell.valid and myHero.activeSpell.name == "PykeQ" then
		return 
	end
	if Ready(_W) and ComboActive() and Menu.Skills.W.Combo:Value() then
		local target, distance = NearestEnemy(myHero.pos, 1500)
		if target and distance > 500 then
			CastSpell(HK_W)
			NextTick = LocalGameTimer() + .25
		end
	end
	
	
	if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() then
		if Menu.Skills.E.Auto:Value() or ComboActive() then
			for i = 1, LocalGameHeroCount() do
				local hero = LocalGameHero(i)
				if CanTarget(hero) then		
					local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, hero, E.Range, E.Delay, E.Speed, E.Radius, E.Collision, E.IsLine)
					if castPosition and accuracy > 3 and Menu.Skills.E.Auto:Value() then 
						NextTick = LocalGameTimer() + .25
						CastSpell(HK_E, castPosition)
						break
					end
				end
			end
		end
	end
	
	local target = GetTarget(E.Range, true)
	if Ready(_E) and CanTarget(target) and ComboActive() and not myHero.activeSpell.valid then
		local castPosition = LocalGeometry:PredictUnitPosition(target, E.Delay + LocalGeometry:GetDistance(myHero.pos, target.pos)/E.Speed)
		if LocalGeometry:IsInRange(myHero.pos, castPosition, E.Range) then
			local endPosition = myHero.pos + (castPosition-myHero.pos):Normalized() * E.Range
			local targetCount = LocalGeometry:GetLineTargetCount(myHero.pos, endPosition, E.Delay, E.Speed, E.Radius)
			if targetCount >= Menu.Skills.E.Count:Value() then
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_E, castPosition)
				return
			end
		end
	end	
	
	if Ready(_R) then
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if CanTarget(hero) and LocalGeometry:IsInRange(myHero.pos, hero.pos, R.Range) then
				local castPosition = LocalGeometry:PredictUnitPosition(hero, R.Delay)
				if Menu.Skills.R.Killsteal:Value() then				
					if RTarget == hero and LocalGameTimer() - RCastTime < 2 then return end			
					local thisDmg = LocalDamageManager:CalculateDamage(myHero, hero, R.SpellName)
					if thisDmg > hero.health + hero.hpRegen then
						if LocalGeometry:IsInRange(myHero.pos, castPosition, R.Range) then
							NextTick = LocalGameTimer() + .25
							CastSpell(HK_R, castPosition)
							RTarget = hero
							RCastTime = LocalGameTimer()
							return
						end
					end
				end	
				if ComboActive() then
					local hitCount = EnemyCount(castPosition, R.Radius, R.Delay)
					if hitCount >= Menu.Skills.R.Count:Value() then
						NextTick = LocalGameTimer() + .25
						CastSpell(HK_R, castPosition)
						return
					end
				end
				
			end
		end
	end
	
	
	NextTick = LocalGameTimer() + .05
end

function OnCC(target, damage, ccType)
end