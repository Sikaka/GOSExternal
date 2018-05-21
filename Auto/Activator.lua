if _G.Activator then return end
class "__Activator"


function __Activator:__init()


	print("Loaded Auto3.0: Activator")
	self.ActivatorMenu = MenuElement({type = MENU, id = "Activator", name = "[Activator]"})
	self.ActivatorMenu:MenuElement({id = "Healing", name = "Healing", type = MENU})
	self.ActivatorMenu.Healing:MenuElement({id = "Auto", name = "Use Healing Items", value = true, toggle = true})
	self.ActivatorMenu.Healing:MenuElement({id = "Life", name = "% Life", value = 50, min = 1, max = 100, step = 1})
	
	self.ActivatorMenu:MenuElement({id = "Damage", name = "Damage", type = MENU})
	
	
	self.Inventory = {}	
	--Initialize empty collection so we can read existing items at start
	for i = ITEM_1, ITEM_7 do
		self.Inventory[i] = {valid = false, data = nil}		
	end
	
	self.ItemHotkeys = {
		[ITEM_1] = HK_ITEM_1,
		[ITEM_2] = HK_ITEM_2,
		[ITEM_3] = HK_ITEM_3,
		[ITEM_4] = HK_ITEM_4,
		[ITEM_5] = HK_ITEM_5,
		[ITEM_6] = HK_ITEM_6,
		[ITEM_7] = HK_ITEM_7,
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
		[3077] = {name = "Tiamat", id = 3077, range = 300},
		[3074] = {name = "Ravenous Hydra", id = 3074, range = 300},
		[3748] = {name = "Titanic Hydra", id = 3748, range = 300},
		[3153] = {name = "Blade of the Ruined King", id = 3153, range = 600},
		[3144] = {name = "Bilgewater Cutlass", id = 3144, range = 600},
		[3152] = {nam = "Hextech Protobelt-01", id = 3152, range = 800},
		[3030] = {name = "Hextech GLP-800", id = 3030, range = 800},
		[3146] = {name = "Hextech Gunblade", id = 3146, range = 700}
	}
	
	
	DelayAction(function()
		self.LocalGeometry = _G.Alpha.Geometry
		self.LocalDamageManager = _G.Alpha.DamageManager
		_G.SDK.Orbwalker:OnPostAttack(function(args) self:OnPostAttack() end)		
		Callback.Add("Tick", function () self:Tick() end)
		
	end, 1)
end

function __Activator:OnBuyItem(item, slot)
	local itemID = item.itemID
	if self.DamageItems[itemID] and not self.ActivatorMenu.Damage[itemID] then
		local itemMenu = self.ActivatorMenu.Damage:MenuElement({id = itemID, name = self.DamageItems[item.itemID].name, type = MENU})
		
		--Auto use it to killsteal targets in range
		self.ActivatorMenu.Damage[itemID]:MenuElement({id = "Killsteal", name = "Killsteal", value = true})
		
		--Use it after an auto attack for smooth resets
		self.ActivatorMenu.Damage[itemID]:MenuElement({id = "Auto", name = "AA Reset (Combo)", value = false})
	end
end

function __Activator:OnSellItem(item, slot)
	if self.ActivatorMenu.Damage[item.itemID] then
		self.ActivatorMenu.Damage[item.itemID]:Remove()
		self.ActivatorMenu.Damage[item.itemID] = nil
	end
end

function __Activator:Tick()
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
					if self.ActivatorMenu.Damage[itemID] and itemInfo.spell and self.LocalGeometry:IsInRange(myHero.pos, target.pos, itemInfo.spell.Range) then						
						if self.ActivatorMenu.Damage[itemID].Auto:Value() then
							Control.CastSpell(self.ItemHotkeys[i], target)
							break
						else
							local damage = self.LocalDamageManager:CalculateSkillDamage(myHero, target, itemInfo.spell)
							print(damage)
							if damage >= target.health and self.ActivatorMenu.Damage[itemID].Killsteal:Value() then
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
