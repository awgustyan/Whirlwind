local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MovementClass = require(ReplicatedStorage.Shared.Classes.MovementClass)
local AnimateFunction = require(ReplicatedStorage.Shared.Modules.AnimateModule)
local PhysicsCharacterControllerClass = require(ReplicatedStorage.Shared.Classes.PhysicsCharacterController)

local Character = {}
Character.__index = Character

function Character.new(Player : Player)
	local self = {}
	setmetatable(self, Character)
	
	-- Classes
	
	Player.Character:WaitForChild("Humanoid").PlatformStand = true

	self.PhysicsController = PhysicsCharacterControllerClass.new(Player.Character:WaitForChild("HumanoidRootPart"))
	self.PhysicsController:AddCoreComponents()
	self.PhysicsController:Run()
	self.PhysicsController:ConnectComponentsToInput()
	
	self.Movement = MovementClass.new(Player, self.PhysicsController)
	
	-- Player parts

	self.Player = Player
	self.Character = Player.Character
	self.Humanoid = Player.Character:WaitForChild("Humanoid")
	self.HRT = Player.Character:WaitForChild("HumanoidRootPart")
	self.Camera = workspace.CurrentCamera
        
	task.spawn(AnimateFunction, self.Character, self.PhysicsController)
	
	self.Character:WaitForChild("Animate").Enabled = false

	return self
end

function Character:Update(dt)
	self.Movement:Update(dt)
end

function Character:Destroy()
	self.Movement:Destroy()
	self = nil
end

return Character
