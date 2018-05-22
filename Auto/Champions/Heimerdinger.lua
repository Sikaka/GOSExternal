Q = {Range = 350}
W = {Range = 1300, Radius = 85,Delay = .75, Speed = 99999 }

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Lunge", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Hit Vitals", value = true})
	Menu.Skills.Q:MenuElement({id = "DodgeAuto", name = "Dodge Danger Level (Auto)", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.Q:MenuElement({id = "DodgeCombo", name = "Dodge Danger Level (Combo) ", value = 2, min = 1, max = 6, step = 1 })
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Riposte", type = MENU})
	Menu.Skills.W:MenuElement({id = "Auto", name = "Auto Reflect", value = true})
	Menu.Skills.W:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Bladework", type = MENU})
	Menu.Skills.E:MenuElement({id = "Auto", name = "AA Reset", value = true})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })		
	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType, canDodge) OnCC(target, damage, ccType, canDodge) end)
	Callback.Add("Tick", function() Tick() end)	
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
end


function OnSpellCast(spell)
	if spell.isEnemy then
		local hitDetails = LocalDamageManager:GetSpellHitDetails(spell,myHero)
		if hitDetails.Hit then
			if Ready(_Q) and hitDetails.HitTime  > .25 then	
				CastSpell(HK_Q, myHero.pos + (spell.data.startPos - myHero.pos):Normalized() * 50)
			end
		end
	end
end



local NextTick = LocalGameTimer()
function Tick()
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	if myHero.activeSpell and myHero.activeSpell.valid and not myHero.activeSpell.spellWasCast then return end
	NextTick = LocalGameTimer() + .05
end

function OnCC(target, damage, ccType, canDodge)
	
end