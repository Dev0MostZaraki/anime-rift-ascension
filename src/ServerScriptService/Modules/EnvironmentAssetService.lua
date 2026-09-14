local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local AssetCatalog = require(AnimeRift:WaitForChild("AssetCatalog"))

local EnvironmentAssetService = {}
EnvironmentAssetService.__index = EnvironmentAssetService

function EnvironmentAssetService.new(context)
	return setmetatable({
		Context = context,
		Catalog = AssetCatalog,
		Spawned = 0,
	}, EnvironmentAssetService)
end

local function containsAny(name, keywords)
	name = string.lower(name)
	for _, keyword in ipairs(keywords) do
		if string.find(name, string.lower(keyword), 1, true) then return true end
	end
	return false
end

local function matchingModels(root, keywords)
	local models = {}
	for _, object in ipairs(root:GetDescendants()) do
		if object:IsA("Model") and containsAny(object.Name, keywords) then
			table.insert(models, object)
		end
	end
	if #models > 0 then return models end
	for _, object in ipairs(root:GetDescendants()) do
		if object:IsA("MeshPart") and containsAny(object.Name, keywords) then
			table.insert(models, object)
		end
	end
	return models
end

local function firstPart(model)
	if model:IsA("BasePart") then return model end
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") then return object end
	end
	return nil
end

local function normalizeVisual(object)
	for _, descendant in ipairs(object:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end
	if object:IsA("BasePart") then
		object.Anchored = true
		object.CanCollide = false
		object.CanTouch = false
		object.CanQuery = false
	end
end

function EnvironmentAssetService:GetGroundY(x, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = self.Context.WorldFolder and {self.Context.WorldFolder} or {}
	params.IgnoreWater = false
	local result = Workspace:Raycast(Vector3.new(x, 140, z), Vector3.new(0, -300, 0), params)
	return result and result.Position.Y or 2
end

function EnvironmentAssetService:PlaceTemplate(template, parent, x, z, yaw, scale)
	if not template or not template.Parent then return false end
	local clone = template:Clone()
	clone.Name = "External_" .. template.Name
	normalizeVisual(clone)
	clone.Parent = parent

	if clone:IsA("Model") then
		local primary = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart", true) or firstPart(clone)
		if not primary then clone:Destroy() return false end
		clone.PrimaryPart = primary
		if scale and math.abs(scale - 1) > 0.001 then pcall(function() clone:ScaleTo(scale) end) end
		local bboxCF, bboxSize = clone:GetBoundingBox()
		local pivot = clone:GetPivot()
		local bottom = bboxCF.Position.Y - bboxSize.Y / 2
		local pivotAboveBottom = pivot.Position.Y - bottom
		local y = self:GetGroundY(x, z) + math.max(0.1, pivotAboveBottom)
		clone:PivotTo(CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0))
	elseif clone:IsA("BasePart") then
		local y = self:GetGroundY(x, z) + clone.Size.Y / 2
		clone.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	else
		clone:Destroy()
		return false
	end

	clone:SetAttribute("AnimeRiftExternalEnvironment", true)
	self.Spawned += 1
	return true
end

function EnvironmentAssetService:Scatter(pool, parent, placements, seed, minScale, maxScale)
	if #pool == 0 then return 0 end
	local random = Random.new(seed)
	local count = 0
	for _, pos in ipairs(placements) do
		local template = pool[random:NextInteger(1, #pool)]
		if self:PlaceTemplate(template, parent, pos.X, pos.Z, random:NextNumber(0, 360), random:NextNumber(minScale or 0.85, maxScale or 1.15)) then
			count += 1
		end
	end
	return count
end

local function pointsAround(center, seed, count, minRadius, maxRadius, exclusions)
	local random = Random.new(seed)
	local result = {}
	local attempts = 0
	while #result < count and attempts < count * 10 do
		attempts += 1
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(minRadius, maxRadius)
		local p = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local allowed = true
		for _, exclusion in ipairs(exclusions or {}) do
			if (Vector3.new(p.X, 0, p.Z) - Vector3.new(exclusion.X, 0, exclusion.Z)).Magnitude < (exclusion.Radius or 14) then
				allowed = false
				break
			end
		end
		if allowed then table.insert(result, p) end
	end
	return result
end

function EnvironmentAssetService:UseNaturePack(parent, package)
	local keywords = self.Catalog.EnvironmentKeywords.Nature
	local treePool = matchingModels(package, keywords.Tree)
	local bushPool = matchingModels(package, keywords.Bush)
	local rockPool = matchingModels(package, keywords.Rock)
	local logPool = matchingModels(package, keywords.Log)
	local verdant = self.Context.Config.Zones[1].Center
	local ember = self.Context.Config.Zones[2].Center

	local treePoints = pointsAround(verdant, 4501, 24, 48, 108, {
		{X = 0, Z = 190, Radius = 24},
		{X = 82, Z = 260, Radius = 30},
	})
	for _, p in ipairs({Vector3.new(-88,0,-48), Vector3.new(88,0,-45), Vector3.new(-94,0,62), Vector3.new(94,0,64)}) do table.insert(treePoints, p) end
	self:Scatter(treePool, parent, treePoints, 4510, 0.82, 1.18)

	local bushPoints = pointsAround(verdant, 4520, 28, 32, 105)
	self:Scatter(bushPool, parent, bushPoints, 4530, 0.72, 1.12)

	local rockPoints = pointsAround(verdant, 4540, 14, 58, 116)
	for _, p in ipairs(pointsAround(ember, 4550, 10, 62, 112)) do table.insert(rockPoints, p) end
	self:Scatter(rockPool, parent, rockPoints, 4560, 0.72, 1.20)

	local logPoints = {
		verdant + Vector3.new(-38,0,62), verdant + Vector3.new(42,0,49),
		verdant + Vector3.new(-71,0,-21), verdant + Vector3.new(67,0,-34),
	}
	self:Scatter(logPool, parent, logPoints, 4570, 0.8, 1.05)
end

function EnvironmentAssetService:UseDungeonPack(parent, package)
	local keywords = self.Catalog.EnvironmentKeywords.Dungeon
	local rockPool = matchingModels(package, keywords.Rock)
	local ruinPool = matchingModels(package, keywords.Ruin)
	local frost = self.Context.Config.Zones[3].Center
	local void = self.Context.Config.Zones[4].Center

	local rockPoints = pointsAround(frost, 4601, 10, 58, 112)
	for _, p in ipairs(pointsAround(void, 4602, 14, 54, 116)) do table.insert(rockPoints, p) end
	self:Scatter(rockPool, parent, rockPoints, 4610, 0.70, 1.08)

	local ruinPoints = {
		frost + Vector3.new(-52,0,-61), frost + Vector3.new(45,0,-58),
		void + Vector3.new(-58,0,-5), void + Vector3.new(48,0,12),
		void + Vector3.new(-44,0,-58), void + Vector3.new(38,0,-66),
	}
	self:Scatter(ruinPool, parent, ruinPoints, 4620, 0.65, 0.92)
end

function EnvironmentAssetService:Start()
	local intake = self.Context.Services.AssetIntakeService
	if not intake or not intake.Root then return end
	local old = self.Context.WorldFolder:FindFirstChild("ExternalEnvironment")
	if old then old:Destroy() end
	local parent = Instance.new("Folder")
	parent.Name = "ExternalEnvironment"
	parent.Parent = self.Context.WorldFolder

	local used = 0
	for _, pack in ipairs(self.Catalog.ApprovedEnvironmentPacks) do
		local package = intake:GetPackage(pack.Folder)
		if package and intake:HasContent(pack.Folder) then
			used += 1
			if pack.Id == 6933438443 then
				self:UseNaturePack(parent, package)
			elseif pack.Id == 6934021345 then
				self:UseDungeonPack(parent, package)
			end
		end
	end

	if used == 0 then
		print("[Environment Assets] no approved external packs imported yet • procedural fallbacks remain active")
	else
		print(string.format("[Environment Assets] %d approved packs active • %d external props placed", used, self.Spawned))
	end
end

return EnvironmentAssetService
