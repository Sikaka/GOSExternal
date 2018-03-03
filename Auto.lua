local Heroes = {"Nami","Brand", "Velkoz", "Heimerdinger", "Zilean"}
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

	
class "AutoUtil"

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
	--This is a list of ADCs that we will want to help by using auto E on them and cleansing with crucible. Auto select all ADCs but let user toggle at will.	
	AIO:MenuElement({id = "HeroList", name = "Auto Assist List", type = MENU})	
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly then
			if table.contains(_adcHeroes, Hero.charName) then
				AIO.HeroList:MenuElement({id = Hero.charName, name = Hero.charName, value = true, toggle = true})
			else
				AIO.HeroList:MenuElement({id = Hero.charName, name = Hero.charName, value = false, toggle = false})				
			end
		end
	end	
	
	--This lists the types of CC we are willing to use crucible to remove (On adcs only)
	AIO:MenuElement({id = "CleanseList", name = "Auto Crucible List", type = MENU})
	AIO.CleanseList:MenuElement({id = "CleanseTime", name = "Cleanse CC If Duration Over (Seconds)", value = .5, min = .1, max = 2, step = .1 })
	AIO.CleanseList:MenuElement({id = "Suppression", name = "Suppression", value = true, toggle = true})
	AIO.CleanseList:MenuElement({id = "Stun", name = "Stun", value = true, toggle = true})
	AIO.CleanseList:MenuElement({id = "Sleep", name = "Sleep", value = true, toggle = true})
	AIO.CleanseList:MenuElement({id = "Polymorph", name = "Polymorph", value = true, toggle = true})
	AIO.CleanseList:MenuElement({id = "Taunt", name = "Taunt", value = true, toggle = true})
	AIO.CleanseList:MenuElement({id = "Charm", name = "Charm", value = true, toggle = true})
	AIO.CleanseList:MenuElement({id = "Fear", name = "Fear", value = true, toggle = true})
	AIO.CleanseList:MenuElement({id = "Blind", name = "Blind", value = false, toggle = true})	
	AIO.CleanseList:MenuElement({id = "Snare", name = "Snare", value = false, toggle = true})
	AIO.CleanseList:MenuElement({id = "Slow", name = "Slow", value = false, toggle = true})
	AIO.CleanseList:MenuElement({id = "Poison", name = "Poison", value = false, toggle = true})
end

function AutoUtil:GetDistanceSqr(p1, p2)
	assert(p1, "GetDistance: invalid argument: cannot calculate distance to "..type(p1))
	assert(p2, "GetDistance: invalid argument: cannot calculate distance to "..type(p2))
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function AutoUtil:GetDistance(p1, p2)
	return math.sqrt(self:GetDistanceSqr(p1, p2))
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
		if Hero.isAlly and Hero ~= myHero then
			if AIO.HeroList[Hero.charName] and AIO.HeroList[Hero.charName]:Value() then
				for ccName, ccType in pairs(_ccNames) do
					if AIO.CleanseList[ccName] and AIO.CleanseList[ccName]:Value() and self:HasBuffType(Hero, ccType, AIO.CleanseList.CleanseTime:Value()) then
						AutoUtil:CastItem(Hero, 3222, 650)
					end
				end
			end
		end
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
	if Ready(_W) and HitChance >= AIO.Skills.WAcc:Value() and myHero.mana/myHero.maxMana >= AIO.Skills.WMan:Value() / 100 then
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
	if target ~= nil then
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

function Velkoz:Tick()
	if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or not AIO.autoSkillsActive:Value() then return end
	
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
	end
end


function Velkoz:FindEnemyWithBuff(buffName, range, stackCount)
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
	if target ~= nil then
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
	local Enemy = self:FindEnemyWithBuff("velkozresearchstack", W.Range, 2)
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
	if target ~= nil then
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
	if Game.HeroCount() < 2 then
		return false
	end
	
	print("Loaded [Auto] "..myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Draw", function() self:Draw() end)	
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
end


function Nami:AutoQInterrupt()
	--Use Q to target the end of a gapcloser
	local target = TPred:GetInteruptTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, AIO.Skills.QTiming:Value())
	if target ~= nil then
		Control.CastSpell(HK_Q, target:GetPath(1))
	end
	
	--Use Q to target the end of a hourglass stasis
	local target = TPred:GetStasisTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, AIO.Skills.QTiming:Value())
	if target ~= nil then
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
		if Hero.isAlly and AutoUtil:GetDistance(myHero.pos, Hero.pos) <= W.Range and CurrentPctLife(Hero) <= AIO.Skills.WEmergencyPct:Value() then
			Control.CastSpell(HK_W, Hero.pos)			
		end
	end
end

function Nami:AutoWBounce()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and AutoUtil:GetDistance(myHero.pos, Hero.pos) <= W.Range and CurrentPctLife(Hero) <= AIO.Skills.WBouncePct:Value() then
			if AutoUtil:NearestEnemy(Hero) < 500 then
				Control.CastSpell(HK_W, Hero.pos)
			end
		end
	end
end

function Nami:AutoE()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if  Hero.isAlly and Hero ~= myHero and AutoUtil:GetDistance(myHero.pos, Hero.pos) <= E.Range and table.contains(_adcHeroes, Hero.charName) then
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
	if target ~= nil then
		Control.CastSpell(HK_E, target.pos)	
	end	
	
	
	--Use E on stunned enemies
	local target, ccRemaining = AutoUtil:GetCCdEnemyInRange(myHero.pos, E.Range, AIO.Skills.ECCTiming:Value(), 1 + E.Delay)
	if target then
		Control.CastSpell(HK_E, target.pos)
	end
	
	--Use E on gapclosing enemies who are jumping VERY close to us. Note: This is not finished at all and will be buggy
	local target, endDistance, interceptTime = self:GetDashingTarget(E.Range, E.Delay, E.Speed)
	if target and endDistance <= AIO.Skills.EDistance:Value() and target.pathing and target.pathing.endPos then
		Control.CastSpell(HK_E, target.pathing.endPos)
	end
end

function Heimerdinger:WImmobile()
	--Use W to target the end of a gapcloser
	local target = TPred:GetInteruptTarget(myHero.pos, W.Range, W.Delay, W.Speed, AIO.Skills.ETiming:Value())
	if target ~= nil then
		Control.CastSpell(HK_E, target:GetPath(1))	
	end
	
	--Use W to target the end of a hourglass stasis
	local target = TPred:GetStasisTarget(myHero.pos, W.Range, W.Delay, W.Speed, AIO.Skills.ETiming:Value())
	if target ~= nil then
		Control.CastSpell(HK_E, target.pos)	
	end	
		
	--Use W on stunned enemies
	local target, ccRemaining = AutoUtil:GetCCdEnemyInRange(myHero.pos, W.Range, AIO.Skills.ECCTiming:Value(), 1 + W.Delay)
	if target then
		Control.CastSpell(HK_E, target.pos)
	end	
end

function Heimerdinger:CastW(target, pos)
	if target and Ready(_W) then
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
local _carryHealthPercent = 	{}
local _healthTick
local _isLoaded = false
function Zilean:__init()	
	AutoUtil()
	Callback.Add("Tick", function() self:Tick() end)
	_healthTick = Game.Timer()
end

--Keep trying to load the game until heroes are finished populating. This means we wont have to re-load the script once in game for it to pull the hero list.
function Zilean:TryLoad()
	if Game.HeroCount() < 2 then
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
	
	AIO:MenuElement({id = "Skills", name = "Skills", type = MENU})
	AIO.Skills:MenuElement({id = "QTiming", name = "Q Interrupt Delay", value = 1, min = .1, max = 2, step = .05 })
	AIO.Skills:MenuElement({id = "QCCTiming", name = "Q Imobile Targets", value = .5, min = .1, max = 2, step = .05 })
	AIO.Skills:MenuElement({id = "QStunMana", name = "Q Stun Mana", value = 25, min = 1, max = 100, step = 5 })	
	
	AIO.Skills:MenuElement({id = "QAccuracy", name = "Q Accuracy", value = 3, min = 1, max = 5, step = 1 })
	AIO.Skills:MenuElement({id = "QMana", name = "Q Mana", value = 30, min = 1, max = 100, step = 5 })
		
	AIO.Skills:MenuElement({id = "WMana", name = "W Mana", value = 30, min = 1, max = 100, step = 5 })
	
	AIO.Skills:MenuElement({id = "EPeelDistance", name = "E Peel Distance", value = 250, min = 50, max = 500, step = 10 })
	AIO.Skills:MenuElement({id = "EPeelHealth", name = "E Peel Health", value = 50, min = 1, max = 100, step = 5 })
	AIO.Skills:MenuElement({id = "EPeelMana", name = "E Peel Mana", value = 30, min = 1, max = 100, step = 5 })
	
	
	AIO.Skills:MenuElement({id = "RMinHealth", name = "Auto R Health Pct", value = 20, min = 1, max = 100, step = 5 })
	AIO.Skills:MenuElement({id = "RHealthLoss", name = "Auto R Damage Pct", value = 5, min = 1, max = 50, step = 1 })
	AIO.Skills:MenuElement({id = "RHealthFrequency", name = "Auto R Damage Check Frequency", value = 1, min = .1, max = 1, step = .1 })
	
	AIO:MenuElement({id = "autoSkillsActive", name = "Auto Skills Enabled",value = true, toggle = true, key = 0x7A })
end

function Zilean:Draw()
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

function Zilean:Tick()	
	if(not _isLoaded) then
		_isLoaded = Zilean:TryLoad()
	end
	if not _isLoaded or myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or not AIO.autoSkillsActive:Value() then return end
		
	--Try to revive carry
	if Ready(_R) then
		self:AutoR()
	end
		
	--If both Q and E are on cooldown, cast W to refresh them!
	if not Ready(_Q) and not Ready(_E) and Ready(_W) and CurrentPctMana(myHero) >= AIO.Skills.WMana:Value() then
		Control.CastSpell(HK_W)
	end
	
	--Use Q/Double Q on immobile targets
	if Ready(_Q) and CurrentPctMana(myHero) >= AIO.Skills.QStunMana:Value() then
		self:QInterrupt()
	end	
	
	--Slow enemy if they are too close to our carry
	if Ready(_E) and CurrentPctMana(myHero) >= AIO.Skills.EPeelMana:Value() then
		self:EPeel()
	end
	
	--Use crucible on carry if they are CCd
	if AutoUtil:IsItemReady(3222) then
		AutoUtil:AutoCrucible()
	end
	
	
	--Use Q just based on hitchance
	if Ready(_Q) and CurrentPctMana(myHero) >= AIO.Skills.QMana:Value() then
		self:AimSingleQ()
	end
end

function Zilean:QInterrupt()
	local target = TPred:GetInteruptTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, AIO.Skills.QTiming:Value())
	if target ~= nil then		
		CastMultiQ(target.pos)
	end
	
	--Use Q to target the end of a hourglass stasis
	local target = TPred:GetStasisTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, AIO.Skills.QTiming:Value())
	if target ~= nil then
		CastMultiQ(target.pos)
	end		
	
	--Use Q on stunned enemies
	local target, ccRemaining = AutoUtil:GetCCdEnemyInRange(myHero.pos, Q.Range, AIO.Skills.QCCTiming:Value(), 1 + Q.Delay)
	if target ~= nil then
		CastMultiQ(target.pos)
	end
end

function Zilean:AimSingleQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end  
	local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.Collision, Q.Sort)
	if Ready(_Q) and HitChance >= AIO.Skills.QAccuracy:Value() then
		Control.CastSpell(HK_Q, castpos)
	end
end

function CastMultiQ(pos)
	Control.CastSpell(HK_Q, pos)
	if Ready(_W) then
		DelayAction(function()Control.CastSpell(HK_W) end,0.15)
		DelayAction(function()Control.CastSpell(HK_Q, pos) end,0.3)
	end
end

function Zilean:EPeel()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		--Its an ally, they are in range and we've set them as a carry. Lets peel for them!
		if Hero.isAlly and CurrentPctLife(Hero) <= AIO.Skills.EPeelHealth:Value() and AutoUtil:GetDistance(myHero.pos, Hero.pos) <= E.Range + AIO.Skills.EPeelDistance:Value()then
			local distance, target = AutoUtil:NearestEnemy(Hero)	
			if target ~= nil and distance <= AIO.Skills.EPeelDistance:Value() and AutoUtil:GetDistance(myHero.pos, target.pos) < E.Range then
				Control.CastSpell(HK_E, target.pos)
			end
		end
	end
end

function Zilean:AutoR()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and AutoUtil:GetDistance(myHero.pos, Hero.pos) < R.Range and CurrentPctLife(Hero) <= AIO.Skills.RMinHealth:Value() and AIO.HeroList[Hero.charName] and AIO.HeroList[Hero.charName]:Value() and _carryHealthPercent[Hero.charName] then			
			local deltaLifeLost = _carryHealthPercent[Hero.charName] - CurrentPctLife(Hero)
			if deltaLifeLost >= AIO.Skills.RHealthLoss:Value() then
				Control.CastSpell(HK_R, Hero.pos)
			end
		end
	end
	
	self:UpdateAllyHealth()	
end

function Zilean:UpdateAllyHealth()
	local deltaTick = Game.Timer() - _healthTick
	if deltaTick >= AIO.Skills.RHealthFrequency:Value() then
		_carryHealthPercent = {}
		_healthTick = Game.Timer()
		for i = 1, Game.HeroCount() do
			local Hero = Game.Hero(i)
			if Hero.isAlly and AIO.HeroList[Hero.charName] and AIO.HeroList[Hero.charName]:Value() then
				_carryHealthPercent[Hero.charName] = CurrentPctLife(Hero)				
			end
		end
	end
end