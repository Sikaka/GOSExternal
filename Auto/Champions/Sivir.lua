local Sivir = Class()
function Sivir:__init()
	self:GenerateMenu()
	Q = {	Range = 1250,	Delay = 0.25,	Speed = 1350,	Radius = 90, IsLine = true	}
	self.NextTick = GameTimer()
	self.Data = _G.SDK.Data
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)

	if _G.JustEvade then 
		_G.JustEvade:OnImpossibleDodge(function(dangerLevel)  self:ImpossibleDodge(dangerLevel) end)		
		print("Warning: JustEvade must have evade mode emabled for E to be used.")
	else
		print("JustEvade is not loaded. E will not be used.")
	end	
	_G.SDK.Orbwalker:OnPostAttack(function(args) self:OnPostAttack() end)
end

function Sivir:GenerateMenu()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})

	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Boomerang Blade", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Draw", name = "Draw Range", value = false, toggle = true })	
	Menu.Skills.Q:MenuElement({id = "Killsteal", name = "Killsteal", value = true, toggle = true })	
	Menu.Skills.Q:MenuElement({id = "AccuracyAuto", name = "Auto Accuracy Required", value = 3, drop = {"Low", "Normal", "High", "Dashing/Channeling", "Immobile", "Never"} })		
	Menu.Skills.Q:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy Required", value = 2, drop = {"Low", "Normal", "High", "Dashing/Channeling", "Immobile"} })
	Menu.Skills.Q:MenuElement({id = "Targets", name = "Auto: Allowed Target List", type = MENU})
	for i = 1, GameHeroCount() do
		local hero = GameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.Q.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true, toggle = true})
		end
	end

	Menu.Skills:MenuElement({id = "W", name = "[W] Ricochet", type = MENU})	
	Menu.Skills.W:MenuElement({id = "ManaAuto", name = "Auto: Mana for AA Reset", value = 30, min = 1, max = 101, step = 1 })
	Menu.Skills.W:MenuElement({id = "ManaCombo", name = "Combo: Mana for AA Reset", value = 10, min = 1, max = 101, step = 1 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Ricochet", type = MENU})
	Menu.Skills.E:MenuElement({id = "DangerAuto", name = "Auto: Cast on Danger Level", value = 4, min = 1, max = 6, step = 1 })
	Menu.Skills.E:MenuElement({id = "DangerCombo", name = "Combo: Cast on Danger Level", value = 1, min = 1, max = 6, step = 1 })			
end

function Sivir:ImpossibleDodge(danger)
	if not Ready(_E) then return end
	local eDangerRequired = ComboActive() and Menu.Skills.E.DangerCombo:Value() or Menu.Skills.E.DangerAuto:Value()
	if danger >= eDangerRequired then
		CastSpell(HK_E)
	end
end

function Sivir:OnPostAttack()
	if not Ready(_W) then return end
	if not myHero.activeSpell.target then return end
	local target = LocalObjectManager:GetHeroByHandle(myHero.activeSpell.target)
	if not target then return end

	local currentManaPct = CurrentPctMana(myHero)
	local minimumManaPct = ComboActive() and Menu.Skills.W.ManaCombo:Value() or Menu.Skills.W.ManaAuto:Value()
	if(currentManaPct >= minimumManaPct) then
		CastSpell(HK_W)
	end
end

function Sivir:Draw()
	--Draw Forced Target
	if Menu.Skills.Q.Draw:Value() then
		DrawCircle(myHero.Pos, self.Q.Range,1)
	end
end

function Sivir:Tick()
	--Cache the current game time for use in the combo logic
	self.CurrentGameTime = GameTimer()

	--Return if the script shouldn't be run
	if BlockSpells() then return end

	--If the script has set a next tick time (artificial delay) dont run logic!
	if self.NextTick > self.CurrentGameTime then return end

	if self:Q_Logic() then return end
end

function Sivir:Q_Logic()	
	if not Ready(_Q) then return false end

	local candidates = {}
	for i = 1, GameHeroCount() do
		local target = GameHero(i)
		if CanTarget(target) and (ComboActive() or Menu.Skills.Q.Targets[target.networkID]) then
			local targetData = self:Q_Targeting(target)
			if targetData and targetData.target then
				TableInsert(candidates, targetData)
			end
		end
	end
	--Order the table and select the best one.			
	TableSort(candidates, function (a,b) return a.target and (a.targetPriority > b.targetPriority or (a.targetPriority == b.targetPriority and a.targetCount > b.targetCount)) end)
	if #candidates > 0 and candidates[1].aimPosition then			
		CastSpell(HK_Q, candidates[1].aimPosition, true)
		self.NextTick = self.CurrentGameTime + .3
	end
end


function Sivir:Q_Targeting(target)
	local aimPosition, hitChance = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
	if aimPosition and LocalGeometry:IsInRange(myHero.pos, aimPosition, Q.Range) then
		local endPosition = myHero.pos + (aimPosition-myHero.pos):Normalized() * Q.Range						
		local targetCount = LocalGeometry:GetLineTargetCount(myHero.pos, endPosition, Q.Delay, Q.Speed, Q.Radius)
		local targetPriority = self.Data:GetHeroPriority(target.charName)

		if Menu.Skills.Q.Killsteal:Value() then
			local qDamage = LocalDamageManager:CalculateDamage(myHero, target, "SivirQ")
			local incomingDmg =LocalDamageManager:RecordedIncomingDamage(target)			
			if incomingDmg < target.health and incomingDmg +  qDamage >= target.health and Menu.Skills.Q.Killsteal:Value() then								
				return {target = target, killsteal = true, targetPriority = 6, targetCount = targetCount, accuracy = hitChance, aimPosition = aimPosition}
			end
		end

		if hitChance >= (ComboActive() and Menu.Skills.Q.AccuracyCombo:Value() or Menu.Skills.Q.AccuracyAuto:Value()) then								
			return {target = target, targetPriority = targetPriority, targetCount = targetCount, accuracy = hitChance, aimPosition = aimPosition}
		end
	end
	--Not valid. Return empty collection
	return {}
end


function LoadScript()
	Sivir()
end