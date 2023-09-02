local Stack = {}
Stack.__index = Stack

function Stack.new(t)
	return setmetatable(t or {}, Stack)
end

function Stack:Top()
	return self[#self]
end

function Stack:IsEmpty()
	return #self == 0
end

function Stack:Push(val)
	table.insert(self, val)
end

function Stack:Pop()
	table.remove(self, #self)
end

return Stack