local ProgressionUI = {}
ProgressionUI.__index = ProgressionUI

local function formatTime(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	if hours > 0 then return string.format("%d:%02d:%02d", hours, minutes, secs) end
	return string.format("%02d:%02d", minutes, secs)
end

local function makeLabel(parent, position, size, text, textSize, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Text = text
	label.TextColor3 = Color3.fromRGB(238, 240, 248)
	label.TextSize = textSize or 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.Parent = parent
	return label
end

function ProgressionUI.new(player)
	local self = setmetatable({}, ProgressionUI)
	local playerGui = player:WaitForChild("PlayerGui")
	local profile = player:WaitForChild("RiftProfile")
	local progression = profile:WaitForChild("Progression")

	local existing = playerGui:FindFirstChild("RiftProgressionUI")
	if existing then existing:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "RiftProgressionUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 6
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "ProgressionPanel"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -14, 0, 14)
	panel.Size = UDim2.new(0, 250, 0, 94)
	panel.BackgroundColor3 = Color3.fromRGB(13, 15, 23)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(116, 92, 158)
	stroke.Transparency = 0.45
	stroke.Thickness = 1
	stroke.Parent = panel

	local title = makeLabel(panel, UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 18), "RIFT RESONANCE", 12, true)
	title.TextColor3 = Color3.fromRGB(202, 174, 255)
	local resonance = makeLabel(panel, UDim2.new(0, 12, 0, 30), UDim2.new(1, -24, 0, 18), "0.0%", 16, true)
	local active = makeLabel(panel, UDim2.new(0, 12, 0, 54), UDim2.new(0.6, -12, 0, 18), "Active 00:00", 12, false)
	local tickets = makeLabel(panel, UDim2.new(0.6, 0, 0, 54), UDim2.new(0.4, -12, 0, 18), "Tickets 0", 12, false)
	tickets.TextXAlignment = Enum.TextXAlignment.Right
	local note = makeLabel(panel, UDim2.new(0, 12, 0, 74), UDim2.new(1, -24, 0, 14), "Move • fight • hatch • explore", 10, false)
	note.TextColor3 = Color3.fromRGB(155, 160, 178)

	local resonanceValue = progression:WaitForChild("Resonance")
	local sessionValue = progression:WaitForChild("SessionEffectiveSeconds")
	local ticketsValue = progression:WaitForChild("RiftTickets")

	local function refresh()
		resonance.Text = string.format("%.1f%%", tonumber(resonanceValue.Value) or 0)
		active.Text = "Active " .. formatTime(sessionValue.Value)
		tickets.Text = "Tickets " .. tostring(ticketsValue.Value)
	end
	refresh()
	resonanceValue.Changed:Connect(refresh)
	sessionValue.Changed:Connect(refresh)
	ticketsValue.Changed:Connect(refresh)

	self.Gui = gui
	return self
end

return ProgressionUI
