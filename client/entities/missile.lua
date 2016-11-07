class 'Missile' (Entity)

function Missile:__init(args)
	Entity.__init(self)

	self.co = coroutine.create(self.YieldableStep)
	self.timer = Timer()

	self.position = args.origin
	self.angle = args.angle

	self.projectile = nil
	self.booster_stage = true
	self.speed = 0

	self.detonate = false
	self.detonation_point = nil

	self.target = nil
	self.target_position = nil

	self.booster_acceleration = 250 -- m/s
	self.max_speed = 50 -- m/s
	self.max_turn_angle = 140 -- degrees per second
	self.fuel = 2000 -- meters
end

function Missile:__tostring()
	return string.format('Fuel: %f, Speed: %f', self.fuel, self.speed)
end

function Missile:Tick(dt)
	self.dt = dt

	-- Above all else, we need to check for detonations
	self:DetonationCheck()

	-- Run the coroutine and print out any errors it might encounter
	local success, error_message = coroutine.resume(self.co, self)
	if not success then
		error(error_message)
	end
end

function Missile:Remove()
	if self.projectile then
		self.projectile:Remove()
		self.projectile = nil
	end
end

function Missile:DetonationCheck()
	-- No point doing checks if we don't have a projectile
	if not self.projectile then
		return
	end

	-- Maximum distance we can travel in one frame. This varies
	-- drastically according to FPS. If we search a set distance, its
	-- quite possible that the collision check will fail in cases
	-- where framerates tank. In these situations, the missile would otherwise
	-- skip right through the target.
	local max_travel = self.dt * self.speed
	local ray = Physics:Raycast(self.position, (self.angle * Vector3.Forward), 0, max_travel)

	-- Did our ray collide with something?
	if (max_travel - ray.distance) > 0.001 then
		self.detonate = true
		self.detonation_point = ray.position
	end

	-- So our ray didn't hit the target. What if the target is in open 
	-- space, without a collision?
	if Vector3.Distance(self.position, self:GetTargetPosition()) < 1 then
		self.detonate = true
		self.detonation_point = self.position
	end
end

function Missile:YieldableStep()
	-- Calculate a point in front of the provided origin
	local direction = self.angle
	local start_pos = self.position + ((direction * Vector3.Forward) * 15)

	-- First thing that occurs when you fire a missile?
	-- Flames, of course!
	self:PlayFireEffect(start_pos)

	-- We also need a projectile!
	self:CreateProjectile(start_pos)

	-- We have a ploom and a projectile. Time to simulate it.
	while not self:IsExpired() do
		self:Step()
		coroutine.yield()
	end
end

function Missile:Step()
	if self.detonate then
		self:Detonate()

		return
	end

	-- If we ran out of fuel, its game over. Thanks for playing!
	if self.fuel < 0 then
		self:Expire()
	end

	-- If we were just fired, we need to gradually speed up
	-- to an acceptable speed. We obey the laws of physics (sometimes)!
	if self.booster_stage then
		self:BoosterStage()
	end

	local dir_to_target = self.angle
	-- If we're aiming for a target, calculate the angle to it.
	-- Otherwise, Forward is fine.
	if self:HasTarget() then
		dir_to_target = Vector3.NormalisedDir(self:GetTargetPosition(), self.position)
		dir_to_target = Angle.FromVectors(Vector3.Forward, dir_to_target)
	end

	-- Calculate the new angle to the target, taking into account the maximum 
	-- turning angle.
	local new_angle	= Angle.RotateToward(self.angle, dir_to_target, math.rad(self.max_turn_angle * self.dt))

	self:SimulateMovement(new_angle)
end

function Missile:BoosterStage()
	local start_time = Timer()
	local direction = self.angle * Vector3.Forward

	while not self.detonate and self.speed < self.max_speed do
		self.speed = self.speed + (self.booster_acceleration * self.dt)
		self:SimulateMovement(self.angle)

		coroutine.yield()
	end

	self.booster_stage = false
end

function Missile:SimulateMovement(angle)
	local direction = angle * Vector3.Forward

	-- Simulate velocity
	self.position = self.projectile:GetPosition() + (direction * (self.speed * self.dt))
	self.angle = angle

	self.projectile:SetPosition(self.position)
	self.projectile:SetAngle(self.angle)

	self.fuel = self.fuel - (self.speed * self.dt)
end

function Missile:Detonate()
	-- Remove our projectile
	self.projectile:Remove()
	self.projectile = nil

	-- Play the detonation effect
	ClientEffect.Play(AssetLocation.Game, {
		effect_id = 5,
		position = self.detonation_point,
		angle = Angle()
	})

	-- We've completed our task. Goodbye
	self:Expire()
end

function Missile:PlayFireEffect(start_pos)
	-- We rotate the angle by 90 degrees to match the offset
	-- rotation of the effect emitter.
	ClientEffect.Play(AssetLocation.Game, {
		effect_id = 53,
		position = start_pos,
		angle = self.angle * Angle(math.pi/2, 0, 0)
	})
end

function Missile:CreateProjectile(start_pos)
	self.projectile = ClientEffect.Create(AssetLocation.Game, {
		effect_id = 246,
		position = start_pos,
		angle = self.angle
	})
end

function Missile:HasTarget()
	return self.target_entity or self.target_position
end

function Missile:GetTargetPosition()
	-- Are we chasing some vehicle/player?
	if self.target_entity then
		if IsValid(self.target_entity) then
			return self.target_entity:GetPosition()
		end
	elseif self.target_position then
		return self.target_position
	end

	-- Well, we have no special target.. this shouldn't be 
	-- operated on, so return zero.
	return Vector3.Zero
end
