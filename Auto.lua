local Heroes = {"Nami","Brand"}
if not table.contains(Heroes, myHero.charName) then return end

local Scriptname,Version,Author,LVersion = "[Auto]","v1.0","Sikaka","0.01"


Callback.Add("Load",function() _G[myHero.charName]() end)
 	

function CurrentPctLife(entity)
	local pctLife =  entity.health/entity.maxHealth  * 100
	return pctLife
end

function CurrentPctMana(entity)
	local pctMana =  entity.mana/entity.maxMana * 100
	return pctMana
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


class "Brand"
function Brand:__init()	
	print("Loaded [Auto] ".. myHero.charName)
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end
function Brand:LoadSpells()
	Q = {Range = 1000, Width = 80, Delay = 0.30, Speed = 1550, Collision = true, aoe = false, Sort = 'line'}
	W = {Range = 900, Width = 240, Delay = 0.75, Speed = 99999, Collision = false, aoe = true, Sort = "circular"}
	E = {Range = 600, Delay = 0.25, Speed = 99999, Collision = false }
	R = {Range = 750, Width = 0, Delay = 0.25, Speed = 1700, Collision = false, aoe = false, Sort = "circular"}
end

function Brand:CreateMenu()
	TPred()
	
	AIO = MenuElement({type = MENU, id = myHero.charName, name = "[Auto] "..myHero.charName})
	AIO:MenuElement({id = "Skills", name = "Skills", type = MENU})
	AIO.Skills:MenuElement({id = "QAcc", name = "Auto Q Accuracy", value = 3, min = 1, max = 5, step = 1 })
	
	AIO.Skills:MenuElement({id = "EMan", name = "Auto E Mana", value = 25, min = 1, max = 100, step = 5 })
	
	AIO.Skills:MenuElement({id = "WAcc", name = "Auto W Accuracy", value = 3, min = 1, max = 5, step = 1 })
	AIO.Skills:MenuElement({id = "WMan", name = "Auto W Mana", value = 25, min = 1, max = 100, step = 5})
	
	
	AIO.Skills:MenuElement({id = "RCount", name = "Auto R Enemy Count", value = 3, min = 1, max = 5, step = 1})
		
	AIO:MenuElement({id = "comboActive", name = "Combo key",value = true, toggle = true, key = string.byte(" ")})
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

	--Check for out of range gapclosers	
	local target = TPred:GetInteruptTarget(myHero.pos, W.Range, W.Delay, W.Speed, AIO.reactionTime:Value())
	if target ~= nil then
		Control.CastSpell(HK_W, target:GetPath(1))	
	end			
	
	--Check for stasis targets
	local target = TPred:GetStasisTarget(myHero.pos, W.Range, W.Delay, W.Speed, AIO.reactionTime:Value())
	if target ~= nil then
		Control.CastSpell(HK_W, target.pos)			
		--Check if our Q will intercept after W and not hit minions on the way, if so cast it as well.		
	end
		
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

class "Nami"

local _adcHeroes = { "Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "Jhin", "Jinx", "Kalista", "KogMaw", "Lucian", "MissFortune", "Quinn", "Sivir", "Teemo", "Tristiana", "Twitch", "Varus", "Vayne", "Xayah"}
	
function Nami:__init()	
	print("Loaded [Auto] "..myHero.charName)
	TPred()	
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end
function Nami:LoadSpells()

	Q = {Range = 875, Width = 150,Delay = 0.75, Speed = 2000,  Sort = "circular"}
	W = {Range = 725}
	E = { Range = 800}
	R = {Range = 2750,Width = 260, Speed = 850, Delay = 0.5, Sort = "line" }
end

function Nami:CreateMenu()
	AIO = MenuElement({type = MENU, id = "Nami", name = "[Auto] " .. myHero.charName})
	
	AIO:MenuElement({id = "Skills", name = "Skills", type = MENU})
	AIO.Skills:MenuElement({id = "QTiming", name = "Q Interupt Delay", value = .25, min = .1, max = 1, step = .05 })
	
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
	if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or not AIO.autoSkillsActive:Value() then return end	
		
	--Try to interupt dashes or hourglass with Q if we can
	if Ready(_Q) then 
		self:AutoQInterupt()
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
	self:AutoCrucible()
end

function Nami:GetDistanceSqr(p1, p2)
	assert(p1, "GetDistance: invalid argument: cannot calculate distance to "..type(p1))
	assert(p2, "GetDistance: invalid argument: cannot calculate distance to "..type(p2))
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function Nami:GetDistance(p1, p2)
	return math.sqrt(self:GetDistanceSqr(p1, p2))
end
function Nami:NearestEnemyDistance(entity)
	local distance = 999999
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if isValidTarget(hero,range) and hero.team ~= myHero.team then
			local d = self:GetDistance(entity.pos, hero.pos)
			if d < distance then
				distance = d
			end
		end
	end
	return distance
end

function Nami:AutoQInterupt()
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
end

function Nami:AutoWEmergency()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and self:GetDistance(myHero.pos, Hero.pos) <= W.Range and CurrentPctLife(Hero) <= AIO.Skills.WEmergencyPct:Value() then
			Control.CastSpell(HK_W, Hero.pos)			
		end
	end
end

function Nami:AutoWBounce()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and self:GetDistance(myHero.pos, Hero.pos) <= W.Range and CurrentPctLife(Hero) <= AIO.Skills.WBouncePct:Value() then
			if self:NearestEnemyDistance(Hero) < 500 then
				Control.CastSpell(HK_W, Hero.pos)
			end
		end
	end
end

function Nami:AutoE()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if  Hero.isAlly and Hero ~= myHero and self:GetDistance(myHero.pos, Hero.pos) <= E.Range then
			--Check if they are using an auto attack spell
			local targetHandle = nil			
			if Hero.activeSpell and Hero.activeSpell.valid and Hero.activeSpell.isAutoAttack and Hero.activeSpell.target then
				targetHandle = Hero.activeSpell.target
			end
			if Hero.attackData and Hero.attackData.state == STATE_WINDUP and Hero.attackData.target then
				targetHandle = Hero.attackData.target
			end
			
			if targetHandle then 
				for ei = 1, Game.HeroCount() do
					local Enemy = Game.Hero(ei)
					if Enemy.isEnemy and Enemy.handle == targetHandle then
						Control.CastSpell(HK_E, Hero.pos)
					end
				end
			end
		end
	end
end

function Nami:AutoCrucible()
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and Hero ~= myHero then
			--Check if they are hard CCd
			--Check if they are our carry
			--Cast Crucible
		end
	end
end