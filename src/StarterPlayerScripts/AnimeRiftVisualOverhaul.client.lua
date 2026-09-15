local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("AnimeRiftHUD", 25)
if not gui then return end
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end)

local function corner(object, radius)
	local c = object:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = object
end

local function stroke(object, color, transparency, thickness)
	local s = object:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	s.Color = color
	s.Transparency = transparency or 0.6
	s.Thickness = thickness or 1
	s.Parent = object
	return s
end

local function gradient(object, a, b, rotation)
	local old = object:FindFirstChild("VisualGradient")
	if old then old:Destroy() end
	local g = Instance.new("UIGradient")
	g.Name = "VisualGradient"
	g.Color = ColorSequence.new(a,b)
	g.Rotation = rotation or 90
	g.Parent = object
end

local function styleDockButton(button)
	if not button:IsA("TextButton") then return end
	button.Size = UDim2.new(1,0,0,34)
	button.BackgroundColor3 = Color3.fromRGB(25,26,39)
	button.BackgroundTransparency = 0.14
	button.BorderSizePixel = 0
	button.TextColor3 = Color3.fromRGB(228,224,241)
	button.TextSize = 10
	button.Font = Enum.Font.GothamBold
	corner(button,9)
	stroke(button,Color3.fromRGB(102,82,139),0.64,1)
	gradient(button,Color3.fromRGB(34,35,50),Color3.fromRGB(18,19,29),90)
end

local function polishHeader()
	local top=gui:FindFirstChild("PlayerHeader")
	if not top then return end
	top.Size=UDim2.new(0,520,0,72)
	top.Position=UDim2.new(.5,0,0,14)
	top.BackgroundColor3=Color3.fromRGB(11,13,21)
	top.BackgroundTransparency=.14
	corner(top,14)
	stroke(top,Color3.fromRGB(126,94,170),.57,1)
	gradient(top,Color3.fromRGB(23,23,35),Color3.fromRGB(10,12,19),90)
	for _,child in ipairs(top:GetDescendants()) do if child:IsA("TextLabel") then child.TextStrokeTransparency=1 end end
end

local function polishDock()
	local dock=gui:FindFirstChild("MenuDock")
	if not dock then return end
	dock.Position=UDim2.new(1,-18,0,90)
	dock.Size=UDim2.new(0,128,0,238)
	local layout=dock:FindFirstChildOfClass("UIListLayout")
	if layout then layout.Padding=UDim.new(0,6) end
	for _,child in ipairs(dock:GetChildren()) do styleDockButton(child) end
	dock.ChildAdded:Connect(function(child) task.defer(function() styleDockButton(child) end) end)
end

local function missionDrawer()
	local missions=gui:FindFirstChild("MissionPanel")
	if not missions then return end
	missions.Size=UDim2.new(0,264,0,178)
	missions.Position=UDim2.new(0,-280,0,136)
	missions.BackgroundColor3=Color3.fromRGB(11,14,22)
	missions.BackgroundTransparency=.14
	missions.Visible=false
	corner(missions,14)
	stroke(missions,Color3.fromRGB(73,159,190),.58,1)
	gradient(missions,Color3.fromRGB(20,25,35),Color3.fromRGB(9,11,18),90)

	local toggle=Instance.new("TextButton")
	toggle.Name="MissionToggle"
	toggle.Size=UDim2.new(0,142,0,34)
	toggle.Position=UDim2.new(0,14,0,96)
	toggle.BackgroundColor3=Color3.fromRGB(18,28,36)
	toggle.BackgroundTransparency=.08
	toggle.BorderSizePixel=0
	toggle.Text="◈  MISSIONS"
	toggle.TextColor3=Color3.fromRGB(188,226,239)
	toggle.TextSize=11
	toggle.Font=Enum.Font.GothamBold
	toggle.Parent=gui
	corner(toggle,10)
	stroke(toggle,Color3.fromRGB(72,193,227),.56,1)
	gradient(toggle,Color3.fromRGB(24,38,46),Color3.fromRGB(13,18,27),0)

	local open=false
	local function setOpen(value)
		open=value
		if value then
			missions.Visible=true
			TweenService:Create(missions,TweenInfo.new(.22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.new(0,14,0,136)}):Play()
			toggle.Text="×  MISSIONS"
		else
			local t=TweenService:Create(missions,TweenInfo.new(.18,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=UDim2.new(0,-280,0,136)})
			t:Play()
			t.Completed:Connect(function() if not open then missions.Visible=false end end)
			toggle.Text="◈  MISSIONS"
		end
	end
	toggle.Activated:Connect(function() setOpen(not open) end)
end

local function polishCombatBar(bar)
	if not bar or not bar:IsA("Frame") then return end
	bar.Size=UDim2.new(0,456,0,60)
	bar.Position=UDim2.new(.5,0,1,-14)
	bar.BackgroundTransparency=.17
	local s=bar:FindFirstChildOfClass("UIStroke")
	if s then s.Transparency=.60; s.Thickness=1 end
	for index,name in ipairs({"DASH","RIFT BURST","RIFT NOVA"}) do
		local button=bar:FindFirstChild(name)
		if button and button:IsA("TextButton") then
			button.Size=UDim2.new(0,140,0,40)
			button.Position=UDim2.new(0,8+(index-1)*150,0,11)
			button.BackgroundTransparency=.12
			local bs=button:FindFirstChildOfClass("UIStroke")
			if bs then bs.Transparency=.64 end
			local accent=button:FindFirstChild("Accent")
			if accent then accent.Size=UDim2.new(0,3,1,-10); accent.Position=UDim2.new(0,5,0,5) end
			for _,child in ipairs(button:GetChildren()) do
				if child:IsA("TextLabel") then
					if child.Name=="Cooldown" then child.TextSize=16
					elseif child.Text=="Q" or child.Text=="E" or child.Text=="R" then child.Size=UDim2.new(0,28,0,28); child.Position=UDim2.new(0,14,.5,-14); child.TextSize=14
					else child.Position=UDim2.new(0,50,0,0); child.Size=UDim2.new(1,-56,1,0); child.TextSize=10 end
				end
			end
		end
	end
	for _,child in ipairs(bar:GetChildren()) do
		if child:IsA("TextLabel") and string.find(child.Text,"STYLE //",1,true) then child.Size=UDim2.new(0,230,0,20); child.Position=UDim2.new(.5,0,0,-5); child.BackgroundTransparency=.24; child.TextSize=9 end
	end
end

local function polishAssistBar(bar)
	if not bar or not bar:IsA("Frame") then return end
	bar.Size=UDim2.new(0,500,0,57)
	bar.Position=UDim2.new(.5,0,1,-76)
	bar.BackgroundTransparency=.22
	local s=bar:FindFirstChildOfClass("UIStroke")
	if s then s.Transparency=.67; s.Thickness=1 end
	for slot=1,3 do
		local button=bar:FindFirstChild("Assist"..slot)
		if button then
			button.Size=UDim2.new(0,155,0,38)
			button.Position=UDim2.new(0,10+(slot-1)*164,0,15)
			button.BackgroundTransparency=.14
			local bs=button:FindFirstChildOfClass("UIStroke"); if bs then bs.Transparency=.66 end
			for _,child in ipairs(button:GetChildren()) do
				if child:IsA("Frame") and child.Size.X.Offset==32 then child.Size=UDim2.new(0,28,0,28); child.Position=UDim2.new(0,6,0,5)
				elseif child:IsA("TextLabel") and child.ZIndex<5 then
					if child.Position.Y.Offset<15 then child.Position=UDim2.new(0,40,0,3); child.Size=UDim2.new(1,-44,0,17); child.TextSize=9
					else child.Position=UDim2.new(0,40,0,20); child.Size=UDim2.new(1,-44,0,15); child.TextSize=8 end
				end
			end
		end
	end
	for _,child in ipairs(bar:GetChildren()) do if child:IsA("TextLabel") and child.Text=="FIGHTER ASSISTS" then child.Text="ASSISTS"; child.Position=UDim2.new(0,11,0,2); child.TextSize=8 end end
end

local function polishModal(frame)
	if not frame:IsA("Frame") then return end
	if frame.Name~="FighterPanel" and frame.Name~="PetPanel" and frame.Name~="ArsenalPanel" and frame.Name~="RelicPanel" then return end
	frame.BackgroundColor3=Color3.fromRGB(11,12,20)
	frame.BackgroundTransparency=.045
	corner(frame,18)
	stroke(frame,Color3.fromRGB(126,88,176),.43,1.1)
	gradient(frame,Color3.fromRGB(22,21,34),Color3.fromRGB(10,12,19),90)
end

polishHeader()
polishDock()
missionDrawer()
for _,child in ipairs(gui:GetChildren()) do polishModal(child) end

local combat=gui:FindFirstChild("CombatBar") or gui:WaitForChild("CombatBar",15)
local assists=gui:FindFirstChild("FighterAssistBar") or gui:WaitForChild("FighterAssistBar",15)
polishCombatBar(combat)
polishAssistBar(assists)

gui.ChildAdded:Connect(function(child)
	task.defer(function()
		polishModal(child)
		if child.Name=="CombatBar" then polishCombatBar(child) end
		if child.Name=="FighterAssistBar" then polishAssistBar(child) end
	end)
end)

for _,child in ipairs(gui:GetChildren()) do
	if child:IsA("TextLabel") and string.find(child.Text,"3-HIT COMBO",1,true) then
		child.Size=UDim2.new(0,180,0,29)
		child.BackgroundTransparency=.38
		child.TextSize=9
		child.TextColor3=Color3.fromRGB(166,163,187)
		corner(child,9)
		task.delay(8,function() if child.Parent then TweenService:Create(child,TweenInfo.new(1),{BackgroundTransparency=.72,TextTransparency=.45}):Play() end end)
	end
end

print("[VisualOverhaul] decluttered anime HUD active")
