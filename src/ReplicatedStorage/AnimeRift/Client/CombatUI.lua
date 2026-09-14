local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CombatUI = {}
CombatUI.__index = CombatUI

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
end

local function stroke(parent, color, transparency, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(125, 110, 175)
	s.Transparency = transparency or 0.45
	s.Thickness = thickness or 1
	s.Parent = parent
end

local function gradient(parent, a, b, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = rotation or 90
	g.Parent = parent
end

local function makeButton(parent, keyText, nameText, x, color)
	local button = Instance.new("TextButton")
	button.Name = nameText
	button.Size = UDim2.new(0, 164, 0, 50)
	button.Position = UDim2.new(0, x, 0, 11)
	button.BackgroundColor3 = Color3.fromRGB(24, 27, 39)
	button.BackgroundTransparency = 0.02
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Text = ""
	button.Parent = parent
	corner(button, 12)
	stroke(button, color, 0.52, 1.2)
	gradient(button, Color3.fromRGB(32, 35, 49), Color3.fromRGB(18, 20, 30), 90)

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.new(0, 5, 1, -12)
	accent.Position = UDim2.new(0, 6, 0, 6)
	accent.BackgroundColor3 = color
	accent.BorderSizePixel = 0
	accent.Parent = button
	corner(accent, 4)

	local key = Instance.new("TextLabel")
	key.Size = UDim2.new(0, 34, 0, 34)
	key.Position = UDim2.new(0, 18, 0.5, -17)
	key.BackgroundColor3 = color:Lerp(Color3.fromRGB(24, 25, 34), 0.44)
	key.BorderSizePixel = 0
	key.Text = keyText
	key.TextColor3 = Color3.fromRGB(255, 255, 255)
	key.TextSize = 17
	key.Font = Enum.Font.GothamBlack
	key.Parent = button
	corner(key, 9)

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -64, 1, 0)
	name.Position = UDim2.new(0, 59, 0, 0)
	name.BackgroundTransparency = 1
	name.Text = nameText
	name.TextColor3 = Color3.fromRGB(236, 238, 247)
	name.TextSize = 12
	name.Font = Enum.Font.GothamBold
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = button

	local cooldown = Instance.new("TextLabel")
	cooldown.Name = "Cooldown"
	cooldown.Size = UDim2.fromScale(1, 1)
	cooldown.BackgroundColor3 = Color3.fromRGB(9, 10, 15)
	cooldown.BackgroundTransparency = 0.22
	cooldown.BorderSizePixel = 0
	cooldown.TextColor3 = Color3.fromRGB(255, 255, 255)
	cooldown.TextSize = 20
	cooldown.Font = Enum.Font.GothamBlack
	cooldown.Visible = false
	cooldown.Parent = button
	corner(cooldown, 12)

	return button, cooldown
end

function CombatUI.new(gui, config, onAbility)
	local self = setmetatable({}, CombatUI)
	self.Config = config
	self.OnAbility = onAbility
	self.CooldownEnds = {}
	self.Buttons = {}
	self.ComboToken = 0

	local frame = Instance.new("Frame")
	frame.Name = "CombatBar"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -18)
	frame.Size = UDim2.new(0, 536, 0, 72)
	frame.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
	frame.BackgroundTransparency = 0.03
	frame.BorderSizePixel = 0
	frame.Parent = gui
	corner(frame, 16)
	stroke(frame, Color3.fromRGB(102, 83, 142), 0.38, 1.2)
	gradient(frame, Color3.fromRGB(21, 23, 34), Color3.fromRGB(10, 12, 19), 90)
	self.Frame = frame

	local q, qCd = makeButton(frame, "Q", "DASH", 10, Color3.fromRGB(70, 167, 215))
	local e, eCd = makeButton(frame, "E", "RIFT BURST", 186, Color3.fromRGB(143, 85, 211))
	local r, rCd = makeButton(frame, "R", "RIFT NOVA", 362, Color3.fromRGB(212, 72, 139))
	self.Buttons.Dash = {Button = q, Cooldown = qCd}
	self.Buttons.Burst = {Button = e, Cooldown = eCd}
	self.Buttons.Nova = {Button = r, Cooldown = rCd}
	q.Activated:Connect(function() self:TryUse("Dash") end)
	e.Activated:Connect(function() self:TryUse("Burst") end)
	r.Activated:Connect(function() self:TryUse("Nova") end)

	local styleLabel = Instance.new("TextLabel")
	styleLabel.AnchorPoint = Vector2.new(0.5, 1)
	styleLabel.Position = UDim2.new(0.5, 0, 0, -7)
	styleLabel.Size = UDim2.new(0, 300, 0, 25)
	styleLabel.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
	styleLabel.BackgroundTransparency = 0.04
	styleLabel.BorderSizePixel = 0
	styleLabel.Text = "STYLE // RIFT BLADE"
	styleLabel.TextColor3 = Color3.fromRGB(205, 170, 255)
	styleLabel.TextSize = 11
	styleLabel.Font = Enum.Font.GothamBold
	styleLabel.Parent = frame
	corner(styleLabel, 8)
	stroke(styleLabel, Color3.fromRGB(93, 78, 123), 0.60)
	self.StyleLabel = styleLabel

	local combo = Instance.new("TextLabel")
	combo.AnchorPoint = Vector2.new(0.5, 1)
	combo.Position = UDim2.new(0.5, 0, 1, -101)
	combo.Size = UDim2.new(0, 210, 0, 31)
	combo.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
	combo.BackgroundTransparency = 0.10
	combo.BorderSizePixel = 0
	combo.TextColor3 = Color3.fromRGB(235, 220, 255)
	combo.TextSize = 13
	combo.Font = Enum.Font.GothamBold
	combo.Text = "COMBO"
	combo.Visible = false
	combo.Parent = gui
	corner(combo, 9)
	stroke(combo, Color3.fromRGB(104, 86, 143), 0.55)
	self.Combo = combo

	RunService.RenderStepped:Connect(function() self:RenderCooldowns() end)
	return self
end

function CombatUI:SetStyle(style)
	if not style then return end
	self.StyleLabel.Text = "STYLE // " .. string.upper(style.Name)
	self.StyleLabel.TextColor3 = style.Color
	local s = self.StyleLabel:FindFirstChildOfClass("UIStroke")
	if s then s.Color = style.Color end
end

function CombatUI:GetCooldown(name)
	if name == "Dash" then return self.Config.Game.DashCooldown end
	if name == "Burst" then return self.Config.Game.BurstCooldown end
	if name == "Nova" then return self.Config.Game.NovaCooldown end
	return 0
end

function CombatUI:IsReady(name)
	return os.clock() >= (self.CooldownEnds[name] or 0)
end

function CombatUI:TryUse(name)
	if not self:IsReady(name) then return end
	self:StartCooldown(name, self:GetCooldown(name))
	if self.OnAbility then self.OnAbility(name) end
end

function CombatUI:StartCooldown(name, seconds)
	self.CooldownEnds[name] = os.clock() + seconds
	local refs = self.Buttons[name]
	if refs and refs.Button then
		refs.Button.Size = UDim2.new(0, 160, 0, 47)
		TweenService:Create(refs.Button, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 164, 0, 50)}):Play()
	end
end

function CombatUI:ResetCooldowns()
	table.clear(self.CooldownEnds)
	self.ComboToken += 1
	self.Combo.Visible = false
	self:RenderCooldowns()
end

function CombatUI:RenderCooldowns()
	local now = os.clock()
	for name, refs in pairs(self.Buttons) do
		local remaining = math.max(0, (self.CooldownEnds[name] or 0) - now)
		if remaining > 0 then
			refs.Cooldown.Visible = true
			refs.Cooldown.Text = string.format("%.1f", remaining)
			refs.Button.BackgroundTransparency = 0.20
		else
			refs.Cooldown.Visible = false
			refs.Button.BackgroundTransparency = 0.02
		end
	end
end

function CombatUI:ShowCombo(stage)
	self.ComboToken += 1
	local token = self.ComboToken
	local names = {"I", "II", "III"}
	self.Combo.Text = "CHAIN // " .. (names[stage] or tostring(stage))
	self.Combo.TextColor3 = stage == 3 and Color3.fromRGB(255, 210, 100) or Color3.fromRGB(225, 213, 248)
	self.Combo.Visible = true
	self.Combo.TextTransparency = 1
	self.Combo.Position = UDim2.new(0.5, 0, 1, -91)
	TweenService:Create(self.Combo, TweenInfo.new(0.12), {TextTransparency = 0, Position = UDim2.new(0.5, 0, 1, -101)}):Play()
	task.delay(0.72, function()
		if token ~= self.ComboToken then return end
		local tween = TweenService:Create(self.Combo, TweenInfo.new(0.18), {TextTransparency = 1, Position = UDim2.new(0.5, 0, 1, -111)})
		tween:Play(); tween.Completed:Wait()
		if token == self.ComboToken then self.Combo.Visible = false end
	end)
end

return CombatUI
