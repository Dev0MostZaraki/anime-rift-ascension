local Workspace = game:GetService("Workspace")

local OpenWorldExpansionService = {}
OpenWorldExpansionService.__index = OpenWorldExpansionService

function OpenWorldExpansionService.new(context)
	return setmetatable({
		Context = context,
		Claims = {},
	}, OpenWorldExpansionService)
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

local function label(parent, text, offset, maxDistance)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 220, 0, 52)
	gui.StudsOffset = offset or Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = maxDistance or 42
	gui.LightInfluence = 0
	gui.Parent = parent
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = Color3.fromRGB(239, 235, 222)
	l.TextStrokeTransparency = 0.72
	l.TextScaled = true
	l.TextWrapped = true
	l.Font = Enum.Font.GothamBold
	l.Parent = gui
	return gui
end

local function prompt(parent, actionText, objectText, hold)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = actionText
	p.ObjectText = objectText
	p.HoldDuration = hold or 0.28
	p.MaxActivationDistance = 11
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = Enum.KeyCode.F
	p.Parent = parent
	return p
end

local function beam(parent, name, a, b, width, color, material)
	local delta = b - a
	if delta.Magnitude < 0.5 then return nil end
	local mid = a:Lerp(b, 0.5)
	return part(parent, name, Vector3.new(width, width, delta.Magnitude), CFrame.lookAt(mid, b), color, material or Enum.Material.Wood)
end

local function trail(parent, points, width, color, material)
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local delta = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		if delta.Magnitude > 1 then
			local mid = a:Lerp(b, 0.5)
			part(parent, "RegionTrail", Vector3.new(width or 7, 0.24, delta.Magnitude + 1.4), CFrame.lookAt(Vector3.new(mid.X, 2.14, mid.Z), Vector3.new(mid.X, 2.14, mid.Z) + delta.Unit), color or Color3.fromRGB(112, 97, 78), material or Enum.Material.Ground, 0, true)
		end
	end
end

local function rock(parent, pos, size, color, material)
	return part(parent, "RegionRock", size, CFrame.new(pos) * CFrame.Angles(math.rad(8), math.rad((pos.X + pos.Z) % 55), math.rad(6)), color, material or Enum.Material.Rock)
end

local function pine(parent, pos, scale, snowy)
	part(parent, "PineTrunk", Vector3.new(1.4 * scale, 8.5 * scale, 1.4 * scale), CFrame.new(pos + Vector3.new(0, 4.25 * scale, 0)), Color3.fromRGB(78, 62, 49), Enum.Material.Wood)
	local green = snowy and Color3.fromRGB(67, 91, 83) or Color3.fromRGB(58, 88, 69)
	for i = 1, 3 do
		local crown = ball(parent, "PineCrown", (6.4 - i * 0.9) * scale, pos + Vector3.new(0, (5.8 + i * 2.1) * scale, 0), green:Lerp(Color3.fromRGB(216, 224, 224), snowy and (0.08 * i) or 0.02), Enum.Material.Grass, false)
		crown.CanQuery = false
	end
end

local function deadTree(parent, pos, scale)
	local c = Color3.fromRGB(62, 56, 60)
	part(parent, "DeadTree", Vector3.new(1.5 * scale, 10.5 * scale, 1.5 * scale), CFrame.new(pos + Vector3.new(0, 5.25 * scale, 0)) * CFrame.Angles(0, 0, math.rad(7)), c, Enum.Material.Wood)
	part(parent, "DeadBranch", Vector3.new(0.7 * scale, 5.4 * scale, 0.7 * scale), CFrame.new(pos + Vector3.new(2 * scale, 7.6 * scale, 0)) * CFrame.Angles(0, 0, math.rad(-48)), c, Enum.Material.Wood, 0, false)
	part(parent, "DeadBranch", Vector3.new(0.65 * scale, 4.7 * scale, 0.65 * scale), CFrame.new(pos + Vector3.new(-1.8 * scale, 7.2 * scale, 0.5)) * CFrame.Angles(0, 0, math.rad(50)), c, Enum.Material.Wood, 0, false)
end

local function lantern(parent, pos, cold)
	part(parent, "RoadLanternPost", Vector3.new(0.45, 4.8, 0.45), CFrame.new(pos + Vector3.new(0, 2.4, 0)), Color3.fromRGB(66, 55, 47), Enum.Material.Wood)
	local lamp = part(parent, "RoadLantern", Vector3.new(1.05, 1.2, 1.05), CFrame.new(pos + Vector3.new(0, 4.75, 0)), cold and Color3.fromRGB(188, 211, 219) or Color3.fromRGB(226, 176, 104), Enum.Material.Glass, 0.28, false)
	local light = Instance.new("PointLight")
	light.Color = cold and Color3.fromRGB(188, 218, 231) or Color3.fromRGB(247, 187, 112)
	light.Brightness = 0.38
	light.Range = 8
	light.Shadows = true
	light.Parent = lamp
end

local function arch(parent, center, width, height, color, material)
	for _, x in ipairs({-width / 2, width / 2}) do
		part(parent, "ArchPillar", Vector3.new(3.2, height, 3.2), CFrame.new(center + Vector3.new(x, height / 2, 0)), color, material or Enum.Material.Slate)
	end
	part(parent, "ArchBeam", Vector3.new(width + 5, 3.2, 3.5), CFrame.new(center + Vector3.new(0, height, 0)), color, material or Enum.Material.Slate)
end

function OpenWorldExpansionService:ConfigureStreaming()
	local cfg = self.Context.Config.Game
	pcall(function() Workspace.StreamingEnabled = true end)
	pcall(function() Workspace.StreamingMinRadius = cfg.StreamingMinRadius or 128 end)
	pcall(function() Workspace.StreamingTargetRadius = cfg.StreamingTargetRadius or 384 end)
end

function OpenWorldExpansionService:SculptRegionTerrain()
	local terrain = Workspace.Terrain
	local ember = self.Context.Config.Zones[2].Center
	local frost = self.Context.Config.Zones[3].Center
	local void = self.Context.Config.Zones[4].Center

	-- Ember: raised broken ridges around a lower travel corridor.
	for i, data in ipairs({
		{ember + Vector3.new(-82,-14,-55), 28}, {ember + Vector3.new(78,-13,-48), 31},
		{ember + Vector3.new(-74,-15,58), 32}, {ember + Vector3.new(83,-14,62), 29},
		{ember + Vector3.new(18,-16,92), 25}, {ember + Vector3.new(65,-16,8), 22},
	}) do
		terrain:FillBall(data[1], data[2], i % 3 == 0 and Enum.Material.Basalt or Enum.Material.Rock)
	end
	for _, patch in ipairs({
		{ember + Vector3.new(-36,-0.6,-20), Vector3.new(38,4,26), Enum.Material.Ground},
		{ember + Vector3.new(32,-0.6,20), Vector3.new(44,4,30), Enum.Material.Basalt},
		{ember + Vector3.new(-8,-0.7,58), Vector3.new(36,4,26), Enum.Material.Ground},
	}) do terrain:FillBlock(CFrame.new(patch[1]), patch[2], patch[3]) end

	-- Frost: long snow ridges and a shallow frozen basin.
	for i, data in ipairs({
		{frost + Vector3.new(-88,-13,-35), 28}, {frost + Vector3.new(87,-13,-42), 30},
		{frost + Vector3.new(-72,-14,62), 29}, {frost + Vector3.new(76,-14,68), 31},
		{frost + Vector3.new(5,-15,-88), 27}, {frost + Vector3.new(58,-15,14), 23},
	}) do
		terrain:FillBall(data[1], data[2], i % 3 == 0 and Enum.Material.Rock or Enum.Material.Snow)
	end
	terrain:FillBlock(CFrame.new(frost + Vector3.new(42, 0.2, 18)), Vector3.new(34, 6, 28), Enum.Material.Air)
	terrain:FillBlock(CFrame.new(frost + Vector3.new(42, -1.7, 18)), Vector3.new(31, 3.2, 25), Enum.Material.Water)

	-- Void: low basalt shoulders and depressions create broken sight lines without neon spam.
	for i, data in ipairs({
		{void + Vector3.new(-84,-13,-48), 29}, {void + Vector3.new(81,-14,-54), 31},
		{void + Vector3.new(-78,-14,60), 27}, {void + Vector3.new(76,-13,66), 30},
		{void + Vector3.new(-14,-15,-92), 26}, {void + Vector3.new(57,-15,9), 22},
	}) do
		terrain:FillBall(data[1], data[2], i % 2 == 0 and Enum.Material.Basalt or Enum.Material.Rock)
	end
	for _, patch in ipairs({
		{void + Vector3.new(-30,-0.7,20), Vector3.new(34,4,28)},
		{void + Vector3.new(34,-0.7,-18), Vector3.new(42,4,24)},
	}) do terrain:FillBlock(CFrame.new(patch[1]), patch[2], Enum.Material.Basalt) end
end

function OpenWorldExpansionService:BuildEmber(folder)
	local c = self.Context.Config.Zones[2].Center
	trail(folder, {
		Vector3.new(78,2.15,24), Vector3.new(111,2.15,31), Vector3.new(142,2.15,43),
		Vector3.new(166,2.15,55), c + Vector3.new(-20,2.15,-5), c + Vector3.new(0,2.15,10),
	}, 7.5, Color3.fromRGB(113, 89, 72), Enum.Material.Ground)
	arch(folder, c + Vector3.new(-49,2.2,-16), 20, 12, Color3.fromRGB(92, 71, 62), Enum.Material.Brick)
	local gateMarker = part(folder, "EmberGateMarker", Vector3.new(3,7,3), CFrame.new(c + Vector3.new(-49,5.5,-13)), Color3.fromRGB(84,69,62), Enum.Material.Slate)
	label(gateMarker, "ASHEN APPROACH", Vector3.new(0,5.5,0), 38)

	-- Ronin camp.
	local camp = c + Vector3.new(-43,2.2,19)
	part(folder, "RoninCampGround", Vector3.new(32,0.35,25), CFrame.new(camp), Color3.fromRGB(106,84,69), Enum.Material.Ground)
	for _, x in ipairs({-10,10}) do
		part(folder, "RoninTent", Vector3.new(10,0.7,12), CFrame.new(camp + Vector3.new(x,4.8,-4)) * CFrame.Angles(0,0,math.rad(x > 0 and -13 or 13)), Color3.fromRGB(118,78,64), Enum.Material.Fabric, 0, false)
	end
	local fire = part(folder, "RoninFire", Vector3.new(2,0.6,2), CFrame.new(camp + Vector3.new(0,0.6,5)), Color3.fromRGB(171,91,52), Enum.Material.Neon, 0.45, false)
	local flame = Instance.new("Fire")
	flame.Color = Color3.fromRGB(231,142,77)
	flame.SecondaryColor = Color3.fromRGB(151,67,42)
	flame.Size = 2.8
	flame.Parent = fire

	-- Forge quarter.
	local forge = c + Vector3.new(2,2.2,-45)
	part(folder, "ForgeYard", Vector3.new(46,0.5,31), CFrame.new(forge), Color3.fromRGB(91,72,64), Enum.Material.Brick)
	for _, x in ipairs({-17,17}) do
		part(folder, "ForgeStack", Vector3.new(9,17,9), CFrame.new(forge + Vector3.new(x,8.8,-6)), Color3.fromRGB(76,62,58), Enum.Material.Brick)
	end
	local furnace = part(folder, "ForgeCore", Vector3.new(9,4.5,0.5), CFrame.new(forge + Vector3.new(0,3.6,-15.7)), Color3.fromRGB(179,84,47), Enum.Material.Neon, 0.32, false)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(223,123,69)
	glow.Brightness = 0.55
	glow.Range = 9
	glow.Parent = furnace

	-- Quarry/overlook landmarks.
	local quarry = c + Vector3.new(49,2.1,30)
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		local pos = quarry + Vector3.new(math.cos(angle) * 18, 2.5 + (i % 3), math.sin(angle) * 14)
		rock(folder, pos, Vector3.new(7 + i % 3, 6 + i % 4, 6), Color3.fromRGB(82,69,64), Enum.Material.Rock)
	end
	local overlook = part(folder, "CinderOverlook", Vector3.new(18,1,14), CFrame.new(c + Vector3.new(18,2.5,61)), Color3.fromRGB(94,78,68), Enum.Material.Slate)
	label(overlook, "CINDER OVERLOOK", Vector3.new(0,5,0), 34)

	for _, pos in ipairs({c+Vector3.new(-28,2,0), c+Vector3.new(-8,2,-24), c+Vector3.new(22,2,-18), c+Vector3.new(36,2,17)}) do lantern(folder, pos, false) end
end

function OpenWorldExpansionService:BuildFrost(folder)
	local c = self.Context.Config.Zones[3].Center
	trail(folder, {
		Vector3.new(30,2.15,-76), Vector3.new(42,2.15,-111), Vector3.new(52,2.15,-138),
		Vector3.new(62,2.15,-162), c + Vector3.new(-10,2.15,20), c + Vector3.new(0,2.15,2),
	}, 7.5, Color3.fromRGB(151,145,132), Enum.Material.Cobblestone)
	arch(folder, c + Vector3.new(-17,2.2,52), 20, 12, Color3.fromRGB(115,126,132), Enum.Material.Slate)
	local pass = part(folder, "FrostPassMarker", Vector3.new(3,7,3), CFrame.new(c + Vector3.new(-17,5.5,55)), Color3.fromRGB(105,116,122), Enum.Material.Slate)
	label(pass, "FROSTFALL PASS", Vector3.new(0,5.5,0), 38)

	local random = Random.new(4303)
	for _ = 1, 34 do
		local x = random:NextNumber(-95,95)
		local z = random:NextNumber(-86,86)
		if x > 28 and x < 58 and z > 2 and z < 35 then continue end
		pine(folder, c + Vector3.new(x,2,z), random:NextNumber(0.68,1.05), true)
	end

	-- Frozen basin / crossing.
	local lake = c + Vector3.new(42,2,18)
	local ice = part(folder, "FrozenLake", Vector3.new(31,0.45,25), CFrame.new(lake + Vector3.new(0,0.1,0)), Color3.fromRGB(176,204,213), Enum.Material.Glass, 0.35, true)
	ice.CastShadow = false
	for _, offset in ipairs({Vector3.new(-20,2,-12),Vector3.new(18,2,13),Vector3.new(20,2,-10),Vector3.new(-18,2,12)}) do
		rock(folder, lake + offset, Vector3.new(7,5,6), Color3.fromRGB(137,149,154), Enum.Material.Rock)
	end

	-- Warden watch and citadel approach.
	local watch = c + Vector3.new(-43,2.2,20)
	part(folder, "WardenWatchBase", Vector3.new(24,1,20), CFrame.new(watch), Color3.fromRGB(117,122,120), Enum.Material.Slate)
	for _, x in ipairs({-8,8}) do part(folder, "WardenWatchPost", Vector3.new(2,13,2), CFrame.new(watch + Vector3.new(x,7,0)), Color3.fromRGB(92,102,106), Enum.Material.Slate) end
	beam(folder, "WardenWatchBeam", watch + Vector3.new(-8,13,0), watch + Vector3.new(8,13,0), 1.4, Color3.fromRGB(94,105,109), Enum.Material.Slate)

	local citadel = c + Vector3.new(0,2.2,-58)
	arch(folder, citadel, 34, 18, Color3.fromRGB(101,112,118), Enum.Material.Slate)
	for _, x in ipairs({-24,24}) do
		part(folder, "CitadelTower", Vector3.new(11,24,11), CFrame.new(citadel + Vector3.new(x,12,0)), Color3.fromRGB(96,107,113), Enum.Material.Slate)
	end
	label(part(folder, "CitadelMarker", Vector3.new(2.5,6,2.5), CFrame.new(citadel + Vector3.new(0,6,6)), Color3.fromRGB(104,116,122), Enum.Material.Slate), "THE OLD CITADEL", Vector3.new(0,5,0), 42)

	for _, pos in ipairs({c+Vector3.new(-24,2,43), c+Vector3.new(-7,2,18), c+Vector3.new(12,2,-8), c+Vector3.new(6,2,-38)}) do lantern(folder, pos, true) end
end

function OpenWorldExpansionService:BuildVoid(folder)
	local c = self.Context.Config.Zones[4].Center
	trail(folder, {
		Vector3.new(-78,2.15,-23), Vector3.new(-111,2.15,-33), Vector3.new(-139,2.15,-45),
		Vector3.new(-163,2.15,-58), c + Vector3.new(26,2.15,8), c + Vector3.new(8,2.15,-5),
	}, 7, Color3.fromRGB(86,82,82), Enum.Material.Basalt)

	-- Ruined entry arch.
	arch(folder, c + Vector3.new(45,2.2,18), 22, 13, Color3.fromRGB(70,66,73), Enum.Material.Slate)
	local entry = part(folder, "VoidEntryMarker", Vector3.new(3,7,3), CFrame.new(c + Vector3.new(45,5.5,21)), Color3.fromRGB(68,64,72), Enum.Material.Slate)
	label(entry, "THE SILENT SCAR", Vector3.new(0,5.5,0), 38)

	local random = Random.new(4304)
	for _ = 1, 26 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(42,92)
		deadTree(folder, c + Vector3.new(math.cos(angle)*radius,2,math.sin(angle)*radius), random:NextNumber(0.7,1.08))
	end

	-- Silent ruins.
	local ruins = c + Vector3.new(36,2.2,-12)
	part(folder, "SilentRuinFloor", Vector3.new(38,0.7,28), CFrame.new(ruins), Color3.fromRGB(68,64,70), Enum.Material.Slate)
	for _, offset in ipairs({Vector3.new(-14,7,-9),Vector3.new(13,5,-9),Vector3.new(-12,4,9),Vector3.new(15,8,8)}) do
		part(folder, "BrokenRuinPillar", Vector3.new(4,offset.Y,4), CFrame.new(ruins + Vector3.new(offset.X,offset.Y/2,offset.Z)) * CFrame.Angles(0,0,math.rad(offset.X > 0 and 4 or -5)), Color3.fromRGB(65,61,69), Enum.Material.Slate)
	end

	-- Observatory on the western shoulder.
	local obs = c + Vector3.new(-42,2.2,-8)
	local base = part(folder, "VoidObservatory", Vector3.new(30,1.0,26), CFrame.new(obs), Color3.fromRGB(66,62,69), Enum.Material.Basalt)
	label(base, "FALLEN OBSERVATORY", Vector3.new(0,6,0), 36)
	for i = 1, 7 do
		local angle = (i/7)*math.pi*2
		local pos = obs + Vector3.new(math.cos(angle)*12,6,math.sin(angle)*10)
		part(folder, "ObservatoryStone", Vector3.new(3.3,12,3.3), CFrame.new(pos) * CFrame.Angles(math.rad((i%2)*3),-angle,math.rad((i%3-1)*4)), Color3.fromRGB(61,58,66), Enum.Material.Slate)
	end

	-- Boss ascent gives the Tyrant arena a readable destination from a distance.
	local boss = c + Vector3.new(0,2.2,-34)
	for step = 1, 6 do
		part(folder, "BossAscentStep", Vector3.new(26,0.65,5), CFrame.new(c + Vector3.new(0,2.1 + step*0.36,-5 - step*5)), Color3.fromRGB(72,67,75), Enum.Material.Slate)
	end
	for i = 1, 8 do
		local angle = (i/8)*math.pi*2
		local pos = boss + Vector3.new(math.cos(angle)*31,5,math.sin(angle)*31)
		local monolith = part(folder, "BossMonolith", Vector3.new(4,10 + (i%3)*2,4), CFrame.new(pos) * CFrame.Angles(0,-angle,math.rad((i%2==0) and 3 or -3)), Color3.fromRGB(60,57,65), Enum.Material.Basalt)
		if i % 4 == 0 then
			local rune = part(folder, "BossRuneAccent", Vector3.new(0.4,2.8,0.18), monolith.CFrame * CFrame.new(0,0.5,-2.05), Color3.fromRGB(112,86,124), Enum.Material.Glass, 0.25, false)
			local l = Instance.new("PointLight")
			l.Color = rune.Color
			l.Brightness = 0.18
			l.Range = 5
			l.Parent = rune
		end
	end
end

function OpenWorldExpansionService:ClaimKey(player, id)
	local key = tostring(player.UserId) .. ":" .. id
	if self.Claims[key] then return false end
	self.Claims[key] = true
	return true
end

function OpenWorldExpansionService:BuildCache(parent, id, pos, zoneId, hidden)
	local model = Instance.new("Model")
	model.Name = "RegionCache_" .. id
	model.Parent = parent
	local wood = hidden and Color3.fromRGB(82,70,57) or Color3.fromRGB(106,78,54)
	local base = part(model, "CacheBase", Vector3.new(5,2.1,3.3), CFrame.new(pos + Vector3.new(0,1.05,0)), wood, Enum.Material.WoodPlanks)
	part(model, "CacheLid", Vector3.new(5.2,0.9,3.5), CFrame.new(pos + Vector3.new(0,2.6,-0.1)) * CFrame.Angles(math.rad(-7),0,0), wood:Lerp(Color3.fromRGB(148,111,72),0.22), Enum.Material.WoodPlanks)
	part(model, "CacheBand", Vector3.new(0.6,3.2,3.6), CFrame.new(pos + Vector3.new(0,1.7,0)), Color3.fromRGB(85,80,72), Enum.Material.Metal)
	prompt(base, "Open", hidden and "Hidden Cache" or "Expedition Cache", 0.35).Triggered:Connect(function(player)
		if not self:ClaimKey(player, id) then
			self.Context:Notify(player, "You already searched this cache during this journey.", "info")
			return
		end
		local stats = player:FindFirstChild("leaderstats")
		if not stats then return end
		local scale = 1 + (zoneId - 1) * 0.7
		local coins = math.floor(math.random(hidden and 260 or 120, hidden and 420 or 230) * scale)
		local gems = hidden and math.random(2, 4 + zoneId) or (math.random() < 0.35 and math.max(1, zoneId - 1) or 0)
		stats.Coins.Value += coins
		stats.Gems.Value += gems
		self.Context.Services.DataService:AddXP(player, math.floor((hidden and 130 or 65) * scale))
		self.Context:Notify(player, "EXPEDITION CACHE • +" .. coins .. " Coins" .. (gems > 0 and (" • +" .. gems .. " Gems") or ""), "loot")
		base.Color = Color3.fromRGB(69,66,60)
	end)
end

function OpenWorldExpansionService:BuildExploration(folder)
	local e = self.Context.Config.Zones[2].Center
	local f = self.Context.Config.Zones[3].Center
	local v = self.Context.Config.Zones[4].Center
	for _, data in ipairs({
		{"ember_camp", e+Vector3.new(-54,2.2,28),2,false}, {"ember_forge",e+Vector3.new(18,2.2,-54),2,false}, {"ember_quarry",e+Vector3.new(60,2.2,36),2,true}, {"ember_overlook",e+Vector3.new(10,3.2,68),2,true},
		{"frost_watch",f+Vector3.new(-52,2.2,25),3,false}, {"frost_lake",f+Vector3.new(61,2.2,22),3,false}, {"frost_citadel",f+Vector3.new(-18,2.2,-66),3,true}, {"frost_ridge",f+Vector3.new(62,2.2,-49),3,true},
		{"void_ruins",v+Vector3.new(50,2.2,-4),4,false}, {"void_observatory",v+Vector3.new(-55,2.2,0),4,true}, {"void_ascent",v+Vector3.new(24,2.2,-49),4,false}, {"void_farstone",v+Vector3.new(-66,2.2,-52),4,true},
	}) do self:BuildCache(folder, data[1], data[2], data[3], data[4]) end
end

function OpenWorldExpansionService:GetEnemySpawn(zoneId, index, boss)
	local zone = self.Context.Config.Zones[zoneId]
	if not zone then return nil end
	if boss then return zone.Center + Vector3.new(0,8,-34) end
	local offsets = {
		[2] = {
			Vector3.new(-46,6,18), Vector3.new(-31,6,7), Vector3.new(-20,6,-42),
			Vector3.new(15,6,-49), Vector3.new(47,6,-19), Vector3.new(51,6,27), Vector3.new(-33,6,45),
		},
		[3] = {
			Vector3.new(-44,6,20), Vector3.new(-27,6,-27), Vector3.new(0,6,-49),
			Vector3.new(31,6,-37), Vector3.new(49,6,13), Vector3.new(27,6,43), Vector3.new(-39,6,45),
		},
		[4] = {
			Vector3.new(-42,6,17), Vector3.new(-29,6,-27), Vector3.new(0,6,-55),
			Vector3.new(34,6,-41), Vector3.new(49,6,-6), Vector3.new(28,6,42), Vector3.new(-36,6,43),
		},
	}
	local list = offsets[zoneId]
	if not list then return nil end
	return zone.Center + list[((index - 1) % #list) + 1]
end

function OpenWorldExpansionService:GetSecretEggPositions()
	local e = self.Context.Config.Zones[2].Center
	local f = self.Context.Config.Zones[3].Center
	local v = self.Context.Config.Zones[4].Center
	return {
		e + Vector3.new(62,4,-42), e + Vector3.new(-68,4,51), e + Vector3.new(32,4,73),
		f + Vector3.new(67,4,47), f + Vector3.new(-61,4,-41), f + Vector3.new(-46,4,66),
		v + Vector3.new(65,4,45), v + Vector3.new(-62,4,-48), v + Vector3.new(-56,4,59),
	}
end

function OpenWorldExpansionService:Start()
	self:ConfigureStreaming()
	self:SculptRegionTerrain()
	local old = self.Context.WorldFolder:FindFirstChild("OpenWorldExpansion")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "OpenWorldExpansion"
	folder.Parent = self.Context.WorldFolder
	self:BuildEmber(folder)
	self:BuildFrost(folder)
	self:BuildVoid(folder)
	self:BuildExploration(folder)
end

return OpenWorldExpansionService
