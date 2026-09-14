local PetUI = {}
PetUI.__index = PetUI

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
	l.TextColor3 = Color3.fromRGB(235, 238, 246)
	l.TextSize = fontSize or 16
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function button(parent, text, size, position, color)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = position or UDim2.new()
	b.BackgroundColor3 = color or Color3.fromRGB(55, 49, 78)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(245, 245, 250)
	b.TextSize = 13
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 10)
	stroke(b, b.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.2), 0.58)
	gradient(b, b.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.06), b.BackgroundColor3:Lerp(Color3.new(0,0,0), 0.08))
	return b
end

function PetUI.new(gui, inventory, config, equipRemote)
	local self = setmetatable({}, PetUI)
	self.Gui = gui
	self.Inventory = inventory
	self.Config = config
	self.EquipRemote = equipRemote
	self.Connections = {}

	local dock = gui:FindFirstChild("MenuDock") or gui
	self.OpenButton = button(dock, "COMPANIONS", UDim2.new(1, 0, 0, 42), UDim2.new(), Color3.fromRGB(66, 54, 96))
	self.OpenButton.LayoutOrder = 10
	self.HelpButton = button(dock, "FIELD GUIDE", UDim2.new(1, 0, 0, 42), UDim2.new(), Color3.fromRGB(47, 63, 84))
	self.HelpButton.LayoutOrder = 20

	self.Panel = Instance.new("Frame")
	self.Panel.Size = UDim2.new(0, 540, 0, 440)
	self.Panel.Position = UDim2.new(0.5, -270, 0.5, -220)
	self.Panel.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
	self.Panel.BorderSizePixel = 0
	self.Panel.Visible = false
	self.Panel.Parent = gui
	corner(self.Panel, 18)
	stroke(self.Panel, Color3.fromRGB(137, 104, 201), 0.28)
	gradient(self.Panel, Color3.fromRGB(23, 25, 37), Color3.fromRGB(12, 14, 21))

	label(self.Panel, "COMPANION ARCHIVE", UDim2.new(1, -120, 0, 35), UDim2.new(0, 18, 0, 12), 20, true)
	local sub = label(self.Panel, "Equip three spirits to amplify your combat Power.", UDim2.new(1, -210, 0, 28), UDim2.new(0, 18, 0, 45), 12, false)
	sub.TextColor3 = Color3.fromRGB(165, 169, 188)
	local close = button(self.Panel, "X", UDim2.new(0, 42, 0, 36), UDim2.new(1, -56, 0, 10), Color3.fromRGB(61, 48, 75))
	local best = button(self.Panel, "AUTO EQUIP BEST", UDim2.new(0, 166, 0, 34), UDim2.new(1, -184, 0, 47), Color3.fromRGB(61, 81, 115))

	self.List = Instance.new("ScrollingFrame")
	self.List.Size = UDim2.new(1, -28, 1, -102)
	self.List.Position = UDim2.new(0, 14, 0, 90)
	self.List.BackgroundColor3 = Color3.fromRGB(21, 24, 35)
	self.List.BackgroundTransparency = 0.08
	self.List.BorderSizePixel = 0
	self.List.ScrollBarThickness = 5
	self.List.ScrollBarImageColor3 = Color3.fromRGB(110, 95, 150)
	self.List.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.List.Parent = self.Panel
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

	self.HelpPanel = Instance.new("Frame")
	self.HelpPanel.Size = UDim2.new(0, 500, 0, 380)
	self.HelpPanel.Position = UDim2.new(0.5, -250, 0.5, -190)
	self.HelpPanel.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
	self.HelpPanel.BorderSizePixel = 0
	self.HelpPanel.Visible = false
	self.HelpPanel.Parent = gui
	corner(self.HelpPanel, 18)
	stroke(self.HelpPanel, Color3.fromRGB(86, 145, 187), 0.32)
	gradient(self.HelpPanel, Color3.fromRGB(21, 27, 38), Color3.fromRGB(12, 14, 21))
	label(self.HelpPanel, "RIFT FIELD GUIDE", UDim2.new(1, -80, 0, 34), UDim2.new(0, 18, 0, 14), 20, true)
	local closeHelp = button(self.HelpPanel, "X", UDim2.new(0, 42, 0, 36), UDim2.new(1, -56, 0, 10), Color3.fromRGB(52, 61, 78))
	local helpText = label(self.HelpPanel,
		"COMBAT\nM1 / Tap chains a 3-hit combo. Q dashes. E unleashes Rift Burst. R triggers Rift Nova.\n\n" ..
		"PROGRESSION\nDefeat enemies for Coins, XP, Style Mastery and Relics. New worlds require Levels and Coins.\n\n" ..
		"BUILDCRAFTING\nCompanions and Relics increase Power. Arsenal styles change damage, speed, range, crit and stagger.\n\n" ..
		"WORLD\nHatch zone eggs, complete Missions, hunt Rift Surges and face the Rift Tyrant in Void Sanctum.",
		UDim2.new(1, -36, 1, -78), UDim2.new(0, 18, 0, 60), 14, false)
	helpText.TextWrapped = true
	helpText.TextYAlignment = Enum.TextYAlignment.Top
	helpText.TextColor3 = Color3.fromRGB(205, 210, 224)

	self.OpenButton.Activated:Connect(function()
		self.Panel.Visible = not self.Panel.Visible
		self.HelpPanel.Visible = false
		if self.Panel.Visible then self:Rebuild() end
	end)
	close.Activated:Connect(function() self.Panel.Visible = false end)
	best.Activated:Connect(function() self.EquipRemote:FireServer("__BEST__") end)
	self.HelpButton.Activated:Connect(function()
		self.HelpPanel.Visible = not self.HelpPanel.Visible
		self.Panel.Visible = false
	end)
	closeHelp.Activated:Connect(function() self.HelpPanel.Visible = false end)

	inventory.ChildAdded:Connect(function() self:Rebuild() end)
	inventory.ChildRemoved:Connect(function() self:Rebuild() end)
	self:Rebuild()
	return self
end

function PetUI:Rebuild()
	for _, child in ipairs(self.List:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	for _, connection in ipairs(self.Connections) do if connection.Connected then connection:Disconnect() end end
	table.clear(self.Connections)

	local pets = self.Inventory:GetChildren()
	table.sort(pets, function(a, b)
		return (tonumber(a:GetAttribute("Bonus")) or 0) > (tonumber(b:GetAttribute("Bonus")) or 0)
	end)

	if #pets == 0 then
		local empty = label(self.List, "No companions yet. Travel through a Rift and hatch your first zone egg.", UDim2.new(1, -30, 0, 72), UDim2.new(0, 15, 0, 18), 13, false)
		empty.TextWrapped = true
		empty.TextColor3 = Color3.fromRGB(166, 170, 188)
		return
	end

	for index, pet in ipairs(pets) do
		local rarity = tostring(pet:GetAttribute("Rarity") or "Common")
		local bonus = tonumber(pet:GetAttribute("Bonus")) or 0
		local equipped = pet:GetAttribute("Equipped") == true
		local color = self.Config.RarityColors[rarity] or self.Config.RarityColors.Common

		local row = Instance.new("Frame")
		row.Name = pet.Name
		row.Size = UDim2.new(1, -4, 0, 66)
		row.BackgroundColor3 = equipped and Color3.fromRGB(35, 45, 53) or Color3.fromRGB(30, 33, 45)
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = self.List
		corner(row, 11)
		stroke(row, equipped and color or Color3.fromRGB(80, 82, 98), equipped and 0.55 or 0.78)

		local rarityBar = Instance.new("Frame")
		rarityBar.Size = UDim2.new(0, 5, 1, -14)
		rarityBar.Position = UDim2.new(0, 7, 0, 7)
		rarityBar.BackgroundColor3 = color
		rarityBar.BorderSizePixel = 0
		rarityBar.Parent = row
		corner(rarityBar, 4)

		label(row, pet.Value, UDim2.new(0.48, 0, 0, 25), UDim2.new(0, 22, 0, 8), 14, true)
		local sub = label(row, string.upper(rarity) .. "  •  +" .. math.floor(bonus * 100) .. "% POWER", UDim2.new(0.55, 0, 0, 22), UDim2.new(0, 22, 0, 35), 11, true)
		sub.TextColor3 = color
		local equip = button(row, equipped and "UNEQUIP" or "EQUIP", UDim2.new(0, 104, 0, 36), UDim2.new(1, -116, 0, 15), equipped and Color3.fromRGB(48, 109, 75) or Color3.fromRGB(68, 58, 99))
		equip.Activated:Connect(function() self.EquipRemote:FireServer(pet.Name) end)
		table.insert(self.Connections, pet:GetAttributeChangedSignal("Equipped"):Connect(function() self:Rebuild() end))
	end
end

return PetUI
