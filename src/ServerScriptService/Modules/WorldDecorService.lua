local WorldDecorService = {}
WorldDecorService.__index = WorldDecorService

function WorldDecorService.new(context)
	return setmetatable({Context = context}, WorldDecorService)
end

local function part(parent, name, size, cf, color, material, transparency, solid)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = solid == true
	p.CanTouch = false
	p.CanQuery = solid == true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function ball(parent, name, size, cf, color, material, transparency, solid)
	local p = part(parent, name, Vector3.new(size, size, size), cf, color, material, transparency, solid)
	p.Shape = Enum.PartType.Ball
	return p
end

local function wedge(parent, name, size, cf, color, material, solid)
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = solid == true
	p.CanTouch = false
	p.CanQuery = solid == true
	p.Color = color
	p.Material = material or Enum.Material.WoodPlanks
	p.Parent = parent
	return p
end

local function light(parent, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 0.55
	l.Range = range or 10
	l.Shadows = true
	l.Parent = parent
end

local function tree(parent, position, scale, leafColor)
	local trunkColor = Color3.fromRGB(86, 67, 48)
	part(parent, "TreeTrunk", Vector3.new(1.8 * scale, 9 * scale, 1.8 * scale), CFrame.new(position + Vector3.new(0, 4.5 * scale, 0)), trunkColor, Enum.Material.Wood, 0, true)
	ball(parent, "TreeCrown", 6.5 * scale, CFrame.new(position + Vector3.new(0, 10.0 * scale, 0)), leafColor, Enum.Material.Grass, 0, false)
	ball(parent, "TreeCrown", 5.1 * scale, CFrame.new(position + Vector3.new(2.3 * scale, 9.2 * scale, 0)), leafColor:Lerp(Color3.new(1,1,1), 0.035), Enum.Material.Grass, 0, false)
	ball(parent, "TreeCrown", 4.8 * scale, CFrame.new(position + Vector3.new(-2.2 * scale, 9.0 * scale, 1.2 * scale)), leafColor:Lerp(Color3.new(0,0,0), 0.045), Enum.Material.Grass, 0, false)
end

local function pine(parent, position, scale)
	part(parent, "PineTrunk", Vector3.new(1.4 * scale, 9 * scale, 1.4 * scale), CFrame.new(position + Vector3.new(0, 4.5 * scale, 0)), Color3.fromRGB(78, 62, 48), Enum.Material.Wood, 0, true)
	local green = Color3.fromRGB(55, 83, 72)
	for i = 1, 3 do
		local y = 6.3 * scale + (i - 1) * 2.6 * scale
		ball(parent, "PineNeedles", (7.1 - i * 1.15) * scale, CFrame.new(position + Vector3.new(0, y, 0)), green:Lerp(Color3.fromRGB(205, 219, 220), 0.08 * i), Enum.Material.Grass, 0, false)
	end
end

local function boulder(parent, position, size, color, material)
	local p = part(parent, "Boulder", size, CFrame.new(position) * CFrame.Angles(math.rad(12), math.rad(27), math.rad(8)), color, material or Enum.Material.Rock, 0, true)
	return p
end

local function lantern(parent, position)
	part(parent, "LanternPost", Vector3.new(0.55, 5.5, 0.55), CFrame.new(position + Vector3.new(0, 2.75, 0)), Color3.fromRGB(55, 49, 42), Enum.Material.Wood, 0, true)
	local lamp = part(parent, "Lantern", Vector3.new(1.25, 1.55, 1.25), CFrame.new(position + Vector3.new(0, 5.5, 0)), Color3.fromRGB(244, 190, 103), Enum.Material.Glass, 0.2, false)
	light(lamp, Color3.fromRGB(255, 196, 105), 0.65, 11)
end

local function fenceLine(parent, from, to, posts)
	local delta = to - from
	for i = 0, posts do
		local alpha = i / posts
		local pos = from:Lerp(to, alpha)
		part(parent, "FencePost", Vector3.new(0.65, 4, 0.65), CFrame.new(pos + Vector3.new(0, 2, 0)), Color3.fromRGB(91, 72, 51), Enum.Material.Wood, 0, true)
	end
	local mid = from:Lerp(to, 0.5) + Vector3.new(0, 2.4, 0)
	local horizontal = Vector3.new(delta.X, 0, delta.Z)
	part(parent, "FenceRail", Vector3.new(0.45, 0.5, horizontal.Magnitude), CFrame.lookAt(mid, mid + horizontal.Unit), Color3.fromRGB(101, 80, 57), Enum.Material.Wood, 0, true)
end

local function house(parent, center, width, depth, wallColor, roofColor)
	part(parent, "HouseFloor", Vector3.new(width, 1, depth), CFrame.new(center + Vector3.new(0, 0.5, 0)), Color3.fromRGB(105, 94, 75), Enum.Material.WoodPlanks, 0, true)
	for _, x in ipairs({-width/2 + 1, width/2 - 1}) do
		part(parent, "HousePost", Vector3.new(1.1, 10, 1.1), CFrame.new(center + Vector3.new(x, 5.5, -depth/2 + 1)), Color3.fromRGB(78, 57, 40), Enum.Material.Wood, 0, true)
		part(parent, "HousePost", Vector3.new(1.1, 10, 1.1), CFrame.new(center + Vector3.new(x, 5.5, depth/2 - 1)), Color3.fromRGB(78, 57, 40), Enum.Material.Wood, 0, true)
	end
	part(parent, "HouseBack", Vector3.new(width - 2, 8, 1), CFrame.new(center + Vector3.new(0, 5, -depth/2)), wallColor, Enum.Material.WoodPlanks, 0, true)
	part(parent, "HouseLeft", Vector3.new(1, 8, depth - 2), CFrame.new(center + Vector3.new(-width/2, 5, 0)), wallColor, Enum.Material.WoodPlanks, 0, true)
	part(parent, "HouseRight", Vector3.new(1, 8, depth - 2), CFrame.new(center + Vector3.new(width/2, 5, 0)), wallColor, Enum.Material.WoodPlanks, 0, true)
	part(parent, "HouseFrontA", Vector3.new(width * 0.38, 8, 1), CFrame.new(center + Vector3.new(-width * 0.29, 5, depth/2)), wallColor, Enum.Material.WoodPlanks, 0, true)
	part(parent, "HouseFrontB", Vector3.new(width * 0.38, 8, 1), CFrame.new(center + Vector3.new(width * 0.29, 5, depth/2)), wallColor, Enum.Material.WoodPlanks, 0, true)
	wedge(parent, "RoofLeft", Vector3.new(width + 3, 3.8, depth/2 + 2), CFrame.new(center + Vector3.new(0, 11.1, -depth/4)) * CFrame.Angles(0, math.rad(180), 0), roofColor, Enum.Material.Slate, false)
	wedge(parent, "RoofRight", Vector3.new(width + 3, 3.8, depth/2 + 2), CFrame.new(center + Vector3.new(0, 11.1, depth/4)), roofColor, Enum.Material.Slate, false)
end

function WorldDecorService:DecorateHaven(folder)
	local wall = Color3.fromRGB(195, 183, 153)
	local roof = Color3.fromRGB(79, 73, 67)
	house(folder, Vector3.new(-54, 2, -24), 24, 19, wall, roof)
	house(folder, Vector3.new(54, 2, -20), 26, 20, wall:Lerp(Color3.fromRGB(170, 151, 124), 0.25), roof)
	house(folder, Vector3.new(-48, 2, 42), 22, 18, wall, Color3.fromRGB(67, 75, 70))
	house(folder, Vector3.new(50, 2, 44), 25, 19, wall:Lerp(Color3.fromRGB(160, 174, 145), 0.20), Color3.fromRGB(72, 78, 65))

	-- Small market beside the plaza.
	for i, x in ipairs({-19, -7, 7, 19}) do
		local z = 47
		part(folder, "MarketCounter", Vector3.new(9, 2.5, 4), CFrame.new(x, 4.0, z), Color3.fromRGB(104, 77, 51), Enum.Material.WoodPlanks, 0, true)
		part(folder, "MarketCanopy", Vector3.new(10, 0.5, 7), CFrame.new(x, 8.0, z), i % 2 == 0 and Color3.fromRGB(129, 78, 62) or Color3.fromRGB(112, 104, 72), Enum.Material.Fabric, 0, false)
	end

	for _, pos in ipairs({
		Vector3.new(-73,2,-60), Vector3.new(-73,2,5), Vector3.new(-69,2,70),
		Vector3.new(73,2,-62), Vector3.new(72,2,9), Vector3.new(70,2,71),
		Vector3.new(-18,2,-67), Vector3.new(18,2,-67),
	}) do tree(folder, pos, 0.9, Color3.fromRGB(83, 119, 77)) end

	for _, pos in ipairs({Vector3.new(-36,2,-35), Vector3.new(36,2,-35), Vector3.new(-36,2,34), Vector3.new(36,2,34)}) do lantern(folder, pos) end
	fenceLine(folder, Vector3.new(-73,2,74), Vector3.new(-34,2,74), 5)
	fenceLine(folder, Vector3.new(34,2,74), Vector3.new(73,2,74), 5)
end

function WorldDecorService:DecorateVerdant(folder, zone)
	local c = zone.Center
	local random = Random.new(101)
	for i = 1, 34 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(46, 88)
		local pos = c + Vector3.new(math.cos(angle) * radius, 2, math.sin(angle) * radius)
		tree(folder, pos, random:NextNumber(0.72, 1.12), Color3.fromRGB(63, random:NextInteger(103, 126), 66))
	end

	-- Old dojo ruins instead of another glowing arena.
	local ruin = c + Vector3.new(0, 2, -58)
	part(folder, "DojoFoundation", Vector3.new(47, 1.2, 28), CFrame.new(ruin), Color3.fromRGB(104, 99, 85), Enum.Material.Slate, 0, true)
	for _, x in ipairs({-19, -7, 8, 19}) do
		part(folder, "DojoRuinedPost", Vector3.new(1.8, 10 + (math.abs(x) % 4), 1.8), CFrame.new(ruin + Vector3.new(x, 5.5, -8)), Color3.fromRGB(77, 57, 41), Enum.Material.Wood, 0, true)
	end
	part(folder, "DojoBackWall", Vector3.new(43, 7, 1.3), CFrame.new(ruin + Vector3.new(0, 4, -12)), Color3.fromRGB(171, 162, 137), Enum.Material.WoodPlanks, 0, true)

	for _, x in ipairs({-61, -55, 55, 61}) do
		for _, z in ipairs({-34, -10, 16, 39}) do
			part(folder, "Bamboo", Vector3.new(1.05, 13, 1.05), CFrame.new(c + Vector3.new(x, 8.5, z)), Color3.fromRGB(77, 118, 67), Enum.Material.Wood, 0, true)
		end
	end
	for _, pos in ipairs({Vector3.new(-34,3,38), Vector3.new(-27,3,32), Vector3.new(34,3,-8), Vector3.new(42,3,-18)}) do
		boulder(folder, c + pos, Vector3.new(7, 4, 6), Color3.fromRGB(94, 98, 87))
	end
end

function WorldDecorService:DecorateEmber(folder, zone)
	local c = zone.Center
	local random = Random.new(202)
	for i = 1, 24 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(48, 91)
		local pos = c + Vector3.new(math.cos(angle) * radius, 4, math.sin(angle) * radius)
		boulder(folder, pos, Vector3.new(random:NextNumber(6,13), random:NextNumber(5,15), random:NextNumber(6,12)), Color3.fromRGB(87, 70, 62), Enum.Material.Rock)
	end

	-- Forge ruin: muted brick/metal with only the furnace itself glowing.
	local forge = c + Vector3.new(0, 2, -55)
	part(folder, "ForgeFoundation", Vector3.new(48, 1.4, 28), CFrame.new(forge), Color3.fromRGB(91, 72, 63), Enum.Material.Brick, 0, true)
	for _, x in ipairs({-18, 18}) do
		part(folder, "ForgeTower", Vector3.new(12, 18, 12), CFrame.new(forge + Vector3.new(x, 9.5, -7)), Color3.fromRGB(78, 60, 55), Enum.Material.Brick, 0, true)
	end
	local furnace = part(folder, "ForgeMouth", Vector3.new(10, 5, 0.5), CFrame.new(forge + Vector3.new(0, 4, -13.8)), Color3.fromRGB(191, 91, 47), Enum.Material.Neon, 0.18, false)
	light(furnace, Color3.fromRGB(211, 103, 53), 0.65, 10)

	-- Sparse lava cracks: accents, not the entire biome.
	for _, offset in ipairs({Vector3.new(-32,2,18), Vector3.new(25,2,27), Vector3.new(41,2,-22), Vector3.new(-45,2,-14)}) do
		part(folder, "LavaFissure", Vector3.new(18, 0.18, 1.4), CFrame.new(c + offset) * CFrame.Angles(0, math.rad(25 + offset.X), 0), Color3.fromRGB(183, 73, 38), Enum.Material.Neon, 0.22, false)
	end
end

function WorldDecorService:DecorateFrost(folder, zone)
	local c = zone.Center
	local random = Random.new(303)
	for i = 1, 27 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(47, 91)
		local pos = c + Vector3.new(math.cos(angle) * radius, 2, math.sin(angle) * radius)
		pine(folder, pos, random:NextNumber(0.72, 1.06))
	end
	for _, pos in ipairs({Vector3.new(-48,4,28), Vector3.new(46,4,35), Vector3.new(-36,4,-37), Vector3.new(41,4,-42)}) do
		boulder(folder, c + pos, Vector3.new(9, 7, 8), Color3.fromRGB(139, 153, 158), Enum.Material.Snow)
	end

	-- Weathered citadel gate at the far ridge.
	local gate = c + Vector3.new(0, 2, -58)
	for _, x in ipairs({-22, -12, 12, 22}) do
		part(folder, "CitadelTower", Vector3.new(9, 22, 9), CFrame.new(gate + Vector3.new(x, 11.5, 0)), Color3.fromRGB(100, 112, 119), Enum.Material.Slate, 0, true)
	end
	part(folder, "CitadelWallL", Vector3.new(17, 13, 5), CFrame.new(gate + Vector3.new(-16, 7, 0)), Color3.fromRGB(105, 117, 123), Enum.Material.Slate, 0, true)
	part(folder, "CitadelWallR", Vector3.new(17, 13, 5), CFrame.new(gate + Vector3.new(16, 7, 0)), Color3.fromRGB(105, 117, 123), Enum.Material.Slate, 0, true)
	part(folder, "FrozenBanner", Vector3.new(6, 7, 0.25), CFrame.new(gate + Vector3.new(0, 10, 2.7)), Color3.fromRGB(88, 122, 141), Enum.Material.Fabric, 0, false)
end

local function deadTree(parent, position, scale)
	local color = Color3.fromRGB(59, 53, 58)
	part(parent, "DeadTree", Vector3.new(1.5 * scale, 11 * scale, 1.5 * scale), CFrame.new(position + Vector3.new(0, 5.5 * scale, 0)) * CFrame.Angles(0, 0, math.rad(8)), color, Enum.Material.Wood, 0, true)
	part(parent, "DeadBranch", Vector3.new(0.8 * scale, 6 * scale, 0.8 * scale), CFrame.new(position + Vector3.new(2.1 * scale, 8.2 * scale, 0)) * CFrame.Angles(0, 0, math.rad(-50)), color, Enum.Material.Wood, 0, false)
	part(parent, "DeadBranch", Vector3.new(0.7 * scale, 5 * scale, 0.7 * scale), CFrame.new(position + Vector3.new(-1.8 * scale, 7.5 * scale, 0.5)) * CFrame.Angles(0, 0, math.rad(48)), color, Enum.Material.Wood, 0, false)
end

function WorldDecorService:DecorateVoid(folder, zone)
	local c = zone.Center
	local random = Random.new(404)
	for i = 1, 18 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(50, 91)
		deadTree(folder, c + Vector3.new(math.cos(angle) * radius, 2, math.sin(angle) * radius), random:NextNumber(0.7, 1.12))
	end
	for i = 1, 15 do
		local angle = (i / 15) * math.pi * 2
		local radius = 73 + (i % 3) * 6
		local pos = c + Vector3.new(math.cos(angle) * radius, 5 + (i % 2) * 2, math.sin(angle) * radius)
		boulder(folder, pos, Vector3.new(7, 10 + (i % 3) * 3, 7), Color3.fromRGB(63, 58, 68), Enum.Material.Basalt)
	end

	-- The boss area is a ruined stone circle, not a luminous arena.
	local bossCenter = c + Vector3.new(0, 2, -34)
	for i = 1, 14 do
		local angle = (i / 14) * math.pi * 2
		local pos = bossCenter + Vector3.new(math.cos(angle) * 34, 0, math.sin(angle) * 34)
		local stone = part(folder, "BossStandingStone", Vector3.new(4.5, 9 + (i % 3) * 2, 3.7), CFrame.new(pos + Vector3.new(0, 5, 0)) * CFrame.Angles(math.rad(i%2*4), -angle, math.rad((i%3-1)*5)), Color3.fromRGB(67, 62, 72), Enum.Material.Slate, 0, true)
		if i % 3 == 0 then
			local rune = part(folder, "BossRune", Vector3.new(1.1, 3.2, 0.16), stone.CFrame * CFrame.new(0, 0.6, -1.95), Color3.fromRGB(118, 87, 132), Enum.Material.Neon, 0.28, false)
			light(rune, rune.Color, 0.28, 6)
		end
	end
end

function WorldDecorService:Start()
	local old = self.Context.WorldFolder:FindFirstChild("Decor")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "Decor"
	folder.Parent = self.Context.WorldFolder

	self:DecorateHaven(folder)
	for _, zone in ipairs(self.Context.Config.Zones) do
		if zone.Id == 1 then
			self:DecorateVerdant(folder, zone)
		elseif zone.Id == 2 then
			self:DecorateEmber(folder, zone)
		elseif zone.Id == 3 then
			self:DecorateFrost(folder, zone)
		elseif zone.Id == 4 then
			self:DecorateVoid(folder, zone)
		end
	end
end

return WorldDecorService
