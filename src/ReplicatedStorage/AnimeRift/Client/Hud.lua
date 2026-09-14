local TweenService = game:GetService("TweenService")

local Hud = {}
Hud.__index = Hud

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
end

local function stroke(parent, color, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(115, 105, 150)
	s.Transparency = transparency or 0.5
	s.Thickness = 1
	s.Parent = parent
end

local function label(parent, text, size, position, fontSize, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = position
	l.Text = text
	l.TextColor3 = Color3.fromRGB(235, 238, 246)
	l.TextSize = fontSize or 16
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

function Hud.new(player, stats, profile, config)
	local self = setmetatable({}, Hud)
	self.Player = player
	self.Stats = stats
	self.Profile = profile
	self.Config = config
	self.NoticeToken = 0

	local playerGui = player:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("AnimeRiftHUD")
	if old then old:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AnimeRiftHUD"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	self.Gui = gui

	local top = Instance.new("Frame")
	top.Size = UDim2.new(0, 510, 0, 70)
	top.Position = UDim2.new(0.5, -255, 0, 12)
	top.BackgroundColor3 = Color3.fromRGB(18, 20, 29)
	top.BackgroundTransparency = 0.08
	top.BorderSizePixel = 0
	top.Parent = gui
	corner(top, 14)
	stroke(top)

	local title = label(top, "ANIME RIFT ASCENSION", UDim2.new(1, -20, 0, 25), UDim2.new(0, 12, 0, 7), 17, true)
	title.TextXAlignment = Enum.TextXAlignment.Center
	self.StatLine = label(top, "", UDim2.new(1, -24, 0, 26), UDim2.new(0, 12, 0, 36), 15, true)
	self.StatLine.TextXAlignment = Enum.TextXAlignment.Center

	local xpBack = Instance.new("Frame")
	xpBack.Size = UDim2.new(0, 390, 0, 17)
	xpBack.Position = UDim2.new(0.5, -195, 0, 88)
	xpBack.BackgroundColor3 = Color3.fromRGB(30, 33, 44)
	xpBack.BorderSizePixel = 0
	xpBack.Parent = gui
	corner(xpBack, 8)

	self.XPFill = Instance.new("Frame")
	self.XPFill.Size = UDim2.new(0, 0, 1, 0)
	self.XPFill.BackgroundColor3 = Color3.fromRGB(143, 91, 226)
	self.XPFill.BorderSizePixel = 0
	self.XPFill.Parent = xpBack
	corner(self.XPFill, 8)

	self.XPText = label(xpBack, "", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 12, true)
	self.XPText.TextXAlignment = Enum.TextXAlignment.Center

	local missions = Instance.new("Frame")
	missions.Size = UDim2.new(0, 270, 0, 190)
	missions.Position = UDim2.new(0, 14, 0, 14)
	missions.BackgroundColor3 = Color3.fromRGB(18, 20, 29)
	missions.BackgroundTransparency = 0.08
	missions.BorderSizePixel = 0
	missions.Parent = gui
	corner(missions, 14)
	stroke(missions)
	label(missions, "MISSIONS", UDim2.new(1, -20, 0, 25), UDim2.new(0, 12, 0, 9), 16, true)

	self.MissionText = label(missions, "", UDim2.new(1, -24, 1, -43), UDim2.new(0, 12, 0, 38), 14, false)
	self.MissionText.TextYAlignment = Enum.TextYAlignment.Top
	self.MissionText.TextWrapped = true
	self.MissionText.RichText = true

	self.Notice = Instance.new("TextLabel")
	self.Notice.AnchorPoint = Vector2.new(0.5, 1)
	self.Notice.Position = UDim2.new(0.5, 0, 0.91, 0)
	self.Notice.Size = UDim2.new(0.58, 0, 0, 58)
	self.Notice.BackgroundColor3 = Color3.fromRGB(18, 20, 29)
	self.Notice.BackgroundTransparency = 0.05
	self.Notice.BorderSizePixel = 0
	self.Notice.TextColor3 = Color3.fromRGB(245, 240, 225)
	self.Notice.TextSize = 17
	self.Notice.Font = Enum.Font.GothamBold
	self.Notice.TextWrapped = true
	self.Notice.Visible = false
	self.Notice.Parent = gui
	corner(self.Notice, 13)
	stroke(self.Notice)

	self.EventBanner = Instance.new("TextLabel")
	self.EventBanner.AnchorPoint = Vector2.new(0.5, 0)
	self.EventBanner.Position = UDim2.new(0.5, 0, 0, 116)
	self.EventBanner.Size = UDim2.new(0, 430, 0, 46)
	self.EventBanner.BackgroundColor3 = Color3.fromRGB(112, 55, 145)
	self.EventBanner.BorderSizePixel = 0
	self.EventBanner.TextColor3 = Color3.fromRGB(255, 235, 170)
	self.EventBanner.TextSize = 18
	self.EventBanner.Font = Enum.Font.GothamBlack
	self.EventBanner.Visible = false
	self.EventBanner.Parent = gui
	corner(self.EventBanner, 12)

	local hint = Instance.new("TextLabel")
	hint.AnchorPoint = Vector2.new(1, 1)
	hint.Position = UDim2.new(1, -18, 1, -20)
	hint.Size = UDim2.new(0, 255, 0, 45)
	hint.BackgroundColor3 = Color3.fromRGB(18, 20, 29)
	hint.BackgroundTransparency = 0.12
	hint.BorderSizePixel = 0
	hint.Text = "Rift Blade - CLICK / TAP"
	hint.TextColor3 = Color3.fromRGB(230, 215, 255)
	hint.TextSize = 15
	hint.Font = Enum.Font.GothamBold
	hint.Parent = gui
	corner(hint, 11)

	self:BindStats()
	self:Update()
	return self
end

function Hud:BindStats()
	local s = self.Stats
	local p = self.Profile
	for _, value in ipairs({s.Level, s.Coins, s.Gems, s.Power, p.XP, p.QuestKills, p.QuestHatches, p.QuestBosses, p.QuestKillsDone, p.QuestHatchesDone, p.QuestBossesDone}) do
		value.Changed:Connect(function()
			self:Update()
		end)
	end
end

function Hud:Update()
	local s = self.Stats
	local p = self.Profile
	self.StatLine.Text = "Lv." .. s.Level.Value .. "   |   " .. s.Coins.Value .. " Coins   |   " .. s.Gems.Value .. " Gems   |   " .. string.format("%.2fx", s.Power.Value) .. " Power"
	local needed = 100 + math.floor((s.Level.Value - 1) * 85)
	local ratio = math.clamp(p.XP.Value / needed, 0, 1)
	self.XPFill.Size = UDim2.new(ratio, 0, 1, 0)
	self.XPText.Text = p.XP.Value .. " / " .. needed .. " XP"

	local q1 = p.QuestKillsDone.Value and "DONE" or (math.min(p.QuestKills.Value, 12) .. "/12")
	local q2 = p.QuestHatchesDone.Value and "DONE" or (math.min(p.QuestHatches.Value, 3) .. "/3")
	local q3 = p.QuestBossesDone.Value and "DONE" or (math.min(p.QuestBosses.Value, 1) .. "/1")
	self.MissionText.Text = "<b>Rift Initiate</b>  " .. q1 .. "\nDefeat 12 enemies - 500 Coins\n\n" ..
		"<b>Companion Hunter</b>  " .. q2 .. "\nHatch 3 companions - 300 Coins + 5 Gems\n\n" ..
		"<b>Break the Rift</b>  " .. q3 .. "\nDefeat Rift Tyrant - 1000 Coins + 15 Gems"
end

function Hud:Notify(text, kind)
	self.NoticeToken += 1
	local token = self.NoticeToken
	local colors = {
		success = Color3.fromRGB(118, 220, 145),
		error = Color3.fromRGB(255, 115, 115),
		level = Color3.fromRGB(255, 216, 90),
		loot = Color3.fromRGB(135, 205, 255),
		event = Color3.fromRGB(220, 145, 255),
		world = Color3.fromRGB(255, 228, 92),
		boss = Color3.fromRGB(255, 92, 155),
	}
	for rarity, color in pairs(self.Config.RarityColors) do colors[rarity] = color end
	self.Notice.Text = tostring(text)
	self.Notice.TextColor3 = colors[kind] or Color3.fromRGB(240, 240, 245)
	self.Notice.Visible = true
	self.Notice.TextTransparency = 0
	self.Notice.BackgroundTransparency = 0.05

	task.delay(3.2, function()
		if token ~= self.NoticeToken then return end
		local tween = TweenService:Create(self.Notice, TweenInfo.new(0.3), {TextTransparency = 1, BackgroundTransparency = 1})
		tween:Play()
		tween.Completed:Wait()
		if token == self.NoticeToken then self.Notice.Visible = false end
	end)
end

function Hud:ShowRiftSurge(duration)
	self.EventBanner.Visible = true
	local finish = os.clock() + (tonumber(duration) or 0)
	task.spawn(function()
		while self.EventBanner.Visible and os.clock() < finish do
			self.EventBanner.Text = "RIFT SURGE - 2x COINS & XP - " .. math.max(0, math.ceil(finish - os.clock())) .. "s"
			task.wait(0.2)
		end
		self.EventBanner.Visible = false
	end)
end

return Hud
