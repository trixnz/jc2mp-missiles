class 'EntityManager'

function EntityManager:__init()
	Events:Subscribe('PostRender', self, self.PostRender)
	Events:Subscribe('PostTick', self, self.PostTick)
	Events:Subscribe('ModuleUnload', self, self.Unload)

	self.entities = {}
	self.tick_timer = Timer()	
end

function EntityManager:CreateEntity(name, args)
	local fn = _G[name]
	local ent = fn(args)
	if class_info(ent).name ~= name then
		error('Unexpected return value from entity constructor')
		return
	end

	table.insert(self.entities, ent)

	return ent
end

function EntityManager:PostRender()
	local pos = Vector2(0, 0)

	for k, v in ipairs(self.entities) do
		v:Draw()

		Render:DrawText(pos, string.format('%s #%i %s', class_info(v).name, k, tostring(v)), Color.LawnGreen)
		pos.y = pos.y + 15
	end
end

function EntityManager:PostTick()
	local frame_time = self.tick_timer:GetMilliseconds() / 1000
	self.tick_timer:Restart()

	local i = 1
	while i <= #self.entities do
		local v = self.entities[i]
		v:Tick(frame_time)

		if v:IsExpired() then
			v:Remove()
			table.remove(self.entities, i)
		else
			i = i + 1
		end	
	end
end

function EntityManager:Unload()
	-- Clean up all remaining entities on unload, just in-case
	-- we ran into errors. We don't want to leave stuff everywhere.
	local i = 1
	while i <= #self.entities do
		local v = self.entities[i]

		v:Remove()
		table.remove(self.entities, i)
	end
end