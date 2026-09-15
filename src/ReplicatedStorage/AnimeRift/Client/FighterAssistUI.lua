local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local FighterAssistUI = {}
FighterAssistUI.__index = FighterAssistUI

local KEYS = {
	[1] = {Name = "Z", Code = Enum.KeyCode.Z},
	[2] = {Name = "X", Code = Enum.KeyCode.X},
	[3] = {Name = "C", Code = Enum.KeyCode.C},
}

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
end

local function stroke(parent, color, transparency, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Transparency = transparency or 0.45
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function textLabel(parent, text, size, position, textSize, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Text = text
	label.TextColor3 = Color3.fromRGB(240, 242, 249)
	label.TextSize = textSize or 12
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

function FighterAssistUI.new(gui, inventory, config, remote)
	local self = setmetatable({}, FighterAssistUI)
	self.Gui = gui
	self.Inventory = inventory
	self.Config = config
	self.Remote = remote
	self.CooldownEnds = {}
	self.Buttons = {}
	self.Connections = {}

	local bar = Instance.new("Frame")
	bar.Name = "FighterAssistBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -92)
	bar.Size = UDim2.new(0, 570, 0, 70)
	bar.BackgroundColor3 = Color3.fromRGB(10, 12, 19)
	bar.BackgroundTransparency = 0.08
	bar.BorderSizePixel = 0
	bar.Parent = gui
	corner(bar, 14)
	stroke(bar, Color3.fromRGB(105, 84, 142), 0.50, 1)
	self.Bar = bar

	local title = textLabel(bar, "FIGHTER ASSISTS", UDim2.new(0, 100, 0, 15), UDim2.new(0, 12, 0, 4), 9, true)
	title.TextColor3 = Color3.fromRGB(156, 160, 180)

	for slot = 1, 3 do
		local frame = Instance.new("TextButton")
		frame.Name = "Assist" .. slot
		frame.Size = UDim2.new(0, 176, 0, 44)
		frame.Position = UDim2.new(0, 12 + (slot - 1) * 182, 0, 21)
		frame.BackgroundColor3 = Color3.fromRGB(29, 32, 45)
		frame.BorderSizePixel = 0
		frame.Text = ""
		frame.AutoButtonColor = true
		frame.Parent = bar
		corner(frame, 9)
		local outline = stroke(frame, Color3.fromRGB(79, 82, 99), 0.62, 1)

		local keyBox = Instance.new("Frame")
		keyBox.Size = UDim2.new(0, 32, 0, 32)
		keyBox.Position = UDim2.new(0, 6, 0, 6)
		keyBox.BackgroundColor3 = Color3.fromRGB(47, 50, 67)
		keyBox.BorderSizePixel = 0
		keyBox.Parent = frame
		corner(keyBox, 7)
		local key = textLabel(keyBox, KEYS[slot].Name, UDim2.fromScale(1, 1), UDim2.new(), 13, true)
		key.TextXAlignment = Enum.TextXAlignment.Center

		local fighter = textLabel(frame, "EMPTY SLOT", UDim2.new(1, -48, 0, 19), UDim2.new(0, 44, 0, 4), 11, true)
		local assist = textLabel(frame, "Equip a Fighter", UDim2.new(1, -48, 0, 17), UDim2.new(0, 44, 0, 23), 9, false)
		assist.TextColor3 = Color3.fromRGB(155, 159, 177)

		local cooldown = Instance.new("TextLabel")
		cooldown.Size = UDim2.fromScale(1, 1)
		cooldown.BackgroundColor3 = Color3.fromRGB(8, 9, 14)
		cooldown.BackgroundTransparency = 0.20
		cooldown.BorderSizePixel = 0
		cooldown.Text = ""
		cooldown.TextColor3 = Color3.fromRGB(247, 231, 255)
		cooldown.TextSize = 15
		cooldown.Font = Enum.Font.GothamBold
		cooldown.Visible = false
		cooldown.ZIndex = 5
		cooldown.Parent = frame
		corner(cooldown, 9)

		self.Buttons[slot] = {
			Root = frame,
			KeyBox = keyBox,
			Fighter = fighter,
			Assist = assist,
			Cooldown = cooldown,
			Outline = outline,
			FighterId = nil,
		}
		frame.Activated:Connect(function() self:TryActivate(slot) end)
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		for slot, info in pairs(KEYS) do
			if input.KeyCode == info.Code then
				self:TryActivate(slot)
				return
			end
		end
	end)

	remote.OnClientEvent:Connect(function(action, slot, seconds, fighterId)
		if action == "ResetCooldowns" then
			table.clear(self.CooldownEnds)
			return
		end
		slot = tonumber(slot)
		if not slot or not self.Buttons[slot] then return end
		if action == "Activated" or action == "Cooldown" then
			self.CooldownEnds[slot] = math.max(self.CooldownEnds[slot] or 0, os.clock() + math.max(0, tonumber(seconds) or 0))
			if fighterId then self.Buttons[slot].FighterId = tostring(fighterId) end
		end
	end)

	inventory.ChildAdded:Connect(function(child)
		self:HookFighter(child)
		self:Rebuild()
	end)
	inventory.ChildRemoved:Connect(function() self:Rebuild() end)
	for _, child in ipairs(inventory:GetChildren()) do self:HookFighter(child) end
	self:Rebuild()

	RunService.RenderStepped:Connect(function()
		self:RenderCooldowns()
	end)
	return self
end

function FighterAssistUI:HookFighter(fighter)
	table.insert(self.Connections, fighter:GetAttributeChangedSignal("EquippedSlot"):Connect(function()
		self:Rebuild()
	end))
end

function FighterAssistUI:TryActivate(slot)
	local button = self.Buttons[slot]
	if not button or not button.FighterId then return end
	if os.clock() < (self.CooldownEnds[slot] or 0) then return end
	self.Remote:FireServer(slot)
end

function FighterAssistUI:Rebuild()
	local equipped = {}
	for _, fighter in ipairs(self.Inventory:GetChildren()) do
		local slot = tonumber(fighter:GetAttribute("EquippedSlot")) or 0
		if slot >= 1 and slot <= 3 then equipped[slot] = fighter end
	end

	for slot = 1, 3 do
		local ui = self.Buttons[slot]
		local fighter = equipped[slot]
		if fighter then
			local definition, rarity = self.Config.GetById(fighter.Name)
			if definition and definition.Assist then
				local color = self.Config.Elements[definition.Element] or (self.Config.Rarities[rarity] and self.Config.Rarities[rarity].Color) or Color3.fromRGB(160, 110, 220)
				ui.FighterId = fighter.Name
				ui.Fighter.Text = definition.Name
				ui.Assist.Text = definition.Element .. " • " .. definition.Assist.Name
				ui.Assist.TextColor3 = color
				ui.KeyBox.BackgroundColor3 = color:Lerp(Color3.fromRGB(22, 24, 34), 0.52)
				ui.Outline.Color = color
				ui.Root.BackgroundColor3 = Color3.fromRGB(31, 33, 45)
			else
				ui.FighterId = nil
			end
		else
			ui.FighterId = nil
			ui.Fighter.Text = "EMPTY SLOT"
			ui.Assist.Text = "Equip a Fighter"
			ui.Assist.TextColor3 = Color3.fromRGB(155, 159, 177)
			ui.KeyBox.BackgroundColor3 = Color3.fromRGB(47, 50, 67)
			ui.Outline.Color = Color3.fromRGB(79, 82, 99)
			ui.Root.BackgroundColor3 = Color3.fromRGB(25, 27, 37)
			self.CooldownEnds[slot] = nil
		end
	end
end

function FighterAssistUI:RenderCooldowns()
	local now = os.clock()
	for slot = 1, 3 do
		local ui = self.Buttons[slot]
		local remaining = (self.CooldownEnds[slot] or 0) - now
		if remaining > 0 and ui.FighterId then
			ui.Cooldown.Visible = true
			ui.Cooldown.Text = string.format("%.1fs", remaining)
		else
			ui.Cooldown.Visible = false
			ui.Cooldown.Text = ""
			if remaining <= 0 then self.CooldownEnds[slot] = nil end
		end
	end
end

return FighterAssistUI
