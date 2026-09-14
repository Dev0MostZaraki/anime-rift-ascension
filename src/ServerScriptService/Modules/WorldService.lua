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

local function makePart(parent, name, size, cf, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = color or Color3.fromRGB(100, 100, 100)
	part.Material = material or Enum.Material.SmoothPlastic
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
	label.TextStrokeTransparency = 0.3
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
	p.HoldDuration = hold or 0.15
	p.MaxActivationDistance = 13
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

function WorldService:PlayerNear(player, part, distance)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and (root.Position - part.Position).Magnitude <= distance
end

function WorldService:ConfigureLighting()
	Lighting.ClockTime = 18.7
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(72, 73, 95)
	Lighting.OutdoorAmbient = Color3.fromRGB(92, 92, 115)

	for _, object in ipairs(Lighting:GetChildren()) do
		if object.Name == "AnimeRiftFX" then object:Destroy() end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "AnimeRiftFX"
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(188, 190, 225)
	atmosphere.Decay = Color3.fromRGB(90, 88, 120)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 1.5
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "AnimeRiftFX"
	bloom.Intensity = 0.5
	bloom.Size = 28
	bloom.Threshold = 1.15
	bloom.Parent = Lighting

	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "AnimeRiftFX"
	correction.Brightness = 0.01
	correction.Contrast = 0.08
	correction.Saturation = 0.06
	correction.Parent = Lighting
end

function WorldService:BuildHub()
	local map = self.MapFolder
	makePart(map, "CentralHub", Vector3.new(145, 4, 145), CFrame.new(0, 0, 0), Color3.fromRGB(44, 48, 66), Enum.Material.Marble)

	local core = makePart(map, "HubCore", Vector3.new(26, 2, 26), CFrame.new(0, 3, 0), Color3.fromRGB(106, 75, 180), Enum.Material.Neon)
	core.CanCollide = false
	makeBillboard(core, "ANIME RIFT\nASCENSION", Vector3.new(0, 8, 0), Color3.fromRGB(235, 220, 255), UDim2.new(0, 300, 0, 85), 70)

	for _, x in ipairs({-58, 58}) do
		for _, z in ipairs({-58, 58}) do
			makePart(map, "HubTower", Vector3.new(6, 30, 6), CFrame.new(x, 17, z), Color3.fromRGB(78, 72, 108), Enum.Material.Marble)
			local cap = makePart(map, "TowerCap", Vector3.new(9, 2, 9), CFrame.new(x, 33, z), Color3.fromRGB(154, 102, 235), Enum.Material.Neon)
			cap.CanCollide = false
		end
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 4, 24)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Color = Color3.fromRGB(120, 88, 225)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = map

	local portalPositions = {
		Vector3.new(-54, 4, -44),
		Vector3.new(-18, 4, -44),
		Vector3.new(18, 4, -44),
		Vector3.new(54, 4, -44),
	}

	for id, zone in ipairs(self.Context.Config.Zones) do
		local position = portalPositions[id]
		local pad = makePart(map, "Portal_" .. id, Vector3.new(12, 1, 12), CFrame.new(position), zone.Color, Enum.Material.Neon)
		local left = makePart(map, "PortalPillar", Vector3.new(2.5, 15, 2.5), CFrame.new(position + Vector3.new(-6, 7, 0)), zone.Color, Enum.Material.Neon)
		local right = makePart(map, "PortalPillar", Vector3.new(2.5, 15, 2.5), CFrame.new(position + Vector3.new(6, 7, 0)), zone.Color, Enum.Material.Neon)
		local top = makePart(map, "PortalTop", Vector3.new(14, 2.5, 2.5), CFrame.new(position + Vector3.new(0, 14, 0)), zone.Color, Enum.Material.Neon)
		left.CanCollide, right.CanCollide, top.CanCollide = false, false, false

		local req = id == 1 and "FREE" or ("Lv." .. zone.UnlockLevel .. " • " .. zone.UnlockCost .. " Coins")
		makeBillboard(pad, zone.Name .. "\n" .. req, Vector3.new(0, 7, 0), Color3.fromRGB(245, 245, 250), UDim2.new(0, 190, 0, 60), 32)

		prompt(pad, "Enter", zone.Name).Triggered:Connect(function(player)
			self:TryEnterZone(player, id, pad)
		end)
	end
end

function WorldService:BuildZone(zone)
	local map = self.MapFolder
	local center = zone.Center
	makePart(map, zone.Name .. "_Island", Vector3.new(118, 4, 118), CFrame.new(center), zone.Color:Lerp(Color3.fromRGB(40, 42, 50), 0.24), Enum.Material.Slate)
	makePart(map, zone.Name .. "_Arena", Vector3.new(82, 1, 82), CFrame.new(center + Vector3.new(0, 2.5, 0)), zone.Color:Lerp(Color3.new(1, 1, 1), 0.12), Enum.Material.SmoothPlastic)

	local crystal = makePart(map, zone.Name .. "_Core", Vector3.new(8, 20, 8), CFrame.new(center + Vector3.new(0, 13, 0)) * CFrame.Angles(0, 0, math.rad(45)), zone.Color, Enum.Material.Neon)
	crystal.CanCollide = false
	makeBillboard(crystal, zone.Name, Vector3.new(0, 13, 0), Color3.fromRGB(245, 245, 250), UDim2.new(0, 230, 0, 54), 72)

	for _, offset in ipairs({Vector3.new(-48, 8, -48), Vector3.new(48, 8, -48), Vector3.new(-48, 8, 48), Vector3.new(48, 8, 48)}) do
		makePart(map, zone.Name .. "_Column", Vector3.new(5, 20, 5), CFrame.new(center + offset), zone.Color:Lerp(Color3.fromRGB(30, 30, 40), 0.38), Enum.Material.Rock)
		local glow = makePart(map, zone.Name .. "_Glow", Vector3.new(7, 1, 7), CFrame.new(center + offset + Vector3.new(0, 10.5, 0)), zone.Color, Enum.Material.Neon)
		glow.CanCollide = false
	end

	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		local pos = center + Vector3.new(math.cos(angle) * 43, 5, math.sin(angle) * 43)
		local shard = makePart(map, zone.Name .. "_Shard", Vector3.new(3, math.random(8, 16), 3), CFrame.new(pos) * CFrame.Angles(math.rad(math.random(-12, 12)), 0, math.rad(math.random(-18, 18))), zone.Color, Enum.Material.Neon)
		shard.CanCollide = false
	end

	self.ZoneSpawnPoints[zone.Id] = center + Vector3.new(0, 5, 42)

	local returnPad = makePart(map, zone.Name .. "_Return", Vector3.new(13, 1, 13), CFrame.new(center + Vector3.new(0, 3, 50)), Color3.fromRGB(150, 120, 225), Enum.Material.Neon)
	makeBillboard(returnPad, "RETURN TO HUB", Vector3.new(0, 4, 0), Color3.fromRGB(240, 230, 255), UDim2.new(0, 180, 0, 44), 36)
	prompt(returnPad, "Return", "Central Hub", 0.1).Triggered:Connect(function(player)
		if not self:PlayerNear(player, returnPad, 16) then return end
		self:TeleportToHub(player)
		self.Context.Remotes.ZoneEntered:FireClient(player, "Central Hub", Color3.fromRGB(154, 102, 235))
	end)

	local egg = self.Context.Config.Eggs[zone.Id]
	local pos = center + Vector3.new(-36, 5, 36)
	local pedestal = makePart(map, "EggPedestal_" .. zone.Id, Vector3.new(11, 7, 11), CFrame.new(pos), zone.Color:Lerp(Color3.fromRGB(30, 30, 40), 0.25), Enum.Material.Marble)
	local orb = makePart(map, "EggOrb_" .. zone.Id, Vector3.new(7, 9, 7), CFrame.new(pos + Vector3.new(0, 7, 0)), zone.Color:Lerp(Color3.new(1, 1, 1), 0.25), Enum.Material.Neon)
	orb.Shape = Enum.PartType.Ball
	orb.CanCollide = false
	makeBillboard(orb, egg.Name .. "\n" .. egg.Cost .. " Coins", Vector3.new(0, 6, 0), Color3.fromRGB(255, 245, 220), UDim2.new(0, 190, 0, 56), 42)

	local hatch = prompt(pedestal, "Hatch 1", egg.Name, 0.25)
	hatch.Triggered:Connect(function(player)
		if self:PlayerNear(player, pedestal, 16) then self.Context.Services.PetService:Hatch(player, zone.Id) end
	end)
	self.EggPedestals[zone.Id] = pedestal
end

function WorldService:TryEnterZone(player, zoneId, pad)
	if not self:PlayerNear(player, pad, 16) then return end
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
		self.Context:Notify(player, "ZONE UNLOCKED: " .. zone.Name, "success")
	end

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(self.ZoneSpawnPoints[zoneId])
		self.Context.Remotes.ZoneEntered:FireClient(player, zone.Name, zone.Color)
	end
end

function WorldService:TeleportToHub(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.new(0, 9, 24)
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

	local safety = makePart(self.MapFolder, "EmergencySafetyFloor", Vector3.new(240, 4, 240), CFrame.new(0, -4, 0), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic)
	safety.Transparency = 1

	self:BuildHub()
	for _, zone in ipairs(self.Context.Config.Zones) do self:BuildZone(zone) end
end

return WorldService
