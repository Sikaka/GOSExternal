Q = {Range = 1000, Radius = 45,Delay = 0.25, Speed = 2850, Collision = true, IsLine = true }
W = {Range = 900, Radius = 150,Delay = 1, Speed = 99999 }
E = {Range = 700, Radius = 300,Delay = 0.25, Speed = 2000 }

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Threaded Volley", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast on Immobile", value = true})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1})
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Seismic Shove", type = MENU})
	Menu.Skills.W:MenuElement({id = "Auto", name = "Auto Cast on Immobile", value = true})
	Menu.Skills.W:MenuElement({id = "Radius", name = "Push Range", value = 300, min = 100, max = 600, step = 50 })
	Menu.Skills.W:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1})
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Unraveled Earth", type = MENU})
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Cast on Immobile", value = true})
	Menu.Skills.E:MenuElement({id = "Radius", name = "Peel Range", value = 300, min = 100, max = 600, step = 50 })
	Menu.Skills.E:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 4, min = 1, max = 6, step = 1})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	Callback.Add("Tick", function() Tick() end)
end

local WPos = nil
local WDir = nil
local WExpiresAt = 0

function OnSpellCast(spell)
	if spell.data.name == "TaliyahWVC" then
		WPos = Vector(myHero.activeSpell.placementPos.x,myHero.activeSpell.placementPos.y,myHero.activeSpell.placementPos.z)
		WDir = (mousePos - WPos):Normalized()
		WExpiresAt = spell.data.startTime + 1
	end
end


local NextTick = LocalGameTimer()
function Tick()
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end	
	
	if BlockSpells() then return end
	if #vectorCast > 0 then
		vectorCast[1]()
		table.remove(vectorCast, 1)
		return
	end
	if LocalGameIsChatOpen() then return end
	if WPos and LocalGeometry:IsInRange(myHero.pos, WPos, E.Range) then
		local timeTillDetonate = WExpiresAt - currentTime
		if timeTillDetonate < 0 then
			WPos = nil
		elseif timeTillDetonate < .6 and Ready(_E) then
			for i = 1, LocalGameHeroCount() do
				local hero = LocalGameHero(i)
				if hero and CanTarget(hero) then
					local predictedPosition = LocalGeometry:PredictUnitPosition(hero, timeTillDetonate)
					if LocalGeometry:IsInRange(WPos, predictedPosition, W.Radius) then
						local endPos = predictedPosition + WDir * 400
						if LocalGeometry:IsInRange(myHero.pos, endPos, E.Range) then
							WExpiresAt = 0
							CastSpell(HK_E, WPos)
							return
						end
					end
				end
			end
		end
	end
	
	local target = GetTarget(Q.Range)
	if target and Ready(_Q) then
		local accuracyRequired = 6
		if Menu.Skills.Q.Auto:Value() then accuracyRequired =  4 end
		if ComboActive() then accuracyRequired = Menu.Skills.Q.Accuracy:Value() end	
		
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay,Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
		if castPosition and accuracy >= accuracyRequired and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_Q, castPosition)
			return
		end
	end
	
	local target = GetTarget(E.Range)
	if Ready(_E) and target then
		if LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then			
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay,W.Speed, W.Radius, W.Collision, W.IsLine)
			if castPosition and (accuracy >= Menu.Skills.E.Accuracy:Value() or LocalGeometry:IsInRange(myHero.pos, castPosition, Menu.Skills.E.Radius:Value())) then
				CastSpell(HK_E, castPosition)
			end
		end
			
	end
	local target = GetTarget(W.Range)
	if Ready(_W) and target  then		
	
		local requiredAccuracy = 6
		if ComboActive() then
			requiredAccuracy = Menu.Skills.W.Accuracy:Value()
		elseif Menu.Skills.W.Auto:Value() then
			requiredAccuracy = 4
		end
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay,W.Speed, W.Radius, W.Collision, W.IsLine)		
		if castPosition and accuracy >= requiredAccuracy and LocalGeometry:IsInRange(myHero.pos, castPosition, W.Range) then
			NextTick = LocalGameTimer() + .15
			local pushDir = castPosition + (myHero.pos - castPosition):Normalized() * 200
			if LocalGeometry:IsInRange(myHero.pos, castPosition, Menu.Skills.W.Radius:Value()) then
				pushDir = castPosition + (castPosition - myHero.pos):Normalized() * 200
			end
			CastVectorSpell(HK_W, castPosition, pushDir)
			return
		end
	end
	
	NextTick = LocalGameTimer() + .05
end

function OnCC(target, damage, ccType)
	if target.isEnemy and CanTarget(target) and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then
		if Ready(_E) and CanTarget(target) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() and Menu.Skills.E.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
			NextTick = LocalGameTimer() +.25
			CastSpell(HK_E, target.pos)
			return
		end
		if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_Q, target.pos,true)
			return
		end
	end
end