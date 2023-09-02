--[[
Mouse Module
	Created by: BRicey763
	
This module is used to replace the standard player:GetMouse(), since it is basically deprecated 

API: 
- Most of the time, you will use GetUnitRay() and send this data to the server for a raycast 
- GetPosition(), GetTarget(), and Raycast() are all useful, but unsecure and would not be consistent in a real game; it is useful for debugging and small projects, though 
- Note the optional RaycastParams, can be useful when whitelisting/blacklisting something 
- LeftClick and RightClick events are there for convenience, use UserInputService or ContextActionService instead 

]]


local UserInputService = game:GetService("UserInputService")	
local RunService = game:GetService("RunService")

local MAX_DISTANCE : number = 500 

local cam : Camera = workspace.CurrentCamera

local Mouse = {}

local leftClick : BindableEvent = Instance.new("BindableEvent")
local rightClick : BindableEvent = Instance.new("BindableEvent")

--References to bindable events that act similarly to the original mouse 
Mouse.LeftClick = leftClick.Event 
Mouse.RightClick = rightClick.Event

function Mouse.GetUnitRay() : Ray
	--Get position of mouse on screen 
	local x : number, y : number = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y

	--Convert that to a unit ray pointing towards the camera CFrame 
	local ray : Ray = cam:ViewportPointToRay(x, y)	
	
	return ray 
end

function Mouse.Raycast(rayParams : RaycastParams?) : (RaycastResult?, Ray) 
	local unitRay : Ray = Mouse.GetUnitRay()
	
	--Raycast from the origin to max dist 
	local result : RaycastResult? = workspace:Raycast(unitRay.Origin, unitRay.Direction * MAX_DISTANCE, rayParams)
	
	--Give them the RaycastResult and Unit Ray, if they need it  
	return result, unitRay
end

function Mouse.GetPosition(rayParams : RaycastParams?) : Vector3
    --Get the current Mouse Position, either as a raycastResult or Ray 
    local raycast : RaycastResult?, unitRay : Ray = Mouse.Raycast(rayParams)

    --Return the appropriate value 
	if raycast then 
		--The raycast was successful, so we can just get the position 
        return raycast.Position 
	elseif unitRay then 
		--Raycast was not successful, we need to manually calculate the intended position 
        return unitRay.Origin + unitRay.Direction * MAX_DISTANCE
    end
end

function Mouse.GetTarget(rayParams : RaycastParams?) : Instance?
	--Call the raycast, forwarding the rayParams object 
	local raycast : RaycastResult, unitRay : Ray = Mouse.Raycast(rayParams)
	
	--Give them target if it exists 
    return raycast and raycast.Instance
end


function Mouse._OnInput(obj : InputObject)
    if obj.UserInputType == Enum.UserInputType.MouseButton1 then 
        leftClick:Fire(obj.UserInputState)
    elseif obj.UserInputType == Enum.UserInputType.MouseButton2 then 
        rightClick:Fire(obj.UserInputState)
    end  
end

function Mouse.GetVelocity()
	local oldHit = Mouse.GetPosition()
	RunService.RenderStepped:Wait()
	return Mouse.GetPosition() - oldHit
end

function Mouse.HitChanged()
	
	local clone = Instance.new("BindableEvent")

	local oldVel = CFrame.new()
	RunService.RenderStepped:Connect(function()
		local newVel =  Mouse:GetVelocity()
		if newVel ~= oldVel then
			clone:Fire(oldVel)
		end
		oldVel = newVel
	end) 

	return clone.Event
end

UserInputService.InputBegan:Connect(Mouse._OnInput)
UserInputService.InputEnded:Connect(Mouse._OnInput)

return Mouse
