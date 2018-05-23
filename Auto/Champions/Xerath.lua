Q = {	Range = 750,	Delay = 0.35,	Speed = _huge,	Radius = 145	}
W = {	Range = 1050,	Delay = 0.5,	Speed = _huge,	Radius = 200	}
E = {	Range = 1050,	Delay = 0.25,	Speed = 2100,	Radius = 80, Collision = true,	IsLine = true	}
R = {	Range = 3520,	Delay = 0.5,	Speed = _huge,	Radius = 200	}
local LocalMathMin = math.min

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Arcanopulse", type = MENU})	
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Accuracy", value = 3, min = 1, max = 6, step = 1 })		
	Menu.Skills.Q:MenuElement({id = "Targets", name = "Target List", type = MENU})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.Q.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true, toggle = true})
		end
	end
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Eye of Destruction", type = MENU})
	Menu.Skills.W:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.W:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })	
	Menu.Skills.W:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
	
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Shocking Orb", type = MENU})
	Menu.Skills.E:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })	
	Menu.Skills.E:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
	
		
	Menu.Skills:MenuElement({id = "R", name = "[R] Rite of the Arcane", type = MENU})
	Menu.Skills.R:MenuElement({id = "Auto", name = "Auto Cast", value = true })
	Menu.Skills.W:MenuElement({id = "Accuracy", name = "Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.R:MenuElement({id = "Frequency", name = "Cast Speed", value = 1, min .25, max = 3, step = .25 })
	Menu.Skills.R:MenuElement({id = "Killsteal", name = "Killsteal", value = true })
	Menu.Skills.R:MenuElement({id = "Assist", name = "Assist Key",value = false,  key = 0x73})
	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)	
	Callback.Add("Tick", function() Tick() end)
end

local qStartTime = 0
function OnSpellCast(spell)
	if spell.owner == myHero.networkID and spell.data.name == "XerathArcanopulseChargeUp" then
		qStartTime = LocalGameTimer()
	end
end

function IsQCharging()
	return myHero.activeSpell and myHero.activeSpell.valid and myHero.activeSpell.name == "XerathArcanopulseChargeUp"
end

local NextTick = LocalGameTimer()
function Tick()
	if LocalGameIsChatOpen() then return end
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	NextTick = LocalGameTimer() + .1
	
	if IsQCharging() then
		local chargeTime = LocalMathMin(LocalGameTimer() - qStartTime, 2)
		local range = 750 + 500* chargeTime
		
		local targets = {}
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if CanTarget(hero) then
				local aimPosition = LocalGeometry:PredictUnitPosition(hero, Q.Delay)
				if LocalGeometry:IsInRange(myHero.pos, aimPosition, range - hero.boundingRadius) then
					CastSpell(HK_Q, aimPosition)
					return
				end
			end
		end
	end
	
	
end