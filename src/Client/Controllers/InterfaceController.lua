local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)

local InterfaceController = Knit.CreateController {
	Name = "InterfaceController",
	InterfaceGui = nil,
	Info = {
		Stamina = 0,
		MaxStamina = 3,
	}
}

-- Methods --

function InterfaceController:UpdateStaminaSections(Stamina, MaxStamina)
	local StaminaBar = self.InterfaceGui.StaminaBar
	local Sections = StaminaBar.Sections
	
	-- Stamina
	
	local staminaUsed = Stamina
	
	for _, section in pairs(Sections:GetChildren()) do
		if not section:IsA("Frame") then
			continue
		end

		if staminaUsed >= 1 then
			section.Charge.Size = UDim2.fromScale(1, 1)
			staminaUsed -= 1
			
			if not section:GetAttribute("Lit") then
				section:SetAttribute("Lit", true)
				TweenService:Create(section.Charge, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0, BackgroundColor3 = Color3.fromRGB(196, 250, 255)}):Play()

				task.delay(0.3, function()
					if not section:GetAttribute("Lit") then
						return
					end

					TweenService:Create(section.Charge, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {Transparency = 0, BackgroundColor3 = Color3.fromRGB(142, 249, 255)}):Play()
				end)

				ReplicatedStorage.SFXAssets:FindFirstChild("BatteryCharged", 1):Play()
			end
		else
			section.Charge.Size = UDim2.fromScale(staminaUsed % 1, 1)
			staminaUsed = 0
			
			if section:GetAttribute("Lit") then
				section:SetAttribute("Lit", false)
				TweenService:Create(section.Charge, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.6, BackgroundColor3 = Color3.fromRGB(95, 95, 95)}):Play()
			end
		end
	end
	
	-- Max stamina

	if #Sections:GetChildren() - 1 ~= MaxStamina then
		for _, item in pairs(Sections:GetChildren()) do
			if not item:IsA("Frame") then
				continue
			end

			item:Destroy()
		end

		for i = 1, MaxStamina, 1 do
			local section = Sections.UIListLayout.SectionTemplate:Clone()

			section.Name = tostring(i)
			section.Size = UDim2.fromScale(1 / 3, 1)
			section.LayoutOrder = i
			section.Parent = Sections
		end
	end
end

function InterfaceController:Update()	
	self:UpdateStaminaSections(self.Info.Stamina, self.Info.MaxStamina)
end

function InterfaceController:KnitInit()
	self.InterfaceGui = ReplicatedStorage.StarterGUI.InterfaceGUI:Clone()
	self.InterfaceGui.Parent = Player.PlayerGui
	
	RunService.Heartbeat:Connect(function(dt)
		self:Update()
	end)
end

return InterfaceController