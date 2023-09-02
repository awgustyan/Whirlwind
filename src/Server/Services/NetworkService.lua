local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)

local NetworkService = Knit.CreateService {
	Name = "NetworkService"
}

-- Functions --

local function SetNetworkOwnership(instance, owner)
	if instance:IsA("BasePart") and instance:CanSetNetworkOwnership() then
		instance:SetNetworkOwner(owner)
	end
	
	for _, descendant in pairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:CanSetNetworkOwnership() then
			descendant:SetNetworkOwner(owner)
		end
	end
end

-- Methods --

function NetworkService:KnitInit()
	for index, instance in ipairs(workspace:GetDescendants()) do		
		if not instance:IsA("BasePart") then
			continue
		end

		if not instance:CanSetNetworkOwnership() then
			continue
		end

		if instance:GetNetworkOwner() then
			continue
		end
		
		instance:SetNetworkOwner(nil)
	end

	workspace.DescendantAdded:Connect(function(instance)
		task.wait()
		
		if not instance:IsA("BasePart") then
			return
		end
		
		if not instance:CanSetNetworkOwnership() then
			return
		end

		if instance:GetNetworkOwner() then
			return
		end

		instance:SetNetworkOwner(nil)
	end)
end

return NetworkService