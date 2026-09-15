local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("AnimeRiftHUD", 25)
if not gui then
	warn("[VisualPolish] AnimeRiftHUD did not appear")
	return
end

-- Roblox core UI competes heavily with the game HUD in the current prototype.
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end)

local COLORS = {
	Panel = Color3.fromRGB(11, 13, 21),
	PanelSoft = Color3.fromRGB(22, 24, 35),
	Purple = Color3.fromRGB(147, 87, 222),
	Cyan = Color3.fromRGB(72, 193, 227),
	Text = Color3.fromRGB(242, 243, 250),
	Muted = Color3.fromRGB(151, 156, 178),
}

local function ensureCorner(object, radius)
	local corner = object:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = object
end

local function ensureStroke(object, color, transparency, thickness)
	local stroke = object:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Color = color or COLORS.Purple
	stroke.Transparency = transparency or 0.65
	stroke.Thickness = thickness or 1
	stroke.Parent = object
end

local function addGradient(object, a, b, rotation)
	local old = object:FindFirstChild("VisualPolishGradient")
	if old then old:Destroy() end
	local gradient = Instance.new("UIGradient")
	gradient.Name = "VisualPolishGradient"
	gradient.Color = ColorSequence.new(a, b)
	gradient.Rotation = rotation or 0
	gradient.Parent = object
end

local function styleButton(button)
	if not button:IsA("TextButton") then return end
	button.Size = UDim2.new(1, 0, 0, 34)
	button.BackgroundColor3 = Color3.fromRGB(26, 27, 40)
	button.BackgroundTransparency = 0.16
	button.BorderSizePixel = 0
	button.TextColor3 = Color3.fromRGB(226, 222, 241)
	button.TextSize = 10
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	ensureCorner(button, 9)
	ensureStroke(button, Color3.fromRGB(101, 83, 138), 0.62, 1)
	addGradient(button, Color3.fromRGB(33, 35, 50), Color3.fromRGB(20, 20, 31), 90)

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {BackgroundTransparency = 0.03, TextColor3 = Color3.fromRGB(255, 248, 255)}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {BackgroundTransparency = 0.16, TextColor3 = Color3.fromRGB(226, 222, 241)}):Play()
	end)
end

local top = gui:FindFirstChild("PlayerHeader")
if top and top:IsA("Frame") then
	top.Size = UDim2.new(0, 520, 0, 72)
	top.Position = UDim2.new(0.5, 0, 0, 14)
	top.BackgroundColor3 = COLORS.Panel
	top.BackgroundTransparency = 0.14
	ensureCorner(top, 14)
	ensureStroke(top, Color3.fromRGB(126, 94, 170), 0.57, 1)
	addGradient(top, Color3.fromRGB(22, 23, 35), Color3.fromRGB(10, 12, 19), 90)

	for _, child in ipairs(top:GetDescendants()) do
		if child:IsA("TextLabel") then
			child.TextStrokeTransparency = 1
		end
	end
end

local dock = gui:FindFirstChild("MenuDock")
if dock and dock:IsA("Frame") then
	dock.Position = UDim2.new(1, -18, 0, 88)
	dock.Size = UDim2.new(0, 128, 0, 238)
	local layout = dock:FindFirstChildOfClass("UIListLayout")
	if layout then layout.Padding = UDim.new(0, 6) end
	for _, child in ipairs(dock:GetChildren()) do styleButton(child) end
	dock.ChildAdded:Connect(function(child)
		task.defer(function() styleButton(child) end)
	end)
end

local missions = gui:FindFirstChild("MissionPanel")
local missionToggle
if missions and missions:IsA("Frame") then
	missions.Size = UDim2.new(0, 264, 0, 178)
	missions.Position = UDim2.new(0, 14, 0, 136)
	missions.BackgroundColor3 = COLORS.Panel
	missions.BackgroundTransparency = 0.12
	missions.Visible = false
	ensureCorner(missions, 14)
	ensureStroke(missions, Color3.fromRGB(80, 158, 186), 0.58, 1)
	addGradient(missions, Color3.fromRGB(20, 25, 35), Color3.fromRGB(10, 12, 19), 90)

	missionToggle = Instance.new("TextButton")
	missionToggle.Name = "MissionToggle"
	missionToggle.Size = UDim2.new(0, 142, 0, 34)
	missionToggle.Position = UDim2.new(0, 14, 0, 94)
	missionToggle.BackgroundColor3 = Color3.fromRGB(19, 27, 35)
	missionToggle.BackgroundTransparency = 0.10
	missionToggle.BorderSizePixel = 0
	missionToggle.Text = "◈  MISSIONS"
	missionToggle.TextColor3 = Color3.fromRGB(188, 226, 239)
	missionToggle.TextSize = 11
	missionToggle.Font = Enum.Font.GothamBold
	missionToggle.Parent = gui
	ensureCorner(missionToggle, 10)
	ensureStroke(missionToggle, COLORS.Cyan, 0.58, 1)
	addGradient(missionToggle, Color3.fromRGB(24, 37, 45), Color3.fromRGB(14, 18, 27), 0)

	local open = false
	local function setOpen(value)
		open = value
		missions.Visible = true
		if open then
			missions.Position = UDim2.new(0, -280, 0, 136)
			missions.BackgroundTransparency = 0.24
			TweenService:Create(missions, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, 14, 0, 136),
				BackgroundTransparency = 0.12,
			}):Play()
			missionToggle.Text = "×  MISSIONS"
		else
			local tween = TweenService:Create(missions, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
				Position = UDim2.new(0, -280, 0, 136),
				BackgroundTransparency = 0.35,
			})
			tween:Play()
			tween.Completed:Once(function()
				if not open then missions.Visible = false end
			end)
			missionToggle.Text = "◈  MISSIONS"
		end
	end
	missionToggle.Activated:Connect(function() setOpen(not open) end)
end

local hint
for _, child in ipairs(gui:GetChildren()) do
	if child:IsA("TextLabel") and string.find(child.Text, "3%-HIT COMBO") then
		hint = child
		break
	end
end
if hint then
	hint.Size = UDim2.new(0, 184, 0, 30)
	hint.Position = UDim2.new(1, -18, 1, -18)
	hint.BackgroundTransparency = 0.30
	hint.TextSize = 10
	hint.TextColor3 = Color3.fromRGB(176, 173, 196)
	ensureCorner(hint, 9)
	ensureStroke(hint, Color3.fromRGB(92, 80, 118), 0.72, 1)
	task.delay(10, function()
		if hint and hint.Parent then
			TweenService:Create(hint, TweenInfo.new(1.0), {BackgroundTransparency = 0.72, TextTransparency = 0.44}):Play()
		end
	end)
end

local notice = gui:FindFirstChild("Notice")
if notice and notice:IsA("TextLabel") then
	notice.Size = UDim2.new(0, 460, 0, 44)
	notice.BackgroundTransparency = 0.16
	ensureCorner(notice, 11)
	ensureStroke(notice, Color3.fromRGB(122, 93, 161), 0.62, 1)
end

-- Any large modal generated by the collection systems receives the same glass treatment.
local function styleModal(object)
	if not object:IsA("Frame") then return end
	if object.Name ~= "FighterPanel" and object.Name ~= "PetPanel" and object.Name ~= "ArsenalPanel" and object.Name ~= "RelicPanel" then return end
	object.BackgroundColor3 = Color3.fromRGB(12, 13, 21)
	object.BackgroundTransparency = 0.045
	ensureCorner(object, 18)
	ensureStroke(object, Color3.fromRGB(126, 88, 176), 0.42, 1.15)
	addGradient(object, Color3.fromRGB(22, 21, 34), Color3.fromRGB(11, 13, 20), 90)
end
for _, object in ipairs(gui:GetChildren()) do styleModal(object) end
gui.ChildAdded:Connect(function(child)
	task.defer(function() styleModal(child) end)
end)

-- Minimal key legend. The old screen was teaching every input at once; this appears
-- only when keyboard/mouse is actually in use and stays visually quiet.
if UserInputService.KeyboardEnabled then
	local legend = Instance.new("TextLabel")
	legend.Name = "MinimalLegend"
	legend.AnchorPoint = Vector2.new(0.5, 1)
	legend.Position = UDim2.new(0.5, 0, 1, -10)
	legend.Size = UDim2.new(0, 300, 0, 18)
	legend.BackgroundTransparency = 1
	legend.Text = "Q DASH   •   E BURST   •   R NOVA   •   Z X C ASSISTS"
	legend.TextColor3 = Color3.fromRGB(142, 142, 163)
	legend.TextTransparency = 0.23
	legend.TextSize = 9
	legend.Font = Enum.Font.GothamMedium
	legend.Parent = gui
end

print("[VisualPolish] decluttered anime HUD active")
