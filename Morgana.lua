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


Q = {	Range = 1175,	Radius = 60,	Delay = 0.25,	Speed = 1200,	Collision = true	}
W = {	Range = 900,	Radius = 325,	Delay = 0.25,	Speed = math.huge	}
E = {	Range = 800,	Delay = 0.25,	Speed = math.huge	}
R = {	Range = 625,	Delay = 0.25,	Speed = math.huge	}

Menu = MenuElement({type = MENU, id = myHero.networkID, name = "Morgana Test Script"})
Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
Menu.Skills:MenuElement({id = "Q", name = "[Q] Dark Binding", type = MENU})
Menu.Skills.Q:MenuElement({id = "UseOnBlinks", name = "Auto Cast on Flash", value = true, toggle = true})
Menu.Skills.Q:MenuElement({id = "UseOnCC", name = "Auto Cast on CC", value = true, toggle = true})
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

	print ()

Menu.Skills:MenuElement({id = "R", name = "[R] Soul Shackles", type = MENU})

_G.Alpha.ObjectManager:OnBlink(function(target) 
	if target.isEnemy and Ready(_Q) and Menu.Skills.Q.UseOnBlinks:Value() and _G.Alpha.Geometry:IsInRange(myHero.pos, target.pos, Q.Range) then
		local castPosition, accuracy = _G.Alpha.Geometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision)
		if accuracy > 0 then
			Control.CastSpell(HK_Q, target.pos)
		end	
	end
end)

_G.Alpha.DamageManager:OnIncomingCC(function(target, damage, ccType)
	--Only auto cast if the CC type is something that will immobilize the target. Later I would suggest just using a hitchance calc for prediction so we can target things like fear/charm/slow/etc
	if target.isEnemy and _G.Alpha.DamageManager.IMMOBILE_TYPES[ccType] then
		if Ready(_Q) and Menu.Skills.Q.UseOnCC:Value() and _G.Alpha.Geometry:IsInRange(myHero.pos, target.pos, Q.Range) then
			local castPosition, accuracy = _G.Alpha.Geometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision)
			if accuracy > 0 then
				Control.CastSpell(HK_Q, target.pos)
			end
		end
		if  Ready(_W) and Menu.Skills.W.UseOnCC:Value() and _G.Alpha.Geometry:IsInRange(myHero.pos, target.pos, W.Range) then
			Control.CastSpell(HK_W, target.pos)
		end
	end
	
	--Calculate the damage they would be AFTER the spell hits instead
	--TODO: Send total incoming damage so we can make better decisions about to evade/shield or not
	if target.isAlly and Ready(_E) and Menu.Skills.E.Targets[target.networkID] and Menu.Skills.E.Targets[target.networkID]:Value() > (target.health-damage)/target.maxHealth  * 100 and _G.Alpha.Geometry:IsInRange(myHero.pos, target.pos, E.Range) then
		Control.CastSpell(HK_E, target.pos)
	end
 end)