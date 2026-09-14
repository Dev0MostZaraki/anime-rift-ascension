local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local WorldService = {}
WorldService.__index = WorldService

function WorldService.new(context)
	local self = setmetatable({}, WorldService)
	self.Context = context
	self.ZoneSpawnPoints = {}
	self.EggPedestals = {}
	self.WorldFolder = nil
	self.MapFolder = nil
	return self
end

local function makePart(parent, name, size, cf, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = color or Color3.fromRGB(100, 100, 100)
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Parent = parent
	return part
end

local function makeBillboard(parent, text, offset, color, size, maxDistance)
	local gui = Instance.new("BillboardGui")
	gui.Size = size or UDim2.new(0, 230, 0, 64)
	gui.StudsOffset = offset or Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = maxDistance or 90
	gui.LightInfluence = 0
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.45
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	return label
end

local function prompt(parent, action, objectText, hold)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = objectText
	p.HoldDuration = hold or 0.12
	p.MaxActivationDistance = 14
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = Enum.KeyCode.F
	p.Parent = parent
	return p
end

local function pointLight(parent, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness or 1
	light.Range = range or 14
	light.Shadows = true
	light.Parent = parent
	return light
end

local function accentPart(parent, name, size, cf, color, transparency)
	local p = makePart(parent, name, size, cf, color, Enum.Material.Neon, transparency or 0.08)
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	return p
end

function WorldService:PlayerNear(player, part, distance)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and (root.Position - part.Position).Magnitude <= distance
end

function WorldService:ConfigureLighting()
	Lighting.ClockTime = 19.15
	Lighting.Brightness = 1.8
	Lighting.ExposureCompensation = -0.08
	Lighting.Ambient = Color3.fromRGB(45, 48, 67)
	Lighting.OutdoorAmbient = Color3.fromRGB(76, 80, 105)
	Lighting.EnvironmentDiffuseScale = 0.42
	Lighting.EnvironmentSpecularScale = 0.65
	Lighting.GlobalShadows = true

	for _, object in ipairs(Lighting:GetChildren()) do
		if object.Name == "AnimeRiftFX" then object:Destroy() end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "AnimeRiftFX"
	atmosphere.Density = 0.24
	atmosphere.Offset = 0.12
	atmosphere.Color = Color3.fromRGB(166, 174, 215)
	atmosphere.Decay = Color3.fromRGB(52, 45, 82)
	atmosphere.Glare = 0.08
	atmosphere.Haze = 1.15
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "AnimeRiftFX"
	bloom.Intensity = 0.30
	bloom.Size = 26
	bloom.Threshold = 1.45
	bloom.Parent = Lighting

	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "AnimeRiftFX"
	correction.Brightness = -0.01
	correction.Contrast = 0.13
	correction.Saturation = 0.02
	correction.TintColor = Color3.fromRGB(236, 239, 255)
	correction.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Name = "AnimeRiftFX"
	rays.Intensity = 0.035
	rays.Spread = 0.72
	rays.Parent = Lighting
end

function WorldService:BuildPortal(id, zone, position, yaw)
	local map = self.MapFolder
	local base = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0)
	local stone = Color3.fromRGB(35, 38, 51)
	local trim = Color3.fromRGB(67, 69, 86)

	local platform = makePart(map, "PortalPlatform_" .. id, Vector3.new(32, 2.2, 24), base * CFrame.new(0, 1.1, 0), stone, Enum.Material.Slate)
	platform.CanCollide = true
	makePart(map, "PortalStep_" .. id, Vector3.new(20, 1, 7), base * CFrame.new(0, 2.7, 10), trim, Enum.Material.Marble)
	local pad = makePart(map, "Portal_" .. id, Vector3.new(13, 0.65, 8), base * CFrame.new(0, 2.58, 4.5), zone.Color:Lerp(stone, 0.28), Enum.Material.SmoothPlastic)
	pointLight(pad, zone.Color, 0.75, 12)

	for _, x in ipairs({-7, 7}) do
		local post = makePart(map, "PortalPost_" .. id, Vector3.new(3.2, 18, 3.2), base * CFrame.new(x, 11.2, -2), stone, Enum.Material.Marble)
		post.CanCollide = true
		accentPart(map, "PortalTrim_" .. id, Vector3.new(3.7, 0.55, 3.7), base * CFrame.new(x, 18.5, -2), zone.Color, 0.04)
	end
	makePart(map, "PortalLintel_" .. id, Vector3.new(18, 3, 3.4), base * CFrame.new(0, 20, -2), stone, Enum.Material.Marble)
	accentPart(map, "PortalCrown_" .. id, Vector3.new(20, 0.65, 3.8), base * CFrame.new(0, 21.85, -2), zone.Color, 0.02)

	local surface = makePart(map, "PortalSurface_" .. id, Vector3.new(11.7, 13.8, 0.65), base * CFrame.new(0, 11.4, -1.95), zone.Color, Enum.Material.Glass, 0.34)
	surface.CanCollide = false
	surface.CanTouch = false
	surface.CanQuery = false
	pointLight(surface, zone.Color, 1.4, 20)
	accentPart(map, "PortalCore_" .. id, Vector3.new(8.3, 10.2, 0.18), base * CFrame.new(0, 11.4, -1.55), zone.Color:Lerp(Color3.new(1,1,1), 0.18), 0.58)

	local req = id == 1 and "OPEN" or ("LV." .. zone.UnlockLevel .. "  •  " .. zone.UnlockCost .. " COINS")
	makeBillboard(surface, string.upper(zone.Name) .. "\n" .. req, Vector3.new(0, 9.6, 0), Color3.fromRGB(245, 246, 252), UDim2.new(0, 230, 0, 58), 48)

	prompt(pad, "Enter Rift", zone.Name).Triggered:Connect(function(player)
		self:TryEnterZone(player, id, pad)
	end)
end

function WorldService:BuildHub()
	local map = self.MapFolder
	local stone = Color3.fromRGB(29, 32, 44)
	local stone2 = Color3.fromRGB(42, 46, 62)
	local marble = Color3.fromRGB(63, 65, 82)
	local rift = Color3.fromRGB(143, 89, 225)

	makePart(map, "NexusFoundation", Vector3.new(212, 3, 212), CFrame.new(0, -2.5, 0), Color3.fromRGB(17, 19, 27), Enum.Material.Slate)
	makePart(map, "CentralHub", Vector3.new(174, 5, 174), CFrame.new(0, 0, 0), stone, Enum.Material.Slate)
	makePart(map, "NexusPlaza", Vector3.new(84, 2, 84), CFrame.new(0, 3.4, 0), stone2, Enum.Material.Marble)
	makePart(map, "NexusInner", Vector3.new(54, 1, 54), CFrame.new(0, 4.9, 0), Color3.fromRGB(36, 37, 50), Enum.Material.Marble)

	for _, data in ipairs({
		{Vector3.new(0, 3.6, -57), Vector3.new(28, 1.2, 50)},
		{Vector3.new(57, 3.6, 0), Vector3.new(50, 1.2, 28)},
		{Vector3.new(0, 3.6, 57), Vector3.new(28, 1.2, 50)},
		{Vector3.new(-57, 3.6, 0), Vector3.new(50, 1.2, 28)},
	}) do
		makePart(map, "NexusCauseway", data[2], CFrame.new(data[1]), marble, Enum.Material.Marble)
	end

	-- Central rift engine: mostly dark architecture with restrained neon accents.
	local coreBase = makePart(map, "HubCore", Vector3.new(28, 5, 28), CFrame.new(0, 7.3, 0), Color3.fromRGB(24, 25, 36), Enum.Material.Marble)
	coreBase.CanCollide = true
	makeBillboard(coreBase, "RIFT NEXUS", Vector3.new(0, 13.5, 0), Color3.fromRGB(224, 214, 255), UDim2.new(0, 280, 0, 52), 56)

	for _, y in ipairs({10.3, 15.2, 20.1}) do
		local ring = accentPart(map, "NexusCoreRing", Vector3.new(18 - (y - 10) * 0.5, 0.7, 18 - (y - 10) * 0.5), CFrame.new(0, y, 0) * CFrame.Angles(0, math.rad(y * 9), math.rad(45)), rift, 0.12)
		ring.Shape = Enum.PartType.Cylinder
		ring.CFrame = CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90))
	end
	local shard = accentPart(map, "NexusCrystal", Vector3.new(5.5, 17, 5.5), CFrame.new(0, 17, 0) * CFrame.Angles(0, math.rad(45), math.rad(45)), Color3.fromRGB(188, 120, 255), 0.04)
	pointLight(shard, shard.Color, 2.1, 28)

	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * 35, 5.55, math.sin(angle) * 35)
		local tile = makePart(map, "NexusRune", Vector3.new(8, 0.22, 2.2), CFrame.new(pos) * CFrame.Angles(0, -angle, 0), rift, Enum.Material.Neon, 0.42)
		tile.CanCollide = false
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(11, 0.6, 11)
	spawn.CFrame = CFrame.new(0, 5.7, 33)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = map

	local portals = {
		{Vector3.new(0, 3.9, -74), 0},
		{Vector3.new(74, 3.9, 0), 90},
		{Vector3.new(0, 3.9, 74), 180},
		{Vector3.new(-74, 3.9, 0), -90},
	}
	for id, zone in ipairs(self.Context.Config.Zones) do
		self:BuildPortal(id, zone, portals[id][1], portals[id][2])
	end
end

function WorldService:BuildZone(zone)
	local map = self.MapFolder
	local center = zone.Center
	local dark = Color3.fromRGB(25, 28, 36)
	local mid = zone.Color:Lerp(dark, 0.68)
	local lightStone = zone.Color:Lerp(Color3.fromRGB(73, 76, 86), 0.70)

	makePart(map, zone.Name .. "_Island", Vector3.new(154, 7, 154), CFrame.new(center + Vector3.new(0, 0, 0)), mid, Enum.Material.Rock)
	makePart(map, zone.Name .. "_Upper", Vector3.new(132, 2, 132), CFrame.new(center + Vector3.new(0, 4.5, 0)), dark:Lerp(zone.Color, 0.10), Enum.Material.Slate)
	makePart(map, zone.Name .. "_Arena", Vector3.new(94, 1, 94), CFrame.new(center + Vector3.new(0, 6, -7)), lightStone, Enum.Material.SmoothPlastic)

	-- Arena border gives enemies and boss a readable combat stage without blocking movement.
	for _, offset in ipairs({
		Vector3.new(0, 6.8, -55), Vector3.new(0, 6.8, 41),
		Vector3.new(-48, 6.8, -7), Vector3.new(48, 6.8, -7),
	}) do
		local size = math.abs(offset.X) > 0 and Vector3.new(1.2, 1.2, 96) or Vector3.new(96, 1.2, 1.2)
		accentPart(map, zone.Name .. "_ArenaTrim", size, CFrame.new(center + offset), zone.Color, 0.34)
	end

	-- Landmark at the far end, readable from the zone entrance.
	local monument = makePart(map, zone.Name .. "_Core", Vector3.new(10, 22, 10), CFrame.new(center + Vector3.new(0, 17, -56)) * CFrame.Angles(0, math.rad(45), math.rad(8)), zone.Color:Lerp(dark, 0.22), Enum.Material.Slate)
	monument.CanCollide = false
	local monumentGlow = accentPart(map, zone.Name .. "_CoreGlow", Vector3.new(3.2, 18, 3.2), CFrame.new(center + Vector3.new(0, 17, -56)) * CFrame.Angles(0, math.rad(45), math.rad(8)), zone.Color, 0.06)
	pointLight(monumentGlow, zone.Color, 1.3, 20)
	makeBillboard(monument, string.upper(zone.Name), Vector3.new(0, 15, 0), Color3.fromRGB(244, 245, 250), UDim2.new(0, 250, 0, 48), 68)

	self.ZoneSpawnPoints[zone.Id] = center + Vector3.new(0, 8, 55)

	local returnPad = makePart(map, zone.Name .. "_Return", Vector3.new(14, 0.8, 10), CFrame.new(center + Vector3.new(0, 6.3, 61)), Color3.fromRGB(55, 55, 70), Enum.Material.Marble)
	accentPart(map, zone.Name .. "_ReturnAccent", Vector3.new(12, 0.16, 8), CFrame.new(center + Vector3.new(0, 6.75, 61)), Color3.fromRGB(150, 120, 225), 0.25)
	makeBillboard(returnPad, "RETURN TO NEXUS", Vector3.new(0, 4, 0), Color3.fromRGB(232, 226, 250), UDim2.new(0, 190, 0, 38), 34)
	prompt(returnPad, "Return", "Rift Nexus", 0.08).Triggered:Connect(function(player)
		if not self:PlayerNear(player, returnPad, 16) then return end
		self:TeleportToHub(player)
		self.Context.Remotes.ZoneEntered:FireClient(player, "Rift Nexus", Color3.fromRGB(154, 102, 235))
	end)

	local egg = self.Context.Config.Eggs[zone.Id]
	local pos = center + Vector3.new(-53, 8, 42)
	local pedestal = makePart(map, "EggPedestal_" .. zone.Id, Vector3.new(13, 4, 13), CFrame.new(pos), dark:Lerp(zone.Color, 0.15), Enum.Material.Marble)
	makePart(map, "EggPedestalStep_" .. zone.Id, Vector3.new(18, 1, 18), CFrame.new(pos - Vector3.new(0, 2.5, 0)), Color3.fromRGB(35, 36, 45), Enum.Material.Slate)
	local orb = makePart(map, "EggOrb_" .. zone.Id, Vector3.new(6.5, 8.5, 6.5), CFrame.new(pos + Vector3.new(0, 7, 0)), zone.Color:Lerp(Color3.new(1, 1, 1), 0.18), Enum.Material.Glass, 0.15)
	orb.Shape = Enum.PartType.Ball
	orb.CanCollide = false
	pointLight(orb, zone.Color, 1.5, 16)
	for i = 1, 3 do
		local a = (i / 3) * math.pi * 2
		accentPart(map, "EggRune_" .. zone.Id, Vector3.new(1.4, 5.5, 1.4), CFrame.new(pos + Vector3.new(math.cos(a) * 6, 4, math.sin(a) * 6)) * CFrame.Angles(0, -a, math.rad(22)), zone.Color, 0.14)
	end
	makeBillboard(orb, string.upper(egg.Name) .. "\n" .. egg.Cost .. " COINS", Vector3.new(0, 6.3, 0), Color3.fromRGB(250, 242, 220), UDim2.new(0, 190, 0, 48), 40)

	local hatch = prompt(pedestal, "Hatch", egg.Name, 0.20)
	hatch.Triggered:Connect(function(player)
		if self:PlayerNear(player, pedestal, 16) then self.Context.Services.PetService:Hatch(player, zone.Id) end
	end)
	self.EggPedestals[zone.Id] = pedestal
end

function WorldService:TryEnterZone(player, zoneId, pad)
	if not self:PlayerNear(player, pad, 17) then return end
	local zone = self.Context.Config.Zones[zoneId]
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	if not zone or not stats or not profile then return end

	local unlocked = profile.ZoneUnlocks:FindFirstChild("Zone" .. zoneId)
	if not unlocked then return end

	if not unlocked.Value then
		if stats.Level.Value < zone.UnlockLevel then
			self.Context:Notify(player, "Requires Level " .. zone.UnlockLevel .. ".", "error")
			return
		end
		if stats.Coins.Value < zone.UnlockCost then
			self.Context:Notify(player, "Requires " .. zone.UnlockCost .. " Coins.", "error")
			return
		end
		stats.Coins.Value -= zone.UnlockCost
		unlocked.Value = true
		self.Context:Notify(player, "RIFT ATTUNED • " .. zone.Name, "success")
	end

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.new(self.ZoneSpawnPoints[zoneId]) * CFrame.Angles(0, math.rad(180), 0)
		self.Context.Remotes.ZoneEntered:FireClient(player, zone.Name, zone.Color)
	end
end

function WorldService:TeleportToHub(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.new(0, 7, 33) * CFrame.Angles(0, math.rad(180), 0)
	end
end

function WorldService:Start()
	self:ConfigureLighting()

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then baseplate:Destroy() end
	local old = Workspace:FindFirstChild("AnimeRiftWorld")
	if old then old:Destroy() end

	self.WorldFolder = Instance.new("Folder")
	self.WorldFolder.Name = "AnimeRiftWorld"
	self.WorldFolder.Parent = Workspace
	self.Context.WorldFolder = self.WorldFolder

	self.MapFolder = Instance.new("Folder")
	self.MapFolder.Name = "Map"
	self.MapFolder.Parent = self.WorldFolder

	for _, name in ipairs({"Enemies", "Followers", "WorldEvents"}) do
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = self.WorldFolder
	end

	local safety = makePart(self.MapFolder, "EmergencySafetyFloor", Vector3.new(230, 4, 230), CFrame.new(0, -5, 0), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, 1)
	safety.CanCollide = true

	self:BuildHub()
	for _, zone in ipairs(self.Context.Config.Zones) do self:BuildZone(zone) end
end

return WorldService
