class 'FireTests'

function FireTests:__init()
	Events:Subscribe('LocalPlayerInput', self, self.LocalPlayerInput)

	self.fire_right_timer = Timer()
end

function FireTests:LocalPlayerInput(e)
	if e.input == Action.FireRight then
		if self.fire_right_timer:GetSeconds() > 1 then
			EntMgr:CreateEntity('Missile', {
				origin = Camera:GetPosition(),
				angle = Camera:GetAngle()
			})

			self.fire_right_timer:Restart()
		end
	end

	-- Update the target of our missiles to our aim position
	for k, v in ipairs(EntMgr.entities) do
		if class_info(v).name == 'Missile' then
			v.target_position = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 2000).position
		end
	end
end

local tests = FireTests()