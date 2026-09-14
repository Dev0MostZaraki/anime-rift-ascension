local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local WorldService = {}
WorldService.__index = WorldService

function WorldService.new(context)
	return setmetatable({
		Context = context,
		ZoneSpawnPoints = {},
		EggPedestals = {},
		WorldFolder = nil,
		MapFolder = nil,
	}, WorldService)
end

local function makePart(parent, name, size, cf, color, material, transparency, collide)
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
	part.CanCollide = collide ~= false
	part.Parent = parent
	return part
end

local function makeBillboard(parent, text, offset, color, size, maxDistance)
	local gui = Instance.new("BillboardGui")
	gui.Size = size or UDim2.new(0, 220, 0, 54)
	gui.StudsOffset = offset or Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = maxDistance or 70
	gui.LightInfluence = 0
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.6
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
	p.MaxActivationDistance = 13
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = Enum.KeyCode.F
	p.Parent = parent
	return p
end

local function pointLight(parent, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness or 0.65
	light.Range = range or 12
	light.Shadows = true
	light.Parent = parent
	return light
end

local function flatUnit(vector)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude < 0.01 then return Vector3.new(0, 0, 1) end
	return flat.Unit
end

function WorldService:PlayerNear(player, part, distance)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and (root.Position - part.Position).Magnitude <= distance
end

function WorldService:ConfigureLighting()
	Lighting.ClockTime = 15.35
	Lighting.Brightness = 2.35
	Lighting.ExposureCompensation = 0.03
	Lighting.Ambient = Color3.fromRGB(116, 113, 106)
	Lighting.OutdoorAmbient = Color3.fromRGB(145, 143, 136)
	Lighting.EnvironmentDiffuseScale = 0.72
	Lighting.EnvironmentSpecularScale = 0.48
	Lighting.GlobalShadows = true

	for _, object in ipairs(Lighting:GetChildren()) do
		if object.Name == "AnimeRiftFX" then object:Destroy() end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "AnimeRiftFX"
	atmosphere.Density = 0.18
	atmosphere.Offset = 0.12
	atmosphere.Color = Color3.fromRGB(208, 216, 219)
	atmosphere.Decay = Color3.fromRGB(111, 120, 126)
	atmosphere.Glare = 0.03
	atmosphere.Haze = 0.75
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "AnimeRiftFX"
	bloom.Intensity = 0.08
	bloom.Size = 18
	bloom.Threshold = 1.9
	bloom.Parent = Lighting

	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "AnimeRiftFX"
	correction.Brightness = 0.01
	correction.Contrast = 0.035
	correction.Saturation = -0.04
	correction.TintColor = Color3.fromRGB(255, 250, 239)
	correction.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Name = "AnimeRiftFX"
	rays.Intensity = 0.025
	rays.Spread = 0.82
	rays.Parent = Lighting
end

function WorldService:BuildTerrain()
	local terrain = Workspace.Terrain
	terrain:Clear()

	-- One continuous landmass. Biomes are material regions rather than floating islands.
	terrain:FillBlock(CFrame.new(0, -25, 0), Vector3.new(760, 44, 760), Enum.Material.Rock)
	terrain:FillBlock(CFrame.new(0, -3, 0), Vector3.new(720, 10, 720), Enum.Material.Grass)

	local ember = self.Context.Config.Zones[2].Center
	local frost = self.Context.Config.Zones[3].Center
	local void = self.Context.Config.Zones[4].Center
	terrain:FillBlock(CFrame.new(ember.X, -2.8, ember.Z), Vector3.new(185, 9, 175), Enum.Material.Ground)
	terrain:FillBlock(CFrame.new(frost.X, -2.8, frost.Z), Vector3.new(190, 9, 180), Enum.Material.Snow)
	terrain:FillBlock(CFrame.new(void.X, -2.8, void.Z), Vector3.new(180, 9, 180), Enum.Material.Basalt)

	-- Rolling perimeter and transition hills hide the square world edge and break sight lines.
	local hills = {
		Vector3.new(-315, -4, 210), Vector3.new(-300, -4, -220), Vector3.new(305, -4, 225), Vector3.new(310, -4, -205),
		Vector3.new(-235, -5, 320), Vector3.new(235, -5, 320), Vector3.new(-230, -5, -315), Vector3.new(230, -5, -315),
		Vector3.new(135, -4, 150), Vector3.new(-120, -5, -155), Vector3.new(155, -5, -90), Vector3.new(-155, -5, 105),
	}
	for i, pos in ipairs(hills) do
		local radius = 28 + (i % 4) * 8
		terrain:FillBall(pos, radius, i % 3 == 0 and Enum.Material.Rock or Enum.Material.Grass)
	end

	-- A real water feature beside the Verdant route.
	terrain:FillBlock(CFrame.new(48, 0, 112), Vector3.new(19, 9, 118), Enum.Material.Air)
	terrain:FillBlock(CFrame.new(48, -1.2, 112), Vector3.new(17, 4.2, 116), Enum.Material.Water)
end

function WorldService:BuildRoad(from, to, width, name)
	local delta = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local length = delta.Magnitude
	if length < 2 then return end
	local direction = delta.Unit
	local segmentLength = 12
	local count = math.ceil(length / segmentLength)
	for i = 1, count do
		local startDistance = (i - 1) * segmentLength
		local currentLength = math.min(segmentLength + 0.6, length - startDistance)
		local centerDistance = startDistance + currentLength / 2
		local center = from + direction * centerDistance
		local flatCenter = Vector3.new(center.X, 2.18, center.Z)
		local road = makePart(self.MapFolder, name or "Road", Vector3.new(width or 10, 0.28, currentLength), CFrame.lookAt(flatCenter, flatCenter + direction), Color3.fromRGB(116, 108, 91), Enum.Material.Cobblestone, 0, true)
		road.CastShadow = false
	end
end

function WorldService:BuildWaystone(id, zone, position)
	local stone = makePart(self.MapFolder, "Waystone_" .. id, Vector3.new(6, 8, 4), CFrame.new(position + Vector3.new(0, 6, 0)) * CFrame.Angles(0, math.rad(id * 17), math.rad(2)), Color3.fromRGB(77, 78, 72), Enum.Material.Slate)
	local rune = makePart(self.MapFolder, "WaystoneRune_" .. id, Vector3.new(1.6, 3.4, 0.18), stone.CFrame * CFrame.new(0, 0.4, -2.05), zone.Color:Lerp(Color3.new(1,1,1), 0.18), Enum.Material.Neon, 0.18, false)
	pointLight(rune, zone.Color, 0.42, 8)
	local req = id == 1 and "DISCOVERED" or ("LV." .. zone.UnlockLevel .. " • " .. zone.UnlockCost .. " COINS")
	makeBillboard(stone, string.upper(zone.Name) .. "\n" .. req, Vector3.new(0, 6.2, 0), Color3.fromRGB(244, 240, 226), UDim2.new(0, 190, 0, 52), 42)
	prompt(stone, "Attune / Travel", zone.Name).Triggered:Connect(function(player)
		self:TryEnterZone(player, id, stone)
	end)
end

function WorldService:BuildHaven()
	local map = self.MapFolder
	local plaza = makePart(map, "RiftHavenPlaza", Vector3.new(78, 1.2, 70), CFrame.new(0, 2.5, 0), Color3.fromRGB(126, 120, 105), Enum.Material.Cobblestone)
	plaza.CastShadow = false

	local well = makePart(map, "HavenWell", Vector3.new(15, 3, 15), CFrame.new(0, 4.4, -4), Color3.fromRGB(88, 86, 79), Enum.Material.Slate)
	well.Shape = Enum.PartType.Cylinder
	well.CFrame = CFrame.new(0, 4.4, -4) * CFrame.Angles(0, 0, math.rad(90))
	local crystal = makePart(map, "HavenRiftStone", Vector3.new(2.5, 7, 2.5), CFrame.new(0, 9, -4) * CFrame.Angles(0, 0, math.rad(18)), Color3.fromRGB(128, 101, 148), Enum.Material.Glass, 0.18, false)
	pointLight(crystal, Color3.fromRGB(147, 117, 168), 0.55, 12)
	makeBillboard(crystal, "RIFT HAVEN", Vector3.new(0, 6.5, 0), Color3.fromRGB(248, 242, 225), UDim2.new(0, 240, 0, 52), 55)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(10, 0.5, 10)
	spawn.CFrame = CFrame.new(0, 3.6, 22)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = map

	local waystones = {
		Vector3.new(-27, 2, -22),
		Vector3.new(27, 2, -22),
		Vector3.new(27, 2, 22),
		Vector3.new(-27, 2, 22),
	}
	for id, zone in ipairs(self.Context.Config.Zones) do
		self:BuildWaystone(id, zone, waystones[id])
	end
end

function WorldService:BuildZone(zone)
	local map = self.MapFolder
	local center = zone.Center
	local towardHub = flatUnit(-center)
	local right = Vector3.new(-towardHub.Z, 0, towardHub.X)
	local arrival = center + towardHub * 52
	self.ZoneSpawnPoints[zone.Id] = Vector3.new(arrival.X, 5, arrival.Z)

	-- A small grounded camp marks each region without turning it into an arena island.
	makePart(map, zone.Name .. "_Camp", Vector3.new(34, 0.7, 24), CFrame.new(arrival + Vector3.new(0, 2.15, 0)), Color3.fromRGB(112, 105, 91), Enum.Material.Cobblestone)
	local marker = makePart(map, zone.Name .. "_Marker", Vector3.new(4, 9, 4), CFrame.new(arrival + right * 11 + Vector3.new(0, 6.3, 0)), Color3.fromRGB(78, 76, 70), Enum.Material.Slate)
	makeBillboard(marker, string.upper(zone.Name), Vector3.new(0, 6.5, 0), Color3.fromRGB(248, 243, 228), UDim2.new(0, 220, 0, 46), 55)

	local returnStone = makePart(map, zone.Name .. "_Return", Vector3.new(4.5, 6.5, 3.5), CFrame.new(arrival - right * 11 + Vector3.new(0, 5, 0)), Color3.fromRGB(77, 77, 72), Enum.Material.Slate)
	prompt(returnStone, "Fast Travel", "Rift Haven", 0.1).Triggered:Connect(function(player)
		if not self:PlayerNear(player, returnStone, 15) then return end
		self:TeleportToHub(player)
		self.Context.Remotes.ZoneEntered:FireClient(player, "Rift Haven", Color3.fromRGB(139, 125, 104))
	end)

	local egg = self.Context.Config.Eggs[zone.Id]
	local eggPos = center + right * 38 + towardHub * 25
	local pedestal = makePart(map, "EggPedestal_" .. zone.Id, Vector3.new(9, 2.5, 9), CFrame.new(eggPos + Vector3.new(0, 3.25, 0)), Color3.fromRGB(96, 91, 81), Enum.Material.Stone)
	local orb = makePart(map, "EggOrb_" .. zone.Id, Vector3.new(5.4, 6.8, 5.4), CFrame.new(eggPos + Vector3.new(0, 7.4, 0)), zone.Color:Lerp(Color3.new(1,1,1), 0.18), Enum.Material.Glass, 0.12, false)
	orb.Shape = Enum.PartType.Ball
	pointLight(orb, zone.Color, 0.58, 10)
	makeBillboard(orb, egg.Name .. "\n" .. egg.Cost .. " Coins", Vector3.new(0, 5.4, 0), Color3.fromRGB(250, 244, 224), UDim2.new(0, 170, 0, 48), 36)
	prompt(pedestal, "Hatch", egg.Name, 0.22).Triggered:Connect(function(player)
		if self:PlayerNear(player, pedestal, 15) then self.Context.Services.PetService:Hatch(player, zone.Id) end
	end)
	self.EggPedestals[zone.Id] = pedestal
end

function WorldService:TryEnterZone(player, zoneId, stone)
	if not self:PlayerNear(player, stone, 16) then return end
	local zone = self.Context.Config.Zones[zoneId]
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	if not zone or not stats or not profile then return end
	local unlocked = profile.ZoneUnlocks:FindFirstChild("Zone" .. zoneId)
	if not unlocked then return end

	if not unlocked.Value then
		if stats.Level.Value < zone.UnlockLevel then
			self.Context:Notify(player, "Attunement requires Level " .. zone.UnlockLevel .. ". You can still reach the region on foot.", "error")
			return
		end
		if stats.Coins.Value < zone.UnlockCost then
			self.Context:Notify(player, "Attunement requires " .. zone.UnlockCost .. " Coins.", "error")
			return
		end
		stats.Coins.Value -= zone.UnlockCost
		unlocked.Value = true
		self.Context:Notify(player, "WAYSTONE ATTUNED • " .. zone.Name, "success")
	end

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.new(self.ZoneSpawnPoints[zoneId])
		self.Context.Remotes.ZoneEntered:FireClient(player, zone.Name, zone.Color)
	end
end

function WorldService:TeleportToHub(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.new(0, 6, 22)
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

	self:BuildTerrain()
	self:BuildHaven()

	for _, zone in ipairs(self.Context.Config.Zones) do
		local towardHub = flatUnit(-zone.Center)
		local arrival = zone.Center + towardHub * 52
		self:BuildRoad(Vector3.new(0, 0, 0), arrival, zone.Id == 1 and 11 or 9, "WorldRoad_" .. zone.Id)
		self:BuildZone(zone)
	end
end

return WorldService
