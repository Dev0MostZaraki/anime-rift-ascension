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
	b.BackgroundColor3 = color or Color3.fromRGB(75, 61, 112)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(248, 248, 252)
	b.TextSize = 13
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 10)
	stroke(b, b.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.2), 0.58)
	gradient(b, b.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.06), b.BackgroundColor3:Lerp(Color3.new(0,0,0), 0.08))
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

	local dock = gui:FindFirstChild("MenuDock") or gui
	self.OpenButton = button(dock, "RELICS", UDim2.new(1, 0, 0, 42), UDim2.new(), Color3.fromRGB(100, 68, 43))
	self.OpenButton.LayoutOrder = 40

	self.Panel = Instance.new("Frame")
	self.Panel.Name = "RelicPanel"
	self.Panel.Size = UDim2.new(0, 610, 0, 480)
	self.Panel.Position = UDim2.new(0.5, -305, 0.5, -240)
	self.Panel.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
	self.Panel.BorderSizePixel = 0
	self.Panel.Visible = false
	self.Panel.Parent = gui
	corner(self.Panel, 18)
	stroke(self.Panel, Color3.fromRGB(202, 146, 76), 0.30)
	gradient(self.Panel, Color3.fromRGB(29, 24, 21), Color3.fromRGB(12, 14, 21))

	label(self.Panel, "RIFT RELIQUARY", UDim2.new(1, -90, 0, 38), UDim2.new(0, 18, 0, 12), 22, true)
	self.Summary = label(self.Panel, "", UDim2.new(0, 235, 0, 28), UDim2.new(0, 18, 0, 48), 12, true)
	self.Summary.TextColor3 = Color3.fromRGB(229, 185, 112)
	local close = button(self.Panel, "X", UDim2.new(0, 42, 0, 36), UDim2.new(1, -56, 0, 10), Color3.fromRGB(73, 55, 42))
	local best = button(self.Panel, "AUTO EQUIP BEST", UDim2.new(0, 170, 0, 34), UDim2.new(1, -246, 0, 43), Color3.fromRGB(93, 67, 37))

	self.List = Instance.new("ScrollingFrame")
	self.List.Size = UDim2.new(1, -28, 1, -98)
	self.List.Position = UDim2.new(0, 14, 0, 86)
	self.List.BackgroundColor3 = Color3.fromRGB(21, 23, 33)
	self.List.BackgroundTransparency = 0.05
	self.List.BorderSizePixel = 0
	self.List.ScrollBarThickness = 5
	self.List.ScrollBarImageColor3 = Color3.fromRGB(145, 107, 63)
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
	self.Summary.Text = "EQUIPPED " .. equippedCount .. "/" .. self.Config.Game.MaxEquippedRelics .. "   •   " .. #relics .. " OWNED"

	if #relics == 0 then
		local empty = label(self.List, "No relics recovered yet. Normal enemies can drop them; the Rift Tyrant guarantees high-tier relics.", UDim2.new(1, -30, 0, 82), UDim2.new(0, 15, 0, 18), 13, false)
		empty.TextWrapped = true
		empty.TextColor3 = Color3.fromRGB(174, 176, 191)
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
		row.Size = UDim2.new(1, -4, 0, 72)
		row.BackgroundColor3 = equipped and Color3.fromRGB(43, 43, 48) or Color3.fromRGB(29, 32, 43)
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = self.List
		corner(row, 11)
		stroke(row, equipped and color or Color3.fromRGB(78, 79, 91), equipped and 0.48 or 0.80)

		local rarityBar = Instance.new("Frame")
		rarityBar.Size = UDim2.new(0, 6, 1, -14)
		rarityBar.Position = UDim2.new(0, 7, 0, 7)
		rarityBar.BackgroundColor3 = color
		rarityBar.BorderSizePixel = 0
		rarityBar.Parent = row
		corner(rarityBar, 4)

		label(row, string.upper(relic.Value), UDim2.new(0.48, 0, 0, 24), UDim2.new(0, 24, 0, 8), 14, true)
		local sub = label(row, string.upper(rarity) .. "  •  ZONE " .. zone .. "  •  +" .. math.floor(power * 100) .. "% POWER  •  +" .. string.format("%.1f", crit * 100) .. "% CRIT", UDim2.new(0.66, 0, 0, 22), UDim2.new(0, 24, 0, 38), 10, true)
		sub.TextColor3 = color
		local equip = button(row, equipped and "UNEQUIP" or "EQUIP", UDim2.new(0, 110, 0, 38), UDim2.new(1, -122, 0, 17), equipped and Color3.fromRGB(54, 109, 75) or Color3.fromRGB(76, 61, 98))
		equip.Activated:Connect(function() self.EquipRemote:FireServer(relic.Name) end)
		table.insert(self.Connections, relic:GetAttributeChangedSignal("Equipped"):Connect(function() self:Rebuild() end))
	end
end

return RelicUI
