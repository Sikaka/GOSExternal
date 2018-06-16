Q = {	Range = 750,	Delay = 0.35,	Speed = 99999,	Radius = 145	}
W = {	Range = 1050,	Delay = 0.5,	Speed = 99999,	Radius = 200	}
E = {	Range = 1050,	Delay = 0.25,	Speed = 2100,	Radius = 80, Collision = true,	IsLine = true	}
R = {	Range = 3520,	Delay = 0.5,	Speed = 99999,	Radius = 200	}
local LocalMathMin = math.min
local LocalTableSort = table.sort

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Arcanopulse", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Assist", name = "Assist", value = true, toggle = true,  key = 0x70 })		
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
	Menu.Skills.W:MenuElement({id = "Killsteal", name = "Killsteal", value = true, toggle = true })	
	Menu.Skills.W:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
	
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Shocking Orb", type = MENU})
	Menu.Skills.E:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })	
	Menu.Skills.E:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
	
		
	Menu.Skills:MenuElement({id = "R", name = "[R] Rite of the Arcane", type = MENU})
	Menu.Skills.R:MenuElement({id = "Auto", name = "Auto Cast", value = true })
	Menu.Skills.R:MenuElement({id = "Accuracy", name = "Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.R:MenuElement({id = "Frequency", name = "Cast Speed", value = 1, min =.25, max = 3, step = .25 })
	Menu.Skills.R:MenuElement({id = "Killsteal", name = "Killsteal", value = true })
	Menu.Skills.R:MenuElement({id = "Assist", name = "Assist Key",value = false,  key = 0x73})
	
		
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)	
	Callback.Add("Tick", function() Tick() end)
end

local qStartTime = 0
function OnSpellCast(spell)
	if spell.owner == myHero.networkID then
		if spell.data.name == "XerathArcanopulseChargeUp" then
			qStartTime = LocalGameTimer()
		--Update the range of our ult on use so it will always be correct
		elseif spell.data.name == "XerathLocusOfPower2" then
			local rData = myHero:GetSpellData(_R)
			if rData.level == 3 then R.Range = 6100
			elseif rData.level == 2 then R.Range = 4800
			else R.Range = 3500 end
		end
	end
end

function IsQCharging()
	return myHero.activeSpell and myHero.activeSpell.valid and myHero.activeSpell.name == "XerathArcanopulseChargeUp"
end

function IsRActive()	
	if myHero.activeSpell and myHero.activeSpell.valid and myHero.activeSpell.name == "XerathLocusOfPower2" then
		return true
	end
end

local NextTick = LocalGameTimer()
function Tick()	
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	NextTick = LocalGameTimer() + .1
	if BlockSpells() then return end
	
	if IsQCharging() and Menu.Skills.Q.Assist:Value() then
		local chargeTime = LocalMathMin(LocalGameTimer() - qStartTime, 2)
		local range = 750 + 500* chargeTime		
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if CanTarget(hero) and Menu.Skills.Q.Targets[hero.networkID] then
				local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, hero, range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
				if aimPosition and LocalGeometry:IsInRange(myHero.pos, aimPosition, range - 200) then
					local thisDmg = LocalDamageManager:CalculateDamage(myHero, hero, "XerathArcanopulseChargeUp")
					local incomingDmg =LocalDamageManager:RecordedIncomingDamage(hero)
					--We can killsteal the target. Set them as our priority
					if incomingDmg < hero.health and incomingDmg +  thisDmg >= hero.health and Menu.Skills.Q.Killsteal then
						CastSpell(HK_Q, aimPosition, true)
						NextTick = LocalGameTimer() + .3
						return
					end

					if Menu.Skills.Q.Targets[hero.networkID]:Value() or chargeTime > 1.75 then
						if hitChance >= Menu.Skills.Q.Accuracy:Value() then
							CastSpell(HK_Q, aimPosition, true)
							NextTick = LocalGameTimer() + .3
							return
						end
					end
					
				end
			end
		end		
	end
	
	if IsRActive() and Ready(_R) then
		local target = Menu.Skills.R.Assist:Value() and NearestEnemy(mousePos, 800) or Menu.Skills.R.Auto:Value() and GetTarget(R.Range)
		if target then
			local thisDmg = LocalDamageManager:CalculateDamage(myHero, target, "XerathLocusOfPower2")
			local accuracyRequired = Menu.Skills.R.Killsteal:Value() and thisDmg >= target.health and 1 or Menu.Skills.R.Accuracy:Value()
			local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, R.Range, R.Delay,R.Speed, R.Radius, R.Collision, R.IsLine)
			if aimPosition and hitChance >= accuracyRequired then
				CastSpell(HK_R, aimPosition)
				if Menu.Skills.R.Assist:Value() then
					NextTick = LocalGameTimer() + .2
				else					
					NextTick = LocalGameTimer() + Menu.Skills.R.Frequency:Value() + math.random(-.25, .25)
				end
				return
			end			
		end
	end
	
	if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value()  then
		local target = GetTarget(E.Range)
		if CanTarget(target) then
			local accuracyRequired =  ComboActive() and Menu.Skills.E.Accuracy:Value() or Menu.Skills.E.Auto:Value() and 4 or 6
			local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay,E.Speed, E.Radius, E.Collision, E.IsLine)
			if aimPosition and hitChance >= accuracyRequired then
				CastSpell(HK_E, aimPosition)
				NextTick = LocalGameTimer() + .2	
				return
			end
		end
	end
	
	if Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() then
		local target = GetTarget(W.Range)
		if CanTarget(target) then
			local thisDmg = LocalDamageManager:CalculateDamage(myHero, target, "XerathArcaneBarrage2")
			local accuracyRequired = Menu.Skills.W.Killsteal:Value() and thisDmg >= target.health and 2 or ComboActive() and Menu.Skills.W.Accuracy:Value() or Menu.Skills.W.Auto:Value() and 4 or 6
			local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay,W.Speed, W.Radius, W.Collision, W.IsLine)
			if aimPosition and hitChance >= accuracyRequired then
				CastSpell(HK_W, aimPosition)
				NextTick = LocalGameTimer() + .2	
				return
			end
		end
	end
	
	
	
end