local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local UISBinds = require(ReplicatedStorage.Shared.Modules:WaitForChild("UserInputBind"));
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Stack = require(ReplicatedStorage.Shared.Modules.Stack)
local WeightQueue = require(ReplicatedStorage.Shared.Modules.WeightQueue)

local Movement = {}
Movement.__index = Movement

-- Functions --

local function vectorDirectionWASD(inputObjects)
	local sumDirection = Vector3.zero

	local KeyDirection = {
		[Enum.KeyCode.W] = Vector3.new(0, 0, -1),
		[Enum.KeyCode.A] = Vector3.new(-1 ,0, 0),
		[Enum.KeyCode.S] = Vector3.new(0, 0, 1),
		[Enum.KeyCode.D] = Vector3.new(1, 0, 0),
	}

	for _, inputObject in pairs(inputObjects) do
		if not KeyDirection[inputObject.KeyCode] then
			continue
		end

		sumDirection += KeyDirection[inputObject.KeyCode]
	end

	if sumDirection.Magnitude <= 0 then
		return Vector3.new(0, 0, -1)
	end

	return CFrame.new(Vector3.zero, sumDirection).LookVector
end

local function isPressed(keyCode)
	for _, inputObject in pairs(UIS:GetKeysPressed()) do
		if inputObject.KeyCode == keyCode then
			return true
		end
	end
	
	return false
end

-- Class --

function Movement.new(Player : Player, PhysicsController)
	local self = {}
	setmetatable(self, Movement)
	
	self._trove = Trove.new()
	
	-- Knit and classes
	
	self.CharacterService = Knit.GetService("CharacterService")
	self.InterfaceController = Knit.GetController("InterfaceController")
	self.VFXService = Knit.GetService("VFXService")
	self.VFXController = Knit.GetController("VFXController")
	
	self.PhysicsController = PhysicsController
	self.HipHeightObject = self.PhysicsController:GetComponent("HipHeight")
	
	-- Player parts and setup

	self.Player = Player
	self.Character = Player.Character
	self.Humanoid = Player.Character:WaitForChild("Humanoid")
	self.HRT = Player.Character:WaitForChild("HumanoidRootPart")
	self.Camera = workspace.CurrentCamera
	
	-- Physics
	
	self.FrictionWeightQueue = WeightQueue.new()
	self.DragWeightQueue = WeightQueue.new()
	
	-- Speed
	
	self.BaseSpeed = 30
	self.MaxSpeed = 60
	
	self._speed = self.BaseSpeed
	self._Speed = self.BaseSpeed
	
	self.DisabledSpeedTimeLeft = 0 -- Seconds
	self.DisabledSpeedStack = Stack.new()
	
	-- Jump
	
	self.BaseJumpPower = 65
	self.MaxJumpPower = 200
	
	self._jumpPower = self.BaseJumpPower
	self._JumpPower = self._jumpPower
		
	self.DisabledJumpTimeLeft = 0 -- Seconds
	self.DisabledJumpStack = Stack.new()
	
	-- AutoRotate
	
	self.DisabledAutoRotateStack = Stack.new()
	
	-- Stamina
	
	self.MaxStamina = 3
	self.StaminaRegainSpeed = 1 -- bars / seconds
	
	self._stamina = 0
	
	-- RootJoint

	self.RootJointTimeLeft = 0
	self.RootJointRadiansRotation = 0
	
	-- FOV 

	self.BaseFOV = 80
	self.FOVTimeLeft = 0
	self.FOV = self.BaseFOV
	
	-- Animation Tracks
	
	self._movementTrack = nil
	
	-- ABILITIES --	
	
	self.AbilityInfo = {
		Dash = {
			KeyBinds = {Enum.KeyCode.RightShift, Enum.KeyCode.LeftShift},
			DBDuration = 0,
			Duration = 0.15, -- Seconds
			Speed = 120, -- Units / Seconds
			StartingBoost = 25,

			_order = 1,
			_db = false,
		},
		Jump = {
			KeyBinds = {Enum.KeyCode.Space},
			DBDuration = 0,
			
			_active = false,
			_db = false,
		},
		Landing = {
			DBDuration = 0,
			JumpDisableTime = 0.4,
			
			_previousOnGround = true,
			_db = false,
		},
		Slam = {
			DBDuration = 0.3,
			SlamSpeed = 140,
			
			_slamEnding = false,
			_active = false,
			_heartbeatConnection = nil,
			_db = false,
		},
		Slide = {
			KeyBinds = {Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl},
			DBDuration = 0,
			StartingBoost = 35,
			MinimalHorizontalSpeed = 40, -- Units / Seconds,
			
			_active = false,
			_alignOrientation = nil,
			_heartbeatConnection = nil,
			_db = false,
		}
	}
	
	self:_bindAbilities()
	
	return self
end

function Movement:_bind(AbilityName, KeyBinds, Function)
	UISBinds:BindToInput(AbilityName, KeyBinds, Function)
	
	self._trove:Add(function()
		UISBinds:UnbindAction(AbilityName)
	end)
end

function Movement:_bindAbilities()
	self:_bind("Dash", self.AbilityInfo.Dash.KeyBinds, function(actionName, userInputState, input)
		if userInputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass;
		end

		self:Dash(vectorDirectionWASD(UIS:GetKeysPressed()))

		return Enum.ContextActionResult.Sink;
	end);
	
	self:_bind("Jump", self.AbilityInfo.Jump.KeyBinds, function(actionName, userInputState, input)
		if userInputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass;
		end

		self:Jump(vectorDirectionWASD(UIS:GetKeysPressed()))

		return Enum.ContextActionResult.Sink;
	end);
	
	self:_bind("Slide", self.AbilityInfo.Slide.KeyBinds, function(actionName, userInputState, input)
		if userInputState == Enum.UserInputState.Begin then
			self:SlideStart(vectorDirectionWASD(UIS:GetKeysPressed()))
			self:SlamStart()
			return Enum.ContextActionResult.Sink;
		end
		
		if userInputState == Enum.UserInputState.End then
			self:SlideEnd(true)
			return Enum.ContextActionResult.Sink;
		end

		return Enum.ContextActionResult.Pass;
	end);
end

function Movement:Update(dt)
	
	if self.HipHeightObject.OnGround and not self.AbilityInfo.Jump._active then
		if not self.FrictionWeightQueue:IsEmpty() then
			self.Character:SetAttribute("FlatFriction", self.FrictionWeightQueue:Top())
		else
			self.Character:SetAttribute("FlatFriction", 1000)
		end
		
		if not self.DragWeightQueue:IsEmpty() then
			self.Character:SetAttribute("XZDragFactorVSquared", self.DragWeightQueue:Top())
		else
			self.Character:SetAttribute("XZDragFactorVSquared", 3)
		end
	else
		self.Character:SetAttribute("XZDragFactorVSquared", 0)
		self.Character:SetAttribute("FlatFriction", 0)
	end
	
	-- Speed

	if self.DisabledSpeedTimeLeft <= 0 and self.DisabledSpeedStack:IsEmpty() then
		self.Character:SetAttribute("WalkSpeed", self._speed)
	else
		self.Character:SetAttribute("WalkSpeed", 0)
	end
	
	self.DisabledSpeedTimeLeft = math.clamp(self.DisabledSpeedTimeLeft - dt, 0, 120)
	
	-- Jump
	
	if self.DisabledJumpTimeLeft <= 0 and self.DisabledJumpStack:IsEmpty() then
		self.Character:SetAttribute("JumpPower", self._jumpPower * 10)
	else
		self.Character:SetAttribute("JumpPower", 0)
	end

	self.DisabledJumpTimeLeft = math.clamp(self.DisabledJumpTimeLeft - dt, 0, 120)
	
	-- AutoRotate
	
	if self.DisabledAutoRotateStack:IsEmpty() then
		self.Humanoid.AutoRotate = true
	else
		self.Humanoid.AutoRotate = false
	end
	
	-- Stamina
	
	if self._stamina + (self.StaminaRegainSpeed * dt) > self.MaxStamina then
		self._stamina += (self.StaminaRegainSpeed * dt) + self.MaxStamina - (self._stamina + (self.StaminaRegainSpeed * dt))
	else
		self._stamina += self.StaminaRegainSpeed * dt
	end
	
	-- RootJoint
	
	if self.RootJointTimeLeft > 0 then
		local Info = {
			Character = self.Character,
			Player = self.Player,
			RootJointRotation = self.RootJointRadiansRotation,
		}
		
		self.VFXController:ClientVFX("RotateRootJoint", Info)
		self.CharacterService.AbilityRemote:Fire("RotateRootJoint", Info)
	else
		local Info = {
			Character = self.Character,
			Player = self.Player,
			RootJointRotation = -math.pi,
		}
		
		self.VFXController:ClientVFX("RotateRootJoint", Info)
		self.CharacterService.AbilityRemote:Fire("RotateRootJoint", Info)
	end
	
	self.RootJointTimeLeft = math.clamp(self.RootJointTimeLeft - dt, 0, 120)
	
	-- FOV

	self.FOVTimeLeft = math.clamp(self.FOVTimeLeft - dt, 0, 120)

	if self.FOVTimeLeft > 0 then
		TweenService:Create(self.Camera, TweenInfo.new(0.01, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = self.FOV}):Play()
	else
		local extraVelocityFOV = math.clamp((math.sqrt(self.HRT.Velocity.Magnitude) * 0.7) - 1, 0, 50)

		TweenService:Create(self.Camera, TweenInfo.new(0.01, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = self.BaseFOV + extraVelocityFOV}):Play()
	end
	
	-- Abilities
	
	if self.AbilityInfo.Landing._previousOnGround == false and self.HipHeightObject.OnGround then
		self:Landing()
	end
	
	self.AbilityInfo.Landing._previousOnGround = self.HipHeightObject.OnGround
	
	-- UI
	
	self.InterfaceController.Info.Stamina = self._stamina
	self.InterfaceController.Info.MaxStamina = self.MaxStamina
end

function Movement:Destroy()
	self._trove:Destroy()	
	self = nil
end

-- Abilities --

function Movement:Dash(DirectionVector)
	
	local AbilityInfo = self.AbilityInfo.Dash

	local cameraDirection = CFrame.new(Vector3.zero, self.Camera.CFrame.LookVector * Vector3.new(1, 0, 1)):VectorToWorldSpace(DirectionVector)
	
	-- Debounce and stamina
	
	if AbilityInfo._db then
		return
	end
	
	if self._stamina < 1 then
		return
	end
	
	self._stamina += -1
	AbilityInfo._db = true
	
	task.delay(AbilityInfo.DBDuration, function()
		AbilityInfo._db = false
	end)
	
	-- Cancel other moves
	
	AbilityInfo._active = true

	task.delay(0.1, function()
		AbilityInfo._active = false
	end)
	
	self:SlideEnd()
	self:SlamEnd()
	
	-- Fire server
	
	self.CharacterService.AbilityRemote:Fire("Dash", {
		cameraDirection = cameraDirection
	})
	
	self.VFXController:ClientVFX("Dash", {
		cameraDirection = cameraDirection,
		Character = self.Character
	})
	
	-- Animation
	
	local animation = Instance.new("Animation")
	
	if AbilityInfo._order == 1 then
		animation.AnimationId = "rbxassetid://14388368580"
	else
		animation.AnimationId = "rbxassetid://14388180703"
	end

	AbilityInfo._order = ((AbilityInfo._order) % 2) + 1
	
	if self._movementTrack then
		self._movementTrack:Stop()
	end
	
	self._movementTrack = self.Humanoid:LoadAnimation(animation)
	self._movementTrack:Play(0, AbilityInfo._order, 1.4)
	
	-- Rotate the player in the dash direction

	if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
		self.RootJointRadiansRotation = math.atan2(DirectionVector.X, DirectionVector.Z)
		self.RootJointTimeLeft = AbilityInfo.Duration + 0.1
	end
	
	-- Move task
	
	self.HRT.AssemblyLinearVelocity = Vector3.zero
	
	task.spawn(function()
		local accumulated = 0
		
		self.DisabledSpeedTimeLeft += AbilityInfo.Duration
		
		while accumulated < AbilityInfo.Duration do
			local dt = RunService.Heartbeat:Wait()

			if AbilityInfo.Duration - (accumulated + dt) < 0 then
				dt += AbilityInfo.Duration - (accumulated + dt)
			end

			accumulated += dt
			
			self.HRT.CFrame += cameraDirection * AbilityInfo.Speed * dt
		end
	end)
end

function Movement:Jump(DirectionVector)

	local AbilityInfo = self.AbilityInfo.Jump
	
	local cameraDirection = CFrame.new(Vector3.zero, self.Camera.CFrame.LookVector * Vector3.new(1, 0, 1)):VectorToWorldSpace(DirectionVector)
	
	-- Debounce and stamina
	
	if not self.HipHeightObject.OnGround then
		return
	end
	
	if AbilityInfo._db then
		return
	end

	AbilityInfo._db = true

	task.delay(AbilityInfo.DBDuration, function()
		AbilityInfo._db = false
	end)
	
	AbilityInfo._active = true

	task.delay(0.1, function()
		AbilityInfo._active = false
	end)

	-- Fire server

	self.CharacterService.AbilityRemote:Fire("Jump", {

	})

	self.VFXController:ClientVFX("Jump", {
		Character = self.Character
	})

	-- Cancel other moves
	
	if self.AbilityInfo.Dash._active and self._stamina > 1 then
		self._stamina += -1
		
		self.HRT.AssemblyLinearVelocity += Vector3.new(0, 60, 0)
		
		task.spawn(function()
			RunService.Heartbeat:Wait()
			
			self.HRT.AssemblyLinearVelocity += cameraDirection * 60
		end)
	elseif self.AbilityInfo.Slide._active then
		self.HRT.AssemblyLinearVelocity += Vector3.new(0, self._jumpPower, 0)

		task.spawn(function()
			RunService.Heartbeat:Wait()

			self.HRT.AssemblyLinearVelocity += cameraDirection * 15
		end)
	else
		self.HRT.AssemblyLinearVelocity += Vector3.new(0, self._jumpPower, 0)
	end
	
	self:SlideEnd(false)
	
	-- Animation

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://14436562714"

	if self._movementTrack then
		self._movementTrack:Stop()
	end

	self._movementTrack = self.Humanoid:LoadAnimation(animation)
	self._movementTrack:Play()
end

function Movement:Landing()
	local AbilityInfo = self.AbilityInfo.Landing

	-- Debounce and stamina

	if not self.HipHeightObject.OnGround then
		return
	end

	if AbilityInfo._db then
		return
	end

	AbilityInfo._db = true

	task.delay(AbilityInfo.DBDuration, function()
		AbilityInfo._db = false
	end)

	-- Cancel other moves

	-- Fire server
	
	if not self.AbilityInfo.Slam._slamEnding then
		self.CharacterService.AbilityRemote:Fire("Landing", {

		})

		self.VFXController:ClientVFX("Landing", {
			Character = self.Character
		})
	end

	-- Animation

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://14443686855"

	if not self._movementTrack or not self._movementTrack.IsPlaying then
		self._movementTrack = self.Humanoid:LoadAnimation(animation)
		self._movementTrack:Play(0, 1, 1.6)
	end
end

function Movement:SlamStart()

	local AbilityInfo = self.AbilityInfo.Slam

	-- Debounce and stamina

	if self.HipHeightObject.OnGround then
		return
	end
	
	if AbilityInfo._active then
		return
	end

	if AbilityInfo._db then
		return
	end

	AbilityInfo._db = true

	task.delay(AbilityInfo.DBDuration, function()
		AbilityInfo._db = false
	end)

	if AbilityInfo._heartbeatConnection then
		AbilityInfo._heartbeatConnection:Disconnect()
	end

	-- Animation

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://14506958374"

	if self._movementTrack then
		self._movementTrack:Stop()
	end

	self._movementTrack = self.Humanoid:LoadAnimation(animation)
	self._movementTrack:Play()

	-- VFX

	self.CharacterService.AbilityRemote:Fire("SlamStart", {
	})

	self.VFXController:ClientVFX("SlamStart", {
		Player = self.Player,
		Character = self.Character,
	})

	-- Disable movement
	
	self.DisabledSpeedStack:Push(true)
	self.DisabledJumpStack:Push(true)

	-- Move connection

	AbilityInfo._active = true

	AbilityInfo._heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		if self.HipHeightObject.OnGround then
			self:SlamEnd()
			return
		end
		
		self.HRT.AssemblyLinearVelocity = Vector3.new(0, -AbilityInfo.SlamSpeed, 0)
	end)
end

function Movement:SlamEnd()

	local AbilityInfo = self.AbilityInfo.Slam
	
	if not AbilityInfo._active then
		return
	end
	
	local IsHeavy = isPressed(Enum.KeyCode.LeftControl) or isPressed(Enum.KeyCode.RightControl)
	
	if self._stamina < 1 then
		IsHeavy = false
	end
	
	if IsHeavy then
		self._stamina -= 1
	end
	
	-- Fire server
	
	AbilityInfo._slamEnding = true
	
	task.spawn(function()
		RunService.Heartbeat:Wait()

		AbilityInfo._slamEnding = false
	end)

	self.CharacterService.AbilityRemote:Fire("SlamEnd", {
		IsHeavy = IsHeavy,
		Landed = self.HipHeightObject.OnGround
	})

	self.VFXController:ClientVFX("SlamEnd", {
		Character = self.Character,
		Player = self.Player,
		IsHeavy = IsHeavy,
		Landed = self.HipHeightObject.OnGround
	})

	-- Animation

	if self._movementTrack and AbilityInfo._active then
		self._movementTrack:Stop()
	end

	-- Enable movement
	
	self.DisabledJumpStack:Pop()
	self.DisabledSpeedStack:Pop()
	
	AbilityInfo._active = false

	if AbilityInfo._heartbeatConnection then
		AbilityInfo._heartbeatConnection:Disconnect()
	end
	
	self.HRT.AssemblyLinearVelocity *= Vector3.new(1, 0, 1)
end

function Movement:SlideStart(DirectionVector)

	local AbilityInfo = self.AbilityInfo.Slide
	
	local cameraDirection = CFrame.new(Vector3.zero, self.Camera.CFrame.LookVector * Vector3.new(1, 0, 1)):VectorToWorldSpace(DirectionVector)

	-- Debounce and stamina
	
	if not self.HipHeightObject.OnGround then
		return
	end
	
	if AbilityInfo._db then
		return
	end
	
	if AbilityInfo._active then
		return
	end

	AbilityInfo._db = true

	task.delay(AbilityInfo.DBDuration, function()
		AbilityInfo._db = false
	end)
	
	if AbilityInfo._alignOrientation then
		AbilityInfo._alignOrientation:Destroy()
	end
	
	if AbilityInfo._heartbeatConnection then
		AbilityInfo._heartbeatConnection:Disconnect()
	end

	-- Animation

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://14423572699"
	
	if self._movementTrack then
		self._movementTrack:Stop()
	end

	self._movementTrack = self.Humanoid:LoadAnimation(animation)
	self._movementTrack:Play()
	
	if UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		self.HRT.CFrame = CFrame.new(Vector3.new(), cameraDirection) + self.HRT.Position
	end
	
	-- VFX
	
	self.CharacterService.AbilityRemote:Fire("SlideStart", {
		cameraDirection = cameraDirection
	})

	self.VFXController:ClientVFX("SlideStart", {
		cameraDirection = cameraDirection,
		Player = self.Player,
		Character = self.Character,
	})
	
	-- Disable movement
	
	self.StaminaRegainSpeed = 0
	
	self.DisabledSpeedStack:Push(true)
	self.DisabledJumpStack:Push(true)
	self.DisabledAutoRotateStack:Push(true)
	
	-- Move connection
	
	self.FrictionWeightQueue:Add("Slide", 5, 0)
	self.DragWeightQueue:Add("Slide", 5, 0)

	local adjustedDirection = self.HRT.CFrame:VectorToWorldSpace(DirectionVector)
	
	AbilityInfo._active = true
	
	self.HRT.AssemblyLinearVelocity  += Vector3.new(adjustedDirection.X, 0, adjustedDirection.Z) * AbilityInfo.StartingBoost
	
	AbilityInfo._alignOrientation = Instance.new("AlignOrientation", self.HRT)
	AbilityInfo._alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	AbilityInfo._alignOrientation.CFrame = self.HRT.CFrame
	AbilityInfo._alignOrientation.Attachment0 = self.HRT.RootAttachment
	AbilityInfo._alignOrientation.RigidityEnabled = true
	
	AbilityInfo._heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		-- Rotate the player in the dash direction
		
		if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
			self.RootJointRadiansRotation = math.atan2(DirectionVector.X, DirectionVector.Z)
			self.RootJointTimeLeft = dt
		end
		
		local horizontalSpeed = Vector3.new(self.HRT.AssemblyLinearVelocity.X, 0, self.HRT.AssemblyLinearVelocity.Z).Magnitude
		
		if horizontalSpeed < AbilityInfo.MinimalHorizontalSpeed then
			self.HRT.AssemblyLinearVelocity = Vector3.new(cameraDirection.X * AbilityInfo.MinimalHorizontalSpeed, self.HRT.AssemblyLinearVelocity.Y, cameraDirection.Z * AbilityInfo.MinimalHorizontalSpeed)
		end
		
	end)
end

function Movement:SlideEnd(RemoveVelocity)

	local AbilityInfo = self.AbilityInfo.Slide

	-- Debounce and stamina
	
	if not AbilityInfo._active then
		return
	end
	
	-- Fire server

	self.CharacterService.AbilityRemote:Fire("SlideEnd", {

	})

	self.VFXController:ClientVFX("SlideEnd", {
		Character = self.Character,
		Player = self.Player,
	})

	-- Animation

	if self._movementTrack and AbilityInfo._active then
		self._movementTrack:Stop()
	end

	-- Enable movement
	
	if AbilityInfo._alignOrientation then
		AbilityInfo._alignOrientation:Destroy()
	end
	
	self.StaminaRegainSpeed = 1
	
	self.DisabledJumpStack:Pop()
	self.DisabledSpeedStack:Pop()
	self.DisabledAutoRotateStack:Pop()
	
	AbilityInfo._active = false
	
	self.FrictionWeightQueue:Remove("Slide")
	self.DragWeightQueue:Remove("Slide")
	
	if AbilityInfo._heartbeatConnection then
		AbilityInfo._heartbeatConnection:Disconnect()
	end
	
	if self.HipHeightObject.OnGround and (RemoveVelocity and not self.AbilityInfo.Jump._active) then
		self.HRT.Velocity  = Vector3.zero
	end
end

return Movement
