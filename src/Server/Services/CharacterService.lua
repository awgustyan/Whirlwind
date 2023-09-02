local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

-- Utility --

local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- Classes --

local ServerCharacterClass = require(ServerScriptService.Server.Classes.ServerCharacterClass)

local CharacterService = Knit.CreateService {
	Name = "CharacterService",
	CachedCharacters = {}, -- UserId -> ServerCharacter
	Client = {
		AbilityRemote = Knit.CreateSignal()
	},
}

-- Functions -- 

-- Methods --

function CharacterService:InitServerCharacter(Player)
	local ServerCharacter = ServerCharacterClass.new(Player)
	
	self.CachedCharacters[Player.UserId] = ServerCharacter

	local trove = Trove.new()
	
	trove:Add(function()
		self.CachedCharacters[Player.UserId] = nil
	end)

	trove:Connect(RunService.Heartbeat, function(dt)
		ServerCharacter:Update(dt)
	end)
	
	Player.Character:WaitForChild("Humanoid").Died:Connect(function()
		if trove then
			trove:Destroy()
		end

		if ServerCharacter then
			ServerCharacter:Destroy()
		end
	end)
	
	Player.CharacterRemoving:Connect(function()		
		if trove then
			trove:Destroy()
		end
		
		if ServerCharacter then
			ServerCharacter:Destroy()
		end
	end)
end

function CharacterService:KnitInit()
	self.Client.AbilityRemote:Connect(function(Player, Ability, InfoTable)
		
		if not Player then
			return
		end
		
		if not InfoTable then
			return
		end
		
		if typeof(Ability) ~= "string" then
			Player:Kick("Suspicious activity")
			return
		end
		
		if typeof(InfoTable) ~= "table" then
			Player:Kick("Suspicious activity")
			return
		end
		
		if not self.CachedCharacters[Player.UserId] then
			return
		end
		
		if not self.CachedCharacters[Player.UserId].Abilities[Ability] then
			return
		end
		
		if typeof(self.CachedCharacters[Player.UserId].Abilities[Ability]) ~= "function" then
			Player:Kick("Suspicious activity")
			return
		end
		
		self.CachedCharacters[Player.UserId].Abilities[Ability](self.CachedCharacters[Player.UserId].Abilities, InfoTable)
	end)
end

function CharacterService:KnitStart()
	for _, Player in Players:GetPlayers() do
		if Player.Character then
			self:InitServerCharacter(Player)
		end
	end
	
	Players.PlayerAdded:Connect(function(Player)
		Player.CharacterAdded:Connect(function()
			self:InitServerCharacter(Player)
		end)
	end)
end

return CharacterService