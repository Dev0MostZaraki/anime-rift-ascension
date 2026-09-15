local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local world = Workspace:WaitForChild("AnimeRiftWorld", 30)
if not world then return end
local events = world:WaitForChild("WorldEvents", 15)
if not events then return end

local function part(model, name, size, cf, color, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = transparency or 0.24
	p.Parent = model
	return p
end

local function wedge(model, name, size, cf, color, transparency)
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = transparency or 0.26
	p.Parent = model
	return p
end

local function fade(partObject, rise)
	TweenService:Create(partObject, TweenInfo.new(0.58, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Transparency = 1,
		CFrame = partObject.CFrame * CFrame.new(0, rise or 1.4, -0.9),
	}):Play()
end

local function decorate(model)
	if not model:IsA("Model") or not string.find(model.Name, "FighterEcho_", 1, true) then return end
	local torso = model:WaitForChild("Torso", 0.18)
	local head = model:WaitForChild("Head", 0.18)
	if not torso or not head or model:GetAttribute("AnimeEchoDecorated") then return end
	model:SetAttribute("AnimeEchoDecorated", true)

	local color = torso.Color
	local bright = color:Lerp(Color3.new(1,1,1), 0.28)
	local dark = color:Lerp(Color3.fromRGB(25,22,35), 0.62)
	local base = torso.CFrame

	-- Soften the original primitives and use them as the luminous inner core.
	torso.Size = Vector3.new(2.7, 3.9, 1.35)
	torso.Transparency = 0.48
	head.Size = Vector3.new(1.9,1.9,1.9)
	head.Transparency = 0.42

	local created = {}
	local function add(p) table.insert(created,p); return p end
	add(part(model,"Chest",Vector3.new(2.95,1.55,1.48),base*CFrame.new(0,0.65,-0.04),color,0.18))
	add(part(model,"Waist",Vector3.new(2.5,0.7,1.3),base*CFrame.new(0,-1.8,0),dark,0.24))
	for _,side in ipairs({-1,1}) do
		add(part(model,"Arm",Vector3.new(0.72,3.2,0.72),base*CFrame.new(side*1.8,0,0)*CFrame.Angles(0,0,math.rad(side*-8)),bright,0.28))
		add(part(model,"Leg",Vector3.new(0.82,3.3,0.9),base*CFrame.new(side*0.68,-3.25,0),dark,0.28))
	end
	-- Strong anime hair silhouette that reads even during a sub-second assist summon.
	for i=1,6 do
		local angle=(i/6)*math.pi*2
		add(wedge(model,"Hair",Vector3.new(0.68,1.7,0.7),head.CFrame*CFrame.new(math.cos(angle)*0.62,0.82,math.sin(angle)*0.62)*CFrame.Angles(math.rad(-18),angle,math.rad(i%2==0 and 15 or -15)),bright,0.20))
	end
	local eye=add(part(model,"EyeGlow",Vector3.new(1.15,0.18,0.1),head.CFrame*CFrame.new(0,0,-0.96),bright,0.06))
	local aura = Instance.new("PointLight")
	aura.Color = color
	aura.Brightness = 1.4
	aura.Range = 12
	aura.Shadows = false
	aura.Parent = eye

	local outline = Instance.new("Highlight")
	outline.Adornee = model
	outline.FillTransparency = 1
	outline.OutlineColor = bright
	outline.OutlineTransparency = 0.28
	outline.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	outline.Parent = model

	for _,p in ipairs(created) do fade(p,1.5) end
end

for _,child in ipairs(events:GetChildren()) do task.defer(decorate,child) end
events.ChildAdded:Connect(function(child) task.defer(decorate,child) end)

print("[FighterEchoArt] stylized assist echoes active")
