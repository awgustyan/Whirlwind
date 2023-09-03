local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Player = Players.LocalPlayer

-- Utility --

local UISBinds = require(ReplicatedStorage.Shared.Modules:WaitForChild("UserInputBind"));
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- Classes --

local CharacterClass = require(ReplicatedStorage.Shared.Classes.CharacterClass)

local CharacterController = Knit.CreateController {
	Name = "CharacterController"
}

-- Functions -- 

-- Methods --	

function CharacterController:InitCharacter()
	local Character = CharacterClass.new(Player)
	local trove = Trove.new()

	trove:Connect(RunService.Heartbeat, function(dt)
		Character:Update(dt)
	end)

	Player.Character:WaitForChild("Humanoid").Died:Connect(function()
		if trove then
			trove:Destroy()
		end

		if Character then
			Character:Destroy()
		end
	end)
	
	Player.CharacterRemoving:Connect(function()		
		if trove then
			trove:Destroy()
		end
		
		if Character then
			Character:Destroy()
		end
	end)
end

function CharacterController:KnitStart()
	if Player.Character then
		self:InitCharacter()
	end
	
	Player.CharacterAdded:Connect(function()
		self:InitCharacter()
	end)
end

return CharacterController