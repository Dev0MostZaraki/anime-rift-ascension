local UserInputService = game:GetService("UserInputService")

local DialogUI = {}
DialogUI.__index = DialogUI

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
end

local function stroke(parent, color, transparency, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Transparency = transparency or 0.35
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

function DialogUI.new(gui, remote)
	local self = setmetatable({Lines = {}, Index = 0, Payload = nil}, DialogUI)

	local panel = Instance.new("Frame")
	panel.Name = "DialoguePanel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -74)
	panel.Size = UDim2.new(0, 650, 0, 148)
	panel.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
	panel.BackgroundTransparency = 0.03
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	corner(panel, 15)
	self.Stroke = stroke(panel, Color3.fromRGB(125, 115, 150), 0.30, 1.2)
	self.Panel = panel

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.new(0, 5, 1, -20)
	accent.Position = UDim2.new(0, 10, 0, 10)
	accent.BackgroundColor3 = Color3.fromRGB(125, 115, 150)
	accent.BorderSizePixel = 0
	accent.Parent = panel
	corner(accent, 4)
	self.Accent = accent

	local speaker = Instance.new("TextLabel")
	speaker.Name = "Speaker"
	speaker.BackgroundTransparency = 1
	speaker.Position = UDim2.new(0, 28, 0, 12)
	speaker.Size = UDim2.new(1, -150, 0, 23)
	speaker.TextColor3 = Color3.fromRGB(245, 241, 230)
	speaker.TextSize = 17
	speaker.Font = Enum.Font.GothamBold
	speaker.TextXAlignment = Enum.TextXAlignment.Left
	speaker.Parent = panel
	self.Speaker = speaker

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 28, 0, 35)
	title.Size = UDim2.new(1, -150, 0, 17)
	title.TextColor3 = Color3.fromRGB(157, 162, 179)
	title.TextSize = 10
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel
	self.Title = title

	local line = Instance.new("TextLabel")
	line.Name = "Line"
	line.BackgroundTransparency = 1
	line.Position = UDim2.new(0, 28, 0, 61)
	line.Size = UDim2.new(1, -56, 0, 54)
	line.TextColor3 = Color3.fromRGB(224, 226, 233)
	line.TextSize = 15
	line.Font = Enum.Font.Gotham
	line.TextWrapped = true
	line.TextYAlignment = Enum.TextYAlignment.Top
	line.TextXAlignment = Enum.TextXAlignment.Left
	line.Parent = panel
	self.Line = line

	local nextButton = Instance.new("TextButton")
	nextButton.Name = "Next"
	nextButton.AnchorPoint = Vector2.new(1, 1)
	nextButton.Position = UDim2.new(1, -16, 1, -12)
	nextButton.Size = UDim2.new(0, 126, 0, 29)
	nextButton.BackgroundColor3 = Color3.fromRGB(39, 42, 55)
	nextButton.BorderSizePixel = 0
	nextButton.Text = "NEXT  ›"
	nextButton.TextColor3 = Color3.fromRGB(224, 226, 235)
	nextButton.TextSize = 11
	nextButton.Font = Enum.Font.GothamBold
	nextButton.Parent = panel
	corner(nextButton, 8)
	self.NextButton = nextButton

	local progress = Instance.new("TextLabel")
	progress.BackgroundTransparency = 1
	progress.Position = UDim2.new(0, 28, 1, -31)
	progress.Size = UDim2.new(0, 150, 0, 18)
	progress.TextColor3 = Color3.fromRGB(133, 138, 155)
	progress.TextSize = 10
	progress.Font = Enum.Font.Gotham
	progress.TextXAlignment = Enum.TextXAlignment.Left
	progress.Parent = panel
	self.Progress = progress

	function self:Advance()
		if not self.Panel.Visible then return end
		self.Index += 1
		if self.Index > #self.Lines then
			self.Panel.Visible = false
			return
		end
		self.Line.Text = tostring(self.Lines[self.Index])
		self.Progress.Text = tostring(self.Index) .. " / " .. tostring(#self.Lines)
		self.NextButton.Text = self.Index == #self.Lines and "CLOSE  ×" or "NEXT  ›"
	end

	function self:Show(payload)
		if type(payload) ~= "table" or type(payload.Lines) ~= "table" or #payload.Lines == 0 then return end
		self.Payload = payload
		self.Lines = payload.Lines
		self.Index = 0
		local color = typeof(payload.Color) == "Color3" and payload.Color or Color3.fromRGB(125, 115, 150)
		self.Speaker.Text = tostring(payload.Speaker or "Traveler")
		self.Title.Text = string.upper(tostring(payload.Title or ""))
		self.Accent.BackgroundColor3 = color
		self.Stroke.Color = color
		self.Panel.Visible = true
		self:Advance()
	end

	nextButton.Activated:Connect(function() self:Advance() end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not self.Panel.Visible then return end
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then
			self:Advance()
		end
	end)
	remote.OnClientEvent:Connect(function(payload) self:Show(payload) end)

	return self
end

return DialogUI
