local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local Config = require(AnimeRift:WaitForChild("Config"))
local world = Workspace:WaitForChild("AnimeRiftWorld", 30)
if not world then return end

-- Let the ordinary world services finish, then apply one isolated visual layer.
task.wait(2.5)
local old = world:FindFirstChild("VisualOverhaul")
if old then old:Destroy() end
local art = Instance.new("Folder")
art.Name = "VisualOverhaul"
art.Parent = world

local function makePart(parent, name, size, cf, color, material, transparency, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = collide == true
	p.CanTouch = false
	p.CanQuery = collide == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function beam(parent, a, b, thickness, color, material, transparency)
	local delta = b - a
	if delta.Magnitude < 0.1 then return end
	makePart(parent, "Beam", Vector3.new(thickness, thickness, delta.Magnitude), CFrame.lookAt(a:Lerp(b, 0.5), b), color, material, transparency, false)
end

local function glow(parent, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = parent
end

local function setArtDirection()
	Lighting.ClockTime = 16.75
	Lighting.Brightness = 2.15
	Lighting.ExposureCompensation = 0.12
	Lighting.Ambient = Color3.fromRGB(84, 86, 104)
	Lighting.OutdoorAmbient = Color3.fromRGB(132, 132, 151)
	Lighting.EnvironmentDiffuseScale = 0.62
	Lighting.EnvironmentSpecularScale = 0.80
	Lighting.ShadowSoftness = 0.28
	Lighting.GlobalShadows = true

	for _, child in ipairs(Lighting:GetChildren()) do
		if child.Name == "AnimeRiftFX" or string.find(child.Name, "VisualRiftFX", 1, true) == 1 then child:Destroy() end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "VisualRiftFX_Atmosphere"
	atmosphere.Density = 0.23
	atmosphere.Offset = 0.18
	atmosphere.Color = Color3.fromRGB(199, 215, 235)
	atmosphere.Decay = Color3.fromRGB(102, 92, 126)
	atmosphere.Glare = 0.10
	atmosphere.Haze = 1.1
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "VisualRiftFX_Bloom"
	bloom.Intensity = 0.20
	bloom.Size = 25
	bloom.Threshold = 1.2
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "VisualRiftFX_Color"
	cc.Contrast = 0.10
	cc.Saturation = 0.08
	cc.Brightness = 0.01
	cc.TintColor = Color3.fromRGB(255, 247, 243)
	cc.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Name = "VisualRiftFX_Rays"
	rays.Intensity = 0.05
	rays.Spread = 0.8
	rays.Parent = Lighting

	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "VisualRiftFX_DOF"
	dof.FocusDistance = 75
	dof.InFocusRadius = 115
	dof.NearIntensity = 0
	dof.FarIntensity = 0.045
	dof.Parent = Lighting

	local terrain = Workspace.Terrain
	local palette = {
		[Enum.Material.Grass] = Color3.fromRGB(82, 119, 77),
		[Enum.Material.Ground] = Color3.fromRGB(116, 97, 78),
		[Enum.Material.Mud] = Color3.fromRGB(88, 72, 66),
		[Enum.Material.Rock] = Color3.fromRGB(89, 90, 98),
		[Enum.Material.Slate] = Color3.fromRGB(75, 76, 91),
		[Enum.Material.Cobblestone] = Color3.fromRGB(102, 100, 111),
		[Enum.Material.Basalt] = Color3.fromRGB(54, 47, 66),
		[Enum.Material.Snow] = Color3.fromRGB(220, 232, 239),
		[Enum.Material.Ice] = Color3.fromRGB(155, 211, 230),
	}
	for material, color in pairs(palette) do pcall(function() terrain:SetMaterialColor(material, color) end) end
	pcall(function() terrain.Decoration = true end)
	terrain.WaterColor = Color3.fromRGB(59, 130, 154)
	terrain.WaterTransparency = 0.27
	terrain.WaterReflectance = 0.23
	terrain.WaterWaveSize = 0.12
	terrain.WaterWaveSpeed = 7

	local clouds = terrain:FindFirstChild("AnimeRiftClouds")
	if clouds and clouds:IsA("Clouds") then
		clouds.Cover = 0.34
		clouds.Density = 0.39
		clouds.Color = Color3.fromRGB(247, 238, 244)
	end
end

local function cleanupPrototypeFoliage()
	local replace = {TreeCrown=true, TreeTrunk=true, WildTreeCrown=true, WildTreeTrunk=true, PineNeedles=true, PineTrunk=true}
	for _, object in ipairs(world:GetDescendants()) do
		if object:IsA("BasePart") and replace[object.Name] then object:Destroy() end
	end
end

local function tree(parent, pos, scale, leaves, blossom)
	local f = Instance.new("Folder")
	f.Name = blossom and "SakuraTree" or "AnimeTree"
	f.Parent = parent
	local trunkColor = blossom and Color3.fromRGB(78, 55, 59) or Color3.fromRGB(75, 57, 43)
	local trunk = makePart(f, "Trunk", Vector3.new(1.55, 8.6, 1.55) * scale,
		CFrame.new(pos + Vector3.new(0, 4.3 * scale, 0)) * CFrame.Angles(math.rad(2), math.rad((pos.X + pos.Z) % 40), math.rad(2)),
		trunkColor, Enum.Material.Wood, 0, true)
	for _, branch in ipairs({
		{Vector3.new(0,6.4,0), Vector3.new(-3.1,9.3,0.6)},
		{Vector3.new(0,6.8,0), Vector3.new(3.0,9.5,-0.5)},
		{Vector3.new(0,7.2,0), Vector3.new(0.6,10.6,2.0)},
	}) do beam(f, pos + branch[1] * scale, pos + branch[2] * scale, 0.6 * scale, trunkColor, Enum.Material.Wood, 0) end
	local clusters = {
		{Vector3.new(0,11,0),Vector3.new(6.2,4.2,5.8)}, {Vector3.new(-3.0,9.8,0.5),Vector3.new(4.7,3.5,4.4)},
		{Vector3.new(3.0,10,-0.6),Vector3.new(4.6,3.6,4.4)}, {Vector3.new(0.6,9.8,2.8),Vector3.new(4.3,3.2,4.0)},
		{Vector3.new(-0.5,12.4,-2.2),Vector3.new(3.8,2.9,3.8)},
	}
	for i, c in ipairs(clusters) do
		local leaf = makePart(f, "Canopy", c[2] * scale, CFrame.new(pos + c[1] * scale), leaves[((i-1)%#leaves)+1], Enum.Material.SmoothPlastic, 0, false)
		leaf.Shape = Enum.PartType.Ball
	end
	if blossom then
		local petals = Instance.new("ParticleEmitter")
		petals.Name = "Petals"
		petals.Rate = 2
		petals.Lifetime = NumberRange.new(4,6)
		petals.Speed = NumberRange.new(0.25,0.75)
		petals.SpreadAngle = Vector2.new(180,55)
		petals.Acceleration = Vector3.new(0.25,-0.55,0.2)
		petals.Color = ColorSequence.new(Color3.fromRGB(255,190,219), Color3.fromRGB(230,139,190))
		petals.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.16),NumberSequenceKeypoint.new(1,0.05)})
		petals.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.18),NumberSequenceKeypoint.new(1,1)})
		petals.LightEmission = 0.08
		petals.Parent = trunk
	end
end

local function crystal(parent, pos, scale, color, yaw)
	local shell = makePart(parent, "RiftCrystal", Vector3.new(1.6,6.5,1.6)*scale,
		CFrame.new(pos)*CFrame.Angles(math.rad(8),math.rad(yaw or 0),math.rad(18)), color, Enum.Material.Glass, 0.10, false)
	local core = shell:Clone()
	core.Name = "CrystalCore"
	core.Size = shell.Size * 0.52
	core.Material = Enum.Material.Neon
	core.Transparency = 0.15
	core.Color = color:Lerp(Color3.new(1,1,1),0.24)
	core.Parent = parent
	glow(core,color,0.5*scale,8+scale*5)
end

local function lantern(parent, pos, color)
	makePart(parent,"LanternPost",Vector3.new(0.38,5.2,0.38),CFrame.new(pos+Vector3.new(0,2.6,0)),Color3.fromRGB(54,48,56),Enum.Material.Wood,0,true)
	local lamp = makePart(parent,"SpiritLantern",Vector3.new(1.1,1.4,1.1),CFrame.new(pos+Vector3.new(0,5.1,0)),color,Enum.Material.Glass,0.15,false)
	glow(lamp,color,0.65,11)
end

local function gate(parent, center, yaw, tint, scale)
	scale = scale or 1
	local cf = CFrame.new(center)*CFrame.Angles(0,math.rad(yaw or 0),0)
	local dark = Color3.fromRGB(45,42,51)
	for _, x in ipairs({-7.2,7.2}) do
		makePart(parent,"GatePillar",Vector3.new(1.25,12.8,1.25)*scale,cf*CFrame.new(x*scale,6.4*scale,0),dark,Enum.Material.Slate,0,true)
		local rune = makePart(parent,"GateRune",Vector3.new(1.55,3,1.55)*scale,cf*CFrame.new(x*scale,2*scale,0),tint,Enum.Material.Neon,0.32,false)
		glow(rune,tint,0.3,8*scale)
	end
	makePart(parent,"GateBeam",Vector3.new(18.2,1.2,1.35)*scale,cf*CFrame.new(0,12*scale,0),dark,Enum.Material.Slate,0,true)
	makePart(parent,"GateCrown",Vector3.new(21,0.65,1.6)*scale,cf*CFrame.new(0,13.2*scale,0),tint:Lerp(dark,0.58),Enum.Material.Slate,0,true)
	local core = makePart(parent,"GateCore",Vector3.new(4,1.8,0.2)*scale,cf*CFrame.new(0,11.9*scale,-0.78*scale),tint,Enum.Material.Neon,0.08,false)
	glow(core,tint,0.35,8*scale)
end

local function banner(parent, pos, tint, text)
	makePart(parent,"BannerPole",Vector3.new(0.32,8,0.32),CFrame.new(pos+Vector3.new(0,4,0)),Color3.fromRGB(50,46,55),Enum.Material.Metal,0,true)
	local cloth = makePart(parent,"Banner",Vector3.new(3,5.2,0.14),CFrame.new(pos+Vector3.new(1.55,5,0)),tint,Enum.Material.Fabric,0.03,false)
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.PixelsPerStud = 35
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.Parent = cloth
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(244,239,255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = surface
end

local function buildHub()
	local f = Instance.new("Folder")
	f.Name = "RiftHaven"
	f.Parent = art
	local pink = {Color3.fromRGB(244,155,196),Color3.fromRGB(255,188,218),Color3.fromRGB(224,137,190)}
	for _, d in ipairs({
		{Vector3.new(-31,2.3,29),0.90},{Vector3.new(32,2.3,29),0.96},{Vector3.new(-38,2.3,-39),0.84},
		{Vector3.new(39,2.3,-37),0.88},{Vector3.new(-64,2.2,61),0.78},{Vector3.new(64,2.2,59),0.82},
	}) do tree(f,d[1],d[2],pink,true) end
	for i=1,10 do
		local a=i/10*math.pi*2
		crystal(f,Vector3.new(math.cos(a)*15.5,5,-4+math.sin(a)*15.5),i%3==0 and 0.8 or 0.58,i%2==0 and Color3.fromRGB(88,210,239) or Color3.fromRGB(174,101,246),i*29)
	end
	for _, p in ipairs({Vector3.new(-23,2.6,23),Vector3.new(23,2.6,23),Vector3.new(-23,2.6,-29),Vector3.new(23,2.6,-29)}) do lantern(f,p,Color3.fromRGB(196,137,255)) end
	banner(f,Vector3.new(-13,2.4,37),Color3.fromRGB(88,64,128),"RIFT")
	banner(f,Vector3.new(13,2.4,37),Color3.fromRGB(52,109,136),"ASCEND")
	gate(f,Vector3.new(0,2.3,78),0,Color3.fromRGB(139,92,202),1.05)
	local anchor = makePart(f,"MoteAnchor",Vector3.one,CFrame.new(0,9,5),Color3.new(0,0,0),Enum.Material.SmoothPlastic,1,false)
	local motes = Instance.new("ParticleEmitter")
	motes.Rate = 6
	motes.Lifetime = NumberRange.new(3,6)
	motes.Speed = NumberRange.new(0.3,0.9)
	motes.SpreadAngle = Vector2.new(180,180)
	motes.Acceleration = Vector3.new(0,0.3,0)
	motes.Color = ColorSequence.new(Color3.fromRGB(139,207,255),Color3.fromRGB(207,130,255))
	motes.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.14),NumberSequenceKeypoint.new(1,0)})
	motes.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,1)})
	motes.LightEmission = 0.65
	motes.Parent = anchor
end

local function buildBiome(zone)
	local f = Instance.new("Folder")
	f.Name = "Biome_"..zone.Id
	f.Parent = art
	local c = zone.Center
	if zone.Id == 1 then
		local green={Color3.fromRGB(68,130,89),Color3.fromRGB(91,156,99),Color3.fromRGB(117,172,110)}
		for _,d in ipairs({{-64,-35,.92},{-48,35,.82},{50,-42,.96},{64,28,.86},{-17,66,.78},{26,72,.90}}) do tree(f,c+Vector3.new(d[1],2.2,d[2]),d[3],green,false) end
		gate(f,c+Vector3.new(0,2.3,-48),0,Color3.fromRGB(76,173,124),.9)
		crystal(f,c+Vector3.new(0,7,42),1.1,Color3.fromRGB(84,220,158),18)
	elseif zone.Id == 2 then
		local ember=Color3.fromRGB(236,105,61)
		gate(f,c+Vector3.new(-18,3,-50),25,ember,.95)
		for _,o in ipairs({Vector3.new(-48,7,20),Vector3.new(48,8,-12),Vector3.new(32,6,52),Vector3.new(-38,7,-48)}) do crystal(f,c+o,1.1,ember:Lerp(Color3.fromRGB(255,190,86),.24),o.X) end
	elseif zone.Id == 3 then
		local ice=Color3.fromRGB(126,207,245)
		gate(f,c+Vector3.new(0,3,-56),0,ice,1)
		for _,o in ipairs({Vector3.new(-42,8,-42),Vector3.new(44,10,-34),Vector3.new(-55,7,38),Vector3.new(50,9,47),Vector3.new(0,12,64)}) do crystal(f,c+o,1.3,ice:Lerp(Color3.fromRGB(191,159,255),.18),o.Z) end
	else
		local void=Color3.fromRGB(170,91,235)
		for i=1,7 do local a=i/7*math.pi*2; local r=48+(i%2)*12; crystal(f,c+Vector3.new(math.cos(a)*r,9+(i%3)*2,math.sin(a)*r),1.3,i%2==0 and void or Color3.fromRGB(80,187,229),i*37) end
		local mono=makePart(f,"VoidMonolith",Vector3.new(12,27,7),CFrame.new(c+Vector3.new(0,15.5,52))*CFrame.Angles(math.rad(4),math.rad(17),math.rad(-5)),Color3.fromRGB(40,36,52),Enum.Material.Basalt,0,true)
		local slit=makePart(f,"VoidCore",Vector3.new(2,16,.25),mono.CFrame*CFrame.new(0,0,-3.55),void,Enum.Material.Neon,.06,false)
		glow(slit,void,1.0,18)
	end
end

setArtDirection()
cleanupPrototypeFoliage()
buildHub()
for _,zone in ipairs(Config.Zones) do buildBiome(zone) end
print("[VisualOverhaul] anime-fantasy world active")
