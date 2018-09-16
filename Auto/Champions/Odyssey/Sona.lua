Q = {	Range = 825 }
W = {	Range = 1000	}
E = {	Range = 430 }
R = {	Range = 800,	Delay = .25	}

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Power Chord", type = MENU})
	Menu.Skills.Q:MenuElement({id = "AA", name = "Cast after AA", value = true })
	
	Menu.Skills:MenuElement({id = "W", name = "[W] Hymn of Valor", type = MENU})
	Menu.Skills.W:MenuElement({id = "Targets", name = "Target Settings", type = MENU})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isAlly and myHero ~= hero then
			Menu.Skills.W.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = 75, min = 1, max = 100, step = 5 })		
		end
	end
		
	Menu.Skills:MenuElement({id = "E", name = "[E] Song of Celerity", type = MENU})
	Menu.Skills.E:MenuElement({id = "Cleanse", name = "Cast on Ally CC", value = true })
	Menu.Skills.E:MenuElement({id = "AA", name = "Cast after AA", value = true })
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Crescendo", type = MENU})
	Menu.Skills.R:MenuElement({id = "Count", name = "Auto Cast On # Enemies", value = 10, min = 1, max = 5, step = 1 })
	Callback.Add("Tick", function() Tick() end)	
	_G.SDK.Orbwalker:OnPostAttack(function(args) OnPostAttack() end)	
end


local NextTick = LocalGameTimer()
function OnPostAttack()
	if not myHero.activeSpell.target then return end
	local target = LocalObjectManager:GetObjectByHandle(myHero.activeSpell.target)
	if not target then return end
			
	if Ready(_Q) and (Menu.Skills.Q.AA:Value() or ComboActive()) then	
		CastSpell(HK_Q)
		return
	end		
	if Ready(_E) and (Menu.Skills.E.AA:Value() or ComboActive()) then	
		CastSpell(HK_E)
		return
	end	
end


function Tick()
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	if BlockSpells() then return end
	if myHero.activeSpell and myHero.activeSpell.valid and not myHero.activeSpell.spellWasCast then return end
	
	if Ready(_W) then
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if CanTargetAlly(hero) and LocalGeometry:IsInRange(myHero.pos, hero.pos, W.Range) then
				local incomingDamage = LocalDamageManager:RecordedIncomingDamage(hero)
				local remainingLifePct = (hero.health - incomingDamage) / hero.maxHealth * 100
				if 75 >= remainingLifePct then
					CastSpell(HK_W, hero)
					NextTick = LocalGameTimer() + .15
				end
			end
		end
	end
	
	if Ready(_E) and Menu.Skills.E.Cleanse:Value() then
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i)
			if CanTargetAlly(hero) and LocalGeometry:IsInRange(myHero.pos, hero.pos, W.Range) and LocalGeometry:GetImmobileTime(hero) > 1 then				
				CastSpell(HK_E)
			end
		end
	end
	
	if Ready(_R) then
		if OdysseyEnemyCount(myHero.pos, R.Range, R.Delay) >= Menu.Skills.R.Count:Value() then
			CastSpell(HK_R)
		end		
	end	
	NextTick = LocalGameTimer() + .05
end