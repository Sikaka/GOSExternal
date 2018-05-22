if _G.Activator then return end
class "__Activator"

local LocalGameHeroCount 			= Game.HeroCount;
local LocalGameHero 				= Game.Hero;

function __Activator:__init()
	print("Loaded Auto3.0: Activator")
	
	self.CCInfo = {
		{	Type = 5,	Name = "Stun",			Value = true	},
		{	Type = 7,	Name = "Silence",		Value = false	},
		{	Type = 8,	Name = "Taunt",			Value = true	},
		{	Type = 9,	Name = "Polymorph",		Value = true	},
		{	Type = 10,	Name = "Slow",			Value = false	},
		{	Type = 11,	Name = "Snare",			Value = true	},
		{	Type = 18,	Name = "Sleep",			Value = true	},
		{	Type = 21,	Name = "Fear",			Value = true	},
		{	Type = 22,	Name = "Charm",			Value = true	},
		{	Type = 23,	Name = "Poison",		Value = false	},
		{	Type = 24,	Name = "Suppression",	Value = true	},
		{	Type = 25,	Name = "Blind",			Value = true	},
		{	Type = 28,	Name = "Flee",			Value = true	},
		{	Type = 31,	Name = "Disarm",		Value = true	},
	}
	
	self.ActivatorMenu = MenuElement({type = MENU, id = "Activator", name = "[Activator]"})
	self.ActivatorMenu:MenuElement({id = "Summoners", name = "Summoners", type = MENU})
	
	self.ActivatorMenu:MenuElement({id = "Healing", name = "Healing", type = MENU})
	self.ActivatorMenu.Healing:MenuElement({id = "Auto", name = "Use Healing Items", value = true, toggle = true})
	self.ActivatorMenu.Healing:MenuElement({id = "Life", name = "% Life", value = 50, min = 1, max = 100, step = 1})
	
	self.ActivatorMenu:MenuElement({id = "Cleanse", name = "Cleanse", type = MENU})
	self.ActivatorMenu.Cleanse:MenuElement({id = "CC", name = "CC Settings", type = MENU})	
	for _, cc in pairs(self.CCInfo) do
		self.ActivatorMenu.Cleanse.CC:MenuElement({id = cc.Type, name = cc.Name, value = cc.Value})
	end
	self.ActivatorMenu.Cleanse:MenuElement({id="Auto", name="Use Always", value = false})
	self.ActivatorMenu.Cleanse:MenuElement({id="Combo", name="Use In Combo", value = true})
		
	self.ActivatorMenu:MenuElement({id = "Damage", name = "Damage", type = MENU})
	self.ActivatorMenu.Damage:MenuElement({id="Killsteal", name="Killsteal", value = true})
	self.ActivatorMenu.Damage:MenuElement({id="Combo", name="AA Reset (Combo)", value = true})
		
	self.Inventory = {}
	--Initialize empty collection so we can read existing items at start
	for i = ITEM_1, ITEM_7 do
		self.Inventory[i] = {valid = false, data = nil}		
	end
	self.Base = 
			MapID == TWISTED_TREELINE and myHero.team == 100 and {x=1076, y=150, z=7275} or myHero.team == 200 and {x=14350, y=151, z=7299} or
			MapID == SUMMONERS_RIFT and myHero.team == 100 and {x=419,y=182,z=438} or myHero.team == 200 and {x=14303,y=172,z=14395} or
			MapID == HOWLING_ABYSS and myHero.team == 100 and {x=971,y=-132,z=1180} or myHero.team == 200 and {x=11749,y=-131,z=11519} or
			MapID == CRYSTAL_SCAR and {x = 0, y = 0, z = 0}
			
	self.ItemHotkeys = {
		[ITEM_1] = HK_ITEM_1,
		[ITEM_2] = HK_ITEM_2,
		[ITEM_3] = HK_ITEM_3,
		[ITEM_4] = HK_ITEM_4,
		[ITEM_5] = HK_ITEM_5,
		[ITEM_6] = HK_ITEM_6,
		[ITEM_7] = HK_ITEM_7,
	}
	
	self.SummonerFunctions = {
		["SummonerExhaust"] = { 
			Tick = self.Exhaust,
			Initialize = function () 
				local m = self.ActivatorMenu.Summoners:MenuElement({id = "Exhaust", name = "Exhaust", type = MENU})
				m:MenuElement{id = "Radius", name = "Radius", value = 300, min = 100, max = 700, step = 50}
				m:MenuElement{id = "Combo", name = "Combo Only", value = true}
			end
		},
		["SummonerDot"] = { 
			Tick = self.Ignite, 
			Initialize = function () 
				local m = self.ActivatorMenu.Summoners:MenuElement({id = "Ignite", name = "Ignite", type = MENU})
				m:MenuElement{id = "Combo", name = "Use in Combo", value = true}
				m:MenuElement{id = "Killsteal", name = "Killsteal", value = true}
			end
		},
		["SummonerHeal"] = { 
			Tick = self.Heal,
			Initialize = function () 
				local m = self.ActivatorMenu.Summoners:MenuElement({id = "Heal", name = "Heal", type = MENU})
				m:MenuElement{id = "Health", name = "Health %", value = 30, min = 1, max = 100, step = 1}
				m:MenuElement{id = "Combo", name = "Combo Only", value = false}
			end
		},
		["SummonerBarrier"] = { 
			Tick = self.Barrier,
			Initialize = function () 
				local m = self.ActivatorMenu.Summoners:MenuElement({id = "Barrier", name = "Barrier", type = MENU})
				m:MenuElement{id = "Health", name = "Health %", value = 30, min = 1, max = 100, step = 1}
				m:MenuElement{id = "Combo", name = "Combo Only", value = false}
			end
		},
	}
	
	self.ConsumableItems = {
		[2010] = {name = "Biscuit of Rejuvenation",	buffName = "ItemMiniRegenPotion"},
		[2003] = {name = "Health Potion",	buffName = "RegenerationPotion"},
		[2031] = {name = "Refillable Potion",	buffName = "ItemCrystalFlask"},
		[2032] = {name = "Hunter's Potion",	buffName = "ItemCrystalFlaskJungle"},
		[2033] = {name = "Corrupting Potion",	buffName = "ItemDarkCrystalFlask"},
	}
	
	self.WardingItems = {
		[3340] = {name = "Warding Totem",	range = 600},
		[3098] = {name = "Frostfang",	range = 600},
		[3092] = {name = "Remnant of the Watchers",	range = 600},
		[3096] = {name = "Nomad's Medallion",	range = 600},
		[3069] = {name = "Remnant of the Ascended",	range = 600},
		[3097] = {name = "Targon's Brace",	range = 600},
		[3401] = {name = "Remnant of the Aspect",	range = 600},
		[2055] = {name = "Control Ward",	range = 600},
		[3363] = {name = "Farsight Alteration",	range= 4000}
	}
	
	self.DamageItems = {
		[3077] = {name = "Tiamat", range = 300},
		[3074] = {name = "Ravenous Hydra",  range = 300},
		[3748] = {name = "Titanic Hydra", range = 300},
		[3153] = {name = "Blade of the Ruined King", range = 600},
		[3144] = {name = "Bilgewater Cutlass", range = 600},
		[3146] = {name = "Hextech Gunblade", range = 700},
		--[3152] = {name = "Hextech Protobelt-01", range = 800},
		--[3030] = {name = "Hextech GLP-800", range = 800},
	}
	self.ShieldItems = {
		[2420] = {name = "Stopwatch", effect = "Statis"},
		[3157] = {name = "Zhonya's Hourglass", effect = "Statis"},
		
		[3140] = {name = "Quicksilver Sash", target = "Self", effect = "Cleanse"},
		[3139] = {name = "Mercurial Scimittar", target = "Self", effect = "Cleanse"},
		[3222] = {name = "Mikael's Crucible", target = "Ally", effect = "Cleanse", Range = 650},
		
		[3190] = {name = "Locket of the Iron Solari", target = "Self", effect = "Shield", Radius = 700},
	}
	
	DelayAction(function () self.LoadCompleted() end, math.max(2,30 - Game.Timer()))
end

function __Activator:CanTarget(target)
	return target and target.pos and target.isEnemy and target.alive and target.health > 0 and target.visible and target.isTargetable
end


function __Activator:EnableOrb(bool)
    if _G.EOWLoaded then
        EOW:SetMovements(bool)
        EOW:SetAttacks(bool)
    elseif _G.SDK and _G.SDK.Orbwalker then
        _G.SDK.Orbwalker:SetMovement(bool)
        _G.SDK.Orbwalker:SetAttack(bool)
    else
        GOS.BlockMovement = not bool
        GOS.BlockAttack = not bool
    end
end

function __Activator:CastSpell(key, pos, isLine)
	if not pos then Control.CastSpell(key) return end
	
	if type(pos) == "userdata" and pos.pos then
		pos = pos.pos
	end
	
	if not pos:ToScreen().onScreen and isLine then			
		pos = myHero.pos + (pos - myHero.pos):Normalized() * 250
	end
	
	if not pos:ToScreen().onScreen then
		return
	end
		
	EnableOrb(false)
	Control.CastSpell(key, pos)
	EnableOrb(true)		
end

function __Activator:LoadCompleted()
	Activator.LocalGeometry = _G.Alpha.Geometry
	Activator.LocalDamageManager = _G.Alpha.DamageManager
	Activator.LocalObjectManager = _G.Alpha.ObjectManager
	Activator.LocalOrbwalker = _G.SDK.Orbwalker		
	Activator.LocalOrbwalker:OnPostAttack(function(args) Activator:OnPostAttack() end)		
	Callback.Add("Tick", function () Activator:CheckItems() end)
	Callback.Add("Tick", function () Activator:Tick() end)
		
	local summoner = myHero:GetSpellData(SUMMONER_1)
	if Activator.SummonerFunctions[summoner.name] then
		Activator.Summoner1 = Activator.SummonerFunctions[summoner.name].Tick
		Activator.SummonerFunctions[summoner.name]:Initialize()
	else
		print("Unhandled Summoner1: " .. summoner.name)
	end	
	
	summoner = myHero:GetSpellData(SUMMONER_2)
	if Activator.SummonerFunctions[summoner.name] then
		Activator.Summoner2 = Activator.SummonerFunctions[summoner.name].Tick
		Activator.SummonerFunctions[summoner.name]:Initialize()
	else
		print("Unhandled Summoner2: " .. summoner.name)
	end
	
end

function __Activator:OnBuyItem(item, slot)
end

function __Activator:OnSellItem(item, slot)	
end

local nextTick = Game.Timer()
function __Activator:Tick()	
	if nextTick > Game.Timer() then return end
	nextTick = Game.Timer() + .25
	
	if self.Summoner1 and myHero:GetSpellData(SUMMONER_1).currentCd < 1 then
		
		self:Summoner1(SUMMONER_1, HK_SUMMONER_1)
	end
	if self.Summoner2 and myHero:GetSpellData(SUMMONER_2).currentCd < 1 then
		self:Summoner2(SUMMONER_2, HK_SUMMONER_2)
	end
end

local nextInventoryCheck = Game.Timer()
function __Activator:CheckItems()
	if nextInventoryCheck > Game.Timer() then return end
	nextInventoryCheck = Game.Timer() + 5
	for i = ITEM_1, ITEM_7 do
		if myHero:GetItemData(i).itemID ~= 0 then
			if self.Inventory[i].valid == false then
				self.Inventory[i].valid = true
				self.Inventory[i].data = myHero:GetItemData(i)
				self.Inventory[i].spell = self.LocalDamageManager.MasterSkillLookupTable[myHero:GetItemData(i).itemID]
				self:OnBuyItem(myHero:GetItemData(i), i)			
			end
		else
			if self.Inventory[i].valid == true then
				self:OnSellItem(self.Inventory[i].data, i)
				self.Inventory[i].valid = false
				self.Inventory[i].data = nil
			end
		end
	end
end


function __Activator:Exhaust(spellSlot, hotkey)
	
end

function __Activator:Ignite(spellSlot, hotkey)
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if CanTarget(hero) and LocalGeometry:IsInRange(myHero.pos, hero.pos, 600) then	
			local remainingHealth = hero.health - LocalDamageManager:RecordedIncomingDamage(hero)
			if not remainingHealth then
				remainingHealth = hero.health
			end
			if remainingHealth > 0 then
				if remainingHealth < ({80,105,130,155,180,205,230,255,280,305,330,355,380,405,430,455,480,505})[myHero.levelData.lvl] then	
					Activator:CastSpell(hotkey, hero)
				elseif Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and Activator.ActivatorMenu.Summoners.Ignite.Combo:Value() then
					Activator:CastSpell(hotkey, hero)
				end
			end
		end
	end	
end

function __Activator:Barrier(spellSlot, hotkey)
	if myHero.alive and not Activator.ActivatorMenu.Summoners.Barrier.Combo:Value() or Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
		local incomingDamage = LocalDamageManager:RecordedIncomingDamage(myHero)
		local remainingLifePct = (myHero.health - incomingDamage) / myHero.maxHealth * 100
		if remainingLifePct <= Activator.ActivatorMenu.Summoners.Barrier.Health:Value() and incomingDamage / myHero.health  * 100 > 25 then
			Control.CastSpell(hotkey)
		end
	end
end

function __Activator:Heal(spellSlot, hotkey)
	if myHero.alive and not Activator.ActivatorMenu.Summoners.Heal.Combo:Value() or Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then	
		local incomingDamage = LocalDamageManager:RecordedIncomingDamage(myHero)
		local remainingLifePct = (myHero.health - incomingDamage) / myHero.maxHealth * 100
		if remainingLifePct <= Activator.ActivatorMenu.Summoners.Heal.Health:Value() and incomingDamage / myHero.health  * 100 > 25 then
			Control.CastSpell(hotkey)
		end
	end
end

function __Activator:Cleanse(spellSlot, hotkey)
end

function __Activator:OnPostAttack()
	--Check for E AA reset
	if not myHero.activeSpell.target then return end
	local target = LocalObjectManager:GetHeroByHandle(myHero.activeSpell.target)
	if not target then return end

	--Check damage items in our inventory
	for i = ITEM_1, ITEM_7 do
		local itemInfo = self.Inventory[i]		
		if itemInfo.valid then
			local itemID = itemInfo.data.itemID
			if self.DamageItems[itemID] then
				local spellData = myHero:GetSpellData(i)
				if spellData.currentCd < .5 then
					if itemInfo.spell and self.LocalGeometry:IsInRange(myHero.pos, target.pos, itemInfo.spell.Range) then						
						if self.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and self.ActivatorMenu.Damage.Combo:Value() then
							Control.CastSpell(self.ItemHotkeys[i], target)
							break
						else
							local damage = self.LocalDamageManager:CalculateSkillDamage(myHero, target, itemInfo.spell)
							if damage >= target.health and self.ActivatorMenu.Damage.Killsteal:Value() then
								Control.CastSpell(self.ItemHotkeys[i], target)
								break
							end
						end
					end
				end
			end
		end
	end
end

Activator = __Activator()
_G.Activator = Activator
