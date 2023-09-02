local UIS = game:GetService("UserInputService");

--

local uisBinds = {};
local uisBinds_mt = {__index = uisBinds};

function uisBinds.new()
	local self = {};
	
	self.connections = {};
	
	return setmetatable(self, uisBinds_mt);
end

--

function uisBinds:BindToInput(actionName, binds, func)
	self.connections[actionName] = {}
	
	for i = 1, #binds do
		local keycode = binds[i];
		self.connections[actionName][keycode] = {
			UIS.InputBegan:Connect(function(input, process)
				if (input.KeyCode == keycode) then
					func(actionName, input.UserInputState, input);
				end
			end),
			
			UIS.InputChanged:Connect(function(input, process)
				if (input.KeyCode == keycode) then
					func(actionName, input.UserInputState, input);
				end
			end),
			
			UIS.InputEnded:Connect(function(input, process)
				if (input.KeyCode == keycode) then
					func(actionName, input.UserInputState, input);
				end
			end)
		}
	end
end

function uisBinds:UnbindAction(actionName)
	if not self.connections[actionName] then
		return
	end
	
	for keycode, array in next, self.connections[actionName] do
		for i = 1, #array do
			array[i]:Disconnect();
		end
	end
	
	self.connections[actionName] = nil;
end

--

return uisBinds.new();