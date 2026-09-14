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

local function glow(parent, name, size, cf, color, transparency)
	local p = part(parent, name, size, cf, color, Enum.Material.Neon, transparency or 0.08, false)
	p.CastShadow = false
	return p
end

local function light(parent, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 1.1
	l.Range = range or 14
	l.Shadows = true
	l.Parent = parent
	return l
end

local function fire(parent, color, secondary, size, heat)
	local f = Instance.new("Fire")
	f.Color = color
	f.SecondaryColor = secondary or color
	f.Size = size or 5
	f.Heat = heat or 5
	f.Parent = parent
	return f
end

local function cylinder(parent, name, size, cf, color, material, transparency, solid)
	local p = part(parent, name, size, cf * CFrame.Angles(0, 0, math.rad(90)), color, material, transparency, solid)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function lantern(parent, position, color)
	local post = part(parent, "LanternPost", Vector3.new(0.8, 7, 0.8), CFrame.new(position + Vector3.new(0, 3.5, 0)), Color3.fromRGB(42, 42, 50), Enum.Material.Metal, 0, true)
	local cap = part(parent, "LanternCap", Vector3.new(3.2, 0.5, 3.2), CFrame.new(position + Vector3.new(0, 7.1, 0)), Color3.fromRGB(50, 50, 62), Enum.Material.Metal)
	local lamp = glow(parent, "LanternGlow", Vector3.new(1.5, 2.1, 1.5), CFrame.new(position + Vector3.new(0, 6.1, 0)), color, 0.15)
	light(lamp, color, 1.3, 14)
	return post, cap, lamp
end

local function roof(parent, center, width, depth, y, color)
	part(parent, "Roof", Vector3.new(width + 6, 1.2, depth + 6), CFrame.new(center + Vector3.new(0, y, 0)), color, Enum.Material.Slate, 0, false)
	part(parent, "RoofInset", Vector3.new(width, 0.65, depth), CFrame.new(center + Vector3.new(0, y + 0.75, 0)), color:Lerp(Color3.new(1,1,1), 0.08), Enum.Material.Slate, 0, false)
end

local function arch(parent, center, width, height, color, accent)
	for _, x in ipairs({-width/2, width/2}) do
		part(parent, "ArchPost", Vector3.new(2.4, height, 2.4), CFrame.new(center + Vector3.new(x, height/2, 0)), color, Enum.Material.Marble, 0, true)
	end
	part(parent, "ArchTop", Vector3.new(width + 5, 2.4, 3), CFrame.new(center + Vector3.new(0, height, 0)), color, Enum.Material.Marble, 0, true)
	glow(parent, "ArchAccent", Vector3.new(width + 1, 0.45, 3.3), CFrame.new(center + Vector3.new(0, height + 1.45, 0)), accent, 0.12)
end

local function bladeMonument(parent, center, color)
	local base = part(parent, "BladeMonumentBase", Vector3.new(9, 3, 9), CFrame.new(center + Vector3.new(0, 1.5, 0)), Color3.fromRGB(38, 39, 48), Enum.Material.Marble, 0, true)
	local blade = glow(parent, "BladeMonument", Vector3.new(1.4, 15, 2.6), CFrame.new(center + Vector3.new(0, 11, 0)) * CFrame.Angles(0, 0, math.rad(18)), color, 0.06)
	light(blade, color, 1.1, 15)
	return base
end

function WorldDecorService:DecorateHub(folder)
	local rift = Color3.fromRGB(158, 96, 235)
	local cyan = Color3.fromRGB(82, 210, 245)
	local dark = Color3.fromRGB(31, 33, 45)

	-- Outer colonnade and skyline: tall, mostly dark, readable from every portal.
	for i = 1, 16 do
		local angle = (i / 16) * math.pi * 2
		local radius = 94
		local pos = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local h = 17 + (i % 3) * 5
		local pillar = part(folder, "NexusSpire", Vector3.new(4, h, 4), CFrame.new(pos + Vector3.new(0, h/2 + 2, 0)), dark, Enum.Material.Marble, 0, true)
		local cap = glow(folder, "NexusSpireCap", Vector3.new(5.5, 0.55, 5.5), CFrame.new(pos + Vector3.new(0, h + 2.4, 0)), i % 2 == 0 and rift or cyan, 0.10)
		light(cap, cap.Color, 0.7, 10)
		pillar.CastShadow = true
	end

	-- Four approach arches create real architectural thresholds into the portal courts.
	arch(folder, Vector3.new(0, 4.5, -46), 22, 15, dark, Color3.fromRGB(65, 170, 95))
	arch(folder, Vector3.new(46, 4.5, 0), 22, 15, dark, Color3.fromRGB(235, 108, 50))
	arch(folder, Vector3.new(0, 4.5, 46), 22, 15, dark, Color3.fromRGB(90, 180, 235))
	arch(folder, Vector3.new(-46, 4.5, 0), 22, 15, dark, Color3.fromRGB(170, 85, 225))

	for _, pos in ipairs({Vector3.new(-28, 5, -28), Vector3.new(28, 5, -28), Vector3.new(-28, 5, 28), Vector3.new(28, 5, 28)}) do
		lantern(folder, pos, rift)
	end

	-- Floating shard crown above the nexus.
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		local radius = 18 + (i % 2) * 4
		local y = 24 + (i % 3) * 3
		local pos = Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
		local shard = glow(folder, "NexusFloatingShard", Vector3.new(1.2, 6 + (i % 2) * 2, 1.2), CFrame.new(pos) * CFrame.Angles(math.rad(i*9), math.rad(i*31), math.rad(20)), i % 2 == 0 and rift or cyan, 0.12)
		shard.CastShadow = false
	end

	bladeMonument(folder, Vector3.new(-20, 5, 0), Color3.fromRGB(255, 112, 62))
	bladeMonument(folder, Vector3.new(20, 5, 0), Color3.fromRGB(98, 205, 255))
end

function WorldDecorService:DecorateVerdant(folder, zone)
	local c = zone.Center
	local green = zone.Color
	local wood = Color3.fromRGB(72, 52, 38)
	local stone = Color3.fromRGB(61, 69, 64)

	-- Dojo at the back of the island.
	local dojo = c + Vector3.new(0, 6.5, -58)
	part(folder, "DojoBase", Vector3.new(48, 4, 25), CFrame.new(dojo), stone, Enum.Material.Slate, 0, true)
	for _, x in ipairs({-19, -7, 7, 19}) do
		part(folder, "DojoPost", Vector3.new(2, 14, 2), CFrame.new(dojo + Vector3.new(x, 9, 0)), wood, Enum.Material.Wood, 0, true)
	end
	part(folder, "DojoWall", Vector3.new(44, 11, 2), CFrame.new(dojo + Vector3.new(0, 8, -9)), Color3.fromRGB(210, 202, 177), Enum.Material.WoodPlanks, 0, true)
	roof(folder, dojo, 50, 27, 16, Color3.fromRGB(41, 64, 46))
	roof(folder, dojo, 34, 20, 19, Color3.fromRGB(51, 82, 56))
	glow(folder, "DojoCrest", Vector3.new(11, 0.45, 2), CFrame.new(dojo + Vector3.new(0, 21, 0)), green, 0.10)

	-- Garden / water area to break the square arena silhouette.
	part(folder, "KoiPond", Vector3.new(30, 0.5, 18), CFrame.new(c + Vector3.new(45, 6.2, 26)), Color3.fromRGB(46, 116, 126), Enum.Material.Glass, 0.26, false)
	for i = 1, 6 do
		part(folder, "GardenStone", Vector3.new(4.5, 0.6, 4.5), CFrame.new(c + Vector3.new(28 + i*5, 6.65, 17 + (i%2)*4)), Color3.fromRGB(92, 96, 88), Enum.Material.Slate, 0, true)
	end

	for _, x in ipairs({-60, -49, 49, 60}) do
		for _, z in ipairs({-36, -6, 24}) do
			local trunk = part(folder, "Bamboo", Vector3.new(1.3, 15 + ((x+z)%3), 1.3), CFrame.new(c + Vector3.new(x, 13, z)), Color3.fromRGB(66, 107, 62), Enum.Material.Wood, 0, true)
			for y = 8, 17, 4.5 do
				part(folder, "BambooJoint", Vector3.new(1.7, 0.38, 1.7), CFrame.new(trunk.Position.X, c.Y + y, trunk.Position.Z), Color3.fromRGB(95, 136, 77), Enum.Material.Wood, 0, false)
			end
		end
	end

	-- Torii gateway on the entrance side.
	local gate = c + Vector3.new(0, 6, 51)
	for _, x in ipairs({-11, 11}) do
		part(folder, "ToriiPost", Vector3.new(2.6, 17, 2.6), CFrame.new(gate + Vector3.new(x, 8.5, 0)), Color3.fromRGB(102, 41, 34), Enum.Material.Wood, 0, true)
	end
	part(folder, "ToriiBeam", Vector3.new(31, 2.6, 3), CFrame.new(gate + Vector3.new(0, 17, 0)), Color3.fromRGB(125, 47, 39), Enum.Material.Wood, 0, true)
	part(folder, "ToriiBeamTop", Vector3.new(36, 1.4, 3.4), CFrame.new(gate + Vector3.new(0, 19.2, 0)), Color3.fromRGB(140, 51, 43), Enum.Material.Wood, 0, true)
end

function WorldDecorService:DecorateEmber(folder, zone)
	local c = zone.Center
	local orange = Color3.fromRGB(255, 95, 35)
	local brick = Color3.fromRGB(72, 44, 39)
	local metal = Color3.fromRGB(55, 48, 47)

	-- Broken forge district with magma channels and industrial silhouettes.
	for _, z in ipairs({-40, 2, 44}) do
		local strip = glow(folder, "MagmaChannel", Vector3.new(92, 0.32, 3.4), CFrame.new(c + Vector3.new(0, 6.55, z)), orange, 0.03)
		light(strip, orange, 0.8, 11)
		for _, x in ipairs({-45, 45}) do
			part(folder, "MagmaBridge", Vector3.new(13, 0.8, 8), CFrame.new(c + Vector3.new(x, 7.05, z)), metal, Enum.Material.Metal, 0, true)
		end
	end

	for _, offset in ipairs({Vector3.new(-53,0,-48), Vector3.new(53,0,-48), Vector3.new(-53,0,24), Vector3.new(53,0,24)}) do
		local base = c + offset + Vector3.new(0, 6.5, 0)
		part(folder, "ForgeTower", Vector3.new(13, 22, 13), CFrame.new(base + Vector3.new(0, 11, 0)), brick, Enum.Material.Brick, 0, true)
		part(folder, "ForgeCrown", Vector3.new(16, 2, 16), CFrame.new(base + Vector3.new(0, 22, 0)), metal, Enum.Material.Metal, 0, true)
		local brazier = glow(folder, "ForgeFlameCore", Vector3.new(3.5, 1.3, 3.5), CFrame.new(base + Vector3.new(0, 24, 0)), orange, 0.05)
		light(brazier, orange, 1.7, 17)
		fire(brazier, Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 45, 10), 6, 8)
	end

	for _, x in ipairs({-31, 31}) do
		local furnace = c + Vector3.new(x, 8, -59)
		part(folder, "Furnace", Vector3.new(22, 15, 14), CFrame.new(furnace + Vector3.new(0, 7.5, 0)), brick, Enum.Material.Brick, 0, true)
		glow(folder, "FurnaceMouth", Vector3.new(9, 6, 0.4), CFrame.new(furnace + Vector3.new(0, 4, 7.15)), orange, 0.05)
	end
end

function WorldDecorService:DecorateFrost(folder, zone)
	local c = zone.Center
	local ice = Color3.fromRGB(122, 218, 255)
	local stone = Color3.fromRGB(73, 87, 103)

	-- Citadel wall line with central gate.
	for _, x in ipairs({-54, -38, 38, 54}) do
		part(folder, "CitadelTower", Vector3.new(13, 28, 13), CFrame.new(c + Vector3.new(x, 20, -55)), stone, Enum.Material.Slate, 0, true)
		local crown = cylinder(folder, "IceCrown", Vector3.new(2, 15, 15), CFrame.new(c + Vector3.new(x, 34, -55)), ice, Enum.Material.Ice, 0.12, false)
		light(crown, ice, 0.9, 13)
	end
	part(folder, "CitadelWallL", Vector3.new(40, 17, 6), CFrame.new(c + Vector3.new(-24, 14.5, -55)), stone, Enum.Material.Slate, 0, true)
	part(folder, "CitadelWallR", Vector3.new(40, 17, 6), CFrame.new(c + Vector3.new(24, 14.5, -55)), stone, Enum.Material.Slate, 0, true)
	arch(folder, c + Vector3.new(0, 6, -54), 16, 18, stone, ice)

	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local radius = 61 + (i % 2) * 5
		local h = 12 + (i % 4) * 4
		local pos = c + Vector3.new(math.cos(angle) * radius, 7 + h/2, math.sin(angle) * radius)
		local shard = part(folder, "IceSpire", Vector3.new(3.5, h, 3.5), CFrame.new(pos) * CFrame.Angles(math.rad((i%2)*8), math.rad(i*23), math.rad(12)), ice:Lerp(Color3.new(1,1,1), 0.25), Enum.Material.Ice, 0.13, true)
		shard.CastShadow = true
	end

	for _, pos in ipairs({c + Vector3.new(-42,7,38), c + Vector3.new(42,7,38)}) do
		lantern(folder, pos, ice)
	end
end

function WorldDecorService:DecorateVoid(folder, zone)
	local c = zone.Center
	local violet = Color3.fromRGB(189, 78, 255)
	local abyss = Color3.fromRGB(31, 25, 45)

	-- Dedicated boss dais around the tyrant's actual spawn position.
	local boss = c + Vector3.new(0, 6.55, -34)
	cylinder(folder, "TyrantDais", Vector3.new(1.2, 52, 52), CFrame.new(boss), abyss, Enum.Material.Slate, 0, true)
	cylinder(folder, "TyrantRune", Vector3.new(0.20, 45, 45), CFrame.new(boss + Vector3.new(0,0.72,0)), violet, Enum.Material.Neon, 0.55, false)
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local pos = boss + Vector3.new(math.cos(angle) * 22, 1, math.sin(angle) * 22)
		glow(folder, "TyrantRuneMark", Vector3.new(5, 0.16, 1.2), CFrame.new(pos) * CFrame.Angles(0, -angle, 0), violet, 0.16)
	end

	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local radius = 58 + (i % 3) * 6
		local y = 15 + (i % 4) * 4
		local pos = c + Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
		local stone = part(folder, "VoidMonolith", Vector3.new(7, 16 + (i%3)*4, 7), CFrame.new(pos) * CFrame.Angles(math.rad(i*5), math.rad(i*27), math.rad(i*9)), abyss, Enum.Material.Slate, 0, false)
		local glyph = glow(folder, "VoidGlyph", Vector3.new(4.2, 0.3, 4.2), stone.CFrame * CFrame.new(0, stone.Size.Y/2 + 0.2, 0), violet, 0.10)
		light(glyph, violet, 0.9, 12)
	end

	-- Broken bridge slabs suspended over the front of the arena.
	for i = -4, 4 do
		local x = i * 11
		local y = 8 + math.abs(i % 2) * 2
		part(folder, "VoidBridgeShard", Vector3.new(8.5, 1.2, 17), CFrame.new(c + Vector3.new(x, y, 52)) * CFrame.Angles(math.rad(i*2), math.rad(i*4), math.rad(i*3)), abyss:Lerp(violet, 0.07), Enum.Material.Slate, 0, true)
	end

	for _, x in ipairs({-34, 34}) do
		local beacon = glow(folder, "VoidBeacon", Vector3.new(2.2, 26, 2.2), CFrame.new(c + Vector3.new(x, 20, -54)), violet, 0.08)
		light(beacon, violet, 1.4, 20)
	end
end

function WorldDecorService:Start()
	local old = self.Context.WorldFolder:FindFirstChild("Decor")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "Decor"
	folder.Parent = self.Context.WorldFolder

	self:DecorateHub(folder)
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
