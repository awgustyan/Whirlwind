--[[
    Class that handles movement components
    Mostly used for storing data required such as root part and model
    Also can handle input

    MIT License

    Copyright (c) 2022 dthecoolest

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Uses FSM module version from Daniel Perez Alvarez:
    
    MIT License from that project:
    https://github.com/unindented/lua-fsm
    Copyright (c) 2016 Daniel Perez Alvarez

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
]]
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local fsm = require(script.fsm)
local XZ_VECTOR = Vector3.new(1,0,1)
local ZERO_VECTOR = Vector3.zero

local COMPONENTS_FOLDER : Folder = script.Components
local CORE_COMPONENTS_FOLDER : Folder = COMPONENTS_FOLDER.CoreComponents
local CORE_MOVEMENT_COMPONENTS_ARRAY = CORE_COMPONENTS_FOLDER:GetChildren()

local Signal = require(script.Signal)

export type PhysicsCharacterController = {
    RootPart : BasePart, --Rootpart
    _Model : Model,
    _CenterAttachment : Attachment,
    _MovementComponents : {},
    _XZ_Speed : Vector3,
    _XZ_Velocity : Vector3,
    Velocity : Vector3,
    MoveDirection : Vector3
}

local function setPartFriction(part, friction, frictionWeight)
	local partProperties = part.CustomPhysicalProperties or PhysicalProperties.new(part.Material)
	local a, b, c, d, e =
		partProperties.Density, partProperties.Friction, partProperties.Elasticity, partProperties.FrictionWeight, partProperties.ElasticityWeight

        b = friction
        d = frictionWeight
	part.CustomPhysicalProperties = PhysicalProperties.new(a, b, c, d, e)
end


local PhysicsCharacterController : PhysicsCharacterController = {}
PhysicsCharacterController.__index = PhysicsCharacterController

function PhysicsCharacterController.new(rootPart : BasePart, humanoid : Humanoid?)
    local self = setmetatable({}, PhysicsCharacterController)

    local model = rootPart:FindFirstAncestorOfClass("Model")
    assert(model, "Rootpart should have a model")
    self._Model = model

    local descendants = model:GetDescendants()
    for i, v : BasePart in pairs(descendants) do
        if v:IsA("BasePart") then
            setPartFriction(v, 0, 9999999)
        end
    end
    --Doesn't do much for sliding

    self.RootPart = rootPart
    
    local charEvents = {
        {name = "run",  from = "Standing",  to = "Running"},
        {name = "jump", from = "Standing", to = "Jumping"   },
        {name = "leap", from = "Running", to = "Jumping"   },
        {name = "fall",  from = "Jumping",    to = "FreeFalling"},
        {name = "land", from = "FreeFalling", to = "Landed" },
        {name = "recover", from = "Landed", to = "Standing" },
        {name = "stand",  from = "Running",  to = "Standing"},
    } 

    local StateSignal = {}

    for _, event in pairs(charEvents) do
        local signal = Signal.new()
        local state = event.to
        StateSignal[state] = signal
    end

    self._StateSignals = StateSignal

    local charCallbacks = {}

    for state : string, signal in pairs(StateSignal) do
        charCallbacks["on_"..state] = function(self, event, from, to)
            if state == "Running" then
                local speedVector = rootPart.AssemblyLinearVelocity*XZ_VECTOR
                signal:Fire(speedVector.Magnitude)
                return
            end
            signal:Fire()
        end
    end

    self._StateMachine = fsm.create({
		initial = "Standing",
		events = charEvents,
		callbacks = charCallbacks
	})

    self._RunLoop = true
    task.spawn(function()
        while model.Parent ~= nil and self._RunLoop do
            if  self._StateMachine.current == "Running" then
                local speedVector = rootPart.AssemblyLinearVelocity*XZ_VECTOR
                StateSignal.Running:Fire(speedVector.Magnitude)
            end
            
            RunService.Heartbeat:Wait()
        end
    end)


    self._ValidJumpingStates = {
        Standing = true;
        Running = true;
    }
    
    local centerAttachment = Instance.new("Attachment")
    centerAttachment.WorldPosition = rootPart.CenterOfMass
    centerAttachment.Parent = rootPart
    self._CenterAttachment = centerAttachment
        
    --XZ Movement
    

    self._MovementComponents = {}
    return self
end

function PhysicsCharacterController:AddComponent(componentModuleOrString : ModuleScript?)
    local componentModule : ModuleScript
    if typeof(componentModuleOrString) == "string" then
        componentModule = script:FindFirstChild(componentModuleOrString, true)
        assert(componentModule, "Component module cannot be found! Please check Components folder")
    end
    if typeof(componentModuleOrString) == "Instance" then
        componentModule = componentModuleOrString
    end

    local componentInitializer = require(componentModule)

    local component = componentInitializer.new(self)
    component.Name = componentModule.Name
    component.ShouldUpdate = true

    self._MovementComponents[componentModule.Name] = component

end

function PhysicsCharacterController:RemoveComponent(componentName : string)

    local existingComponent = self._MovementComponents[componentName]
    existingComponent:Destroy()
    self._MovementComponents[componentName] = nil

end

function PhysicsCharacterController:GetComponent(nameOfComponentModule)
    return self._MovementComponents[nameOfComponentModule]
end

function PhysicsCharacterController:AddCoreComponents()
    for name, movementComponentObject in pairs(CORE_MOVEMENT_COMPONENTS_ARRAY) do

        self:AddComponent(movementComponentObject)
    end
end

function PhysicsCharacterController:Update(moveDirection : Vector3, deltaTime)
    local rootPart = self.RootPart
	local rootVelocity = rootPart.AssemblyLinearVelocity
	local xzVelocity = rootVelocity*XZ_VECTOR
	local xzSpeed = xzVelocity.Magnitude
	local unitXZ = (xzVelocity).Unit

    self._XZ_Speed = xzSpeed
    self._XZ_Velocity = xzVelocity
    self._RootPartUnitXZVelocity = unitXZ
    self.Velocity = rootVelocity
    self.MoveDirection = moveDirection

    for i, component in pairs(self._MovementComponents) do
        if component.Update and component.ShouldUpdate then
            component:Update(self, deltaTime)
        end
    end

end

function PhysicsCharacterController:Run()
    local PlayerModule = require(game.Players.LocalPlayer.PlayerScripts.PlayerModule)
    local humanoid = self._Model:FindFirstChild("Humanoid")
	local Controls = PlayerModule:GetControls()
	
    local connection
    local camera = workspace.CurrentCamera

    connection = RunService.Stepped:Connect(function(time, deltaTime)
        if self._Model.Parent == nil then
            --Automatic clean up upon character respawn
            connection:Disconnect()
		end
		
		local vector = Controls:GetMoveVector()
        local movementMagnitude = math.clamp(vector.Magnitude, 0, 1)
        local moveDirection = camera.CFrame:VectorToWorldSpace(vector)*Vector3.new(1,0,1)
        if moveDirection.Magnitude > 0.01 then
            moveDirection = moveDirection.Unit
        end
        self:Update(moveDirection*movementMagnitude, deltaTime)
    end)
end

function PhysicsCharacterController:ConnectComponentsToInput()
    local movementComponents = self._MovementComponents

    for _, componentObject in pairs(movementComponents) do
        if componentObject.UseJumpRequest then
            local jumpConnection 
            jumpConnection = UserInputService.JumpRequest:Connect(function()
                if self._Model.Parent == nil then
                    --Automatic clean up upon character respawn
                    jumpConnection:Disconnect()
                end
                componentObject:InputBegan()
            end)        
        end

        if componentObject.KeyCodes then
            local testFunction = function(actionName, inputState, inputObject)
                if inputState == Enum.UserInputState.Begin then
                    componentObject:InputBegan()
                end
                if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
                    componentObject:InputEnd()
                end

                return Enum.ContextActionResult.Sink
            end
            ContextActionService:BindAction(componentObject.Name, testFunction, true, table.unpack(componentObject.KeyCodes))
        end
        
        if componentObject.UserInputTypes then
            local testFunction = function(actionName, inputState, inputObject)
                if inputState == Enum.UserInputState.Begin then
                    componentObject:InputBegan()
                end
                if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
                    componentObject:InputEnd()
                end

                return Enum.ContextActionResult.Sink
            end
            ContextActionService:BindAction(componentObject.Name, testFunction, true, table.unpack(componentObject.UserInputTypes))
        end

    end
end

--To do add
function PhysicsCharacterController:Destroy()

    for i, componentObject in pairs(self._MovementComponents) do
        componentObject:Destroy()
    end

    self._CenterAttachment:Destroy()

    self._RunLoop = false
    
    for state : string, signal in pairs(self._StateSignals) do
        signal:DisconnectAll()
    end

end


return PhysicsCharacterController
