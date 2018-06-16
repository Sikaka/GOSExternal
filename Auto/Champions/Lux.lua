Q = {Range = 1075, Radius = 50,Delay = 0.25, Speed = 1200, Collision = true}
W = {Range = 1075, Radius = 120,Delay = 0.25, Speed = 1400}
E = {Range = 1100, Radius = 310,Delay = 0.25, Speed = 1200}
R = {Range = 3340, Radius = 110, Delay = 1, Speed = 999999}
	

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Light Binding", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 2, min = 1, max = 6, step = 1 })	
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })	
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Prismatic Barrier", type = MENU})
	Menu.Skills.W:MenuElement({id = "Damage", name = "Minimum Damage", value = 200, min = 100, max = 1000, step = 25 })
	Menu.Skills.W:MenuElement({id = "Count", name = "Minimum Targets", value = 1, min = 1, max = 6, step = 1 })
	Menu.Skills.W:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
		
	Menu.Skills:MenuElement({id = "E", name = "[E] Lucent Singularity", type = MENU})
	Menu.Skills.E:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })
	Menu.Skills.E:MenuElement({id = "Targets", name = "Burst Targets", type = MENU})	
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.E.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true })
		end
	end
	Menu.Skills.E:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
		
	Menu.Skills:MenuElement({id = "R", name = "[R] Final Spark", type = MENU})
	Menu.Skills.R:MenuElement({id = "Accuracy", name = "Accuracy", value = 2, min = 1, max = 6, step = 1 })
	Menu.Skills.R:MenuElement({id = "Combo", name = "Combo Only", value = false })
	Menu.Skills.R:MenuElement({id = "Count", name = "Combo Target Count", tooltip = "How many targets we need to be able to hit to auto cast", value = 2, min = 1, max = 6, step = 1 })	
	Menu.Skills.R:MenuElement({id = "Killsteal", name = "Auto Killsteal", value = true, toggle = true })
	Menu.Skills.R:MenuElement({id = "Targets", name = "Burst Targets", type = MENU})	
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.R.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true })
		end
	end
		
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	LocalObjectManager:OnBlink(function(target) OnBlink(target) end )
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	Callback.Add("Tick", function() Tick() end)
end

local EPos = nil
local EExpiresAt = 0

function OnSpellCast(spell)
	if spell.data.name == "LuxLightStrikeKugel" then
		EPos = Vector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z)
		EExpiresAt = LocalGameTimer() + 5
	end
end


local NextTick = LocalGameTimer()
function Tick()
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end	
	if BlockSpells() then return end
	if EPos and EExpiresAt> currentTime  then
		DetonateE()
	end
	
	NextTick = LocalGameTimer() + .1
	
	if Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() then
		for i = 1, LocalGameHeroCount() do
			local target = LocalGameHero(i)
			if CanTargetAlly(target) and  LocalGeometry:IsInRange(myHero.pos, target.pos, W.Range) then
				local incomingDamage = LocalDamageManager:RecordedIncomingDamage(target)
				if incomingDamage > Menu.Skills.W.Damage:Value() then				
					local castPosition = LocalGeometry:PredictUnitPosition(target, W.Delay + LocalGeometry:GetDistance(myHero.pos, target.pos)/W.Speed)
					local endPosition = myHero.pos + (castPosition-myHero.pos):Normalized() * W.Range			
					local targetCount = LocalGeometry:GetLineTargetCount(myHero.pos, endPosition, W.Delay, W.Speed, W.Radius,true)
					if targetCount >= Menu.Skills.W.Count:Value() then
						NextTick = LocalGameTimer() + .25
						if CastSpell(HK_W, castPosition, true) then
							return
						end
					end
				end
			end
		end
	end
	
	--Check for killsteal or target count R
	if Ready(_R) and Menu.Skills.R.Killsteal:Value() and (not Menu.Skills.R.Combo:Value() or ComboActive()) then
		local rDamage= 200 + (myHero:GetSpellData(_R).level) * 100 + myHero.ap * 0.75
		for i = 1, LocalGameHeroCount() do
			local target = LocalGameHero(i)
			if CanTarget(target) and LocalGeometry:IsInRange(myHero.pos, target.pos, R.Range) then
				
				local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, R.Range, R.Delay, R.Speed, R.Radius, R.Collision, R.IsLine)
				if castPosition and accuracy >= Menu.Skills.R.Accuracy:Value() then					
					local thisRDamage = rDamage
					if LocalBuffManager:HasBuff(target, "LuxIlluminatingFraulein",R.Delay) then
						thisRDamage = thisRDamage + 20 + myHero.levelData.lvl * 10 + myHero.ap * 0.2
					end
					local extraIncoming = LocalDamageManager:RecordedIncomingDamage(target)
					local predictedHealth = target.health + target.hpRegen * 2 - extraIncoming			
					thisRDamage = LocalDamageManager:CalculateMagicDamage(myHero,target, thisRDamage)
					if predictedHealth > 0 and thisRDamage > predictedHealth then
						NextTick = LocalGameTimer() + 1
						if CastSpell(HK_R, castPosition, true) then
							return
						end
					end
				end
			end
		end
	end
	
	
	local target = GetTarget(Q.Range)
	if target and CanTarget(target) then
		if Ready(_E) then
			local accuracyRequired = ComboActive() and Menu.Skills.E.Accuracy:Value() or Menu.Skills.E.Auto:Value() and 4 or 6
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay, E.Speed, E.Radius, E.Collision, E.IsLine)
			if castPosition and accuracy >= accuracyRequired and LocalGeometry:IsInRange(myHero.pos, castPosition, E.Range) then
				NextTick = LocalGameTimer() + .25
				if CastSpell(HK_E, castPosition) then
					return
				end
			end
		end
		
		if Ready(_Q) then
			local accuracyRequired = ComboActive() and Menu.Skills.Q.Accuracy:Value() or Menu.Skills.Q.Auto:Value() and 4 or 6
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
			if castPosition and accuracy >= accuracyRequired and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
				NextTick = LocalGameTimer() + .25
				if CastSpell(HK_Q, castPosition) then
					return
				end
			end
		end
	end
	
	local target = GetTarget(R.Range)
	if target and CanTarget(target) and Ready(_R) and (not Menu.Skills.R.Combo:Value() or ComboActive()) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, R.Range, R.Delay, R.Speed, R.Radius, R.Collision, R.IsLine)
		if castPosition and LocalGeometry:IsInRange(myHero.pos, castPosition, R.Range) then
			if accuracy >= Menu.Skills.R.Accuracy:Value() then
				local endPosition = myHero.pos + (castPosition-myHero.pos):Normalized() * R.Range
				local targetCount = LocalGeometry:GetLineTargetCount(myHero.pos, endPosition, R.Delay, R.Speed, R.Radius)
				if targetCount >= Menu.Skills.R.Count:Value() then
					NextTick = LocalGameTimer() + 1					
					if CastSpell(HK_R, castPosition, true) then
						return
					end
				end
			end
		end
	end
	
end


function DetonateE()
	local eData = myHero:GetSpellData(_E)
	if eData.toggleState == 2 then
		for i = 1, LocalGameHeroCount() do
			local target = LocalGameHero(i)
			if CanTarget(target) and LocalGeometry:IsInRange(EPos, target.pos, E.Radius) then
				if Menu.Skills.E.Targets[target.networkID] and Menu.Skills.E.Targets[target.networkID]:Value() then
					CastSpell(HK_E)
					EExpiresAt = 0
					break
				else
					if LocalDamageManager:PredictDamage(myHero, target, "LuxLightStrikeKugel") > target.health then
						CastSpell(HK_E)
						EExpiresAt = 0
						break
					end
					local nextPosition = LocalGeometry:PredictUnitPosition(target, .1)
					if not LocalGeometry:IsInRange(EPos, nextPosition, E.Radius) then
						CastSpell(HK_E)
						EExpiresAt = 0
						break
					end
				end
			end
		end
	end
end

function OnBlink(target)
	if target.isEnemy and CanTarget(target) and Ready(_Q) and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision)
		if accuracy > 0 then
			CastSpell(HK_Q, castPosition,true)
		end	
	end
	if target.isEnemy and CanTarget(target) and Ready(_E) and Menu.Skills.E.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay, E.Speed, E.Radius, E.Collision)
		if accuracy > 0 then
			CastSpell(HK_E, castPosition)
		end	
	end
end

function OnCC(target, damage, ccType)
	if target.isAlly and Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, W.Range) then
		local castPosition = mousePos		
		if target ~= myHero then
			castPosition = LocalGeometry:PredictUnitPosition(target, W.Delay + LocalGeometry:GetDistance(myHero.pos, target.pos)/W.Speed)
		else
			local ally = NearestAlly(myHero.pos, W.Range)
			if ally then
				castPosition = LocalGeometry:PredictUnitPosition(ally, W.Delay + LocalGeometry:GetDistance(myHero.pos, ally.pos)/W.Speed)
			end
		end		
		CastSpell(HK_W, castPosition)
	end
	
	if target.isEnemy and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then
		if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_Q, target.pos,true)
			return
		end
		
		if Ready(_E) and CanTarget(target) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() and Menu.Skills.E.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
			NextTick = LocalGameTimer() +.25
			CastSpell(HK_E, target.pos)
			return
		end
	end
end