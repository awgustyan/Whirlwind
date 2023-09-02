local WeightQueue = {}
WeightQueue.__index = WeightQueue

local function isEmpty(dictionary)	
	for _, _ in pairs(dictionary) do
		return false
	end
	
	return true
end

function WeightQueue.new(queue)
	local self = setmetatable({}, WeightQueue)
	
	self._topKey = nil
	self._bottomKey = nil
	self._queue = queue or {}
	
	self:_update()
	
	return self
end

function WeightQueue:_update()
	local topKey = nil
	local bottomKey = nil

	for key, info in pairs(self._queue) do
		if not self._topKey or info.Weight > self._queue[self._topKey].Weight then
			self._topKey = key
		end

		if not self._bottomKey or info.Weight < self._queue[self._bottomKey].Weight then
			self._bottomKey = key
		end
	end
end

function WeightQueue:IsEmpty()
	return isEmpty(self._queue)
end

function WeightQueue:Add(key : string, weight : number, value : number)
	if (not self._topKey or not self._queue[self._topKey]) or weight > self._queue[self._topKey].Weight then
		self._topKey = key
	end
	
	if (not self._bottomKey or not self._queue[self._bottomKey]) or weight < self._queue[self._bottomKey].Weight then
		self._bottomKey = key
	end
	
	self._queue[key] = {Value = value, Weight = weight}
end

function WeightQueue:Remove(key : string)
	self._queue[key] = nil
	
	self:_update()
end

function WeightQueue:Top()
	return self._queue[self._topKey].Value
end

function WeightQueue:Bottom()
	return self._queue[self._bottomKey].Value
end

function WeightQueue:Destroy()
	self = nil
end

return WeightQueue