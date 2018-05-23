Q = {Range = 400}
W = {Range = 750, Radius = 85,Delay = .75, Speed = 99999 }

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Lunge", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Hit Vitals", value = true})
	Menu.Skills.Q:MenuElement({id = "DodgeAuto", name = "Dodge Danger Level (Auto)", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.Q:MenuElement({id = "DodgeCombo", name = "Dodge Danger Level (Combo) ", value = 2, min = 1, max = 6, step = 1 })
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Riposte", type = MENU})
	Menu.Skills.W:MenuElement({id = "Auto", name = "Auto Reflect", value = true})
	Menu.Skills.W:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Bladework", type = MENU})
	Menu.Skills.E:MenuElement({id = "Auto", name = "AA Reset", value = true})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })		
	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType, canDodge) OnCC(target, damage, ccType, canDodge) end)
	Callback.Add("Tick", function() Tick() end)	
	_G.SDK.Orbwalker:OnPostAttack(function(args) OnPostAttack() end)	
	LocalObjectManager:OnParticleCreate(function(particleInfo) OnParticleCreate(particleInfo) end)	
	LocalObjectManager:OnParticleDestroy(function(particleInfo) OnParticleDestroy(particleInfo) end)
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
end


function OnSpellCast(spell)
	if spell.isEnemy then
		local hitDetails = LocalDamageManager:GetSpellHitDetails(spell,myHero)
		if hitDetails.Hit and hitDetails.Path then
			if hitDetails.CC and Ready(_W) and hitDetails.HitTime < .7 then				
				local target = GetTarget(W.Range, true)
				if target then
					local aimPosition = LocalGeometry:PredictUnitPosition(target, .75)
					if LocalGeometry:IsInRange(myHero.pos, aimPosition, W.Range) then
						CastSpell(HK_W, aimPosition)
						return
					end
				end
			end
			if Ready(_Q) then
				if hitDetails.Danger >= Menu.Skills.Q.DodgeAuto:Value() or (Menu.Skills.Combo:Value() and hitDetails.Danger >= Menu.Skills.Q.DodgeCombo:Value()) then	
					local dashPos = myHero.pos + hitDetails.Path * Q.Range				
					CastSpell(HK_Q, dashPos)
					NextTick = LocalGameTimer() +.15
				end	
			end
		end
	end
end


local _offsetDistance = 50
local _marks = {}
local _markOffsets = 
{
	["_NE"] = Vector(0,0,_offsetDistance),
	["_NW"] = Vector(_offsetDistance,0,0),
	["_SE"] = Vector(-_offsetDistance,0,0),
	["_SW"] = Vector(0,0,-_offsetDistance),
	["_NE_FioraOnly"] = Vector(0,0,_offsetDistance),
	["_NW_FioraOnly"] = Vector(_offsetDistance,0,0),
	["_SE_FioraOnly"] = Vector(-_offsetDistance,0,0),
	["_SW_FioraOnly"] = Vector(0,0,-_offsetDistance),
}

function OnParticleDestroy(particleInfo)
	if _marks[particleInfo.networkID] then
		_marks[particleInfo.networkID] = nil
	end
end
	
function OnParticleCreate(particleInfo)
	for key, offset in LocalPairs(_markOffsets) do
		if StringEndsWith(particleInfo.name, key) then
			if not _marks[particleInfo.networkID] then
				local owner = LocalObjectManager:GetPlayerByPosition(particleInfo.pos)				
				_marks[particleInfo.networkID] = { pos = offset, owner = owner}
			end
		end
	end
end

function OnPostAttack()
	--Check for E AA reset
	if not myHero.activeSpell.target then return end
	local target = LocalObjectManager:GetHeroByHandle(myHero.activeSpell.target)
	if not target then return end
		
	if Ready(_E) and (Menu.Skills.E.Auto:Value() or Menu.Skills.Combo:Value()) then	
		CastSpell(HK_E)
		_G.SDK.Orbwalker.AutoAttackResetted = true
		return
	end	
end

local NextTick = LocalGameTimer()
function Tick()
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end

	if myHero.activeSpell and myHero.activeSpell.valid and not myHero.activeSpell.spellWasCast then return end
	if Ready(_Q) and (Menu.Skills.Combo:Value() or Menu.Skills.Q.Auto:Value()) then
		local target = GetTarget(Q.Range, true)
		if CanTarget(target) then
			for _, mark in LocalPairs(_marks) do
				if mark.owner ==  target then
					local markHitPos = LocalGeometry:PredictUnitPosition(target, LocalGeometry:GetDistance(myHero.pos, target.pos) / 800) + mark.pos
					if LocalGeometry:IsInRange(myHero.pos, markHitPos, Q.Range) then
						NextTick = LocalGameTimer() +.25
						CastSpell(HK_Q, markHitPos)
						return
					end
				end
			end
		end
	end
	NextTick = LocalGameTimer() + .05
end

function OnCC(target, damage, ccType, canDodge)
	if target == myHero then
		if Menu.Skills.W.Auto:Value() or Menu.Skills.Combo:Value() then
			local target = GetTarget(W.Range, true)
			if target then				
				local predictedPosition = LocalGeometry:PredictUnitPosition(target, W.Delay)
				if LocalGeometry:IsInRange(myHero.pos, predictedPosition, W.Range) or LocalDamageManager.IMMOBILE_TYPES[ccType] then
					NextTick = LocalGameTimer() +.25
					CastSpell(HK_W, predictedPosition)
					return
				end
			end
		end
	end
end