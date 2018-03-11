local _carryHealthPercent = {}
local _healthTick = 1
local Heroes = {"Nami","Brand", "Velkoz", "Heimerdinger", "Zilean", "Soraka"}
local _adcHeroes = { "Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "Jhin", "Jinx", "Kalista", "KogMaw", "Lucian", "MissFortune", "Quinn", "Sivir", "Teemo", "Tristana", "Twitch", "Varus", "Vayne", "Xayah"}
if not table.contains(Heroes, myHero.charName) then print("Hero not supported: " .. myHero.charName) return end

local Scriptname,Version,Author,LVersion = "[Auto]","v1.0","Sikaka","0.01"

Callback.Add("Load",
function() 
	_G[myHero.charName]() 
	AutoUtil()
	TPred()
end)
 		
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

function isValidTarget(obj,range)
	range = range or math.huge
	return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and obj.distance <= range
end


function CountEnemies(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if isValidTarget(hero,range) and hero.team ~= myHero.team then
			N = N + 1
		end
	end
	return N	
end

function CurrentTarget(range)
	if _G.SDK then
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL);
	elseif _G.EOW then
		return _G.EOW:GetTarget(range)
	else
		return _G.GOS:GetTarget(range,"AD")
	end
end
 
function Ready(spellSlot)
	return IsReady(spellSlot)
end

function IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function IsRecalling()
	for K, Buff in pairs(GetBuffs(myHero)) do
		if Buff.name == "recall" and Buff.duration > 0 then
			return true
		end
	end
	return false
end

function UpdateAllyHealth()
	local deltaTick = Game.Timer() - _healthTick	
	if deltaTick >= 1 then	
		 _carryHealthPercent = {}
		_healthTick = Game.Timer()
		for i = 1, Game.HeroCount() do
			local Hero = Game.Hero(i)
			if Hero.isAlly and Hero.alive then	
				_carryHealthPercent[Hero.charName] = CurrentPctLife(Hero)				
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

function AutoUtil:SupportMenu(AIO)			
	---[ITEM SETTINGS]---
	AIO:MenuElement({id = "Items", name = "Item Settings", type = MENU})	
	
	---[LOCKET SETTINGS]---
	AIO.Items:MenuElement({id = "Locket", name = "Locket", type = MENU})
	AIO.Items.Locket:MenuElement({id = "Threshold", tooltip = "How much damage allies received in last second", name = "Ally Damage Threshold", value = 15, min = 1, max = 80, step = 1 })
	AIO.Items.Locket:MenuElement({id="Count", tooltip = "How many allies must have been injured in last second to cast", name = "Ally Count", value = 3, min = 1, max = 5, step = 1 })
	AIO.Items.Locket:MenuElement({id="Enabled", name="Enabled", value = true})
	
	---[CRUCIBLE SETTINGS]---
	AIO.Items:MenuElement({id = "Crucible", name = "Crucible", type = MENU})
	AIO.Items.Crucible:MenuElement({id = "Targets", name = "Targets", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly and myHero ~= hero then			
			if table.contains(_adcHeroes, hero.charName) then
				AIO.Items.Crucible.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
			else
				AIO.Items.Crucible.Targets:MenuElement({id = hero.charName, name = hero.charName, value = false })
			end
		end
	end	
	AIO.Items.Crucible:MenuElement({id = "CC", name = "CC Settings", type = MENU})
	AIO.Items.Crucible.CC:MenuElement({id = "CleanseTime", name = "Cleanse CC If Duration Over (Seconds)", value = .5, min = .1, max = 2, step = .1 })
	AIO.Items.Crucible.CC:MenuElement({id = "Suppression", name = "Suppression", value = true, toggle = true})
	AIO.Items.Crucible.CC:MenuElement({id = "Stun", name = "Stun", value = true, toggle = true})
	AIO.Items.Crucible.CC:MenuElement({id = "Sleep", name = "Sleep", value = true, toggle = true})
	AIO.Items.Crucible.CC:MenuElement({id = "Polymorph", name = "Polymorph", value = true, toggle = true})
	AIO.Items.Crucible.CC:MenuElement({id = "Taunt", name = "Taunt", value = true, toggle = true})
	AIO.Items.Crucible.CC:MenuElement({id = "Charm", name = "Charm", value = true, toggle = true})
	AIO.Items.Crucible.CC:MenuElement({id = "Fear", name = "Fear", value = true, toggle = true})
	AIO.Items.Crucible.CC:MenuElement({id = "Blind", name = "Blind", value = false, toggle = true})	
	AIO.Items.Crucible.CC:MenuElement({id = "Snare", name = "Snare", value = false, toggle = true})
	AIO.Items.Crucible.CC:MenuElement({id = "Slow", name = "Slow", value = false, toggle = true})
	AIO.Items.Crucible.CC:MenuElement({id = "Poison", name = "Poison", value = false, toggle = true})
	
	---[REDEMPTION SETTINGS]---
	AIO.Items:MenuElement({id = "Redemption", name = "Redemption", type = MENU})
	AIO.Items.Redemption:MenuElement({id = "XXX", name = "---NOT YET DONE---", type = MENU})
end

function AutoUtil:GetDistanceSqr(p1, p2)
	assert(p1, "GetDistance: invalid argument: cannot calculate distance to "..type(p1))
	assert(p2, "GetDistance: invalid argument: cannot calculate distance to "..type(p2))
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function AutoUtil:GetDistance(p1, p2)
	return math.sqrt(self:GetDistanceSqr(p1, p2))
end

function AutoUtil:GetChannelingEnemyInRange(origin, range, minimumChannelTime)
	local bestTarget
	local bestCCTime = minimumChannelTime
	for heroIndex = 1,Game.HeroCount()  do
		local enemy = Game.Hero(heroIndex)
		if enemy.isEnemy and isValidTarget(enemy, range) and self:GetDistance(origin, enemy.pos) <= range and enemy.activeSpell and enemy.activeSpell.valid and enemy.activeSpell.isChanneling then
			local channelRemaining = enemy.activeSpell.castEntTime - Game.Timer()
			if channelTimeRemaining > bestCCTime then
				bestTarget = enemy
				bestCCTime = buff.duration
			end
		end
	end	
	return bestTarget, bestCCTime
end

function AutoUtil:GetCCdEnemyInRange(origin, range, minimumCCTime, maximumCCTime)
	--TODO: Give priority to certain targets in case of tie. Right now I prioritize based on maximum CC effect (not over stunning)	
	local bestTarget
	local bestCCTime = 0
	for heroIndex = 1,Game.HeroCount()  do
		local enemy = Game.Hero(heroIndex)
		if enemy.isEnemy and isValidTarget(enemy, range) and self:GetDistance(origin, enemy.pos) <= range then
			for buffIndex = 0, enemy.buffCount do
				local buff = enemy:GetBuff(buffIndex)
				
				if (buff.type == 5 or buff.type == 8 or buff.type == 21 or buff.type == 22 or buff.type == 24 or buff.type == 11) then					
					if(buff.duration > minimumCCTime and buff.duration > bestCCTime and buff.duration < maximumCCTime) then
						bestTarget = enemy
						bestCCTime = buff.duration
					end
				end
			end
		end
	end	
	return bestTarget, bestCCTime
end


function AutoUtil:NearestEnemy(entity)
	local distance = 999999
	local enemy = nil
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if isValidTarget(hero,range) and hero.team ~= myHero.team then
			local d = self:GetDistance(entity.pos, hero.pos)
			if d < distance then
				distance = d
				enemy = hero
			end
		end
	end
	return distance, enemy
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
				Control.CastSpell(key, myHero)
			end
		end
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


function AutoUtil:AutoCrucible()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and Hero.alive and Hero ~= myHero then
			if AIO.Items.Crucible.Targets[Hero.charName] and AIO.Items.Crucible.Targets[Hero.charName]:Value() then
				for ccName, ccType in pairs(_ccNames) do
					if AIO.Items.Crucible.CC[ccName] and AIO.Items.Crucible.CC[ccName]:Value() and self:HasBuffType(Hero, ccType, AIO.Items.Crucible.CC.CleanseTime:Value()) then
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
		local Hero = Game.Hero(i)
		if _carryHealthPercent and _carryHealthPercent[Hero.charName] and Hero.isAlly and Hero.alive and self:GetDistance(myHero.pos, Hero.pos) <= 700 then
			local deltaLifeLost = _carryHealthPercent[Hero.charName] - CurrentPctLife(Hero)			
			if deltaLifeLost >= AIO.Items.Locket.Threshold:Value() then
				injuredCount = injuredCount + 1
			end
		end
	end	
	if injuredCount >= AIO.Items.Locket.Count:Value() then	
		AutoUtil:CastItem(myHero, 3190, math.huge)
	end
end

class "Brand"
local WCastPos, WCastTime


--Gets the time until our W will deal damage
function Brand:GetWHitTime()
	local deltaHitTime = 99999999
	if( WCastTime) then
		deltaHitTime = WCastTime + W.Delay - Game.Timer()
	end
	return deltaHitTime
end

function Brand:__init()	
	print("Loaded [Auto] ".. myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end
function Brand:LoadSpells()
	Q = {Range = 1050, Width = 80, Delay = 0.25, Speed = 1550, Collision = true, aoe = false, Sort = 'line'}
	W = {Range = 900, Width = 250, Delay = 0.625, Speed = math.huge, Collision = false, aoe = true, Sort = "circular"}
	E = {Range = 600, Delay = 0.25, Speed = math.huge, Collision = false }
	R = {Range = 750, Width = 0, Delay = 0.25, Speed = 1700, Collision = false, aoe = false, Sort = "circular"}
end

function Brand:CreateMenu()	
	AIO = MenuElement({type = MENU, id = myHero.charName, name = "[Auto] "..myHero.charName})	
	
	AIO:MenuElement({id = "TargetList", name = "Auto W List", type = MENU})	
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			if table.contains(_adcHeroes, Hero.charName) then
				AIO.TargetList:MenuElement({id = Hero.charName, name = Hero.charName, value = true, toggle = true})
			else
				AIO.TargetList:MenuElement({id = Hero.charName, name = Hero.charName, value = false, toggle = false})				
			end
		end
	end
	
	AIO:MenuElement({id = "Skills", name = "Skills", type = MENU})
	AIO.Skills:MenuElement({id = "QAcc", name = "Auto Q Accuracy", value = 3, min = 1, max = 5, step = 1 })
	
	AIO.Skills:MenuElement({id = "EMan", name = "Auto E Mana", value = 25, min = 1, max = 100, step = 5 })
	
	AIO.Skills:MenuElement({id = "WAcc", name = "Auto W Accuracy", value = 3, min = 1, max = 5, step = 1 })
	AIO.Skills:MenuElement({id = "WMan", name = "Auto W Mana", value = 25, min = 1, max = 100, step = 5})
	
	
	AIO.Skills:MenuElement({id = "RCount", name = "Auto R Enemy Count", value = 3, min = 1, max = 5, step = 1})
		
	AIO:MenuElement({id = "comboActive", name = "Combo key",value = true, toggle = true,  key = 0x7A})
	AIO:MenuElement({id = "reactionTime", name = "Target reaction time", value = .5, min = .1, max = 1, step = .05})
end

function Brand:Draw()
	if AIO.comboActive:Value() then
		local textPos = myHero.pos:To2D()
		Draw.Text("ON", 20, textPos.x - 25, textPos.y + 40, Draw.Color(220, 0, 255, 0))
	end
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)    
		if Hero.isEnemy and Hero.pathing.hasMovePath and Hero.pathing.isDashing and Hero.pathing.dashSpeed>500 then
			Draw.Circle(Hero:GetPath(1), 40, 20, Draw.Color(255, 255, 255, 255))
		end
	end
end

function Brand:Tick()	
	if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true  or not AIO.comboActive:Value() then return end

	Brand:AutoImobileCombo()
		
	--TODO: Clean up rest of the skills to follow new format of other champs
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.Collision, W.Sort, AIO.reactionTime:Value())
	if Ready(_W) and HitChance >= AIO.Skills.WAcc:Value() and AIO.TargetList[target.charName] and AIO.TargetList[target.charName]:Value() and myHero.mana/myHero.maxMana >= AIO.Skills.WMan:Value() / 100 then
		Control.CastSpell(HK_W, castpos)
	end	
	
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if Ready(_E) and myHero.mana/myHero.maxMana >= AIO.Skills.EMan:Value() / 100 then
		Control.CastSpell(HK_E, target.pos)
	end
	
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
  
	local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.Collision, Q.Sort, AIO.reactionTime:Value())
	if Ready(_Q) and HitChance >= AIO.Skills.QAcc:Value() then
		--Check if target has burn status
		if TPred:HasBuff(target, "BrandAblaze") then				
			Control.CastSpell(HK_Q, castpos)
		end
	end
		
	--Check enemy count near our target. If the target is ablaze and enough enemies, cast ult! 
		--TODO: Check stack counts so that we use ult on 'central' target or one with 2 stacks already to force detonation
	if TPred:HasBuff(target, "BrandAblaze") and Ready(_R) and CountEnemies(target.pos, 350) >=AIO.Skills.RCount:Value() then
		Control.CastSpell(HK_R, target)
	end
end

--Will attempt to W or WQ any champions who are immobile (hourglass, using gapcloser)
function Brand:AutoImobileCombo()

	--Get Dashing Targets
	local target = TPred:GetInteruptTarget(myHero.pos, W.Range, W.Delay, W.Speed, AIO.reactionTime:Value())
	if target ~= nil then
		if Ready(_W) then
			Control.CastSpell(HK_W, target:GetPath(1))
			WCastPos = target:GetPath(1)
			WCastTime = Game.Timer()
		end
		
		local wHitTime = self:GetWHitTime()
		if Ready(_Q) and AutoUtil:GetDistance(myHero.pos, target.pos) <= Q.Range and wHitTime > 0 and TPred:GetSpellInterceptTime(myHero.pos, target:GetPath(1), Q.Delay, Q.Speed) > wHitTime and not TPred:CheckMinionCollision(target, target.pos, Q.Delay, Q.Width, Q.Range, Q.Speed, myHero.pos) then
			Control.CastSpell(HK_Q, target:GetPath(1))
		end		
	end
	
	--Get Statsis Target
	local target = TPred:GetStasisTarget(myHero.pos, W.Range, W.Delay, W.Speed, AIO.reactionTime:Value())
	if target ~= nil  and target.isEnemy then
		if Ready(_W) then
			Control.CastSpell(HK_W, target.pos)
			WCastPos = target.pos
			WCastTime = Game.Timer()
		end
		
		local wHitTime = self:GetWHitTime()
		if Ready(_Q) and AutoUtil:GetDistance(myHero.pos, target.pos) <= Q.Range and  wHitTime > 0 and TPred:GetSpellInterceptTime(myHero.pos, target.pos, Q.Delay, Q.Speed) > wHitTime and not TPred:CheckMinionCollision(target, target.pos, Q.Delay, Q.Width, Q.Range, Q.Speed, myHero.pos) then
			Control.CastSpell(HK_Q, target.pos)
		end	
	end
end


class "Velkoz"

local qMissile
local qHitPoints
local qPointsUpdatedAt = Game.Timer()

function Velkoz:__init()	
	print("Loaded [Auto] "..myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Velkoz:LoadSpells()

	Q = {Range = 1050, Width = 55,Delay = 0.251, Speed = 1235,  Sort = "line"}
	W = {Range = 1050, Width = 80,Delay = 0.25, Speed = 1500,  Sort = "line"}
	E = {Range = 850, Width = 235,Delay = 0.75, Speed = math.huge,  Sort = "circular"}
	R = {Range = 1550,Width = 75, Delay = 0.25, Speed = math.huge, Sort = "line" }
end

function Velkoz:CreateMenu()
	AIO = MenuElement({type = MENU, id = myHero.charName, name = "[Auto] " .. myHero.charName})
	
	AIO:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	
	--%Mana needed for us to launch a Q vs immobile targets
	AIO.Skills:MenuElement({id = "QMana", name = "Auto Q Mana", value = 25, min = 5, max = 100, step = 1 })
	
	--%Mana needed for us to use W to detonate passive or steal a kill
	AIO.Skills:MenuElement({id = "WDetonateMana", name = "W Detonate Mana", value = 50, min = 5, max = 100, step = 5 })
	AIO.Skills:MenuElement({id = "WInterruptMana", name = "W Interrupt Mana", value = 50, min = 5, max = 100, step = 5 })
	
	AIO.Skills:MenuElement({id = "ETiming", name = "E Interrupt Delay", value = .25, min = .1, max = 1, step = .05 })
	AIO.Skills:MenuElement({id = "ECCTiming", name = "E Imobile Targets", value = .5, min = .1, max = 2, step = .1 })	
	
	--Minimum E mana to use on stunned targets
	AIO.Skills:MenuElement({id = "EMana", name = "Auto E Mana", value = 25, min = 5, max = 100, step = 1 })	
	
	AIO:MenuElement({id = "autoSkillsActive", name = "Auto Skills Enabled",value = true, toggle = true, key = 0x7A })
end

function Velkoz:Draw()
	if AIO.autoSkillsActive:Value() then
		local textPos = myHero.pos:To2D()
		Draw.Text("ON", 20, textPos.x - 25, textPos.y + 40, Draw.Color(220, 0, 255, 0))
	end
	
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)    
		if Hero.isEnemy and Hero.pathing.hasMovePath and Hero.pathing.isDashing and Hero.pathing.dashSpeed>500 then
			Draw.Circle(Hero:GetPath(1), 40, 20, Draw.Color(255, 255, 255, 255))
		end
	end	
end


function Velkoz:IsUltActive()
	if myHero.activeSpell and myHero.activeSpell.valid and myHero.activeSpell.name == "VelkozR" then
		return true
	else
		return false
	end
end
function Velkoz:Tick()
	if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or not AIO.autoSkillsActive:Value() or self:IsUltActive() then return end
	
	if Ready(_E) then 
		self:AutoEInterrupt()
	end
	
	if Ready(_W) and CurrentPctMana(myHero) >= AIO.Skills.WDetonateMana:Value() then
		self:AutoWDetonate()
	end
	
	if Ready(_W) and CurrentPctMana(myHero) >= AIO.Skills.QMana:Value() then
		self:AutoQInterrupt()
	end
	
	if Ready(_Q) and CurrentPctMana(myHero) >= AIO.Skills.QMana:Value() then
		self:AutoQInterrupt()		
		self:AutoQDetonate()
	end
	
end


function Velkoz:AutoQDetonate()	
	self:UpdateQInfo()
	--Check if any of our qHitPoints hit an enemy. If so re-activate it
	if Game.Timer() - qPointsUpdatedAt < .25 and self:IsQActive() and qHitPoints then
		for i = 1, #qHitPoints do		
			if qHitPoints[i] then
				if qHitPoints[i].playerHit then					
					Control.CastSpell(HK_Q)
				end
			end
		end
	end
end


function Velkoz:IsQActive()
	return qMissile and qMissile.name and qMissile.name == "VelkozQMissile"
end
function Velkoz:UpdateQInfo()
	if self:IsQActive() then
		local directionVector = Vector(qMissile.missileData.endPos.x - qMissile.missileData.startPos.x,qMissile.missileData.endPos.y - qMissile.missileData.startPos.y,qMissile.missileData.endPos.z - qMissile.missileData.startPos.z):Normalized()
		
		local upVector = directionVector:Perpendicular()
		local downVector = directionVector:Perpendicular2()		
		
		--TODO: Change 50 to a variable setting such as "checkInterval"
		local pointCount = 600 / 50 * 2
		qHitPoints = {}
		
		for i = 1, pointCount, 2 do
			local result =  self:CalculateNode(qMissile, qMissile.pos + upVector * i * 50)			
			qHitPoints[i] = result
			if result.collision then
				break
			end
		end
		
		for i = 2, pointCount, 2 do		
			local result =  self:CalculateNode(qMissile, qMissile.pos + downVector * i * 50)			
			qHitPoints[i] = result	
			if result.collision then
				break
			end
		end
		
		qPointsUpdatedAt = Game.Timer()
		
	end
	
	--Record our Q data	
	local qData = myHero:GetSpellData(_Q)
	if Game.Timer() - qData.castTime < .1 then
		for i = 1, Game.MissileCount() do
			local missile = Game.Missile(i)
			if missile.name == "VelkozQMissile" and AutoUtil:GetDistance(missile.pos, myHero.pos) < 400 then
				qMissile = missile
			end
		end
	end
end


function Velkoz:CalculateNode(missile, nodePos)
	local result = {}
	result["pos"] = nodePos
	result["delay"] = 0.251 + self:GetDistance(missile.pos, nodePos) / Q.Speed
	
	local isCollision = self:CheckMinionCollision(nodePos, 50, result["delay"])
	local hitEnemy 
	if not isCollision then
		isCollision, hitEnemy = self:CheckEnemyCollision(nodePos, 50, result["delay"])
	end
	
	result["playerHit"] = hitEnemy	
	result["collision"] = isCollision
	return result
end

function Velkoz:CheckMinionCollision(location, radius, delay, maxDistance)
	if not maxDistance then
		maxDistance = 1000
	end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion.isEnemy and minion.isTargetable and minion.alive and self:GetDistance(minion.pos, location) < maxDistance then
			local predictedPosition = self:PredictUnitPosition(minion, delay)
			if self:GetDistance(location, predictedPosition) <= radius + minion.boundingRadius then
				return true
			end
		end
	end
	
	return false
end

function Velkoz:CheckEnemyCollision(location, radius, delay, maxDistance)
	if not maxDistance then
		maxDistance = 1000
	end
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy and hero.isTargetable and hero.alive and self:GetDistance(hero.pos, location) < maxDistance then
			local predictedPosition = self:PredictUnitPosition(hero, delay)
			if self:GetDistance(location, predictedPosition) <= radius + hero.boundingRadius then
				return true, hero
			end
		end
	end
	
	return false
end

function Velkoz:GetDistanceSqr(p1, p2)
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function Velkoz:GetDistance(p1, p2)
	return math.sqrt(self:GetDistanceSqr(p1, p2))
end


--Returns where the unit will be when the delay has passed given current pathing information. This assumes the target makes NO CHANGES during the delay.
function Velkoz:PredictUnitPosition(unit, delay)	
	local predictedPosition = unit.pos
	local timeRemaining = delay
	local pathNodes = self:GetPathNodes(unit)
	for i = 1, #pathNodes -1 do
		local nodeDistance = self:GetDistance(pathNodes[i], pathNodes[i +1])
		local nodeTraversalTime = nodeDistance / unit.ms
		if timeRemaining > nodeTraversalTime then
			--This node of the path will be completed before the delay has finished. Move on to the next node if one remains
			timeRemaining =  timeRemaining - nodeTraversalTime
			predictedPosition = pathNodes[i + 1]
		else
			--The delay will be completed before the node of the path. Find the partial position.
			predictedPosition = pathNodes[i] + (pathNodes[i+1] - pathNodes[i]) * 1 / nodeTraversalTime / timeRemaining			
			--Break the loop
			i = #pathNodes
		end
	end	
	return predictedPosition
end

--Returns a position and radius in which the target could potentially move before the delay ends. ReactionTime defines how quick we expect the target to be able to change their current path
function Velkoz:UnitMovementBounds(unit, delay, reactionTime)
	local startPosition = self:PredictUnitPosition(unit, reactionTime)
	
	local radius = 0
	local deltaDelay = delay - self:GetImmobileTime(unit)	
	if (deltaDelay >0) then
		radius = target.ms * deltaDelay	
	end
	return startPosition, radius	
end

--Returns how long (in seconds) the target will be unable to move from their current location
function Velkoz:GetImmobileTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.count > 0 and buff.duration> duration and (buff.type == 5 or buff.type == 8 or buff.type == 21 or buff.type == 22 or buff.type == 24 or buff.type == 11) then
			duration = buff.duration
		end
	end
	return duration		
end

--Returns how long (in seconds) the target will be slowed for
function Velkoz:GetSlowedTime(unit)
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
function Velkoz:GetPathNodes(unit)
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

--Returns the total distance of our current path so we can calculate how long it will take to complete
function Velkoz:GetPathLength(nodes)
	local result = 0
	for i = 1, #nodes -1 do
		result = result + self:GetDistance(nodes[i], nodes[i + 1])
	end
	return result
end


function Velkoz:AutoEInterrupt()
	--Use E to target the end of a gapcloser
	local target = TPred:GetInteruptTarget(myHero.pos, E.Range, E.Delay, E.Speed, AIO.Skills.ETiming:Value())
	if target ~= nil then
		Control.CastSpell(HK_E, target:GetPath(1))
		if Ready(_W) and CurrentPctMana(myHero) >= AIO.Skills.WInterruptMana:Value() then
			Control.CastSpell(HK_W, target:GetPath(1))
		end
	end
	
	--Use E to target the end of a hourglass stasis
	local target = TPred:GetStasisTarget(myHero.pos, E.Range, E.Delay, E.Speed, AIO.Skills.ETiming:Value())
	if target ~= nil  and target.isEnemy then
		Control.CastSpell(HK_E, target.pos)	
		if Ready(_W) and CurrentPctMana(myHero) >= AIO.Skills.WInterruptMana:Value() then
			Control.CastSpell(HK_W, target.pos)
		end
	end		
	
	--Use E on Stunned Targets
	local target, ccRemaining = AutoUtil:GetCCdEnemyInRange(myHero.pos, E.Range, AIO.Skills.ECCTiming:Value(), 1 + E.Delay)
	if target and CurrentPctMana(myHero) >= AIO.Skills.EMana:Value() then
		Control.CastSpell(HK_E, target.pos)	
		if Ready(_W) and CurrentPctMana(myHero) >= AIO.Skills.WInterruptMana:Value() then
			Control.CastSpell(HK_W, target.pos)
		end
	end
end


--Find an enemy with 2 stacks of passive on them and use W to pop it.
function Velkoz:AutoWDetonate()
	local Enemy = AutoUtil:FindEnemyWithBuff("velkozresearchstack", W.Range, 2)
	if Enemy ~= nil then	
		local castpos,HitChance, pos = TPred:GetBestCastPosition(Enemy, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.Collision, W.Sort)
		if HitChance >= 2 then
			Control.CastSpell(HK_W, castpos)
		end
	end
end

--Find an enemy that we can launch Q directly at. This means immobile, dashing or stasis targets who will not be blocked by minions.
function Velkoz:AutoQInterrupt()
	
	--Use Q to target the end of a gapcloser
	local target = TPred:GetInteruptTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, AIO.Skills.ETiming:Value())
	if target ~= nil then
		Control.CastSpell(HK_Q, target:GetPath(1))
	end
	
	--Use Q to target the end of a hourglass stasis
	local target = TPred:GetStasisTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, AIO.Skills.ETiming:Value())
	if target ~= nil  and target.isEnemy then
		Control.CastSpell(HK_Q, target.pos)	
	end	
	
	--Use Q on Stunned Targets
	local target, ccRemaining = AutoUtil:GetCCdEnemyInRange(myHero.pos, Q.Range, AIO.Skills.ECCTiming:Value(), 1 + Q.Delay)
	if target and not TPred:CheckMinionCollision(target, target.pos, Q.Delay, Q.Width, Q.Range, Q.Speed, myHero.pos) then 
		Control.CastSpell(HK_Q, target.pos)	
	end
end

class "Nami"
local _isLoaded = false

function Nami:__init()	
	AutoUtil()
	Callback.Add("Tick", function() self:Tick() end)
end

--Keep trying to load the game until heroes are finished populating. This means we wont have to re-load the script once in game for it to pull the hero list.
function Nami:TryLoad()
	if Game.Timer() < 10 then
		return false
	end
	
	print("Loaded [Auto] "..myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Draw", function() self:Draw() end)
	UpdateAllyHealth()	
	return true
end
function Nami:LoadSpells()

	Q = {Range = 875, Width = 200,Delay = 0.95, Speed = math.huge,  Sort = "circular"}
	W = {Range = 725}
	E = { Range = 800}
	R = {Range = 2750,Width = 215, Speed = 850, Delay = 0.5, Sort = "line" }
end

function Nami:CreateMenu()
	AIO = MenuElement({type = MENU, id = myHero.charName, name = "[Auto] " .. myHero.charName})	
	
	AutoUtil:SupportMenu(AIO)
	
	AIO:MenuElement({id = "Skills", name = "Skills", type = MENU})
	AIO.Skills:MenuElement({id = "QTiming", name = "Q Interrupt Delay", value = .25, min = .1, max = 1, step = .05 })
	AIO.Skills:MenuElement({id = "QCCTiming", name = "Q Imobile Targets", value = .5, min = .1, max = 2, step = .1 })
	
	AIO.Skills:MenuElement({id = "WBouncePct", name = "W Health (Bounce)", value = 50, min = 1, max = 100, step = 5 })
	AIO.Skills:MenuElement({id = "WBounceMana", name = "W Mana (Bounce)", value = 50, min = 5, max = 100, step = 5 })
	
	AIO.Skills:MenuElement({id = "WEmergencyPct", name = "W Health (Emergency)", value = 10, min = 1, max = 100, step = 1 })
	AIO.Skills:MenuElement({id = "WEmergencyMana", name = "W Mana (Emergency)", value = 20, min = 5, max = 100, step = 1 })
	
	AIO.Skills:MenuElement({id = "EMana", name = "E Mana", value = 25, min = 5, max = 100, step = 1 })
	
	AIO:MenuElement({id = "autoSkillsActive", name = "Auto Skills Enabled",value = true, toggle = true, key = 0x7A })
end

function Nami:Draw()
	if AIO.autoSkillsActive:Value() then
		local textPos = myHero.pos:To2D()
		Draw.Text("ON", 20, textPos.x - 25, textPos.y + 40, Draw.Color(220, 0, 255, 0))
	end
	
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)    
		if Hero.isEnemy and Hero.pathing.hasMovePath and Hero.pathing.isDashing and Hero.pathing.dashSpeed>500 then
			Draw.Circle(Hero:GetPath(1), 40, 20, Draw.Color(255, 255, 255, 255))
		end
	end
end

function Nami:Tick()

	if(not _isLoaded) then
		_isLoaded = Nami:TryLoad()
	end
	if not _isLoaded or myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or not AIO.autoSkillsActive:Value() then return end	
		
	--Try to interrupt dashes or hourglass with Q if we can
	if Ready(_Q) then 
		self:AutoQInterrupt()
	end
		
	--Use W on myself or ally if it will also bounce to an enemy. 
	if Ready(_W) and CurrentPctMana(myHero) >= AIO.Skills.WBounceMana:Value() then
		self:AutoWBounce()
	end
	
	--Use W on myself or ally if they are very close to death
	if Ready(_W) and CurrentPctMana(myHero) >= AIO.Skills.WEmergencyMana:Value() then	
			self:AutoWEmergency()
	end
		
	--Use E on our carry if they are attacking the enemy
	if Ready(_E) and CurrentPctMana(myHero) >= AIO.Skills.EMana:Value() then
		self:AutoE()
	end
	
	--Use crucible on carry if they are CCd
	if AutoUtil:IsItemReady(3222) then
		AutoUtil:AutoCrucible()
	end
	
	--Use Locket
	if AutoUtil:IsItemReady(3190) then
		AutoUtil:AutoLocket()
	end
end



function Nami:AutoQInterrupt()
	--Use Q to target the end of a gapcloser
	local target = TPred:GetInteruptTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, AIO.Skills.QTiming:Value())
	if target ~= nil and target.isEnemy then
		Control.CastSpell(HK_Q, target:GetPath(1))
	end
	
	--Use Q to target the end of a hourglass stasis
	local target = TPred:GetStasisTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, AIO.Skills.QTiming:Value())
	if target ~= nil and target.isEnemy then
		Control.CastSpell(HK_Q, target.pos)	
	end	
	
	--Find a target that is already stunned for at least QCCTiming:Value(). 
	--Don't stun them if the existing stun on them will last 1 second + the time for our Q to hit because that would waste the majority of our Qs stun duration
	local target, ccRemaining = AutoUtil:GetCCdEnemyInRange(myHero.pos, Q.Range, AIO.Skills.QCCTiming:Value(), 1 + Q.Delay)
	if target then
		Control.CastSpell(HK_Q, target.pos)	
	end
end

function Nami:AutoWEmergency()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and Hero.alive and AutoUtil:GetDistance(myHero.pos, Hero.pos) <= W.Range and CurrentPctLife(Hero) <= AIO.Skills.WEmergencyPct:Value() then
			Control.CastSpell(HK_W, Hero.pos)			
		end
	end
end

function Nami:AutoWBounce()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and Hero.alive and AutoUtil:GetDistance(myHero.pos, Hero.pos) <= W.Range and CurrentPctLife(Hero) <= AIO.Skills.WBouncePct:Value() then
			if AutoUtil:NearestEnemy(Hero) < 500 then
				Control.CastSpell(HK_W, Hero.pos)
			end
		end
	end
end

function Nami:AutoE()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if  Hero.isAlly and Hero.alive and Hero ~= myHero and AutoUtil:GetDistance(myHero.pos, Hero.pos) <= E.Range and table.contains(_adcHeroes, Hero.charName) then
			local targetHandle = nil			
			if Hero.activeSpell and Hero.activeSpell.valid and Hero.activeSpell.target and Hero.activeSpell.isAutoAttack then
				targetHandle = Hero.activeSpell.target
			end
			
			if targetHandle then 
				local Enemy = GetHeroByHandle(targetHandle)
				if Enemy and Enemy.isEnemy then
					Control.CastSpell(HK_E, Hero.pos)
				end
			end
		end
	end
end

class "Heimerdinger"

function Heimerdinger:__init()	
	AutoUtil()
	Callback.Add("Tick", function() self:Tick() end)
	print("Loaded [Auto] "..myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Draw", function() self:Draw() end)	
end

function Heimerdinger:LoadSpells()
	Q = {Range = 450, Width = 55,Delay = 0.25, Speed = math.huge,  Sort = "circular"}
	W = {Range = 1325, Width = 55, Delay = 0.25, Speed = 2050, Sort = "line", Collision = true}
	E = { Range = 970, Width = 250, Delay = 0.25, Speed = 1200, Sort = "circular"}
end

function Heimerdinger:CreateMenu()
	AIO = MenuElement({type = MENU, id = myHero.charName, name = "[Auto] " .. myHero.charName})	
	
	AIO:MenuElement({id = "Skills", name = "Skills", type = MENU})
	AIO.Skills:MenuElement({id = "ETiming", name = "E Interrupt Delay", value = .5, min = .1, max = 1, step = .05 })
	AIO.Skills:MenuElement({id = "ECCTiming", name = "E Imobile Targets", value = .5, min = .1, max = 2, step = .05 })
	AIO.Skills:MenuElement({id = "EDistance", name = "Auto E Distance", value = 100, min = 50, max = 300, step = 10 })
	AIO.Skills:MenuElement({id = "EMana", name = "Auto E Mana Limit", value = 50, min = 1, max = 100, step = 5 })
	AIO.Skills:MenuElement({id = "WMana", name = "Auto W Mana Limit", value = 50, min = 1, max = 100, step = 5 })
	AIO.Skills:MenuElement({id = "RWMinHP", name = "RW Minimum Life", value = 200, min = 100, max = 3000, step = 100 })	
	AIO.Skills:MenuElement({id = "RWMaxHP", name = "RW Maximum Life", value = 1000, min = 100, max = 3000, step = 100 })	
	
	AIO:MenuElement({id = "autoSkillsActive", name = "Auto Skills Enabled",value = true, toggle = true, key = 0x7A })
end

function Heimerdinger:Draw()
	if AIO.autoSkillsActive:Value() then
		local textPos = myHero.pos:To2D()
		Draw.Text("ON", 20, textPos.x - 25, textPos.y + 40, Draw.Color(220, 0, 255, 0))
	end
	
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)    
		if Hero.isEnemy and Hero.pathing.hasMovePath and Hero.pathing.isDashing and Hero.pathing.dashSpeed>500 then
			Draw.Circle(Hero:GetPath(1), 40, 20, Draw.Color(255, 255, 255, 255))
		end
	end
end

function Heimerdinger:Tick()
	if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or not AIO.autoSkillsActive:Value() then return end	
	
	
	--Used to E enemies who are unlikely to be able to dodge. May or may not cast W on them after.
	if Ready(_E) and CurrentPctMana(myHero) >= AIO.Skills.EMana:Value() then
		self:EInterrupt()
	end
	
	--Used to W enemies even if we cant E them.
	if Ready(_W) and CurrentPctMana(myHero) >= AIO.Skills.WMana:Value() then
		self:WImmobile()
	end
end

--This is a secondary anti gap closer... I honestly think this will cause issues but lets try for now. The goal is to get targets dashing ONTOP of us to peel
function Heimerdinger:GetDashingTarget(range, delay, speed)
	local target
	local endDistance = range
	local interceptTime = 9999
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if t.isEnemy and t.pathing.hasMovePath and t.pathing.isDashing and t.pathing.dashSpeed>500 then
			local dashEndPosition = t:GetPath(1)
			if AutoUtil:GetDistance(myHero.pos, dashEndPosition) < endDistance then
				target = t
				endDistance = AutoUtil:GetDistance(myHero.pos, dashEndPosition)
				interceptTime = TPred:GetSpellInterceptTime(myHero.pos, dashEndPosition, delay, speed)
			end	
		end
	end
	
	if target then
		return target, endDistance, interceptTime
	end
end

function Heimerdinger:EInterrupt()
	--Use E to target the end of a gapcloser
	local target = TPred:GetInteruptTarget(myHero.pos, E.Range, E.Delay, E.Speed, AIO.Skills.ETiming:Value())
	if target ~= nil then
		Control.CastSpell(HK_E, target:GetPath(1))	
	end
	
	--Use E to target the end of a hourglass stasis
	local target = TPred:GetStasisTarget(myHero.pos, E.Range, E.Delay, E.Speed, AIO.Skills.ETiming:Value())
	if target ~= nil and target.isEnemy then
		Control.CastSpell(HK_E, target.pos)	
	end
	
	--Use E on stunned enemies
	local target, ccRemaining = AutoUtil:GetCCdEnemyInRange(myHero.pos, E.Range, AIO.Skills.ECCTiming:Value(), 1 + E.Delay)
	if target then
		Control.CastSpell(HK_E, target.pos)
	end
	
	--Use E on gapclosing enemies who are jumping VERY close to us. Note: This is not finished at all and will be buggy
	local target, endDistance, interceptTime = self:GetDashingTarget(E.Range, E.Delay, E.Speed)
	if target ~= nil and endDistance <= AIO.Skills.EDistance:Value() and target.pathing and target.pathing.endPos then
		Control.CastSpell(HK_E, target.pathing.endPos)
	end
end

function Heimerdinger:WImmobile()
	--Use W to target the end of a gapcloser
	local target = TPred:GetInteruptTarget(myHero.pos, W.Range, W.Delay, W.Speed, AIO.Skills.ETiming:Value())
	if target ~= nil then
		self:CastW(target,target:GetPath(1))
	end
	
	--Use W to target the end of a hourglass stasis
	local target = TPred:GetStasisTarget(myHero.pos, W.Range, W.Delay, W.Speed, AIO.Skills.ETiming:Value())
	if target ~= nil  and target.isEnemy then
		self:CastW(target,target.pos)
	end	
		
	--Use W on stunned enemies
	local target, ccRemaining = AutoUtil:GetCCdEnemyInRange(myHero.pos, W.Range, AIO.Skills.ECCTiming:Value(), 1 + W.Delay)
	if target ~= nil then
		self:CastW(target, target.pos)
	end	
end

function Heimerdinger:CastW(target, pos)
	if target ~= nil and Ready(_W) then
		--Check target health and R cooldown
		if Ready(_R) and target.health >= AIO.Skills.RWMinHP:Value() and target.health <= AIO.Skills.RWMaxHP:Value() then
			Control.CastSpell(HK_R)			
			DelayAction(function()Control.CastSpell(HK_W, pos) end,0.1)
		else
			Control.CastSpell(HK_W, pos)
		end
	end
end



class "Zilean"
local _isLoaded = false
function Zilean:__init()	
	AutoUtil()
	Callback.Add("Tick", function() self:Tick() end)
end

--Keep trying to load the game until heroes are finished populating. This means we wont have to re-load the script once in game for it to pull the hero list.
function Zilean:TryLoad()
	if Game.Timer() < 10 then
		return false
	end
	
	print("Loaded [Auto] "..myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Draw", function() self:Draw() end)	
	return true
end

function Zilean:LoadSpells()
	Q = {Range = 900, Width = 180,Delay = 0.25, Speed = 2050,  Sort = "circular"}
	E = {Range = 550}
	R = {Range = 900}
end

function Zilean:CreateMenu()
	AIO = MenuElement({type = MENU, id = myHero.charName, name = "[Auto] " .. myHero.charName})	
	
	AutoUtil:SupportMenu(AIO)	
	
	---[SPELL SETTINGS]---
	AIO:MenuElement({id = "Spells", name = "Spell Settings", type = MENU})
	
	AIO.Spells:MenuElement({id = "General", name = "General", type = MENU})
	AIO.Spells.General:MenuElement({id="InteruptDelay", tooltip = "Maximum time our spell should hit after a dash or hourglass ends", name = "Interrupt Delay", value = .75, min = .1, max = 2, step = .05})
	AIO.Spells.General:MenuElement({id="CCDelay", tooltip = "Minimum CC duration to cause our spells to cast automatically", name = "CC Threshold", value = .5, min = .1, max = 2, step = .05})
	AIO.Spells.General:MenuElement({id = "ImmobileMana", tooltip ="Minimum mana to cast spells on immobile targets", name = "Immobile Mana", value = 30, min = 1, max = 100, step = 5 })	
	AIO.Spells.General:MenuElement({id = "DrawSpells", tooltip ="Draw W and Q ranges", name = "Draw Spell Range", value = true})
	
	AIO.Spells:MenuElement({id = "Exhaust", name = "Exhaust", type = MENU})
	AIO.Spells.Exhaust:MenuElement({id ="Targets", name ="Target List", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy then
			AIO.Spells.Exhaust.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
		end
	end
	AIO.Spells.Exhaust:MenuElement({id = "Health", tooltip ="How low health allies must be to use exhaust", name = "Ally Health", value = 40, min = 1, max = 100, step = 5 })	
	AIO.Spells.Exhaust:MenuElement({id = "Radius", tooltip ="How close targets must be to allies to use exhaust", name = "Peel Distance", value = 200, min = 100, max = 1000, step = 25 })
	AIO.Spells.Exhaust:MenuElement({id="Enabled", name="Enabled", value = false})
	
	
	AIO.Spells:MenuElement({id = "Q", name = "[Q] Timb Bomb", type = MENU})
	AIO.Spells.Q:MenuElement({id ="Targets", name ="Target List", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy then
			AIO.Spells.Q.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
		end
	end
	AIO.Spells.Q:MenuElement({id = "Accuracy", tooltip = "Lower means it will cast more often, higher means it will be more accurate", name = "Q Accuracy", value = 3, min = 1, max = 5, step = 1 })
	AIO.Spells.Q:MenuElement({id = "Mana", tooltip ="Minimum mana percent to auto cast Q", name = "Q Mana", value = 30, min = 1, max = 100, step = 5 })
	
	AIO.Spells:MenuElement({id = "W", name = "[W] Rewind", type = MENU})
	AIO.Spells.W:MenuElement({id = "Cooldown", tooltip ="How long a cooldown on Q+E before using W", name = "Cooldown Remaining", value = 3, min = 1, max = 10, step = .5 })
	AIO.Spells.W:MenuElement({id = "Mana", tooltip ="How high must our mana be to use W", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 5 })
	
	
	AIO.Spells:MenuElement({id = "E", name = "[E] Time Warp", type = MENU})
	AIO.Spells.E:MenuElement({id = "Mana", tooltip ="How high must our mana be to use E", name = "Minimum Mana", value = 20, min = 1, max = 100, step = 5 })
	AIO.Spells.E:MenuElement({id = "Health", tooltip ="How low must an ally health be before we peel", name = "Ally Health", value = 75, min = 1, max = 100, step = 5 })
	AIO.Spells.E:MenuElement({id = "Radius", tooltip ="How close an enemy must be to an ally to use E", name = "Peel Range", value = 250, min = 50, max = 500, step = 25 })
	
	
	AIO.Spells:MenuElement({id = "R", name = "[R] Chronoshift", type = MENU})
	AIO.Spells.R:MenuElement({id = "Health", tooltip = "How low must an ally health be before we ult them", name = "Ally Health", value = 20, min = 1, max = 50, step = 5 })	
	AIO.Spells.R:MenuElement({id = "Damage", tooltip = "How much damage must they have taken in last 1 second before we ult them", name = "Damage Received", value = 15, min = 1, max = 50, step = 1 })
	AIO.Spells.R:MenuElement({id ="Targets", name ="Target List", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly then
			if table.contains(_adcHeroes, hero.charName) then
				AIO.Spells.R.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
			else
				AIO.Spells.R.Targets:MenuElement({id = hero.charName, name = hero.charName, value = false })
			end
		end
	end
	
end

function Zilean:Draw()	
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)    
		if Hero.isEnemy and Hero.pathing.hasMovePath and Hero.pathing.isDashing and Hero.pathing.dashSpeed>500 then
			Draw.Circle(Hero:GetPath(1), 40, 20, Draw.Color(255, 255, 255, 255))
		end
	end
	
	if AIO.Spells.General.DrawSpells:Value() then
		Draw.Circle(myHero.pos, Q.Range, Draw.Color(150, 200, 0,0))
		Draw.Circle(myHero.pos, E.Range, Draw.Color(150, 0, 200,0))
	end
end

function Zilean:Tick()	
	if(not _isLoaded) then
		_isLoaded = Zilean:TryLoad()
	end
	if not _isLoaded or myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
		
	--Try to revive carry
	if Ready(_R) then
		self:AutoR()
	end
		
	--If both Q and E are on cooldown and not about to come back up on their own, cast W to refresh them!
	if myHero.levelData.lvl > 3 and not Ready(_Q) and not Ready(_E) and Ready(_W) and CurrentPctMana(myHero) >= AIO.Spells.W.Mana:Value() then
		if myHero:GetSpellData(_Q).currentCd >= AIO.Spells.W.Cooldown:Value() and myHero:GetSpellData(_E).currentCd >= AIO.Spells.W.Cooldown:Value() then		
			Control.CastSpell(HK_W)
		end
	end
	
	--Use Q/Double Q on immobile targets
	if Ready(_Q) and CurrentPctMana(myHero) >= AIO.Spells.General.ImmobileMana:Value() then
		self:QInterrupt()
	end	
	
	--Slow enemy if they are too close to our carry
	if Ready(_E) and CurrentPctMana(myHero) >= AIO.Spells.E.Mana:Value() then
		self:EPeel()
	end
	
	--Use crucible on carry if they are CCd
	if AutoUtil:IsItemReady(3222) then
		AutoUtil:AutoCrucible()
	end	
	
	--Use Locket
	if AutoUtil:IsItemReady(3190) then
		AutoUtil:AutoLocket()
	end
	
	--Use Q just based on hitchance
	if Ready(_Q) and CurrentPctMana(myHero) >= AIO.Spells.Q.Mana:Value() then
		self:AimSingleQ()
	end
	
	UpdateAllyHealth()
	
end

function Zilean:QInterrupt()
	local target = TPred:GetInteruptTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, AIO.Spells.General.InteruptDelay:Value())
	if target ~= nil then		
		CastMultiQ(target.pos)
	end
	
	--Use Q to target the end of a hourglass stasis
	local target = TPred:GetStasisTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, AIO.Spells.General.InteruptDelay:Value())
	if target ~= nil  and target.isEnemy then
		CastMultiQ(target.pos)
	end		
	
	--Use Q on stunned enemies
	local target, ccRemaining = AutoUtil:GetCCdEnemyInRange(myHero.pos, Q.Range, AIO.Spells.General.CCDelay:Value(), 1 + Q.Delay)
	if target ~= nil then
		CastMultiQ(target.pos)
	end
end

function Zilean:AimSingleQ()
	local target = AutoUtil:FindEnemyWithBuff("ZileanQEnemyBomb", Q.Range, 0)
	if target == nil then
		target = CurrentTarget(Q.Range)
	end
	
	if target == nil then return end  
	local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.Collision, Q.Sort)
	if Ready(_Q) and AIO.Spells.Q.Targets[target.charName] and AIO.Spells.Q.Targets[target.charName]:Value() and HitChance >= AIO.Spells.Q.Accuracy:Value() then
		Control.CastSpell(HK_Q, castpos)
	end
end

function CastMultiQ(target, pos)
	Control.CastSpell(HK_Q, pos)
	local delay = 0.15
	if Ready(_W) then
		if Ready(_E) and AutoUtil:GetDistance(myHero.pos, target.pos) <= E.Range then		
			DelayAction(function()Control.CastSpell(HK_E, target.pos) end,delay)
			delay  = delay + 0.15
		end
		DelayAction(function()Control.CastSpell(HK_W) end,delay)
		DelayAction(function()Control.CastSpell(HK_Q, pos) end,delay + 0.15)
	end
end

function Zilean:EPeel()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		--Its an ally, they are in range and we've set them as a carry. Lets peel for them!
		if Hero.isAlly and CurrentPctLife(Hero) <= AIO.Spells.E.Health:Value() and AutoUtil:GetDistance(myHero.pos, Hero.pos) <= E.Range + AIO.Spells.E.Radius:Value()then
			local distance, target = AutoUtil:NearestEnemy(Hero)	
			if target ~= nil and distance <= AIO.Spells.E.Radius:Value() and AutoUtil:GetDistance(myHero.pos, target.pos) < E.Range then
				Control.CastSpell(HK_E, target.pos)
			end
		end
	end
end

function Zilean:AutoR()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and AutoUtil:GetDistance(myHero.pos, Hero.pos) < R.Range and CurrentPctLife(Hero) <= AIO.Spells.R.Health:Value() and AIO.Spells.R.Targets[Hero.charName] and AIO.Spells.R.Targets[Hero.charName]:Value() and _carryHealthPercent[Hero.charName] then			
			local deltaLifeLost = _carryHealthPercent[Hero.charName] - CurrentPctLife(Hero)
			if deltaLifeLost >= AIO.Spells.R.Damage:Value() then
				Control.CastSpell(HK_R, Hero.pos)
			end
		end
	end	
end

class "Soraka"

local _spellsLastCast = {}
local _isLoaded = false
function Soraka:__init()	
	AutoUtil()
	Callback.Add("Tick", function() self:Tick() end)
end

--Keep trying to load the game until heroes are finished populating. This means we wont have to re-load the script once in game for it to pull the hero list.
function Soraka:TryLoad()
	if Game.Timer() < 10 then
		return false
	end
	
	print("Loaded [Auto] "..myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Draw", function() self:Draw() end)	
	return true
end

function Soraka:LoadSpells()
	Q = {Range = 800, Width = 235,Delay = 0.25, Speed = 1150,  Sort = "circular"}
	W = {Range = 550 }
	E = {Range = 925, Width = 300, Delay = 0.25, Speed = math.huge, Sort = "circular"}
end

function Soraka:CreateMenu()
	AIO = MenuElement({type = MENU, id = myHero.charName, name = "[Auto] " .. myHero.charName})	
	
	AutoUtil:SupportMenu(AIO)
	
	
	---[SPELL SETTINGS]---
	AIO:MenuElement({id = "Spells", name = "Spell Settings", type = MENU})
	
	AIO.Spells:MenuElement({id = "General", name = "General", type = MENU})
	AIO.Spells.General:MenuElement({id="InteruptDelay", tooltip = "Maximum time our spell should hit after a dash or hourglass ends", name = "Interrupt Delay", value = .75, min = .1, max = 2, step = .05})
	AIO.Spells.General:MenuElement({id="CCDelay", tooltip = "Minimum CC duration to cause our spells to cast automatically", name = "CC Threshold", value = .5, min = .1, max = 2, step = .05})
	AIO.Spells.General:MenuElement({id = "ImmobileMana", tooltip ="Minimum mana to cast spells on immobile targets", name = "Immobile Mana", value = 30, min = 1, max = 100, step = 5 })	
	AIO.Spells.General:MenuElement({id = "DrawSpells", tooltip ="Draw W and Q ranges", name = "Draw Spell Range", value = true})
	
	AIO.Spells:MenuElement({id = "Exhaust", name = "Exhaust", type = MENU})
	AIO.Spells.Exhaust:MenuElement({id ="Targets", name ="Target List", type = MENU})
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy then
			AIO.Spells.Exhaust.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
		end
	end
	AIO.Spells.Exhaust:MenuElement({id = "Health", tooltip ="How low health allies must be to use exhaust", name = "Ally Health", value = 40, min = 1, max = 100, step = 5 })	
	AIO.Spells.Exhaust:MenuElement({id = "Radius", tooltip ="How close targets must be to allies to use exhaust", name = "Peel Distance", value = 200, min = 100, max = 1000, step = 25 })
	AIO.Spells.Exhaust:MenuElement({id="Enabled", name="Enabled", value = false})
	
	
	AIO.Spells:MenuElement({id = "Q", name = "[Q] Starcall", type = MENU})
	AIO.Spells.Q:MenuElement({id = "Radius", tooltip = "How far a cast position must be from our mouse to auto cast Q", name = "Mouse Targeting Radius", value = 250, min = 100, max = 1000, step = 25 })
	AIO.Spells.Q:MenuElement({id = "Accuracy", tooltip = "Lower means it will cast more often, higher means it will be more accurate", name = "Q Accuracy", value = 3, min = 1, max = 5, step = 1 })
	AIO.Spells.Q:MenuElement({id = "Mana", tooltip ="Minimum mana percent to auto cast Q", name = "Q Mana", value = 30, min = 1, max = 100, step = 5 })
	
	AIO.Spells:MenuElement({id = "W", name = "[W] Astral Infusion", type = MENU})
	AIO.Spells.W:MenuElement({id = "Targets", name = "Target Settings", type = MENU})	
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly and myHero ~= hero then
			AIO.Spells.W.Targets:MenuElement({id = hero.charName, name = hero.charName, value = 50, min = 1, max = 100, step = 5 })
		end
	end	
	AIO.Spells.W:MenuElement({id = "Health", tooltip ="How high must our health be to heal", name = "W Minimum Health", value = 40, min = 1, max = 100, step = 5 })
	AIO.Spells.W:MenuElement({id = "Mana", tooltip ="How high must our mana be to heal", name = "W Minimum Mana", value = 20, min = 1, max = 100, step = 5 })
	
	
	AIO.Spells:MenuElement({id = "E", name = "[E] Equinox", type = MENU})
	AIO.Spells.E:MenuElement({id="Killsteal", name="Killsteal", value = true})
	AIO.Spells.E:MenuElement({id="TargetImmobile", name="Target Dashes/Hourglass", value = true})
	AIO.Spells.E:MenuElement({id="TargetChannels", name="Target Channels", value = true})
	AIO.Spells.E:MenuElement({id="TargetCC", name="Target CCd Enemies", value = true})
	
	
	AIO.Spells:MenuElement({id = "R", name = "[R] Wish", type = MENU})
	AIO.Spells.R:MenuElement({id = "EmergencyCount", tooltip = "How many allies must be below 40pct for ultimate to cast", name = "Ally count below 40% HP", value = 2, min = 1, max = 5, step = 1 })
	
	AIO.Spells.R:MenuElement({id = "DamageCount", tooltip = "How many allies must have been injured in last second to cast", name = "Ally count Damaged X%", value = 3, min = 1, max = 5, step = 1 })
	AIO.Spells.R:MenuElement({id = "DamagePercent", tooltip = "How much damage allies received in last second", name = "Ally Damage Threshold", value = 40, min = 1, max = 80, step = 1 })
end

function Soraka:Draw()	
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)    
		if Hero.isEnemy and Hero.pathing.hasMovePath and Hero.pathing.isDashing and Hero.pathing.dashSpeed>500 then
			Draw.Circle(Hero:GetPath(1), 40, 20, Draw.Color(255, 255, 255, 255))
		end
	end
	
	if AIO.Spells.General.DrawSpells:Value() then
		Draw.Circle(myHero.pos, Q.Range, Draw.Color(150, 200, 0,0))
		Draw.Circle(myHero.pos, W.Range, Draw.Color(150, 0, 200,0))
	end
end

function Soraka:Tick()	
	if(not _isLoaded) then
		_isLoaded = self:TryLoad()
	end
	
	if not _isLoaded or myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	
	--Cast W on low health carries nearby
	if Ready(_W) and CurrentPctLife(myHero) >= AIO.Spells.W.Health:Value() and CurrentPctMana(myHero) >= AIO.Spells.W.Mana:Value() then
		self:AutoW()
	end
	
	--Cast E and or Q on targets that aren't mobile
	if CurrentPctMana(myHero) >= AIO.Spells.General.ImmobileMana:Value() then
		self:HitImmobileTargets()
	end
	
	--Cast Q on targets near our mouse (based on accuracy)
	if Ready(_Q) and CurrentPctMana(myHero) >= AIO.Spells.Q.Mana:Value() then
		self:HitTargetsNearMouse()
	end
	
	--Use crucible on carry if they are CCd
	if AutoUtil:IsItemReady(3222) then
		AutoUtil:AutoCrucible()
	end
	
	
	--Use Locket
	if AutoUtil:IsItemReady(3190) then
		AutoUtil:AutoLocket()
	end
	
	if Ready(_R) then
		self:AutoR()
	end	
	
	if AIO.Spells.Exhaust.Enabled:Value() then
		self:AutoExhaust()
	end
	
	if Ready(_E) and AIO.Spells.E.Killsteal:Value() then
		self:KillstealE()
	end
		
	UpdateAllyHealth()
end


function Soraka:AutoR()	
	--Use R if enough allies are below 40% health
	if self:GetLowHealthAllyCount() >= AIO.Spells.R.EmergencyCount:Value() then
		Control.CastSpell(HK_R)
	end
	
	--Use R if enough allies have taken X% of their max hp as dmg in the last second
	local injuredCount = self:CountInjuredAllies(AIO.Spells.R.DamagePercent:Value())	
	if injuredCount >= AIO.Spells.R.DamageCount:Value() then
		Control.CastSpell(HK_R)
	end		
end

function Soraka:CountInjuredAllies(percent, origin, radius)	
	local count = 0	
	if not origin then
		origin = myHero.pos
	end
	if not radius then
		radius = math.huge
	end
	
	for i = 1, Game.HeroCount() do
		local ally = Game.Hero(i)
		if ally.isAlly and ally.alive and _carryHealthPercent and _carryHealthPercent[ally.charName] and AutoUtil:GetDistance(origin, ally.pos) <= radius then		
			
			local life = _carryHealthPercent[ally.charName]
			local deltaLifeLost = life - CurrentPctLife(ally)		
			if deltaLifeLost > percent then
				count = count + 1
			end
		end
	end
	
	return count
end

function Soraka:AutoW()
	if _spellsLastCast and _spellsLastCast.HK_W and Game.Timer() - _spellsLastCast.HK_W  < .5 then return end	
	local target = self:GetHealingTarget()
	if target ~= nil then
		self.CastW(HK_W, target.pos)
	end
	
end

function Soraka:HitImmobileTargets()

	if Ready(_E) then	
		if AIO.Spells.E.TargetChannels:Value() then
			local target = AutoUtil.GetChannelingEnemyInRange(myHero.pos, E.Range, .5)
			if target ~= nil then
				Control.CastSpell(HK_E, target.pos)
			end
		end
		
		if AIO.Spells.E.TargetImmobile:Value() then
			local target = TPred:GetInteruptTarget(myHero.pos, E.Range, E.Delay, E.Speed, AIO.Spells.General.InteruptDelay:Value())
			if target ~= nil then
				Control.CastSpell(HK_E, target:GetPath(1))
			end
			
			local target = TPred:GetStasisTarget(myHero.pos, E.Range, E.Delay, E.Speed, AIO.Spells.General.InteruptDelay:Value())
			if target ~= nil  and target.isEnemy then
				Control.CastSpell(HK_E, target.pos)	
			end		
		end
		
		
		if AIO.Spells.E.TargetCC:Value() then
			local target, ccRemaining = AutoUtil:GetCCdEnemyInRange(myHero.pos, E.Range, AIO.Spells.General.CCDelay:Value(), 1 + E.Delay)
			if target then
				Control.CastSpell(HK_E, target.pos)	
			end
		end
	end
	
	if Ready(_Q) then
		--Use Q to hit enemies who are using a channel longer than .5 seconds
		local target = AutoUtil.GetChannelingEnemyInRange(myHero.pos, Q.Range, .5)
		if target ~= nil then
			Control.CastSpell(HK_Q, target.pos)
		end
		
		--Use Q to target the end of a gapcloser
		local target = TPred:GetInteruptTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, AIO.Spells.General.InteruptDelay:Value())
		if target ~= nil then
			Control.CastSpell(HK_Q, target:GetPath(1))
		end
		
		--Use Q to target the end of a hourglass stasis
		local target = TPred:GetStasisTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, AIO.Spells.General.InteruptDelay:Value())
		if target ~= nil  and target.isEnemy then
			Control.CastSpell(HK_Q, target.pos)	
		end		
		
		--Use Q on Stunned Targets
		local target, ccRemaining = AutoUtil:GetCCdEnemyInRange(myHero.pos, Q.Range, AIO.Spells.General.CCDelay:Value(), 1 + Q.Delay)
		if target then
			Control.CastSpell(HK_Q, target.pos)	
		end
	end
end

function Soraka:HitTargetsNearMouse()	
	
	--If we JUST tried to cast, dont move the mouse and try to cast again.
	if _spellsLastCast and _spellsLastCast.HK_Q and Game.Timer() - _spellsLastCast.HK_Q  < .5 then return end	
	
	--Get the highest accuracy target near our mouse that is within QRadius
	local targets = {}
	for i = 1, Game.HeroCount() do
		local target = Game.Hero(i)
		if target.isEnemy and isValidTarget(target, Q.Range) and target.alive then
			local castPos,hitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.Collision, Q.Sort,0.0)
			if hitChance > 0 and AutoUtil:GetDistance(mousePos, target.pos) <= AIO.Spells.Q.Radius:Value() then
				local lookupValue ={target.charName, castPos, hitChance}
				table.insert(targets, lookupValue)
			end
		end
	end	
	
	--Sort the table so that we aim for the highest hitchance target possible
	table.sort(targets, function( a, b ) return a[3] > b[3] end)	
	if #targets > 0 then
		if targets[1][3] >= AIO.Spells.Q.Accuracy:Value() then
			self.CastQ(HK_Q, targets[1][2], 0.5)
			return
		end
	end
end

--Returns the total number of allies below 40% health. Soraka ult heals 50% more on these targets so we should really use this as our threshold and save W for healing ADCs.
function Soraka:GetLowHealthAllyCount()
	local count = 0
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly and hero.alive and CurrentPctLife(hero) <= 40 then
			count = count + 1
		end
	end
	
	return count
end


function Soraka:CastW(position, delay)
	if not delay then
		delay = 0.5
	end
	
	if _spellsLastCast and _spellsLastCast[HK_W] and Game.Timer() - _spellsLastCast[HK_W]  < delay then return end	
	
	
	_spellsLastCast[HK_W] = Game.Timer()
	Control.CastSpell(HK_W, position)
	
end
function Soraka:CastQ(position, delay)
	if not delay then
		delay = 0.5
	end
	
	if _spellsLastCast and _spellsLastCast[HK_Q] and Game.Timer() - _spellsLastCast[HK_Q]  < delay then return end	
	
	
	_spellsLastCast[HK_Q] = Game.Timer()
	Control.CastSpell(HK_Q, position)
	
end

function Soraka:GetExhaust()
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

function Soraka:AutoExhaust()
	local exhaustHotkey = self:GetExhaust()	
	if not exhaustHotkey then return end
	
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		--It's an enemy who is within exhaust range and is toggled ON in ExhaustList
		if enemy.isEnemy and AutoUtil:GetDistance(myHero.pos, enemy.pos) <= 600 + enemy.boundingRadius and isValidTarget(enemy, 650) and AIO.Spells.Exhaust.Targets[enemy.charName] and AIO.Spells.Exhaust.Targets[enemy.charName]:Value() then
			for allyIndex = 1, Game.HeroCount() do
				local ally = Game.Hero(allyIndex)
				if ally.isAlly and ally.alive and AutoUtil:GetDistance(enemy.pos, ally.pos) <= AIO.Spells.Exhaust.Radius:Value() and CurrentPctLife(ally) <= AIO.Spells.Exhaust.Health:Value() then
					Control.CastSpell(exhaustHotkey, enemy)
				end
			end
		end
	end
end

function Soraka:KillstealE()
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.isEnemy and enemy.alive and enemy.isTargetable and AutoUtil:GetDistance(myHero.pos, enemy.pos) <= E.Range then		
			--This is SO SO SO OVERKILL but it will be accurate to ensure you get the last hit. It does not account for incoming damage is all.
			local spellLevel = myHero:GetSpellData(_E).level
			local eDamage = 70 + (spellLevel -1) * 30 + myHero.ap * 0.4			
			local targetMR = enemy.magicResist * myHero.magicPenPercent - myHero.magicPen	

			local damageReduction = 100 / ( 100 + targetMR)
			if targetMR < 0 then
				damageReduction = 2 - (100 / (100 - targetMR))
			end
			
			local damage = eDamage * damageReduction
			
			if damage >= enemy.health then
				Control.CastSpell(HK_E, enemy.pos)
			end			
		end
	end
end

function Soraka:GetHealingTarget()	
	local targets = {}
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly and hero ~= myHero and hero.alive and AutoUtil:GetDistance(myHero.pos, hero.pos) <= W.Range + hero.boundingRadius and AIO.Spells.W.Targets[hero.charName] and AIO.Spells.W.Targets[hero.charName]:Value() >= CurrentPctLife(hero) then		
			local pctLife = CurrentPctLife(hero)
			table.insert(targets, {hero, pctLife})
		end
	end
	
	table.sort(targets, function( a, b ) return a[2] < b[2] end)	
	if #targets > 0 then
		return targets[1][1]
	end
end