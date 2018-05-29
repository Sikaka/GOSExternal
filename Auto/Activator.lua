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
	self.ActivatorMenu.Cleanse:MenuElement({id="Combo", name="Only Use In Combo", value = true})
	
	
	self.ActivatorMenu:MenuElement({id = "Damage", name = "Damage", type = MENU})
	self.ActivatorMenu.Damage:MenuElement({id = "AAReset", name = "Tiamat/Hydra Usage", type = MENU})
	self.ActivatorMenu.Damage.AAReset:MenuElement({id="Killsteal", name="Killsteal", value = true})
	self.ActivatorMenu.Damage.AAReset:MenuElement({id="Combo", name="AA Reset (Combo)", value = true})
	
	self.ActivatorMenu.Damage:MenuElement({id = "Ranged", name = "BOTRK/Gunblade Usage", type = MENU})
	self.ActivatorMenu.Damage.Ranged:MenuElement({id="Killsteal", name = "Killsteal", value = true})
	self.ActivatorMenu.Damage.Ranged:MenuElement({id="Radius", name= "Peel Enemies [Combo]", value = 300, min = 50, max = 600, step = 25})
		
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
	self.ItemFunctions = {
		[3077] = {Name = "Tiamat", OnAttack = self.AAResetItem },
		[3074] = {Name = "Ravenous Hydra", OnAttack = self.AAResetItem },
		[3748] = {Name = "Titanic Hydra", OnAttack = self.AAResetItem },
		
		[3153] = {Name = "Blade of the Ruined King", OnTick = self.RangedItem},
		[3144] = {Name = "Bilgewater Cutlass", OnTick = self.RangedItem},
		[3146] = {Name = "Hextech Gunblade", OnTick = self.RangedItem},		
		
		[3190] = {
			Name = "Locket of the Iron Solari", 
			OnMenu = function()
				local m = self.ActivatorMenu:MenuElement({id = 3190, name = "Locket of the Iron Solari", type = MENU})
				m:MenuElement{id = "Auto", name = "Auto Cast", value = true}
				m:MenuElement{id = "Count", name = "Minimum Ally Count", value = 2, min = 1, max = 5, step = 1}
				m:MenuElement{id = "Health", name = "Health %", value = 50, min = 1, max = 100, step = 1}
				m:MenuElement{id = "Damage", name = "Damage %", value = 10, min = 1, max = 100, step = 1}
			end,
			OnTick = function(slot)
				local realSlot = slot.Slot
				local spellData = myHero:GetSpellData(realSlot)
				if spellData.currentCd < .5 and (Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] or Activator.ActivatorMenu[3190].Auto:Value()) then
					local targetCount = 0
					local targetCountRequired = Activator.ActivatorMenu[3190].Count:Value() 
					for i = 1, LocalGameHeroCount() do
						local hero = LocalGameHero(i)
						if CanTargetAlly(hero) and LocalGeometry:IsInRange(myHero.pos, hero.pos, spellData.range) then
							if CurrentPctLife(hero) <= Activator.ActivatorMenu[3190].Health:Value() then
								local incomingDamage = LocalDamageManager:RecordedIncomingDamage(hero)
								if incomingDamage / hero.health * 100 >= Activator.ActivatorMenu[3190].Damage:Value() then
									targetCount = targetCount + 1
									if targetCount >= targetCountRequired then break end
								end
							end
						end
					end
					if targetCount >= targetCountRequired then
						Control.CastSpell(Activator.ItemHotkeys[realSlot])
					end
				end
			end
		},
		[3140] = {	Name = "Quicksilver Sash",	OnTick = self.CleanseSelf	},
		[3139] = {	Name = "Mercurial Scimittar",	OnTick = self.CleanseSelf	},
		[3222] = {	Name = "Mikael's Crucible",	
		OnMenu = function()
			local m = self.ActivatorMenu:MenuElement({id = 3222, name = "Mikael's Crucible", type = MENU})			
			
			m:MenuElement({id = "CC", name = "CC Settings", type = MENU})	
			for _, cc in pairs(self.CCInfo) do
				m.CC:MenuElement({id = cc.Type, name = cc.Name, value = cc.Value})
			end
			
			m:MenuElement({id = "Targets", name = "Target Settings", type = MENU})
			for i = 1, LocalGameHeroCount() do
				local hero = LocalGameHero(i)
				if hero.isAlly then
					m.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true })
				end
			end
			m:MenuElement({id="Combo", name="Use Only In Combo", value = false})
		end,
		OnTick = self.CleanseTarget	},		
	}
	
	
	self.ItemAttackCallbacks = {}
	self.ItemTickCallbacks = {}
	
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
	}
	
	DelayAction(function () self.LoadCompleted() end, math.max(2,30 - Game.Timer()))
end

function __Activator:CanTarget(target)
	return target and target.pos and target.isEnemy and target.alive and target.health > 0 and target.visible and target.isTargetable
end

function __Activator:CanTargetAlly(target)
	return target and target.pos and target.isAlly and target.alive and target.health > 0 and target.visible and target.isTargetable
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
	if self.ItemFunctions[item.itemID] then
		if self.ItemFunctions[item.itemID].OnMenu then
			self.ItemFunctions[item.itemID]:OnMenu()
		end
		
		if self.ItemFunctions[item.itemID].OnAttack then
			table.insert(self.ItemAttackCallbacks, { Tick = self.ItemFunctions[item.itemID].OnAttack, Item = item, Slot = slot})
		elseif self.ItemFunctions[item.itemID].OnTick then
			table.insert(self.ItemTickCallbacks, {Tick = self.ItemFunctions[item.itemID].OnTick, Item = item, Slot = slot})
		end
	end
end

function __Activator:OnSellItem(item, slot)
	if Activator.ActivatorMenu[item.itemID] then
		Activator.ActivatorMenu[item.itemID]:Remove()
	end
	for _, cb in pairs(self.ItemAttackCallbacks) do		
		if cb.Item.itemID == item.itemID then
			table.remove(self.ItemAttackCallbacks, _)
		end
	end
	for _, cb in pairs(self.ItemTickCallbacks) do		
		if cb.Item.itemID == item.itemID then
			table.remove(self.ItemTickCallbacks, _)
		end
	end
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
	
	for i = 1, #self.ItemTickCallbacks do
		self.ItemTickCallbacks[i]:Tick(self.ItemTickCallbacks[i].Slot)
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
	if not myHero or not myHero.levelData then return end
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

function __Activator:CleanseSelf(slot)
	--Check if we want to activate only in combo or not	
	if Activator.ActivatorMenu.Cleanse.Combo:Value() and not Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then return end
	
	print("Cleanse test")
	local spellData = myHero:GetSpellData(slot)
	if spellData.currentCd < .5 then	
		for i = 0, myHero.buffCount do
			local buff = myHero:GetBuff(i)
			if buff.duration > 0 and Activator.ActivatorMenu.Cleanse.CC[buff.type] and Activator.ActivatorMenu.Cleanse.CC[buff.type]:Value() then
				Control.CastSpell(Activator.ItemHotkeys[slot])
				print("casting Cleanse")
				return
			end
		end
	end
end

function __Activator:CleanseTarget(slot)
	--Check if we want to activate only in combo or not	
	if Activator.ActivatorMenu[3222].Combo:Value() and not Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then return end
	
	local spellData = myHero:GetSpellData(slot)
	if spellData.currentCd < .5 then	
		for h = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(h)
			if CanTargetAlly(hero) and LocalGeometry:IsInRange(myHero.pos, hero.pos, spellData.range) and Activator.ActivatorMenu[3222].Targets[hero.networkID] and Activator.ActivatorMenu[3222].Targets[hero.networkID]:Value() then
				for i = 0, myHero.buffCount do
					local buff = myHero:GetBuff(i)
					if buff.duration > 0 and Activator.ActivatorMenu[3222].CC[buff.type] and Activator.ActivatorMenu[3222].CC[buff.type]:Value() then
						Control.CastSpell(Activator.ItemHotkeys[slot])
						return
					end
				end
			end
		end
	end
end


function __Activator:RangedItem(slot)
	local spellData = myHero:GetSpellData(slot)
	if spellData.currentCd < .5 then
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if CanTarget(hero) and LocalGeometry:IsInRange(myHero.pos, hero.pos, spellData.range) then
				if Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and LocalGeometry:IsInRange(myHero.pos, hero.pos, Activator.ActivatorMenu.Damage.Ranged.Radius:Value()) then
					Control.CastSpell(Activator.ItemHotkeys[slot], hero)
				elseif Activator.ActivatorMenu.Damage.Ranged.Killsteal:Value() then
					local damage = Activator.LocalDamageManager:CalculateSkillDamage(myHero, hero, spellData.name)
					if damage >= hero.health then
						Control.CastSpell(Activator.ItemHotkeys[slot], hero)				
					end
				end
			end
		end
	end
end

function __Activator:AAResetItem(target, itemInfo, slot)
	local spellData = myHero:GetSpellData(slot)
	if spellData.currentCd < .5 then
		if spellData.name and Activator.LocalGeometry:IsInRange(myHero.pos, target.pos, spellData.range) then						
			if Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and Activator.ActivatorMenu.Damage.AAReset.Combo:Value() then
				Control.CastSpell(Activator.ItemHotkeys[slot])						
			else
				local damage = Activator.LocalDamageManager:CalculateSkillDamage(myHero, target, spellData.name)
				if damage >= target.health and Activator.ActivatorMenu.Damage.AAReset.Killsteal:Value() then
					Control.CastSpell(Activator.ItemHotkeys[slot])							
				end
			end
		end
	end
end

function __Activator:OnPostAttack()
	--Check for E AA reset
	if not myHero.activeSpell.target then return end
	local target = LocalObjectManager:GetHeroByHandle(myHero.activeSpell.target)
	if not target then return end

	for i = 1, #self.ItemAttackCallbacks do
		local cb = self.ItemAttackCallbacks[i]
		cb:Tick(target, cb.Item, cb.Slot)
	end	
end

Activator = __Activator()
_G.Activator = Activator
