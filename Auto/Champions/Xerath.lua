Q = {	Range = 750,	Delay = 0.35,	Speed = 999999,	Radius = 145	}
W = {	Range = 1050,	Delay = 0.5,	Speed = 999999,	Radius = 200	}
E = {	Range = 1100,	Delay = 0.25,	Speed = 1400,	Radius = 80, Collision = true,	IsLine = true	}
R = {	Range = 5000,	Delay = 0.627,	Speed = 999999,	Radius = 140	}

local Xerath = Class()
function Xerath:__init()
	self:GenerateMenu()

	--Set internal variables for champ logic
	self.QData = { StartTime = 0, IsCharging = false, Range = 700, ChargeDuration = 0}	
	self.RCount = 0
	self.RNextCast = GameTimer()
	self.NextTick = GameTimer()
	self.TargetExpiresAt = GameTimer()
	self.Data = _G.SDK.Data

	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	LocalObjectManager:OnSpellCast(function(spell) self:OnSpellCast(spell) end)
	Callback.Add("WndMsg",function(Msg, Key) self:WndMsg(Msg, Key) end)
end

function Xerath:GenerateMenu()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})

	--Global settings like target switch frequency
	Menu:MenuElement({id = "Settings", name = "Settings", type = MENU})
	Menu.Settings:MenuElement({id = "TargetFrequency", name = "Switch Target Frequency", value = 3000, min = 500, max = 10000, step = 250 })
	Menu.Settings:MenuElement({id = "TargetingMode", name = "Target Mode", drop = {"Priority List", "Selected Target Only"}})

	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Arcanopulse", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Killsteal", name = "Killsteal", value = true, toggle = true })	
	Menu.Skills.Q:MenuElement({id = "Mode", name = "Targeting Mode", drop = {"All Allowed Targets", "Selected Target Only"}})
	Menu.Skills.Q:MenuElement({id = "AccuracyAuto", name = "Auto: Release Accuracy", value = 3, drop = {"Low", "Normal", "High", "Dashing/Channeling", "Immobile", "Never"} })	
	Menu.Skills.Q:MenuElement({id = "TargetCount", name = "Auto: Release # Enemies (Uses Combo Accuracy)", value = 2, min = 1, max = 6, step = 1 })
	Menu.Skills.Q:MenuElement({id = "AccuracyCombo", name = "Combo: Release Accuracy", value = 2, drop = {"Low", "Normal", "High", "Dashing/Channeling", "Immobile"} })	
	Menu.Skills.Q:MenuElement({id = "Targets", name = "Priority List (Release Before Full Charge)", type = MENU})
	for i = 1, GameHeroCount() do
		local hero = GameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.Q.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true, toggle = true})
		end
	end

	Menu.Skills:MenuElement({id = "W", name = "[W] Eye of Destruction", type = MENU})
	Menu.Skills.W:MenuElement({id = "Killsteal", name = "Killsteal", value = true, toggle = true })	
	Menu.Skills.W:MenuElement({id = "AccuracyAuto", name = "Assist Accuracy", value = 4, drop = {"Low", "Normal", "High", "Dashing/Channeling", "Immobile", "Never"} })
	Menu.Skills.W:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy", value = 2, drop = {"Low", "Normal", "High", "Dashing/Channeling", "Immobile"} })
	Menu.Skills.W:MenuElement({id = "TargetCount", name = "Target # Enemies", value = 2, min = 1, max = 6, step = 1 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Shocking Orb", type = MENU})
	Menu.Skills.E:MenuElement({id = "AccuracyAuto", name = "Assist Accuracy", value = 4, drop = {"Low", "Normal", "High", "Dashing/Channeling", "Immobile", "Never"} })	
	Menu.Skills.E:MenuElement({id = "PeelRadius", name = "Auto: Peel Radius (Use Combo Accuracy)", value = 400, min = 100, max = 1500, step = 50 })
	Menu.Skills.E:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy", value = 2, drop = {"Low", "Normal", "High", "Dashing/Channeling", "Immobile"} })
			
	Menu.Skills:MenuElement({id = "R", name = "[R] Rite of the Arcane", type = MENU})
	Menu.Skills.R:MenuElement({id = "Frequency", name = "Cast Frequency", value = .9, min =.25, max = 3, step = .25 })
	Menu.Skills.R:MenuElement({id = "Randomization", name = "Cast Randomization", value = .2, min =.1, max = 1, step = .1 })
	Menu.Skills.R:MenuElement({id = "Auto", name = "Auto Cast", value = true })
	Menu.Skills.R:MenuElement({id = "Count", name = "Focus # Enemies", value = 2, min = 1, max = 6, step = 1 })
	Menu.Skills.R:MenuElement({id = "Accuracy", name = "Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.R:MenuElement({id = "Killsteal", name = "Killsteal", value = true })
	Menu.Skills.R:MenuElement({id = "Assist", name = "Assist Key",value = false,  key = 0x73})
	Menu.Skills.R:MenuElement({id = "Targets", name = "Target List", type = MENU})
	for i = 1, GameHeroCount() do
		local hero = GameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.R.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true, toggle = true})
		end
	end
end


function Xerath:OnSpellCast(spell)
	if spell.owner == myHero.networkID then
		if spell.data.name == "XerathArcanopulseChargeUp" then
			self.QData.StartTime = GameTimer()
			self.QData.IsCharging = true
			self.QData.Range = 700
			self.QData.ChargeDuration = 0
		elseif spell.data.name == "XerathLocusOfPower2" then
			local rData = myHero:GetSpellData(_R)
			self.RCount = 2 + rData.level
		end
	end
end


function Xerath:Draw()
	--Draw Forced Target
	if self.ForcedTarget and Menu.Settings.TargetingMode:Value() == 2 then
		DrawCircle(self.ForcedTarget, 100, 1)
	end
end

function Xerath:Tick()
	--Cache the current game time for use in the combo logic
	self.CurrentGameTime = GameTimer()

	--Return if the script shouldn't be run
	if BlockSpells() then return end

	--If the script has set a next tick time (artificial delay) dont run logic!
	if self.NextTick > self.CurrentGameTime then return end

	--Check if we should un-lock our current target.
		--Dead, untargetable, lost vision, too long since last spell cast on them, etc
	self:CheckRetargetTimeout()

	_G.GOS.BlockAttack = not self:IsRActive() or not self:IsQActive()
	_G.GOS.BlockMovement =not self:IsRActive()

	--Run skill logic in order of priority. If logic returns true (action taken) then cancel the rest of the logic early!
	if self:E_Peel() then return end
	if self:Q_Logic() then return end
	if self:R_Logic() then return end
	if self:E_Logic() then return end
	if self:W_Logic() then return end
end

function Xerath:CheckRetargetTimeout()
	
	--Handle nulling out out current target if the last spell cast at them was too long ago.
	if Menu.Settings.TargetingMode:Value() == 2 then return end

	--We are NOT forcibly locked on a target. We can now check if the target is able to be deleted.
	if self.ForcedTarget then
		--Note: This will untarget if we lose visibility... this may be a problem.
		if not CanTarget(self.ForcedTarget) then self.ForcedTarget = nil return end
		--We targeted them too long ago. Clear the target
		if self.CurrentGameTime > self.TargetExpiresAt then self.ForcedTarget = nil return end
	end
end

function Xerath:SetDynamicForcedTarget(target, delay)
	if not target then return end
	self.ForcedTarget = target
	self.TargetExpiresAt = self.CurrentGameTime + Menu.Settings.TargetFrequency:Value()
	self.NextTick = self.CurrentGameTime + (delay or .25)
end

function Xerath:Q_Logic()
	self:Q_Update()
	if self.QData.IsCharging then
		--We dont have a target. Try to find the best candidate to release Q on.
		if not self.ForcedTarget then
			local candidates = {}
			for i = 1, GameHeroCount() do
				local target = GameHero(i)
				if CanTarget(target) and Menu.Skills.Q.Targets[target.networkID]:Value() then
					local targetData = self:Q_Targeting(target)
					if targetData and targetData.target then
						TableInsert(candidates, targetData)
					end
				end
			end
			--Order the table and select the best one.			
			TableSort(candidates, function (a,b) return a.target and (a.targetPriority > b.targetPriority or (a.targetPriority == b.targetPriority and a.accuracy > b.accuracy)) end)
			if #candidates > 0 then			
				CastSpell(HK_Q, candidates[1].aimPosition, true)
				self:SetDynamicForcedTarget(candidates[1].target, .3)
			end
		elseif self.ForcedTarget and CanTarget(self.ForcedTarget) then			
			local targetData = self:Q_Targeting(self.ForcedTarget)
			if targetData and targetData.target then		
				CastSpell(HK_Q, targetData.aimPosition, true)
				self:SetDynamicForcedTarget(targetData.target, .3)
			end
		end
		return true
	elseif ComboActive() and Ready(_Q) then
		local candidates = {}
		for i = 1, GameHeroCount() do
			local target = GameHero(i)
			if CanTarget(target) and Menu.Skills.Q.Targets[target.networkID]:Value() then
				local targetData = self:Q_Targeting(target)
				if targetData and targetData.target then
					TableInsert(candidates, targetData)
				end
			end
		end
		--Order the table and select the best one.			
		TableSort(candidates, function (a,b) return a.target and (a.targetPriority > b.targetPriority or (a.targetPriority == b.targetPriority and a.accuracy > b.accuracy)) end)
		if #candidates > 0 then			
			CastSpell(HK_Q, candidates[1].aimPosition, true)
			self:SetDynamicForcedTarget(candidates[1].target, .3)
		end
	end
end

function Xerath:Q_Update()
	if self.QData.IsCharging then
		if not self:IsQActive() then
			self.QData.IsCharging = false
			self.QData.Range = 700		
		else
			self.QData.ChargeDuration = MathMin(self.CurrentGameTime - self.QData.StartTime, 2)
			self.QData.Range = 700 + 500 * self.QData.ChargeDuration
		end
	end
end

function Xerath:Q_Targeting(target)
	local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, self.QData.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
	if aimPosition and LocalGeometry:IsInRange(myHero.pos, aimPosition, self.QData.Range - 150) then
		local endPosition = myHero.pos + (aimPosition-myHero.pos):Normalized() * self.QData.Range						
		local targetCount = LocalGeometry:GetLineTargetCount(myHero.pos, endPosition, Q.Delay, Q.Speed, Q.Radius)
		local qDamage = LocalDamageManager:CalculateDamage(myHero, target, "XerathArcanopulseChargeUp")
		local incomingDmg =LocalDamageManager:RecordedIncomingDamage(target)
		local targetPriority = self.Data:GetHeroPriority(target.charName)

		if incomingDmg < target.health and incomingDmg +  qDamage >= target.health and Menu.Skills.Q.Killsteal:Value() then								
			return {target = target, killsteal = true, targetPriority = 6, targetCount = targetCount, accuracy = hitChance, aimPosition = aimPosition}
		elseif Menu.Skills.Q.Targets[target.networkID]:Value() or self.QData.ChargeDuration > 1.75 then
			if hitChance >= (ComboActive() and Menu.Skills.Q.AccuracyCombo:Value() or Menu.Skills.Q.AccuracyAuto:Value()) then								
				return {target = target, targetPriority = targetPriority, targetCount = targetCount, accuracy = hitChance, aimPosition = aimPosition}
			elseif targetCount >= Menu.Skills.Q.TargetCount:Value() then
				return {target = target, targetPriority = targetPriority, targetCount = targetCount, accuracy = hitChance, aimPosition = aimPosition}
			end
		end
	end
	--Not valid. Return empty collection
	return {}
end

function Xerath:W_Logic()
	if not Ready(_W) then return false end
	
	if not self.ForcedTarget then
		local candidates = {}
		for i = 1, GameHeroCount() do
			local target = GameHero(i)
			if CanTarget(target) then
				local targetData = self:W_Targeting(target)
				if targetData and targetData.target then
					TableInsert(candidates, targetData)
				end
			end
		end
		--Order the table and select the best one.			
		TableSort(candidates, function (a,b) return a.target and (a.targetPriority > b.targetPriority or (a.targetPriority == b.targetPriority and a.accuracy > b.accuracy)) end)			
		if #candidates > 0 then
			CastSpell(HK_W, candidates[1].aimPosition, true)
			self:SetDynamicForcedTarget(candidates[1].target, .3)
			return true
		end
	elseif self.ForcedTarget and CanTarget(self.ForcedTarget) then			
		local targetData = self:W_Targeting(self.ForcedTarget)
		if targetData and targetData.target then		
			CastSpell(HK_W, targetData.aimPosition, true)
			self:SetDynamicForcedTarget(targetData.target, .3)
			return true
		end
	end
end

function Xerath:W_Targeting(target)	
	local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay, W.Speed, W.Radius, W.Collision, W.IsLine)
	if aimPosition and LocalGeometry:IsInRange(myHero.pos, aimPosition, W.Range) then
		local targetCount = EnemyCount(aimPosition, W.Radius, W.Delay)
		local targetPriority = self.Data:GetHeroPriority(target.charName)
		if Menu.Skills.W.Killsteal:Value() then
			local wDamage = LocalDamageManager:CalculateDamage(myHero, target, "XerathArcaneBarrage2")
			local incomingDmg =LocalDamageManager:RecordedIncomingDamage(target)

			if incomingDmg < target.health and incomingDmg + wDamage >= target.health then
				return {target = target, killsteal = true, targetPriority = 6, targetCount = targetCount, accuracy = hitChance, aimPosition = aimPosition}
			end
		end

		if (hitChance >= Menu.Skills.W.AccuracyAuto:Value()) or (ComboActive() and hitChance >= Menu.Skills.W.AccuracyCombo:Value()) then
			return {target = target, targetPriority = targetPriority, targetCount = targetCount, accuracy = hitChance, aimPosition = aimPosition}
		elseif hitChance >= Menu.Skills.W.AccuracyCombo:Value() and targetCount >= Menu.Skills.W.TargetCount:Value()then
			return {target = target, targetPriority = targetPriority, targetCount = targetCount, accuracy = hitChance, aimPosition = aimPosition}
		end
	end
	return {}
end

function Xerath:E_Logic()
	if not Ready(_E) then return false end
	if not self.ForcedTarget then
		local candidates = {}
		for i = 1, GameHeroCount() do
			local target = GameHero(i)
			if CanTarget(target) then
				local targetData = self:E_Targeting(target)
				if targetData and targetData.target then
					TableInsert(candidates, targetData)
				end
			end
		end
		--Order the table and select the best one.
		TableSort(candidates, function (a,b) return a.target and (a.targetPriority > b.targetPriority or (a.targetPriority == b.targetPriority and a.accuracy > b.accuracy)) end)
		if #candidates > 0 then
			CastSpell(HK_E, candidates[1].aimPosition, true)
			self:SetDynamicForcedTarget(candidates[1].target, .25)
			return true
		end
	elseif self.ForcedTarget and CanTarget(self.ForcedTarget) then			
		local targetData = self:E_Targeting(self.ForcedTarget)
		if targetData and targetData.target then		
			CastSpell(HK_E, targetData.aimPosition, true)
			self:SetDynamicForcedTarget(targetData.target, .25)
			return true
		end
	end
end

function Xerath:E_Peel()
	if not Ready(_E) or self:IsQActive() or self:IsRActive() then return end
	--Handle peeling enemies that come too close to self/allies by using E. We will ignore forced target for the duration
	--This bypasses all locked target checks to try to peel with more reliability
	for i = 1, GameHeroCount() do
		local target = GameHero(i)
		if target and CanTarget(target) and LocalGeometry:GetDistance(myHero.pos, target.pos) <= Menu.Skills.E.PeelRadius:Value() then			
			local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay, E.Speed, E.Radius, E.Collision, E.IsLine)
			if aimPosition and LocalGeometry:IsInRange(myHero.pos, aimPosition, E.Range)  then
				if (hitChance >= Menu.Skills.E.AccuracyAuto:Value()) or (ComboActive() and hitChance >= Menu.Skills.E.AccuracyCombo:Value()) then
					CastSpell(HK_E, aimPosition, true)					
					self.NextTick = self.CurrentGameTime + .25
				end
			end
		end
	end
end

function Xerath:E_Targeting(target)	
	local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay, E.Speed, E.Radius, E.Collision, E.IsLine)
	if aimPosition and LocalGeometry:IsInRange(myHero.pos, aimPosition, E.Range) then
		local targetPriority = self.Data:GetHeroPriority(target.charName)
		if (hitChance >= Menu.Skills.E.AccuracyAuto:Value()) or (ComboActive() and hitChance >= Menu.Skills.E.AccuracyCombo:Value()) then
			return {target = target, targetPriority = targetPriority, targetCount = 1, accuracy = hitChance, aimPosition = aimPosition}		
		end
	end
	return {}
end

function Xerath:R_Logic()
	--Assist key logic
	if self:R_Assist() then return end

	if self:IsRActive() then
		--Dont run auto logic if script has delayed it
		if self.RNextCast > self.CurrentGameTime then return true end

		--We dont have a target. Try to find the best candidate to release Q on.
		if not self.ForcedTarget then
			local candidates = {}
			for i = 1, GameHeroCount() do
				local target = GameHero(i)
				if CanTarget(target) and Menu.Skills.R.Targets[target.networkID]:Value() then
					local targetData = self:R_Targeting(target)
					if targetData and targetData.target then
						TableInsert(candidates, targetData)
					end
				end
			end
			--Order the table and select the best one.			
			TableSort(candidates, function (a,b) return a.target and (a.targetPriority > b.targetPriority or (a.targetPriority == b.targetPriority and a.accuracy > b.accuracy)) end)
			if #candidates > 0 then				
				self:R_Cast(candidates[1])
			end

		elseif self.ForcedTarget and CanTarget(self.ForcedTarget) then			
			local targetData = self:R_Targeting(self.ForcedTarget)
			if targetData and targetData.target then				
				self:R_Cast(targetData)
			end
		end
		return true
	else
		--Check if we should start casting R (combo)
	end
end

function Xerath:R_Assist()
	if not Menu.Skills.R.Assist:Value() then return false end
		
	if not self:IsRActive() then
		--Handle activation if it's possible
		return false
	end

	local candidates = {}
	for i  = 1,GameHeroCount(i) do
		local target = GameHero(i)	
		if CanTarget(target) then
			local distance = LocalGeometry:GetDistance(mousePos, target.pos)
			if distance < 500 then
				local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, R.Range, R.Delay, R.Speed, R.Radius, R.Collision, R.IsLine)
				if aimPosition and hitChance > 0 and LocalGeometry:IsInRange(myHero.pos, aimPosition, R.Range) then
					local targetCount = EnemyCount(aimPosition, R.Radius, R.Delay)
					local targetPriority = self.Data:GetHeroPriority(target.charName)
					TableInsert(candidates, {target = target, targetPriority = targetPriority, targetCount = targetCount, accuracy = hitChance, aimPosition = aimPosition})
				end
			end
		end
	end

	--Pull the best target and cast
	if #candidates > 0 then
		TableSort(candidates, function (a,b) return a.target and (a.targetPriority > b.targetPriority or (a.targetPriority == b.targetPriority and a.accuracy > b.accuracy)) end)
		self:R_Cast(candidates[1])
		return true
	end
end

function Xerath:R_Cast(targetData)
	CastSpell(HK_R, targetData.aimPosition, true)	
	self:SetDynamicForcedTarget(targetData.target)
	self.RCount = self.RCount - 1
	self.RNextCast = self.CurrentGameTime + Menu.Skills.R.Frequency:Value() + MathRandom(0,Menu.Skills.R.Randomization:Value())
end

function Xerath:R_Targeting(target)
	local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, R.Range, R.Delay, R.Speed, R.Radius, R.Collision, R.IsLine)
	if aimPosition and LocalGeometry:IsInRange(myHero.pos, aimPosition, R.Range) then
		local targetCount = EnemyCount(aimPosition, R.Radius, R.Delay)

		local targetPriority = self.Data:GetHeroPriority(target.charName)
		if Menu.Skills.R.Killsteal:Value() then
			local rDamage = LocalDamageManager:CalculateDamage(myHero, target, "XerathLocusOfPower2") * self.RCount * .5
			local incomingDmg =LocalDamageManager:RecordedIncomingDamage(target)

			if incomingDmg < target.health and incomingDmg + rDamage >= target.health then
				return {target = target, killsteal = true, targetPriority = 6, targetCount = targetCount, accuracy = hitChance, aimPosition = aimPosition}
			end
		end

		if Menu.Skills.R.Targets[target.networkID]:Value() then
			if (Menu.Skills.R.Auto:Value() or ComboActive()) and hitChance >= Menu.Skills.R.Accuracy:Value()  then
				return {target = target, targetPriority = targetPriority, targetCount = targetCount, accuracy = hitChance, aimPosition = aimPosition}
			elseif targetCount >= Menu.Skills.R.Count:Value() then
				return {target = target, targetPriority = targetPriority, targetCount = targetCount, accuracy = hitChance, aimPosition = aimPosition}
			end
		end
	end
	return {}
end


--Set forced target when clicking on the enemy
function Xerath:WndMsg(msg,key)	
	if Menu.Settings.TargetingMode:Value() ~= 2 then return end
	if msg == 513 then
		local candidates = {}
		for i  = 1,GameHeroCount(i) do
			local enemy = GameHero(i)	
			if enemy.alive and enemy.isEnemy  then
				local distance = LocalGeometry:GetDistance(mousePos, enemy.pos)
				if distance < 250 then
					TableInsert(candidates, {target = enemy, distance = distance})
				end
			end
		end

		if #candidates == 0 then
			self.ForcedTarget = nil
		else
			TableSort(candidates, function (a,b) return a.target and  a.distance < b.distance end)
			self.ForcedTarget = candidates[1].target
		end
	end
end


function Xerath:IsQActive()
	return myHero.activeSpell and myHero.activeSpell.valid and myHero.activeSpell.name == "XerathArcanopulseChargeUp"
end

function Xerath:IsRActive()	
	return myHero.activeSpell and myHero.activeSpell.valid and myHero.activeSpell.name == "XerathLocusOfPower2" 
end




function LoadScript()
	Xerath()
end