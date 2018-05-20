Q = {Range = 900, Radius = 180,Delay = 0.25, Speed = 2050}
E = {Range = 550}
R = {Range = 900}
	

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Timb Bomb", type = MENU})
	Menu.Skills.Q:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.Q:MenuElement({id = "AccuracyAuto", name = "Auto Accuracy", value = 4, min = 1, max = 6, step = 1 })
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Auto Cast Mana", value = 30, min = 1, max = 100, step = 5 })
	Menu.Skills.Q:MenuElement({id = "Targets", name = "Targets", type = MENU})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.Q.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true, toggle = true})
		end
	end
	
	
	Menu.Skills:MenuElement({id = "W", name = "[W] Rewind", type = MENU})
	Menu.Skills.W:MenuElement({id = "Cooldown", name = "Minimum Cooldown Remaining", value = 3, min = 1, max = 10, step = .5 })
	Menu.Skills.W:MenuElement({id = "Mana", name = "Minimum Mana", value = 25, min = 1, max = 100, step = 5 })
	
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Time Warp", type = MENU})	
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Peel", value = true, toggle = true })
	Menu.Skills.E:MenuElement({id = "Radius", name = "Peel Radius", value = 300, min = 100, max = 600, step = 50 })
	Menu.Skills.E:MenuElement({id = "Mana", name = "Minimum Mana", value = 25, min = 1, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Chronoshift", type = MENU})
	Menu.Skills.R:MenuElement({id = "Targets", name = "Targets", type = MENU})	
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isAlly then
			Menu.Skills.R.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = 15, min = 0, max = 100, step = 5 })
		end
	end
	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	LocalObjectManager:OnBlink(function(target) OnBlink(target) end )
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	Callback.Add("Tick", function() Tick() end)
end

function OnSpellCast(spell)
end

local NextTick = LocalGameTimer()
function Tick()
	if NextTick > LocalGameTimer() then return end	
	NextTick = LocalGameTimer() + .1
end

function OnCC(target, damage, ccType)
	if target.isEnemy and LocalDamageManager.IMMOBILE_TYPES[ccType] then
		if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
			NextTick = LocalGameTimer() +.25
			CastSpell(HK_Q, target.pos)
			return
		end
	end
end

function OnBlink(target)
	if CanTarget(target) and Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
		if accuracy > 0 then
			CastSpell(HK_Q, target.pos)			
		end	
	end
end