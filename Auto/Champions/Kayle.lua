Q = {	Range = 650,	Delay = 0.25,	Speed = 1750,	SpellName = "JudicatorReckoning"	}
W = {	Range = 900,	Delay = 0.25	}
E = {	Range = 525,	Delay = 0.25	}
R = {	Range = 900,	Delay = 0.25	}
	

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({	id = "Skills",	name = "Skills", type = MENU})
	Menu.Skills:MenuElement({	id = "Q",	name = "[Q] Reckoning", type = MENU})	
	Menu.Skills.Q:MenuElement({	id = "Radius",	name = "Auto Peel Radius",	value = 0,	min = 0,	max = 650,	step = 1	})
	Menu.Skills.Q:MenuElement({	id = "Harass",	name = "Use in Harass",	value = true	})
	Menu.Skills.Q:MenuElement({	id = "Combo",	name = "Use in Combo",	value = true	})
	Menu.Skills.Q:MenuElement({	id = "Killsteal",	name = "Killsteal",	value = true,	toggle = true	})
	Menu.Skills.Q:MenuElement({	id = "Mana",	name = "Minimum Mana",	value = 20,	min = 1,	max = 100	})
		
	Menu.Skills:MenuElement({	id = "W",	name = "[W] Divine Blessing",	type = MENU	})
	Menu.Skills.W:MenuElement({id = "Auto", name = "Cast Automatically (No Combo)", value = true, toggle = true })
	Menu.Skills.W:MenuElement({	id = "Targets",	name = "Target Settings",	type = MENU	})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isAlly then
			Menu.Skills.W.Targets:MenuElement({	id = hero.networkID,	name = hero.charName,	value = hero.isMe and 50 or 10,	min = 1,	max = 100,	step = 1	})
		end
	end
	Menu.Skills.W:MenuElement({id = "Mana", name = "Mana Limit", value = 20, min = 5, max = 100, step = 5 })
		
		
	Menu.Skills:MenuElement({id = "E", name = "[E] Righteous Fury", type = MENU})	
	Menu.Skills.E:MenuElement({	id = "Harass",	name = "Use in Harass",	value = true	})
	Menu.Skills.E:MenuElement({	id = "Combo",	name = "Use in Combo",	value = true	})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Minimum Mana", value = 15, min = 1, max = 100, step = 1 })
		
		
	Menu.Skills:MenuElement({id = "R", name = "[R] Intervention", type = MENU})
	Menu.Skills.R:MenuElement({id = "Auto", name = "Cast Automatically (No Combo)", value = true, toggle = true })
	Menu.Skills.R:MenuElement({id = "Targets", name = "Target Settings", type = MENU})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isAlly then
			Menu.Skills.R.Targets:MenuElement({	id = hero.networkID,	name = hero.charName,	value = hero.isMe and 30 or 10,	min = 1,	max = 100,	step = 1	})
		end
	end	
	Menu.Skills.R:MenuElement({	id = "TargetCC",	name = "Incoming CC Target Settings",	type = MENU	})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isAlly then
			Menu.Skills.R.TargetCC:MenuElement({	id = hero.networkID,	name = hero.charName,	value = hero.isMe and 75 or 50,	min = 1,	max = 100,	step = 1	})
		end
	end
	Menu.Skills.R:MenuElement({	id = "Gapcloser",	name = "Anti Gapcloser Settings",	type = MENU	})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.R.Gapcloser:MenuElement({	id = hero.networkID,	name = hero.charName,	value = false	})
		end
	end
	Menu.Skills.R:MenuElement({id = "Damage", name = "Minimum Incoming Dmg%", value = 10, min = 1, max = 50, step = 1 })
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	Callback.Add("Tick", function() Tick() end)
end


local NextTick = LocalGameTimer()
function Tick()
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	if BlockSpells() then return end
	if Ready(_R) then
		if ComboActive() or Menu.Skills.R.Auto:Value() then
			for i = 1, LocalGameHeroCount() do
				local hero = LocalGameHero(i)				
				if hero and hero.isAlly and LocalGeometry:IsInRange(myHero.pos, hero.pos, R.Range) and Menu.Skills.R.Targets[hero.networkID] then
					local incomingDamage = LocalDamageManager:RecordedIncomingDamage(hero)
					local remainingLifePct = (hero.health - incomingDamage) / hero.maxHealth * 100
					if Menu.Skills.R.Targets[hero.networkID]:Value() >= remainingLifePct and (incomingDamage > hero.health or GetTarget(1500) ~= nil and incomingDamage / hero.health * 100 > Menu.Skills.R.Damage:Value()) then
						NextTick = LocalGameTimer() + .25
						CastSpell(HK_R, hero)
						return
					end
				elseif CanTarget(hero) and hero.pathing.hasMovePath and hero.pathing.isDashing and Menu.Skills.R.Gapcloser[hero.networkID] and Menu.Skills.R.Gapcloser[hero.networkID]:Value() then
					local endPos = hero:GetPath(1)
					local ally = NearestAlly(endPos, 200)
					if ally and LocalGeometry:IsInRange(myHero.pos, ally.pos, R.Range) then
						NextTick = LocalGameTimer() + .25
						CastSpell(HK_R, ally)
						return
					end
				end
			end
		end
	end
	
	if Ready(_W) then
		if ComboActive() or Menu.Skills.W.Auto:Value() and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() then
			for i = 1, LocalGameHeroCount() do
				local hero = LocalGameHero(i)				
				if hero and hero.isAlly and LocalGeometry:IsInRange(myHero.pos, hero.pos, W.Range) and Menu.Skills.W.Targets[hero.networkID] then
					local incomingDamage = LocalDamageManager:RecordedIncomingDamage(hero)
					local remainingLifePct = (hero.health - incomingDamage) / hero.maxHealth * 100
					if Menu.Skills.W.Targets[hero.networkID]:Value() >= remainingLifePct and incomingDamage > hero.hpRegen then
						NextTick = LocalGameTimer() + .25
						CastSpell(HK_W, hero)
						return
					end
				end
			end
		end
	end
			
	if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() then
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)				
			if CanTarget(hero) and LocalGeometry:IsInRange(myHero.pos, hero.pos, Q.Range) then
				
				--Killsteal checks
				if Menu.Skills.Q.Killsteal:Value() then
					local thisDmg = LocalDamageManager:CalculateSkillDamage(myHero, hero, Q.SpellName)
					local incomingDmg =LocalDamageManager:RecordedIncomingDamage(hero)					
					if hero.health > incomingDmg and thisDmg + incomingDmg > hero.health + hero.hpRegen then
						NextTick = LocalGameTimer() + .25
						CastSpell(HK_Q, hero)
						return
					end
				end
				
				--Peel radius
				if LocalGeometry:GetDistance(myHero.pos, hero.pos) < Menu.Skills.Q.Radius:Value() then
					NextTick = LocalGameTimer() + .25
					CastSpell(HK_Q, hero)
					return
				end
			end
		end
		if ComboActive() and Menu.Skills.Q.Combo:Value() or HarassActive() and Menu.Skills.Q.Harass:Value() then
			local target = GetTarget(Q.Range)
			if CanTarget(target) then
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_Q, target)
			end
		end		
	end
	
	if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() then
		if ComboActive() and Menu.Skills.E.Combo:Value() or HarassActive() and Menu.Skills.E.Harass:Value() then
			local target = GetTarget(E.Range)
			if CanTarget(target) then
				CastSpell(HK_E)
			end
		end
	end
	
	NextTick = LocalGameTimer() + .05
end



function OnCC(target, damage, ccType)
	if target.isAlly and LocalDamageManager.IMMOBILE_TYPES[ccType]  and Ready(_R) and LocalGeometry:IsInRange(myHero.pos, target.pos, R.Range) and Menu.Skills.R.TargetCC[target.networkID] then
		local incomingDamage = LocalDamageManager:RecordedIncomingDamage(target)
		local remainingLifePct = (target.health - incomingDamage) / target.maxHealth * 100
		if Menu.Skills.R.TargetCC[target.networkID]:Value() >= remainingLifePct then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_R, target)
			return
		end
	end
end