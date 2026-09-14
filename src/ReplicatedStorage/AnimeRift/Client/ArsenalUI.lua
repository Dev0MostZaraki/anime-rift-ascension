local ArsenalUI = {}
ArsenalUI.__index = ArsenalUI

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
end

local function stroke(parent, color, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(125, 105, 175)
	s.Transparency = transparency or 0.45
	s.Thickness = 1
	s.Parent = parent
end

local function label(parent, text, size, position, fontSize, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = position
	l.Text = text
	l.TextColor3 = Color3.fromRGB(238, 240, 248)
	l.TextSize = fontSize or 14
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function button(parent, text, size, position, color)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = position
	b.BackgroundColor3 = color or Color3.fromRGB(75, 61, 112)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(248, 248, 252)
	b.TextSize = 14
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 9)
	return b
end

function ArsenalUI.new(gui, player, profile, stats, config, styleRemote)
	local self = setmetatable({}, ArsenalUI)
	self.Gui = gui
	self.Player = player
	self.Profile = profile
	self.Stats = stats
	self.Config = config
	self.StyleRemote = styleRemote
	self.Connections = {}

	self.OpenButton = button(gui, "ARSENAL", UDim2.new(0, 150, 0, 46), UDim2.new(1, -166, 0, 126), Color3.fromRGB(93, 57, 132))
	self.Panel = Instance.new("Frame")
	self.Panel.Name = "ArsenalPanel"
	self.Panel.Size = UDim2.new(0, 610, 0, 470)
	self.Panel.Position = UDim2.new(0.5, -305, 0.5, -235)
	self.Panel.BackgroundColor3 = Color3.fromRGB(17, 19, 28)
	self.Panel.BorderSizePixel = 0
	self.Panel.Visible = false
	self.Panel.Parent = gui
	corner(self.Panel, 16)
	stroke(self.Panel, Color3.fromRGB(170, 100, 235), 0.25)

	label(self.Panel, "RIFT ARSENAL", UDim2.new(1, -90, 0, 38), UDim2.new(0, 18, 0, 12), 22, true)
	local sub = label(self.Panel, "Unlock fighting styles, build mastery, and change your combat identity.", UDim2.new(1, -110, 0, 30), UDim2.new(0, 18, 0, 48), 13, false)
	sub.TextColor3 = Color3.fromRGB(180, 180, 200)
	local close = button(self.Panel, "X", UDim2.new(0, 42, 0, 36), UDim2.new(1, -56, 0, 10))

	self.List = Instance.new("ScrollingFrame")
	self.List.Size = UDim2.new(1, -28, 1, -94)
	self.List.Position = UDim2.new(0, 14, 0, 82)
	self.List.BackgroundColor3 = Color3.fromRGB(24, 27, 38)
	self.List.BorderSizePixel = 0
	self.List.ScrollBarThickness = 6
	self.List.CanvasSize = UDim2.new()
	self.List.Parent = self.Panel
	corner(self.List, 12)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = self.List
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom, pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8)
	pad.Parent = self.List
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.List.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end)

	self.OpenButton.Activated:Connect(function()
		self.Panel.Visible = not self.Panel.Visible
		if self.Panel.Visible then self:Rebuild() end
	end)
	close.Activated:Connect(function() self.Panel.Visible = false end)
	profile.EquippedStyle.Changed:Connect(function() self:Rebuild() end)
	stats.Coins.Changed:Connect(function() if self.Panel.Visible then self:Rebuild() end end)
	stats.Level.Changed:Connect(function() if self.Panel.Visible then self:Rebuild() end end)
	for _, value in ipairs(profile.StyleUnlocks:GetChildren()) do value.Changed:Connect(function() self:Rebuild() end) end
	for _, value in ipairs(profile.StyleMastery:GetChildren()) do value.Changed:Connect(function() if self.Panel.Visible then self:Rebuild() end end) end

	self:Rebuild()
	return self
end

function ArsenalUI:Rebuild()
	for _, child in ipairs(self.List:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	for _, connection in ipairs(self.Connections) do if connection.Connected then connection:Disconnect() end end
	table.clear(self.Connections)

	local styles = {}
	for _, style in pairs(self.Config.Styles) do table.insert(styles, style) end
	table.sort(styles, function(a, b) return (a.Order or 99) < (b.Order or 99) end)

	for index, style in ipairs(styles) do
		local unlockedValue = self.Profile.StyleUnlocks:FindFirstChild(style.Id)
		local masteryValue = self.Profile.StyleMastery:FindFirstChild(style.Id)
		local unlocked = unlockedValue and unlockedValue.Value
		local equipped = self.Profile.EquippedStyle.Value == style.Id
		local mastery = masteryValue and masteryValue.Value or 0
		local masteryBonus = math.min(self.Config.Game.MasteryDamageCap, mastery * self.Config.Game.MasteryDamagePerPoint)

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -4, 0, 88)
		row.BackgroundColor3 = equipped and Color3.fromRGB(43, 51, 66) or Color3.fromRGB(32, 35, 48)
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = self.List
		corner(row, 11)

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 7, 1, -12)
		bar.Position = UDim2.new(0, 6, 0, 6)
		bar.BackgroundColor3 = style.Color
		bar.BorderSizePixel = 0
		bar.Parent = row
		corner(bar, 4)

		label(row, style.Name, UDim2.new(0.42, 0, 0, 24), UDim2.new(0, 24, 0, 8), 16, true)
		local desc = label(row, style.Description, UDim2.new(0.56, 0, 0, 34), UDim2.new(0, 24, 0, 30), 11, false)
		desc.TextWrapped = true
		desc.TextColor3 = Color3.fromRGB(186, 188, 202)
		local statsText = string.format("DMG x%.2f  •  %.2fs  •  Range %.1f  •  Crit +%.0f%%", style.DamageMultiplier, style.AttackCooldown, style.Range, style.CritBonus * 100)
		local statLine = label(row, statsText, UDim2.new(0.62, 0, 0, 20), UDim2.new(0, 24, 1, -23), 11, true)
		statLine.TextColor3 = style.Color

		local masteryLabel = label(row, "Mastery " .. mastery .. "  •  +" .. string.format("%.1f", masteryBonus * 100) .. "% DMG", UDim2.new(0, 180, 0, 20), UDim2.new(1, -310, 0, 12), 11, true)
		masteryLabel.TextXAlignment = Enum.TextXAlignment.Right

		local actionText
		local actionColor
		if equipped then
			actionText, actionColor = "EQUIPPED", Color3.fromRGB(55, 120, 82)
		elseif unlocked then
			actionText, actionColor = "EQUIP", Color3.fromRGB(83, 76, 145)
		else
			actionText = "UNLOCK  Lv." .. style.UnlockLevel .. " • " .. style.UnlockCost
			actionColor = Color3.fromRGB(135, 76, 70)
		end
		local action = button(row, actionText, UDim2.new(0, 190, 0, 38), UDim2.new(1, -202, 0, 38), actionColor)
		action.TextSize = 12
		action.Active = not equipped
		if not equipped then action.Activated:Connect(function() self.StyleRemote:FireServer(style.Id) end) end
	end
end

return ArsenalUI
