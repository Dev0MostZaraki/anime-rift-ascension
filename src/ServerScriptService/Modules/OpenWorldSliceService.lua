local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local OpenWorldSliceService = {}
OpenWorldSliceService.__index = OpenWorldSliceService

function OpenWorldSliceService.new(context)
	return setmetatable({
		Context = context,
		Claims = {},
		RegionClock = 0,
	}, OpenWorldSliceService)
end

local function part(parent, name, size, cf, color, material, transparency, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = collide ~= false
	p.CanTouch = false
	p.CanQuery = collide ~= false
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function ball(parent, name, size, position, color, material, collide)
	local p = part(parent, name, Vector3.new(size, size, size), CFrame.new(position), color, material, 0, collide)
	p.Shape = Enum.PartType.Ball
	return p
end

local function prompt(parent, actionText, objectText, hold)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = actionText
	p.ObjectText = objectText
	p.HoldDuration = hold or 0.2
	p.MaxActivationDistance = 11
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = Enum.KeyCode.F
	p.Parent = parent
	return p
end

local function label(parent, text, offset, maxDistance)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 210, 0, 48)
	gui.StudsOffset = offset or Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = maxDistance or 42
	gui.LightInfluence = 0
	gui.Parent = parent
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = Color3.fromRGB(243, 238, 221)
	l.TextStrokeTransparency = 0.72
	l.TextScaled = true
	l.Font = Enum.Font.GothamBold
	l.Parent = gui
	return gui
end

local function lantern(parent, pos)
	local wood = Color3.fromRGB(77, 61, 43)
	part(parent, "TrailLanternPost", Vector3.new(0.45, 4.8, 0.45), CFrame.new(pos + Vector3.new(0, 2.4, 0)), wood, Enum.Material.Wood)
	local lamp = part(parent, "TrailLantern", Vector3.new(1.1, 1.25, 1.1), CFrame.new(pos + Vector3.new(0, 4.75, 0)), Color3.fromRGB(232, 190, 112), Enum.Material.Glass, 0.25, false)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 207, 133)
	light.Brightness = 0.45
	light.Range = 9
	light.Shadows = true
	light.Parent = lamp
end

local function tree(parent, pos, scale, leaf)
	local trunk = part(parent, "WildTreeTrunk", Vector3.new(1.7 * scale, 8.5 * scale, 1.7 * scale), CFrame.new(pos + Vector3.new(0, 4.25 * scale, 0)), Color3.fromRGB(83, 64, 45), Enum.Material.Wood)
	trunk.CFrame *= CFrame.Angles(0, math.rad((math.floor(pos.X + pos.Z) % 9) * 7), math.rad(2))
	ball(parent, "WildTreeCrown", 6.2 * scale, pos + Vector3.new(0, 9.2 * scale, 0), leaf, Enum.Material.Grass, false)
	ball(parent, "WildTreeCrown", 4.4 * scale, pos + Vector3.new(2.3 * scale, 8.4 * scale, 0.6 * scale), leaf:Lerp(Color3.fromRGB(109, 132, 84), 0.18), Enum.Material.Grass, false)
	ball(parent, "WildTreeCrown", 4.1 * scale, pos + Vector3.new(-2.1 * scale, 8.5 * scale, -0.7 * scale), leaf:Lerp(Color3.fromRGB(46, 82, 50), 0.12), Enum.Material.Grass, false)
end

local function rock(parent, pos, size, color)
	return part(parent, "WorldRock", size, CFrame.new(pos) * CFrame.Angles(math.rad(9), math.rad((pos.X * 3 + pos.Z) % 60), math.rad(7)), color or Color3.fromRGB(99, 99, 88), Enum.Material.Rock)
end

local function beam(parent, name, a, b, thickness, color, material)
	local delta = b - a
	local length = delta.Magnitude
	local mid = a:Lerp(b, 0.5)
	return part(parent, name, Vector3.new(thickness, thickness, length), CFrame.lookAt(mid, b), color, material or Enum.Material.Wood)
end

local function sign(parent, pos, text, yaw)
	local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	part(parent, "SignPost", Vector3.new(0.5, 4.7, 0.5), cf * CFrame.new(0, 2.35, 0), Color3.fromRGB(83, 63, 44), Enum.Material.Wood)
	local board = part(parent, "SignBoard", Vector3.new(7, 2.4, 0.5), cf * CFrame.new(0, 4.3, 0), Color3.fromRGB(112, 86, 57), Enum.Material.WoodPlanks)
	label(board, text, Vector3.new(0, 0, 0), 32)
	return board
end

local function roof(parent, center, width, depth, y, color)
	local left = Instance.new("WedgePart")
	left.Name = "Roof"
	left.Size = Vector3.new(width + 3, 3.4, depth / 2 + 1.5)
	left.CFrame = CFrame.new(center + Vector3.new(0, y, -depth / 4)) * CFrame.Angles(0, math.rad(180), 0)
	left.Anchored = true
	left.CanCollide = false
	left.Color = color
	left.Material = Enum.Material.Slate
	left.Parent = parent
	local right = left:Clone()
	right.CFrame = CFrame.new(center + Vector3.new(0, y, depth / 4))
	right.Parent = parent
end

local function building(parent, name, center, width, depth, wall, roofColor, openFront)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	part(folder, "Floor", Vector3.new(width, 0.8, depth), CFrame.new(center + Vector3.new(0, 0.4, 0)), Color3.fromRGB(111, 98, 76), Enum.Material.WoodPlanks)
	part(folder, "Back", Vector3.new(width, 8.5, 1), CFrame.new(center + Vector3.new(0, 4.7, -depth / 2)), wall, Enum.Material.WoodPlanks)
	part(folder, "Left", Vector3.new(1, 8.5, depth), CFrame.new(center + Vector3.new(-width / 2, 4.7, 0)), wall, Enum.Material.WoodPlanks)
	part(folder, "Right", Vector3.new(1, 8.5, depth), CFrame.new(center + Vector3.new(width / 2, 4.7, 0)), wall, Enum.Material.WoodPlanks)
	if not openFront then
		part(folder, "FrontL", Vector3.new(width * 0.36, 8.5, 1), CFrame.new(center + Vector3.new(-width * 0.31, 4.7, depth / 2)), wall, Enum.Material.WoodPlanks)
		part(folder, "FrontR", Vector3.new(width * 0.36, 8.5, 1), CFrame.new(center + Vector3.new(width * 0.31, 4.7, depth / 2)), wall, Enum.Material.WoodPlanks)
	end
	for _, x in ipairs({-width / 2 + 0.8, width / 2 - 0.8}) do
		for _, z in ipairs({-depth / 2 + 0.8, depth / 2 - 0.8}) do
			part(folder, "Post", Vector3.new(0.9, 10, 0.9), CFrame.new(center + Vector3.new(x, 5.2, z)), Color3.fromRGB(75, 55, 39), Enum.Material.Wood)
		end
	end
	roof(folder, center, width, depth, 10.4, roofColor)
	return folder
end

function OpenWorldSliceService:SculptTerrain()
	local terrain = Workspace.Terrain
	local c = self.Context.Config.Zones[1].Center
	local hills = {
		{Vector3.new(-92, -11, 132), 27}, {Vector3.new(90, -12, 142), 30},
		{Vector3.new(-86, -12, 215), 31}, {Vector3.new(84, -11, 225), 29},
		{Vector3.new(-50, -13, 270), 32}, {Vector3.new(45, -12, 282), 35},
		{Vector3.new(-118, -13, 180), 24}, {Vector3.new(116, -13, 193), 25},
	}
	for i, data in ipairs(hills) do
		terrain:FillBall(data[1], data[2], i % 4 == 0 and Enum.Material.Rock or Enum.Material.Grass)
	end

	-- Widen the watercourse that visually leads from Haven into Verdant.
	terrain:FillBlock(CFrame.new(48, 0.3, 155), Vector3.new(21, 8, 72), Enum.Material.Air)
	terrain:FillBlock(CFrame.new(48, -1.6, 155), Vector3.new(18, 4, 72), Enum.Material.Water)

	local clouds = terrain:FindFirstChild("AnimeRiftClouds")
	if not clouds then
		clouds = Instance.new("Clouds")
		clouds.Name = "AnimeRiftClouds"
		clouds.Parent = terrain
	end
	clouds.Cover = 0.32
	clouds.Density = 0.42
	clouds.Color = Color3.fromRGB(240, 239, 233)
end

function OpenWorldSliceService:BuildHaven(folder)
	local wall = Color3.fromRGB(188, 177, 150)
	local darkRoof = Color3.fromRGB(72, 70, 63)
	local greenRoof = Color3.fromRGB(61, 78, 62)

	-- A stronger village silhouette: guild hall, forge and companion stable.
	local guild = building(folder, "HavenGuildHall", Vector3.new(0, 2.9, -67), 42, 24, wall, darkRoof, false)
	local guildBoard = part(guild, "GuildBoard", Vector3.new(16, 4.2, 0.5), CFrame.new(0, 8, -54.7), Color3.fromRGB(93, 69, 47), Enum.Material.WoodPlanks)
	label(guildBoard, "RIFT HAVEN GUILD", Vector3.new(0, 0, 0), 44)

	local forge = building(folder, "HavenForge", Vector3.new(82, 2.7, 14), 24, 19, Color3.fromRGB(163, 146, 122), darkRoof, true)
	local chimney = part(forge, "Chimney", Vector3.new(4.2, 13, 4.2), CFrame.new(90, 10.3, 8), Color3.fromRGB(87, 77, 68), Enum.Material.Brick)
	local fireCore = part(forge, "ForgeFire", Vector3.new(3.2, 1.2, 3.2), CFrame.new(78, 4.0, 22), Color3.fromRGB(191, 100, 55), Enum.Material.Neon, 0.28, false)
	local fireLight = Instance.new("PointLight")
	fireLight.Color = Color3.fromRGB(236, 142, 79)
	fireLight.Brightness = 0.65
	fireLight.Range = 10
	fireLight.Parent = fireCore
	chimney.CastShadow = true
	label(forge:FindFirstChild("Floor"), "ARSENAL FORGE", Vector3.new(0, 5.8, 0), 34)

	local stable = building(folder, "CompanionStable", Vector3.new(-82, 2.7, 18), 28, 20, Color3.fromRGB(172, 161, 133), greenRoof, true)
	label(stable:FindFirstChild("Floor"), "COMPANION LODGE", Vector3.new(0, 5.8, 0), 34)

	-- A physical gateway toward the first region makes the road feel like a journey.
	local gateZ = 84
	for _, x in ipairs({-12, 12}) do
		part(folder, "VerdantGatePost", Vector3.new(2.2, 13, 2.2), CFrame.new(x, 8.5, gateZ), Color3.fromRGB(86, 62, 42), Enum.Material.Wood)
	end
	part(folder, "VerdantGateBeam", Vector3.new(29, 2, 2.8), CFrame.new(0, 14.5, gateZ), Color3.fromRGB(98, 69, 45), Enum.Material.Wood)
	sign(folder, Vector3.new(0, 2.1, gateZ + 1.6), "VERDANT ROAD", 0)

	for _, pos in ipairs({
		Vector3.new(-22, 2.2, 71), Vector3.new(22, 2.2, 71),
		Vector3.new(-20, 2.2, 102), Vector3.new(20, 2.2, 102),
	}) do lantern(folder, pos) end
end

function OpenWorldSliceService:BuildVerdantBridge(folder)
	local center = Vector3.new(48, 2.6, 151)
	part(folder, "RiverBridgeDeck", Vector3.new(30, 1.1, 8), CFrame.new(center), Color3.fromRGB(105, 78, 52), Enum.Material.WoodPlanks)
	for _, z in ipairs({-3.3, 3.3}) do
		for _, x in ipairs({-13, -7, 0, 7, 13}) do
			part(folder, "BridgePost", Vector3.new(0.45, 3.3, 0.45), CFrame.new(center + Vector3.new(x, 2, z)), Color3.fromRGB(78, 59, 42), Enum.Material.Wood)
		end
		beam(folder, "BridgeRail", center + Vector3.new(-13, 3.2, z), center + Vector3.new(13, 3.2, z), 0.4, Color3.fromRGB(82, 61, 43), Enum.Material.Wood)
	end
	for _, offset in ipairs({Vector3.new(-19,0,-9), Vector3.new(18,0,9), Vector3.new(-18,0,10), Vector3.new(19,0,-10)}) do
		rock(folder, center + offset + Vector3.new(0, -0.2, 0), Vector3.new(7, 4, 6), Color3.fromRGB(103, 106, 94))
	end
end

function OpenWorldSliceService:BuildVerdantLandmarks(folder)
	local c = self.Context.Config.Zones[1].Center
	local leaf = Color3.fromRGB(64, 105, 63)

	-- Layer the main approach so the player stops seeing the whole region at once.
	local random = Random.new(4101)
	for i = 1, 44 do
		local x = random:NextNumber(-102, 102)
		local z = random:NextNumber(105, 292)
		if math.abs(x) < 16 and z < 218 then continue end
		if x > 34 and x < 63 and z > 118 and z < 190 then continue end
		tree(folder, Vector3.new(x, 2.1, z), random:NextNumber(0.72, 1.12), leaf:Lerp(Color3.fromRGB(94, 122, 70), random:NextNumber(0, 0.22)))
	end

	self:BuildVerdantBridge(folder)

	-- Bandit camp / combat POI on the western trail.
	local camp = c + Vector3.new(-48, 2.3, 9)
	part(folder, "BanditCampGround", Vector3.new(32, 0.35, 25), CFrame.new(camp), Color3.fromRGB(103, 94, 73), Enum.Material.Ground)
	for _, x in ipairs({-11, 11}) do
		part(folder, "CampTentPole", Vector3.new(0.6, 6, 0.6), CFrame.new(camp + Vector3.new(x, 3.2, -5)), Color3.fromRGB(74, 55, 39), Enum.Material.Wood)
		local canvas = part(folder, "CampTent", Vector3.new(10, 0.7, 12), CFrame.new(camp + Vector3.new(x, 5.5, -5)) * CFrame.Angles(0, 0, math.rad(x > 0 and -12 or 12)), Color3.fromRGB(125, 105, 75), Enum.Material.Fabric, 0, false)
		canvas.CanCollide = false
	end
	local campfire = part(folder, "Campfire", Vector3.new(2.2, 0.7, 2.2), CFrame.new(camp + Vector3.new(0, 0.7, 5)), Color3.fromRGB(161, 89, 51), Enum.Material.Neon, 0.38, false)
	local fire = Instance.new("Fire")
	fire.Color = Color3.fromRGB(236, 155, 81)
	fire.SecondaryColor = Color3.fromRGB(160, 68, 38)
	fire.Size = 3.2
	fire.Heat = 3
	fire.Parent = campfire

	-- Quiet shrine and a small stepped approach on the opposite side.
	local shrine = c + Vector3.new(-57, 2.5, 53)
	for step = 1, 5 do
		part(folder, "ShrineStep", Vector3.new(14, 0.7, 4), CFrame.new(shrine + Vector3.new(0, step * 0.55, 14 - step * 4)), Color3.fromRGB(112, 111, 95), Enum.Material.Slate)
	end
	part(folder, "ShrineBase", Vector3.new(23, 1, 18), CFrame.new(shrine + Vector3.new(0, 3.4, -8)), Color3.fromRGB(111, 105, 88), Enum.Material.Slate)
	for _, x in ipairs({-8, 8}) do
		part(folder, "ShrinePost", Vector3.new(1.4, 9, 1.4), CFrame.new(shrine + Vector3.new(x, 8.2, -8)), Color3.fromRGB(101, 55, 42), Enum.Material.Wood)
	end
	part(folder, "ShrineBeam", Vector3.new(21, 1.5, 2.1), CFrame.new(shrine + Vector3.new(0, 12.4, -8)), Color3.fromRGB(119, 60, 43), Enum.Material.Wood)

	-- Cave mouth and cliff stones at the deep edge; this is a future dungeon hook.
	local cave = c + Vector3.new(69, 3, 58)
	for i = -3, 3 do
		local angle = (i / 6) * math.pi
		local p = cave + Vector3.new(math.cos(angle) * 11, 7 + math.sin(angle) * 7, 0)
		rock(folder, p, Vector3.new(7, 8, 9), Color3.fromRGB(88, 92, 83))
	end
	local caveDark = part(folder, "CaveMouth", Vector3.new(15, 12, 0.6), CFrame.new(cave + Vector3.new(0, 6, 1.3)), Color3.fromRGB(24, 28, 25), Enum.Material.SmoothPlastic, 0, false)
	label(caveDark, "SEALED GROTTO", Vector3.new(0, 8, 0), 28)

	-- Trail lights are warm and sparse, deliberately not neon.
	for _, pos in ipairs({
		Vector3.new(-13,2.2,118), Vector3.new(13,2.2,125), Vector3.new(-12,2.2,153), Vector3.new(10,2.2,176),
		Vector3.new(-15,2.2,211), Vector3.new(13,2.2,237),
	}) do lantern(folder, pos) end

	sign(folder, Vector3.new(-16, 2.2, 132), "OLD DOJO  ↑", -12)
	sign(folder, Vector3.new(24, 2.2, 168), "RIVER PATH  →", 10)
	sign(folder, Vector3.new(-27, 2.2, 221), "SHRINE TRAIL  ←", -8)
end

function OpenWorldSliceService:ClaimKey(player, id)
	local key = tostring(player.UserId) .. ":" .. tostring(id)
	if self.Claims[key] then return false end
	self.Claims[key] = true
	return true
end

function OpenWorldSliceService:BuildChest(folder, id, position, quality)
	local model = Instance.new("Model")
	model.Name = "ExplorationChest_" .. id
	model.Parent = folder
	local wood = quality == "hidden" and Color3.fromRGB(87, 72, 50) or Color3.fromRGB(112, 80, 48)
	local base = part(model, "ChestBase", Vector3.new(5.2, 2.2, 3.5), CFrame.new(position + Vector3.new(0, 1.1, 0)), wood, Enum.Material.WoodPlanks)
	part(model, "ChestLid", Vector3.new(5.4, 1.0, 3.7), CFrame.new(position + Vector3.new(0, 2.7, -0.15)) * CFrame.Angles(math.rad(-8), 0, 0), wood:Lerp(Color3.fromRGB(153, 112, 64), 0.25), Enum.Material.WoodPlanks)
	part(model, "ChestBand", Vector3.new(0.65, 3.4, 3.8), CFrame.new(position + Vector3.new(0, 1.8, 0)), Color3.fromRGB(91, 82, 69), Enum.Material.Metal)
	local p = prompt(base, "Open", quality == "hidden" and "Hidden Cache" or "Traveler Cache", 0.35)
	p.Triggered:Connect(function(player)
		if not self:ClaimKey(player, id) then
			self.Context:Notify(player, "You already searched this cache during this journey.", "info")
			return
		end
		local stats = player:FindFirstChild("leaderstats")
		if not stats then return end
		local coins = quality == "hidden" and math.random(260, 420) or math.random(100, 220)
		local gems = quality == "hidden" and math.random(2, 4) or (math.random() < 0.35 and 1 or 0)
		stats.Coins.Value += coins
		stats.Gems.Value += gems
		self.Context.Services.DataService:AddXP(player, quality == "hidden" and 120 or 55)
		self.Context:Notify(player, "DISCOVERY CACHE • +" .. coins .. " Coins" .. (gems > 0 and (" • +" .. gems .. " Gems") or ""), "loot")
		base.Color = Color3.fromRGB(72, 68, 59)
	end)
end

function OpenWorldSliceService:BuildExploration(folder)
	local c = self.Context.Config.Zones[1].Center
	self:BuildChest(folder, "haven_rooftree", Vector3.new(-72, 2.2, -51), "normal")
	self:BuildChest(folder, "verdant_camp", c + Vector3.new(-57, 2.2, 20), "normal")
	self:BuildChest(folder, "verdant_river", Vector3.new(69, 2.2, 176), "normal")
	self:BuildChest(folder, "verdant_shrine", c + Vector3.new(-58, 5.9, 43), "hidden")
	self:BuildChest(folder, "verdant_cave", c + Vector3.new(58, 2.2, 61), "hidden")
end

function OpenWorldSliceService:GetEnemySpawn(zoneId, index, boss)
	local zone = self.Context.Config.Zones[zoneId]
	if not zone then return nil end
	if boss then return zone.Center + Vector3.new(0, 8, -34) end
	local offsets = {
		[1] = {
			Vector3.new(-48,6,9), Vector3.new(-35,6,2), Vector3.new(-18,6,-33),
			Vector3.new(14,6,-48), Vector3.new(39,6,-7), Vector3.new(50,6,28), Vector3.new(-48,6,48),
		},
		[2] = {
			Vector3.new(-50,6,12), Vector3.new(-28,6,-36), Vector3.new(7,6,-51),
			Vector3.new(37,6,-24), Vector3.new(52,6,18), Vector3.new(18,6,49), Vector3.new(-39,6,43),
		},
		[3] = {
			Vector3.new(-48,6,21), Vector3.new(-33,6,-34), Vector3.new(0,6,-51),
			Vector3.new(34,6,-38), Vector3.new(51,6,8), Vector3.new(25,6,45), Vector3.new(-38,6,46),
		},
		[4] = {
			Vector3.new(-49,6,18), Vector3.new(-34,6,-31), Vector3.new(-4,6,-57),
			Vector3.new(36,6,-44), Vector3.new(53,6,-5), Vector3.new(31,6,43), Vector3.new(-39,6,45),
		},
	}
	local list = offsets[zoneId]
	if not list or #list == 0 then return nil end
	local offset = list[((index - 1) % #list) + 1]
	return zone.Center + offset
end

function OpenWorldSliceService:GetSecretEggPositions()
	local c = self.Context.Config.Zones[1].Center
	return {
		Vector3.new(72, 4, 124), Vector3.new(-74, 4, 146),
		c + Vector3.new(-64,4,36), c + Vector3.new(62,4,48), c + Vector3.new(4,4,-65),
		self.Context.Config.Zones[2].Center + Vector3.new(-52,4,38),
		self.Context.Config.Zones[3].Center + Vector3.new(44,4,35),
		self.Context.Config.Zones[4].Center + Vector3.new(-38,4,42),
	}
end

function OpenWorldSliceService:UpdateRegions()
	for _, player in ipairs(Players:GetPlayers()) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root then continue end
		local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
		local regionName, color
		if flat.Magnitude <= 88 then
			regionName, color = "Rift Haven", Color3.fromRGB(139, 125, 104)
		else
			for _, zone in ipairs(self.Context.Config.Zones) do
				local center = Vector3.new(zone.Center.X, 0, zone.Center.Z)
				if (flat - center).Magnitude <= 112 then
					regionName, color = zone.Name, zone.Color
					break
				end
			end
		end
		if regionName and player:GetAttribute("OpenWorldRegion") ~= regionName then
			player:SetAttribute("OpenWorldRegion", regionName)
			self.Context.Remotes.ZoneEntered:FireClient(player, regionName, color)
		end
	end
end

function OpenWorldSliceService:Start()
	self:SculptTerrain()
	local old = self.Context.WorldFolder:FindFirstChild("VerticalSlice")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "VerticalSlice"
	folder.Parent = self.Context.WorldFolder
	self:BuildHaven(folder)
	self:BuildVerdantLandmarks(folder)
	self:BuildExploration(folder)

	RunService.Heartbeat:Connect(function(dt)
		self.RegionClock += dt
		if self.RegionClock < 0.65 then return end
		self.RegionClock = 0
		self:UpdateRegions()
	end)
end

return OpenWorldSliceService
