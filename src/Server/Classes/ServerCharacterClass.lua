local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local AbilitiesClass = require(ServerScriptService.Server.Classes.AbilitiesClass)

local ServerCharacter = {}
ServerCharacter.__index = ServerCharacter

function ServerCharacter.new(Player : Player)
	local self = {}
	setmetatable(self, ServerCharacter)
	
	-- Classes
	
	self.Abilities = AbilitiesClass.new(Player)

	-- Player parts

	self.Player = Player
	self.Character = Player.Character
	self.Humanoid = Player.Character:WaitForChild("Humanoid")
	self.HRT = Player.Character:WaitForChild("HumanoidRootPart")

	return self
end

function ServerCharacter:Update(dt)
	self.Abilities:Update(dt)
end

function ServerCharacter:Destroy()
	self.Abilities:Destroy()
	self = nil
end

return ServerCharacter
