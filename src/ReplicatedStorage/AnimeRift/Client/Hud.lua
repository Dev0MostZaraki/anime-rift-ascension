local TweenService = game:GetService("TweenService")

local Hud = {}
Hud.__index = Hud

local COLORS = {
	Panel = Color3.fromRGB(13, 15, 23),
	Panel2 = Color3.fromRGB(24, 27, 39),
	Line = Color3.fromRGB(92, 82, 128),
	Text = Color3.fromRGB(239, 241, 248),
	Muted = Color3.fromRGB(160, 165, 184),
	Purple = Color3.fromRGB(143, 91, 226),
	Cyan = Color3.fromRGB(78, 203, 238),
	Red = Color3.fromRGB(223, 75, 98),
}

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

local function stroke(parent, color, transparency, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.Line
	s.Transparency = transparency or 0.45
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function gradient(parent, a, b, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = rotation or 0
	g.Parent = parent
	return g
end

local function label(parent, text, size, position, fontSize, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = position
	l.Text = text
	l.TextColor3 = COLORS.Text
	l.TextSize = fontSize or 16
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function bar(parent, size, position, fillColor)
	local back = Instance.new("Frame")
	back.Size = size
	back.Position = position
	back.BackgroundColor3 = Color3.fromRGB(35, 38, 50)
	back.BorderSizePixel = 0
	back.ClipsDescendants = true
	back.Parent = parent
	corner(back, 7)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.Parent = back
	corner(fill, 7)
	gradient(fill, fillColor:Lerp(Color3.new(1,1,1), 0.14), fillColor, 0)
	return back, fill
end

function Hud.new(player, stats, profile, config)
	local self = setmetatable({}, Hud)
	self.Player = player
	self.Stats = stats
	self.Profile = profile
	self.Config = config
	self.NoticeToken = 0
	self.HealthConnections = {}

	local playerGui = player:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("AnimeRiftHUD")
	if old then old:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AnimeRiftHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 10
	gui.Parent = playerGui
	self.Gui = gui

	-- One shared dock for Companions / Help / Arsenal / Relics. Other UI modules parent into it.
	local dock = Instance.new("Frame")
	dock.Name = "MenuDock"
	dock.AnchorPoint = Vector2.new(1, 0)
	dock.Position = UDim2.new(1, -18, 0, 92)
	dock.Size = UDim2.new(0, 154, 0, 260)
	dock.BackgroundTransparency = 1
	dock.Parent = gui
	local dockLayout = Instance.new("UIListLayout")
	dockLayout.FillDirection = Enum.FillDirection.Vertical
	dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dockLayout.Padding = UDim.new(0, 8)
	dockLayout.SortOrder = Enum.SortOrder.LayoutOrder
	dockLayout.Parent = dock
	self.MenuDock = dock

	local top = Instance.new("Frame")
	top.Name = "PlayerHeader"
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Size = UDim2.new(0, 610, 0, 86)
	top.Position = UDim2.new(0.5, 0, 0, 12)
	top.BackgroundColor3 = COLORS.Panel
	top.BackgroundTransparency = 0.04
	top.BorderSizePixel = 0
	top.Parent = gui
	corner(top, 16)
	stroke(top, Color3.fromRGB(116, 94, 165), 0.34, 1.2)
	gradient(top, Color3.fromRGB(21, 23, 34), Color3.fromRGB(12, 14, 22), 90)

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 5, 1, -20)
	accent.Position = UDim2.new(0, 10, 0, 10)
	accent.BackgroundColor3 = COLORS.Purple
	accent.BorderSizePixel = 0
	accent.Parent = top
	corner(accent, 4)
	gradient(accent, COLORS.Cyan, COLORS.Purple, 90)

	local title = label(top, "ANIME RIFT // ASCENSION", UDim2.new(0, 235, 0, 21), UDim2.new(0, 28, 0, 10), 14, true)
	title.TextColor3 = Color3.fromRGB(208, 198, 238)
	local sub = label(top, "RIFT OPERATIVE", UDim2.new(0, 150, 0, 16), UDim2.new(0, 28, 0, 31), 10, true)
	sub.TextColor3 = COLORS.Muted

	self.StatLine = label(top, "", UDim2.new(0, 328, 0, 28), UDim2.new(1, -344, 0, 14), 14, true)
	self.StatLine.TextXAlignment = Enum.TextXAlignment.Right

	local xpBack, xpFill = bar(top, UDim2.new(0, 350, 0, 13), UDim2.new(0, 28, 0, 58), COLORS.Purple)
	self.XPFill = xpFill
	self.XPText = label(xpBack, "", UDim2.fromScale(1,1), UDim2.fromScale(0,0), 10, true)
	self.XPText.TextXAlignment = Enum.TextXAlignment.Center

	local healthBack, healthFill = bar(top, UDim2.new(0, 190, 0, 13), UDim2.new(1, -206, 0, 58), COLORS.Red)
	self.HealthFill = healthFill
	self.HealthText = label(healthBack, "100 / 100", UDim2.fromScale(1,1), UDim2.fromScale(0,0), 10, true)
	self.HealthText.TextXAlignment = Enum.TextXAlignment.Center

	local missions = Instance.new("Frame")
	missions.Name = "MissionPanel"
	missions.Size = UDim2.new(0, 252, 0, 178)
	missions.Position = UDim2.new(0, 14, 0, 98)
	missions.BackgroundColor3 = COLORS.Panel
	missions.BackgroundTransparency = 0.08
	missions.BorderSizePixel = 0
	missions.Parent = gui
	corner(missions, 14)
	stroke(missions, Color3.fromRGB(89, 82, 119), 0.48)
	gradient(missions, Color3.fromRGB(20, 22, 32), Color3.fromRGB(12, 14, 21), 90)

	local missionAccent = Instance.new("Frame")
	missionAccent.Size = UDim2.new(0, 4, 0, 24)
	missionAccent.Position = UDim2.new(0, 11, 0, 10)
	missionAccent.BackgroundColor3 = COLORS.Cyan
	missionAccent.BorderSizePixel = 0
	missionAccent.Parent = missions
	corner(missionAccent, 3)
	label(missions, "ACTIVE MISSIONS", UDim2.new(1, -30, 0, 24), UDim2.new(0, 23, 0, 8), 13, true)

	self.MissionText = label(missions, "", UDim2.new(1, -24, 1, -46), UDim2.new(0, 12, 0, 40), 12, false)
	self.MissionText.TextYAlignment = Enum.TextYAlignment.Top
	self.MissionText.TextWrapped = true
	self.MissionText.RichText = true
	self.MissionText.TextColor3 = Color3.fromRGB(215, 218, 228)

	self.Notice = Instance.new("TextLabel")
	self.Notice.AnchorPoint = Vector2.new(0.5, 1)
	self.Notice.Position = UDim2.new(0.5, 0, 0.84, 0)
	self.Notice.Size = UDim2.new(0, 570, 0, 52)
	self.Notice.BackgroundColor3 = COLORS.Panel
	self.Notice.BackgroundTransparency = 0.06
	self.Notice.BorderSizePixel = 0
	self.Notice.TextColor3 = COLORS.Text
	self.Notice.TextSize = 15
	self.Notice.Font = Enum.Font.GothamBold
	self.Notice.TextWrapped = true
	self.Notice.Visible = false
	self.Notice.Parent = gui
	corner(self.Notice, 12)
	stroke(self.Notice, Color3.fromRGB(112, 95, 150), 0.38)

	self.EventBanner = Instance.new("TextLabel")
	self.EventBanner.AnchorPoint = Vector2.new(0.5, 0)
	self.EventBanner.Position = UDim2.new(0.5, 0, 0, 108)
	self.EventBanner.Size = UDim2.new(0, 390, 0, 38)
	self.EventBanner.BackgroundColor3 = Color3.fromRGB(74, 43, 104)
	self.EventBanner.BorderSizePixel = 0
	self.EventBanner.TextColor3 = Color3.fromRGB(255, 231, 164)
	self.EventBanner.TextSize = 14
	self.EventBanner.Font = Enum.Font.GothamBlack
	self.EventBanner.Visible = false
	self.EventBanner.Parent = gui
	corner(self.EventBanner, 10)
	stroke(self.EventBanner, Color3.fromRGB(205, 132, 255), 0.35)

	local hint = Instance.new("TextLabel")
	hint.AnchorPoint = Vector2.new(1, 1)
	hint.Position = UDim2.new(1, -18, 1, -18)
	hint.Size = UDim2.new(0, 226, 0, 38)
	hint.BackgroundColor3 = COLORS.Panel
	hint.BackgroundTransparency = 0.10
	hint.BorderSizePixel = 0
	hint.Text = "M1 / TAP   •   3-HIT COMBO"
	hint.TextColor3 = Color3.fromRGB(202, 191, 229)
	hint.TextSize = 12
	hint.Font = Enum.Font.GothamBold
	hint.Parent = gui
	corner(hint, 10)
	stroke(hint, Color3.fromRGB(91, 79, 122), 0.55)

	self:BindStats()
	self:BindCharacter(player.Character)
	player.CharacterAdded:Connect(function(character) self:BindCharacter(character) end)
	self:Update()
	return self
end

function Hud:BindCharacter(character)
	for _, connection in ipairs(self.HealthConnections) do connection:Disconnect() end
	table.clear(self.HealthConnections)
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	local function updateHealth()
		local maxHealth = math.max(1, humanoid.MaxHealth)
		local health = math.max(0, humanoid.Health)
		self.HealthFill.Size = UDim2.new(math.clamp(health / maxHealth, 0, 1), 0, 1, 0)
		self.HealthText.Text = math.floor(health) .. " / " .. math.floor(maxHealth) .. " HP"
	end
	table.insert(self.HealthConnections, humanoid.HealthChanged:Connect(updateHealth))
	table.insert(self.HealthConnections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth))
	updateHealth()
end

function Hud:BindStats()
	local s = self.Stats
	local p = self.Profile
	for _, value in ipairs({s.Level, s.Coins, s.Gems, s.Power, p.XP, p.QuestKills, p.QuestHatches, p.QuestBosses, p.QuestKillsDone, p.QuestHatchesDone, p.QuestBossesDone}) do
		value.Changed:Connect(function() self:Update() end)
	end
end

function Hud:Update()
	local s = self.Stats
	local p = self.Profile
	self.StatLine.Text = "LV " .. s.Level.Value .. "    ◈ " .. s.Coins.Value .. "    ◆ " .. s.Gems.Value .. "    " .. string.format("%.2fx", s.Power.Value)
	local needed = 100 + math.floor((s.Level.Value - 1) * 85)
	local ratio = math.clamp(p.XP.Value / needed, 0, 1)
	self.XPFill.Size = UDim2.new(ratio, 0, 1, 0)
	self.XPText.Text = p.XP.Value .. " / " .. needed .. " XP"

	local q1 = p.QuestKillsDone.Value and "<font color='#77D997'>DONE</font>" or (math.min(p.QuestKills.Value, 12) .. "/12")
	local q2 = p.QuestHatchesDone.Value and "<font color='#77D997'>DONE</font>" or (math.min(p.QuestHatches.Value, 3) .. "/3")
	local q3 = p.QuestBossesDone.Value and "<font color='#77D997'>DONE</font>" or (math.min(p.QuestBosses.Value, 1) .. "/1")
	self.MissionText.Text = "<b>Rift Initiate</b>  " .. q1 .. "\n<font color='#9EA3B6'>Defeat 12 enemies • 500 Coins</font>\n\n" ..
		"<b>Companion Hunter</b>  " .. q2 .. "\n<font color='#9EA3B6'>Hatch 3 companions • 300 + 5 Gems</font>\n\n" ..
		"<b>Break the Rift</b>  " .. q3 .. "\n<font color='#9EA3B6'>Defeat Rift Tyrant • 1000 + 15 Gems</font>"
end

function Hud:Notify(text, kind)
	self.NoticeToken += 1
	local token = self.NoticeToken
	local colors = {
		success = Color3.fromRGB(118, 220, 145), error = Color3.fromRGB(255, 115, 115),
		level = Color3.fromRGB(255, 216, 90), loot = Color3.fromRGB(135, 205, 255),
		event = Color3.fromRGB(220, 145, 255), world = Color3.fromRGB(255, 228, 92), boss = Color3.fromRGB(255, 92, 155),
	}
	for rarity, color in pairs(self.Config.RarityColors) do colors[rarity] = color end
	self.Notice.Text = tostring(text)
	self.Notice.TextColor3 = colors[kind] or COLORS.Text
	self.Notice.Visible = true
	self.Notice.TextTransparency = 0
	self.Notice.BackgroundTransparency = 0.06
	self.Notice.Position = UDim2.new(0.5, 0, 0.86, 8)
	TweenService:Create(self.Notice, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.84, 0)}):Play()

	task.delay(3.2, function()
		if token ~= self.NoticeToken then return end
		local tween = TweenService:Create(self.Notice, TweenInfo.new(0.28), {TextTransparency = 1, BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.82, 0)})
		tween:Play(); tween.Completed:Wait()
		if token == self.NoticeToken then self.Notice.Visible = false end
	end)
end

function Hud:ShowRiftSurge(duration)
	self.EventBanner.Visible = true
	local finish = os.clock() + (tonumber(duration) or 0)
	task.spawn(function()
		while self.EventBanner.Visible and os.clock() < finish do
			self.EventBanner.Text = "RIFT SURGE  //  2x COINS + XP  //  " .. math.max(0, math.ceil(finish - os.clock())) .. "s"
			task.wait(0.2)
		end
		self.EventBanner.Visible = false
	end)
end

return Hud
