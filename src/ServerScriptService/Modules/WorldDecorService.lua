local Workspace = game:GetService("Workspace")

local WorldDecorService = {}
WorldDecorService.__index = WorldDecorService

function WorldDecorService.new(context)
	return setmetatable({Context = context}, WorldDecorService)
end

local function part(parent, name, size, cf, color, material, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Parent = parent
	return p
end

local function light(parent, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 1.5
	l.Range = range or 14
	l.Parent = parent
	return l
end

local function verticalBeam(parent, name, position, height, color, width)
	local beam = part(parent, name, Vector3.new(width or 1.2, height, width or 1.2), CFrame.new(position + Vector3.new(0, height / 2, 0)), color, Enum.Material.Neon, 0.08)
	light(beam, color, 1.2, 12)
	return beam
end

function WorldDecorService:DecorateHub(folder)
	local map = self.Context.WorldFolder:FindFirstChild("Map")
	if not map then return end

	local core = map:FindFirstChild("HubCore")
	if core then
		for _, child in ipairs(core:GetChildren()) do
			if child:IsA("BillboardGui") then
				child.MaxDistance = 38
				child.StudsOffset = Vector3.new(0, 5.5, 0)
				local label = child:FindFirstChild("Label")
				if label then label.Text = "RIFT NEXUS" end
			end
		end
	end

	-- Low neon guide rails make the hub read as a deliberate plaza instead of a flat plate.
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local radius = 48
		local pos = Vector3.new(math.cos(angle) * radius, 3.1, math.sin(angle) * radius)
		local segment = part(folder, "NexusRing", Vector3.new(10, 0.45, 2.2), CFrame.new(pos) * CFrame.Angles(0, -angle, 0), Color3.fromRGB(126, 88, 210), Enum.Material.Neon, 0.22)
		segment.CastShadow = false
	end

	for _, z in ipairs({-26, 26}) do
		for _, x in ipairs({-26, 26}) do
			local pillar = part(folder, "NexusBeacon", Vector3.new(3.2, 14, 3.2), CFrame.new(x, 9, z), Color3.fromRGB(86, 75, 126), Enum.Material.Marble, 0)
			local cap = part(folder, "NexusBeaconGlow", Vector3.new(5, 1, 5), CFrame.new(x, 16.4, z), Color3.fromRGB(170, 105, 255), Enum.Material.Neon, 0.05)
			light(cap, cap.Color, 1.5, 16)
			pillar.CanCollide = true
		end
	end

	-- Four short floor paths visually connect the spawn to the portal line.
	for _, x in ipairs({-54, -18, 18, 54}) do
		for step = 1, 4 do
			part(folder, "PortalPath", Vector3.new(7, 0.18, 5), CFrame.new(x, 2.2, 20 - step * 12), Color3.fromRGB(97, 78, 150), Enum.Material.Neon, 0.68)
		end
	end
end

function WorldDecorService:DecorateVerdant(folder, zone)
	local c = zone.Center
	local green = zone.Color
	for _, x in ipairs({-43, 43}) do
		for _, z in ipairs({-34, 4, 34}) do
			local trunk = part(folder, "Bamboo", Vector3.new(1.6, 16, 1.6), CFrame.new(c + Vector3.new(x, 10, z)), Color3.fromRGB(55, 105, 66), Enum.Material.Wood, 0)
			trunk.CanCollide = true
			part(folder, "BambooGlow", Vector3.new(2.2, 0.6, 2.2), CFrame.new(c + Vector3.new(x, 18.2, z)), green, Enum.Material.Neon, 0.15)
		end
	end
	-- Simple torii silhouette at the far edge.
	for _, x in ipairs({-10, 10}) do
		local post = part(folder, "DojoGate", Vector3.new(3, 18, 3), CFrame.new(c + Vector3.new(x, 11, -48)), Color3.fromRGB(60, 80, 65), Enum.Material.Wood, 0)
		post.CanCollide = true
	end
	part(folder, "DojoGateTop", Vector3.new(27, 2.4, 3), CFrame.new(c + Vector3.new(0, 19.5, -48)), green, Enum.Material.Neon, 0.05)
end

function WorldDecorService:DecorateEmber(folder, zone)
	local c = zone.Center
	local orange = zone.Color
	for _, z in ipairs({-46, -30, 30, 46}) do
		local strip = part(folder, "MagmaChannel", Vector3.new(72, 0.25, 2.8), CFrame.new(c + Vector3.new(0, 2.2, z)), Color3.fromRGB(255, 94, 32), Enum.Material.Neon, 0.08)
		light(strip, orange, 1.2, 11)
	end
	for _, offset in ipairs({Vector3.new(-45, 0, -45), Vector3.new(45, 0, -45), Vector3.new(-45, 0, 45), Vector3.new(45, 0, 45)}) do
		verticalBeam(folder, "EmberVent", c + offset + Vector3.new(0, 2.5, 0), 18, Color3.fromRGB(255, 95, 38), 1.5)
	end
end

function WorldDecorService:DecorateFrost(folder, zone)
	local c = zone.Center
	local blue = zone.Color
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local radius = 48
		local pos = c + Vector3.new(math.cos(angle) * radius, 9, math.sin(angle) * radius)
		local shard = part(folder, "IceSpire", Vector3.new(4, 18 + (i % 3) * 5, 4), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(18)), blue:Lerp(Color3.new(1, 1, 1), 0.25), Enum.Material.Ice, 0.1)
		shard.CanCollide = true
	end
	for _, z in ipairs({-20, 20}) do
		part(folder, "FrostRune", Vector3.new(54, 0.22, 1.7), CFrame.new(c + Vector3.new(0, 3.15, z)), Color3.fromRGB(120, 220, 255), Enum.Material.Neon, 0.25)
	end
end

function WorldDecorService:DecorateVoid(folder, zone)
	local c = zone.Center
	local violet = zone.Color
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		local radius = 47 + (i % 2) * 5
		local y = 8 + (i % 3) * 5
		local pos = c + Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
		local stone = part(folder, "VoidMonolith", Vector3.new(5, 10, 5), CFrame.new(pos) * CFrame.Angles(math.rad(i * 7), math.rad(i * 21), math.rad(i * 11)), Color3.fromRGB(42, 34, 61), Enum.Material.Slate, 0)
		local glow = part(folder, "VoidGlyph", Vector3.new(5.8, 0.45, 5.8), stone.CFrame * CFrame.new(0, 5.2, 0), violet, Enum.Material.Neon, 0.08)
		light(glow, violet, 1.6, 13)
	end
	verticalBeam(folder, "VoidBeacon", c + Vector3.new(0, 3, -49), 26, Color3.fromRGB(185, 80, 255), 2)
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
