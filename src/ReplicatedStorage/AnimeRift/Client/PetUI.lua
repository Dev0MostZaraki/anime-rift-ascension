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

local function button(parent, text, size, position)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = position
	b.BackgroundColor3 = Color3.fromRGB(75, 61, 112)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(245, 245, 250)
	b.TextSize = 15
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 9)
	return b
end

function PetUI.new(gui, inventory, config, equipRemote)
	local self = setmetatable({}, PetUI)
	self.Gui = gui
	self.Inventory = inventory
	self.Config = config
	self.EquipRemote = equipRemote
	self.Connections = {}

	self.OpenButton = button(gui, "COMPANIONS", UDim2.new(0, 150, 0, 46), UDim2.new(1, -166, 0, 18))
	self.HelpButton = button(gui, "HOW TO PLAY", UDim2.new(0, 150, 0, 46), UDim2.new(1, -166, 0, 72))

	self.Panel = Instance.new("Frame")
	self.Panel.Size = UDim2.new(0, 520, 0, 430)
	self.Panel.Position = UDim2.new(0.5, -260, 0.5, -215)
	self.Panel.BackgroundColor3 = Color3.fromRGB(18, 20, 29)
	self.Panel.BorderSizePixel = 0
	self.Panel.Visible = false
	self.Panel.Parent = gui
	corner(self.Panel, 16)
	stroke(self.Panel, Color3.fromRGB(150, 105, 220), 0.25)

	label(self.Panel, "COMPANIONS", UDim2.new(1, -120, 0, 35), UDim2.new(0, 16, 0, 10), 21, true)
	local close = button(self.Panel, "X", UDim2.new(0, 42, 0, 36), UDim2.new(1, -56, 0, 10))
	local best = button(self.Panel, "AUTO EQUIP BEST", UDim2.new(0, 170, 0, 36), UDim2.new(0, 16, 0, 52))
	local hint = label(self.Panel, "Equip up to 3 companions. Their bonuses add to your Power.", UDim2.new(1, -205, 0, 42), UDim2.new(0, 198, 0, 50), 13, false)
	hint.TextWrapped = true

	self.List = Instance.new("ScrollingFrame")
	self.List.Size = UDim2.new(1, -28, 1, -112)
	self.List.Position = UDim2.new(0, 14, 0, 100)
	self.List.BackgroundColor3 = Color3.fromRGB(25, 28, 39)
	self.List.BorderSizePixel = 0
	self.List.ScrollBarThickness = 6
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
	self.HelpPanel.Size = UDim2.new(0, 470, 0, 345)
	self.HelpPanel.Position = UDim2.new(0.5, -235, 0.5, -172)
	self.HelpPanel.BackgroundColor3 = Color3.fromRGB(18, 20, 29)
	self.HelpPanel.BorderSizePixel = 0
	self.HelpPanel.Visible = false
	self.HelpPanel.Parent = gui
	corner(self.HelpPanel, 16)
	stroke(self.HelpPanel)
	label(self.HelpPanel, "HOW TO PLAY", UDim2.new(1, -80, 0, 34), UDim2.new(0, 16, 0, 12), 21, true)
	local closeHelp = button(self.HelpPanel, "X", UDim2.new(0, 42, 0, 36), UDim2.new(1, -56, 0, 10))
	local helpText = label(self.HelpPanel,
		"1. Your Rift Blade auto-equips. Click or tap near enemies to attack.\n\n" ..
		"2. Defeat enemies for Coins and XP. Levels increase Power.\n\n" ..
		"3. Use the Hub portals. Higher worlds require Levels and Coins.\n\n" ..
		"4. Hatch zone eggs and equip your strongest 3 companions.\n\n" ..
		"5. Complete Missions, defeat the Rift Tyrant and hunt secret Rift Eggs.\n\n" ..
		"6. Rift Surge doubles enemy Coins and XP for a limited time.",
		UDim2.new(1, -32, 1, -72), UDim2.new(0, 16, 0, 58), 15, false)
	helpText.TextWrapped = true
	helpText.TextYAlignment = Enum.TextYAlignment.Top

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
	for _, child in ipairs(self.List:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for _, connection in ipairs(self.Connections) do
		if connection.Connected then connection:Disconnect() end
	end
	table.clear(self.Connections)

	local pets = self.Inventory:GetChildren()
	table.sort(pets, function(a, b)
		return (tonumber(a:GetAttribute("Bonus")) or 0) > (tonumber(b:GetAttribute("Bonus")) or 0)
	end)

	for index, pet in ipairs(pets) do
		local rarity = tostring(pet:GetAttribute("Rarity") or "Common")
		local bonus = tonumber(pet:GetAttribute("Bonus")) or 0
		local equipped = pet:GetAttribute("Equipped") == true
		local color = self.Config.RarityColors[rarity] or self.Config.RarityColors.Common

		local row = Instance.new("Frame")
		row.Name = pet.Name
		row.Size = UDim2.new(1, -4, 0, 64)
		row.BackgroundColor3 = Color3.fromRGB(34, 37, 50)
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = self.List
		corner(row, 10)

		local rarityBar = Instance.new("Frame")
		rarityBar.Size = UDim2.new(0, 6, 1, -12)
		rarityBar.Position = UDim2.new(0, 6, 0, 6)
		rarityBar.BackgroundColor3 = color
		rarityBar.BorderSizePixel = 0
		rarityBar.Parent = row
		corner(rarityBar, 4)

		label(row, pet.Value, UDim2.new(0.48, 0, 0, 25), UDim2.new(0, 22, 0, 8), 15, true)
		local sub = label(row, rarity .. " - +" .. math.floor(bonus * 100) .. "% Power", UDim2.new(0.55, 0, 0, 22), UDim2.new(0, 22, 0, 34), 12, false)
		sub.TextColor3 = color
		local equip = button(row, equipped and "UNEQUIP" or "EQUIP", UDim2.new(0, 105, 0, 38), UDim2.new(1, -116, 0, 13))
		if equipped then equip.BackgroundColor3 = Color3.fromRGB(65, 125, 88) end
		equip.Activated:Connect(function()
			self.EquipRemote:FireServer(pet.Name)
		end)
		table.insert(self.Connections, pet:GetAttributeChangedSignal("Equipped"):Connect(function()
			self:Rebuild()
		end))
	end
end

return PetUI
