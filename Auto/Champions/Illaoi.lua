Q = {	Range = 850,	Radius = 100,	Delay = 0.75,	Speed = 999999,	IsLine = true	}
E = {	Range = 900,	Radius = 45,	Delay = 0.25,	Speed = 1800,	Collision = true, 	IsLine = true}
W = {	Range = 350	}
R = {	Range = 450,	Delay = 0.5	}
	

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Tentacle Smash", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast on Immobile", value = true})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1})
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Harsh Lesson", type = MENU})
	Menu.Skills.W:MenuElement({id = "Auto", name = "Attack Reset", value = true})
	Menu.Skills.W:MenuElement({id = "Combo", name = "Gapclose in Combo", value = true})
	Menu.Skills.W:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
		
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Test of Spirit", type = MENU})
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Cast on Immobile", value = true})
	Menu.Skills.E:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })	
	Menu.Skills.E:MenuElement({id = "Assist", name = "Assist Key",value = false,  key = 0x72})
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Leap of Faith", type = MENU})
	Menu.Skills.R:MenuElement({id = "Count", name = "Target Count", value = 3, min = 1, max = 6, step = 1})
	Menu.Skills.R:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	Callback.Add("Tick", function() Tick() end)
	_G.SDK.Orbwalker:OnPostAttack(function(args) OnPostAttack() end)
	LocalObjectManager:OnParticleCreate(function(particleInfo) OnParticleCreate(particleInfo) end)
	LocalObjectManager:OnParticleDestroy(function(particleInfo) OnParticleDestroy(particleInfo) end)
end

local SpiritTarget = nil

function OnParticleDestroy(particleInfo)	
	if particleInfo.name == "Illaoi_Base_E_Spirit" then
		SpiritTarget = particleInfo
	end
end
	
function OnParticleCreate(particleInfo)
	if particleInfo.name == "Illaoi_Base_E_Spirit" then
		SpiritTarget = particleInfo
	end
end


function OnPostAttack()
	if not myHero.activeSpell.target then return end
	local target = LocalObjectManager:GetHeroByHandle(myHero.activeSpell.target)
	if not target then
		if not SpiritTarget or SpiritTarget.data.pos.x ~= myHero.activeSpell.placementPos.x or SpiritTarget.data.pos.z ~= myHero.activeSpell.placementPos.z then
			return
		end
	end
	if Ready(_W) and (Menu.Skills.W.Auto:Value() or ComboActive()) then	
		CastSpell(HK_W)
		_G.SDK.Orbwalker.AutoAttackResetted = true
		return
	end	
end


local NextTick = LocalGameTimer()
function Tick()
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	NextTick = LocalGameTimer() + .1
	if BlockSpells() then return end
	local currentMana = CurrentPctMana(myHero)
	
	if Ready(_E) then
		local target = GetTarget(E.Range, true)
		if CanTarget(target) then
			local accuracyRequired = (ComboActive() or Menu.Skills.E.Assist:Value()) and Menu.Skills.E.Accuracy:Value() or Menu.Skills.E.Auto:Value() and 4 or 6
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay, E.Speed, E.Radius, E.Collision, E.IsLine)			
			if castPosition and accuracy >= accuracyRequired and LocalGeometry:IsInRange(myHero.pos, castPosition, E.Range) then
				if CastSpell(HK_E, castPosition) then
					NextTick = LocalGameTimer() + .25
					return
				end
			end
		end
	end
	
	--Get R target info
	if ComboActive() and Ready(_R) and currentMana >= Menu.Skills.R.Mana:Value()  then	
		local targetCount = EnemyCount(myHero.pos, R.Range, R.Delay)
		if SpiritTarget and SpiritTarget.pos and LocalGeometry:IsInRange(myHero.pos, SpiritTarget.pos, R.Range) then
			targetCount = targetCount + 1
		end		
		if targetCount >= Menu.Skills.R.Count:Value() and CastSpell(HK_R) then				
			NextTick = LocalGameTimer() + .25
			return
		end
	end
	
	if Ready(_Q) then
		local target = GetTarget(Q.Range, true)
		if CanTarget(target) then
			local accuracyRequired = ComboActive() and Menu.Skills.Q.Accuracy:Value() or Menu.Skills.Q.Auto:Value() and 4 or 6
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)			
			if castPosition and accuracy >= accuracyRequired and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
				if CastSpell(HK_Q, castPosition) then
					NextTick = LocalGameTimer() + .25
					return
				end
			end
		end
	end
	
	if Ready(_W) and ComboActive() and currentMana >= Menu.Skills.W.Mana:Value() then
		--Don't use combo W if we're already casting something else.
		if myHero.activeSpell and myHero.activeSpell.valid and not myHero.activeSpell.spellWasCast then return end
		local target = GetTarget(W.Range, true)
		if CanTarget(target) and not LocalGeometry:IsInRange(myHero.pos, target.pos, 200) then
			CastSpell(HK_W)
			NextTick = LocalGameTimer() + .25
			return
		end
	end
end


function OnCC(target, damage, ccType)		
	if target.isEnemy and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then
		if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_Q, target.pos)
			return
		end
	end
end