local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Abilities = {}
Abilities.__index = Abilities

function Abilities.new(Player : Player)
	local self = {}
	setmetatable(self, Abilities)
	
	-- Knit
	
	self.VFXService = Knit.GetService("VFXService")
	
	-- Player parts

	self.Player = Player
	self.Character = Player.Character
	self.Humanoid = Player.Character:WaitForChild("Humanoid")
	self.HRT = Player.Character:WaitForChild("HumanoidRootPart")
	
	-- Stamina

	self.MaxStamina = 3
	self.StaminaRegainSpeed = 1 -- bars / seconds

	self._stamina = 0
	
	-- ABILITIES --

	self.AbilityInfo = {
		RotateRootJoint = {
			DBDuration = 0.01,

			_db = false,
		},
		Dash = {
			DBDuration = 0,
			Duration = 0.15, -- Seconds

			_db = false,
		},
		Slide = {
			DBDuration = 0,
			
			_active = false,
			_db = false,
		},
		Landing = {
			DBDuration = 0.1,
			
			_db = false,
		},
		Slam = {
			DBDuration = 0.3,
			
			_active = false,
			_db = false,
		},
		Jump = {
			DBDuration = 0.1,

			_db = false,
		}
	}
	
	return self
end

function Abilities:Update(dt)
	if self._stamina + (self.StaminaRegainSpeed * dt) > self.MaxStamina then
		self._stamina += (self.StaminaRegainSpeed * dt) + self.MaxStamina - (self._stamina + (self.StaminaRegainSpeed * dt))
	else
		self._stamina += self.StaminaRegainSpeed * dt
	end
end

function Abilities:Destroy()
	self = nil
end

-- Abilities --

function Abilities:RotateRootJoint(InfoTable)

	--[[
	InfoTable = {
		RootJointRotation = Radians,
	}
	]]

	if not InfoTable.RootJointRotation then
		self.Player:Kick("Suspicious activity")
		return
	end

	if typeof(InfoTable.RootJointRotation) ~= "number" then
		self.Player:Kick("Suspicious activity")
		return
	end

	local AbilityInfo = self.AbilityInfo.RotateRootJoint

	-- Debounce and stamina

	if AbilityInfo._db then
		return
	end
	
	AbilityInfo._db = true

	task.delay(AbilityInfo.DBDuration, function()
		AbilityInfo._db = false
	end)

	-- Fire VFX for clients

	local CutInfoTable = {
		RootJointRotation = InfoTable.RootJointRotation % (math.pi * 2),
		Character = self.Character,
		Player = self.Player,
	}

	self.VFXService:FireExcept(self.Player, "RotateRootJoint", CutInfoTable)
end

function Abilities:Dash(InfoTable)

	--[[
	InfoTable = {
		cameraDirection = vector3
	}
	]]
	
	if not InfoTable.cameraDirection then
		self.Player:Kick("Suspicious activity")
		return
	end
	
	if typeof(InfoTable.cameraDirection) ~= "Vector3" then
		self.Player:Kick("Suspicious activity")
		return
	end
	
	local AbilityInfo = self.AbilityInfo.Dash

	-- Debounce and stamina

	if AbilityInfo._db then
		return
	end

	if self._stamina < 1 then
		return
	end

	self._stamina -= 1
	AbilityInfo._db = true

	task.delay(AbilityInfo.DBDuration, function()
		AbilityInfo._db = false
	end)
	
	-- Fire VFX for clients
	
	local CutInfoTable = {
		cameraDirection = InfoTable.cameraDirection,
		Character = self.Character,
		Player = self.Player,
	}
	
	self.VFXService:FireExcept(self.Player, "Dash", CutInfoTable)
end

function Abilities:Jump(InfoTable)

	--[[
	InfoTable = {

	}
	]]

	local AbilityInfo = self.AbilityInfo.Jump

	-- Debounce and stamina

	if AbilityInfo._db then
		return
	end

	AbilityInfo._db = true

	task.delay(AbilityInfo.DBDuration, function()
		AbilityInfo._db = false
	end)

	-- Fire VFX for clients

	local CutInfoTable = {
		Character = self.Character,
		Player = self.Player,
	}

	self.VFXService:FireExcept(self.Player, "Jump", CutInfoTable)
end

function Abilities:Landing(InfoTable)

	--[[
	InfoTable = {

	}
	]]

	local AbilityInfo = self.AbilityInfo.Landing

	-- Debounce and stamina

	if AbilityInfo._db then
		return
	end

	AbilityInfo._db = true

	task.delay(AbilityInfo.DBDuration, function()
		AbilityInfo._db = false
	end)

	-- Fire VFX for clients

	local CutInfoTable = {
		Character = self.Character,
		Player = self.Player,
	}

	self.VFXService:FireExcept(self.Player, "Landing", CutInfoTable)
end

function Abilities:SlamStart(InfoTable)

	--[[
	InfoTable = {
	}
	]]

	local AbilityInfo = self.AbilityInfo.Slam

	-- Debounce and stamina

	if AbilityInfo._db then
		return
	end
	
	if AbilityInfo._active then
		return
	end
	
	AbilityInfo._db = true

	task.delay(AbilityInfo.DBDuration, function()
		AbilityInfo._db = false
	end)
	
	AbilityInfo._active = true
	
	-- Fire VFX for clients

	local CutInfoTable = {
		Character = self.Character,
		Player = self.Player,
	}

	self.StaminaRegainSpeed = 0
	self.VFXService:FireExcept(self.Player, "SlamStart", CutInfoTable)
end

function Abilities:SlamEnd(InfoTable)

	--[[
	InfoTable = {
		IsHeavy = bool,
		Landed = bool,
	}
	]]

	local AbilityInfo = self.AbilityInfo.Slide

	-- Debounce and stamina

	if AbilityInfo._db then
		return
	end
	
	if not AbilityInfo._active then
		return
	end
	
	if not InfoTable.IsHeavy then
		return
	end

	if typeof(InfoTable.IsHeavy) ~= "boolean" then
		self.Player:Kick("Suspicious Activity")
		return
	end
	
	if not InfoTable.Landed then
		return
	end

	if typeof(InfoTable.Landed) ~= "boolean" then
		self.Player:Kick("Suspicious Activity")
		return
	end
	
	if self._stamina < 1 then
		InfoTable.IsHeavy = false
	end

	if InfoTable.IsHeavy then
		self._stamina -= 1
	end

	AbilityInfo._db = true

	task.delay(AbilityInfo.DBDuration, function()
		AbilityInfo._db = false
	end)
	
	AbilityInfo._active = false

	-- Fire VFX for clients

	local CutInfoTable = {
		Character = self.Character,
		Player = self.Player,
		IsHeavy = InfoTable.IsHeavy,
		Landed = InfoTable.Landed,
	}

	self.StaminaRegainSpeed = 1
	self.VFXService:FireExcept(self.Player, "SlamEnd", CutInfoTable)
end

function Abilities:SlideStart(InfoTable)

	--[[
	InfoTable = {
		cameraDirection = vector3
	}
	]]

	if not InfoTable.cameraDirection then
		self.Player:Kick("Suspicious activity")
		return
	end

	if typeof(InfoTable.cameraDirection) ~= "Vector3" then
		self.Player:Kick("Suspicious activity")
		return
	end

	local AbilityInfo = self.AbilityInfo.Slide

	-- Debounce and stamina

	if AbilityInfo._db then
		return
	end
	
	if AbilityInfo._active then
		return
	end

	AbilityInfo._db = true

	task.delay(AbilityInfo.DBDuration, function()
		AbilityInfo._db = false
	end)
	
	AbilityInfo._active = true

	-- Fire VFX for clients

	local CutInfoTable = {
		cameraDirection = InfoTable.cameraDirection,
		Character = self.Character,
		Player = self.Player,
	}
	
	self.StaminaRegainSpeed = 0
	self.VFXService:FireExcept(self.Player, "SlideStart", CutInfoTable)
end

function Abilities:SlideEnd(InfoTable)

	--[[
	InfoTable = {

	}
	]]

	local AbilityInfo = self.AbilityInfo.Slide

	-- Debounce and stamina

	if AbilityInfo._db then
		return
	end
	
	if not AbilityInfo._active then
		return
	end

	AbilityInfo._db = true

	task.delay(AbilityInfo.DBDuration, function()
		AbilityInfo._db = false
	end)
	
	AbilityInfo._active = false
	
	-- Fire VFX for clients

	local CutInfoTable = {
		Character = self.Character,
		Player = self.Player,
	}
	
	self.StaminaRegainSpeed = 1
	self.VFXService:FireExcept(self.Player, "SlideEnd", CutInfoTable)
end

return Abilities
