local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local Config = require(AnimeRift:WaitForChild("Config"))

local world = Workspace:WaitForChild("AnimeRiftWorld", 30)
if not world then
	warn("[VisualWorld] AnimeRiftWorld did not appear")
	return
end
local map = world:WaitForChild("Map", 15)
if not map then return end

-- Let the normal world/decor services finish first. This layer intentionally runs last.
task.wait(2.5)

local previous = world:FindFirstChild("VisualOverhaul")
if previous then previous:Destroy() end
local art = Instance.new("Folder")
art.Name = "VisualOverhaul"
art.Parent = world

local function part(parent, name, size, cf, color, material, transparency, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = collide == true
	p.CanTouch = false
	p.CanQuery = collide == true
	p.CastShadow = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function orb(parent, name, size, cf, color, material, transparency)
	local p = part(parent, name, size, cf, color, material, transparency, false)
	p.Shape = Enum.PartType.Ball
	return p
end

local function light(parent, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = parent
	return l
end

local function beam(parent, name, a, b, thickness, color, material, transparency, collide)
	local delta = b - a
	if delta.Magnitude < 0.1 then return nil end
	local mid = a:Lerp(b, 0.5)
	return part(parent, name, Vector3.new(thickness, thickness, delta.Magnitude), CFrame.lookAt(mid, b), color, material, transparency, collide)
end

local function billboard(parent, title, subtitle, tint, studsOffset)
	local gui = Instance.new("BillboardGui")
	gui.Name = "VisualLabel"
	gui.Size = UDim2.new(0, 250, 0, 62)
	gui.StudsOffset = studsOffset or Vector3.new(0, 6, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 65
	gui.LightInfluence = 0
	gui.Parent = parent
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 36)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = tint
	titleLabel.TextStrokeTransparency = 0.48
	titleLabel.TextSize = 20
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Parent = gui
	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, 0, 0, 20)
	sub.Position = UDim2.new(0, 0, 0, 34)
	sub.BackgroundTransparency = 1
	sub.Text = subtitle or ""
	sub.TextColor3 = Color3.fromRGB(220, 222, 235)
	sub.TextStrokeTransparency = 0.68
	sub.TextSize = 10
	sub.Font = Enum.Font.GothamBold
	sub.Parent = gui
end

local function configureLighting()
	Lighting.ClockTime = 16.75
	Lighting.Brightness = 2.2
	Lighting.ExposureCompensation = 0.12
	Lighting.Ambient = Color3.fromRGB(86, 88, 105)
	Lighting.OutdoorAmbient = Color3.fromRGB(132, 132, 149)
	Lighting.EnvironmentDiffuseScale = 0.62
	Lighting.EnvironmentSpecularScale = 0.82
	Lighting.ShadowSoftness = 0.28
	Lighting.GlobalShadows = true

	for _, child in ipairs(Lighting:GetChildren()) do
		if child.Name == "AnimeRiftFX" or string.sub(child.Name, 1, 12) == "VisualRiftFX" then
			child:Destroy()
		end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "VisualRiftFX_Atmosphere"
	atmosphere.Density = 0.24
	atmosphere.Offset = 0.18
	atmosphere.Color = Color3.fromRGB(199, 215, 235)
	atmosphere.Decay = Color3.fromRGB(102, 92, 126)
	atmosphere.Glare = 0.11
	atmosphere.Haze = 1.18
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "VisualRiftFX_Bloom"
	bloom.Intensity = 0.22
	bloom.Size = 26
	bloom.Threshold = 1.18
	bloom.Parent = Lighting

	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "VisualRiftFX_Color"
	correction.Brightness = 0.015
	correction.Contrast = 0.105
	correction.Saturation = 0.08
	correction.TintColor = Color3.fromRGB(255, 246, 242)
	correction.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Name = "VisualRiftFX_Rays"
	rays.Intensity = 0.055
	rays.Spread = 0.79
	rays.Parent = Lighting

	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "VisualRiftFX_DOF"
	dof.FocusDistance = 75
	dof.InFocusRadius = 110
	dof.NearIntensity = 0
	dof.FarIntensity = 0.055
	dof.Parent = Lighting

	local terrain = Workspace.Terrain
	terrain.WaterColor = Color3.fromRGB(64, 132, 153)
	terrain.WaterTransparency = 0.28
	terrain.WaterReflectance = 0.24
	terrain.WaterWaveSize = 0.14
	terrain.WaterWaveSpeed = 8

	local clouds = terrain:FindFirstChild("AnimeRiftClouds")
	if clouds and clouds:IsA("Clouds") then
		clouds.Cover = 0.34
		clouds.Density = 0.39
		clouds.Color = Color3.fromRGB(249, 238, 244)
	end
end

local function cleanupPrototypeFoliage()
	-- Keep gameplay geometry, buildings and landmarks. Replace only the most obvious
	-- round prototype foliage with the cohesive anime-fantasy foliage below.
	local names = {
		TreeCrown = true, TreeTrunk = true,
		WildTreeCrown = true, WildTreeTrunk = true,
		PineNeedles = true, PineTrunk = true,
	}
	for _, object in ipairs(world:GetDescendants()) do
		if names[object.Name] and object:IsA("BasePart") then
			object:Destroy()
		end
	end
end

local function stylizedTree(parent, pos, scale, trunkColor, leafColors, blossom)
	local folder = Instance.new("Folder")
	folder.Name = blossom and "SakuraTree" or "RiftTree"
	folder.Parent = parent

	local trunk = part(folder, "Trunk", Vector3.new(1.55, 8.5, 1.55) * scale,
		CFrame.new(pos + Vector3.new(0, 4.25 * scale, 0)) * CFrame.Angles(math.rad(1.5), math.rad((pos.X + pos.Z) % 45), math.rad(2.5)),
		trunkColor, Enum.Material.Wood, 0, true)
	trunk.CastShadow = true

	local branches = {
		{Vector3.new(-1.8, 7.0, 0), Vector3.new(-3.4, 9.0, 0.7)},
		{Vector3.new(1.5, 7.2, 0.4), Vector3.new(3.2, 9.3, -0.6)},
		{Vector3.new(0.3, 7.7, 0), Vector3.new(0.5, 10.2, 1.8)},
	}
	for _, pair in ipairs(branches) do
		beam(folder, "Branch", pos + pair[1] * scale, pos + pair[2] * scale, 0.65 * scale, trunkColor, Enum.Material.Wood, 0, false)
	end

	local clusters = {
		{Vector3.new(0, 11.0, 0), Vector3.new(6.2, 4.4, 6.0)},
		{Vector3.new(-3.2, 9.8, 0.6), Vector3.new(4.8, 3.7, 4.6)},
		{Vector3.new(3.0, 10.0, -0.7), Vector3.new(4.7, 3.8, 4.5)},
		{Vector3.new(0.6, 9.7, 3.0), Vector3.new(4.5, 3.4, 4.2)},
		{Vector3.new(-0.4, 12.4, -2.5), Vector3.new(4.0, 3.0, 4.0)},
	}
	for i, cluster in ipairs(clusters) do
		local color = leafColors[((i - 1) % #leafColors) + 1]
		local leaf = part(folder, "Canopy", cluster[2] * scale, CFrame.new(pos + cluster[1] * scale), color, Enum.Material.SmoothPlastic, 0, false)
		leaf.Shape = Enum.PartType.Ball
		leaf.CastShadow = true
	end

	if blossom then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Petals"
		emitter.Rate = 2.5
		emitter.Lifetime = NumberRange.new(3.8, 6.2)
		emitter.Speed = NumberRange.new(0.25, 0.8)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-35, 35)
		emitter.SpreadAngle = Vector2.new(180, 55)
		emitter.Acceleration = Vector3.new(0.4, -0.65, 0.2)
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 191, 219), Color3.fromRGB(239, 147, 192))
		emitter.LightEmission = 0.08
		emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0.08)})
		emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 1)})
		emitter.Parent = trunk
	end
	return folder
end

local function crystal(parent, pos, scale, color, yaw)
	local p = part(parent, "RiftCrystal", Vector3.new(1.6, 6.5, 1.6) * scale,
		CFrame.new(pos) * CFrame.Angles(math.rad(8), math.rad(yaw or 0), math.rad(18)), color, Enum.Material.Glass, 0.10, false)
	local core = p:Clone()
	core.Name = "CrystalCore"
	core.Size = p.Size * 0.52
	core.Material = Enum.Material.Neon
	core.Transparency = 0.18
	core.Color = color:Lerp(Color3.new(1, 1, 1), 0.24)
	core.Parent = parent
	light(core, color, 0.55 * scale, 8 + scale * 5)
	return p
end

local function lantern(parent, pos, tint, scale)
	scale = scale or 1
	local post = part(parent, "SpiritLanternPost", Vector3.new(0.38, 5.2, 0.38) * scale,
		CFrame.new(pos + Vector3.new(0, 2.6 * scale, 0)), Color3.fromRGB(56, 49, 57), Enum.Material.Wood, 0, true)
	local lamp = part(parent, "SpiritLantern", Vector3.new(1.15, 1.45, 1.15) * scale,
		CFrame.new(pos + Vector3.new(0, 5.1 * scale, 0)), tint, Enum.Material.Glass, 0.16, false)
	light(lamp, tint, 0.7, 12 * scale)
	return post
end

local function banner(parent, pos, yaw, tint, text)
	local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(yaw), 0)
	part(parent, "BannerPole", Vector3.new(0.35, 8.5, 0.35), cf * CFrame.new(0, 4.25, 0), Color3.fromRGB(52, 47, 56), Enum.Material.Metal, 0, true)
	local cloth = part(parent, "RiftBanner", Vector3.new(3.2, 5.5, 0.16), cf * CFrame.new(1.7, 5.2, 0), tint, Enum.Material.Fabric, 0.04, false)
	local rune = Instance.new("SurfaceGui")
	rune.Face = Enum.NormalId.Front
	rune.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	rune.PixelsPerStud = 35
	rune.Parent = cloth
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text or "◇"
	label.TextColor3 = Color3.fromRGB(245, 238, 255)
	label.TextTransparency = 0.08
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = rune
end

local function torii(parent, center, yaw, tint, scale)
	scale = scale or 1
	local cf = CFrame.new(center) * CFrame.Angles(0, math.rad(yaw), 0)
	local dark = Color3.fromRGB(46, 42, 51)
	for _, x in ipairs({-7.2, 7.2}) do
		part(parent, "RiftGatePillar", Vector3.new(1.25, 12.8, 1.25) * scale, cf * CFrame.new(x * scale, 6.4 * scale, 0), dark, Enum.Material.Slate, 0, true)
		local foot = part(parent, "GateRune", Vector3.new(1.7, 3.2, 1.7) * scale, cf * CFrame.new(x * scale, 2.0 * scale, 0), tint, Enum.Material.Neon, 0.36, false)
		light(foot, tint, 0.35, 8 * scale)
	end
	part(parent, "RiftGateBeam", Vector3.new(18.2, 1.25, 1.35) * scale, cf * CFrame.new(0, 12.0 * scale, 0), dark, Enum.Material.Slate, 0, true)
	part(parent, "RiftGateCrown", Vector3.new(21.0, 0.65, 1.65) * scale, cf * CFrame.new(0, 13.3 * scale, 0), tint:Lerp(dark, 0.60), Enum.Material.Slate, 0, true)
	local rune = part(parent, "RiftGateCore", Vector3.new(4.1, 1.9, 0.22) * scale, cf * CFrame.new(0, 11.9 * scale, -0.78 * scale), tint, Enum.Material.Neon, 0.10, false)
	light(rune, tint, 0.38, 8 * scale)
end

local function hubArt()
	local folder = Instance.new("Folder")
	folder.Name = "RiftHavenArt"
	folder.Parent = art

	-- Central shrine: the old functional well remains, this gives it a strong silhouette.
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		local radius = 15.5
		local pos = Vector3.new(math.cos(angle) * radius, 4.4 + math.sin(i * 1.7) * 0.8, -4 + math.sin(angle) * radius)
		crystal(folder, pos, i % 3 == 0 and 0.80 or 0.58, i % 2 == 0 and Color3.fromRGB(94, 214, 239) or Color3.fromRGB(173, 104, 247), i * 29)
	end

	local ringColor = Color3.fromRGB(124, 88, 174)
	for i = 1, 16 do
		local a1 = ((i - 1) / 16) * math.pi * 2
		local a2 = (i / 16) * math.pi * 2
		local p1 = Vector3.new(math.cos(a1) * 20, 3.18, -4 + math.sin(a1) * 20)
		local p2 = Vector3.new(math.cos(a2) * 20, 3.18, -4 + math.sin(a2) * 20)
		beam(folder, "ShrineRing", p1, p2, 0.32, ringColor, Enum.Material.Neon, 0.28, false)
	end

	local sakuraPalette = {Color3.fromRGB(244, 156, 197), Color3.fromRGB(255, 188, 218), Color3.fromRGB(224, 137, 190)}
	for _, data in ipairs({
		{Vector3.new(-31, 2.3, 29), 0.90}, {Vector3.new(32, 2.3, 29), 0.96},
		{Vector3.new(-38, 2.3, -39), 0.85}, {Vector3.new(39, 2.3, -37), 0.88},
		{Vector3.new(-64, 2.2, 61), 0.78}, {Vector3.new(64, 2.2, 59), 0.82},
	}) do
		stylizedTree(folder, data[1], data[2], Color3.fromRGB(78, 55, 59), sakuraPalette, true)
	end

	for _, pos in ipairs({Vector3.new(-23, 2.7, 23), Vector3.new(23, 2.7, 23), Vector3.new(-23, 2.7, -29), Vector3.new(23, 2.7, -29)}) do
		lantern(folder, pos, Color3.fromRGB(198, 139, 255), 1)
	end

	banner(folder, Vector3.new(-13, 2.5, 37), 0, Color3.fromRGB(89, 66, 130), "RIFT")
	banner(folder, Vector3.new(13, 2.5, 37), 180, Color3.fromRGB(54, 112, 137), "ASCEND")
	torii(folder, Vector3.new(0, 2.3, 78), 0, Color3.fromRGB(139, 92, 202), 1.05)

	-- A few luminous motes around the plaza give the hub motion even while standing still.
	local anchor = part(folder, "SpiritMoteAnchor", Vector3.new(1, 1, 1), CFrame.new(0, 9, 5), Color3.new(), Enum.Material.SmoothPlastic, 1, false)
	local motes = Instance.new("ParticleEmitter")
	motes.Name = "RiftMotes"
	motes.Rate = 7
	motes.Lifetime = NumberRange.new(3, 6)
	motes.Speed = NumberRange.new(0.35, 1.0)
	motes.SpreadAngle = Vector2.new(180, 180)
	motes.Acceleration = Vector3.new(0, 0.35, 0)
	motes.Color = ColorSequence.new(Color3.fromRGB(140, 208, 255), Color3.fromRGB(208, 131, 255))
	motes.LightEmission = 0.7
	motes.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.16), NumberSequenceKeypoint.new(0.7, 0.09), NumberSequenceKeypoint.new(1, 0)})
	motes.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1)})
	motes.Parent = anchor
end

local function biomeLandmark(zone)
	local folder = Instance.new("Folder")
	folder.Name = "ZoneArt_" .. zone.Id
	folder.Parent = art
	local c = zone.Center

	if zone.Id == 1 then
		local palette = {Color3.fromRGB(70, 133, 91), Color3.fromRGB(92, 157, 100), Color3.fromRGB(118, 173, 111)}
		for _, data in ipairs({{-64,-35,0.92},{-48,35,0.82},{50,-42,0.96},{64,28,0.86},{-17,66,0.78},{26,72,0.90}}) do
			stylizedTree(folder, c + Vector3.new(data[1], 2.2, data[2]), data[3], Color3.fromRGB(75, 57, 43), palette, false)
		end
		torii(folder, c + Vector3.new(0, 2.3, -48), 0, Color3.fromRGB(77, 174, 125), 0.9)
		crystal(folder, c + Vector3.new(0, 7, 42), 1.1, Color3.fromRGB(85, 222, 160), 18)
	elseif zone.Id == 2 then
		local ember = Color3.fromRGB(235, 105, 60)
		torii(folder, c + Vector3.new(-18, 3, -50), 25, ember, 0.95)
		for _, offset in ipairs({Vector3.new(-48,7,20), Vector3.new(48,8,-12), Vector3.new(32,6,52), Vector3.new(-38,7,-48)}) do
			crystal(folder, c + offset, 1.1, ember:Lerp(Color3.fromRGB(255, 190, 86), 0.25), math.floor(offset.X))
		end
		for _, pos in ipairs({Vector3.new(-58,2,58), Vector3.new(57,2,55), Vector3.new(-62,2,-58), Vector3.new(63,2,-50)}) do
			banner(folder, c + pos, pos.X > 0 and 180 or 0, Color3.fromRGB(120, 49, 43), "EMBER")
		end
	elseif zone.Id == 3 then
		local ice = Color3.fromRGB(126, 207, 245)
		for _, offset in ipairs({Vector3.new(-42,8,-42), Vector3.new(44,10,-34), Vector3.new(-55,7,38), Vector3.new(50,9,47), Vector3.new(0,12,64)}) do
			crystal(folder, c + offset, 1.3, ice:Lerp(Color3.fromRGB(191, 159, 255), 0.18), math.floor(offset.Z))
		end
		torii(folder, c + Vector3.new(0, 3, -56), 0, ice, 1.0)
	elseif zone.Id == 4 then
		local void = Color3.fromRGB(170, 91, 235)
		for i = 1, 7 do
			local angle = (i / 7) * math.pi * 2
			local radius = 48 + (i % 2) * 12
			local p = c + Vector3.new(math.cos(angle) * radius, 8 + (i % 3) * 2, math.sin(angle) * radius)
			crystal(folder, p, 1.35, i % 2 == 0 and void or Color3.fromRGB(80, 188, 230), i * 37)
		end
		local monolith = part(folder, "VoidMonolith", Vector3.new(12, 27, 7), CFrame.new(c + Vector3.new(0, 15.5, 52)) * CFrame.Angles(math.rad(4), math.rad(17), math.rad(-5)), Color3.fromRGB(41, 37, 53), Enum.Material.Basalt, 0, true)
		local slit = part(folder, "VoidMonolithCore", Vector3.new(2.1, 16, 0.3), monolith.CFrame * CFrame.new(0, 0, -3.55), void, Enum.Material.Neon, 0.07, false)
		light(slit, void, 1.1, 18)
		billboard(monolith, "VOID SCAR", "THE RIFT IS WATCHING", Color3.fromRGB(214, 157, 255), Vector3.new(0, 16.5, 0))
	end
end

configureLighting()
cleanupPrototypeFoliage()
hubArt()
for _, zone in ipairs(Config.Zones) do biomeLandmark(zone) end

print("[VisualWorld] anime-fantasy art direction active")
