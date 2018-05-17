Q = {Range = 400}
W = {Range = 750, Radius = 85,Delay = .75, Speed = 99999 }

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Lunge", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Hit Vitals", value = true})
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
end



local _offsetDistance = 100
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

LocalObjectManager:OnParticleDestroy(function(particleInfo)
	if _marks[particleInfo.networkID] then
		_marks[particleInfo.networkID] = nil
	end
end)
	
LocalObjectManager:OnParticleCreate(function(particleInfo)
	for key, offset in pairs(_markOffsets) do
		if StringEndsWith(particleInfo.name, key) then
			if not _marks[particleInfo.networkID] then
				local owner = LocalObjectManager:GetPlayerByPosition(particleInfo.pos)				
				_marks[particleInfo.networkID] = { pos = offset, owner = owner}
				OnMarkAdded(owner, offset)
			end
		end
	end
end)


function OnMarkAdded(target, offset)
	if LocalGeometry:IsInRange(myHero.pos, target.pos + offset, 400) and (Menu.Skills.Q.Auto:Value() or Menu.Skills.Combo:Value()) then
		CastSpell(HK_Q, target.pos + offset)
		NextTick = LocalGameTimer() +.25
	end
end

function OnPostAttack()
	--Check for E AA reset
	if not myHero.activeSpell.target then return end
	local target = LocalObjectManager:GetObjectByHandle(myHero.activeSpell.target)
	if not target then return end
		
	if Ready(_E) and (Menu.Skills.E.Auto:Value() or Menu.Skills.Combo:Value() then
		CastSpell(HK_E)
		return
	end	
end

local NextTick = LocalGameTimer()
function Tick()
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end		
	NextTick = LocalGameTimer() + .05
end

function OnCC(target, damage, ccType, canDodge)
	if target == myHero and LocalDamageManager.IMMOBILE_TYPES[ccType] then
		if Menu.Skills.W.Auto:Value() or Menu.Skills.Combo:Value() then
			local target = GetTarget(W.Range, true)
			if target then				
				local predictedPosition = LocalGeometry:PredictUnitPosition(target, W.Delay)
				if LocalGeometry:IsInRange(myHero.pos, predictedPosition, W.Range) then
					NextTick = LocalGameTimer() +.25
					CastSpell(HK_W, predictedPosition)
					return
				end
			end
		end
	end
end