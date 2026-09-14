local EnemyVisualService = {}
EnemyVisualService.__index = EnemyVisualService

function EnemyVisualService.new(context)
	return setmetatable({Context = context}, EnemyVisualService)
end

local function visual(model, folder, name, size, cf, color, material, transparency)
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
	p.Parent = folder or model
	return p
end

local function addLight(parent, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = parent
end

local function addPauldron(model, folder, base, x, color, scale)
	return visual(model, folder, "Pauldron", Vector3.new(1.9 * scale, 1.1 * scale, 2.2 * scale), base * CFrame.new(x, 2.15 * scale, 0) * CFrame.Angles(0, 0, math.rad(x > 0 and -18 or 18)), color, Enum.Material.Metal)
end

function EnemyVisualService:Decorate(model, data)
	if not model or not model.Parent or not model.PrimaryPart or model:GetAttribute("VisualDecorated") then return end

	-- 4.4 art pipeline: imported Blender/Roblox models take priority. If no matching
	-- asset exists, the old procedural silhouette remains as a safe development fallback.
	local art = self.Context.Services.CreatureArtService
	if art and art:TryApplyEnemy(model, data) then
		model:SetAttribute("VisualDecorated", true)
		return
	end

	model:SetAttribute("VisualDecorated", true)
	local folder = Instance.new("Folder")
	folder.Name = "VisualRig"
	folder.Parent = model

	local base = model.PrimaryPart.CFrame
	local color = data.Boss and Color3.fromRGB(187, 88, 132) or data.Zone.Color
	local dark = color:Lerp(Color3.fromRGB(24, 25, 30), 0.78)
	local metal = color:Lerp(Color3.fromRGB(73, 75, 84), 0.72)
	local scale = data.Boss and 1.55 or 1

	visual(model, folder, "WaistArmor", Vector3.new(4.5 * scale, 1.0 * scale, 3.5 * scale), base * CFrame.new(0, -2.3 * scale, 0), dark, Enum.Material.Metal)
	addPauldron(model, folder, base, -2.65 * scale, metal, scale)
	addPauldron(model, folder, base, 2.65 * scale, metal, scale)
	local chest = visual(model, folder, "ChestSigil", Vector3.new(2.2 * scale, 2.4 * scale, 0.34 * scale), base * CFrame.new(0, 0.7 * scale, -1.75 * scale), color:Lerp(Color3.new(1,1,1), 0.16), Enum.Material.Glass, 0.18)
	addLight(chest, color, data.Boss and 0.75 or 0.24, data.Boss and 13 or 6)

	if data.Boss then
		visual(model, folder, "TyrantMantle", Vector3.new(9.5, 1.1, 4.0), base * CFrame.new(0, 3.6, 0.5), dark, Enum.Material.Metal)
		for _, x in ipairs({-3.4, 3.4}) do
			visual(model, folder, "TyrantHorn", Vector3.new(1.1, 5.2, 1.1), base * CFrame.new(x, 8.6, 0) * CFrame.Angles(0, 0, math.rad(x > 0 and -28 or 28)), Color3.fromRGB(87, 75, 92), Enum.Material.Slate)
		end
		local core = visual(model, folder, "TyrantCore", Vector3.new(2.3, 2.3, 0.5), base * CFrame.new(0, 1.3, -3.05), Color3.fromRGB(195, 141, 165), Enum.Material.Glass, 0.12)
		core.Shape = Enum.PartType.Ball
		addLight(core, color, 0.9, 14)
		return
	end

	if data.Archetype == "Brawler" then
		visual(model, folder, "Headband", Vector3.new(3.9, 0.42, 3.9), base * CFrame.new(0, 5.15, 0), color, Enum.Material.Fabric)
		visual(model, folder, "Belt", Vector3.new(4.6, 0.46, 3.5), base * CFrame.new(0, -1.65, 0), Color3.fromRGB(54, 42, 34), Enum.Material.Fabric)
	elseif data.Archetype == "Charger" then
		for _, x in ipairs({-3.3, 3.3}) do
			visual(model, folder, "ArmBlade", Vector3.new(0.5, 4.5, 1.0), base * CFrame.new(x, 0.3, -0.4) * CFrame.Angles(math.rad(-18), 0, math.rad(x > 0 and -16 or 16)), color:Lerp(Color3.fromRGB(110, 90, 78), 0.5), Enum.Material.Metal, 0)
		end
		visual(model, folder, "FlameCrest", Vector3.new(1.0, 3.6, 1.0), base * CFrame.new(0, 6.5, 0.5) * CFrame.Angles(math.rad(16), 0, 0), Color3.fromRGB(112, 73, 57), Enum.Material.Metal, 0)
	elseif data.Archetype == "Guardian" then
		visual(model, folder, "ChestPlate", Vector3.new(4.8, 4.2, 0.8), base * CFrame.new(0, 0.6, -1.8), metal:Lerp(Color3.new(1, 1, 1), 0.12), Enum.Material.Metal)
		for _, x in ipairs({-1.0, 1.0}) do
			visual(model, folder, "FrostHorn", Vector3.new(0.7, 2.8, 0.7), base * CFrame.new(x, 6.0, 0) * CFrame.Angles(0, 0, math.rad(x > 0 and -25 or 25)), Color3.fromRGB(151, 177, 184), Enum.Material.Ice, 0.14)
		end
	elseif data.Archetype == "Blinker" then
		visual(model, folder, "VoidMantle", Vector3.new(6.8, 0.55, 3.3), base * CFrame.new(0, 2.7, 0.4), dark, Enum.Material.Slate)
		local eye = visual(model, folder, "VoidEye", Vector3.new(1.05, 1.05, 0.35), base * CFrame.new(0, 4.75, -1.75), color:Lerp(Color3.new(1, 1, 1), 0.25), Enum.Material.Glass, 0.08)
		eye.Shape = Enum.PartType.Ball
		addLight(eye, color, 0.45, 8)
	end
end

function EnemyVisualService:Start()
	task.spawn(function()
		while self.Context.WorldFolder and self.Context.WorldFolder.Parent do
			for model, data in pairs(self.Context.Services.CombatService.Enemies) do
				if data.Alive and model.Parent and not model:GetAttribute("VisualDecorated") then
					self:Decorate(model, data)
				end
			end
			task.wait(0.25)
		end
	end)
end

return EnemyVisualService
