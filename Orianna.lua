--This is all just begining of the manager code, you should move to the official library once it's done and released for best reliability.
--Feel free to test out the OnBlink callback to find enemies who are using flashes and stuff ;)

class "__ObjectManager"

--Localize all the stuff. Can be an efficiency improvement but I haven't tested if all of these are more efficient or not.
local LocalGameHeroCount 			= Game.HeroCount;
local LocalGameHero					= Game.Hero;
local LocalGameMinionCount 			= Game.MinionCount;
local LocalGameMinion				= Game.Minion;
local LocalGameParticleCount 		= Game.ParticleCount;
local LocalGameParticle				= Game.Particle;
local LocalGameMissileCount 		= Game.MissileCount;
local LocalGameMissile				= Game.Missile;
local LocalPairs 					= pairs;
local LocalType						= type;
local LocalVector					= Vector;
local LocalInsert 					= table.insert


--Initialize the object manager
function __ObjectManager:__init()
	Callback.Add('Tick',  function() self:Tick() end)
	
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
	--If there are no on particle callbacks we need to add one or it might never run!
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
					--Todo: a system to try to associate a particle with its owner? There's no way I know to get it right now.
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
					--We need a direct reference to the missile object to handle position/start/end/speed/etc.
					--We pre calculate a forward vector to avoid having to re-calculate it every frame for collision detection
						--TODO: Test that all missiles have a start/end pos and that this doesn't throw exceptions :O
					local missileData = 
					{ 
						valid = true,
						name = missile.name,
						forward = LocalVector(
							missile.missileData.endPos.x -missile.missileData.startPos.x,
							missile.missileData.endPos.y -missile.missileData.startPos.y,
							missile.missileData.endPos.z -missile.missileData.startPos.z):Normalized(),
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



--This is the ori script
ObjectManager = __ObjectManager()

--Sanity check: 
	--If buff orianaghostself is on us, the ball is on us
	--If buff xxxx??xxxx is on ally then its attached to them (look it up!)

local BallNames = 
{
	--Ball name on ground: Add to list if it changes with skins. Requires testing :D
	"Orianna_Base_Q_yomu_ring_green",
}

local BallPosition = nil


--This will trigger every time a particle is created
ObjectManager:OnParticleCreate(function(args)
	--Match up the name: NOTE IT MAY CHANGE WITH SKIN USED... 
	if table.contains(BallNames, args.name) then
		BallPosition = args.pos 
	end
end)

--This will trigger every time a particle in the game is destroyed
ObjectManager:OnParticleDestroy(function(args)	
	if table.contains(BallNames, args.name) then
		BallPosition = nil
	end
end)

Callback.Add('Draw', function()
	if BallPosition then
		Draw.Circle(BallPosition,200, 15)
	end	
end)