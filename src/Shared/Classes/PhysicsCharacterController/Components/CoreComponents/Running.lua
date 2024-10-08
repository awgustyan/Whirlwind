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

local ZERO_VECTOR = Vector3.new(0, 0, 0)

local Running = {}
Running.__index = Running


function Running.new(data : PhysicsCharacterController)
    local self = setmetatable({}, Running)

    local model = data._Model
    local XZ_DRAG_NUMBER = 3
    self._XZ_DRAG_NUMBER = XZ_DRAG_NUMBER
    model:SetAttribute("XZDragFactorVSquared", XZ_DRAG_NUMBER)
    model:SetAttribute("FlatFriction", 500)
    model:SetAttribute("WalkSpeed", 16)

    local attachment = data._CenterAttachment
    local dragForce = Instance.new("VectorForce")
    dragForce.Attachment0 = attachment
    dragForce.Force = Vector3.new()
    dragForce.ApplyAtCenterOfMass = true
    dragForce.RelativeTo = Enum.ActuatorRelativeTo.World
    dragForce.Parent = model
	self.DragForce = dragForce

    local movementForce = Instance.new("VectorForce")
    movementForce.Attachment0 = attachment
    movementForce.ApplyAtCenterOfMass = true
    movementForce.Force = Vector3.new()
    movementForce.RelativeTo = Enum.ActuatorRelativeTo.World
    movementForce.Parent = model
	
	self.RootPart = data.RootPart
	
    self.MovementForce = movementForce

    return self
end

function Running:Update(data : PhysicsCharacterController)

    local hipHeightObject = data:GetComponent("HipHeight")
    assert(hipHeightObject, "Running Component requires HipHeight Component make sure the :Add(HipHeightModuleScript) on Physics Character Controller")
    local onGround = hipHeightObject.OnGround

    local xzSpeed = data._XZ_Speed
    -- local xzVelocity = data._XZ_Velocity
    -- local rootVelocity = data.Velocity
    local moveDirection = data.MoveDirection
    local unitXZ = data._RootPartUnitXZVelocity

    local model = data._Model
    local dragForce = self.DragForce

    local isMoving = unitXZ.X == unitXZ.X and xzSpeed > 0.001 -- NaN check also speed check to avoid very slow speed numbers into formula 1e-19 and such

    local totalDragForce = ZERO_VECTOR

    local flatFrictionScalar
    if onGround and isMoving then
        --This equations allows vector forces to stabilize
        --"Decrease flat friction when low speed"
        --Constant friction when above velocity is above 2 usually
        flatFrictionScalar = model:GetAttribute("FlatFriction")*(1.0-math.exp(-2*xzSpeed))
        totalDragForce += -unitXZ*flatFrictionScalar
    end

    local walkSpeed = model:GetAttribute("WalkSpeed")

    local dragCoefficient = model:GetAttribute("XZDragFactorVSquared")
    local counterActGroundFriction = flatFrictionScalar or model:GetAttribute("FlatFriction")
    local counterActDragFriction = (walkSpeed^2)*dragCoefficient

    --If no drag friction, then no counter ground friction to prevent movement
    if counterActDragFriction <= 0.01 then
        counterActGroundFriction = 0
    end

	local movementForceScalar = math.max(2500, counterActDragFriction + counterActGroundFriction)
	
	if walkSpeed == 0 then
		movementForceScalar = 0
	end
	
	if xzSpeed < walkSpeed or ((self.RootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)) + (moveDirection)).Magnitude < xzSpeed then
		self.MovementForce.Force = moveDirection * movementForceScalar
	else
		self.MovementForce.Force = Vector3.zero
	end
	
    if isMoving then
		local netDragForce = -unitXZ*(xzSpeed^2)*model:GetAttribute("XZDragFactorVSquared")
		
		totalDragForce += netDragForce
	end

	--print("Speed: ",math.round(xzSpeed*100)/100)
	--print("XZVelocity: ", math.round(((self.RootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)) + (moveDirection)).Magnitude * 100) / 100)
    -- print("Drag force: ", math.round(totalDragForce.Magnitude*100)/100)
    -- print("Movement Force: ", math.round(self.MovementForce.Force.Magnitude*100)/100)

    dragForce.Force = totalDragForce

    --handle state
    local stateMachine = data._StateMachine

    if stateMachine.current == "Standing" and isMoving and xzSpeed >= 0.1 then
        stateMachine.run()
    end
    if stateMachine.current == "Running" and xzSpeed < 0.1 then
        stateMachine.stand()
    end
end

function Running:Destroy()
    self.DragForce:Destroy()
    self.MovementForce:Destroy()
end


return Running
