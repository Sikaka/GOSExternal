local R = {	Range = 400	}
local barHeight = 8
local barWidth = 103
local barXOffset = 18                            
local barYOffset = 2

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Decisive Strike", type = MENU	})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "AA Reset", value = true	})
	Menu.Skills.Q:MenuElement({id = "Radius",	name = "Combo When Distance < X",	value = 500,	min = 100,	max = 700,	step = 25	})
		
	Menu.Skills:MenuElement({id = "W",	name = "[W] Courage",	type = MENU})
	Menu.Skills.W:MenuElement({id = "CC",	name = "Use on Incoming CC",	value = true	})
		
	Menu.Skills:MenuElement({id = "E", name = "[E] Judgment", type = MENU})
	Menu.Skills.E:MenuElement({id = "Combo",	name = "Cast In Combo",	value = true	})
	
		
	Menu.Skills:MenuElement({id = "R", name = "[R] Demacian Justice", type = MENU})
	Menu.Skills.R:MenuElement({id = "Killsteal", name = "Killsteal", value = true })
	
	Menu.Skills:MenuElement({id = "Draw", name = "Draw Damage", value = true })
	
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	_G.SDK.Orbwalker:OnPostAttack(function(args) OnPostAttack() end)
	
	Callback.Add("Tick", function() Tick() end)
	Callback.Add("Draw", function() _Draw() end)
end

function OnPostAttack()
	--Check for E AA reset
	if not myHero.activeSpell.target then return end
	local target = LocalObjectManager:GetHeroByHandle(myHero.activeSpell.target)
	if not target then return end
		
	if Ready(_Q) and (Menu.Skills.Q.Auto:Value() or ComboActive()) then	
		CastSpell(HK_Q)
		_G.SDK.Orbwalker.AutoAttackResetted = true
		return
	end	
end

function _Draw()
	if Menu.Skills.Draw:Value() then
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if CanTarget(hero) and hero.hpBar.onScreen then				
				local damage = myHero.totalDamage
				if Ready(_Q) then
					damage = LocalDamageManager:CalculateDamage(myHero, hero, "GarenQ")
				end
				if Ready(_R) then
					local rDamage = myHero:GetSpellData(_R).level * 175 + ({.286,.333,.4})[myHero:GetSpellData(_R).level] * (damage + hero.maxHealth - hero.health)		
					damage = damage + LocalDamageManager:CalculateMagicDamage(myHero, hero, rDamage)
				end
				damage = damage + LocalDamageManager:RecordedIncomingDamage(hero)
				local barPos = hero.hpBar
				local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
				local xPosEnd = barPos.x + barXOffset+ barWidth * hero.health/hero.maxHealth
				local xPosStart = barPos.x +barXOffset+  percentHealthAfterDamage * 100                            
				Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, Draw.Color(255,235,103,25))
			end
		end
	end
end

function OnSpellCast(spell)
	if spell.isEnemy and Ready(_W) then
		local hitDetails = LocalDamageManager:GetSpellHitDetails(spell,myHero)
		if hitDetails and hitDetails.Hit and hitDetails.Path and hitDetails.CC and Menu.Skills.W.CC:Value() then
			CastSpell(HK_W)
		end
	end
end


local NextTick = LocalGameTimer()
function Tick()
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	NextTick = LocalGameTimer() + .1
	if BlockSpells() then return end
	
	if ComboActive() then
		local target = GetTarget(Menu.Skills.Q.Radius:Value(), true)
		if CanTarget(target) then		
			CastSpell(HK_Q)
		end
	end
	
	if Ready(_R) and Menu.Skills.R.Killsteal:Value() then
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if CanTarget(hero) and LocalGeometry:IsInRange(myHero.pos, hero.pos, R.Range) then	
				local thisDmg = LocalDamageManager:CalculateDamage(myHero, hero, "GarenR")
				local qDamage = ComboActive() and Ready(_Q) and LocalGeometry:IsInRange(myHero.pos, hero.pos, myHero.range) and LocalDamageManager:CalculateDamage(myHero, hero, "GarenQAttack") or 0 
				local incomingDmg =LocalDamageManager:RecordedIncomingDamage(hero)
				local heroHp = hero.health + hero.hpRegen
				if thisDmg > heroHp and incomingDmg + qDamage < heroHp then
					if CastSpell(HK_R, hero) then
						NextTick = LocalGameTimer() + .25
						return
					end
				end				
			end
		end
	end
	
	if Ready(_E) and not LocalBuffManager:HasBuff(myHero, "GarenQ") and myHero:GetSpellData(_E).toggleState == 0 and ComboActive() and Menu.Skills.E.Combo:Value() then
		local target = GetTarget(325, true)		
		if CanTarget(target) then
			Control.KeyDown(HK_E)
			DelayAction(function() Control.KeyUp(HK_E) end, .5)
			NextTick = LocalGameTimer() + .65
		end
	end
	
end