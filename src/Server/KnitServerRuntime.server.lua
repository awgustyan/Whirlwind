local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddServices(ServerScriptService.Server.Services)

Knit.Start():catch(warn)