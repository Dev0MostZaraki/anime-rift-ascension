local UserInputService = game:GetService("UserInputService")

local DevUI = {}
DevUI.__index = DevUI

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
end

local function stroke(parent, color, transparency, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(255, 90, 135)
	s.Transparency = transparency or 0.35
	s.Thickness = thickness or 1
	s.Parent = parent
end

local function text(parent, value, size, position, textSize, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Text = value
	label.TextColor3 = Color3.fromRGB(240, 242, 250)
	label.TextSize = textSize or 14
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function button(parent, title, subtitle, order, color, callback)
	local b = Instance.new("TextButton")
	b.Name = title
	b.LayoutOrder = order
	b.Size = UDim2.new(0.5, -6, 0, 62)
	b.BackgroundColor3 = color or Color3.fromRGB(46, 48, 66)
	b.BackgroundTransparency = 0.05
	b.BorderSizePixel = 0
	b.Text = ""
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 10)
	stroke(b, (color or Color3.fromRGB(90, 90, 120)):Lerp(Color3.new(1, 1, 1), 0.25), 0.6)

	local titleLabel = text(b, title, UDim2.new(1, -18, 0, 24), UDim2.new(0, 10, 0, 8), 14, true)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	local sub = text(b, subtitle or "", UDim2.new(1, -18, 0, 20), UDim2.new(0, 10, 0, 34), 11, false)
	sub.TextColor3 = Color3.fromRGB(190, 194, 208)
	sub.TextXAlignment = Enum.TextXAlignment.Center
	b.Activated:Connect(callback)
	return b
end

function DevUI.new(gui, player, remote)
	if player:GetAttribute("AnimeRiftDev") ~= true then return nil end
	local self = setmetatable({}, DevUI)
	self.Remote = remote

	local open = Instance.new("TextButton")
	open.Name = "DevButton"
	open.AnchorPoint = Vector2.new(0, 1)
	open.Position = UDim2.new(0, 14, 1, -18)
	open.Size = UDim2.new(0, 86, 0, 38)
	open.BackgroundColor3 = Color3.fromRGB(120, 35, 62)
	open.BorderSizePixel = 0
	open.Text = "DEV  [F8]"
	open.TextColor3 = Color3.fromRGB(255, 225, 235)
	open.TextSize = 13
	open.Font = Enum.Font.GothamBold
	open.Parent = gui
	corner(open, 10)
	stroke(open, Color3.fromRGB(255, 95, 145), 0.25, 1.2)
	self.OpenButton = open

	local panel = Instance.new("Frame")
	panel.Name = "DevPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0, 610, 0, 540)
	panel.BackgroundColor3 = Color3.fromRGB(14, 15, 22)
	panel.BackgroundTransparency = 0.02
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	corner(panel, 16)
	stroke(panel, Color3.fromRGB(255, 75, 130), 0.18, 1.5)
	self.Panel = panel

	local title = text(panel, "DEVELOPER CONTROL ROOM", UDim2.new(1, -80, 0, 30), UDim2.new(0, 18, 0, 14), 20, true)
	title.TextColor3 = Color3.fromRGB(255, 160, 195)
	local note = text(panel, "Server-authorized testing tools • hidden from normal players", UDim2.new(1, -90, 0, 20), UDim2.new(0, 18, 0, 44), 11, false)
	note.TextColor3 = Color3.fromRGB(165, 170, 188)

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 42, 0, 36)
	close.Position = UDim2.new(1, -56, 0, 14)
	close.BackgroundColor3 = Color3.fromRGB(78, 32, 48)
	close.BorderSizePixel = 0
	close.Text = "X"
	close.TextColor3 = Color3.new(1, 1, 1)
	close.TextSize = 15
	close.Font = Enum.Font.GothamBold
	close.Parent = panel
	corner(close, 9)

	local list = Instance.new("ScrollingFrame")
	list.Name = "Controls"
	list.Size = UDim2.new(1, -28, 1, -88)
	list.Position = UDim2.new(0, 14, 0, 76)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 5
	list.ScrollBarImageColor3 = Color3.fromRGB(108, 88, 125)
	list.Parent = panel

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -7, 0, 62)
	grid.CellPadding = UDim2.new(0, 12, 0, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = list

	local function send(command)
		remote:FireServer(command)
	end

	button(list, "TEST READY", "Lv25 • resources • unlocks", 1, Color3.fromRGB(110, 43, 105), function() send("TestReady") end)
	button(list, "GO TO BOSS", "Teleport to Rift Tyrant", 2, Color3.fromRGB(126, 38, 72), function() send("Boss") end)
	button(list, "+10 LEVELS", "Fast progression test", 3, Color3.fromRGB(75, 65, 125), function() send("Level10") end)
	button(list, "+10K COINS", "Economy testing", 4, Color3.fromRGB(95, 72, 42), function() send("Coins10K") end)
	button(list, "+100 GEMS", "Premium currency test", 5, Color3.fromRGB(52, 88, 120), function() send("Gems100") end)
	button(list, "UNLOCK ZONES", "Open every region", 6, Color3.fromRGB(48, 92, 82), function() send("UnlockZones") end)
	button(list, "UNLOCK STYLES", "Open full Arsenal", 7, Color3.fromRGB(78, 62, 120), function() send("UnlockStyles") end)
	button(list, "TEST RELIC", "Boss-tier Void relic roll", 8, Color3.fromRGB(115, 72, 36), function() send("TestRelic") end)
	button(list, "FULL HEAL", "Restore current character", 9, Color3.fromRGB(52, 105, 72), function() send("Heal") end)
	button(list, "RESET COOLDOWNS", "Q / E / R / combo / dash", 10, Color3.fromRGB(45, 88, 125), function() send("ResetCooldowns") end)
	button(list, "RESPAWN BOSS", "Fresh Rift Tyrant instance", 11, Color3.fromRGB(130, 48, 72), function() send("RespawnBoss") end)
	button(list, "SPAWN RARE", "Force named hunt in current region", 12, Color3.fromRGB(128, 94, 38), function() send("Rare") end)
	button(list, "RIFT SURGE", "Force 60s double rewards", 13, Color3.fromRGB(105, 47, 135), function() send("Surge") end)
	button(list, "RETURN TO HUB", "Instant safe teleport", 14, Color3.fromRGB(60, 64, 82), function() send("Hub") end)
	button(list, "SAVE NOW", "Request DataStore save", 15, Color3.fromRGB(62, 85, 65), function() send("Save") end)

	local function toggle()
		panel.Visible = not panel.Visible
	end
	open.Activated:Connect(toggle)
	close.Activated:Connect(function() panel.Visible = false end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.F8 then toggle() end
	end)

	return self
end

return DevUI
