local RunService = game:GetService("RunService")

local CombatUI = {}
CombatUI.__index = CombatUI

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
end

local function stroke(parent, color, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(125, 110, 175)
	s.Transparency = transparency or 0.45
	s.Thickness = 1
	s.Parent = parent
end

local function makeButton(parent, keyText, nameText, x, color)
	local button = Instance.new("TextButton")
	button.Name = nameText
	button.Size = UDim2.new(0, 154, 0, 48)
	button.Position = UDim2.new(0, x, 0, 8)
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Text = ""
	button.Parent = parent
	corner(button, 10)
	stroke(button, color:Lerp(Color3.new(1, 1, 1), 0.35), 0.55)

	local key = Instance.new("TextLabel")
	key.Size = UDim2.new(0, 34, 1, 0)
	key.Position = UDim2.new(0, 7, 0, 0)
	key.BackgroundTransparency = 1
	key.Text = keyText
	key.TextColor3 = Color3.fromRGB(255, 255, 255)
	key.TextSize = 18
	key.Font = Enum.Font.GothamBlack
	key.Parent = button

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -44, 1, 0)
	name.Position = UDim2.new(0, 42, 0, 0)
	name.BackgroundTransparency = 1
	name.Text = nameText
	name.TextColor3 = Color3.fromRGB(245, 245, 250)
	name.TextSize = 13
	name.Font = Enum.Font.GothamBold
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = button

	local cooldown = Instance.new("TextLabel")
	cooldown.Name = "Cooldown"
	cooldown.Size = UDim2.fromScale(1, 1)
	cooldown.BackgroundColor3 = Color3.fromRGB(12, 13, 18)
	cooldown.BackgroundTransparency = 0.18
	cooldown.BorderSizePixel = 0
	cooldown.TextColor3 = Color3.fromRGB(255, 255, 255)
	cooldown.TextSize = 19
	cooldown.Font = Enum.Font.GothamBlack
	cooldown.Visible = false
	cooldown.Parent = button
	corner(cooldown, 10)

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
	frame.Size = UDim2.new(0, 500, 0, 64)
	frame.BackgroundColor3 = Color3.fromRGB(17, 18, 27)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.Parent = gui
	corner(frame, 14)
	stroke(frame)
	self.Frame = frame

	local q, qCd = makeButton(frame, "Q", "DASH", 8, Color3.fromRGB(50, 115, 165))
	local e, eCd = makeButton(frame, "E", "RIFT BURST", 173, Color3.fromRGB(126, 65, 168))
	local r, rCd = makeButton(frame, "R", "RIFT NOVA", 338, Color3.fromRGB(170, 58, 122))
	self.Buttons.Dash = {Button = q, Cooldown = qCd}
	self.Buttons.Burst = {Button = e, Cooldown = eCd}
	self.Buttons.Nova = {Button = r, Cooldown = rCd}

	q.Activated:Connect(function() self:TryUse("Dash") end)
	e.Activated:Connect(function() self:TryUse("Burst") end)
	r.Activated:Connect(function() self:TryUse("Nova") end)

	local combo = Instance.new("TextLabel")
	combo.AnchorPoint = Vector2.new(0.5, 1)
	combo.Position = UDim2.new(0.5, 0, 1, -88)
	combo.Size = UDim2.new(0, 220, 0, 34)
	combo.BackgroundColor3 = Color3.fromRGB(17, 18, 27)
	combo.BackgroundTransparency = 0.12
	combo.BorderSizePixel = 0
	combo.TextColor3 = Color3.fromRGB(235, 220, 255)
	combo.TextSize = 15
	combo.Font = Enum.Font.GothamBold
	combo.Text = "3-HIT COMBO"
	combo.Visible = false
	combo.Parent = gui
	corner(combo, 10)
	self.Combo = combo

	RunService.RenderStepped:Connect(function()
		self:RenderCooldowns()
	end)

	return self
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
end

function CombatUI:RenderCooldowns()
	local now = os.clock()
	for name, refs in pairs(self.Buttons) do
		local remaining = math.max(0, (self.CooldownEnds[name] or 0) - now)
		if remaining > 0 then
			refs.Cooldown.Visible = true
			refs.Cooldown.Text = string.format("%.1f", remaining)
			refs.Button.BackgroundTransparency = 0.35
		else
			refs.Cooldown.Visible = false
			refs.Button.BackgroundTransparency = 0.08
		end
	end
end

function CombatUI:ShowCombo(stage)
	self.ComboToken += 1
	local token = self.ComboToken
	local names = {"I", "II", "III"}
	self.Combo.Text = "COMBO " .. (names[stage] or tostring(stage))
	self.Combo.TextColor3 = stage == 3 and Color3.fromRGB(255, 210, 100) or Color3.fromRGB(235, 220, 255)
	self.Combo.Visible = true
	self.Combo.TextTransparency = 0
	task.delay(0.8, function()
		if token == self.ComboToken then
			self.Combo.Visible = false
		end
	end)
end

return CombatUI
