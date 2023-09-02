local function absDist(x)
	return type(x) == "number" and math.abs(x) or x.magnitude;
end

--

local spring = {};
local spring_mt = {__index = spring};

function spring.new(position, velocity, target, stiffness, damping, precision)
	local self = {};
	
	self.position = position;
	self.velocity = velocity;
	self.target = target;
	self.stiffness = stiffness;
	self.damping = damping;
	self.precision = precision;
	
	return setmetatable(self, spring_mt);
end

--

function spring:update(dt)
	local displacement = self.position - self.target;
	local springForce = -self.stiffness * displacement;
	local dampForce = -self.damping * self.velocity;
	
	local acceleration = springForce + dampForce;
	local newVelocity = self.velocity + acceleration*dt;
	local newPosition = self.position + newVelocity;
	
	if (absDist(newVelocity) < self.precision and absDist(self.target - newPosition) < self.precision) then
		self.position = self.target;
		self.velocity = self.velocity - self.velocity;
		return;
	end
	
	self.position = newPosition;
	self.velocity = newVelocity;
end

--

return spring;