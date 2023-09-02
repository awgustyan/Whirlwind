export type AutoRotate = {
    AlignOrientation : AlignOrientation, --Rootpart
}

export type PhysicsCharacterController = {
    RootPart : BasePart, --Rootpart
    _Model : Model,
    _CenterAttachment : Attachment,
    _MovementComponent : {},
    _XZ_Speed : Vector3,
    _XZ_Velocity : Vector3,
    Velocity : Vector3,
    MoveDirection : Vector3
}

local UIS = game:GetService("UserInputService")
local ZERO_VECTOR = Vector3.zero

local function notNaN(a)
    return a == a
end

local AutoRotate : AutoRotate = {}
AutoRotate.__index = AutoRotate

function AutoRotate.new(PhysicsCharacterController : PhysicsCharacterController)
    local self = setmetatable({}, AutoRotate)
	
	PhysicsCharacterController._CenterAttachment.Name = "CenterAttach"
	
	local alignmentAttachment = Instance.new("Attachment",workspace.Terrain)
	alignmentAttachment.Name = "TerrainAttach"
	
    local alignOrientation = Instance.new("AlignOrientation")

    alignOrientation.Attachment0 = PhysicsCharacterController._CenterAttachment
	alignOrientation.Attachment1 = alignmentAttachment
	alignOrientation.RigidityEnabled = true
    alignOrientation.Parent = PhysicsCharacterController._Model
	
	self.AlignOrientation = alignOrientation
    self._AlignmentAttachment = alignmentAttachment

    --self._Before = CFrame.new()
    --self._After = CFrame.new()
	--self._OverrideCF = nil	

    return self
end

function AutoRotate:Update(PhysicsCharacterController : PhysicsCharacterController)
    local unitXZ = (PhysicsCharacterController._XZ_Velocity).Unit
    local alignmentAttachment = self._AlignmentAttachment
    local moveDirection = PhysicsCharacterController.MoveDirection
	local rootPart = PhysicsCharacterController.RootPart
	
	if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
		local _, y, _ = rootPart.CFrame.Rotation:ToOrientation()
		alignmentAttachment.CFrame = CFrame.fromOrientation(0, y, 0)
		return
	end
	
	if moveDirection.Magnitude > 0 then
		alignmentAttachment.CFrame = CFrame.lookAt(ZERO_VECTOR, moveDirection)
	else
		--Maintain current orientation
		local _, y, _ = rootPart.CFrame.Rotation:ToOrientation()
		alignmentAttachment.CFrame = CFrame.fromOrientation(0, y, 0)
	end
    
   -- alignmentAttachment.CFrame = self._Before*alignmentAttachment.CFrame*self._After
    -- debugPart.CFrame = alignmentAttachment.CFrame.Rotation + rootPart.CFrame.Position + Vector3.new(0,5,0)
end

function AutoRotate:Destroy()
    self._AlignmentAttachment:Destroy()
    self.AlignOrientation:Destroy() 
end

return AutoRotate
