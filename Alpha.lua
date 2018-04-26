if _G.Alpha then return end
_G.Alpha = 
{
	Geometry = nil,
	ObjectManager = nil,
	DamageManager = nil,
	ItemManager = nil,
	BuffManager = nil,
}

local LocalVector					= Vector;
local LocalCallbackAdd				= Callback.Add;
local LocalCallbackDel				= Callback.Del;
local LocalGameHeroCount 			= Game.HeroCount;
local LocalGameHero					= Game.Hero;
local LocalGameMinionCount 			= Game.MinionCount;
local LocalGameMinion					= Game.Minion;
local LocalGameParticleCount 		= Game.ParticleCount;
local LocalGameParticle				= Game.Particle;
local LocalGameMissileCount 		= Game.MissileCount;
local LocalGameMissile				= Game.Missile;
local LocalPairs 					= pairs;
local LocalType						= type;
local LocalInsert					= table.insert
local LocalSort						= table.sort

local LocalSqrt						= math.sqrt
local LocalAtan						= math.atan
local LocalAbs						= math.abs
local LocalHuge						= math.huge
local LocalPi						= math.pi
local LocalMax						= math.max
local LocalMin						= math.min
local LocalFloor					= math.floor


local DAMAGE_TYPE_TRUE				= 0
local DAMAGE_TYPE_PHYSICAL			= 1
local DAMAGE_TYPE_MAGICAL 			= 2


local BUFF_STUN						= 5
local BUFF_SILENCE					= 7
local BUFF_TAUNT					= 8
local BUFF_SLOW						= 10
local BUFF_ROOT						= 11
local BUFF_FEAR						= 21
local BUFF_CHARM					= 22
local BUFF_POISON					= 23
local BUFF_SURPRESS					= 24
local BUFF_BLIND					= 25
local BUFF_KNOCKUP					= 29
local BUFF_KNOCKBACK				= 30
local BUFF_DISARM					= 31


local Geometry = nil
local ObjectManager = nil
local DamageManager = nil
local ItemManager = nil
local BuffManager = nil

class "__Geometry"
function __Geometry:GetDistanceSqr(p1, p2)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		print("Undefined GetDistanceSqr target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return LocalHuge
	end
	return (p1.x - p2.x) *  (p1.x - p2.x) + ((p1.z or p1.y) - (p2.z or p2.y)) * ((p1.z or p1.y) - (p2.z or p2.y)) 
end

function __Geometry:GetDistance(p1, p2)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		print("Undefined GetDistance target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return LocalHuge
	end
	return LocalSqrt(self:GetDistanceSqr(p1, p2))
end

function __Geometry:IsPointInArc(source, origin, target, angle, range)
	local deltaAngle = LocalAbs(self:Angle(origin, target) - self:Angle(source, origin))
	if deltaAngle < angle and self:IsInRange(origin,target,range) then
		return true
	end
end

function __Geometry:Angle(A, B)
	local deltaPos = A - B
	local angle = LocalAtan(deltaPos.x, deltaPos.z) *  180 / LocalPi	
	if angle < 0 then angle = angle + 360 end
	return angle
end

function __Geometry:IsInRange(p1, p2, range)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		print("Undefined IsInRange target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return false
	end
	return (p1.x - p2.x) *  (p1.x - p2.x) + ((p1.z or p1.y) - (p2.z or p2.y)) * ((p1.z or p1.y) - (p2.z or p2.y)) < range * range 
end


class "__ObjectManager"
--Initialize the object manager
function __ObjectManager:__init()
	LocalCallbackAdd('Tick',  function() self:Tick() end)
	
	self.CachedMissiles = {}	
	self.OnMissileCreateCallbacks = {}
	self.OnMissileDestroyCallbacks = {}
	self.OnBlinkCallbacks = {}
	
	self.CachedParticles = {}
	self.OnParticleCreateCallbacks = {}
	self.OnParticleDestroyCallbacks = {}
	
	self.BlinkParticleLookupTable = 
	{
		"global_ss_flash_02.troy",
		"Lissandra_Base_E_Arrival.troy",
		"LeBlanc_Base_W_return_activation.troy",
		"Zed_Base_CloneSwap",
	}
	
	--Test callbacks to work with
	--self:OnParticleCreate(function(args) print("Particle: " .. args.name .. " Created") end)
	--self:OnParticleDestroy(function(args) print("Particle: " .. args.name .. " Destroyed") end)
end

--Register Missile Create Event
function __ObjectManager:OnMissileCreate(cb)
	LocalInsert(ObjectManager.OnMissileCreateCallbacks, cb)
end

--Trigger Missile Create Event
function __ObjectManager:MissileCreated(missile)
	for i = 1, #self.OnMissileCreateCallbacks do
		self.OnMissileCreateCallbacks[i](missile);
	end
end

--Register Missile Destroy Event
function __ObjectManager:OnMissileDestroy(cb)
	LocalInsert(ObjectManager.OnMissileDestroyCallbacks, cb)
end

--Trigger Missile Destroyed Event
function __ObjectManager:MissileDestroyed(missile)
	for i = 1, #self.OnMissileDestroyCallbacks do
		self.OnMissileDestroyCallbacks[i](missile);
	end
end

--Register Particle Create Event
function __ObjectManager:OnParticleCreate(cb)
	LocalInsert(ObjectManager.OnParticleCreateCallbacks, cb)
end

--Trigger Particle Created Event
function __ObjectManager:ParticleCreated(missile)
	for i = 1, #self.OnParticleCreateCallbacks do
		self.OnParticleCreateCallbacks[i](missile);
	end
end

--Register Particle Destroy Event
function __ObjectManager:OnParticleDestroy(cb)
	LocalInsert(ObjectManager.OnParticleDestroyCallbacks, cb)
end

--Trigger particle Destroyed Event
function __ObjectManager:ParticleDestroyed(particle)
	for i = 1, #self.OnParticleDestroyCallbacks do
		self.OnParticleDestroyCallbacks[i](particle);
	end
end

--RegisterOn Blink Event
function __ObjectManager:OnBlink(cb)
	if #self.OnBlinkCallbacks == 0 then		
		self:OnParticleCreate(function(particle) self:CheckIfBlinkParticle(particle) end)
	end
	LocalInsert(ObjectManager.OnBlinkCallbacks, cb)
end

--Trigger Blink Event
function __ObjectManager:Blinked(target)
	for i = 1, #self.OnBlinkCallbacks do
		self.OnBlinkCallbacks[i](target);
	end
end


--Search for changes in particle or missiles in game. trigger the appropriate events.
function __ObjectManager:Tick()
	--Cache Particles ONLY if a create or destroy event is registered: If not it's a waste of processing
	if #self.OnParticleCreateCallbacks > 0 or #self.OnParticleDestroyCallbacks > 0 then
		for _, particle in LocalPairs(self.CachedParticles) do
			if not particle or not particle.valid then
				if particle then					
					self:ParticleDestroyed(particle)
				end
				self.CachedParticles[_] = nil
			else
				particle.valid = false
			end
		end	
		
		for i = 1, LocalGameParticleCount() do 
			local particle = LocalGameParticle(i)
			if particle ~= nil and LocalType(particle) == "userdata" then
				if self.CachedParticles[particle.networkID] then
					self.CachedParticles[particle.networkID].valid = true
				else
					local particleData = { valid = true, pos = particle.pos, name = particle.name}
					self.CachedParticles[particle.networkID] =particleData
					self:ParticleCreated(particleData)
				end
			end
		end		
	end
	
	--Cache Missiles ONLY if a create or destroy event is registered: If not it's a waste of processing
	if #self.OnMissileCreateCallbacks > 0 or #self.OnMissileDestroyCallbacks > 0 then
		for _, missile in LocalPairs(self.CachedMissiles) do
			if not missile or not missile.data or not missile.valid then
				if missile and missile.data then
					self:MissileDestroyed(missile)
				end
				self.CachedMissiles[_] = nil
			else		
				missile.valid = false
			end
		end	
		
		for i = 1, LocalGameMissileCount() do 
			local missile = LocalGameMissile(i)
			if missile ~= nil and LocalType(missile) == "userdata" and missile.missileData then
				if self.CachedMissiles[missile.networkID] then
					self.CachedMissiles[missile.networkID].valid = true
				else
					--We need a direct reference to the missile so we can query its current position later. If not we'd have to calculate it using speed/start/end data
					local missileData = 
					{ 
						valid = true,
						name = missile.name,
						networkID = missile.networkID,
						data = missile
					}
					self.CachedMissiles[missile.networkID] =missileData
					self:MissileCreated(missileData)
				end
			end
		end
	end
end

function __ObjectManager:CheckIfBlinkParticle(particle)
	if table.contains(self.BlinkParticleLookupTable,particle.name) then
		local target = self:GetPlayerByPosition(particle.pos)
		if target then 
			self:Blinked(target)
		end
	end
end

--Lets us find a particle's owner because the particle and the player will have the same position (IE: Flash)
function __ObjectManager:GetPlayerByPosition(position)
	for i = 1, LocalGameHeroCount() do
		local target = LocalGameHero(i)
		if target and target.pos and Geometry:IsInRange(position, target.pos,50) then
			return target
		end
	end
end

function __ObjectManager:GetObjectByHandle(handle)
	for i = 1, LocalGameHeroCount() do
		local target = LocalGameHero(i)
		if target and target.handle == handle then
			return target
		end
	end
	for i = 1, LocalGameMinionCount() do
		local target = LocalGameMinion(i)
		if target and target.handle == handle then
			return target
		end
	end
end

class "__DamageManager"
--Credits LazyXerath for extra dmg reduction methods
function __DamageManager:__init()
	ObjectManager:OnMissileCreate(function(args) self:MissileCreated(args) end)
	ObjectManager:OnMissileDestroy(function(args) self:MissileDestroyed(args) end)
	
	self.OnIncomingCCCallbacks = {}	
	
	self.SiegeMinionList = {"Red_Minion_MechCannon", "Blue_Minion_MechCannon"}
	self.NormalMinionList = {"Red_Minion_Wizard", "Blue_Minion_Wizard", "Red_Minion_Basic", "Blue_Minion_Basic"}
	self.DamageReductionTable = 
	{
	  ["Braum"] = {buff = "BraumShieldRaise", amount = function(target) return 1 - ({0.3, 0.325, 0.35, 0.375, 0.4})[target:GetSpellData(_E).level] end},
	  ["Urgot"] = {buff = "urgotswapdef", amount = function(target) return 1 - ({0.3, 0.4, 0.5})[target:GetSpellData(_R).level] end},
	  ["Alistar"] = {buff = "Ferocious Howl", amount = function(target) return ({0.5, 0.4, 0.3})[target:GetSpellData(_R).level] end},
	  ["Galio"] = {buff = "GalioIdolOfDurand", amount = function(target) return 0.5 end},
	  ["Garen"] = {buff = "GarenW", amount = function(target) return 0.7 end},
	  ["Gragas"] = {buff = "GragasWSelf", amount = function(target) return ({0.1, 0.12, 0.14, 0.16, 0.18})[target:GetSpellData(_W).level] end},
	  ["Annie"] = {buff = "MoltenShield", amount = function(target) return 1 - ({0.16,0.22,0.28,0.34,0.4})[target:GetSpellData(_E).level] end},
	  ["Malzahar"] = {buff = "malzaharpassiveshield", amount = function(target) return 0.1 end}
	}
	
	self.EnemyHeroes = {}
	self.AlliedHeroes = {}
	for i = 1, Game.HeroCount() do
		local target = Game.Hero(i)
		if target.isAlly then
			self.AlliedHeroes[target.handle] = {}
		else
			self.EnemyHeroes[target.handle] = {}
		end
	end
	
	
	self.TargetedMissileTable = 
	{
		["Disintegrate"] = 
		{
			HeroName = "Annie", 
			SpellName = "Disintegrate",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL, 
			Damage = {80,115,150,185,220},
			APScaling = .8,
			Danger = 2,
		},
		["AkaliMota"] = 
		{
			HeroName = "Akali",
			SpellName = "Mark of the Assassin",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL, 
			Damage = {35,55,75,95,115},
			APScaling = .4,
			Danger = 1,	
		},
		["Frostbite"] = 
		{
			HeroName = "Anivia", 
			SpellName = "Frostbite",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL, 
			Damage = {50,75,100,125,150},
			APScaling = .5,
			BuffScaling = 2.0,
			BuffName = "aniviaiced",
			Danger = 3,
		},
		["CassiopeiaE"] = 
		{
			HeroName = "Cassiopeia",
			SpellName = "Twin Fang",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,
			SpecialDamage = 
			function (owner, target)
				return 48 + 4 * owner.levelData.lvl + 0.1 * owner.ap + (BuffManager:HasBuffType(target, 23) and ({10, 30, 50, 70, 90})[owner:GetSpellData(SpellSlot).level] + 0.60 * owner.ap or 0)
			end,
			Danger = 1,
		},
		["EliseHumanQ"] = 
		{
			HeroName = "Elise",
			SpellName = "Neurotoxin",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			Damage = {40,75,110,145,180},
			CurrentHealth = 0.04,
			CurrentHealthAPScaling = 0.03,
			Danger = 1,
		},
		["FiddlesticksDarkWind"] = 
		{
			HeroName = "FiddleSticks",
			SpellName = "Dark Wind",
			SpellSlot = _E,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			Damage = {65,85,105,125,145},
			APScaling = .45,
			Danger = 3,
			CC = BUFF_SILENCE,
		},
		["GangplankQProceed"] = 
		{
			HeroName = "Gangplank",
			SpellName = "Parrrley",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_PHYSICAL,			
			Damage = {20,45,70,95,120},
			ADScaling = 1.0,
			OnHitEffects = true,
			Danger = 2,
		},
		["SowTheWind"] = 
		{
			HeroName = "Janna",
			SpellName = "Zephyr",
			SpellSlot = _W,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			Damage = {55,100,145,190,235},
			APScaling = .5,
			--Actually has a movement speed scaling. There is no bonus movespeed option in the GOS api so for now leave it out
			--.15 lvl 1, .25 lvl 7, .35 lvl 13
			Danger = 2,
			CC = BUFF_SLOW,
		},
		["NullLance"] = 
		{
			HeroName = "Kassadin",
			SpellName = "Null Sphere",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			Damage = {65,95,125,155,185},
			APScaling = .7,
			Danger = 2,
		},
		["KatarinaQ"] = 
		{
			HeroName = "Katarina",
			SpellName = "Bouncing Blade",
			SpellSlot = _Q,
			DamageType = DAMAGE_TYPE_MAGICAL,			
			Damage = {75,105,135,165,195},
			APScaling = .3,
			Danger = 1,
		},
	}
	
	--Missile changes names after bounce. Just reference the existing one as it doesn't change in damage
	self.TargetedMissileTable["FiddleSticksDarkWindMissile"] = self.TargetedMissileTable["FiddlesticksDarkWind"]
end

function __DamageManager:MissileCreated(missile)
	--Handle targeted missiles only
	if missile.data.missileData.target and self.TargetedMissileTable[missile.name] then
		if self.TargetedMissileTable[missile.name] then
			self:OnTargetedMissileTable(missile)
		elseif LocalStringFind(missile.name, "BasicAttack") or LocalStringFind(missile.name, "CritAttack") then
			self:OnAutoAttackMissile(missile)			
		end
	end
end

function __DamageManager:OnAutoAttackMissile(missile)	
	local owner = ObjectManager:GetObjectByHandle(missile.data.missileData.owner)
	local target = ObjectManager:GetObjectByHandle(missile.data.missileData.target)
	if owner and target then
		--This should not be happening. it's a sign the script isn't populating the enemy/ally collections (delayed load needed IMO)
		if not targetCollection[target.handle] then print("Targeted missile cannot find target... " ..  target.charName) return end
		
		--This missile is already added - ignore it cause something went wrong. 
		if targetCollection[target.handle][missile.networkID] then print("Duplicate targeted missile creation: " .. missile.name) return end
		
		local damage = owner.totalDamage
		if LocalStringFind(missile.name, "CritAttack") then
			damage = damage * 1.5
		end
		damage = self:CalculatePhysicalDamage(owner, target, damage)	
		targetCollection[target.handle][missile.networkID] = 
		{
			Damage = damage,
			--0 Danger means auto attack. It's because we dont want to spell shield it.
			--Barrier/seraph/etc can still do it based on incoming dmg calculation though!
			Danger = 0,
		}
	end
end

function __DamageManager:OnTargetedMissileTable(missile)
	local owner = ObjectManager:GetObjectByHandle(missile.data.missileData.owner)
	local target = ObjectManager:GetObjectByHandle(missile.data.missileData.target)
	if owner and target then
		local skillInfo = self.TargetedMissileTable[missile.name]
		local targetCollection = self.EnemyHeroes
		if target.isAlly then
			targetCollection = self.AlliedHeroes
		end
					
		--This should not be happening. it's a sign the script isn't populating the enemy/ally collections (delayed load needed IMO)
		if not targetCollection[target.handle] then print("Targeted missile cannot find target... " ..  target.charName) return end
		
		--This missile is already added - ignore it cause something went wrong. 
		if targetCollection[target.handle][missile.networkID] then print("Duplicate targeted missile creation: " .. missile.name) return end
			
		local damage = 0
		if skillInfo.SpecialDamage then
			damage = skillInfo.SpecialDamage(owner, target)
		else
			--TODO: Make sure this handles nil values like a champ
			damage = skillInfo.Damage[owner:GetSpellData(skillInfo.SpellSlot).level] + 
			(skillInfo.APScaling and skillInfo.APScaling * owner.ap or 0) +
			(skillInfo.ADScaling and skillInfo.ADScaling * owner.totalDamage or 0) + 
			(skillInfo.CurrentHealth and target.health * skillInfo.CurrentHealth or 0) + 
			(skillInfo.CurrentHealthAPScaling and target.health * skillInfo.CurrentHealthAPScaling * owner.ap/100 or 0)
		end
					
		if skillInfo.DamageType == DAMAGE_TYPE_MAGICAL then
			damage = self:CalculateMagicDamage(owner, target, damage)
		elseif skillInfo.DamageType == DAMAGE_TYPE_PHYSICAL then
			damage = self:CalculatePhysicalDamage(owner, target, damage)				
		end
		
		if skillInfo.BuffName and BuffManager:HasBuff(target, skillInfo.BuffName) then
			damage = damage * skillInfo.BuffScaling
		end
		
		local damageRecord = 
		{
			Damage = damage,
			Danger = skillInfo.Danger or 1,
			CC = skillInfo.CC or false,
			Name = missile.name,
		}
		targetCollection[target.handle][missile.networkID] = damageRecord
		
		print(damage)
		--Trigger any registered OnCC callbacks. Send them the target, damage and type of cc so we can choose our actions
		if damageRecord.CC and #self.OnIncomingCCCallbacks then
			IncomingCC(target, damage, damageRecord.CC)
		end
	end
end

--Register Incoming CC Event
function __DamageManager:OnIncomingCC(cb)
	LocalInsert(_G.Alpha.ObjectManager.OnIncomingCCCallbacks, cb)
end

--Trigger Incoming CC Event
function __DamageManager:IncomingCC(target, damage, ccType)
	for i = 1, #self.OnIncomingCCCallbacks do
		self.OnIncomingCCCallbacks[i](damageRecord);
	end
end

function __DamageManager:MissileDestroyed(missile)
	for _, dmgCollection in LocalPairs(self.AlliedHeroes) do
		if dmgCollection[missile.networkID] then
			dmgCollection[missile.networkID] = nil
		end
	end
	for _, dmgCollection in LocalPairs(self.EnemyHeroes) do
		if dmgCollection[missile.networkID] then
			dmgCollection[missile.networkID] = nil
		end
	end
end

function __DamageManager:CalculatePhysicalDamage(source, target, damage)	
	local ArmorPenPercent = source.armorPenPercent
	local ArmorPenFlat = (0.4 + target.levelData.lvl / 30) * source.armorPen
	local BonusArmorPen = source.bonusArmorPenPercent

	if source.type == Obj_AI_Minion then
		ArmorPenPercent = 1
		ArmorPenFlat = 0
		BonusArmorPen = 1
	elseif source.type == Obj_AI_Turret then
		ArmorPenFlat = 0
		BonusArmorPen = 1
		if source.charName:find("3") or source.charName:find("4") then
		  ArmorPenPercent = 0.25
		else
		  ArmorPenPercent = 0.7
		end
	end

	if source.type == Obj_AI_Turret then
		if target.type == Obj_AI_Minion then
		  damage = amount * 1.25
		  if string.ends(target.charName, "MinionSiege") then
			damage = damage * 0.7
		  end
		  return damage
		end
	end

	local armor = target.armor
	local bonusArmor = target.bonusArmor
	local value = 100 / (100 + (armor * ArmorPenPercent) - (bonusArmor * (1 - BonusArmorPen)) - ArmorPenFlat)

	if armor < 0 then
		value = 2 - 100 / (100 - armor)
	elseif (armor * ArmorPenPercent) - (bonusArmor * (1 - BonusArmorPen)) - ArmorPenFlat < 0 then
		value = 1
	end
	return LocalMax(0, LocalFloor(self:DamageReductionMod(source, target, self:PassivePercentMod(source, target, value) * damage, 1)))
end

function __DamageManager:CalculateMagicDamage(source, target, damage)
	local targetMR = target.magicResist - target.magicResist * source.magicPenPercent - source.magicPen	
	local damageReduction = 100 / ( 100 + targetMR)
	if targetMR < 0 then
		damageReduction = 2 - (100 / (100 - targetMR))
	end	
	return LocalMax(0, LocalFloor(self:DamageReductionMod(source, target, self:PassivePercentMod(source, target, damageReduction) * damage, 2)))
end

function __DamageManager:DamageReductionMod(source,target,amount,DamageType)
  if source.type == Obj_AI_Hero then
    if BuffManager:HasBuff(source, "Exhaust") then
      amount = amount * 0.6
    end
  end

  if target.type == Obj_AI_Hero then
    for i = 0, target.buffCount do
      if target:GetBuff(i).count > 0 then
        local buff = target:GetBuff(i)
        if buff.name == "MasteryWardenOfTheDawn" then
          amount = amount * (1 - (0.06 * buff.count))
        end
    
        if self.DamageReductionTable[target.charName] then
          if buff.name == self.DamageReductionTable[target.charName].buff and (not self.DamageReductionTable[target.charName].damagetype or self.DamageReductionTable[target.charName].damagetype == DamageType) then
            amount = amount * self.DamageReductionTable[target.charName].amount(target)
          end
        end

        if target.charName == "Maokai" and source.type ~= Obj_AI_Turret then
          if buff.name == "MaokaiDrainDefense" then
            amount = amount * 0.8
          end
        end

        if target.charName == "MasterYi" then
          if buff.name == "Meditate" then
            amount = amount - amount * ({0.5, 0.55, 0.6, 0.65, 0.7})[target:GetSpellData(_W).level] / (source.type == Obj_AI_Turret and 2 or 1)
          end
        end
      end
    end

    if ItemManager:GetItemSlot(target, 1054) > 0 then
      amount = amount - 8
    end

    if target.charName == "Kassadin" and DamageType == 2 then
      amount = amount * 0.85
    end
  end

  return amount
end

function __DamageManager:PassivePercentMod(source, target, amount, damageType)
  if source.type == Obj_AI_Turret then
    if table.contains(self.SiegeMinionList, target.charName) then
      amount = amount * 0.7
    elseif table.contains(self.NormalMinionList, target.charName) then
      amount = amount * 1.14285714285714
    end
  end
  if source.type == Obj_AI_Hero then 
    if target.type == Obj_AI_Hero then
      if (ItemManager:GetItemSlot(source, 3036) > 0 or ItemManager:GetItemSlot(source, 3034) > 0) and source.maxHealth < target.maxHealth and damageType == 1 then
        amount = amount * (1 + LocalMin(target.maxHealth - source.maxHealth, 500) / 50 * (ItemManager:GetItemSlot(source, 3036) > 0 and 0.015 or 0.01))
      end
    end
  end
  return amount
end

class "__ItemManager"
function __ItemManager:GetItemSlot(unit, id)
	for i = ITEM_1, ITEM_7 do
		if unit:GetItemData(i).itemID == id then
			return i
		end
	end
	return 0
end

class "__BuffManager"
function __BuffManager:HasBuff(target, buffName, minimumDuration)
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
function __BuffManager:HasBuffType(target, buffType, minimumDuration)
	local duration = minimumDuration
	if not minimumDuration then
		duration = 0
	end
	local durationRemaining
	for i = 1, target.buffCount do 
		local buff = target:GetBuff(i)
		if buff.duration > duration and buff.type == buffType then
			durationRemaining = buff.duration
			return true, durationRemaining
		end
	end
end

--Initialization
Geometry = __Geometry()
_G.Alpha.Geometry = Geometry

ObjectManager = __ObjectManager()
_G.Alpha.ObjectManager = ObjectManager

DamageManager = __DamageManager()
_G.Alpha.DamageManager = DamageManager

ItemManager = __ItemManager()
_G.Alpha.ItemManager = ItemManager

BuffManager = __BuffManager()
_G.Alpha.BuffManager = BuffManager

ObjectManager:OnBlink(function(args) print(args.charName .. " used a blink!") end)
--_G.Alpha.ObjectManager:OnMissileCreate(function(args) print("Missile: " .. args.data.name .. " Created") end)
--_G.Alpha.ObjectManager:OnMissileDestroy(function(args) print("Missile: " .. args.data.name .. " Destroyed") end)