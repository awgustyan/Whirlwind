local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddControllers(script.Parent:WaitForChild("Controllers"))

Knit.Start():catch(warn)