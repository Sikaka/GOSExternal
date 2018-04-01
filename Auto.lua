local NextSpellCast = Game.Timer()
local _allyHealthPercentage = {}
local _allyHealthUpdateRate = 1
local Heroes = {"Nami","Brand", "Zilean", "Soraka", "Lux", "Blitzcrank","Lulu", "MissFortune","Karthus"}
local _adcHeroes = { "Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "Jhin", "Jinx", "Kalista", "KogMaw", "Lucian", "MissFortune", "Quinn", "Sivir", "Teemo", "Tristana", "Twitch", "Varus", "Vayne", "Xayah"}
if not table.contains(Heroes, myHero.charName) then print("Hero not supported: " .. myHero.charName) return end

local Scriptname,Version,Author,LVersion = "[Auto]","v2.0","Sikaka","0.01"

Callback.Add("Load",
function()	

	--Load from common folder OR let us use it if its already activated as its own script
	if FileExist(COMMON_PATH .. "HPred.lua") then
		require 'HPred'
	else
		HPred()
	end	
	
	--Set up the initial menu for drawing and reaction time
	Menu = MenuElement({type = MENU, id = myHero.charName, name = "[Auto] "..myHero.charName})	
	Menu:MenuElement({id = "General", name = "General", type = MENU})
	Menu.General:MenuElement({id = "DrawQ", name = "Draw Q Range", value = false})
	Menu.General:MenuElement({id = "DrawW", name = "Draw W Range", value = false})
	Menu.General:MenuElement({id = "DrawE", name = "Draw E Range", value = false})
	Menu.General:MenuElement({id = "DrawR", name = "Draw R Range", value = false})
	Menu.General:MenuElement({id = "AutoInTurret", name = "Auto Cast While In Enemy Turret Range", value = true})
	Menu.General:MenuElement({id = "SkillFrequency", name = "Skill Frequency", value = .3, min = .1, max = 1, step = .1})
	Menu.General:MenuElement({id = "ReactionTime", name = "Reaction Time", value = .5, min = .1, max = 1, step = .1})
	Callback.Add("Draw", function() CoreDraw() end)
	Callback.Add("WndMsg",function(Msg, Key) WndMsg(Msg, Key) end)
end)


function WndMsg(msg,key)
	if msg == 513 then
		local starget = nil
		local dist = 250
		for i  = 1,Game.HeroCount(i) do
			local enemy = Game.Hero(i)
			if enemy.alive and enemy.isEnemy and HPred:GetDistance(mousePos, enemy.pos) < dist then
				starget = enemy
				dist = HPred:GetDistance(mousePos, enemy.pos)
			end
		end
		if starget then
			forcedTarget = starget
		else
			forcedTarget = nil
		end
	end	
end

local isLoaded = false
function TryLoad()
	if Game.Timer() < 30 then return end
	isLoaded = true	
	_G[myHero.charName]() 
	AutoUtil()
end

--Global draw function to be called from scripts to handle drawing spells and dashes - reduces duplicate code
function CoreDraw()
	if not isLoaded then
		TryLoad()
		return
	end
	if Q and Q.Range and KnowsSpell(_Q) and Menu.General.DrawQ:Value() then
		Draw.Circle(myHero.pos, Q.Range, Draw.Color(150, 255, 0,0))
	end	
	if W and W.Range and KnowsSpell(_W) and Menu.General.DrawW:Value() then
		Draw.Circle(myHero.pos, W.Range, Draw.Color(150, 0, 255,0))
	end	
	if E and E.Range and  KnowsSpell(_E) and Menu.General.DrawE:Value() then
		Draw.Circle(myHero.pos, E.Range, Draw.Color(150, 0, 0,255))
	end		
	if R and R.Range and KnowsSpell(_R) and Menu.General.DrawR:Value() then
		Draw.Circle(myHero.pos, R.Range, Draw.Color(150, 0, 255,255))
	end
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)    
		if Hero.isEnemy and Hero.pathing.hasMovePath and Hero.pathing.isDashing and Hero.pathing.dashSpeed>500 then
			Draw.Circle(Hero:GetPath(1), 40, 20, Draw.Color(255, 255, 255, 255))
		end
	end
end

function SetMovement(bool)
	if _G.EOWLoaded then
		EOW:SetMovements(bool)
		EOW:SetAttacks(bool)
	elseif _G.SDK then
		_G.SDK.Orbwalker:SetMovement(bool)
		_G.SDK.Orbwalker:SetAttack(bool)
	else
		GOS.BlockMovement = not bool
		GOS.BlockAttack = not bool
	end
end

function IsEvading()
    if ExtLibEvade and ExtLibEvade.Evading then return true end
	return false
end

function IsAttacking()
	if myHero.attackData and myHero.attackData.target and myHero.attackData.state == STATE_WINDUP then return true end
	return false
end

function SpecialCast(key, pos)
	if not Menu.General.AutoInTurret:Value() and InsideEnemyTurretRange() then return end	
	if NextSpellCast > Game.Timer() then return end	
	if pos and pos.x and not pos:To2D().onScreen then return end
	if  _G.SDK and _G.Control then
		_G.Control.CastSpell(key, pos)
	else
		Control.CastSpell(key, pos)
	end	
	NextSpellCast = Menu.General.SkillFrequency:Value() + Game.Timer()
end
 	
function KnowsSpell(spell)
	local spellInfo = myHero:GetSpellData(spell)
	if spellInfo and spellInfo.level > 0 then
		return true
	end
	return false
end
	
function CurrentPctLife(entity)
	local pctLife =  entity.health/entity.maxHealth  * 100
	return pctLife
end

function CurrentPctMana(entity)
	local pctMana =  entity.mana/entity.maxMana * 100
	return pctMana
end

function GetHeroByHandle(handle)	
	for ei = 1, Game.HeroCount() do
		local Enemy = Game.Hero(ei)
		if Enemy.isEnemy and Enemy.handle == handle then
			return Enemy
		end
	end
end
 
function Ready(spellSlot)
	return Game.CanUseSpell(spellSlot) == 0
end

function IsRecalling()
	for K, Buff in pairs(GetBuffs(myHero)) do
		if Buff.name == "recall" and Buff.duration > 0 then
			return true
		end
	end
	return false
end


function InsideEnemyTurretRange()
	for i = 1, Game.TurretCount() do
		local turret = Game.Turret(i)
		local range = (turret.boundingRadius + 750 + myHero.boundingRadius / 2)
		if turret.isEnemy and HPred:GetDistance(turret.pos, myHero.pos) <=range then
			return true
		end
	end
end
function UpdateAllyHealth()
	local deltaTick = Game.Timer() - _allyHealthUpdateRate	
	if deltaTick >= 1 then	
		 _allyHealthPercentage = {}
		_allyHealthUpdateRate = Game.Timer()
		for i = 1, Game.HeroCount() do
			local Hero = Game.Hero(i)
			if Hero.isAlly and Hero.alive then	
				_allyHealthPercentage[Hero.charName] = CurrentPctLife(Hero)				
			end
		end		
	end	
end

	
class "AutoUtil"

function AutoUtil:FindEnemyWithBuff(buffName, range, stackCount)
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)    
		if Hero.isEnemy and AutoUtil:GetDistance(myHero.pos, Hero.pos) <= range then
			for bi = 1, Hero.buffCount do 
			local Buff = Hero:GetBuff(bi)
				if Buff.name == buffName and Buff.duration > 0 and Buff.count >= stackCount then
					return Hero
				end
			end
		end
	end
end

function AutoUtil:__init()
	itemKey = {}
	_ccNames = 
	{
		["Cripple"] = 3,
		["Stun"] = 5,
		["Silence"] = 7,
		["Taunt"] = 8,
		["Polymorph"] = 9,
		["Slow"] = 10,
		["Snare"] = 11,
		["Sleep"] = 18,
		["Nearsight"] = 19,
		["Fear"] = 21,
		["Charm"] = 22,
		["Poison"] = 23,
		["Suppression"] = 24,
		["Blind"] = 25,
		-- ["Shred"] = 27,
		["Flee"] = 28,
		-- ["Knockup"] = 29,
		["Airborne"] = 30,
		["Disarm"] = 31
	}
end

function AutoUtil:SupportMenu(Menu)			
	---[ITEM SETTINGS]---
	Menu:MenuElement({id = "Items", name = "Item Settings", type = MENU})	
	
	---[LOCKET SETTINGS]---
	Menu.Items:MenuElement({id = "Locket", name = "Locket", type = MENU})
	Menu.Items.Locket:MenuElement({id = "Threshold", tooltip = "How much damage allies received in last second", name = "Ally Damage Threshold", value = 15, min = 1, max = 80, step = 1 })
	Menu.Items.Locket:MenuElement({id="Count", tooltip = "How many allies must have been injured in last second to cast", name = "Ally Count", value = 3, min = 1, max = 5, step = 1 })
	Menu.Items.Locket:MenuElement({id="Enabled", name="Enabled", value = true})
	
	---[CRUCIBLE SETTINGS]---
	Menu.Items:MenuElement({id = "Crucible", name = "Crucible", type = MENU})
	Menu.Items.Crucible:MenuElement({id = "Targets", name = "Targets", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly and myHero ~= hero then			
			if table.contains(_adcHeroes, hero.charName) then
				Menu.Items.Crucible.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
			else
				Menu.Items.Crucible.Targets:MenuElement({id = hero.charName, name = hero.charName, value = false })
			end
		end
	end	
	Menu.Items.Crucible:MenuElement({id = "CC", name = "CC Settings", type = MENU})
	Menu.Items.Crucible.CC:MenuElement({id = "CleanseTime", name = "Cleanse CC If Duration Over (Seconds)", value = .5, min = .1, max = 2, step = .1 })
	Menu.Items.Crucible.CC:MenuElement({id = "Suppression", name = "Suppression", value = true, toggle = true})
	Menu.Items.Crucible.CC:MenuElement({id = "Stun", name = "Stun", value = true, toggle = true})
	Menu.Items.Crucible.CC:MenuElement({id = "Sleep", name = "Sleep", value = true, toggle = true})
	Menu.Items.Crucible.CC:MenuElement({id = "Polymorph", name = "Polymorph", value = true, toggle = true})
	Menu.Items.Crucible.CC:MenuElement({id = "Taunt", name = "Taunt", value = true, toggle = true})
	Menu.Items.Crucible.CC:MenuElement({id = "Charm", name = "Charm", value = true, toggle = true})
	Menu.Items.Crucible.CC:MenuElement({id = "Fear", name = "Fear", value = true, toggle = true})
	Menu.Items.Crucible.CC:MenuElement({id = "Blind", name = "Blind", value = false, toggle = true})	
	Menu.Items.Crucible.CC:MenuElement({id = "Snare", name = "Snare", value = false, toggle = true})
	Menu.Items.Crucible.CC:MenuElement({id = "Slow", name = "Slow", value = false, toggle = true})
	Menu.Items.Crucible.CC:MenuElement({id = "Poison", name = "Poison", value = false, toggle = true})
	
	---[REDEMPTION SETTINGS]---
	Menu.Items:MenuElement({id = "Redemption", name = "Redemption", type = MENU})
	Menu.Items.Redemption:MenuElement({id = "Targets", name = "Targets", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly then		
			Menu.Items.Redemption.Targets:MenuElement({id = hero.charName, name = hero.charName,  tooltip = "How low must this target's HP be to cast redemption", value = 60, min = 10, max = 90, step = 10 })
		end
	end
	Menu.Items.Redemption:MenuElement({id="Duration", name="Prediction Duration", tooltip = "allies must be immobile for at least this long for redemption to cast", value = .5, min = .25, max = 2, step = .25})
	Menu.Items.Redemption:MenuElement({id="Count", name = "Target Count", tooltip = "The total number of allies+enemies that may be hit with redemption in order to cast it.", value = 3, min = 1, max = 10, step = 1})
end

function AutoUtil:GetDistanceSqr(p1, p2)
	assert(p1, "GetDistance: invalid argument: cannot calculate distance to "..type(p1))
	assert(p2, "GetDistance: invalid argument: cannot calculate distance to "..type(p2))
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function AutoUtil:GetDistance(p1, p2)
	return math.sqrt(self:GetDistanceSqr(p1, p2))
end

function AutoUtil:CalculatePhysicalDamage(target, damage)			
	local targetArmor = target.armor * myHero.armorPenPercent - myHero.armorPen
	local damageReduction = 100 / ( 100 + targetArmor)
	if targetArmor < 0 then
		damageReduction = 2 - (100 / (100 - targetArmor))
	end		
	damage = damage * damageReduction	
	return damage
end

function AutoUtil:CalculateMagicDamage(target, damage)			
	local targetMR = target.magicResist * myHero.magicPenPercent - myHero.magicPen
	local damageReduction = 100 / ( 100 + targetMR)
	if targetMR < 0 then
		damageReduction = 2 - (100 / (100 - targetMR))
	end		
	damage = damage * damageReduction
	
	return damage
end

function AutoUtil:GetNearestAlly(entity, range)
	local ally = nil
	local distance = math.huge
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if hero ~= entity and hero.isAlly and HPred:CanTargetALL(hero) then
			local d = self:GetDistance(entity.pos, hero.pos)
			if d < distance and d < range then
				distance = d
				ally = hero
			end
		end
	end
	if distance <  range then
		return ally
	end
end
function AutoUtil:NearestEnemy(entity)
	local distance = 999999
	local enemy = nil
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if HPred:CanTarget(hero) then
			local d = self:GetDistance(entity.pos, hero.pos)
			if d < distance then
				distance = d
				enemy = hero
			end
		end
	end
	return distance, enemy
end

function AutoUtil:CountEnemiesNear(origin, range)
	local count = 0
	for i  = 1,Game.HeroCount(i) do
		local enemy = Game.Hero(i)
		if HPred:CanTarget(enemy) and AutoUtil:GetDistance(origin, enemy.pos) <= range then
			count = count + 1
		end			
	end
	return count
end

function AutoUtil:GetItemSlot(id)
	for i = 6, 12 do
		if myHero:GetItemData(i).itemID == id then
			return i
		end
	end

	return nil
end

function AutoUtil:IsItemReady(id, ward)
	if not self.itemKey or #self.itemKey == 0 then
		self.itemKey = 
		{
			HK_ITEM_1,
			HK_ITEM_2,
			HK_ITEM_3,
			HK_ITEM_4,
			HK_ITEM_5,
			HK_ITEM_6,
			HK_ITEM_7
		}
	end
	local slot = self:GetItemSlot(id)
	if slot then
		return myHero:GetSpellData(slot).currentCd == 0 and not (ward and myHero:GetSpellData(slot).ammo == 0)
	end
end

function AutoUtil:CastItem(unit, id, range)
	if unit == myHero or self:GetDistance(myHero.pos, unit.pos) <= range then
		local keyIndex = self:GetItemSlot(id) - 5
		local key = self.itemKey[keyIndex]

		if key then
			if unit ~= myHero then
				Control.CastSpell(key, unit.pos or unit)
			else
				Control.CastSpell(key)
			end
		end
	end
end
function AutoUtil:CastItemMiniMap(pos, id)
	local keyIndex = self:GetItemSlot(id) - 5
	local key = self.itemKey[keyIndex]
	if key then
		Control.CastSpell(key, pos:ToMM())
	end
end

function AutoUtil:HasBuffType(unit, buffType, duration)
	for i = 0, 63 do
		local Buff = unit:GetBuff(i)
		if Buff.duration > duration and Buff.count > 0  and Buff.type == buffType then 
			return true 
		end
	end
	return false
end



function AutoUtil:UseSupportItems()
	--Use crucible on carry if they are CCd
	if AutoUtil:IsItemReady(3222) then
		AutoUtil:AutoCrucible()
	end	
	
	--Use Locket
	if AutoUtil:IsItemReady(3190) then
		AutoUtil:AutoLocket()
	end
	
	--Use Redemption
	if AutoUtil:IsItemReady(3107) then
		AutoUtil:AutoRedemption()
	end
end


function AutoUtil:AutoCrucible()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and Hero.alive and Hero ~= myHero then
			if Menu.Items.Crucible.Targets[Hero.charName] and Menu.Items.Crucible.Targets[Hero.charName]:Value() then
				for ccName, ccType in pairs(_ccNames) do
					if Menu.Items.Crucible.CC[ccName] and Menu.Items.Crucible.CC[ccName]:Value() and self:HasBuffType(Hero, ccType, Menu.Items.Crucible.CC.CleanseTime:Value()) then
						AutoUtil:CastItem(Hero, 3222, 650)
					end
				end
			end
		end
	end
end

function AutoUtil:AutoLocket()
	local injuredCount = 0
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if _allyHealthPercentage and _allyHealthPercentage[hero.charName] and hero.isAlly and hero.alive and self:GetDistance(myHero.pos, hero.pos) <= 700 then			
			local deltaLifeLost = _allyHealthPercentage[hero.charName] - CurrentPctLife(hero)
			if deltaLifeLost >= Menu.Items.Locket.Threshold:Value() then
				injuredCount = injuredCount + 1
			end
		end
	end	
	if injuredCount >= Menu.Items.Locket.Count:Value() then
		AutoUtil:CastItem(myHero, 3190, math.huge)
	end
end

function AutoUtil:AutoRedemption()
	local targetCount = 0
	local aimPos
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly and HPred:CanTargetALL(hero) and self:GetDistance(myHero.pos, hero.pos) <= 5500 and Menu.Items.Redemption.Targets[hero.charName] and Menu.Items.Redemption.Targets[hero.charName]:Value() >= CurrentPctLife(hero) then		
			--Check if they are immobile for at least the duration we specified
			if HPred:GetImmobileTime(hero) >= Menu.Items.Redemption.Duration:Value() then
				targetCount = 0
				aimPos = hero.pos
				--we can start adding targets within range!!
				for z = 1, Game.HeroCount() do
					local target = Game.Hero(z)
					if HPred:CanTargetALL(target) and HPred:GetDistance(hero.pos, HPred:PredictUnitPosition(target, 2)) < 525 then
						targetCount = targetCount + 1						
					end
				end
				if targetCount >= Menu.Items.Redemption.Count:Value() then
					break
				end
			end
		end
	end	
	if aimPos and targetCount >= Menu.Items.Redemption.Count:Value() then		
		AutoUtil:CastItemMiniMap(aimPos, 3107)
	end
end

function AutoUtil:GetExhaust()
	local exhaustHotkey
	local exhaustData = myHero:GetSpellData(SUMMONER_1)
	if exhaustData.name ~= "SummonerExhaust" then
		exhaustData = myHero:GetSpellData(SUMMONER_2)
		exhaustHotkey = HK_SUMMONER_2
	else 
		exhaustHotkey = HK_SUMMONER_1
	end
	
	if exhaustData.name == "SummonerExhaust" and exhaustData.currentCd == 0 then 
		return exhaustHotkey
	end	
end

function AutoUtil:AutoExhaust()
	local exhaustHotkey = AutoUtil:GetExhaust()	
	if not exhaustHotkey or not Menu.Skills.Exhaust then return end
	
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		--It's an enemy who is within exhaust range and is toggled ON in ExhaustList
		if enemy.isEnemy and AutoUtil:GetDistance(myHero.pos, enemy.pos) <= 600 + enemy.boundingRadius and HPred:CanTarget(enemy, 650) and Menu.Skills.Exhaust.Targets[enemy.charName] and Menu.Skills.Exhaust.Targets[enemy.charName]:Value() then
			for allyIndex = 1, Game.HeroCount() do
				local ally = Game.Hero(allyIndex)
				if ally.isAlly and ally.alive and AutoUtil:GetDistance(enemy.pos, ally.pos) <= Menu.Skills.Exhaust.Radius:Value() and CurrentPctLife(ally) <= Menu.Skills.Exhaust.Health:Value() then
					Control.CastSpell(exhaustHotkey, enemy)
				end
			end
		end
	end
end

class "Brand"
function Brand:__init()	
	print("Loaded [Auto] ".. myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end
function Brand:LoadSpells()
	Q = {Range = 1050, Width = 80, Delay = 0.25, Speed = 1550, Collision = true}
	W = {Range = 900, Width = 250, Delay = 0.625, Speed = math.huge}
	E = {Range = 600, Delay = 0.25, Speed = math.huge}
	R = {Range = 750, Delay = 0.25, Speed = 1700}
end

function Brand:CreateMenu()	
	
	
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Sear", type = MENU})
	Menu.Skills.Q:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy", value = 3, min = 1, max = 5, step = 1 })
	Menu.Skills.Q:MenuElement({id = "AccuracyAuto", name = "Auto Accuracy", value = 3, min = 1, max = 5, step = 1 })
	
	Menu.Skills:MenuElement({id = "W", name = "[W] Pillar of Flame", type = MENU})
	Menu.Skills.W:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy", value = 3, min = 1, max = 5, step = 1 })
	Menu.Skills.W:MenuElement({id = "AccuracyAuto", name = "Auto Cast Accuracy", value = 3, min = 1, max = 5, step = 1 })
	Menu.Skills.W:MenuElement({id = "Mana", name = "Auto Cast Mana", value = 30, min = 1, max = 100, step = 5 })
	Menu.Skills.W:MenuElement({id = "Targets", name = "Auto Harass Targets", type = MENU})
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			Menu.Skills.W.Targets:MenuElement({id = Hero.charName, name = Hero.charName, value = true, toggle = true})
		end
	end
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Conflagration", type = MENU})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Auto Cast Mana", value = 15, min = 1, max = 100, step = 5 })
	Menu.Skills.E:MenuElement({id = "Targets", name = "Auto Harass Targets", type = MENU})
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			Menu.Skills.E.Targets:MenuElement({id = Hero.charName, name = Hero.charName, value = true, toggle = true})
		end
	end
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Pyroclasm", type = MENU})
	Menu.Skills.R:MenuElement({id = "Count", name = "Auto Cast On Enemy Count", value = 3, min = 1, max = 5, step = 1 })	
	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
end

function Brand:Draw()
	--Nothing special needs to be drawn for brand... Could add prediciton for Q/W but its prob not needed
end

local WCastPos, WCastTime
--Gets the time until our W will deal damage
function Brand:GetWHitTime()
	local deltaHitTime = 99999999
	if( WCastTime) then
		deltaHitTime = WCastTime + W.Delay - Game.Timer()
	end
	return deltaHitTime
end


local _lastWhiteListUpdate = Game.Timer()
local _whiteListUpdateFrequency = 1
local _wWhiteList
function Brand:UpdateWWhiteList()	
	if Game.Timer() - _lastWhiteListUpdate < _whiteListUpdateFrequency then return end	
	_lastWhiteListUpdate = Game.Timer()
	_wWhiteList = {}
	for i  = 1,Game.HeroCount(i) do
		local enemy = Game.Hero(i)
		if Menu.Skills.W.Targets[enemy.charName] and Menu.Skills.W.Targets[enemy.charName]:Value() then
			_wWhiteList[enemy.charName] = true
		end
	end
end

function Brand:Tick()
	if myHero.dead or Game.IsChatOpen() or IsRecalling()  or IsEvading() or IsAttacking() then return end

	--Reliable spells cast even if combo key is NOT pressed and are the most likely to hit.
	if Ready(_W) then
		self:ReliableW()
		if CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() then
			self:UpdateWWhiteList()
			self:UnreliableW(Menu.Skills.W.AccuracyAuto:Value(),_wWhiteList)
		end
	end
	
	if Ready(_Q) then
		self:ReliableQ()
	end
	
	if Ready(_E) then
		self:ReliableE()
	end
	
	if Ready(_R) then
		self:AutoR()
	end
	
	--Unreliable spells are cast if the combo or harass key is pressed
	if Menu.Skills.Combo:Value() then
		if Ready(_W) then
			self:UnreliableW(Menu.Skills.W.AccuracyCombo:Value(), _wWhiteList)
		end
		if Ready(_Q) then		
			self:UnreliableQ(Menu.Skills.Q.AccuracyCombo:Value())
		end
	else	
		if Ready(_Q) then		
			self:UnreliableQ(Menu.Skills.Q.AccuracyAuto:Value())
		end
	end
	
	
	
end

function Brand:ReliableQ()
	local target, aimPosition = HPred:GetReliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed,Q.Width, Menu.General.ReactionTime:Value(), Q.Collision)
	if target and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
		--Check if they are ablaze or will be hit by W before Q
		local WInterceptTime = self:GetWHitTime()		
		local QInterceptTime = HPred:GetSpellInterceptTime(myHero.pos, aimPosition, Q.Delay, Q.Speed)
		
		if HPred:HasBuff(target, "BrandAblaze") or (WCastPos and HPred:GetDistance(WCastPos, aimPosition) < W.Width and  QInterceptTime > WInterceptTime) then
			SpecialCast(HK_Q, aimPosition)
		end
	end
end

function Brand:UnreliableQ(minAccuracy)

	for i  = 1,Game.HeroCount(i) do
		local enemy = Game.Hero(i)
		if HPred:CanTarget(enemy) and HPred:HasBuff(enemy, "BrandAblaze") then	
			local hitChance, aimPosition = HPred:GetHitchance(myHero.pos, enemy,Q.Range, Q.Delay, Q.Speed, Q.Width, Q.Collision, nil)
			if hitChance and hitChance >= minAccuracy and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
				SpecialCast(HK_Q, aimPosition)
			end
		end
	end
end

function Brand:ReliableW()	
	local target, aimPosition = HPred:GetReliableTarget(myHero.pos, W.Range, W.Delay, W.Speed,W.Width, Menu.General.ReactionTime:Value(), W.Collision)
	if target and HPred:GetDistance(myHero.pos, aimPosition) <= W.Range then
		SpecialCast(HK_W, aimPosition)
		WCastPos = aimPosition
		WCastTime = Game.Timer()
	end
end

function Brand:UnreliableW(minAccuracy, whitelist)
	local hitRate, aimPosition = HPred:GetUnreliableTarget(myHero.pos, W.Range, W.Delay, W.Speed, W.Width, W.Collision, minAccuracy,whitelist)	
	if hitRate and HPred:GetDistance(myHero.pos, aimPosition) <= W.Range then
		SpecialCast(HK_W, aimPosition)
		WCastPos = aimPosition
		WCastTime = Game.Timer()
	end	
end

function Brand:ReliableE()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if HPred:CanTarget(Hero) and HPred:GetDistance(myHero.pos, Hero.pos) <= E.Range and Menu.Skills.E.Targets[Hero.charName] and Menu.Skills.E.Targets[Hero.charName]:Value() then
			--TODO: Sort targets by priority and health (KS then priority list)
			SpecialCast(HK_E, Hero.pos)
			break
		end
	end
end

function Brand:AutoR()	
	for i  = 1,Game.HeroCount(i) do
		local enemy = Game.Hero(i)
		if HPred:CanTarget(enemy) and HPred:HasBuff(enemy, "BrandAblaze") and HPred:GetDistance(myHero.pos, enemy.pos) <= R.Range then			
			local targetCount = AutoUtil:CountEnemiesNear(myHero.pos, 600)
			if targetCount >= Menu.Skills.R.Count:Value() then
				SpecialCast(HK_R, enemy.pos)
				break				
			end
		end
	end
end


class "Soraka"

function Soraka:__init()	
	print("Loaded [Auto] ".. myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end
function Soraka:LoadSpells()


	Q = {Range = 800, Width = 235,Delay = 0.25, Speed = 1150}
	W = {Range = 550 }
	E = {Range = 925, Width = 300, Delay = 1, Speed = math.huge}
end

function Soraka:CreateMenu()	
	
	AutoUtil:SupportMenu(Menu)
	
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	if AutoUtil:GetExhaust() then
		Menu.Skills:MenuElement({id = "Exhaust", name = "Exhaust", type = MENU})	
		Menu.Skills.Exhaust:MenuElement({id ="Targets", name ="Target List", type = MENU})
		for i = 1, Game.HeroCount() do
			local hero = Game.Hero(i)
			if hero.isEnemy then
				Menu.Skills.Exhaust.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
			end
		end
		Menu.Skills.Exhaust:MenuElement({id = "Health", tooltip ="How low health allies must be to use exhaust", name = "Ally Health", value = 40, min = 1, max = 100, step = 5 })	
		Menu.Skills.Exhaust:MenuElement({id = "Radius", tooltip ="How close targets must be to allies to use exhaust", name = "Peel Distance", value = 200, min = 100, max = 1000, step = 25 })
		Menu.Skills.Exhaust:MenuElement({id="Enabled", name="Enabled", value = false})	
	end
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Starcall", type = MENU})
	Menu.Skills.Q:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy", value = 3, min = 1, max = 5, step = 1 })
	Menu.Skills.Q:MenuElement({id = "AccuracyAuto", name = "Auto Accuracy", value = 3, min = 1, max = 5, step = 1 })
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Auto Cast Mana", value = 30, min = 1, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "W", name = "[W] Astral Infusion", type = MENU})
	Menu.Skills.W:MenuElement({id = "Targets", name = "Target Settings", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly and myHero ~= hero then
			Menu.Skills.W.Targets:MenuElement({id = hero.charName, name = hero.charName, value = 50, min = 1, max = 100, step = 5 })		
		end
	end	
	Menu.Skills.W:MenuElement({id = "Health", tooltip ="How high must our health be to heal", name = "W Minimum Health", value = 35, min = 1, max = 100, step = 5 })
	Menu.Skills.W:MenuElement({id = "Mana", tooltip ="How high must our mana be to heal", name = "W Minimum Mana", value = 20, min = 1, max = 100, step = 5 })
		
	Menu.Skills:MenuElement({id = "E", name = "[E] Equinox", type = MENU})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Auto Cast Mana", value = 15, min = 1, max = 100, step = 5 })
	Menu.Skills.E:MenuElement({id = "Targets", name = "Auto Interrupt Targets", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy then
			Menu.Skills.E.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true, toggle = true})
		end
	end
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Wish", type = MENU})
	Menu.Skills.R:MenuElement({id = "Targets", name = "Auto Save Targets", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly then
			Menu.Skills.R.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true, toggle = true})
		end
	end
	
	Menu.Skills.R:MenuElement({id = "EmergencyCount", tooltip = "How many allies must be below 40pct for ultimate to cast", name = "Ally count below 40% HP", value = 2, min = 1, max = 5, step = 1 })
	Menu.Skills.R:MenuElement({id = "DamageCount", tooltip = "How many allies must have been injured in last second to cast", name = "Ally count Damaged X%", value = 3, min = 1, max = 5, step = 1 })
	Menu.Skills.R:MenuElement({id = "DamagePercent", tooltip = "How much damage allies received in last second", name = "Ally Damage Threshold", value = 40, min = 1, max = 80, step = 1 })
	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
end

function Soraka:Draw()
	--Nothing special needs to be drawn for brand... Could add prediciton for Q/W but its prob not needed
end

function Soraka:Tick()
	if myHero.dead or Game.IsChatOpen() or IsRecalling()  or IsEvading() or IsAttacking() then return end
	
	--Heal allies with R
	if Ready(_R) then
		self:AutoR()
	end
	
	--Heal allies with W
	if Ready(_W) and CurrentPctLife(myHero) >=  Menu.Skills.W.Health:Value() and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() then
		self:AutoW()
	end
	
	--Harass enemies with Q
	if Ready(_Q) then
		self:AutoQ()
	end
	
	--Interrupt enemies with E
	if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() then
		self:AutoE()
	end
	
	--Use Support Items
	AutoUtil:UseSupportItems()
	
	--Use Exhaust if we have it
	if Menu.Skills.Exhaust and Menu.Skills.Exhaust.Enabled:Value() then
		AutoUtil.AutoExhaust()
	end
end


function Soraka:AutoQ()
	local target, aimPosition = HPred:GetReliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed,Q.Width, Menu.General.ReactionTime:Value(), Q.Collision)
	if target and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
		SpecialCast(HK_Q, aimPosition)
	--No Reliable target: Check for harass/combo unreliable target instead
	else
		if Menu.Skills.Combo:Value() then
			local hitRate, aimPosition = HPred:GetUnreliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, Q.Width, Q.Collision, Menu.Skills.Q.AccuracyAuto:Value(), nil)	
			if hitRate and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
				SpecialCast(HK_Q, aimPosition)
			end	
		elseif CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() then
			local hitRate, aimPosition = HPred:GetUnreliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, Q.Width, Q.Collision, Menu.Skills.Q.AccuracyAuto:Value(), nil)	
			if hitRate and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
				SpecialCast(HK_Q, aimPosition)
			end	
		end
	end
end

function Soraka:AutoW()
	local targets = {}
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly and hero.alive and hero.isTargetable and hero ~= myHero and HPred:GetDistance(myHero.pos, hero.pos) <= W.Range + hero.boundingRadius and Menu.Skills.W.Targets[hero.charName] and Menu.Skills.W.Targets[hero.charName]:Value() >= CurrentPctLife(hero) then		
			local pctLife = CurrentPctLife(hero)
			table.insert(targets, {hero, pctLife})
		end
	end
	
	table.sort(targets, function( a, b ) return a[2] < b[2] end)	
	if #targets > 0 then
		SpecialCast(HK_W, targets[1][1].pos)
	end
end

function Soraka:AutoE()
	local target, aimPosition = HPred:GetReliableTarget(myHero.pos, E.Range, E.Delay, E.Speed,E.Width, Menu.General.ReactionTime:Value(), E.Collision)
	if target and Menu.Skills.E.Targets[target.charName] and Menu.Skills.E.Targets[target.charName]:Value() and HPred:GetDistance(myHero.pos, aimPosition) <= E.Range then
		SpecialCast(HK_E, aimPosition)
	end
end

function Soraka:AutoR()
	
	local count, isValid = self:GetEmergencyRCount()
	if isValid and count >= Menu.Skills.R.EmergencyCount:Value() then
		SpecialCast(HK_R)
	end
	
	local count, isValid = self:GetInjuredRCount()
	if isValid and count >= Menu.Skills.R.DamageCount:Value() then
		SpecialCast(HK_R)
	end
	
	UpdateAllyHealth()	
end

function Soraka:GetInjuredRCount()
	local count = 0
	local isValid = false
	
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly and hero.alive and _allyHealthPercentage and _allyHealthPercentage[hero.charName] then		
			local life = _allyHealthPercentage[hero.charName]
			local deltaLifeLost = life - CurrentPctLife(hero)
			if deltaLifeLost >= Menu.Skills.R.DamagePercent:Value() then
				count = count + 1				
				--Only cast if we've chosen to save at least one of the damaged targets and that target is near an enemy
				--This is prone to issues with untargetable enemies or globals or damage prediction but it will serve for now.
				if not isValid and Menu.Skills.R.Targets[hero.charName] and Menu.Skills.R.Targets[hero.charName]:Value() and AutoUtil:NearestEnemy(hero) < 800 then					
					isValid = true
				end
				
			end
		end
	end
	return count, isValid
end

function Soraka:GetEmergencyRCount()
	local count = 0
	local isValid = false
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly and hero.alive and CurrentPctLife(hero) <= 40 then
			count = count + 1
			if not isValid and Menu.Skills.R.Targets[hero.charName] and Menu.Skills.R.Targets[hero.charName]:Value() then
				isValid = true
			end
		end
	end	
	return count, isValid
end




class "Zilean"

function Zilean:__init()	
	print("Loaded [Auto] ".. myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end
function Zilean:LoadSpells()
	Q = {Range = 900, Width = 180,Delay = 0.25, Speed = 2050}
	E = {Range = 550}
	R = {Range = 900}
end

function Zilean:CreateMenu()	
	
	AutoUtil:SupportMenu(Menu)
	
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	if AutoUtil:GetExhaust() then
		Menu.Skills:MenuElement({id = "Exhaust", name = "Exhaust", type = MENU})	
		Menu.Skills.Exhaust:MenuElement({id ="Targets", name ="Target List", type = MENU})
		for i = 1, Game.HeroCount() do
			local hero = Game.Hero(i)
			if hero.isEnemy then
				Menu.Skills.Exhaust.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
			end
		end
		Menu.Skills.Exhaust:MenuElement({id = "Health", tooltip ="How low health allies must be to use exhaust", name = "Ally Health", value = 40, min = 1, max = 100, step = 5 })	
		Menu.Skills.Exhaust:MenuElement({id = "Radius", tooltip ="How close targets must be to allies to use exhaust", name = "Peel Distance", value = 200, min = 100, max = 1000, step = 25 })
		Menu.Skills.Exhaust:MenuElement({id="Enabled", name="Enabled", value = false})	
	end
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Timb Bomb", type = MENU})
	Menu.Skills.Q:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy", value = 3, min = 1, max = 5, step = 1 })
	Menu.Skills.Q:MenuElement({id = "AccuracyAuto", name = "Auto Accuracy", value = 3, min = 1, max = 5, step = 1 })
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Auto Cast Mana", value = 30, min = 1, max = 100, step = 5 })
	Menu.Skills.Q:MenuElement({id = "Targets", name = "Targets", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy then
			Menu.Skills.Q.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true, toggle = true})
		end
	end
	
	
	Menu.Skills:MenuElement({id = "W", name = "[W] Rewind", type = MENU})
	Menu.Skills.W:MenuElement({id = "Cooldown", name = "Minimum Cooldown Remaining", value = 3, min = 1, max = 10, step = .5 })
	Menu.Skills.W:MenuElement({id = "Mana", name = "Minimum Mana", value = 25, min = 1, max = 100, step = 5 })
	
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Time Warp", type = MENU})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Minimum Mana", value = 25, min = 1, max = 100, step = 5 })
	Menu.Skills.E:MenuElement({id = "Health", name = "Peel When Under % HP", value = 40, min = 1, max = 100, step = 5 })
	Menu.Skills.E:MenuElement({id = "Radius", name = "Peel Range", value = 300, min = 100, max = 600, step = 50 })
	Menu.Skills.E:MenuElement({id = "Targets", name = "Targets", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy then
			Menu.Skills.E.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true, toggle = true})
		end
	end	
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Chronoshift", type = MENU})
	Menu.Skills.R:MenuElement({id = "Health", name = "Ally Health", value = 20, min = 1, max = 100, step = 5 })
	Menu.Skills.R:MenuElement({id = "Damage", name = "Damage Received", value = 15, min = 1, max = 100, step = 5 })		
	Menu.Skills.R:MenuElement({id = "Targets", name = "Targets", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly then
			Menu.Skills.R.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true})		
		end
	end	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
end

function Zilean:Draw()
	--Nothing special needs to be drawn for brand... Could add prediciton for Q/W but its prob not needed
end

function Zilean:Tick()
	if myHero.dead or Game.IsChatOpen() or IsRecalling()  or IsEvading() or IsAttacking() then return end
	if NextSpellCast > Game.Timer() then return end
	
	--Use Ult on Allies	
	if Ready(_R) then
		self:AutoR()
	end
	
	--Reliable Q combo
	if Ready(_Q) then
		self:ReliableQ()
		if Game.Timer() > NextSpellCast then
			self:UnreliableQ()
		end
	end
	
	--Peel with E
	if Ready(_E) then
		self:AutoEPeel()
	end
	
	--Reset cooldowns with W
	if Ready(_W) then
		self:AutoWReset()
	end
		
	--Use Support Items
	AutoUtil:UseSupportItems()
	
	--Use Exhaust if we have it
	if Menu.Skills.Exhaust and Menu.Skills.Exhaust.Enabled:Value() then
		AutoUtil.AutoExhaust()
	end
end

function Zilean:ReliableQ()
	local target, aimPosition = HPred:GetReliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed,Q.Width, Menu.General.ReactionTime:Value(), Q.Collision)
	if target and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
		if Ready(_W) then
			self:StunCombo(target, aimPosition)		
		else	
			Control.CastSpell(HK_Q, aimPosition)
		end		
	end
end

function Zilean:UnreliableQ()	
	if Menu.Skills.Combo:Value() then
		local hitRate, aimPosition = HPred:GetUnreliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, Q.Width, Q.Collision, Menu.Skills.Q.AccuracyAuto:Value(),nil)	
		if hitRate and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
			SpecialCast(HK_Q, aimPosition)
		end	
	elseif CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() then
		local hitRate, aimPosition = HPred:GetUnreliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, Q.Width, Q.Collision, Menu.Skills.Q.AccuracyAuto:Value(),nil)	
		if hitRate and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
			SpecialCast(HK_Q, aimPosition)
		end	
	end
end

function Zilean:StunCombo(target, aimPosition)
	NextSpellCast = Game.Timer() + .5	
	if Ready(_E) and AutoUtil:GetDistance(myHero.pos, target.pos) <= E.Range then
		--We can lead with E, if not just go for QWQ stun combo and we can E later if we really want
		Control.CastSpell(HK_E, target)
	end
	
	--Try spam casting it for the hell of it
	Control.CastSpell(HK_Q, aimPosition)
	DelayAction(function()Control.CastSpell(HK_Q, aimPosition) end,.10)
	DelayAction(function()Control.CastSpell(HK_W) end,.15)
	DelayAction(function()Control.CastSpell(HK_Q, aimPosition) end, 0.3)
end

function Zilean:AutoWReset()
	if myHero.levelData.lvl > 3 and not Ready(_Q) and not Ready(_E) and Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() then
		if myHero:GetSpellData(_Q).currentCd >= Menu.Skills.W.Cooldown:Value() and myHero:GetSpellData(_E).currentCd >= Menu.Skills.W.Cooldown:Value() then		
			Control.CastSpell(HK_W)
		end
	end
end

function Zilean:AutoEPeel()	
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		--Its an ally, they are in range and we've set them as a carry. Lets peel for them!
		if hero.isAlly and CurrentPctLife(hero) <= Menu.Skills.E.Health:Value() and AutoUtil:GetDistance(myHero.pos, hero.pos) <= E.Range + Menu.Skills.E.Radius:Value()then				
			if target ~= nil and  AutoUtil:NearestEnemy(hero) <= Menu.Skills.E.Radius:Value() and AutoUtil:GetDistance(myHero.pos, target.pos) < E.Range then
				Control.CastSpell(HK_E, target.pos)
			end
		end
	end
end

function Zilean:AutoR()
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly and AutoUtil:GetDistance(myHero.pos, hero.pos) < R.Range and CurrentPctLife(hero) <= Menu.Skills.R.Health:Value() and Menu.Skills.R.Targets[hero.charName] and Menu.Skills.R.Targets[hero.charName]:Value() and _allyHealthPercentage[hero.charName] then			
			local deltaLifeLost = _allyHealthPercentage[hero.charName] - CurrentPctLife(hero)
			if deltaLifeLost >= Menu.Skills.R.Damage:Value() and AutoUtil:NearestEnemy(hero) < 800 then
				Control.CastSpell(HK_R, hero.pos)
			end
		end
	end	
	UpdateAllyHealth()	
end


class "Nami"

function Nami:__init()	
	print("Loaded [Auto] ".. myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end
function Nami:LoadSpells()
	Q = {Range = 875, Width = 200,Delay = 0.95, Speed = math.huge}
	W = {Range = 725}
	E = { Range = 800}
	R = {Range = 2750,Width = 215, Speed = 850, Delay = 0.5}
end

function Nami:CreateMenu()	
	
	AutoUtil:SupportMenu(Menu)
	
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	if AutoUtil:GetExhaust() then
		Menu.Skills:MenuElement({id = "Exhaust", name = "Exhaust", type = MENU})	
		Menu.Skills.Exhaust:MenuElement({id ="Targets", name ="Target List", type = MENU})
		for i = 1, Game.HeroCount() do
			local hero = Game.Hero(i)
			if hero.isEnemy then
				Menu.Skills.Exhaust.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
			end
		end
		Menu.Skills.Exhaust:MenuElement({id = "Health", tooltip ="How low health allies must be to use exhaust", name = "Ally Health", value = 40, min = 1, max = 100, step = 5 })	
		Menu.Skills.Exhaust:MenuElement({id = "Radius", tooltip ="How close targets must be to allies to use exhaust", name = "Peel Distance", value = 200, min = 100, max = 1000, step = 25 })
		Menu.Skills.Exhaust:MenuElement({id="Enabled", name="Enabled", value = false})	
	end
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Aqua Prison", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 5, step = 1 })	
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Bubble Immobile Targets", value = true, toggle = true })	
	
	Menu.Skills:MenuElement({id = "W", name = "[W] Ebb and Flow", type = MENU})
	Menu.Skills.W:MenuElement({id = "ManaBounce", name = "Minimum Mana [Bounce]", value = 25, min = 1, max = 100, step = 5 })
	Menu.Skills.W:MenuElement({id = "HealthBounce", name = "Minimum Mana [Bounce]", value = 60, min = 1, max = 100, step = 5 })	
	Menu.Skills.W:MenuElement({id = "ManaEmergency", name = "Minimum Mana [No Bounce]", value = 25, min = 1, max = 100, step = 5 })
	Menu.Skills.W:MenuElement({id = "HealthEmergency", name = "Minimum Mana [No Bounce]", value = 25, min = 1, max = 100, step = 5 })
	
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Tidecaller's Blessing", type = MENU})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Minimum Mana", value = 25, min = 1, max = 100, step = 5 })
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Buff Allies", value = true, toggle = true })	
	Menu.Skills.E:MenuElement({id = "Targets", name = "Targets", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly  then
			if table.contains(_adcHeroes, hero.charName) then
				Menu.Skills.E.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true, toggle = true})
			else
				Menu.Skills.E.Targets:MenuElement({id = hero.charName, name = hero.charName, value = false, toggle = true})
			end
		end
	end	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
end

function Nami:Draw()
	--Nothing special needs to be drawn for brand... Could add prediciton for Q/W but its prob not needed
end

function Nami:Tick()
	if myHero.dead or Game.IsChatOpen() or IsRecalling()  or IsEvading() or IsAttacking() then return end
	if NextSpellCast > Game.Timer() then return end
	
	--Auto Bubble Immobile targets and unreliable targets if combo button held down
	if Ready(_Q) then
		self:AutoQ()		
	end
		
	--Auto W bounce or solo target enemies
	if Ready(_W) then
		self:AutoW()
	end
	
	--Auto E selected allies who are auto attacking enemies
	if Ready(_E) and Menu.Skills.E.Auto:Value() and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() then
		self:AutoE()
	end
	
	
	--Use Support Items
	AutoUtil:UseSupportItems()
	
	--Use Exhaust if we have it
	if Menu.Skills.Exhaust and Menu.Skills.Exhaust.Enabled:Value() then
		AutoUtil.AutoExhaust()
	end	
end

function Nami:AutoQ()
	local target, aimPosition = HPred:GetReliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed,Q.Width, Menu.General.ReactionTime:Value(), Q.Collision)
	if target and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range and Menu.Skills.Q.Auto:Value() then
		SpecialCast(HK_Q, aimPosition)		
	elseif Menu.Skills.Combo:Value() then
		local hitRate, aimPosition = HPred:GetUnreliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, Q.Width, Q.Collision, Menu.Skills.Q.Accuracy:Value(),nil)	
		if hitRate and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
			SpecialCast(HK_Q, aimPosition)
		end	
	end
end

function Nami:AutoW()
	if CurrentPctMana(myHero) >= Menu.Skills.W.ManaEmergency:Value() then
		self:AutoWNoBounce()
	end	
	if CurrentPctMana(myHero) >= Menu.Skills.W.ManaBounce:Value() then
		self:AutoWBounce()
	end	
end

function Nami:AutoWNoBounce()
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly and hero.alive and hero.isTargetable and AutoUtil:GetDistance(myHero.pos, hero.pos) <= W.Range and CurrentPctLife(hero) <= Menu.Skills.W.HealthEmergency:Value() then
			Control.CastSpell(HK_W, hero)			
		end
	end
end
function Nami:AutoWBounce()	
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)		
		if hero.isAlly and hero.alive and hero.isTargetable and AutoUtil:GetDistance(myHero.pos, hero.pos) <= W.Range and CurrentPctLife(hero) <= Menu.Skills.W.HealthBounce:Value() then
			if AutoUtil:NearestEnemy(hero) < 500 then
				Control.CastSpell(HK_W, hero)
			end	
		end
	end
end

function Nami:AutoE()
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if  hero.isAlly and hero.isTargetable and hero.alive and AutoUtil:GetDistance(myHero.pos, hero.pos) <= E.Range and Menu.Skills.E.Targets[hero.charName] and Menu.Skills.E.Targets[hero.charName]:Value() then
			
			local targetHandle = nil			
			if hero.activeSpell and hero.activeSpell.valid and hero.activeSpell.target then
				targetHandle = hero.activeSpell.target
			end
			
			if targetHandle then 		
				local Enemy = GetHeroByHandle(targetHandle)
				if Enemy and Enemy.isEnemy then
					Control.CastSpell(HK_E, hero)
				end
			end
		end
	end
end


class "Lux"

function Lux:__init()	
	print("Loaded [Auto] ".. myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end
function Lux:LoadSpells()
	Q = {Range = 1175, Width = 50,Delay = 0.25, Speed = 1200, Collision = true}
	W = {Range = 1075, Width = 120,Delay = 0.25, Speed = 1400}
	E = {Range = 1000, Width = 350,Delay = 0.25, Speed = 1300}
	R = {Range = 3340,Width = 115, Delay = 1, Speed = math.huge}
end

function Lux:CreateMenu()
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})	
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Light Binding", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 5, step = 1 })	
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })	
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Prismatic Barrier", type = MENU})
	Menu.Skills.W:MenuElement({id = "Mana", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 1 })
	Menu.Skills.W:MenuElement({id = "Damage", name = "Recent Damage Received", value = 15, min = 5, max = 50, step = 5 })
	Menu.Skills.W:MenuElement({id = "Count", name = "Minimum Targets", value = 1, min = 1, max = 5, step = 1 })
		
	Menu.Skills:MenuElement({id = "E", name = "[E] Lucent Singularity", type = MENU})
	Menu.Skills.E:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 5, step = 1 })	
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Cast On Immobile Targets", value = true, toggle = true })
		
	Menu.Skills:MenuElement({id = "R", name = "[R] Final Spark", type = MENU})	
	Menu.Skills.R:MenuElement({id = "Count", name = "Target Count", tooltip = "How many targets we need to be able to hit to auto cast", value = 2, min = 1, max = 5, step = 1 })	
	Menu.Skills.R:MenuElement({id = "Auto", name = "Auto Cast On Target Count", value = true, toggle = true })
	Menu.Skills.R:MenuElement({id = "Killsteal", name = "Auto Killsteal", value = true, toggle = true })
		
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
end

function Lux:Draw()
end

function Lux:PrintDebugSpells()
local count = 0
	for i = 1, Game.MissileCount() do
		local missile = Game.Missile(i)	
		local dist =  HPred:GetDistance(missile.pos, myHero.pos)
		if dist > 100 and dist < 800 then
			count = count + 1
			local screenPos = missile.pos:To2D()
			Draw.Text(missile.name, 13, screenPos.x, screenPos.y+ count * 15)
		end
	end
	local count = 0
	for i = 1, Game.ParticleCount() do
		local particle = Game.Particle(i)		
		local dist =  HPred:GetDistance(particle.pos, myHero.pos)
		if dist > 100 and dist < 800 then
			count = count + 1
			local screenPos = particle.pos:To2D()
			Draw.Text(particle.name, 13, screenPos.x, screenPos.y + count * 15)
		end
	end
end

function Lux:Tick()
	if myHero.dead or Game.IsChatOpen() or IsRecalling()  or IsEvading() or IsAttacking() then return end
	if NextSpellCast > Game.Timer() then return end
	
	if Ready(_Q) then
		self:AutoQ()		
	end
			
	if Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() then
		self:AutoW()
	end
	
	self:AutoE()
			
	if Ready(_R) then
		self:AutoR()
	end
	
	UpdateAllyHealth()
end

function Lux:AutoQ()
	local target, aimPosition = HPred:GetReliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed,Q.Width, Menu.General.ReactionTime:Value(), Q.Collision)
	if target and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range and Menu.Skills.Q.Auto:Value() then
		SpecialCast(HK_Q, aimPosition)		
	elseif Menu.Skills.Combo:Value() then
		--Don't unreliable max range Qs, they will almost never hit...
		local hitRate, aimPosition = HPred:GetUnreliableTarget(myHero.pos, Q.Range* 2 / 3, Q.Delay, Q.Speed, Q.Width, Q.Collision, Menu.Skills.Q.Accuracy:Value(),nil)	
		if hitRate and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
			SpecialCast(HK_Q, aimPosition)
		end	
	end
end

function Lux:AutoW()
	--Find allies who have taken X% damage in the last second. Calculate how many would be hit if we cast W on them
	--Choose ally that results in the most predicted allies hit with W to cast it on
	local aimPositions = {}
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly and AutoUtil:GetDistance(myHero.pos, hero.pos) < W.Range and _allyHealthPercentage[hero.charName] then			
			local deltaLifeLost = _allyHealthPercentage[hero.charName] - CurrentPctLife(hero)
			if deltaLifeLost >= Menu.Skills.W.Damage:Value() then
				--Count how many allies will be hit
				
				if hero == myHero then
					local tempHero = AutoUtil:GetNearestAlly(myHero, W.Range)
					if tempHero then
						hero = tempHero
					end
				end
				
				local aimPosition = HPred:PredictUnitPosition(hero, W.Delay + HPred:GetDistance(myHero.pos, hero.pos) / W.Speed)				
				local targetCount = HPred:GetLineTargetCount(myHero.pos, aimPosition, W.Delay, W.Speed, W.Width, true)
				if targetCount >= Menu.Skills.W.Count:Value() then
					table.insert(aimPositions, {aimPosition, targetCount})		
				end
			end
		end
	end
	
	table.sort(aimPositions, function( a, b ) return a[2] < b[2] end)
	if #aimPositions > 0 then
		SpecialCast(HK_W, aimPositions[1][1])
	end
end

local eMissile
local eParticle

function Lux:IsETraveling()
	return eMissile and eMissile.name and eMissile.name == "LuxLightStrikeKugel"
end

function Lux:IsELanded()
	return eParticle and eParticle.name and string.match(eParticle.name, "E_tar_aoe_sound")
end

function Lux:AutoE()

	if self:IsELanded() then
		if AutoUtil:NearestEnemy(eParticle) < E.Width  then	
			SpecialCast(HK_E)
		end		
	else		
		--Try to cast E or search for missile
		local eData = myHero:GetSpellData(_E)
		if eData.toggleState == 1 then
			--Check if we have the particle or not
			if not self:IsETraveling() then
				for i = 1, Game.MissileCount() do
					local missile = Game.Missile(i)			
					if missile.name == "LuxLightStrikeKugel" and HPred:GetDistance(missile.pos, myHero.pos) < 400 then
						eMissile = missile
						break
					end
				end
			end
		elseif eData.toggleState == 2 then		
			for i = 1, Game.ParticleCount() do 
				local particle = Game.Particle(i)
				if string.match(particle.name, "E_tar_aoe_sound") then
					eParticle = particle
					break
				end
			end			
		elseif Ready(_E) then
			local target, aimPosition = HPred:GetReliableTarget(myHero.pos, E.Range, E.Delay, E.Speed,E.Width, Menu.General.ReactionTime:Value(), E.Collision)
			if Menu.Skills.E.Auto:Value() and target and HPred:GetDistance(myHero.pos, aimPosition) <= E.Range then
				SpecialCast(HK_E, aimPosition)
				eMissile = nil
			elseif Menu.Skills.Combo:Value() then					
				local hitRate, aimPosition = HPred:GetUnreliableTarget(myHero.pos, E.Range, E.Delay, E.Speed, E.Width, E.Collision, Menu.Skills.E.Accuracy:Value(),nil)
				if hitRate then
					SpecialCast(HK_E, aimPosition)
					eMissile = nil
				end
			end
		end
	end	
end

function Lux:AutoR()
	local rDamage= 300 + (myHero:GetSpellData(_R).level -1) * 100 + myHero.ap * 0.75
	--Check if the target has passive on them because that will deal extra damage
	--If the target is a near guarenteed hit then count how many targets it will hit: If enough targets are likely then cast regardless of health
	local target, aimPosition = HPred:GetReliableTarget(myHero.pos, R.Range, R.Delay, R.Speed,R.Width, Menu.General.ReactionTime:Value(), R.Collision)
	if target and HPred:GetDistance(myHero.pos, aimPosition) <= R.Range then
		local thisRDamage = rDamage
		if HPred:HasBuff(target, "LuxIlluminatingFraulein",1) then
			thisRDamage = thisRDamage + 20 + myHero.levelData.lvl * 10 + myHero.ap * 0.2
		end
		
		if Menu.Skills.R.Killsteal:Value() and AutoUtil:CalculateMagicDamage(target, thisRDamage) >= target.health then
			SpecialCast(HK_R, aimPosition)
		elseif Menu.Skills.R.Auto:Value() then
			local targetCount = HPred:GetLineTargetCount(myHero.pos, aimPosition, R.Delay, R.Speed, R.Width, false)
			if targetCount >= Menu.Skills.R.Count:Value() then
				SpecialCast(HK_R, aimPosition)
			end
		end
	end	
end

class "Blitzcrank" 
function Blitzcrank:__init()

	print("Loaded [Auto] ".. myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Blitzcrank:CreateMenu()

	Menu.General:MenuElement({id = "DrawQAim", name = "Draw Q Aim", value = true})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Rocket Grab", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Targets", name = "Targets", type = MENU})	
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy then
			Menu.Skills.Q.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
		end
	end
	Menu.Skills.Q:MenuElement({id = "Immobile", name = "Auto Hook Immobile", value = true})
	Menu.Skills.Q:MenuElement({id = "Range", name = "Minimum Auto Hook Range", value = 300, min = 900, max = 100, step = 50})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 5, step = 1})
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
		
	Menu.Skills:MenuElement({id = "E", name = "[E] Power Fist", type = MENU})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Static Field", type = MENU})
	Menu.Skills.R:MenuElement({id = "KS", name = "Secure Kills", value = true})
	Menu.Skills.R:MenuElement({id = "Count", name = "Target Count", value = 3, min = 1, max = 5, step = 1})
	Menu.Skills.R:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })	
	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })
end

function Blitzcrank:LoadSpells()
	Q = {Range = 925, Width = 120,Delay = 0.25, Speed = 1750,  Collision = true}
	R = {Range = 600 ,Delay = 0.25, Speed = math.huge}
end

function Blitzcrank:Draw()	
	
	if Ready(_Q) and Menu.General.DrawQAim:Value() and self.forcedTarget and self.forcedTarget.alive and self.forcedTarget.visible then	
		local targetOrigin = HPred:PredictUnitPosition(self.forcedTarget, Q.Delay)
		local interceptTime = HPred:GetSpellInterceptTime(myHero.pos, targetOrigin, Q.Delay, Q.Speed)			
		local origin, radius = HPred:UnitMovementBounds(self.forcedTarget, interceptTime, Menu.General.ReactionTime:Value())		
						
		if radius < 25 then
			radius = 25
		end
		
		if self:GetDistance(myHero.pos, origin) > Q.Range then
			Draw.Circle(origin, 25,10, Draw.Color(150, 255, 0,0))
		else
			Draw.Circle(origin, 25,10, Draw.Color(150, 0, 255,0))
			Draw.Circle(origin, radius,1, Draw.Color(150, 255, 255,255))	
		end
	end	
end

function Blitzcrank:Tick()
	if IsRecalling() then return end	
	if NextSpellCast > Game.Timer() then return end
	
	--TODO: Only update whitelist every second
	
	if Ready(_Q) then
		if Menu.Skills.Q.Immobile:Value() then
			local target, aimPosition = HPred:GetReliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed,Q.Width, Menu.General.ReactionTime:Value(), Q.Collision)
			if target and AutoUtil:GetDistance(myHero.pos, aimPosition) >= Menu.Skills.Q.Range:Value() then
				SpecialCast(HK_Q, aimPosition)
			end
		end
		
		if Menu.Skills.Combo:Value() and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() then
			local _whiteList = {}
			for i  = 1,Game.HeroCount(i) do
				local enemy = Game.Hero(i)
				if Menu.Skills.Q.Targets[enemy.charName] and Menu.Skills.Q.Targets[enemy.charName]:Value() then
					_whiteList[enemy.charName] = true
				end
			end
			local hitRate, aimPosition = HPred:GetUnreliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, Q.Width, Q.Collision, Menu.Skills.Q.Accuracy:Value(),_whiteList)	
			if hitRate then
				SpecialCast(HK_Q, aimPosition)
			end
		end
	end	
	
	if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() then
		self:AutoE()
	end
	if Ready(_R) and CurrentPctMana(myHero) >= Menu.Skills.R.Mana:Value() then
	
		
		local target, aimPosition =HPred:GetChannelingTarget(myHero.pos, R.Range, R.Delay, R.Speed, Menu.General.ReactionTime:Value(), R.Collision, R.Width)
			if target and aimPosition then
			Control.CastSpell(HK_R)
		end
		
		local targetCount = AutoUtil:CountEnemiesNear(myHero.pos, R.Range)
		if targetCount >= Menu.Skills.R.Count:Value() or (Menu.Skills.R.KS:Value() and self:CanRKillsteal())then
			Control.CastSpell(HK_R)
		NextSpellCast = .35 + Game.Timer()
		end
	end
end

function Blitzcrank:AutoE()
	--check if we are middle of an auto attack
	if myHero.attackData and myHero.attackData.target and myHero.attackData.state == STATE_WINDUP then
		local target = HPred:GetEnemyHeroByHandle(myHero.attackData.target)
		if target and target.isEnemy then		
			local windupRemaining = myHero.attackData.endTime - Game.Timer() - myHero.attackData.windDownTime
			if windupRemaining < .15 then
				DelayAction(function()Control.CastSpell(HK_E) end,.10)
			end
		end
	end
end



function Blitzcrank:CanRKillsteal()
	local rDamage= 250 + (myHero:GetSpellData(_R).level -1) * 125 + myHero.ap 
	for i  = 1,Game.HeroCount(i) do
		local enemy = Game.Hero(i)
		if enemy.alive and enemy.isEnemy and enemy.visible and enemy.isTargetable and AutoUtil:GetDistance(myHero.pos, enemy.pos) <= R.Range then
			local damage = AutoUtil:CalculateMagicDamage(enemy, rDamage)
			if damage >= enemy.health then
				return true
			end
		end
	end
end


class "Lulu" 
function Lulu:__init()

	print("Loaded [Auto] ".. myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Lulu:CreateMenu()

	AutoUtil:SupportMenu(Menu)
	
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	if AutoUtil:GetExhaust() then
		Menu.Skills:MenuElement({id = "Exhaust", name = "Exhaust", type = MENU})	
		Menu.Skills.Exhaust:MenuElement({id ="Targets", name ="Target List", type = MENU})
		for i = 1, Game.HeroCount() do
			local hero = Game.Hero(i)
			if hero.isEnemy then
				Menu.Skills.Exhaust.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
			end
		end
		Menu.Skills.Exhaust:MenuElement({id = "Health", tooltip ="How low health allies must be to use exhaust", name = "Ally Health", value = 40, min = 1, max = 100, step = 5 })	
		Menu.Skills.Exhaust:MenuElement({id = "Radius", tooltip ="How close targets must be to allies to use exhaust", name = "Peel Distance", value = 200, min = 100, max = 1000, step = 25 })
		Menu.Skills.Exhaust:MenuElement({id="Enabled", name="Enabled", value = false})	
	end
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Glitterlance", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Immobile", name = "Cast On Immobile", value = true})
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 5, step = 1})
		
	Menu.Skills:MenuElement({id = "W", name = "[E] Whimsy", type = MENU})
	Menu.Skills.W:MenuElement({id = "Life", name = "Peel Life", value = 75, min = 0, max = 100, step = 5 })
	Menu.Skills.W:MenuElement({id = "Range", name = "Peel Radius", value = 300, min = 100, max = 800, step = 50 })
	Menu.Skills.W:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Help, Pix!", type = MENU})
	Menu.Skills.E:MenuElement({id = "Killsteal", name = "Killsteal", value = true})
	Menu.Skills.E:MenuElement({id = "Targets", name = "Buff Ally List", type = MENU})
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and Hero ~= myHero then
			Menu.Skills.E.Targets:MenuElement({id = Hero.charName, name = Hero.charName, value = true, toggle = true})
		end
	end
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Wild Growth", type = MENU})	
	Menu.Skills.R:MenuElement({id = "PeelTargets", name = "Ally Peel List", type = MENU})
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly then
			Menu.Skills.R.PeelTargets:MenuElement({id = Hero.charName, name = Hero.charName, value = true, toggle = true})
		end
	end
	Menu.Skills.R:MenuElement({id = "Life", name = "Current Percent Life", value = 25, min = 0, max = 100, step = 5 })
	Menu.Skills.R:MenuElement({id = "Damage", name = "Recent Damage Received", value = 25, min = 5, max = 50, step = 5 })
	
	
	Menu.Skills.R:MenuElement({id = "KnockupTargets", name = "Ally Knockup List", type = MENU})
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly then
			Menu.Skills.R.KnockupTargets:MenuElement({id = Hero.charName, name = Hero.charName, value = true, toggle = true})
		end
	end
	Menu.Skills.R:MenuElement({id = "Count", name = "Enemy Count", value = 2, min = 1, max = 5, step = 1 })		
	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })
end

function Lulu:LoadSpells()
	Q = {Range = 925, Width = 45,Delay = 0.25, Speed = 1500}
	W = {Range = 650, Delay = 0.25, Speed = 1600}
	E = {Range = 650, Delay = 0.25, Speed = math.huge}	
	R = {Range = 900, Width = 400, Delay = 0.25, Speed = math.huge}
end

function Lulu:Draw()
end

function Lulu:Tick()
	if IsRecalling() then return end	
	if NextSpellCast > Game.Timer() then return end
	
	--Use ult to save ally or knockup enemy
	if Ready(_R) then
		self:AutoR()
	end
	
	--Try to peel for allies using polymorph
	if Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() then
		self:AutoW()
	end	
	
	--Try to killsteal with E
	if Ready(_E) then
		if Menu.Skills.E.Killsteal:Value() then
			self:KillstealE()
		end
		if CurrentPCtMana(myHero) >= Menu.Skills.E.Mana:Value() then
			self:BuffE()
		end
	end
	
	if Ready(_Q) then
		self:AutoQ()
	end
	
	--Use Support Items
	AutoUtil:UseSupportItems()
	
	--Use Exhaust if we have it
	if Menu.Skills.Exhaust and Menu.Skills.Exhaust.Enabled:Value() then
		AutoUtil.AutoExhaust()
	end
end

function Lulu:AutoQ()
	local target, aimPosition = HPred:GetReliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed,Q.Width, Menu.General.ReactionTime:Value(), Q.Collision)
	if target and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
		SpecialCast(HK_Q, aimPosition)		
	elseif Menu.Skills.Combo:Value() then
		--Don't unreliable max range Qs, they will almost never hit...
		local hitRate, aimPosition = HPred:GetUnreliableTarget(myHero.pos, Q.Range* 2 / 3, Q.Delay, Q.Speed, Q.Width, Q.Collision, Menu.Skills.Q.Accuracy:Value(),nil)	
		if hitRate and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
			SpecialCast(HK_Q, aimPosition)
		end	
	end
end

function Lulu:AutoW()
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if HPred:CanTarget(enemy) and HPred:GetDistance(myHero.pos, enemy.pos) <= W.Range then	
			local nearestAlly = AutoUtil:GetNearestAlly(enemy, Menu.Skills.W.Range:Value())
			if nearestAlly and Menu.Skills.W.Life:Value() >= CurrentPctLife(nearestAlly) then
				SpecialCast(HK_W, enemy)
			end
		end
	end		
end

function Lulu:BuffE()
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if  hero.isAlly and hero.isTargetable and hero.alive and AutoUtil:GetDistance(myHero.pos, hero.pos) <= E.Range and Menu.Skills.E.Targets[hero.charName] and Menu.Skills.E.Targets[hero.charName]:Value() then			
			local targetHandle = nil			
			if hero.activeSpell and hero.activeSpell.valid and hero.activeSpell.target then
				targetHandle = hero.activeSpell.target
			end			
			if targetHandle then 		
				local Enemy = GetHeroByHandle(targetHandle)
				if Enemy and Enemy.isEnemy then
					SpecialCast(HK_E, hero)
				end
			end
		end
	end
end

function Lulu:KillstealE()
	local eDamage= 80 + (myHero:GetSpellData(_R).level -1) * 30 + myHero.ap * 0.4
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if HPred:CanTarget(enemy) and HPred:GetDistance(myHero.pos, enemy.pos) <= E.Range and AutoUtil:CalculateMagicDamage(enemy, eDamage) >= enemy.health then
			SpecialCast(HK_E, enemy)			
		end
	end
end

function Lulu:AutoR()
	for i = 1, Game.HeroCount() do
		local ally = Game.Hero(i)
		if ally.isAlly and HPred:CanTargetALL(ally) and HPred:GetDistance(myHero.pos, ally.pos) <= R.Range then
			if Menu.Skills.R.KnockupTargets[ally.charName] and Menu.Skills.R.KnockupTargets[ally.charName]:Value() then		
				local targetCount = AutoUtil:CountEnemiesNear(ally.pos, R.Width)
				if targetCount >= Menu.Skills.R.Count:Value() then
					SpecialCast(HK_R, ally)
				end
			end
			if Menu.Skills.R.PeelTargets[ally.charName] and Menu.Skills.R.PeelTargets[ally.charName]:Value() and CurrentPctLife(ally) <= Menu.Skills.R.Life:Value() then
				local deltaLifeLost = _allyHealthPercentage[ally.charName] - CurrentPctLife(ally)
				if deltaLifeLost >= Menu.Skills.Damage:Value() then
					SpecialCast(HK_R, ally)
				end
			end
		end
	end
end

class "MissFortune" 
function MissFortune:__init()

	print("Loaded [Auto] ".. myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function MissFortune:CreateMenu()
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Double Up", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Minion Crit Bounce", value = true})
	Menu.Skills.Q:MenuElement({id = "Hero", name = "Auto 2X Hero Bounce", value = true})
	Menu.Skills.Q:MenuElement({id = "Killsteal", name = "Killsteal", value = true})
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Make it Rain", type = MENU})
	Menu.Skills.E:MenuElement({id = "Auto", name = "Cast on Immobile Targets", value = true})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 20, min = 5, max = 100, step = 5 })
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
end

function MissFortune:LoadSpells()
	Q = {Range = 650, Delay = .25, Speed = 1800}
	E = {Range = 1000, Delay = .5, Width = 400}
end

function MissFortune:Draw()
end

function MissFortune:Tick()
	if IsRecalling() then return end	
	if NextSpellCast > Game.Timer() then return end
	if self:IsRActive() then return end
	
	self:FindPassiveMark()
	
	if Ready(_Q) then
		self:AutoQ()
	end
	
	if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() then
		self:AutoE()
	end
end

function MissFortune:IsRActive()
	return myHero.activeSpell and myHero.activeSpell.valid and myHero.activeSpell.name =="MissFortuneBulletTime"
end

function MissFortune:AutoQ()
	--Search for players we can kill
	if Menu.Skills.Q.Killsteal:Value() then
		for i = 1, Game.HeroCount() do
			local t = Game.Hero(i)
			if HPred:GetDistance(myHero.pos, t.pos) < Q.Range + t.boundingRadius and HPred:CanTarget(t) and self:GetQDamage(t) >= t.health then			
				SpecialCast(HK_Q, t)
			end
		end		
	end
	
	--Search for players we can target that will bounce to other players
	if Menu.Skills.Q.Hero:Value() and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() then
		for i = 1, Game.HeroCount() do
			local t = Game.Hero(i)
			if HPred:GetDistance(myHero.pos, t.pos) < Q.Range + t.boundingRadius and HPred:CanTarget(t) then
				local bounceTarget = self:GetQBounce(t)
				if bounceTarget and HPred:CanTarget(bounceTarget) and string.match(bounceTarget.type, "Hero") then
					SpecialCast(HK_Q, t)
				end
			end
		end
	end
	
	--Search for minions that we can bounce Q off of
	if (Menu.Skills.Q.Auto:Value() and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value()) or Menu.Skills.Combo:Value() then
		for i = 1, Game.MinionCount() do
			local t = Game.Minion(i)
			if HPred:GetDistance(myHero.pos, t.pos) < Q.Range + t.boundingRadius and HPred:CanTarget(t) and (Menu.Skills.Combo:Value() or self:GetQDamage(t) >= t.health) then
				local bounceTarget = self:GetQBounce(t)
				if bounceTarget and HPred:CanTarget(bounceTarget) and string.match(bounceTarget.type, "Hero") then
					SpecialCast(HK_Q, t)
				end
			end
		end
	end
	
	--Combo Q
	if Menu.Skills.Combo:Value() then		
		for i = 1, Game.HeroCount() do
			local t = Game.Hero(i)
			if HPred:GetDistance(myHero.pos, t.pos) < Q.Range + t.boundingRadius and HPred:CanTarget(t) then
				SpecialCast(HK_Q, t)
			end
		end
	end	
end

--Only cast on immobile targets, we dont want to waste it if not.
function MissFortune:AutoE()
	local target, aimPosition =HPred:GetImmobileTarget(myHero.pos, E.Range, E.Delay, math.huge,Menu.General.ReactionTime:Value())
	if target and aimPosition then
		SpecialCast(HK_E, aimPosition)
	end
end

local _nextPassiveSearch = Game.Timer()
local _passiveSearchFrequency = .25
local _passiveSearchDistance = 1000
local _passiveTarget
function MissFortune:FindPassiveMark()
	if _nextPassiveSearch > Game.Timer() then return end
	_nextPassiveSearch = Game.Timer() + _passiveSearchFrequency
	
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		if HPred:GetDistance(myHero.pos, particle.pos) < _passiveSearchDistance and string.match(particle.name, "_P_Mark") then			
			_passiveTarget = HPred:GetObjectByPosition(particle.pos)
		end
	end
end

local _passiveDamagePctByLevel = { .50, .50, .60, .60, .60, .60, .60, .70, .70, .80, .80,.90, .90, 1,1,1,1,1 }
function MissFortune:GetQDamage(target)
	local qDamage= myHero:GetSpellData(_Q).level * 20  + myHero.ap * 0.35+ myHero.totalDamage
	
	--Boost if they dont have love tap on them
	if target ~= _passiveTarget then
		local bonusDamage = myHero.totalDamage * _passiveDamagePctByLevel[myHero.levelData.lvl]
		--Passive damage is half to minion
		if not string.match(target.type, "Hero") then
			bonusDamage = bonusDamage / 2
		end		
		qDamage = qDamage + bonusDamage
	end
	local qDamage = AutoUtil:CalculatePhysicalDamage(target, qDamage)
	return qDamage
end

function MissFortune:GetQBounce(target)
	local targets = {}
	local angleTargetingWeight = 5
	local bounceTargetingDelay = Q.Delay + HPred:GetDistance(myHero.pos, target.pos) / Q.Speed
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		local predictedPosition = HPred:PredictUnitPosition(t, bounceTargetingDelay)
		if HPred:CanTarget(t) and t ~= target and HPred:IsPointInArc(myHero.pos, target.pos, predictedPosition, 40, 475+ t.boundingRadius) then
			table.insert(targets, {t, HPred:GetDistance(target.pos, predictedPosition) + angleTargetingWeight * math.abs(HPred:Angle(target.pos, predictedPosition) - HPred:Angle(myHero.pos, target.pos))})
		end
	end		
	for i = 1, Game.MinionCount() do
		local t = Game.Minion(i)
		local predictedPosition = HPred:PredictUnitPosition(t, bounceTargetingDelay)
		if HPred:CanTarget(t) and t ~= target and HPred:IsPointInArc(myHero.pos, target.pos, predictedPosition, 40, 475 + t.boundingRadius) then
			table.insert(targets, {t, HPred:GetDistance(target.pos, predictedPosition) + angleTargetingWeight * math.abs(HPred:Angle(target.pos, predictedPosition) - HPred:Angle(myHero.pos, target.pos))})
		end
	end
	
	if #targets > 0 then
		table.sort(targets, function( a, b ) return a[2] < b[2] end)
		return targets[1][1]
	end
end

class "Karthus" 
local _canUltCount = 0
local _targetUltData = {}
function Karthus:__init()

	print("Loaded [Auto] ".. myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Karthus:CreateMenu()
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Lay Waste", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast on Immobile", value = true})
	Menu.Skills.Q:MenuElement({id = "AccuracyAuto", name = "Auto Accuracy", value = 4, min = 1, max = 5, step = 1})
	Menu.Skills.Q:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy", value = 3, min = 1, max = 5, step = 1})
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "W", name = "[W] Wall of Pain", type = MENU})
	Menu.Skills.W:MenuElement({id = "Auto", name = "Auto Cast on Immobile", value = true})
	Menu.Skills.W:MenuElement({id = "Assist", name = "Assist Key",value = false,  key = 0x71})	
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Defile", type = MENU})
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Active When Enemy In Range", value = true})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Requiem", type = MENU})
	Menu.Skills.R:MenuElement({id = "Auto", name = "Auto Use In Passive (If Will Kill)", value = true})
	Menu.Skills.R:MenuElement({id = "Draw", name = "Draw Kill Count", value = true})
	
	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
end

function Karthus:LoadSpells()
	Q = {Range = 874, Width = 100, Delay = .5, Speed = math.huge}
	W = {Range = 1000, Width = 800, Delay = .25, Speed = math.huge}
	E = { Range = 425 }
end

function Karthus:Draw()
	if Ready(_R) and _canUltCount > 0 and Menu.Skills.R.Draw:Value() then
		local drawPos = myHero.pos:To2D()
		Draw.Text("[R] Can Kill " .. _canUltCount .. " Enemies!", 24, 100, 200)
	end
end

function Karthus:Tick()
	if IsRecalling() then return end	
	if NextSpellCast > Game.Timer() then return end
	
	if Ready(_E) then
		self:AutoE()
	end
	
	if Ready(_R) then	
		self:AutoR()
	end
	
	if Ready(_W) then
		self:AutoW()
	end	
	
	if Ready(_Q) then
		self:AutoQ()
	end
end


function Karthus:AutoQ()

	local hasCast = false
	if Menu.Skills.Q.Auto:Value() then
		local target, aimPosition = HPred:GetReliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed,Q.Width, Menu.General.ReactionTime:Value(), Q.Collision)
		if target and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
			SpecialCast(HK_Q, aimPosition)
			hasCast = true
		end
	end
	
	if not hasCast and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() then
		--TODO: Try Killstealing with Q? Will require some extra logic for sure.
		if Menu.Skills.Combo:Value() then
			local hitRate, aimPosition = HPred:GetUnreliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, Q.Width, Q.Collision, Menu.Skills.Q.AccuracyCombo:Value(), nil)	
			if hitRate and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
				SpecialCast(HK_Q, aimPosition)
			end
		elseif Menu.Skills.Q.Auto:Value() then
			local hitRate, aimPosition = HPred:GetUnreliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, Q.Width, Q.Collision, Menu.Skills.Q.AccuracyAuto:Value(), nil)	
			if hitRate and HPred:GetDistance(myHero.pos, aimPosition) <= Q.Range then
				SpecialCast(HK_Q, aimPosition)
			end
		end
	end
end

function Karthus:AutoW()
	--If we're pushing the assisted aim W key then find a unreliable target we can hit and cast on them (nearest mouse)
	if Menu.Skills.W.Assist:Value() then		
		local distance, target = AutoUtil:NearestEnemy(myHero)
		if target and distance < W.Range then		
			local castPos = HPred:PredictUnitPosition(target, W.Delay)
			if HPred:GetDistance(myHero.pos, castPos) < W.Range / 3 * 2 then
				SpecialCast(HK_W, castPos)
			end
		end
	end	
	
	if Menu.Skills.Combo:Value() then
		--Get the most targets we can hit?
		local distance, target = AutoUtil:NearestEnemy(myHero)
		if target and distance < W.Range then		
			local castPos = HPred:PredictUnitPosition(target, W.Delay)
			if HPred:GetDistance(myHero.pos, castPos) < W.Range / 3 * 2 then
				SpecialCast(HK_W, castPos)
			end
		end
	end
end

local _eActivationTime = 0

function Karthus:AutoE()
	local eData = myHero:GetSpellData(_E)
	local distance, target = AutoUtil:NearestEnemy(myHero)
	if distance < E.Range then
		if eData.toggleState ==1 and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() then
			_eActivationTime = Game.Timer()
			Control.CastSpell(HK_E)
		elseif eData.toggleState == 2 and _eActivationTime > 0 and CurrentPctMana(myHero) < Menu.Skills.E.Mana:Value() then
			Control.CastSpell(HK_E)
			_eActivationTime = 0		
		end
	--Don't deactivate E if we are the ones who turned it on!
	elseif eData.toggleState == 2 and _eActivationTime > 0 then
		_eActivationTime = 0
		Control.CastSpell(HK_E)
	end
end

function Karthus:AutoR()
	_canUltCount = 0
	local rDamage= 250 + (myHero:GetSpellData(_R).level -1) * 150 + myHero.ap * 0.75
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if HPred:CanTarget(t) then
			_targetUltData[t.charName] = {}
			_targetUltData[t.charName]["LastVisible"] = Game.Timer()
			_targetUltData[t.charName]["Damage"] = AutoUtil:CalculateMagicDamage(t, rDamage)
			_targetUltData[t.charName]["Life"] = t.health
		elseif not t.alive and _targetUltData[t.charName] then
			_targetUltData[t.charName] = nil
		end
	end
	
	
	for _, target in pairs(_targetUltData) do
		if Game.Timer() - target.LastVisible < 3 and target.Damage > target.Life then
			_canUltCount = _canUltCount + 1		
		end
	end	
	
	local hasBuff, timeRemaining = HPred:HasBuff(myHero, "KarthusDeathDefiedBuff")
	if hasBuff and _canUltCount > 0 and Menu.Skills.R.Auto:Value() and timeRemaining < 4 then	
		Control.CastSpell(HK_R)
	end
end


class "HPred"

Callback.Add("Tick", function() HPred:Tick() end)

local _reviveQueryFrequency = .2
local _lastReviveQuery = Game.Timer()
local _reviveLookupTable = 
	{ 
		["LifeAura.troy"] = 4, 
		["ZileanBase_R_Buf.troy"] = 3,
		["Aatrox_Base_Passive_Death_Activate"] = 3
		
		--TwistedFate_Base_R_Gatemarker_Red
			--String match would be ideal.... could be different in other skins
	}

--Stores a collection of spells that will cause a character to blink
	--Ground targeted spells go towards mouse castPos with a maximum range
	--Hero/Minion targeted spells have a direction type to determine where we will land relative to our target (in front of, behind, etc)
	
--Key = Spell name
--Value = range a spell can travel, OR a targeted end position type, OR a list of particles the spell can teleport to	
local _blinkSpellLookupTable = 
	{ 
		["EzrealArcaneShift"] = 475, 
		["RiftWalk"] = 500,
		
		--Ekko and other similar blinks end up between their start pos and target pos (in front of their target relatively speaking)
		["EkkoEAttack"] = 0,
		["AlphaStrike"] = 0,
		
		--Katarina E ends on the side of her target closest to where her mouse was... 
		["KatarinaE"] = -255,
		
		--Katarina can target a dagger to teleport directly to it: Each skin has a different particle name. This should cover all of them.
		["KatarinaEDagger"] = { "Katarina_Base_Dagger_Ground_Indicator","Katarina_Skin01_Dagger_Ground_Indicator","Katarina_Skin02_Dagger_Ground_Indicator","Katarina_Skin03_Dagger_Ground_Indicator","Katarina_Skin04_Dagger_Ground_Indicator","Katarina_Skin05_Dagger_Ground_Indicator","Katarina_Skin06_Dagger_Ground_Indicator","Katarina_Skin07_Dagger_Ground_Indicator" ,"Katarina_Skin08_Dagger_Ground_Indicator","Katarina_Skin09_Dagger_Ground_Indicator"  }, 
	}

local _blinkLookupTable = 
	{ 
		"global_ss_flash_02.troy",
		"Lissandra_Base_E_Arrival.troy",
		"LeBlanc_Base_W_return_activation.troy"
		--TODO: Check if liss/leblanc have diff skill versions. MOST likely dont but worth checking for completion sake
		
		--Zed uses 'switch shadows'... It will require some special checks to choose the shadow he's going TO not from...
		--Shaco deceive no longer has any particles where you jump to so it cant be tracked (no spell data or particles showing path)
		
	}

local _cachedRevives = {}
local _cachedTeleports = {}
local _movementHistory = {}

function HPred:Tick()
	--Check for revives and record them	
	if Game.Timer() - _lastReviveQuery < _reviveQueryFrequency then return end
	_lastReviveQuery=Game.Timer()
	
	--Remove old cached revives
	for _, revive in pairs(_cachedRevives) do
		if Game.Timer() > revive.expireTime + .5 then
			_cachedRevives[_] = nil
		end
	end
	
	--Cache new revives
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		if not _cachedRevives[particle.networkID] and  _reviveLookupTable[particle.name] then
			_cachedRevives[particle.networkID] = {}
			_cachedRevives[particle.networkID]["expireTime"] = Game.Timer() + _reviveLookupTable[particle.name]			
			local target = self:GetHeroByPosition(particle.pos)
			if target.isEnemy then				
				_cachedRevives[particle.networkID]["target"] = target
				_cachedRevives[particle.networkID]["pos"] = target.pos
				_cachedRevives[particle.networkID]["isEnemy"] = target.isEnemy	
			end
		end
	end
	
	--Update hero movement history	
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		self:UpdateMovementHistory(t)
	end
	
	--Remove old cached teleports	
	for _, teleport in pairs(_cachedTeleports) do
		if Game.Timer() > teleport.expireTime + .5 then
			_cachedTeleports[_] = nil
		end
	end	
	
	--Update teleport cache
	self:CacheTeleports()
	
	
end

function HPred:GetEnemyNexusPosition()
	--This is slightly wrong. It represents fountain not the nexus. Fix later.
	if myHero.team == 100 then return Vector(14340, 171.977722167969, 14390); else return Vector(396,182.132507324219,462); end
end


function HPred:GetReliableTarget(source, range, delay, speed, radius, timingAccuracy, checkCollision)
	--TODO: Target whitelist. This will target anyone which is definitely not what we want
	--For now we can handle in the champ script. That will cause issues with multiple people in range who are goood targets though.
	
	
	--Get hourglass enemies
	target, aimPosition =self:GetHourglassTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get reviving target
	target, aimPosition =self:GetRevivingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get channeling enemies
	target, aimPosition =self:GetChannelingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
		if target and aimPosition then
		return target, aimPosition
	end
	
	--Get teleporting enemies
	target, aimPosition =self:GetTeleportingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)	
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get instant dash enemies
	target, aimPosition =self:GetInstantDashTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end	
	
	--Get dashing enemies
	target, aimPosition =self:GetDashingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius, midDash)
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get stunned enemies
	local target, aimPosition =self:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get blink targets
	--target, aimPosition =self:GetBlinkTarget(source, range, speed, delay, checkCollision, radius)
	--if target and aimPosition then
	--	return target, aimPosition
	--end	
end

--Will return how many allies or enemies will be hit by a linear spell based on current waypoint data.
function HPred:GetLineTargetCount(source, aimPos, delay, speed, width, targetAllies)
	local targetCount = 0
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if self:CanTargetALL(t) and ( targetAllies or t.isEnemy) then
			local predictedPos = self:PredictUnitPosition(t, delay+ self:GetDistance(source, t.pos) / speed)
			if predictedPos:To2D().onScreen then
				local proj1, pointLine, isOnSegment = self:VectorPointProjectionOnLineSegment(source, aimPos, predictedPos)
				if proj1 and isOnSegment and (self:GetDistanceSqr(predictedPos, proj1) <= (t.boundingRadius + width) ^ 2) then
					targetCount = targetCount + 1
				end
			end
		end
	end
	return targetCount
end

--Will return the valid target who has the highest hit chance and meets all conditions (minHitChance, whitelist check, etc)
function HPred:GetUnreliableTarget(source, range, delay, speed, radius, checkCollision, minimumHitChance, whitelist)
	local _validTargets = {}
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if self:CanTarget(t) and (not whitelist or whitelist[t.charName]) then			
			local hitChance, aimPosition = self:GetHitchance(source, t, range, delay, speed, radius, checkCollision)		
			if hitChance >= minimumHitChance and aimPosition:To2D().onScreen then
				_validTargets[t.charName] = {["hitChance"] = hitChance, ["aimPosition"] = aimPosition}
			end
		end
	end
	
	local rHitChance = 0
	local rAimPosition
	for targetName, targetData in pairs(_validTargets) do
		if targetData.hitChance > rHitChance then
			rHitChance = targetData.hitChance
			rAimPosition = targetData.aimPosition
		end		
	end
	
	if rHitChance >= minimumHitChance then
		return rHitChance, rAimPosition
	end	
end

function HPred:GetHitchance(source, target, range, delay, speed, radius, checkCollision)	
	local hitChance = 1	
	
	local aimPosition = self:PredictUnitPosition(target, delay + self:GetDistance(source, target.pos) / speed)	
	local interceptTime = self:GetSpellInterceptTime(source, aimPosition, delay, speed)
	local reactionTime = self:PredictReactionTime(target, .1)
	
	--If they just now changed their path then assume they will keep it for at least a short while... slightly higher chance
	if _movementHistory and _movementHistory[target.charName] and Game.Timer() - _movementHistory[target.charName]["ChangedAt"] < .25 then
		hitChance = 2
	end

	--If they are standing still give a higher accuracy because they have to take actions to react to it
	if not target.pathing or not target.pathing.hasMovePath then
		hitChance = 2
	end	
	
	
	local origin,movementRadius = self:UnitMovementBounds(target, interceptTime, reactionTime)
	--Our spell is so wide or the target so slow or their reaction time is such that the spell will be nearly impossible to avoid
	if movementRadius - target.boundingRadius <= radius /2 then
		origin,movementRadius = self:UnitMovementBounds(target, interceptTime, 0)
		if movementRadius - target.boundingRadius <= radius /2 then
			hitChance = 4
		else		
			hitChance = 3
		end
	end	
	
	--If they are casting a spell then the accuracy will be fairly high. if the windup is longer than our delay then it's quite likely to hit. 
	--Ideally we would predict where they will go AFTER the spell finishes but that's beyond the scope of this prediction
	if target.activeSpell and target.activeSpell.valid then
		if target.activeSpell.startTime + target.activeSpell.windup - Game.Timer() >= delay then
			hitChance = 5
		else			
			hitChance = 3
		end
	end
	
	--Check for out of range
	if self:GetDistance(myHero.pos, aimPosition) >= range then
		hitChance = -1
	end
	
	--Check minion block
	if hitChance > 0 and checkCollision then	
		if self:CheckMinionCollision(source, aimPosition, delay, speed, radius) then
			hitChance = -1
		end
	end
	
	return hitChance, aimPosition
end

function HPred:PredictReactionTime(unit, minimumReactionTime)
	local reactionTime = minimumReactionTime
	
	--If the target is auto attacking increase their reaction time by .15s - If using a skill use the remaining windup time
	if unit.activeSpell and unit.activeSpell.valid then
		local windupRemaining = unit.activeSpell.startTime + unit.activeSpell.windup - Game.Timer()
		if windupRemaining > 0 then
			reactionTime = windupRemaining
		end
	end
	
	--If the target is recalling and has been for over .25s then increase their reaction time by .25s
	local isRecalling, recallDuration = self:GetRecallingData(unit)	
	if isRecalling and recallDuration > .25 then
		reactionTime = .25
	end
	
	return reactionTime
end

function HPred:GetDashingTarget(source, range, delay, speed, dashThreshold, checkCollision, radius, midDash)

	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if t.isEnemy and t.pathing.hasMovePath and t.pathing.isDashing and t.pathing.dashSpeed>500  then
			local dashEndPosition = t:GetPath(1)
			if self:GetDistance(source, dashEndPosition) <= range  and dashEndPosition:To2D().onScreen then				
				--The dash ends within range of our skill. We now need to find if our spell can connect with them very close to the time their dash will end
				local dashTimeRemaining = self:GetDistance(t.pos, dashEndPosition) / t.pathing.dashSpeed
				local skillInterceptTime = self:GetSpellInterceptTime(myHero.pos, dashEndPosition, delay, speed)
				local deltaInterceptTime =skillInterceptTime - dashTimeRemaining
				if deltaInterceptTime > 0 and deltaInterceptTime < dashThreshold and (not checkCollision or not self:CheckMinionCollision(source, dashEndPosition, delay, speed, radius)) then
					target = t
					aimPosition = dashEndPosition
					return target, aimPosition
				end
			end			
		end
	end
end

function HPred:GetHourglassTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if t.isEnemy and t.pos:To2D().onScreen then		
			local success, timeRemaining = self:HasBuff(t, "zhonyasringshield")
			if success then
				local spellInterceptTime = self:GetSpellInterceptTime(myHero.pos, t.pos, delay, speed)
				local deltaInterceptTime = spellInterceptTime - timeRemaining
				if spellInterceptTime > timeRemaining and deltaInterceptTime < timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
					target = t
					aimPosition = t.pos
					return target, aimPosition
				end
			end
		end
	end
end

function HPred:GetRevivingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for _, revive in pairs(_cachedRevives) do	
		if revive.isEnemy and revive.pos:To2D().onScreen then
			local interceptTime = self:GetSpellInterceptTime(source, revive.pos, delay, speed)
			if interceptTime > revive.expireTime - Game.Timer() and interceptTime - revive.expireTime - Game.Timer() < timingAccuracy then
				target = revive.target
				aimPosition = revive.pos
				return target, aimPosition
			end
		end
	end	
end

function HPred:GetInstantDashTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if t.isEnemy and t.activeSpell and t.activeSpell.valid and _blinkSpellLookupTable[t.activeSpell.name] then
			local windupRemaining = t.activeSpell.startTime + t.activeSpell.windup - Game.Timer()
			if windupRemaining > 0 then
				local endPos
				local blinkRange = _blinkSpellLookupTable[t.activeSpell.name]
				if type(blinkRange) == "table" then
					--Find the nearest matching particle to our mouse
					local target, distance = self:GetNearestParticleByNames(t.pos, blinkRange)
					if target and distance < 250 then					
						endPos = target.pos		
					end
				elseif blinkRange > 0 then
					endPos = Vector(t.activeSpell.placementPos.x, t.activeSpell.placementPos.y, t.activeSpell.placementPos.z)					
					endPos = t.activeSpell.startPos + (endPos- t.activeSpell.startPos):Normalized() * math.min(self:GetDistance(t.activeSpell.startPos,endPos), range)
				else
					local blinkTarget = self:GetObjectByHandle(t.activeSpell.target)
					if blinkTarget then				
						local offsetDirection						
						
						--We will land in front of our target relative to our starting position
						if blinkRange == 0 then						
							offsetDirection = (blinkTarget.pos - t.pos):Normalized()
						--We will land behind our target relative to our starting position
						elseif blinkRange == -1 then						
							offsetDirection = (t.pos-blinkTarget.pos):Normalized()
						--They can choose which side of target to come out on , there is no way currently to read this data so we will only use this calculation if the spell radius is large
						elseif blinkRange == -255 then
							if radius > 250 then
								endPos = blinkTarget.pos
							end							
						end
						
						if offsetDirection then
							endPos = blinkTarget.pos - offsetDirection * 150
						end
						
					end
				end	
				
				local interceptTime = self:GetSpellInterceptTime(myHero.pos, endPos, delay,speed)
				local deltaInterceptTime = interceptTime - windupRemaining
				if self:GetDistance(source, endPos) <= range and endPos:To2D().onScreen and deltaInterceptTime < timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, endPos, delay, speed, radius)) then
					target = t
					aimPosition = endPos
					return target,aimPosition					
				end
			end
		end
	end
end

function HPred:GetBlinkTarget(source, range, speed, delay, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		if particle and _blinkLookupTable[particle.name] and self:GetDistance(source, particle.pos) < range and particle.pos:To2D().onScreen then
			local pPos = particle.pos
			for k,v in pairs(self:GetEnemyHeroes()) do
				local t = v
				if t and t.isEnemy and self:GetDistance(t.pos, pPos) < t.boundingRadius then
					if (not checkCollision or not self:CheckMinionCollision(source, pPos, delay, speed, radius)) then
						target = t
						aimPosition = pPos
						return target,aimPosition
					end
				end
			end
		end
	end
end

function HPred:GetChannelingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		local interceptTime = self:GetSpellInterceptTime(myHero.pos, t.pos, delay, speed)
		if self:CanTarget(t) and self:GetDistance(source, t.pos) <= range and t.pos:To2D().onScreen and self:IsChannelling(t, interceptTime) and (not checkCollision or not self:CheckMinionCollision(source, t.pos, delay, speed, radius)) then
			target = t
			aimPosition = t.pos	
			return target, aimPosition
		end
	end
end

function HPred:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if self:CanTarget(t) and self:GetDistance(source, t.pos) <= range and t.pos:To2D().onScreen then
			local immobileTime = self:GetImmobileTime(t)
			
			local interceptTime = self:GetSpellInterceptTime(source, t.pos, delay, speed)
			if immobileTime - interceptTime > timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, t.pos, delay, speed, radius)) then
				target = t
				aimPosition = t.pos
				return target, aimPosition
			end
		end
	end
end

function HPred:RecordTeleport(target, aimPos, endTime)
	_cachedTeleports[target.networkID] = {}
	_cachedTeleports[target.networkID]["target"] = target
	_cachedTeleports[target.networkID]["aimPos"] = aimPos
	_cachedTeleports[target.networkID]["expireTime"] = endTime + Game.Timer()
end

function HPred:CacheTeleports()
	--Get enemies who are teleporting to towers
	for i = 1, Game.TurretCount() do
		local turret = Game.Turret(i);
		if turret.isEnemy and not _cachedTeleports[turret.networkID] then
			local hasBuff, expiresAt = self:HasBuff(turret, "teleport_target")
			if hasBuff then
				self:RecordTeleport(turret, self:GetTeleportOffset(turret.pos,223.31),expiresAt)
			end
		end
	end	
	
	--Get enemies who are teleporting to wards	
	for i = 1, Game.WardCount() do
		local ward = Game.Ward(i);
		if ward.isEnemy and not _cachedTeleports[ward.networkID] then
			local hasBuff, expiresAt = self:HasBuff(ward, "teleport_target")
			if hasBuff then
				self:RecordTeleport(ward, self:GetTeleportOffset(ward.pos,100.01),expiresAt)
			end
		end
	end
	
	--Get enemies who are teleporting to minions
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i);
		if minion.isEnemy and not _cachedTeleports[minion.networkID] then
			local hasBuff, expiresAt = self:HasBuff(minion, "teleport_target")
			if hasBuff then
				self:RecordTeleport(minion, self:GetTeleportOffset(minion.pos,143.25),expiresAt)
			end
		end
	end	
end

function HPred:GetTeleportingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)

	local target
	local aimPosition
	for _, teleport in pairs(_cachedTeleports) do
		if teleport.expireTime > Game.Timer() and self:GetDistance(source, teleport.aimPos) <= range and teleport.aimPos:To2D().onScreen then			
			local spellInterceptTime = self:GetSpellInterceptTime(source, teleport.aimPos, delay, speed)
			local teleportRemaining = teleport.expireTime - Game.Timer()
			if spellInterceptTime > teleportRemaining and spellInterceptTime - teleportRemaining <= timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, teleport.aimPos, delay, speed, radius)) then								
				target = teleport.target
				aimPosition = teleport.aimPos
				return target, aimPosition
			end
		end
	end		
end

function HPred:GetTargetMS(target)
	local ms = target.pathing.isDashing and target.pathing.dashSpeed or target.ms
	return ms
end

function HPred:Angle(A, B)
	local deltaPos = A - B
	local angle = math.atan2(deltaPos.x, deltaPos.z) *  180 / math.pi	
	if angle < 0 then angle = angle + 360 end
	return angle
end

function HPred:UpdateMovementHistory(unit)
	if not _movementHistory[unit.charName] then
		_movementHistory[unit.charName] = {}
		_movementHistory[unit.charName]["EndPos"] = unit.pathing.endPos
		_movementHistory[unit.charName]["StartPos"] = unit.pathing.endPos
		_movementHistory[unit.charName]["PreviousAngle"] = 0
		_movementHistory[unit.charName]["ChangedAt"] = Game.Timer()
	end
	
	if _movementHistory[unit.charName]["EndPos"].x ~=unit.pathing.endPos.x or _movementHistory[unit.charName]["EndPos"].y ~=unit.pathing.endPos.y or _movementHistory[unit.charName]["EndPos"].z ~=unit.pathing.endPos.z then				
		_movementHistory[unit.charName]["PreviousAngle"] = self:Angle(Vector(_movementHistory[unit.charName]["StartPos"].x, _movementHistory[unit.charName]["StartPos"].y, _movementHistory[unit.charName]["StartPos"].z), Vector(_movementHistory[unit.charName]["EndPos"].x, _movementHistory[unit.charName]["EndPos"].y, _movementHistory[unit.charName]["EndPos"].z))
		_movementHistory[unit.charName]["EndPos"] = unit.pathing.endPos
		_movementHistory[unit.charName]["StartPos"] = unit.pos
		_movementHistory[unit.charName]["ChangedAt"] = Game.Timer()
	end
	
end

--Returns where the unit will be when the delay has passed given current pathing information. This assumes the target makes NO CHANGES during the delay.
function HPred:PredictUnitPosition(unit, delay)
	local predictedPosition = unit.pos
	local timeRemaining = delay
	local pathNodes = self:GetPathNodes(unit)
	for i = 1, #pathNodes -1 do
		local nodeDistance = self:GetDistance(pathNodes[i], pathNodes[i +1])
		local nodeTraversalTime = nodeDistance / self:GetTargetMS(unit)
			
		if timeRemaining > nodeTraversalTime then
			--This node of the path will be completed before the delay has finished. Move on to the next node if one remains
			timeRemaining =  timeRemaining - nodeTraversalTime
			predictedPosition = pathNodes[i + 1]
		else
			local directionVector = (pathNodes[i+1] - pathNodes[i]):Normalized()
			predictedPosition = pathNodes[i] + directionVector *  self:GetTargetMS(unit) * timeRemaining
			break;
		end
	end
	return predictedPosition
end

function HPred:IsChannelling(target, interceptTime)
	if target.activeSpell and target.activeSpell.valid and target.activeSpell.isChanneling then
		return true
	end
end

function HPred:HasBuff(target, buffName, minimumDuration)
	local duration = minimumDuration
	if not minimumDuration then
		duration = 0
	end
	local durationRemaining
	for i = 1, target.buffCount do 
		local buff = target:GetBuff(i)
		if buff.duration > duration and buff.name == buffName then
			durationRemaining = buff.duration
			return true, durationRemaining
		end
	end
end

--Moves an origin towards the enemy team nexus by magnitude
function HPred:GetTeleportOffset(origin, magnitude)
	local teleportOffset = origin + (self:GetEnemyNexusPosition()- origin):Normalized() * magnitude
	return teleportOffset
end

function HPred:GetSpellInterceptTime(startPos, endPos, delay, speed)	
	local interceptTime = Game.Latency()/2000 + delay + self:GetDistance(startPos, endPos) / speed
	return interceptTime
end

--Checks if a target can be targeted by abilities or auto attacks currently.
--CanTarget(target)
	--target : gameObject we are trying to hit
function HPred:CanTarget(target)
	return target.isEnemy and target.alive and target.visible and target.isTargetable
end

--Derp: dont want to fuck with the isEnemy checks elsewhere. This will just let us know if the target can actually be hit by something even if its an ally
function HPred:CanTargetALL(target)
	return target.alive and target.visible and target.isTargetable
end

--Returns a position and radius in which the target could potentially move before the delay ends. ReactionTime defines how quick we expect the target to be able to change their current path
function HPred:UnitMovementBounds(unit, delay, reactionTime)
	local startPosition = self:PredictUnitPosition(unit, delay)
	
	local radius = 0
	local deltaDelay = delay -reactionTime- self:GetImmobileTime(unit)	
	if (deltaDelay >0) then
		radius = self:GetTargetMS(unit) * deltaDelay	
	end
	return startPosition, radius	
end

--Returns how long (in seconds) the target will be unable to move from their current location
function HPred:GetImmobileTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.count > 0 and buff.duration> duration and (buff.type == 5 or buff.type == 8 or buff.type == 21 or buff.type == 22 or buff.type == 24 or buff.type == 11 or buff.type == 29 or buff.type == 30 or buff.type == 39 ) then
			duration = buff.duration
		end
	end
	return duration		
end

--Returns how long (in seconds) the target will be slowed for
function HPred:GetSlowedTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.count > 0 and buff.duration > duration and buff.type == 10 then
			duration = buff.duration			
			return duration
		end
	end
	return duration		
end

--Returns all existing path nodes
function HPred:GetPathNodes(unit)
	local nodes = {}
	table.insert(nodes, unit.pos)
	if unit.pathing.hasMovePath then
		for i = unit.pathing.pathIndex, unit.pathing.pathCount do
			path = unit:GetPath(i)
			table.insert(nodes, path)
		end
	end		
	return nodes
end

--Finds any game object with the correct handle to match (hero, minion, wards on either team)
function HPred:GetObjectByHandle(handle)
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.handle == handle then
			target = enemy
			return target
		end
	end
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion.handle == handle then
			target = minion
			return target
		end
	end
	
	for i = 1, Game.WardCount() do
		local ward = Game.Ward(i);
		if ward.handle == handle then
			target = ward
			return target
		end
	end
	
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		if particle.handle == handle then
			target = particle
			return target
		end
	end
end

function HPred:GetHeroByPosition(position)
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
end

function HPred:GetObjectByPosition(position)
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
	
	for i = 1, Game.MinionCount() do
		local enemy = Game.Minion(i)
		if enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
	
	for i = 1, Game.WardCount() do
		local enemy = Game.Ward(i);
		if enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
	
	for i = 1, Game.ParticleCount() do 
		local enemy = Game.Particle(i)
		if enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
end

function HPred:GetEnemyHeroByHandle(handle)	
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.handle == handle then
			target = enemy
			return target
		end
	end
end

--Finds the closest particle to the origin that is contained in the names array
function HPred:GetNearestParticleByNames(origin, names)
	local target
	local distance = math.max
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		local d = self:GetDistance(origin, particle.pos)
		if d < distance then
			distance = d
			target = particle
		end
	end
	return target, distance
end

--Returns the total distance of our current path so we can calculate how long it will take to complete
function HPred:GetPathLength(nodes)
	local result = 0
	for i = 1, #nodes -1 do
		result = result + self:GetDistance(nodes[i], nodes[i + 1])
	end
	return result
end


--I know this isn't efficient but it works accurately... Leaving it for now.
function HPred:CheckMinionCollision(origin, endPos, delay, speed, radius, frequency)
		
	if not frequency then
		frequency = radius
	end
	local directionVector = (endPos - origin):Normalized()
	local checkCount = self:GetDistance(origin, endPos) / frequency
	for i = 1, checkCount do
		local checkPosition = origin + directionVector * i * frequency
		local checkDelay = delay + self:GetDistance(origin, checkPosition) / speed
		if self:IsMinionIntersection(checkPosition, radius, checkDelay, radius * 3) then
			return true
		end
	end
	return false
end


function HPred:IsMinionIntersection(location, radius, delay, maxDistance)
	if not maxDistance then
		maxDistance = 500
	end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if self:CanTarget(minion) and self:GetDistance(minion.pos, location) < maxDistance then
			local predictedPosition = self:PredictUnitPosition(minion, delay)
			if self:GetDistance(location, predictedPosition) <= radius + minion.boundingRadius then
				return true
			end
		end
	end
	return false
end

function HPred:VectorPointProjectionOnLineSegment(v1, v2, v)
	assert(v1 and v2 and v, "VectorPointProjectionOnLineSegment: wrong argument types (3 <Vector> expected)")
	local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
	local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
	local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
	local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	local isOnSegment = rS == rL
	local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
	return pointSegment, pointLine, isOnSegment
end


function HPred:GetRecallingData(unit)
	for K, Buff in pairs(GetBuffs(unit)) do
		if Buff.name == "recall" and Buff.duration > 0 then
			return true, Game.Timer() - Buff.startTime
		end
	end
	return false
end

function HPred:GetEnemyByName(name)
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.isEnemy and enemy.charName == name then
			target = enemy
			return target
		end
	end
end

function HPred:IsPointInArc(source, origin, target, angle, range)
	local deltaAngle = math.abs(HPred:Angle(origin, target) - HPred:Angle(source, origin))
	if deltaAngle < angle and self:GetDistance(origin, target) < range then
		return true
	end
end

function HPred:GetEnemyHeroes()
	local _EnemyHeroes = {}
  	for i = 1, Game.HeroCount() do
    	local enemy = Game.Hero(i)
    	if enemy and enemy.isEnemy then
	  		table.insert(_EnemyHeroes, enemy)
  		end
  	end
  	return _EnemyHeroes
end

function HPred:GetDistanceSqr(p1, p2)	
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function HPred:GetDistance(p1, p2)
	return math.sqrt(self:GetDistanceSqr(p1, p2))
end