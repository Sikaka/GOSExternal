Q = {Range = 325 }
E = {	Range = 450,	Radius = 45,	Speed = 1125,	Delay = .25, 	IsLine = true	}

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Cull the Meek", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Hit Enemies", value = true})	
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Ruthless Predator", type = MENU})
	Menu.Skills.W:MenuElement({id = "Auto", name = "AA Reset", value = true})
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Slice and Dice", type = MENU})
	Menu.Skills.E:MenuElement({id = "CC", name = "Dodge Immobilizing CC", value = true })
	
	Callback.Add("Tick", function() Tick() end)	
	_G.SDK.Orbwalker:OnPostAttack(function(args) OnPostAttack() end)
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
end

function OnSpellCast(spell)
	if spell.isEnemy then
		local hitDetails = LocalDamageManager:GetSpellHitDetails(spell,myHero)
		if hitDetails and hitDetails.Hit and hitDetails.Path then
			if Ready(_E) then				
				local target = GetTarget(E.Range, true)
				if target then
					if hitDetails.CC and Menu.Skills.E.CC:Value() then
						local dashPos = myHero.pos + hitDetails.Path * E.Range				
						CastSpell(HK_E, dashPos)
						NextTick = LocalGameTimer() +.15
					end
				end
			end
		end
	end
end

function OnPostAttack()
	--Check for W AA reset
	if not myHero.activeSpell.target then return end
	local target = LocalObjectManager:GetHeroByHandle(myHero.activeSpell.target)
	if not target then return end
		
	if Ready(_W) and (Menu.Skills.W.Auto:Value() or ComboActive()) then	
		CastSpell(HK_W)
		_G.SDK.Orbwalker.AutoAttackResetted = true
		return
	end
end

local NextTick = LocalGameTimer()
function Tick()
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end

	if myHero.activeSpell and myHero.activeSpell.valid and not myHero.activeSpell.spellWasCast then return end
	
	local target = GetTarget(Q.Range, true)
	if CanTarget(target) and Ready(_Q) and (Menu.Skills.Q.Auto:Value() or ComboActive()) then	
		CastSpell(HK_Q)
	end
	
	local target = GetTarget(E.Range + myHero.range, true)
	if CanTarget(target) and ComboActive() and Ready(_E) and not LocalGeometry:IsInRange(myHero.pos, target.pos, myHero.range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay, E.Speed, E.Radius, E.Collision, E.IsLine)
		--Get the normalized dash pos
		if castPosition and accuracy > 0 then
			local dashPosition = (castPosition - myHero.pos):Normalized() * E.Range
			if LocalGeometry:IsInRange(dashPosition, castPosition, myHero.range) then
				CastSpell(HK_E, dashPosition)
			end
		end
	end
	NextTick = LocalGameTimer() + .05
end