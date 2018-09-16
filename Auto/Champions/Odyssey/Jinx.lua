W = {	Range = 1450,	Delay= 0.6,	Speed = 3300,	Width = 100	}
E = {	Range = 900 }
R = {	Range = 999999,	Delay= 0.6,	Speed = 1700,	Width = 140	}

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "W", name = "[W] Zap", type = MENU})
	Menu.Skills.W:MenuElement({id = "AA", name = "Cast after AA", value = true })
	Menu.Skills.W:MenuElement({id = "Count", name = "Target Count", value = 4, min = 1, max = 25, step = 1 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Flame Chompers!", type = MENU})
	Menu.Skills.E:MenuElement({id = "AA", name = "Cast after AA", value = true })
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Super Mega Death Rocket!", type = MENU})
	Menu.Skills.R:MenuElement({id = "Count", name = "Target Count", value = 5, min = 1, max = 25, step = 1 })
	
	Callback.Add("Tick", function() Tick() end)	
	_G.SDK.Orbwalker:OnPostAttack(function(args) OnPostAttack() end)
end


local NextTick = LocalGameTimer()
function OnPostAttack()
	if not myHero.activeSpell.target then return end
	local target = LocalObjectManager:GetObjectByHandle(myHero.activeSpell.target)
	if not target then return end

	if Ready(_W) and Menu.Skills.W.AA:Value() then
		local targetCount, castPosition = LocalGeometry:GetArcFarmCastPosition(W.Range, W.Delay, W.Speed, W.Width)		
		if targetCount >= 0 then
			CastSpell(HK_W, castPosition)
		end
	end
	
	--Trap between AAs
	if Ready(_E) and Menu.Skills.E.AA:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
		CastSpell(HK_E, target.pos)
	end	
end



function Tick()
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	if BlockSpells() then return end
	if myHero.activeSpell and myHero.activeSpell.valid and not myHero.activeSpell.spellWasCast then return end
	
	if Ready(_W) then
		local targetCount, castPosition = LocalGeometry:GetArcFarmCastPosition(W.Range, W.Delay, W.Speed, W.Width)		
		if targetCount >= Menu.Skills.W.Count:Value() then
			CastSpell(HK_W, castPosition)
		end
	end
	
	if Ready(_R) then
		local targetCount, castPosition = LocalGeometry:GetLineFarmCastPosition(myHero.pos, R.Range, R.Delay, R.Speed, R.Width)
		if targetCount >= Menu.Skills.R.Count:Value() then
			CastSpell(HK_R, castPosition)
		end
	end
	
	NextTick = LocalGameTimer() + .05
end