Q = {Range = 850, Radius = 150,Delay = 0.4, Speed = 999999}
W = {Range = 800, Radius = 160,Delay = 0.25, Speed = 999999}
E = {Range = 690, Delay = 0.125, Speed = 2500}
R = {Range = 750,Delay = 0.5, Angle = 80}

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Noxious Blast", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast On Immobile", value = true})
	Menu.Skills.Q:MenuElement({id = "AccuracyAuto", name = "Auto Accuracy", value = 4, min = 1, max = 6, step = 1})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1})
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Miasma", type = MENU})
	Menu.Skills.W:MenuElement({id = "Auto", name = "Auto Cast On Immobile", value = true})
	Menu.Skills.W:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1})
	Menu.Skills.W:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Twin Fang", type = MENU})
	Menu.Skills.E:MenuElement({id = "Poison", name = "Only cast on poisoned enemies", value = false})
	Menu.Skills.E:MenuElement({id = "FarmPoison", name = "Only cast on poisoned minions", value = false, toggle = true})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Farm Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Petrifying Gaze", type = MENU})
	Menu.Skills.R:MenuElement({id = "Assist", name = "Manual Ult Key",value = false,  key = 0x73})	
	Menu.Skills.R:MenuElement({id = "Targets", name = "Stun Targets", type = MENU})	
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.R.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = false })
		end
	end	
	Menu.Skills.R:MenuElement({id = "Auto", name = "Auto Ult", value = false})	
	Menu.Skills.R:MenuElement({id = "Count", name = "Ult on # of enemies", value = 2, min = 1, max = 6, step = 1 })	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })
	
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType, canDodge) OnCC(target, damage, ccType, canDodge) end)
	
	Callback.Add("Tick", function() Tick() end)	
end



local NextTick = LocalGameTimer()
function Tick()
	local attacks = not Menu.Skills.Combo:Value() or CurrentPctMana(myHero) < 15
	EnableOrbAttacks(attacks)
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	if myHero.activeSpell and myHero.activeSpell.valid and not myHero.activeSpell.spellWasCast then return end
	--Turn off orbwalker auto attacks when in combo mode unless low mana
	
	
	local target = GetTarget(Q.Range)	
	if target and Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() then
		local accuracyRequired = Menu.Skills.Combo:Value() and Menu.Skills.Q.Accuracy:Value() or Menu.Skills.Q.AccuracyAuto:Value() 
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
		if castPosition and accuracy >= accuracyRequired and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_Q, castPosition)
			return
		end
	end
	
	if not target or not LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
		target = GetTarget(E.Range)
	end
	
	if target and Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() and Menu.Skills.Combo:Value() then
		if IsTargetPoisoned(target) or not Menu.Skills.E.Poison:Value() then
			CastSpell(HK_E, target)
			NextTick = LocalGameTimer() + .15
			return
		end
	end
	
	
	NextTick = LocalGameTimer() + .05
end


function IsTargetPoisoned(target, duration)
	if not duration then
		duration = 0
	end
	for i = 1, target.buffCount do 
		local buff = target:GetBuff(i)
		if buff.duration > duration and buff.type == 23 then
			return true
		end
	end
end


function OnCC(target, damage, ccType, canDodge)
	if target.isEnemy and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then	
		if Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() and Menu.Skills.W.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, W.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_W, target.pos)
			return
		end
		if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_Q, target.pos)
			return
		end
	end
end