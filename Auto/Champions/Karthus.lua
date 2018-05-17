Q = {Range = 874, Width = 100, Delay = .5, Speed = 999999}
W = {Range = 1000, Width = 800, Delay = .25, Speed = 999999}
E = { Range = 425 }

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Lay Waste", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast on Immobile", value = true})
	Menu.Skills.Q:MenuElement({id = "AccuracyAuto", name = "Auto Accuracy", value = 4, min = 1, max = 6, step = 1})
	Menu.Skills.Q:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1})
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	Menu.Skills.Q:MenuElement({id = "FarmMana", name = "Farm Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "W", name = "[W] Wall of Pain", type = MENU})
	Menu.Skills.W:MenuElement({id = "Auto", name = "Auto Cast on Immobile", value = true})
	Menu.Skills.W:MenuElement({id = "Combo", name = "Auto Cast in Combo", value = false})
	Menu.Skills.W:MenuElement({id = "Assist", name = "Assist Key",value = false,  key = 0x71})	
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Defile", type = MENU})
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Active When Enemy In Range", value = true})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
		
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Requiem", type = MENU})
	Menu.Skills.R:MenuElement({id = "Auto", name = "Auto Use In Passive (If Will Kill)", value = true})
	Menu.Skills.R:MenuElement({id = "Draw", name = "Draw Kill Count", value = true})
	
	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	Callback.Add("Tick", function() Tick() end)
end

local NextTick = LocalGameTimer()
function Tick()
	if LocalGameIsChatOpen() then return end
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end	
	
	
	NextTick = LocalGameTimer() + .05
end

function OnCC(target, damage, ccType)
	if target.isEnemy and CanTarget(target) and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then		
		if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_Q, target.pos,true)
			return
		end
	end
end