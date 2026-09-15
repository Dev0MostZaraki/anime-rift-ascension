local EnemyVisualService = {}
EnemyVisualService.__index = EnemyVisualService

function EnemyVisualService.new(context)
	return setmetatable({Context = context}, EnemyVisualService)
end

local function visual(folder, name, size, cf, color, material, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local function wedge(folder, name, size, cf, color, material, transparency)
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color
	p.Transparency = transparency or 0
	p.Parent = folder
	return p
end

local function light(parent, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = parent
end

local function hidePrototype(model)
	for _, name in ipairs({"HumanoidRootPart", "Head", "LeftAura", "RightAura", "Shield", "VoidHalo", "Crown"}) do
		local p = model:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			p.Transparency = 1
			if p.Name ~= "HumanoidRootPart" then p.CanCollide = false end
		end
	end
end

local function hairSpikes(folder, base, color, scale, wild)
	local count = wild and 7 or 5
	for i = 1, count do
		local angle = ((i - 1) / count) * math.pi * 2
		local radius = 0.72 * scale
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local spike = wedge(folder, "Hair", Vector3.new(0.9, 2.0 + (i % 2) * 0.5, 0.9) * scale,
			base * CFrame.new(x, 4.75 * scale, z) * CFrame.Angles(math.rad(-16 + (i % 3) * 9), angle, math.rad((i % 2 == 0) and 18 or -18)),
			color, Enum.Material.SmoothPlastic, 0)
		spike.CastShadow = true
	end
end

local function sword(folder, base, side, color, scale, long)
	local x = side * 2.45 * scale
	local bladeLength = (long and 6.0 or 4.8) * scale
	visual(folder, "SwordBlade", Vector3.new(0.28, bladeLength, 0.65 * scale), base * CFrame.new(x, -0.2 * scale, -0.6 * scale) * CFrame.Angles(math.rad(-16), 0, math.rad(side * -10)), color, Enum.Material.Metal, 0)
	visual(folder, "SwordEdge", Vector3.new(0.12, bladeLength * 0.92, 0.18 * scale), base * CFrame.new(x - side * 0.19 * scale, -0.2 * scale, -0.95 * scale) * CFrame.Angles(math.rad(-16), 0, math.rad(side * -10)), color:Lerp(Color3.new(1,1,1),0.55), Enum.Material.Neon, 0.12)
	visual(folder, "SwordGrip", Vector3.new(0.55, 1.4, 0.55) * scale, base * CFrame.new(x, -3.25 * scale, -0.1 * scale), Color3.fromRGB(45,39,45), Enum.Material.Fabric, 0)
end

local function humanoidSilhouette(folder, base, color, dark, scale, skin, hairColor, boss)
	-- The real CombatService root remains the hitbox. These are visuals only.
	visual(folder, "Torso", Vector3.new(3.15, 4.25, 1.75) * scale, base * CFrame.new(0, 0.45 * scale, 0), dark, Enum.Material.SmoothPlastic, 0)
	visual(folder, "ChestLayer", Vector3.new(3.32, 2.0, 1.86) * scale, base * CFrame.new(0, 1.05 * scale, -0.02 * scale), color:Lerp(dark,0.35), Enum.Material.Fabric, 0)
	visual(folder, "Waist", Vector3.new(3.0, 1.05, 1.8) * scale, base * CFrame.new(0, -2.15 * scale, 0), Color3.fromRGB(43,40,49), Enum.Material.Fabric, 0)

	for _, side in ipairs({-1,1}) do
		visual(folder, "Arm", Vector3.new(1.0, 3.9, 1.05) * scale, base * CFrame.new(side * 2.05 * scale, 0.15 * scale, 0) * CFrame.Angles(0,0,math.rad(side * -4)), skin, Enum.Material.SmoothPlastic, 0)
		visual(folder, "Sleeve", Vector3.new(1.2, 2.35, 1.25) * scale, base * CFrame.new(side * 2.05 * scale, 1.0 * scale, 0), dark, Enum.Material.Fabric, 0)
		visual(folder, "Leg", Vector3.new(1.2, 4.25, 1.35) * scale, base * CFrame.new(side * 0.82 * scale, -4.25 * scale, 0), Color3.fromRGB(36,36,45), Enum.Material.Fabric, 0)
		visual(folder, "Boot", Vector3.new(1.35, 1.5, 1.85) * scale, base * CFrame.new(side * 0.82 * scale, -6.45 * scale, -0.25 * scale), Color3.fromRGB(31,29,36), Enum.Material.SmoothPlastic, 0)
	end

	local head = visual(folder, "Face", Vector3.new(2.35,2.35,2.35) * scale, base * CFrame.new(0,3.55 * scale,0), skin, Enum.Material.SmoothPlastic, 0)
	head.Shape = Enum.PartType.Ball
	hairSpikes(folder, base, hairColor, scale, boss)

	-- A small luminous eye-band reads much better at Roblox gameplay distance than tiny facial details.
	local eyes = visual(folder, "Eyes", Vector3.new(1.45,0.26,0.18) * scale, base * CFrame.new(0,3.58 * scale,-1.13 * scale), color:Lerp(Color3.new(1,1,1),0.38), Enum.Material.Neon, 0.08)
	light(eyes, color, boss and 0.55 or 0.16, boss and 10 or 5)
	return head
end

function EnemyVisualService:Decorate(model, data)
	if not model or not model.Parent or not model.PrimaryPart or model:GetAttribute("VisualDecorated") then return end

	-- Imported character art always wins. Procedural art is now a deliberate stylized fallback,
	-- not a visible blockout.
	local art = self.Context.Services.CreatureArtService
	if art and art:TryApplyEnemy(model, data) then
		model:SetAttribute("VisualDecorated", true)
		return
	end

	model:SetAttribute("VisualDecorated", true)
	hidePrototype(model)
	local folder = Instance.new("Folder")
	folder.Name = "VisualRig"
	folder.Parent = model

	local base = model.PrimaryPart.CFrame
	local color = data.Boss and Color3.fromRGB(221,76,150) or data.Zone.Color:Lerp(Color3.new(1,1,1),0.05)
	local dark = color:Lerp(Color3.fromRGB(25,24,34),0.77)
	local metal = color:Lerp(Color3.fromRGB(74,76,89),0.68)
	local scale = data.Boss and 1.42 or 1
	local skin = data.Boss and Color3.fromRGB(201,175,183) or Color3.fromRGB(222,190,171)
	local hair = data.Boss and Color3.fromRGB(38,29,45) or dark:Lerp(color,0.18)
	local head = humanoidSilhouette(folder, base, color, dark, scale, skin, hair, data.Boss)

	local highlight = Instance.new("Highlight")
	highlight.Name = "AnimeOutline"
	highlight.Adornee = model
	highlight.FillTransparency = 1
	highlight.OutlineColor = color:Lerp(Color3.new(1,1,1),0.18)
	highlight.OutlineTransparency = data.Boss and 0.32 or 0.68
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model

	-- Rarity/archetype silhouette language.
	if data.Boss then
		for _, side in ipairs({-1,1}) do
			visual(folder,"TyrantPauldron",Vector3.new(3.0,1.45,2.5),base*CFrame.new(side*2.65*scale,1.9*scale,0)*CFrame.Angles(0,0,math.rad(side*-18)),metal,Enum.Material.Metal,0)
			wedge(folder,"TyrantHorn",Vector3.new(1.25,4.4,1.25),base*CFrame.new(side*1.2*scale,6.05*scale,0.1)*CFrame.Angles(0,0,math.rad(side*-24)),Color3.fromRGB(75,63,86),Enum.Material.Slate,0)
		end
		visual(folder,"Mantle",Vector3.new(7.6,5.3,0.35),base*CFrame.new(0,0.1*scale,1.25*scale)*CFrame.Angles(math.rad(7),0,0),Color3.fromRGB(54,36,62),Enum.Material.Fabric,0.04)
		local core = visual(folder,"TyrantCore",Vector3.new(1.7,1.7,0.32),base*CFrame.new(0,1.0*scale,-1.08*scale),Color3.fromRGB(255,115,192),Enum.Material.Neon,0.05)
		core.Shape = Enum.PartType.Ball
		light(core,color,0.9,14)
		sword(folder,base,-1,color,scale,true)
		sword(folder,base,1,color:Lerp(Color3.fromRGB(95,210,245),0.25),scale,true)
		return
	end

	if data.Archetype == "Brawler" then
		visual(folder,"Headband",Vector3.new(2.7,0.34,2.75),base*CFrame.new(0,4.08,0),Color3.fromRGB(73,116,79),Enum.Material.Fabric,0)
		for _, side in ipairs({-1,1}) do visual(folder,"HandWrap",Vector3.new(1.16,1.2,1.16),base*CFrame.new(side*2.05,-1.55,0),Color3.fromRGB(220,213,191),Enum.Material.Fabric,0) end
	elseif data.Archetype == "Charger" then
		visual(folder,"LongCoat",Vector3.new(3.7,4.6,0.3),base*CFrame.new(0,-2.5,0.92)*CFrame.Angles(math.rad(7),0,0),Color3.fromRGB(79,43,38),Enum.Material.Fabric,0.02)
		visual(folder,"EmberSash",Vector3.new(3.5,0.5,1.95),base*CFrame.new(0,-1.7,0),Color3.fromRGB(207,88,48),Enum.Material.Fabric,0)
		sword(folder,base,1,Color3.fromRGB(218,122,73),1,false)
	elseif data.Archetype == "Guardian" then
		for _, side in ipairs({-1,1}) do visual(folder,"FrostPauldron",Vector3.new(2.1,1.25,2.2),base*CFrame.new(side*2.45,1.85,0)*CFrame.Angles(0,0,math.rad(side*-16)),metal:Lerp(Color3.fromRGB(184,220,235),0.30),Enum.Material.Ice,0.08) end
		local shield = visual(folder,"IceShield",Vector3.new(0.55,5.0,4.1),base*CFrame.new(-3.05,-0.1,-0.25)*CFrame.Angles(0,0,math.rad(-5)),Color3.fromRGB(146,205,228),Enum.Material.Glass,0.15)
		light(shield,Color3.fromRGB(122,200,240),0.28,7)
	elseif data.Archetype == "Blinker" then
		visual(folder,"VoidCape",Vector3.new(4.8,5.6,0.26),base*CFrame.new(0,-1.0,1.12)*CFrame.Angles(math.rad(8),0,0),Color3.fromRGB(48,38,58),Enum.Material.Fabric,0.04)
		visual(folder,"FaceMask",Vector3.new(1.8,1.0,0.2),base*CFrame.new(0,3.25,-1.17),Color3.fromRGB(38,33,47),Enum.Material.Metal,0)
		-- Scythe: long staff plus a curved-looking wedge blade silhouette.
		visual(folder,"ScytheStaff",Vector3.new(0.36,7.2,0.36),base*CFrame.new(2.75,-0.8,0)*CFrame.Angles(0,0,math.rad(-10)),Color3.fromRGB(47,42,52),Enum.Material.Metal,0)
		wedge(folder,"ScytheBlade",Vector3.new(4.0,1.05,1.2),base*CFrame.new(3.55,2.55,-0.25)*CFrame.Angles(0,math.rad(10),math.rad(18)),color:Lerp(Color3.new(1,1,1),0.20),Enum.Material.Neon,0.06)
		local eye = visual(folder,"VoidEye",Vector3.new(0.75,0.75,0.22),base*CFrame.new(0,3.55,-1.23),color:Lerp(Color3.new(1,1,1),0.35),Enum.Material.Neon,0)
		eye.Shape = Enum.PartType.Ball
		light(eye,color,0.45,8)
	end

	if head then head.CastShadow = true end
end

function EnemyVisualService:Start()
	task.spawn(function()
		while self.Context.WorldFolder and self.Context.WorldFolder.Parent do
			for model, data in pairs(self.Context.Services.CombatService.Enemies) do
				if data.Alive and model.Parent and not model:GetAttribute("VisualDecorated") then self:Decorate(model,data) end
			end
			task.wait(0.2)
		end
	end)
end

return EnemyVisualService
