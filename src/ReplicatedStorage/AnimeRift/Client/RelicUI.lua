local RelicUI = {}
RelicUI.__index = RelicUI

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

local function score(relic)
	return (tonumber(relic:GetAttribute("PowerBonus")) or 0) + (tonumber(relic:GetAttribute("CritBonus")) or 0) * 5
end

function RelicUI.new(gui, inventory, config, equipRemote)
	local self = setmetatable({}, RelicUI)
	self.Gui = gui
	self.Inventory = inventory
	self.Config = config
	self.EquipRemote = equipRemote
	self.Connections = {}

	self.OpenButton = button(gui, "RELICS", UDim2.new(0, 150, 0, 46), UDim2.new(1, -166, 0, 180), Color3.fromRGB(119, 78, 48))
	self.Panel = Instance.new("Frame")
	self.Panel.Name = "RelicPanel"
	self.Panel.Size = UDim2.new(0, 600, 0, 470)
	self.Panel.Position = UDim2.new(0.5, -300, 0.5, -235)
	self.Panel.BackgroundColor3 = Color3.fromRGB(17, 19, 28)
	self.Panel.BorderSizePixel = 0
	self.Panel.Visible = false
	self.Panel.Parent = gui
	corner(self.Panel, 16)
	stroke(self.Panel, Color3.fromRGB(210, 155, 80), 0.25)

	label(self.Panel, "RIFT RELICS", UDim2.new(1, -90, 0, 38), UDim2.new(0, 18, 0, 12), 22, true)
	self.Summary = label(self.Panel, "", UDim2.new(0, 220, 0, 28), UDim2.new(0, 18, 0, 48), 13, true)
	self.Summary.TextColor3 = Color3.fromRGB(230, 190, 115)
	local close = button(self.Panel, "X", UDim2.new(0, 42, 0, 36), UDim2.new(1, -56, 0, 10))
	local best = button(self.Panel, "AUTO EQUIP BEST", UDim2.new(0, 170, 0, 36), UDim2.new(1, -246, 0, 42), Color3.fromRGB(107, 78, 42))

	self.List = Instance.new("ScrollingFrame")
	self.List.Size = UDim2.new(1, -28, 1, -98)
	self.List.Position = UDim2.new(0, 14, 0, 86)
	self.List.BackgroundColor3 = Color3.fromRGB(24, 27, 38)
	self.List.BorderSizePixel = 0
	self.List.ScrollBarThickness = 6
	self.List.CanvasSize = UDim2.new()
	self.List.Parent = self.Panel
	corner(self.List, 12)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 7)
	layout.Parent = self.List
	local padding = Instance.new("UIPadding")
	padding.PaddingTop, padding.PaddingBottom, padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8)
	padding.Parent = self.List
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.List.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end)

	self.OpenButton.Activated:Connect(function()
		self.Panel.Visible = not self.Panel.Visible
		if self.Panel.Visible then self:Rebuild() end
	end)
	close.Activated:Connect(function() self.Panel.Visible = false end)
	best.Activated:Connect(function() self.EquipRemote:FireServer("__BEST__") end)
	inventory.ChildAdded:Connect(function() self:Rebuild() end)
	inventory.ChildRemoved:Connect(function() self:Rebuild() end)
	self:Rebuild()
	return self
end

function RelicUI:Rebuild()
	for _, child in ipairs(self.List:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	for _, connection in ipairs(self.Connections) do if connection.Connected then connection:Disconnect() end end
	table.clear(self.Connections)

	local relics = self.Inventory:GetChildren()
	table.sort(relics, function(a, b) return score(a) > score(b) end)
	local equippedCount = 0
	for _, relic in ipairs(relics) do if relic:GetAttribute("Equipped") == true then equippedCount += 1 end end
	self.Summary.Text = "Equipped " .. equippedCount .. "/" .. self.Config.Game.MaxEquippedRelics .. " • " .. #relics .. " owned"

	if #relics == 0 then
		local empty = label(self.List, "No relics yet. Enemies can drop relics; the Rift Tyrant guarantees powerful ones.", UDim2.new(1, -30, 0, 80), UDim2.new(0, 15, 0, 18), 14, false)
		empty.TextWrapped = true
		empty.TextColor3 = Color3.fromRGB(180, 180, 195)
		return
	end

	for index, relic in ipairs(relics) do
		local rarity = tostring(relic:GetAttribute("Rarity") or "Common")
		local power = tonumber(relic:GetAttribute("PowerBonus")) or 0
		local crit = tonumber(relic:GetAttribute("CritBonus")) or 0
		local zone = tonumber(relic:GetAttribute("Zone")) or 1
		local equipped = relic:GetAttribute("Equipped") == true
		local color = self.Config.RarityColors[rarity] or self.Config.RarityColors.Common

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -4, 0, 70)
		row.BackgroundColor3 = equipped and Color3.fromRGB(45, 48, 58) or Color3.fromRGB(32, 35, 48)
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = self.List
		corner(row, 10)

		local rarityBar = Instance.new("Frame")
		rarityBar.Size = UDim2.new(0, 7, 1, -12)
		rarityBar.Position = UDim2.new(0, 6, 0, 6)
		rarityBar.BackgroundColor3 = color
		rarityBar.BorderSizePixel = 0
		rarityBar.Parent = row
		corner(rarityBar, 4)

		label(row, relic.Value, UDim2.new(0.48, 0, 0, 24), UDim2.new(0, 24, 0, 8), 15, true)
		local sub = label(row, rarity .. " • Zone " .. zone .. " • +" .. math.floor(power * 100) .. "% Power • +" .. string.format("%.1f", crit * 100) .. "% Crit", UDim2.new(0.64, 0, 0, 22), UDim2.new(0, 24, 0, 36), 11, false)
		sub.TextColor3 = color
		local equip = button(row, equipped and "UNEQUIP" or "EQUIP", UDim2.new(0, 110, 0, 38), UDim2.new(1, -122, 0, 16), equipped and Color3.fromRGB(63, 120, 82) or Color3.fromRGB(95, 72, 126))
		equip.Activated:Connect(function() self.EquipRemote:FireServer(relic.Name) end)
		table.insert(self.Connections, relic:GetAttributeChangedSignal("Equipped"):Connect(function() self:Rebuild() end))
	end
end

return RelicUI
