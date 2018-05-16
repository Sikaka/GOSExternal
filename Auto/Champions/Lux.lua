Q = {Range = 1075, Width = 50,Delay = 0.25, Speed = 1200, Collision = true}
W = {Range = 1075, Width = 120,Delay = 0.25, Speed = 1400}
E = {Range = 1100, Width = 310,Delay = 0.25, Speed = 1200}
R = {Range = 3340, Width = 115, Delay = 1, Speed = _huge}
	

function LoadScript()
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Light Binding", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })	
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })	
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Prismatic Barrier", type = MENU})
	Menu.Skills.W:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
	Menu.Skills.W:MenuElement({id = "Damage", name = "Recent Damage Received", value = 15, min = 5, max = 60, step = 5 })
	Menu.Skills.W:MenuElement({id = "Count", name = "Minimum Targets", value = 1, min = 1, max = 6, step = 1 })
		
	Menu.Skills:MenuElement({id = "E", name = "[E] Lucent Singularity", type = MENU})
	Menu.Skills.E:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })	
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })
		
	Menu.Skills:MenuElement({id = "R", name = "[R] Final Spark", type = MENU})	
	Menu.Skills.R:MenuElement({id = "Count", name = "Target Count", tooltip = "How many targets we need to be able to hit to auto cast", value = 2, min = 1, max = 6, step = 1 })	
	Menu.Skills.R:MenuElement({id = "Killsteal", name = "Auto Killsteal", value = true, toggle = true })
	Menu.Skills.R:MenuElement({id = "Auto", name = "Auto Cast On Target Count", value = true, toggle = true })	
	Menu.Skills.R:MenuElement({id = "Targets", name = "Auto Targets", type = MENU})	
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.R.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
		end
	end
		
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	LocalObjectManager:OnBlink(function(target) OnBlink(target) end )
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	Callback.Add("Tick", function() Tick() end)
	Callback.Add("WndMsg",function(Msg, Key) WndMsg(Msg, Key) end)
end

local WPos = nil

function OnSpellCast(spell)
	if spell.data.name == "ZiggsW" then
		WPos = Vector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z)	
	end
end


local NextTick = LocalGameTimer()
function Tick()
	if NextTick > LocalGameTimer() then return end
	if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() then
		local target = GetTarget(Q.Range)
		--Get cast position for target
		if target and CanTarget(target) then		
			--Check the damage we will deal to the target
			local targetQDamage = _G.Alpha.DamageManager:CalculateMagicDamage(myHero, target, myHero.ap * .65 + ({75,120,165,210,255})[myHero:GetSpellData(_Q).level])
			local accuracyRequired = Menu.Skills.Combo:Value() and Menu.Skills.Q.Accuracy:Value() or 6
			if targetQDamage > target.health and accuracyRequired > Menu.Skills.Q.KSAccuracy:Value() then
				accuracyRequired = Menu.Skills.Q.KSAccuracy:Value()
			end
			if accuracyRequired < 6 then
				local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision)
				if castPosition and accuracy >= accuracyRequired and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
					NextTick = LocalGameTimer() + .25
					_G.Control.CastSpell(HK_Q, castPosition)
					return
				end
			end			
		end
	end
	if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() then
		local target = GetTarget(E.Range)
		--Get cast position for target
		if target and CanTarget(target) and Menu.Skills.Combo:Value() then
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay, E.Speed, E.Radius, E.Collision)
			if castPosition and accuracy >= Menu.Skills.E.Accuracy:Value() and LocalGeometry:IsInRange(myHero.pos, castPosition, E.Range) then
				NextTick = LocalGameTimer() + .25
				_G.Control.CastSpell(HK_E, castPosition)
				return
			end	
		end
	end
	if Ready(_W) then
		local wData = myHero:GetSpellData(_W)
		if wData.toggleState == 0 then
			for i = 1, LocalGameHeroCount() do
				local hero = LocalGameHero(i)
				if hero and CanTarget(hero) then
					local origin = LocalGeometry:PredictUnitPosition(hero, W.Delay)
					if LocalGeometry:IsInRange(myHero.pos, origin, Menu.Skills.W.Radius:Value()) then
						local castPosition =  myHero.pos + (origin - myHero.pos):Normalized() * 150
						NextTick = LocalGameTimer() + .25
						_G.Control.CastSpell(HK_W, castPosition)
						return
					end
				end
			end
		elseif WPos and wData.toggleState == 2 then
			for i = 1, LocalGameHeroCount() do
				local hero = LocalGameHero(i)
				if hero and CanTarget(hero)  then					
					local origin = LocalGeometry:PredictUnitPosition(hero, .15)
					if  LocalGeometry:IsInRange(WPos, origin, W.Radius) then
						if  LocalGeometry:IsInRange(myHero.pos, origin, Menu.Skills.W.Radius:Value()) and LocalGeometry:IsInRange(myHero.pos, WPos, W.Radius) then							
							NextTick = LocalGameTimer() + .25
							Control.CastSpell(HK_W)
							return
						end
						local forward = (hero.pos - WPos):Normalized()
						local scaling = 400-LocalGeometry:GetDistance(origin, WPos)
						local predictedPosition = origin + forward * scaling					
						if LocalGeometry:IsInRange(myHero.pos, predictedPosition, Q.Range) and Menu.Skills.W.ComboTargets[hero.networkID] and Menu.Skills.W.ComboTargets[hero.networkID]:Value() then
					NextTick = LocalGameTimer() + .25
							_G.Control.CastSpell(HK_Q, predictedPosition)
							DelayAction(function()Control.CastSpell(HK_W) end,.15)
							return
						end
					end
				end
			end
		end
	end
	
	if Ready(_R) and Menu.Skills.Combo:Value() then
		--Check enemies in range and how many enemies are predicted within the explosion radius if we aim at them...				
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if hero and CanTarget(hero) then
				if Menu.Skills.R.Targets[hero.networkID] and Menu.Skills.R.Targets[hero.networkID]:Value() and LocalGeometry:IsInRange(myHero.pos, hero.pos, R.Radius) then
					local interceptTime = LocalGeometry:GetSpellInterceptTime(myHero.pos, hero.pos, R.Delay, R.Speed)
					local origin = LocalGeometry:PredictUnitPosition(hero, interceptTime)
					if LocalGeometry:IsInRange(myHero.pos, origin, R.Radius) then
						--We finally have a target and know we want to try to target them.. Check how many enemies are within this cast radius
						local nearbyEnemies = EnemyCount(origin, R.Radius)
						if nearbyEnemies >= Menu.Skills.R.Count:Value() then
							NextTick = LocalGameTimer() + .25
							_G.Control.CastSpell(HK_R, origin)
							return
						end
					end
				end
			end
		end
	end
	NextTick = LocalGameTimer() + .1
end

function OnBlink(target)
	if target.isEnemy and Ready(_Q) and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision)
		if accuracy > 0 then
			Control.CastSpell(HK_Q, target.pos)
		end	
	end
	if target.isEnemy and Ready(_E) and Menu.Skills.E.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay, E.Speed, E.Radius, E.Collision)
		if accuracy > 0 then
			Control.CastSpell(HK_E, target.pos)
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
		
		if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() and Menu.Skills.E.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
			NextTick = LocalGameTimer() +.25
			CastSpell(HK_E, target.pos)
			return
		end
	end
end