Q = {Range = 1175, Radius = 80, Delay = 0.25, Speed = 1200, Collision = true, IsLine = true}
W = {Range = 900, Radius = 500, Delay = 0.25, Speed = math.huge}
E = {Range = 800, Delay = 0.25, Speed = math.huge}
R = {Range = 625, Delay = 0.25, Speed = math.huge}

function LoadScript()
	CreateMenu()
	LocalDamageManager:OnIncomingCC(
		function(target, damage, ccType)
			OnCC(target, damage, ccType)
		end
	)
	LocalObjectManager:OnBlink(
		function(target)
			OnBlink(target)
		end
	)
	Callback.Add(
		"Tick",
		function()
			Tick()
		end
	)
end

function CreateMenu()
	--Menu
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	--Skills
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	-- Q
	Menu.Skills:MenuElement({name = "[Q] Dark Binding", id = "Q", type = MENU})
	-- KS
	Menu.Skills.Q:MenuElement({name = "KS", id = "Killsteal", type = MENU})
	Menu.Skills.Q.Killsteal:MenuElement({id = "Enabled", name = "Enabled", value = false})
	-- Auto
	Menu.Skills.Q:MenuElement({name = "Auto", id = "Auto", type = MENU})
	Menu.Skills.Q.Auto:MenuElement({id = "Enabled", name = "Enabled", value = true})
	Menu.Skills.Q.Auto:MenuElement({id = "Collision", name = "Skip enemies that have minion collision", value = true})
	Menu.Skills.Q.Auto:MenuElement({name = "Use on:", id = "Useon", type = MENU})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.Q.Auto.Useon:MenuElement({id = hero.networkID, name = hero.charName, value = true})
		end
	end
	Menu.Skills.Q.Auto:MenuElement({id = "Accuracy", name = "Accuracy", value = 3, min = 1, max = 5, step = 1})
	-- Combo / Harass
	Menu.Skills.Q:MenuElement({name = "Combo / Harass", id = "ComHar", type = MENU})
	Menu.Skills.Q.ComHar:MenuElement({id = "Combo", name = "Combo", value = true})
	Menu.Skills.Q.ComHar:MenuElement({id = "Harass", name = "Harass", value = false})
	Menu.Skills.Q.ComHar:MenuElement({id = "Collision", name = "Skip enemies that have minion collision", value = true})
	Menu.Skills.Q.ComHar:MenuElement({name = "Use on:", id = "Useon", type = MENU})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.Q.ComHar.Useon:MenuElement({id = hero.networkID, name = hero.charName, value = true})
		end
	end
	Menu.Skills.Q.ComHar:MenuElement({id = "Accuracy", name = "Accuracy", value = 2, min = 1, max = 5, step = 1})

	-- W
	Menu.Skills:MenuElement({name = "[W] Tormented Soil", id = "W", type = MENU})
	-- KS
	Menu.Skills.W:MenuElement({name = "KS", id = "Killsteal", type = MENU})
	Menu.Skills.W.Killsteal:MenuElement({id = "Enabled", name = "Enabled", value = false})
	-- Auto
	Menu.Skills.W:MenuElement({name = "Auto", id = "Auto", type = MENU})
	Menu.Skills.W.Auto:MenuElement({id = "Enabled", name = "Enabled", value = true})
	Menu.Skills.W.Auto:MenuElement({id = "Slow", name = "Slow", value = false})
	Menu.Skills.W.Auto:MenuElement({id = "Immobile", name = "Immobile", value = true})
	Menu.Skills.W.Auto:MenuElement(
		{id = "Time", name = "Minimum milliseconds", value = 500, min = 250, max = 2000, step = 50}
	)
	Menu.Skills.W.Auto:MenuElement({name = "Use on:", id = "Useon", type = MENU})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.W.Auto.Useon:MenuElement({id = hero.networkID, name = hero.charName, value = true})
		end
	end
	-- Combo / Harass
	Menu.Skills.W:MenuElement({name = "Combo / Harass", id = "ComHar", type = MENU})
	Menu.Skills.W.ComHar:MenuElement({id = "Combo", name = "Use W Combo", value = true})
	Menu.Skills.W.ComHar:MenuElement({id = "Harass", name = "Use W Harass", value = false})
	-- Clear
	Menu.Skills.W:MenuElement({name = "Clear", id = "Clear", type = MENU})
	Menu.Skills.W.Clear:MenuElement({id = "Enabled", name = "Enbaled", value = true})
	Menu.Skills.W.Clear:MenuElement({id = "Xminions", name = "Min minions W Clear", value = 3, min = 1, max = 5, step = 1})

	-- E
	Menu.Skills:MenuElement({name = "[E] Black Shield", id = "E", type = MENU})
	-- Auto
	Menu.Skills.E:MenuElement({name = "Auto", id = "Auto", type = MENU})
	Menu.Skills.E.Auto:MenuElement({id = "Enabled", name = "Enabled", value = true})
	Menu.Skills.E.Auto:MenuElement({id = "OnCC", name = "Use only on incoming CC", value = true})
	Menu.Skills.E.Auto:MenuElement({id = "Ally", name = "Use on ally", value = true})
	Menu.Skills.E.Auto:MenuElement({id = "Selfish", name = "Use on yourself", value = true})
	Menu.Skills.E.Auto:MenuElement(
		{id = "BlockDmg", name = "Min Dmg to block", value = 200, min = 0, max = 500, step = 25}
	)

	--R
	Menu.Skills:MenuElement({name = "[R] Soul Shackles", id = "R", type = MENU})
	-- KS
	Menu.Skills.R:MenuElement({name = "KS", id = "Killsteal", type = MENU})
	Menu.Skills.R.Killsteal:MenuElement({id = "Enabled", name = "Enabled", value = false})
	-- Auto
	Menu.Skills.R:MenuElement({name = "Auto", id = "Auto", type = MENU})
	Menu.Skills.R.Auto:MenuElement({id = "Enabled", name = "Enabled", value = true})
	Menu.Skills.R.Auto:MenuElement(
		{id = "Xenemies", name = ">= X enemies near morgana", value = 2, min = 1, max = 5, step = 1}
	)
	Menu.Skills.R.Auto:MenuElement(
		{id = "Xrange", name = "< X distance enemies to morgana", value = 400, min = 100, max = Q.Range, step = 25}
	)
	-- Combo / Harass
	Menu.Skills.R:MenuElement({name = "Combo / Harass", id = "ComHar", type = MENU})
	Menu.Skills.R.ComHar:MenuElement({id = "Combo", name = "Use R Combo", value = true})
	Menu.Skills.R.ComHar:MenuElement({id = "Harass", name = "Use R Harass", value = false})
	Menu.Skills.R.ComHar:MenuElement(
		{id = "Xenemies", name = ">= X enemies near morgana", value = 2, min = 1, max = 4, step = 1}
	)
	Menu.Skills.R.ComHar:MenuElement(
		{id = "Xrange", name = "< X distance enemies to morgana", value = 400, min = 100, max = Q.Range, step = 25}
	)
end

function GetSlowTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.count > 0 and buff.duration > duration and buff.type == 10 then
			duration = buff.duration
		end
	end
	return duration
end

function GetImmobileTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if
			buff and buff.count > 0 and buff.duration > duration and
				(buff.type == 5 or buff.type == 11 or buff.type == 24 or buff.type == 29)
		 then
			if duration < buff.duration then
				duration = buff.duration
			end
		end
	end
	return duration
end

local NextTick = LocalGameTimer()
function Tick()
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end	
	if BlockSpells() then return end
	-- Q
	local target = GetTarget(Q.Range)
	if target and CanTarget(target) then
		if Ready(_Q) then
			-- KS
			if Menu.Skills.Q.Killsteal.Enabled:Value() then
				local qDmg = 25 + (myHero:GetSpellData(_Q).level) * 55 + myHero.ap * 0.9
				for i = 1, LocalGameHeroCount() do
					local target = LocalGameHero(i)
					if CanTarget(target) and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
						local castPosition, accuracy =
							LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
						if castPosition then
							local extraIncoming = LocalDamageManager:RecordedIncomingDamage(target)
							local predictedHealth = target.health + target.hpRegen * Q.Delay - extraIncoming
							qDmg = LocalDamageManager:CalculateMagicDamage(myHero, target, qDmg)
							if predictedHealth > 0 and qDmg > predictedHealth then
								NextTick = LocalGameTimer() + .25
								CastSpell(HK_Q, castPosition, true)
								return
							end
						end
					end
				end
			end
			-- Combo Harass
			if
				(_G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and Menu.Skills.Q.ComHar.Combo:Value()) or
					(_G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] and Menu.Skills.Q.ComHar.Harass:Value()) and
						Menu.Skills.Q.Auto.Useon[target.networkID]
			 then
				local accuracyRequired = Menu.Skills.Q.ComHar.Accuracy:Value()
				local castPosition, accuracy =
					LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
				if castPosition and accuracy >= accuracyRequired and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
					NextTick = LocalGameTimer() + .25
					CastSpell(HK_Q, castPosition)
					return
				end
			end
			-- Auto
			if Menu.Skills.Q.Auto.Enabled:Value() and Menu.Skills.Q.Auto.Useon[target.networkID] then
				local accuracyRequired = Menu.Skills.Q.Auto.Accuracy:Value()
				local castPosition, accuracy =
					LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
				if castPosition and accuracy >= accuracyRequired and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
					NextTick = LocalGameTimer() + .25
					CastSpell(HK_Q, castPosition)
					return
				end
			end
		end
	end
	-- W
	local target = GetTarget(W.Range)
	if target and CanTarget(target) then
		if Ready(_W) then
			-- KS
			if Menu.Skills.W.Killsteal.Enabled:Value() then
				local wDmg = 10 + (myHero:GetSpellData(_W).level) * 14 + myHero.ap * 0.22
				for i = 1, LocalGameHeroCount() do
					local target = LocalGameHero(i)
					if CanTarget(target) and LocalGeometry:IsInRange(myHero.pos, target.pos, W.Range) then
						local castPosition, accuracy =
							LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay, W.Speed, W.Radius, W.Collision, W.IsLine)
						if castPosition then
							local extraIncoming = LocalDamageManager:RecordedIncomingDamage(target)
							local predictedHealth = target.health + target.hpRegen * W.Delay - extraIncoming
							wDmg = LocalDamageManager:CalculateMagicDamage(myHero, target, wDmg)
							if predictedHealth > 0 and wDmg > predictedHealth then
								NextTick = LocalGameTimer() + .25
								CastSpell(HK_W, castPosition, true)
								return
							end
						end
					end
				end
			end
			-- Combo Harass
			if
				(_G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and Menu.Skills.W.ComHar.Combo:Value()) or
					(_G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] and Menu.Skills.W.ComHar.Harass:Value())
			 then
				local castPosition, accuracy =
					LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay, W.Speed, W.Radius, W.Collision, W.IsLine)
				if castPosition and LocalGeometry:IsInRange(myHero.pos, castPosition, W.Range) then
					NextTick = LocalGameTimer() + .25
					CastSpell(HK_W, castPosition)
					return
				end
			end
			-- Auto
			if Menu.Skills.W.Auto.Enabled:Value() and Menu.Skills.W.Auto.Useon[target.networkID] then
				local mSlow = Menu.Skills.W.Auto.Slow:Value()
				local mImmobile = Menu.Skills.W.Auto.Immobile:Value()
				local mTime = Menu.Skills.W.Auto.Time:Value() * 0.001
				local canW = (mImmobile and GetImmobileTime(target) > mTime) or (mSlow and GetSlowTime(target) > mTime)
				local castPosition, accuracy =
					LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay, W.Speed, W.Radius, W.Collision, W.IsLine)
				if canW and castPosition and LocalGeometry:IsInRange(myHero.pos, castPosition, W.Range) then
					NextTick = LocalGameTimer() + .25
					CastSpell(HK_W, castPosition)
					return
				end
			end
		end
	end
	-- E
	if Ready(_E) and Menu.Skills.E.Auto.Enabled:Value() and not Menu.Skills.E.Auto.OnCC:Value() then
		-- Auto
		for i = 1, LocalGameHeroCount() do
			local target = LocalGameHero(i)
			if CanTargetAlly(target) and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
				local incomingDamage = LocalDamageManager:RecordedIncomingDamage(target)
				if incomingDamage > Menu.Skills.E.Auto.BlockDmg:Value() then
					NextTick = LocalGameTimer() + .25
					CastSpell(HK_E, target.pos)
					return
				end
			end
		end
	end
	-- R
	if Ready(_R) then
		-- KS
		if Menu.Skills.R.Killsteal.Enabled:Value() then
			local rDmg = 75 + (myHero:GetSpellData(_R).level) * 75 + myHero.ap * 0.7
			for i = 1, LocalGameHeroCount() do
				local target = LocalGameHero(i)
				if CanTarget(target) and LocalGeometry:IsInRange(myHero.pos, target.pos, R.Range) then
					local extraIncoming = LocalDamageManager:RecordedIncomingDamage(target)
					local predictedHealth = target.health + target.hpRegen * R.Delay - extraIncoming
					rDmg = LocalDamageManager:CalculateMagicDamage(myHero, target, rDmg)
					if predictedHealth > 0 and rDmg > predictedHealth then
						NextTick = LocalGameTimer() + .25
						CastSpell(HK_R)
						return
					end
				end
			end
		end
		-- Combo / Harass
		if
			(_G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and Menu.Skills.W.ComHar.Combo:Value()) or
				(_G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] and Menu.Skills.W.ComHar.Harass:Value())
		 then
			if EnemyCount(myHero.pos, Menu.Skills.R.ComHar.Xrange:Value(), R.Delay) >= Menu.Skills.R.ComHar.Xenemies:Value() then
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_R)
				return
			end
		end
		-- Auto
		if Menu.Skills.R.Auto.Enabled:Value() then
			if EnemyCount(myHero.pos, Menu.Skills.R.Auto.Xrange:Value(), R.Delay) >= Menu.Skills.R.Auto.Xenemies:Value() then
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_R)
				return
			end
		end
	end

	NextTick = LocalGameTimer() + .1
end

function OnBlink(target)
	-- Ennemy
	if
		target.isEnemy and CanTarget(target) and Ready(_Q) and Menu.Skills.Q.Auto.Enabled:Value() and
			LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range)
	 then
		local castPosition, accuracy =
			LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision)
		if accuracy > 0 then
			CastSpell(HK_Q, castPosition, true)
		end
	end
end

function OnCC(target, damage, ccType)
	if Ready(_E) then
		if target == myHero then
			CastSpell(HK_E, myHero.pos)
			return
		end
		-- Ally
		if target.isAlly and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
			local castPosition = mousePos
			if target ~= myHero then
				castPosition =
					LocalGeometry:PredictUnitPosition(target, E.Delay + LocalGeometry:GetDistance(myHero.pos, target.pos) / E.Speed)
			else
				local ally = NearestAlly(myHero.pos, E.Range)
				if ally then
					castPosition =
						LocalGeometry:PredictUnitPosition(ally, E.Delay + LocalGeometry:GetDistance(myHero.pos, ally.pos) / E.Speed)
				end
			end
			CastSpell(HK_E, castPosition)
			return
		end
	end
	-- Ennemy
	if target.isEnemy and CanTarget(target) then
		if Ready(_W) and CanTarget(target) and Menu.Skills.W.Auto.Enabled:Value() then
			if LocalDamageManager.IMMOBILE_TYPES[ccType] then
				if Menu.Skills.W.Auto.Immobile:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
					NextTick = LocalGameTimer() + .25
					CastSpell(HK_W, target.pos)
					return
				end
			elseif ccType == BUFF_SLOW then
				if Menu.Skills.W.Auto.Slow:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
					NextTick = LocalGameTimer() + .25
					CastSpell(HK_W, target.pos)
					return
				end
			end
		end
	end
end
