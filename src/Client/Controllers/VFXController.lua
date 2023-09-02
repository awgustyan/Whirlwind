local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local VFXClass = require(ReplicatedStorage.Shared.Classes.VFXClass).new()

-- Create the service:
local VFXController = Knit.CreateController {
	Name = "VFXController"
}

function VFXController:ClientVFX(VFXName, InfoTable)
	
	if typeof(VFXClass[VFXName]) ~= "function" then
		return
	end

	VFXClass[VFXName](VFXClass, InfoTable)
end

function VFXController:KnitStart()
	local VFXService = Knit.GetService("VFXService")

	VFXService.VFXRemote:Connect(function(VFXName, InfoTable)
		if typeof(VFXClass[VFXName]) ~= "function" then
			return
		end

		VFXClass[VFXName](VFXClass, InfoTable)
	end)
end

return VFXController