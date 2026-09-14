local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local VisualFX = {}
VisualFX.__index = VisualFX

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
end

function VisualFX.new(gui)
	local self = setmetatable({}, VisualFX)
	self.Gui = gui
	self.Token = 0
	self.BaseFov = 70

	local flash = Instance.new("Frame")
	flash.Name = "ActionFlash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 2
	flash.Parent = gui
	self.Flash = flash

	local edgeTop = Instance.new("Frame")
	edgeTop.Name = "CinematicTop"
	edgeTop.Size = UDim2.new(1, 0, 0, 0)
	edgeTop.Position = UDim2.new(0, 0, 0, 0)
	edgeTop.BackgroundColor3 = Color3.fromRGB(6, 7, 11)
	edgeTop.BorderSizePixel = 0
	edgeTop.ZIndex = 3
	edgeTop.Parent = gui
	self.Top = edgeTop

	local edgeBottom = edgeTop:Clone()
	edgeBottom.Name = "CinematicBottom"
	edgeBottom.AnchorPoint = Vector2.new(0, 1)
	edgeBottom.Position = UDim2.new(0, 0, 1, 0)
	edgeBottom.Parent = gui
	self.Bottom = edgeBottom

	local ability = Instance.new("TextLabel")
	ability.Name = "AbilityCallout"
	ability.AnchorPoint = Vector2.new(0.5, 0.5)
	ability.Position = UDim2.new(0.5, 0, 0.69, 0)
	ability.Size = UDim2.new(0, 300, 0, 42)
	ability.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
	ability.BackgroundTransparency = 1
	ability.BorderSizePixel = 0
	ability.Text = ""
	ability.TextColor3 = Color3.new(1, 1, 1)
	ability.TextTransparency = 1
	ability.TextSize = 17
	ability.Font = Enum.Font.GothamBlack
	ability.ZIndex = 20
	ability.Parent = gui
	corner(ability, 10)
	self.AbilityLabel = ability

	return self
end

function VisualFX:Pulse(color, strength, duration)
	self.Flash.BackgroundColor3 = color
	self.Flash.BackgroundTransparency = 1
	local target = math.clamp(1 - (strength or 0.08), 0.78, 0.98)
	local tin = TweenService:Create(self.Flash, TweenInfo.new(0.05), {BackgroundTransparency = target})
	local tout = TweenService:Create(self.Flash, TweenInfo.new(duration or 0.20), {BackgroundTransparency = 1})
	tin:Play()
	tin.Completed:Once(function() tout:Play() end)
end

function VisualFX:KickFov(amount, duration)
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local base = camera.FieldOfView
	local out = TweenService:Create(camera, TweenInfo.new(0.07, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {FieldOfView = base + amount})
	out:Play()
	task.delay(math.max(0.07, duration or 0.2), function()
		if Workspace.CurrentCamera == camera then
			TweenService:Create(camera, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {FieldOfView = base}):Play()
		end
	end)
end

function VisualFX:Callout(text, color)
	self.Token += 1
	local token = self.Token
	local label = self.AbilityLabel
	label.Text = string.upper(text)
	label.TextColor3 = color
	label.TextTransparency = 1
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0.5, 0, 0.71, 0)
	TweenService:Create(label, TweenInfo.new(0.10), {TextTransparency = 0, BackgroundTransparency = 0.35, Position = UDim2.new(0.5, 0, 0.69, 0)}):Play()
	task.delay(0.42, function()
		if token ~= self.Token then return end
		TweenService:Create(label, TweenInfo.new(0.20), {TextTransparency = 1, BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.67, 0)}):Play()
	end)
end

function VisualFX:Ability(name)
	if name == "Dash" then
		local c = Color3.fromRGB(91, 202, 255)
		self:Pulse(c, 0.045, 0.12)
		self:KickFov(4, 0.10)
		self:Callout("Rift Step", c)
	elseif name == "Burst" then
		local c = Color3.fromRGB(183, 103, 255)
		self:Pulse(c, 0.07, 0.18)
		self:KickFov(3, 0.13)
		self:Callout("Rift Burst", c)
	elseif name == "Nova" then
		local c = Color3.fromRGB(255, 92, 170)
		self:Pulse(c, 0.115, 0.28)
		self:KickFov(7, 0.20)
		self:Callout("Rift Nova", c)
	end
end

function VisualFX:Combo(stage)
	if stage == 3 then
		local c = Color3.fromRGB(255, 208, 111)
		self:Pulse(c, 0.06, 0.12)
		self:KickFov(2.5, 0.08)
	end
end

function VisualFX:Zone(color)
	color = color or Color3.fromRGB(160, 110, 235)
	self:Pulse(color, 0.08, 0.40)
	self.Top.Size = UDim2.new(1, 0, 0, 0)
	self.Bottom.Size = UDim2.new(1, 0, 0, 0)
	TweenService:Create(self.Top, TweenInfo.new(0.18), {Size = UDim2.new(1, 0, 0, 18)}):Play()
	TweenService:Create(self.Bottom, TweenInfo.new(0.18), {Size = UDim2.new(1, 0, 0, 18)}):Play()
	task.delay(1.35, function()
		TweenService:Create(self.Top, TweenInfo.new(0.22), {Size = UDim2.new(1, 0, 0, 0)}):Play()
		TweenService:Create(self.Bottom, TweenInfo.new(0.22), {Size = UDim2.new(1, 0, 0, 0)}):Play()
	end)
end

return VisualFX
