local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ProfileService = require(ReplicatedStorage.Shared.Modules.ProfileService)

local ProfileTemplate = {
	Currencies = {
		
	}
}

local ProfileStore = ProfileService.GetProfileStore("PlayerData", ProfileTemplate)

local ProfileCacherService = Knit.CreateService {
	Name = "ProfileCacherService",
	cachedProfiles = {}
}

-- functions --

local function dictionaryLen(Dictionary)
	local len = 0
	for _, _ in next, Dictionary do
		len += 1
	end
	
	return len
end

-- Methods --

function ProfileCacherService:AddCurrency(UserId, Currency, Amount)
	return Promise.new(function(resolve, reject, onCancel)
		local profile = self.cachedProfiles[UserId]

		if profile.Data.Currencies[Currency] - Amount < 0 then
			reject()
			return
		end

		profile.Data.Currencies[Currency] += Amount
		self.Client.CurrencyChangedRemote:Fire(Players:GetPlayerByUserId(UserId), profile.Data.Currencies)
		resolve()
	end)
end

-- Profile setup --

function ProfileCacherService:setupProfile(Player, profile)
	
	profile.Data.Currencies = {}
	
	local leaderStats = Instance.new("Folder", Player)
	leaderStats.Name = "leaderstats"
	
	task.spawn(function()
		while wait(0.2) do
			if profile then
				for currency, value in pairs(profile.Data.Currencies) do
					if not leaderStats:FindFirstChild(currency) then
						local currencyValue = Instance.new("IntValue", leaderStats)
						currencyValue.Name = currency
					end
					
					leaderStats[currency].Value = value
				end
			else
				break
			end
		end
	end)
end

function ProfileCacherService:PlayerAdded(player)
	
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId, "ForceLoad")

	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		profile:ListenToRelease(function() 
			self.cachedProfiles[player.UserId] = nil
			-- The profile could've been loaded on another Roblox server:
			player:Kick("Your account has been loaded remotely. Please rejoin.")
		end)

		if player:IsDescendantOf(Players) == true then
			self.cachedProfiles[player.UserId] = profile
			-- A profile has been successfully loaded:
			self:setupProfile(player, profile)
		else
			-- Player left before the profile loaded:
			profile:Release()
		end
	else
		-- The profile couldn't be loaded possibly due to other
		-- Roblox servers trying to load this profile at the same time:
		player:Kick("Unable to load data from server. Please rejoin.") 
	end
end

function ProfileCacherService:KnitInit()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(self:PlayerAdded(player))
	end

	Players.PlayerAdded:Connect(function(Player)
		self:PlayerAdded(Player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local profile = self.cachedProfiles[player.UserId]

		if profile ~= nil then
			profile:Release()
		end
	end)
end

function ProfileCacherService:KnitStart()

end

return ProfileCacherService	