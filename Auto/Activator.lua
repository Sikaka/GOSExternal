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
	local MapID = Game.mapID
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
				m:MenuElement{id = "Radius", name = "Peel Radius", value = 300, min = 100, max = 700, step = 50}
				m:MenuElement{id = "Combo", name = "Use only in Combo", value = true}
				m:MenuElement{id = "Active", name = "Enable", value = true}
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
		["SummonerBoost"] = { 
			Tick = self.Cleanse,
			Initialize = function () end
		},		
	}
	
	self.ItemFunctions = {
		[2010] = {Name = "Biscuit of Rejuvenation", OnTick = function(slot) self:Potion(slot, "ItemMiniRegenPotion") end },
		[2003] = {Name = "Health Potion", OnTick = function(slot) self:Potion(slot, "RegenerationPotion") end },
		[2031] = {Name = "Refillable Potion", OnTick = function(slot) self:Potion(slot, "ItemCrystalFlask") end },
		[2032] = {Name = "Hunter's Potion", OnTick = function(slot) self:Potion(slot, "ItemCrystalFlaskJungle") end },
		[2033] = {Name = "Corrupting Potion", OnTick = function(slot) self:Potion(slot, "ItemDarkCrystalFlask") end },
		
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
						if CanTargetAlly(hero) and Activator.LocalGeometry:IsInRange(myHero.pos, hero.pos, spellData.range) then
							if CurrentPctLife(hero) <= Activator.ActivatorMenu[3190].Health:Value() then
								local incomingDamage = Activator.LocalDamageManager:RecordedIncomingDamage(hero)
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
		
		[3040] = {Name = "Seraphs Embrace", 
			OnMenu = function()
				local m = self.ActivatorMenu:MenuElement({id = 3040, name = "Seraphs Embrace", type = MENU})
				m:MenuElement{id = "Auto", name = "Cast Without Combo", value = true}
				m:MenuElement{id = "Health", name = "Health %", value = 30, min = 1, max = 100, step = 1}
			end,
			OnTick = function(slot)
				local realSlot = slot.Slot
				local spellData = myHero:GetSpellData(realSlot)
				if spellData.currentCd < .5 and (Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] or Activator.ActivatorMenu[3040].Auto:Value()) then
					local incomingDamage = Activator.LocalDamageManager:RecordedIncomingDamage(myHero)
					local remainingLifePct = (myHero.health - incomingDamage) / myHero.maxHealth * 100
					if remainingLifePct <= Activator.ActivatorMenu[3040].Health:Value() and incomingDamage / myHero.health  * 100 > 25 then
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
		
		[3905] = {	Name = "Twin Shadows",
		OnMenu = function ()
			local m = self.ActivatorMenu:MenuElement({id = 3905, name = "Twin Shadows", type = MENU})
			m:MenuElement({id = "Range", name = "Max Cast Distance", value = 2500, min = 500, max = 4000, step = 100})
			m:MenuElement({id = "Radius", name = "Minimum Enemy Distance", value = 500, min = 100, max = 2000, step = 50})
		end,
		OnTick = function(slot)
			local realSlot = slot.Slot
			local spellData = myHero:GetSpellData(realSlot)
			if spellData.currentCd < .5 and Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
				for i = 1, LocalGameHeroCount() do
					local hero = LocalGameHero(i)
					if CanTarget(hero) and Activator.LocalGeometry:IsInRange(myHero.pos, hero.pos, Activator.ActivatorMenu[3905].Range:Value()) and Activator:ClosestAlly(hero.pos, 90000) <= Activator.ActivatorMenu[3905].Radius:Value() then						
						Control.CastSpell(Activator.ItemHotkeys[realSlot])
					end
				end
			end
		end
		},
		[3107] = {	Name = "Redemption",
		OnMenu = function ()
			local m = self.ActivatorMenu:MenuElement({id = 3107, name = "Redemption", type = MENU})
			
			m:MenuElement({id = "Targets", name = "Target Settings", type = MENU})
			for i = 1, LocalGameHeroCount() do
				local hero = LocalGameHero(i)
				if hero.isAlly then
					m.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = 50, min = 0, max = 100, step = 1 })
				end
			end
			
			m:MenuElement({id = "Count", name = "Minimum Target Count", value = 3, min = 1, max = 5, step = 1})
			m:MenuElement({id = "Auto", name = "Cast Outside Combo Mode", value = true})
		end,
		OnTick = function(slot)
			local realSlot = slot.Slot
			local spellData = myHero:GetSpellData(realSlot)			
			if spellData.currentCd < .5 and (Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] or Activator.ActivatorMenu[3107].Auto:Value())then
				for i = 1, LocalGameHeroCount() do
					local hero = LocalGameHero(i)
					if CanTargetAlly(hero) and Activator.LocalGeometry:IsInRange(myHero.pos, hero.pos, 5500) and Activator.ActivatorMenu[3107].Targets[hero.networkID] then
						--Count total targets who can be hit after the delay
						local incomingDamage = Activator.LocalDamageManager:RecordedIncomingDamage(hero)
						local remainingLifePct = (hero.health - incomingDamage) / hero.maxHealth * 100		
						local origin = Activator.LocalGeometry:PredictUnitPosition(hero, 2.5)
						if Activator.LocalGeometry:IsInRange(myHero.pos, origin, 5500) and Activator.ActivatorMenu[3107].Targets[hero.networkID]:Value() >= remainingLifePct then
							--Count targets inside the radius
							local targetCount = Activator:EnemyCount(origin, 600,2.5) + Activator:AllyCount(origin, 600,2.5)
							if targetCount >= Activator.ActivatorMenu[3107].Count:Value() then
								--Need to cast it to mini map instead
								Activator:CastSpell(Activator.ItemHotkeys[realSlot], origin)
							end
						end
					end
				end
			end
		end
		},
	}
	
	
	self.ItemAttackCallbacks = {}
	self.ItemTickCallbacks = {}
	
	DelayAction(function () self.LoadCompleted() end, 1)
end

function __Activator:EnemyCount(origin, range, delay)
	local count = 0
	for i  = 1,LocalGameHeroCount(i) do
		local enemy = LocalGameHero(i)
		local enemyPos = enemy.pos
		if delay then
			enemyPos= Activator.LocalGeometry:PredictUnitPosition(enemy, delay)
		end
		if enemy and Activator:CanTarget(enemy) and Activator.LocalGeometry:IsInRange(origin, enemyPos, range) then
			count = count + 1
		end			
	end
	return count
end

function __Activator:AllyCount(origin, range, delay)
	local count = 0
	for i  = 1,LocalGameHeroCount(i) do
		local ally = LocalGameHero(i)
		local allyPos = ally.pos
		if delay then
			allyPos= Activator.LocalGeometry:PredictUnitPosition(ally, delay)
		end
		if ally and Activator:CanTargetAlly(ally) and Activator.LocalGeometry:IsInRange(origin, allyPos, range) then
			count = count + 1
		end			
	end
	return count
end
function __Activator:ClosestAlly(origin, range)
	local distance = range
	for i = 1,LocalGameHeroCount()  do
		local hero = LocalGameHero(i)
		if hero and Activator:CanTargetAlly(hero) then
			local d =  Activator.LocalGeometry:GetDistance(origin, hero.pos)
			if d < range and d < distance then
				distance = d
			end
		end
	end
	if distance < range then
		return distance
	end
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

	if not _G.Alpha or not _G.Alpha.DamageManager or not _G.Alpha.Geometry then
		DelayAction(function () self.LoadCompleted() end, 1)
		return
	end
	
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
	else
		--print("Unhandled item: " .. item.itemID)
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
	if not myHero.alive then return end
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
		local itemData = myHero:GetItemData(i)		
		if self.Inventory[i].valid and (itemData.itemID == 0 or self.Inventory[i].data.itemID ~= itemData.itemID) then			
			self:OnSellItem(self.Inventory[i].data, i)
			self.Inventory[i].valid = false
			self.Inventory[i].data = nil
		end
		
		--New item in the slot
		if not self.Inventory[i].valid and myHero:GetItemData(i).itemID ~= 0 then
			self.Inventory[i].valid = true
			self.Inventory[i].data = myHero:GetItemData(i)
			self.Inventory[i].spell = Activator.LocalDamageManager.MasterSkillLookupTable[myHero:GetItemData(i).itemID]
			self:OnBuyItem(myHero:GetItemData(i), i)
		end
	end
end


function __Activator:Exhaust(spellSlot, hotkey)
	if self.ActivatorMenu.Summoners.Exhaust.Active:Value() and (self.ActivatorMenu.Summoners.Exhaust.Combo:Value() or Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]) then
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if CanTarget(hero) and Activator.LocalGeometry:IsInRange(myHero.pos, hero.pos, 650) then
				if Activator:ClosestAlly(hero.pos, 90000) <= self.ActivatorMenu.Summoners.Exhaust.Radius:Value() then
					Activator:CastSpell(hotkey, hero)
					return
				end
			end
		end
	end
end

function __Activator:Ignite(spellSlot, hotkey)
	if not myHero or not myHero.levelData then return end
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if CanTarget(hero) and Activator.LocalGeometry:IsInRange(myHero.pos, hero.pos, 600) then	
			local remainingHealth = hero.health - Activator.LocalDamageManager:RecordedIncomingDamage(hero)
			if not remainingHealth then
				remainingHealth = hero.health
			end
			if remainingHealth > 0 then
				if remainingHealth < ({80,105,130,155,180,205,230,255,280,305,330,355,380,405,430,455,480,505})[myHero.levelData.lvl] and Activator.ActivatorMenu.Summoners.Ignite.Killsteal:Value() then	
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
		local incomingDamage = Activator.LocalDamageManager:RecordedIncomingDamage(myHero)
		local remainingLifePct = (myHero.health - incomingDamage) / myHero.maxHealth * 100
		if remainingLifePct <= Activator.ActivatorMenu.Summoners.Barrier.Health:Value() and incomingDamage / myHero.health  * 100 > 25 then
			Control.CastSpell(hotkey)
		end
	end
end

function __Activator:Heal(spellSlot, hotkey)
	if myHero.alive and not Activator.ActivatorMenu.Summoners.Heal.Combo:Value() or Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then	
		local incomingDamage = Activator.LocalDamageManager:RecordedIncomingDamage(myHero)
		local remainingLifePct = (myHero.health - incomingDamage) / myHero.maxHealth * 100
		if remainingLifePct <= Activator.ActivatorMenu.Summoners.Heal.Health:Value() and incomingDamage / myHero.health  * 100 > 25 then
			Control.CastSpell(hotkey)
		end
	end
end

function __Activator:Cleanse(spellSlot, hotkey)
	if Activator.ActivatorMenu.Cleanse.Combo:Value() and not Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then return end	
	local spellData = myHero:GetSpellData(hotkey)
	if spellData.currentCd < .5 then	
		for i = 0, myHero.buffCount do
			local buff = myHero:GetBuff(i)
			if buff.duration > 0 and Activator.ActivatorMenu.Cleanse.CC[buff.type] and Activator.ActivatorMenu.Cleanse.CC[buff.type]:Value() then
				Control.CastSpell(hotkey)
				return
			end
		end
	end
end

function __Activator:CleanseSelf(slot)
	--Check if we want to activate only in combo or not	
	if Activator.ActivatorMenu.Cleanse.Combo:Value() and not Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then return end	
	local spellData = myHero:GetSpellData(slot)
	if spellData.currentCd < .5 then	
		for i = 0, myHero.buffCount do
			local buff = myHero:GetBuff(i)
			if buff.duration > 0 and Activator.ActivatorMenu.Cleanse.CC[buff.type] and Activator.ActivatorMenu.Cleanse.CC[buff.type]:Value() then
				Control.CastSpell(Activator.ItemHotkeys[slot])
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
			if CanTargetAlly(hero) and Activator.LocalGeometry:IsInRange(myHero.pos, hero.pos, spellData.range) and Activator.ActivatorMenu[3222].Targets[hero.networkID] and Activator.ActivatorMenu[3222].Targets[hero.networkID]:Value() then
				for i = 0, hero.buffCount do
					local buff = hero:GetBuff(i)
					if buff.duration > 0 and Activator.ActivatorMenu[3222].CC[buff.type] and Activator.ActivatorMenu[3222].CC[buff.type]:Value() then
						Control.CastSpell(Activator.ItemHotkeys[slot],hero)
						return
					end
				end
			end
		end
	end
end
function __Activator:HasBuff(target, buffName, minimumDuration)

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
function __Activator:Potion(slot, buff)
	if Activator:HasBuff(myHero, buff) or Activator:HasBuff(myHero, "recall") or Activator.LocalGeometry:GetDistance(myHero.pos,Activator.Base) < 1000  then return end
	if Activator.ActivatorMenu.Healing.Auto:Value() and CurrentPctLife(myHero) <= Activator.ActivatorMenu.Healing.Life:Value() then
		Control.CastSpell(Activator.ItemHotkeys[slot.Slot])
	end
end

function __Activator:RangedItem(slot)
	local spellData = myHero:GetSpellData(slot)
	if spellData.currentCd < .5 then
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if CanTarget(hero) and Activator.LocalGeometry:IsInRange(myHero.pos, hero.pos, spellData.range) then
				if Activator.LocalOrbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and Activator.LocalGeometry:IsInRange(myHero.pos, hero.pos, Activator.ActivatorMenu.Damage.Ranged.Radius:Value()) then
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
	local target = Activator.LocalObjectManager:GetHeroByHandle(myHero.activeSpell.target)
	if not target then return end

	for i = 1, #self.ItemAttackCallbacks do
		local cb = self.ItemAttackCallbacks[i]
		cb:Tick(target, cb.Item, cb.Slot)
	end	
end

Activator = __Activator()
_G.Activator = Activator
