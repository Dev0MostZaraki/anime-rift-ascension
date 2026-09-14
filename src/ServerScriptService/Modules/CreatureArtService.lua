local ServerStorage = game:GetService("ServerStorage")

local CreatureArtService = {}
CreatureArtService.__index = CreatureArtService

function CreatureArtService.new(context)
	return setmetatable({
		Context = context,
		Manifest = require(context.Config.Parent and context.Config.Parent:FindFirstChild("CreatureArt") or game:GetService("ReplicatedStorage"):WaitForChild("AnimeRift"):WaitForChild("CreatureArt")),
		AssetRoot = nil,
		Tracks = setmetatable({}, {__mode = "k"}),
	}, CreatureArtService)
end

local function folder(parent, name)
	local found = parent:FindFirstChild(name)
	if found and found:IsA("Folder") then return found end
	if found then found:Destroy() end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function firstBasePart(model)
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") then return object end
	end
	return nil
end

local function stripCode(model)
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") then
			object:Destroy()
		end
	end
end

local function setVisualPhysics(model)
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
			object.Massless = true
		end
	end
end

local function tintModel(model, color)
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") then
			local tintable = object:GetAttribute("AnimeRiftTint") == true
			local n = string.lower(object.Name)
			if tintable or string.find(n, "accent", 1, true) or string.find(n, "core", 1, true) or string.find(n, "tint", 1, true) then
				object.Color = color
			end
		end
	end
end

local function ensureAnimator(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local controller = model:FindFirstChildOfClass("AnimationController")
	local owner = humanoid or controller
	if not owner then
		controller = Instance.new("AnimationController")
		controller.Name = "AnimeRiftAnimationController"
		controller.Parent = model
		owner = controller
	end
	local animator = owner:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = owner
	end
	return animator
end

function CreatureArtService:GetAssetFolder(kind)
	if not self.AssetRoot then return nil end
	return self.AssetRoot:FindFirstChild(kind)
end

function CreatureArtService:GetTemplate(kind, assetName)
	local source = self:GetAssetFolder(kind)
	local template = source and source:FindFirstChild(assetName)
	if template and template:IsA("Model") then return template end
	return nil
end

function CreatureArtService:PrepareClone(template, scale, tint)
	local clone = template:Clone()
	stripCode(clone)
	if not clone.PrimaryPart then
		clone.PrimaryPart = clone:FindFirstChild("HumanoidRootPart", true) or clone:FindFirstChild("Root", true) or firstBasePart(clone)
	end
	if not clone.PrimaryPart then
		clone:Destroy()
		return nil
	end
	if scale and math.abs(scale - 1) > 0.001 then
		pcall(function() clone:ScaleTo(scale) end)
	end
	setVisualPhysics(clone)
	if tint then tintModel(clone, tint) end
	clone:SetAttribute("AnimeRiftImported", true)
	return clone
end

function CreatureArtService:Play(model, animationId, looped, speed)
	animationId = tonumber(animationId) or 0
	if animationId <= 0 or not model or not model.Parent then return nil end
	local animator = ensureAnimator(model)
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. tostring(animationId)
	local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
	animation:Destroy()
	if not ok or not track then return nil end
	track.Looped = looped == true
	track.Priority = Enum.AnimationPriority.Movement
	track:Play(0.16, 1, speed or 1)
	self.Tracks[model] = track
	return track
end

function CreatureArtService:HideEnemyFallback(model)
	for _, object in ipairs(model:GetChildren()) do
		if object:IsA("BasePart") then
			if object == model.PrimaryPart then
				object.Transparency = 1
				object.CanCollide = true
			else
				object.Transparency = 1
				object.CanCollide = false
			end
		end
	end
	local oldRig = model:FindFirstChild("VisualRig")
	if oldRig then oldRig:Destroy() end
end

function CreatureArtService:TryApplyEnemy(model, data)
	if not model or not model.Parent or not model.PrimaryPart then return false end
	if model:GetAttribute("ImportedCreatureApplied") then return true end
	local entry
	local kind
	if data.Boss then
		entry = self.Manifest.Bosses.RiftTyrant
		kind = "Bosses"
	else
		entry = self.Manifest.Enemies[data.Archetype]
		kind = "Enemies"
	end
	if not entry then return false end
	local template = self:GetTemplate(kind, entry.Asset)
	if not template then return false end

	local clone = self:PrepareClone(template, entry.Scale or 1, data.Boss and nil or data.Zone.Color)
	if not clone then return false end
	clone.Name = "CreatureVisual"
	clone.Parent = model
	local pivotY = tonumber(entry.PivotY) or 0
	clone:PivotTo(model.PrimaryPart.CFrame * CFrame.new(0, pivotY, 0))
	self:HideEnemyFallback(model)
	model:SetAttribute("ImportedCreatureApplied", true)
	model:SetAttribute("CreatureAsset", entry.Asset)
	if entry.Animations then self:Play(clone, entry.Animations.Idle, true, 1) end
	return true
end

function CreatureArtService:GetPetEntry(petName)
	local exact = self.Manifest.PetExact[petName]
	if exact then return exact end
	for _, entry in ipairs(self.Manifest.PetFamilies) do
		if string.find(string.lower(petName), string.lower(entry.Pattern), 1, true) then return entry end
	end
	return self.Manifest.PetFallback
end

function CreatureArtService:TryBuildPet(parent, pet, slot)
	local petName = tostring(pet.Value)
	local entry = self:GetPetEntry(petName)
	if not entry then return nil end
	local template = self:GetTemplate("Pets", entry.Asset)
	if not template then return nil end
	local rarity = tostring(pet:GetAttribute("Rarity") or "Common")
	local tint = self.Context.Config.RarityColors[rarity] or self.Context.Config.RarityColors.Common
	local clone = self:PrepareClone(template, entry.Scale or 1, tint)
	if not clone then return nil end
	clone.Name = petName
	clone:SetAttribute("Slot", slot)
	clone:SetAttribute("Rarity", rarity)
	clone:SetAttribute("ImportedCompanion", true)
	clone:SetAttribute("CreatureAsset", entry.Asset)
	clone.Parent = parent
	return clone
end

function CreatureArtService:Start()
	self.AssetRoot = folder(ServerStorage, "AnimeRiftAssets")
	folder(self.AssetRoot, "Enemies")
	folder(self.AssetRoot, "Bosses")
	folder(self.AssetRoot, "Pets")

	local enemyCount, bossCount, petCount = 0, 0, 0
	for _, object in ipairs(self.AssetRoot.Enemies:GetChildren()) do if object:IsA("Model") then enemyCount += 1 end end
	for _, object in ipairs(self.AssetRoot.Bosses:GetChildren()) do if object:IsA("Model") then bossCount += 1 end end
	for _, object in ipairs(self.AssetRoot.Pets:GetChildren()) do if object:IsA("Model") then petCount += 1 end end
	print(string.format("[Creature Art] pipeline ready • %d enemy • %d boss • %d pet external models", enemyCount, bossCount, petCount))
end

return CreatureArtService
