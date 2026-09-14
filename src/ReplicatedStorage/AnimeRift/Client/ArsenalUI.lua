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

local function gradient(parent, a, b)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = 90
	g.Parent = parent
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
	b.Position = position or UDim2.new()
	b.BackgroundColor3 = color or Color3.fromRGB(68, 57, 98)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(248, 248, 252)
	b.TextSize = 13
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 10)
	stroke(b, b.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.20), 0.58)
	gradient(b, b.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.06), b.BackgroundColor3:Lerp(Color3.new(0,0,0), 0.08))
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

	local dock = gui:FindFirstChild("MenuDock") or gui
	self.OpenButton = button(dock, "ARSENAL", UDim2.new(1, 0, 0, 42), UDim2.new(), Color3.fromRGB(75, 49, 101))
	self.OpenButton.LayoutOrder = 30

	self.Panel = Instance.new("Frame")
	self.Panel.Name = "ArsenalPanel"
	self.Panel.Size = UDim2.new(0, 650, 0, 500)
	self.Panel.Position = UDim2.new(0.5, -325, 0.5, -250)
	self.Panel.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
	self.Panel.BorderSizePixel = 0
	self.Panel.Visible = false
	self.Panel.Parent = gui
	corner(self.Panel, 18)
	stroke(self.Panel, Color3.fromRGB(140, 116, 156), 0.34)
	gradient(self.Panel, Color3.fromRGB(24, 23, 30), Color3.fromRGB(13, 15, 20))

	label(self.Panel, "RIFT ARSENAL", UDim2.new(1, -90, 0, 38), UDim2.new(0, 18, 0, 12), 22, true)
	local sub = label(self.Panel, "Every style now changes survivability as well as damage, range and tempo.", UDim2.new(1, -120, 0, 30), UDim2.new(0, 18, 0, 48), 12, false)
	sub.TextColor3 = Color3.fromRGB(174, 177, 185)
	local close = button(self.Panel, "X", UDim2.new(0, 42, 0, 36), UDim2.new(1, -56, 0, 10), Color3.fromRGB(61, 55, 66))

	self.List = Instance.new("ScrollingFrame")
	self.List.Size = UDim2.new(1, -28, 1, -94)
	self.List.Position = UDim2.new(0, 14, 0, 82)
	self.List.BackgroundColor3 = Color3.fromRGB(23, 25, 31)
	self.List.BackgroundTransparency = 0.04
	self.List.BorderSizePixel = 0
	self.List.ScrollBarThickness = 5
	self.List.ScrollBarImageColor3 = Color3.fromRGB(111, 103, 119)
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
		row.Size = UDim2.new(1, -4, 0, 104)
		row.BackgroundColor3 = equipped and Color3.fromRGB(40, 43, 48) or Color3.fromRGB(31, 33, 38)
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = self.List
		corner(row, 12)
		stroke(row, equipped and style.Color or Color3.fromRGB(82, 82, 84), equipped and 0.52 or 0.82)

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 6, 1, -14)
		bar.Position = UDim2.new(0, 7, 0, 7)
		bar.BackgroundColor3 = style.Color
		bar.BorderSizePixel = 0
		bar.Parent = row
		corner(bar, 4)

		label(row, string.upper(style.Name), UDim2.new(0.42, 0, 0, 24), UDim2.new(0, 24, 0, 8), 15, true)
		local desc = label(row, style.Description, UDim2.new(0.56, 0, 0, 34), UDim2.new(0, 24, 0, 31), 11, false)
		desc.TextWrapped = true
		desc.TextColor3 = Color3.fromRGB(188, 188, 183)

		local offense = string.format("DMG x%.2f   /   %.2fs   /   %.1f RANGE   /   +%.0f%% CRIT", style.DamageMultiplier, style.AttackCooldown, style.Range, style.CritBonus * 100)
		local offenseLine = label(row, offense, UDim2.new(0.66, 0, 0, 18), UDim2.new(0, 24, 0, 67), 10, true)
		offenseLine.TextColor3 = style.Color
		local defense = string.format("HP x%.2f   /   DEF %+d", style.HealthMultiplier or 1, style.DefenseBonus or 0)
		local defenseLine = label(row, defense, UDim2.new(0.44, 0, 0, 18), UDim2.new(0, 24, 0, 84), 10, true)
		defenseLine.TextColor3 = Color3.fromRGB(166, 201, 174)

		local masteryLabel = label(row, "MASTERY " .. mastery .. "  •  +" .. string.format("%.1f", masteryBonus * 100) .. "% DMG", UDim2.new(0, 190, 0, 20), UDim2.new(1, -322, 0, 12), 10, true)
		masteryLabel.TextXAlignment = Enum.TextXAlignment.Right
		masteryLabel.TextColor3 = Color3.fromRGB(193, 196, 200)

		local actionText, actionColor
		if equipped then
			actionText, actionColor = "EQUIPPED", Color3.fromRGB(58, 105, 74)
		elseif unlocked then
			actionText, actionColor = "EQUIP", Color3.fromRGB(70, 70, 84)
		else
			actionText = "UNLOCK  LV." .. style.UnlockLevel .. "  •  " .. style.UnlockCost
			actionColor = Color3.fromRGB(112, 65, 61)
		end
		local action = button(row, actionText, UDim2.new(0, 194, 0, 38), UDim2.new(1, -206, 0, 47), actionColor)
		action.TextSize = 11
		action.Active = not equipped
		if not equipped then action.Activated:Connect(function() self.StyleRemote:FireServer(style.Id) end) end
	end
end

return ArsenalUI
