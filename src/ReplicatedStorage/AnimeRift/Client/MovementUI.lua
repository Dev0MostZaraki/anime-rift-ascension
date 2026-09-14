local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local MovementUI = {}
MovementUI.__index = MovementUI

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

local function stroke(parent, color, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Transparency = transparency or 0.55
	s.Thickness = 1
	s.Parent = parent
	return s
end

function MovementUI.new(gui, config, remote)
	local self = setmetatable({}, MovementUI)
	self.Gui = gui
	self.Config = config
	self.Remote = remote
	self.Sprinting = false
	self.KeyboardHeld = false
	self.ToggleHeld = false
	self.BaseFov = 70

	local button = Instance.new("TextButton")
	button.Name = "SprintButton"
	button.AnchorPoint = Vector2.new(0, 1)
	button.Position = UDim2.new(0, 18, 1, -74)
	button.Size = UDim2.new(0, 156, 0, 42)
	button.BackgroundColor3 = Color3.fromRGB(18, 24, 26)
	button.BackgroundTransparency = 0.10
	button.BorderSizePixel = 0
	button.Text = "SHIFT  •  SPRINT"
	button.TextColor3 = Color3.fromRGB(218, 226, 215)
	button.TextSize = 12
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = gui
	corner(button, 10)
	stroke(button, Color3.fromRGB(110, 138, 108), 0.50)
	self.Button = button

	local bar = Instance.new("Frame")
	bar.Name = "SprintAccent"
	bar.Size = UDim2.new(0, 4, 1, -12)
	bar.Position = UDim2.new(0, 7, 0, 6)
	bar.BackgroundColor3 = Color3.fromRGB(103, 154, 101)
	bar.BorderSizePixel = 0
	bar.Parent = button
	corner(bar, 3)
	self.Accent = bar

	button.Activated:Connect(function()
		self.ToggleHeld = not self.ToggleHeld
		self:SetSprint(self.ToggleHeld or self.KeyboardHeld)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			self.KeyboardHeld = true
			self:SetSprint(true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			self.KeyboardHeld = false
			self:SetSprint(self.ToggleHeld)
		end
	end)

	return self
end

function MovementUI:SetSprint(enabled)
	enabled = enabled == true
	if self.Sprinting == enabled then return end
	self.Sprinting = enabled
	self.Remote:FireServer("Sprint", enabled)

	self.Button.Text = enabled and "SPRINTING  •  SHIFT" or "SHIFT  •  SPRINT"
	self.Button.BackgroundColor3 = enabled and Color3.fromRGB(31, 49, 35) or Color3.fromRGB(18, 24, 26)
	self.Accent.BackgroundColor3 = enabled and Color3.fromRGB(134, 196, 112) or Color3.fromRGB(103, 154, 101)

	local camera = Workspace.CurrentCamera
	if camera then
		local target = enabled and (self.Config.Game.SprintFov or 76) or self.BaseFov
		TweenService:Create(camera, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {FieldOfView = target}):Play()
	end
end

return MovementUI
