Q = {	Range = 950,	Radius = 80,	Delay = 0.25,	Speed = 1500,	Collision = true,	IsLine = true	}


function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({	id = "Q",	name = "[Q] Cosmic Binding",	type = MENU	})
	Menu.Skills.Q:MenuElement({	id = "Auto",	name = "Auto AA Reset",	value = true	})
	Menu.Skills.Q:MenuElement({	id = "Killsteal",	name = "Killsteal",	value = true	})
	Menu.Skills.Q:MenuElement({	id = "Accuracy",	name = "Combo Accuracy",	value = 2,	min = 1,	max = 6,	step = 1	})
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 1, max = 100, step = 1 })		
	_G.SDK.Orbwalker:OnPostAttack(function(args) OnPostAttack() end)
	
	Callback.Add("Tick", function() Tick() end)
end

function OnPostAttack()	
	if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and Menu.Skills.Q.Auto:Value() or ComboActive() then	
		local target = GetTarget(Q.Range)
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

local NextTick = LocalGameTimer()
function Tick()
	local currentTime = LocalGameTimer()
	if myHero.activeSpell and myHero.activeSpell.valid and not myHero.activeSpell.spellWasCast then return end	
	if NextTick > currentTime then return end
	NextTick = currentTime + .05
	if BlockSpells() then return end
		
	if Ready(_Q) then
		local target = GetTarget(Q.Range, true)
		if CanTarget(target) then			
			local thisDmg = LocalDamageManager:CalculateDamage(myHero, target, "BardQ")
			local accuracyRequired = Menu.Skills.Q.Killsteal:Value() and thisDmg >= target.health + target.hpRegen and 1 or ComboActive() and Menu.Skills.Q.Accuracy:Value() or 6
			if accuracyRequired < 6 then
				local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay,Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
				if aimPosition and hitChance >= accuracyRequired then
					CastSpell(HK_Q, aimPosition, true)
					NextTick = currentTime + .25	
					return
				end
			end
		end
	end	
end