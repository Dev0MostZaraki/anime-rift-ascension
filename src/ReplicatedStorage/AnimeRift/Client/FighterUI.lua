local FighterUI = {}
FighterUI.__index = FighterUI

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
end

local function stroke(parent, color, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(126, 96, 174)
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
	b.BackgroundColor3 = color or Color3.fromRGB(65, 50, 94)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(248, 248, 252)
	b.TextSize = 12
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 9)
	stroke(b, b.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.2), 0.58)
	return b
end

function FighterUI.new(gui, player, inventory, fighterProfile, config, remote)
	local self = setmetatable({}, FighterUI)
	self.Gui = gui
	self.Player = player
	self.Inventory = inventory
	self.Profile = fighterProfile
	self.Config = config
	self.Remote = remote
	self.Connections = {}

	local dock = gui:FindFirstChild("MenuDock") or gui
	self.OpenButton = button(dock, "FIGHTERS", UDim2.new(1, 0, 0, 42), UDim2.new(), Color3.fromRGB(82, 51, 113))
	self.OpenButton.LayoutOrder = 15

	local panel = Instance.new("Frame")
	panel.Name = "FighterPanel"
	panel.Size = UDim2.new(0, 650, 0, 510)
	panel.Position = UDim2.new(0.5, -325, 0.5, -255)
	panel.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	corner(panel, 18)
	stroke(panel, Color3.fromRGB(167, 95, 230), 0.28)
	self.Panel = panel

	label(panel, "RIFT FIGHTER ARCHIVE", UDim2.new(1, -100, 0, 32), UDim2.new(0, 18, 0, 12), 20, true)
	local sub = label(panel, "Build a three-Fighter team. Duplicates become Soul Shards.", UDim2.new(1, -120, 0, 22), UDim2.new(0, 18, 0, 43), 11, false)
	sub.TextColor3 = Color3.fromRGB(164, 168, 187)
	local close = button(panel, "X", UDim2.new(0, 42, 0, 36), UDim2.new(1, -56, 0, 10), Color3.fromRGB(67, 44, 79))

	self.ShardsLabel = label(panel, "Soul Shards 0", UDim2.new(0, 170, 0, 20), UDim2.new(0, 18, 0, 71), 12, true)
	self.PityLabel = label(panel, "Mythic Pity 0/80", UDim2.new(0, 170, 0, 20), UDim2.new(0, 190, 0, 71), 12, true)
	self.CurrencyLabel = label(panel, "0 Gems • 0 Tickets", UDim2.new(0, 250, 0, 20), UDim2.new(1, -268, 0, 71), 12, true)
	self.CurrencyLabel.TextXAlignment = Enum.TextXAlignment.Right

	local summonOne = button(panel, "SUMMON x1 • 60 GEMS", UDim2.new(0, 178, 0, 36), UDim2.new(0, 18, 0, 101), Color3.fromRGB(66, 62, 125))
	local summonTen = button(panel, "SUMMON x10 • 540 GEMS", UDim2.new(0, 198, 0, 36), UDim2.new(0, 205, 0, 101), Color3.fromRGB(105, 55, 130))
	local ticketOne = button(panel, "TICKET x1", UDim2.new(0, 116, 0, 36), UDim2.new(0, 412, 0, 101), Color3.fromRGB(56, 91, 112))
	local pityInfo = label(panel, "Soft pity 55 • Hard pity 80 • 10x guarantees Epic+", UDim2.new(1, -36, 0, 20), UDim2.new(0, 18, 0, 143), 10, false)
	pityInfo.TextColor3 = Color3.fromRGB(153, 157, 176)

	self.LastPull = label(panel, "No summons yet this session.", UDim2.new(1, -36, 0, 38), UDim2.new(0, 18, 0, 165), 12, true)
	self.LastPull.TextWrapped = true
	self.LastPull.TextColor3 = Color3.fromRGB(205, 187, 235)

	self.List = Instance.new("ScrollingFrame")
	self.List.Size = UDim2.new(1, -28, 1, -220)
	self.List.Position = UDim2.new(0, 14, 0, 207)
	self.List.BackgroundColor3 = Color3.fromRGB(21, 24, 35)
	self.List.BackgroundTransparency = 0.08
	self.List.BorderSizePixel = 0
	self.List.ScrollBarThickness = 5
	self.List.ScrollBarImageColor3 = Color3.fromRGB(123, 91, 159)
	self.List.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.List.Parent = panel
	corner(self.List, 12)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 7)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.List
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = self.List
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.List.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end)

	self.OpenButton.Activated:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then self:Rebuild() end
	end)
	close.Activated:Connect(function() panel.Visible = false end)
	summonOne.Activated:Connect(function() remote:FireServer("Summon", "Gems", 1) end)
	summonTen.Activated:Connect(function() remote:FireServer("Summon", "Gems", 10) end)
	ticketOne.Activated:Connect(function() remote:FireServer("Summon", "Tickets", 1) end)

	remote.OnClientEvent:Connect(function(action, payload)
		if action ~= "SummonResults" or type(payload) ~= "table" then return end
		self:ShowResults(payload)
		self:Rebuild()
	end)

	local stats = player:WaitForChild("leaderstats")
	local progression = player:WaitForChild("RiftProfile"):WaitForChild("Progression")
	self.Gems = stats:WaitForChild("Gems")
	self.Tickets = progression:WaitForChild("RiftTickets")
	self.Shards = fighterProfile:WaitForChild("SoulShards")
	self.Pity = fighterProfile:WaitForChild("MythicPity")
	local function refreshHeader()
		self.ShardsLabel.Text = "Soul Shards " .. tostring(self.Shards.Value)
		self.PityLabel.Text = string.format("Mythic Pity %d/%d", self.Pity.Value, config.Settings.HardPity)
		self.CurrencyLabel.Text = string.format("%d Gems • %d Tickets", self.Gems.Value, self.Tickets.Value)
	end
	refreshHeader()
	self.Gems.Changed:Connect(refreshHeader)
	self.Tickets.Changed:Connect(refreshHeader)
	self.Shards.Changed:Connect(refreshHeader)
	self.Pity.Changed:Connect(refreshHeader)
	inventory.ChildAdded:Connect(function() self:Rebuild() end)
	inventory.ChildRemoved:Connect(function() self:Rebuild() end)
	self:Rebuild()
	return self
end

function FighterUI:ShowResults(results)
	if #results == 0 then return end
	local parts = {}
	local bestRank = 0
	local bestColor = Color3.fromRGB(205, 187, 235)
	for _, result in ipairs(results) do
		local rarityData = self.Config.Rarities[result.Rarity]
		local rank = rarityData and rarityData.Rank or 1
		if rank > bestRank then
			bestRank = rank
			bestColor = rarityData.Color
		end
		local suffix = result.Duplicate and (" +" .. tostring(result.Shards) .. " shards") or (" [" .. tostring(result.Trait) .. "]")
		table.insert(parts, result.Name .. suffix)
	end
	if #parts > 4 then
		self.LastPull.Text = table.concat({parts[1], parts[2], parts[3], "…", parts[#parts]}, " • ")
	else
		self.LastPull.Text = table.concat(parts, " • ")
	end
	self.LastPull.TextColor3 = bestColor
end

function FighterUI:Rebuild()
	for _, child in ipairs(self.List:GetChildren()) do if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end end
	for _, connection in ipairs(self.Connections) do if connection.Connected then connection:Disconnect() end end
	table.clear(self.Connections)

	local fighters = self.Inventory:GetChildren()
	table.sort(fighters, function(a, b)
		local ar = self.Config.Rarities[tostring(a:GetAttribute("Rarity"))]
		local br = self.Config.Rarities[tostring(b:GetAttribute("Rarity"))]
		local aRank = ar and ar.Rank or 0
		local bRank = br and br.Rank or 0
		if aRank ~= bRank then return aRank > bRank end
		local aSlot = tonumber(a:GetAttribute("EquippedSlot")) or 0
		local bSlot = tonumber(b:GetAttribute("EquippedSlot")) or 0
		if (aSlot > 0) ~= (bSlot > 0) then return aSlot > 0 end
		return a.Value < b.Value
	end)

	if #fighters == 0 then
		local empty = label(self.List, "No Fighters owned yet. Use Gems or a Rift Ticket to summon your first one.", UDim2.new(1, -30, 0, 68), UDim2.new(0, 14, 0, 14), 13, false)
		empty.TextWrapped = true
		empty.TextColor3 = Color3.fromRGB(166, 170, 188)
		return
	end

	for index, fighter in ipairs(fighters) do
		local rarity = tostring(fighter:GetAttribute("Rarity") or "Rare")
		local rarityData = self.Config.Rarities[rarity] or self.Config.Rarities.Rare
		local definition = self.Config.GetById(fighter.Name)
		local slot = tonumber(fighter:GetAttribute("EquippedSlot")) or 0
		local equipped = slot > 0
		local trait = tostring(fighter:GetAttribute("Trait") or "Normal")
		local traitPower = tonumber(fighter:GetAttribute("TraitPowerMultiplier")) or 1
		local copies = tonumber(fighter:GetAttribute("Copies")) or 1
		local teamPower = (rarityData.TeamPower or 0) * traitPower
		local element = definition and definition.Element or "Unknown"
		local role = definition and definition.Role or "Unknown"
		local assistName = definition and definition.Assist and definition.Assist.Name or "No Assist"
		local passiveName = definition and definition.Passive and definition.Passive.Name or "No Passive"
		local elementColor = self.Config.Elements[element] or rarityData.Color

		local row = Instance.new("Frame")
		row.Name = fighter.Name
		row.Size = UDim2.new(1, -4, 0, 88)
		row.BackgroundColor3 = equipped and Color3.fromRGB(38, 42, 55) or Color3.fromRGB(29, 32, 44)
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = self.List
		corner(row, 11)
		stroke(row, equipped and elementColor or Color3.fromRGB(80, 82, 98), equipped and 0.42 or 0.78)

		local rarityBar = Instance.new("Frame")
		rarityBar.Size = UDim2.new(0, 5, 1, -14)
		rarityBar.Position = UDim2.new(0, 7, 0, 7)
		rarityBar.BackgroundColor3 = elementColor
		rarityBar.BorderSizePixel = 0
		rarityBar.Parent = row
		corner(rarityBar, 4)

		label(row, fighter.Value, UDim2.new(0.48, 0, 0, 22), UDim2.new(0, 22, 0, 7), 14, true)
		local sub = label(row, string.format("%s • %s %s • %s • x%d", string.upper(rarity), string.upper(element), string.upper(role), trait, copies), UDim2.new(0.70, 0, 0, 18), UDim2.new(0, 22, 0, 29), 10, true)
		sub.TextColor3 = elementColor
		local identity = label(row, "ASSIST: " .. assistName .. "  •  PASSIVE: " .. passiveName, UDim2.new(0.72, 0, 0, 17), UDim2.new(0, 22, 0, 48), 9, false)
		identity.TextColor3 = Color3.fromRGB(196, 199, 213)
		local powerText = label(row, string.format("TEAM +%.1f%%%s", teamPower * 100, equipped and (" • SLOT " .. slot) or ""), UDim2.new(0.62, 0, 0, 16), UDim2.new(0, 22, 0, 67), 9, false)
		powerText.TextColor3 = Color3.fromRGB(161, 166, 184)
		local equip = button(row, equipped and "UNEQUIP" or "EQUIP", UDim2.new(0, 104, 0, 38), UDim2.new(1, -116, 0, 25), equipped and Color3.fromRGB(48, 104, 76) or Color3.fromRGB(73, 55, 104))
		equip.Activated:Connect(function() self.Remote:FireServer("Equip", fighter.Name) end)
		table.insert(self.Connections, fighter:GetAttributeChangedSignal("EquippedSlot"):Connect(function() self:Rebuild() end))
		table.insert(self.Connections, fighter:GetAttributeChangedSignal("Copies"):Connect(function() self:Rebuild() end))
	end
end

return FighterUI
