Q = {	Range = 350,	Delay = .25	}
W = {	Range = 1300,	Radius = 70,	Delay = .25,	Speed = 2050,	Collision = true,	IsLine = true	}
E = {	Range = 970,	Radius = 250,	Delay = .25,	Speed = 1200	}

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] H-28G Evolution Turret", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Block", name = "Block Skillshots", value = true})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast", value = false })
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
			
	Menu.Skills:MenuElement({id = "W", name = "[W] Hextech Micro-Rockets", type = MENU})	
	Menu.Skills.W:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.W:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })
	Menu.Skills.W:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] CH-2 Electron Storm Grenade", type = MENU})
	Menu.Skills.E:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	Menu.Skills.E:MenuElement({id = "Assist", name = "Assist Key",value = false,  key = 0x72})
	
	
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType, canDodge) OnCC(target, damage, ccType, canDodge) end)
	LocalObjectManager:OnBlink(function(target) OnBlink(target) end )
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	
	Callback.Add("Tick", function() Tick() end)	
end


function OnSpellCast(spell)
	if spell.isEnemy and Ready(_Q) and Menu.Skills.Q.Block:Value() and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() then
		local hitDetails = LocalDamageManager:GetSpellHitDetails(spell,myHero)
		if hitDetails.Hit and hitDetails.Collision == 1 then
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
	if BlockSpells() then return end
	if myHero.activeSpell and myHero.activeSpell.valid and not myHero.activeSpell.spellWasCast then return end
	if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and (Menu.Skills.Q.Auto:Value() or ComboActive()) then
		local target = GetTarget(Q.Range)
		if target and CanTarget(target) then
			local castPosition = LocalGeometry:PredictUnitPosition(target, Q.Delay)
			if LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
				NextTick = LocalGameTimer() + .2
				CastSpell(HK_Q, castPosition)
			end
		end
	end
	
	if Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() and (Menu.Skills.W.Auto:Value() or ComboActive()) then
		local target = GetTarget(W.Range)
		if target and CanTarget(target) then
			local accuracyRequired = ComboActive() and Menu.Skills.W.Accuracy:Value() or Menu.Skills.W.Auto:Value() and 4 or 6		
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay, W.Speed, W.Radius, W.Collision)
			if castPosition and accuracy >= accuracyRequired and LocalGeometry:IsInRange(myHero.pos, castPosition, W.Range) then				
				NextTick = LocalGameTimer() + .2
				CastSpell(HK_W, castPosition)
			end
		end
	end
	
	if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() and (Menu.Skills.E.Auto:Value() or ComboActive()) then
		local target = GetTarget(E.Range)
		if target and CanTarget(target) then
			local accuracyRequired = Menu.Skills.E.Assist:Value() and 1 or ComboActive() and Menu.Skills.E.Accuracy:Value() or Menu.Skills.E.Auto:Value() and 4 or 6		
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay, E.Speed, E.Radius, E.Collision)
			if castPosition and accuracy >= accuracyRequired and LocalGeometry:IsInRange(myHero.pos, castPosition, E.Range) then				
				NextTick = LocalGameTimer() + .2
				CastSpell(HK_E, castPosition)
			end
		end
	end
	
	NextTick = LocalGameTimer() + .05
end

function OnBlink(target)
	if target.isEnemy and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then
		if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() and Menu.Skills.E.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_E, target.pos)
			return
		end
		if Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() and Menu.Skills.W.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, W.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_W, target.pos)
			return
		end
	end
end

function OnCC(target, damage, ccType, canDodge)
	if target.isEnemy and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then
		if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() and Menu.Skills.E.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_E, target.pos)
			return
		end
		if Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() and Menu.Skills.W.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, W.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_W, target.pos)
			return
		end
	end
end