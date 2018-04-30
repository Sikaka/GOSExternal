if not _G.Alpha then print("Alpha Library Must Be Loaded As An Active Script") return end

function Ready(spellSlot)
	return Game.CanUseSpell(spellSlot) == 0
end
	
function CurrentPctLife(entity)
	local pctLife =  entity.health/entity.maxHealth  * 100
	return pctLife
end

function CurrentPctMana(entity)
	local pctMana =  entity.mana/entity.maxMana * 100
	return pctMana
end

function EnemyCount(origin, range)
	local count = 0
	for i  = 1,LocalGameHeroCount(i) do
		local enemy = LocalGameHero(i)
		if enemy and  HPred:CanTarget(enemy) and _G.Alpha.Geometry:IsInRange(origin, enemy.pos, range) then
			count = count + 1
		end			
	end
	return count
end


Q = {	Range = 1175,	Width = 60,	Delay = 0.25,	Speed = 1200,	Collision = true	}
W = {	Range = 900,	Width = 325,	Delay = 0.25,	Speed = math.huge	}
E = {	Range = 800,	Delay = 0.25,	Speed = math.huge	}
R = {	Range = 625,	Delay = 0.25,	Speed = math.huge	}

Menu = MenuElement({type = MENU, id = myHero.networkID, name = "Morgana Test Script"})
Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
Menu.Skills:MenuElement({id = "Q", name = "[Q] Dark Binding", type = MENU})
--Prediction library is not yet part of alpha. Would have to rely on Hpred for it currently. lets leave it out for now.

Menu.Skills:MenuElement({id = "W", name = "[W] Tormented Soil", type = MENU})
Menu.Skills.W:MenuElement({id = "UseOnCC", name = "Auto Cast on CC", value = true, toggle = true})

Menu.Skills:MenuElement({id = "E", name = "[E] Black Shield", type = MENU})
Menu.Skills.E:MenuElement({id = "UseOnCC", name = "Auto Cast on CC", value = true, toggle = true})
Menu.Skills.E:MenuElement({id = "Targets", name = "Target Settings", type = MENU})
for i = 1, Game.HeroCount() do
	local hero = Game.Hero(i)
	if hero and hero.isAlly then
		Menu.Skills.E.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = 50, min = 1, max = 100, step = 5 })		
	end
end

Menu.Skills:MenuElement({id = "R", name = "[R] Soul Shackles", type = MENU})

_G.Alpha.DamageManager:OnIncomingCC(function(target, damage, ccType) OnIncomingCC(target, damage, ccType) end)


function OnIncomingCC(target, damage, ccType)
	--We would want a list of types of cc we want to use these on. Right now this will auto cast even if its just a silence.
	if target.isEnemy then
		if  Ready(_W) and Menu.Skills.W.UseOnCC:Value() and _G.Alpha.Geometry:IsInRange(myHero.pos, target.pos, W.Range) then
			Control.CastSpell(HK_W, target.pos)
		end
	end	
	if target.isAlly and Ready(_E) and Menu.Skills.E.Targets[target.networkID] and Menu.Skills.E.Targets[target.networkID]:Value() > CurrentPctLife(target) and _G.Alpha.Geometry:IsInRange(myHero.pos, target.pos, E.Range) then
		Control.CastSpell(HK_E, target.pos)
	end
end