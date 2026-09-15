local RegionalQuestUI = {}
RegionalQuestUI.__index = RegionalQuestUI

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
end

local function stroke(parent)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(92, 96, 116)
	s.Transparency = 0.48
	s.Thickness = 1
	s.Parent = parent
end

local function label(parent, text, size, position, font, textSize, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = position
	l.Text = text
	l.TextColor3 = color or Color3.fromRGB(228, 230, 236)
	l.TextSize = textSize or 12
	l.Font = font or Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.TextWrapped = true
	l.Parent = parent
	return l
end

function RegionalQuestUI.new(parent, player, profile, coreConfig)
	local self = setmetatable({}, RegionalQuestUI)
	self.Player = player
	self.Profile = profile
	self.Config = coreConfig

	local panel = Instance.new("Frame")
	panel.Name = "RegionalQuestPanel"
	panel.Size = UDim2.new(0, 252, 0, 126)
	panel.Position = UDim2.new(0, 14, 0, 286)
	panel.BackgroundColor3 = Color3.fromRGB(13, 15, 23)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = parent
	corner(panel, 14)
	stroke(panel)
	self.Panel = panel

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 4, 0, 25)
	accent.Position = UDim2.new(0, 11, 0, 10)
	accent.BackgroundColor3 = Color3.fromRGB(227, 190, 104)
	accent.BorderSizePixel = 0
	accent.Parent = panel
	corner(accent, 3)
	self.Accent = accent

	self.Kicker = label(panel, "REGION QUEST", UDim2.new(1, -30, 0, 18), UDim2.new(0, 23, 0, 9), Enum.Font.GothamBold, 10, Color3.fromRGB(158, 164, 180))
	self.Title = label(panel, "", UDim2.new(1, -30, 0, 22), UDim2.new(0, 23, 0, 26), Enum.Font.GothamBold, 13)
	self.Description = label(panel, "", UDim2.new(1, -24, 0, 37), UDim2.new(0, 12, 0, 52), Enum.Font.Gotham, 11, Color3.fromRGB(184, 190, 204))
	self.Progress = label(panel, "", UDim2.new(0.5, -12, 0, 21), UDim2.new(0, 12, 1, -28), Enum.Font.GothamBold, 11, Color3.fromRGB(230, 198, 115))
	self.Reward = label(panel, "", UDim2.new(0.5, -10, 0, 21), UDim2.new(0.5, 0, 1, -28), Enum.Font.GothamBold, 10, Color3.fromRGB(126, 199, 157))
	self.Reward.TextXAlignment = Enum.TextXAlignment.Right

	local regional = profile:WaitForChild("RegionalQuest", 12)
	self.Regional = regional
	if regional then
		for zoneId in pairs(coreConfig.RegionQuestChains) do
			local stage = regional:FindFirstChild("Zone" .. zoneId .. "Stage")
			local progress = regional:FindFirstChild("Zone" .. zoneId .. "Progress")
			if stage then stage.Changed:Connect(function() self:Update() end) end
			if progress then progress.Changed:Connect(function() self:Update() end) end
		end
	end
	player:GetAttributeChangedSignal("OpenWorldRegion"):Connect(function() self:Update() end)
	self:Update()
	return self
end

function RegionalQuestUI:GetZoneId()
	local regionName = self.Player:GetAttribute("OpenWorldRegion")
	if type(regionName) ~= "string" then return nil end
	for zoneId, chain in pairs(self.Config.RegionQuestChains) do
		if chain.Region == regionName then return zoneId end
	end
	return nil
end

function RegionalQuestUI:Update()
	if not self.Regional then self.Panel.Visible = false return end
	local zoneId = self:GetZoneId()
	local chain = zoneId and self.Config.RegionQuestChains[zoneId]
	if not chain then self.Panel.Visible = false return end

	local stageValue = self.Regional:FindFirstChild("Zone" .. zoneId .. "Stage")
	local progressValue = self.Regional:FindFirstChild("Zone" .. zoneId .. "Progress")
	if not stageValue or not progressValue then self.Panel.Visible = false return end
	self.Panel.Visible = true

	local stage = stageValue.Value
	local step = chain[stage]
	local zoneColors = {
		[1] = Color3.fromRGB(98, 151, 91),
		[2] = Color3.fromRGB(190, 102, 66),
		[3] = Color3.fromRGB(128, 173, 194),
		[4] = Color3.fromRGB(147, 105, 164),
	}
	self.Accent.BackgroundColor3 = zoneColors[zoneId] or Color3.fromRGB(227, 190, 104)
	self.Kicker.Text = string.upper(chain.Region) .. " • REGION QUEST"

	if not step then
		self.Title.Text = "QUEST CHAIN MASTERED"
		self.Description.Text = "You have completed the regional hunt chain. Explore for caches, eggs and world events."
		self.Progress.Text = "COMPLETE"
		self.Reward.Text = ""
		return
	end

	self.Title.Text = step.Title
	self.Description.Text = step.Description
	self.Progress.Text = tostring(math.min(progressValue.Value, step.Target)) .. " / " .. tostring(step.Target)
	local reward = tostring(step.Coins or 0) .. " Coins"
	if (step.Gems or 0) > 0 then reward ..= " • " .. tostring(step.Gems) .. " Gems" end
	self.Reward.Text = reward
end

return RegionalQuestUI
