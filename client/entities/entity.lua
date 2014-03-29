class 'Entity'

function Entity:__init()
	self.expired = false
end

function Entity:IsExpired()
	return self.expired
end

function Entity:Expire()
	self.expired = true
end

function Entity:Tick(dt)
end

function Entity:Draw()
end

function Entity:Remove()
end

function Entity:GetPosition()
	return Vector3.Zero
end

function Entity:__tostring()
	return 'Entity'
end