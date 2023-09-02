local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- Create the service:
local VFXService = Knit.CreateService {
	Name = "VFXService",
	Client = {
		VFXRemote = Knit.CreateSignal()
	},
	LastPlayerFire = {}
}

function VFXService:FireExcept(Player, VFXName, InfoTable)
	self.Client.VFXRemote:FireExcept(Player, VFXName, InfoTable)
end

function VFXService:FireAll(VFXName, InfoTable)
	self.Client.VFXRemote:FireAll(VFXName, InfoTable)
end

function VFXService:Fire(Player, VFXName, InfoTable)
	self.Client.VFXRemote:Fire(Player, VFXName, InfoTable)
end

return VFXService