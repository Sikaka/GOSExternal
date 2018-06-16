Q = {Range = 900, Radius = 300,Delay = 0.25, Speed = 2050}
E = {Range = 550}
R = {Range = 900}
	

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Timb Bomb", type = MENU})
	Menu.Skills.Q:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.Q:MenuElement({id = "AccuracyAuto", name = "Auto Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.Q:MenuElement({id = "AccuracyStun", name = "Stun Accuracy", value = 2, min = 1, max = 6, step = 1 })
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
	
		
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	LocalObjectManager:OnBlink(function(target) OnBlink(target) end )
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	LocalObjectManager:OnBuffAdded(function (target, buff) OnBuffAdded(target,buff) end)
	LocalObjectManager:OnBuffRemoved(function (target, buff) OnBuffRemoved(target,buff) end)
	Callback.Add("Tick", function() Tick() end)
end

function OnSpellCast(spell)
	if spell.owner == myHero.networkID and Ready(_E) and spell.name =="ZileanQ" then
		local castPos = Vector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z)
		local enemy = NearestEnemy(castPos, Q.Radius)
		if CanTarget(enemy) and LocalGeometry:IsInRange(myHero.pos, enemy.pos, E.Range) then
			CastSpell(HK_E, enemy)
			return
		end
	end
	if spell.isEnemy and Ready(_R) then
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if hero and hero.isAlly and LocalGeometry:IsInRange(myHero.pos, hero.pos, R.Range) and Menu.Skills.R.Targets[hero.networkID] and CurrentPctLife(hero) <= Menu.Skills.R.Targets[hero.networkID]:Value() then
				if LocalDamageManager:DodgeSpell(spell.data, hero, 1) then
					CastSpell(HK_R, hero)
					return
				end
			end
		end
	end
end

local qTarget = nil
function OnBuffAdded(target, buff)
	if target and (buff.name == "ZileanQEnemyBomb" or buff.name == "ZileanQAllyBomb") then
		qTarget = target
		if CanTarget(target)  and Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
			CastSpell(HK_E, target)
		end
	end
end

function OnBuffRemoved(target, buff)
	if target and qTarget and qTarget == target  and (buff.name == "ZileanQEnemyBomb" or buff.name == "ZileanQAllyBomb") then
		qTarget = nil
	end
end

local NextTick = LocalGameTimer()
function Tick()
	if NextTick > LocalGameTimer() then return end
	
	if BlockSpells() then return end
	--Look for targets we can revive
	if Ready(_R) then
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)				
			if hero and hero.isAlly and LocalGeometry:IsInRange(myHero.pos, hero.pos, R.Range) and Menu.Skills.R.Targets[hero.networkID] then
				local incomingDamage = LocalDamageManager:RecordedIncomingDamage(hero)
				local remainingLifePct = (hero.health - incomingDamage) / hero.maxHealth * 100
				if Menu.Skills.R.Targets[hero.networkID]:Value() >= remainingLifePct and (incomingDamage > hero.health or incomingDamage / hero.health * 100 > 25) then
					NextTick = LocalGameTimer() + .25			
					CastSpell(HK_R, hero)
					return
				end
			end
		end
	end	
	
	if Ready(_Q)  and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() then
		if qTarget and LocalGeometry:IsInRange(myHero.pos, qTarget.pos, Q.Range) then
			local requiredAccuracy = ComboActive() and Menu.Skills.Q.AccuracyCombo:Value() or Menu.Skills.Q.AccuracyAuto:Value()
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, qTarget, Q.Range, Q.Delay, Q.Speed, 125, Q.Collision, Q.IsLine)
			if castPosition and accuracy >= Menu.Skills.Q.AccuracyStun:Value() and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) and EnemyCount(castPosition, Q.Radius) >= 1 then
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_Q, castPosition)
				return
			end
		end
		local target = GetTarget(Q.Range)
		if target then			
			local requiredAccuracy = ComboActive() and Menu.Skills.Q.AccuracyCombo:Value() or Menu.Skills.Q.AccuracyAuto:Value()
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, 125, Q.Collision, Q.IsLine)
			if castPosition and accuracy >= requiredAccuracy and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_Q, castPosition)
				return
			end
		end		
	end
	
	if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() then
		if qTarget and CanTarget(qTarget) and LocalGeometry:IsInRange(myHero.pos, qTarget.pos, E.Range) then
			CastSpell(HK_E, qTarget)
			NextTick = LocalGameTimer() + .15
			return
		end
		
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if CanTarget(hero) and LocalGeometry:IsInRange(myHero.pos, hero.pos, E.Range) then
				--check how close the nearest ally is to them
				local ally, distance = NearestAlly(hero.pos, Menu.Skills.E.Radius:Value())
				if not ally then
					ally = myHero
					distance = Menu.Skills.E.Radius:Value()
				end
				local d = LocalGeometry:GetDistance(hero.pos, myHero.pos)
				if d < distance then
					ally = myHero
					distance = d					
				end
				if ally and CanTargetAlly(ally) and distance < Menu.Skills.E.Radius:Value() and LocalGeometry:IsInRange(myHero.pos, hero.pos, E.Range) then
					NextTick = LocalGameTimer() + .15
					CastSpell(HK_E, hero)
					return
				end		
			end
		end
	end
	
	if Ready(_W) and myHero.levelData.lvl >= 3 and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() then
		if myHero:GetSpellData(_Q).currentCd >= Menu.Skills.W.Cooldown:Value() and myHero:GetSpellData(_E).currentCd >= Menu.Skills.W.Cooldown:Value() then		
			Control.CastSpell(HK_W)
		end
	end	
	NextTick = LocalGameTimer() + .1
end

function OnCC(target, damage, ccType)
	if CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then
		if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
			NextTick = LocalGameTimer() +.25
			CastSpell(HK_Q, target.pos)
			return
		end
	end
end

function OnBlink(target)
	if CanTarget(target) and Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, 125, Q.Collision, Q.IsLine)
		if accuracy > 0 and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
			CastSpell(HK_Q, castPosition)			
		end	
	end
end