local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Assets = ReplicatedStorage.VFXAssets
local Sounds = ReplicatedStorage.SFXAssets

local VFX = {}
VFX.__index = VFX

-- Functions

local function switchEmitters(Part : Instance, State : boolean)
	for i, v in Part:GetDescendants() do
		if v.ClassName == "ParticleEmitter" then
			v.Enabled = State
		end
	end
end

-- Class

function VFX.new()
	local self = {}
	setmetatable(self, VFX)
	
	self.AbilityInfo = {
		Slide = {
			_heartbeatConnection = nil
		},
		Slam = {
			_heartbeatConnection = nil
		}
	}
	
	self.CachedInfo = {

	}
	
	Players.PlayerAdded:Connect(function(Player)
		if not self.CachedInfo[Player] then
			self.CachedInfo[Player] = table.clone(self.AbilityInfo)
		end
	end)
	
	Players.PlayerRemoving:Connect(function(Player)
		if self.CachedInfo[Player] then
			self.CachedInfo[Player] = nil
		end
	end)
	
	return self
end

function VFX:RotateRootJoint(InfoTable)
	
	--[[
	InfoTable = {
		Character = Character,
		RootJointRotation = Radians,
	}
	]]
	
	if not InfoTable.Character then
		return
	end
	
	if not InfoTable.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	if not InfoTable.Character.HumanoidRootPart:FindFirstChild("RootJoint") then
		return
	end
	
	RunService.Stepped:Wait()
	
	InfoTable.Character.HumanoidRootPart.RootJoint.C0 = CFrame.fromEulerAnglesYXZ(-math.pi / 2, InfoTable.RootJointRotation, 0)
	
	--TweenService:Create(InfoTable.Character.HumanoidRootPart.RootJoint, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = CFrame.fromEulerAnglesYXZ(-math.pi / 2, InfoTable.Radians, 0)}):Play()
end

function VFX:Dash(InfoTable)

	--[[
	InfoTable = {
		Player = Player
		Character = Character,
		cameraDirection = vector3,
	}
	]]

	if not InfoTable.Character then
		return
	end

	if not InfoTable.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	if not InfoTable.cameraDirection then
		return
	end
	
	task.spawn(function()
		for i = 0, 2, 1 do
			local WindStripes = ReplicatedStorage.VFXAssets:FindFirstChild("WindStripes", 1):Clone()
			WindStripes.CFrame = CFrame.new(Vector3.new(), InfoTable.cameraDirection) + InfoTable.Character.HumanoidRootPart.Position
			WindStripes.Parent = workspace
			WindStripes.AirEmitter:Emit(7)

			task.delay(2, function()
				WindStripes:Destroy()
			end)

			task.wait(0.04)
		end
	end)
	
	local DodgeSFX = Sounds:FindFirstChild("Dodge3", 1):Clone()
	
	DodgeSFX.Parent = InfoTable.Character.HumanoidRootPart
	DodgeSFX.RollOffMaxDistance = 100
	DodgeSFX.PlaybackSpeed = math.random(92, 120) / 100
	DodgeSFX:Play()
	
	DodgeSFX.Ended:Connect(function()
		DodgeSFX:Destroy()
	end)
end

function VFX:Jump(InfoTable)

	--[[
	InfoTable = {
		Player = Player
		Character = Character,
	}
	]]

	if not InfoTable.Character then
		return
	end

	if not InfoTable.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local WindStripes = ReplicatedStorage.VFXAssets:FindFirstChild("WindStripes", 1):Clone()
	WindStripes.CFrame = InfoTable.Character.HumanoidRootPart.CFrame * CFrame.new(Vector3.new(), Vector3.new(0, 1, 0))
	WindStripes.Parent = workspace
	WindStripes.AirEmitter:Emit(10)
	
	task.delay(2, function()
		WindStripes:Destroy()
	end)

	local JumpSFX = Sounds:FindFirstChild("Jump", 1):Clone()

	JumpSFX.Parent = InfoTable.Character.HumanoidRootPart
	JumpSFX.TimePosition = 0.3
	JumpSFX.RollOffMaxDistance = 100
	JumpSFX.PlaybackSpeed = math.random(92, 120) / 100
	JumpSFX:Play()

	JumpSFX.Ended:Connect(function()
		JumpSFX:Destroy()
	end)
end

function VFX:Landing(InfoTable)

	--[[
	InfoTable = {
		Player = Player
		Character = Character,
	}
	]]
	
	if not InfoTable.Character then
		return
	end

	if not InfoTable.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {InfoTable.Character}

	local ray = workspace:Raycast(InfoTable.Character.HumanoidRootPart.Position, Vector3.new(0, -5 , 0), Params)

	if ray then
		local Dust = ReplicatedStorage.VFXAssets:FindFirstChild("Dust", 1):Clone()
		Dust.Position = ray.Position
		Dust.Parent = workspace
		Dust.BigCloudsEmitter:Emit(5)
		Dust.SmallCloudsEmitter:Emit(5)

		task.delay(2, function()
			Dust:Destroy()
		end)
	end
	
	local LandingSFX = Sounds:FindFirstChild("Landing", 1):Clone()

	LandingSFX.Parent = InfoTable.Character.HumanoidRootPart
	LandingSFX.RollOffMaxDistance = 100
	LandingSFX.PlaybackSpeed = math.random(95, 105) / 100
	LandingSFX:Play()

	LandingSFX.Ended:Connect(function()
		LandingSFX:Destroy()
	end)
end

function VFX:SlamStart(InfoTable)

	--[[
	InfoTable = {
		? PlayerFired = Player,
		Player = Character
		Character = Character,
	}
	]]

	if not InfoTable.Character then
		return
	end

	if not InfoTable.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	if not self.CachedInfo[InfoTable.Player] then
		self.CachedInfo[InfoTable.Player] = table.clone(self.AbilityInfo)
	end

	local CachedInfo = self.CachedInfo[InfoTable.Player].Slide

	if CachedInfo._heartbeatConnection then
		CachedInfo._heartbeatConnection:Disconnect()
	end

	if CachedInfo._falling then
		CachedInfo._falling:Destroy()
	end
	
	if CachedInfo._longWindStripes then
		CachedInfo._longWindStripes:Destroy()
	end

	CachedInfo._falling = Sounds:FindFirstChild("Whoosh", 1):Clone()
	CachedInfo._falling.Parent = InfoTable.Character.HumanoidRootPart
	CachedInfo._falling:Play()

	CachedInfo._longWindStripes = ReplicatedStorage.VFXAssets:FindFirstChild("LongWindStripes", 1):Clone()
	CachedInfo._longWindStripes.Parent = workspace
	switchEmitters(CachedInfo._longWindStripes, true)

	CachedInfo._heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		-- Rotate the player in the dash direction

		CachedInfo._longWindStripes.CFrame = InfoTable.Character.HumanoidRootPart.CFrame
	end)
end

function VFX:SlamEnd(InfoTable)

	--[[
	InfoTable = {
		Player = Player
		Character = Character,
		IsHeavy = bool,
		Landed = bool,
	}
	]]
	
	if typeof(InfoTable.IsHeavy) ~= "boolean" then
		return
	end
	
	if typeof(InfoTable.Landed) ~= "boolean" then
		return
	end

	if not InfoTable.Character then
		return
	end

	if not InfoTable.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	if not self.CachedInfo[InfoTable.Player] then
		self.CachedInfo[InfoTable.Player] = table.clone(self.AbilityInfo)
	end

	local CachedInfo = self.CachedInfo[InfoTable.Player].Slide

	if CachedInfo._heartbeatConnection then
		CachedInfo._heartbeatConnection:Disconnect()
	end

	if CachedInfo._falling then
		CachedInfo._falling:Destroy()
	end
	
	if InfoTable.Landed then
		local Params = RaycastParams.new()
		Params.FilterType = Enum.RaycastFilterType.Exclude
		Params.FilterDescendantsInstances = {InfoTable.Character}
		
		local ray = workspace:Raycast(InfoTable.Character.HumanoidRootPart.Position, Vector3.new(0, -5 , 0), Params)

		if ray then
			local Dust = ReplicatedStorage.VFXAssets:FindFirstChild("Dust", 1):Clone()
			Dust.Position = ray.Position
			Dust.Parent = workspace
			Dust.BigCloudsEmitter:Emit(5)
			Dust.SmallCloudsEmitter:Emit(5)

			task.delay(2, function()
				Dust:Destroy()
			end)
		end
		
		local LandingSFX
		
		if InfoTable.IsHeavy then
			LandingSFX = Sounds:FindFirstChild("HeavyLanding", 1):Clone()
		else
			LandingSFX = Sounds:FindFirstChild("Landing", 1):Clone()
		end	

		LandingSFX.Parent = InfoTable.Character.HumanoidRootPart
		LandingSFX.RollOffMaxDistance = 100
		LandingSFX.PlaybackSpeed = math.random(92, 120) / 100
		LandingSFX:Play()

		LandingSFX.Ended:Connect(function()
			LandingSFX:Destroy()
		end)
	end

	if CachedInfo._longWindStripes then
		local pointer = CachedInfo._longWindStripes
		switchEmitters(pointer, false)

		task.delay(2, function()
			pointer:Destroy()
		end)
	end
end

function VFX:SlideStart(InfoTable)

	--[[
	InfoTable = {
		Player = Character
		Character = Character,
		cameraDirection = vector3,
	}
	]]

	if not InfoTable.Character then
		return
	end

	if not InfoTable.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	if not InfoTable.cameraDirection then
		return
	end
	
	if not self.CachedInfo[InfoTable.Player] then
		self.CachedInfo[InfoTable.Player] = table.clone(self.AbilityInfo)
	end
	
	local CachedInfo = self.CachedInfo[InfoTable.Player].Slide
	
	if CachedInfo._heartbeatConnection then
		CachedInfo._heartbeatConnection:Disconnect()
	end
	
	if CachedInfo._wallCling then
		CachedInfo._wallCling:Destroy()
	end
	
	CachedInfo._wallCling = Sounds:FindFirstChild("WallCling", 1):Clone()
	CachedInfo._wallCling.Parent = InfoTable.Character.HumanoidRootPart
	CachedInfo._wallCling:Play()
	
	CachedInfo._sparks = ReplicatedStorage.VFXAssets:FindFirstChild("Sparks", 1):Clone()
	CachedInfo._sparks.Parent = workspace
	switchEmitters(CachedInfo._sparks, true)
	
	CachedInfo._windStripes = ReplicatedStorage.VFXAssets:FindFirstChild("SlightWindStripes", 1):Clone()
	CachedInfo._windStripes.Parent = workspace
	switchEmitters(CachedInfo._windStripes, true)
	
	CachedInfo._heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		-- Rotate the player in the dash direction
		
		CachedInfo._sparks.CFrame = CFrame.new(Vector3.new(), InfoTable.cameraDirection) * CFrame.new(0, -2.75, -2.75) + InfoTable.Character.HumanoidRootPart.Position
		CachedInfo._windStripes.CFrame = CFrame.new(Vector3.new(), InfoTable.cameraDirection) + InfoTable.Character.HumanoidRootPart.Position
		
		local Params = RaycastParams.new()
		Params.FilterType = Enum.RaycastFilterType.Exclude
		Params.FilterDescendantsInstances = {InfoTable.Character}
		
		if not workspace:Raycast(InfoTable.Character.HumanoidRootPart.Position, Vector3.new(0, -4, 0), Params) then
			CachedInfo._wallCling:Pause()
			switchEmitters(CachedInfo._sparks, false)
			return
		end
		
		CachedInfo._wallCling:Resume()
		switchEmitters(CachedInfo._sparks, true)
	end)
end

function VFX:SlideEnd(InfoTable)

	--[[
	InfoTable = {
		Player = Player
		Character = Character,
	}
	]]

	if not InfoTable.Character then
		return
	end

	if not InfoTable.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	if not self.CachedInfo[InfoTable.Player] then
		self.CachedInfo[InfoTable.Player] = table.clone(self.AbilityInfo)
	end
	
	local CachedInfo = self.CachedInfo[InfoTable.Player].Slide
	
	if CachedInfo._heartbeatConnection then
		CachedInfo._heartbeatConnection:Disconnect()
	end
	
	if CachedInfo._wallCling then
		CachedInfo._wallCling:Destroy()
	end
	
	if CachedInfo._sparks then
		local pointer = CachedInfo._sparks
		switchEmitters(pointer, false)

		task.delay(2, function()
			pointer:Destroy()
		end)
	end
	
	if CachedInfo._windStripes then
		local pointer = CachedInfo._windStripes
		switchEmitters(pointer, false)

		task.delay(2, function()
			pointer:Destroy()
		end)
	end
end

return VFX
