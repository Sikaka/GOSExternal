Q = {Range = 1000, Radius = 60,Delay = 0.25, Speed = 700, IsLine = true}
W = {Range = 550, Delay = 0.245, Speed = 99999}
E = {Range = 800, Delay = 0.05, Speed = 99999}	
R = {Range = 0, Radius = 725, Delay = 0.25, Speed = 99999}
	

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Howling Gale", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })	
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Zephyr", type = MENU})
	Menu.Skills.W:MenuElement({id = "Auto", name = "Auto Peel", value = true, toggle = true })
	Menu.Skills.W:MenuElement({id = "Radius", name = "Peel Radius", value = 350, min = 100, max = 800, step = 50 })
	Menu.Skills.W:MenuElement({id = "Targets", name = "Target List", type = MENU})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.W.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true, toggle = true})
		end
	end
	Menu.Skills.W:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
		
		
	Menu.Skills:MenuElement({id = "E", name = "[E] Eye of the Storm", type = MENU})	
	Menu.Skills.E:MenuElement({id = "Targets", name = "Shield Targets", type = MENU})	
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isAlly then
			Menu.Skills.E.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true })
		end
	end
	Menu.Skills.E:MenuElement({id = "Damage", name = "Block On Damage", value = 125, min = 50, max = 1000, step = 50 })
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Shield", value = true, toggle = true })
	Menu.Skills.E:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
		
		
	Menu.Skills:MenuElement({id = "R", name = "[R] Monsoon", type = MENU})
	Menu.Skills.R:MenuElement({id = "Targets", name = "Targets", type = MENU})
	Menu.Skills.R:MenuElement({id = "Auto", name = "Auto Cast", value = true, toggle = true })
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isAlly then
			Menu.Skills.R.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = 50, min = 0, max = 100, step = 5 })
		end
	end
	Menu.Skills.R:MenuElement({id = "Damage", name = "Minimum Incoming Damage", value = 100, min = 50, max = 1000, step = 50 })
	Menu.Skills.R:MenuElement({id = "Count", name = "Enemy Count", value = 2, min = 1, max = 6, step = 1 })		
				
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	Callback.Add("Tick", function() Tick() end)
	
	LocalObjectManager:OnBuffAdded(function (target, buff) OnBuffAdded(target,buff) end)
	LocalObjectManager:OnBuffRemoved(function (target, buff) OnBuffRemoved(target,buff) end)
end




qData = { IsCasting = false, StartPos = nil, Direction = nil, StartedAt = LocalGameTimer()}

function OnBuffAdded(target, buff)
	if target and target.handle == myHero.handle and buff.name == "HowlingGale" and qData.StartPos == nil then
		--If qData.StartPos is not nill then we do not run the logic
		--Try to estimate startPos and direction based on mouse location. This is for manual cast tracking.		
		
		Q.Range = 1000;
		Q.Speed = 666
		qData.IsCasting = true;
		qData.StartPos = myHero.pos;
		qData.Direction = (mousePos - qData.StartPos):Normalized();
		qData.StartedAt = LocalGameTimer();
	end
end

function OnBuffRemoved(target, buff)
	if target and target.handle == myHero.handle and buff.name == "HowlingGale" then
		--The buff is removed. Q is no longer being cast and the start pos should be set to nil. 
		qData.IsCasting = false;		
		qData.StartPos = nil;

		--Reset Q Spell Data
		Q.Range = 1000;
		Q.Speed = 666
	end
end



local NextTick = LocalGameTimer()
function Tick()


	if qData.IsCasting then
		Draw.Circle(qData.StartPos,100,1,Draw.Color(255,0,0,255));
		Draw.Circle(qData.StartPos + (qData.Direction * 700),100,1,Draw.Color(255,0,0,255));

		local chargeDuration = LocalGameTimer() - qData.StartedAt;
		Q.Range = 1000 + chargeDuration * 250;
		Q.Speed = 666 + chargeDuration * 166;

		--TODO: Calculate damage for killsteal

		--Find number of targets predicted to be hit with current path. 		
	end

	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	if BlockSpells() then return end

	--R should be cast in the following conditions
		--A priority ally is low health and inbound damage is significantly high
		--Combo is active and the total healable allies nearby is high enough... and enemies are nearby?
		--An assassin can be blocked (dash used on priority carry)
	if Ready(_R) then
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if hero and CanTargetAlly(hero) and LocalGeometry:IsInRange(myHero.pos, hero.pos, R.Range) then
				local incomingDamage = LocalDamageManager:RecordedIncomingDamage(hero)
				local remainingLifePct = (hero.health - incomingDamage) / hero.maxHealth * 100
				if Menu.Skills.R.Targets[hero.networkID]:Value() >= remainingLifePct and (incomingDamage > hero.health or incomingDamage / hero.health * 100 > 25) then
					NextTick = LocalGameTimer() + .25			
					CastSpell(HK_R, hero)
					return
				end
				if EnemyCount(hero.pos, R.Radius) >= Menu.Skills.R.Count:Value() then
					NextTick = LocalGameTimer() + .25
					CastSpell(HK_R, hero)
					return
				end
			end
		end
	end
	
	if Ready(_W)  and (ComboActive() or Menu.Skills.W.Auto:Value()) then		
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if hero and CanTarget(hero) and Menu.Skills.W.Targets[hero.networkID] and Menu.Skills.W.Targets[hero.networkID]:Value() then				
				local ally, distance = NearestAlly(hero.pos, Menu.Skills.W.Radius:Value())
				if not ally then
					ally = myHero
					distance = Menu.Skills.W.Radius:Value()
				end
				local d = LocalGeometry:GetDistance(hero.pos, myHero.pos)
				if d < distance then
					ally = myHero
					distance = d					
				end
				if ally and CanTargetAlly(ally) and distance < Menu.Skills.W.Radius:Value() and LocalGeometry:IsInRange(myHero.pos, hero.pos, W.Range) then
					NextTick = LocalGameTimer() + .25
					CastSpell(HK_W, hero)
					return
				end				
			end
		end
	end
	
	if Ready(_Q) then

		if qData.IsCasting and qData.StartPos then
			--Our Q is already charging (manual or script cast)
			--Check targets predicted to be hit. 

			--Early release on....
				--KillSteal
				--# targets hit
				--Priority target CC about to expire
		else
			--Our Q is NOT casting. Start casting if in combo only?
		end
	end
	
	if Ready(_E) and (if ComboActive() or Menu.Skills.E.Auto:Value()) then
		--Loop allies in range
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if hero and CanTargetAlly(hero) and LocalGeometry:IsInRange(myHero.pos, hero.pos, E.Range) then
				if Menu.Skills.E.Targets[hero.networkID] and Menu.Skills.E.Targets[hero.networkID]:Value() and LocalGeometry:IsInRange(myHero.pos, hero.pos, E.Range) then		
					--Auto cast on inbound damage to shield them
					if LocalDamageManager:RecordedIncomingDamage(hero) >= Menu.Skills.E.Damage:Value() then
						NextTick = LocalGameTimer() + .25
						CastSpell(HK_E, hero)
						return
					end
					--TODO: Shield carry who is attacking enemies if we're in combo!
				end
			end
		end
	end
	
	NextTick = LocalGameTimer() + .1
end


function OnCC(target, damage, ccType)
	if target.isAlly then
		if Ready(_R) and LocalGeometry:IsInRange(myHero.pos, target.pos, R.Range) and Menu.Skills.R.Targets[target.networkID] and Menu.Skills.R.Targets[target.networkID]:Value() >= CurrentPctLife(target) then
			if ComboActive() or Menu.Skills.R.Auto:Value() then
				CastSpell(HK_R, target)				
				NextTick = LocalGameTimer() + .15
				return
			end
		end
		if Ready(_E) and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) and Menu.Skills.E.Targets[target.networkID] and Menu.Skills.E.Targets[target.networkID]:Value() then
			CastSpell(HK_E, target)
			NextTick = LocalGameTimer() + .15
			return
		end	
	end
	
	if target.isEnemy and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then		
		if Ready(_Q) and not qData.IsCasting and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_Q, target, true)

			--Start charging up the cast!
			
			Q.Range = 1000;
			Q.Speed = 666
			qData.IsCasting = true;
			qData.StartPos = myHero.pos;
			qData.Direction = (target.pos - qData.StartPos):Normalized();
			qData.StartedAt = LocalGameTimer();			
		end		
	end
end