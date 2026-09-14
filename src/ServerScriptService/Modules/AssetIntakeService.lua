local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local AssetCatalog = require(AnimeRift:WaitForChild("AssetCatalog"))

local AssetIntakeService = {}
AssetIntakeService.__index = AssetIntakeService

function AssetIntakeService.new(context)
	return setmetatable({
		Context = context,
		Catalog = AssetCatalog,
		Root = nil,
		Audit = {},
	}, AssetIntakeService)
end

local removableClasses = {
	Script = true,
	LocalScript = true,
	ModuleScript = true,
	RemoteEvent = true,
	RemoteFunction = true,
	UnreliableRemoteEvent = true,
	BindableEvent = true,
	BindableFunction = true,
	Tool = true,
	ClickDetector = true,
	ProximityPrompt = true,
}

local function ensureFolder(parent, name)
	local found = parent:FindFirstChild(name)
	if found and found:IsA("Folder") then return found end
	if found then found:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function AssetIntakeService:Sanitize(container)
	if not container then return {Removed = 0, Parts = 0, Meshes = 0} end
	local audit = {Removed = 0, Parts = 0, Meshes = 0}
	for _, object in ipairs(container:GetDescendants()) do
		if removableClasses[object.ClassName] then
			object:Destroy()
			audit.Removed += 1
		elseif object:IsA("BasePart") then
			audit.Parts += 1
			if object:IsA("MeshPart") then audit.Meshes += 1 end
			if self.Catalog.Rules.AnchorEnvironment then object.Anchored = true end
			if self.Catalog.Rules.DisableTouch then object.CanTouch = false end
			object.CanQuery = true
		end
	end
	container:SetAttribute("AnimeRiftSanitized", true)
	container:SetAttribute("AnimeRiftRemovedUnsafe", audit.Removed)
	container:SetAttribute("AnimeRiftPartCount", audit.Parts)
	container:SetAttribute("AnimeRiftMeshCount", audit.Meshes)
	return audit
end

function AssetIntakeService:WatchPackage(folder)
	local function auditNow()
		task.defer(function()
			local result = self:Sanitize(folder)
			self.Audit[folder.Name] = result
		end)
	end
	folder.DescendantAdded:Connect(function(object)
		if removableClasses[object.ClassName] then
			task.defer(function()
				if object.Parent then object:Destroy() end
			end)
		elseif object:IsA("BasePart") then
			if self.Catalog.Rules.AnchorEnvironment then object.Anchored = true end
			if self.Catalog.Rules.DisableTouch then object.CanTouch = false end
		end
	end)
	folder.ChildAdded:Connect(auditNow)
	auditNow()
end

function AssetIntakeService:GetPackage(folderName)
	return self.Root and self.Root:FindFirstChild(folderName)
end

function AssetIntakeService:HasContent(folderName)
	local package = self:GetPackage(folderName)
	if not package then return false end
	for _, object in ipairs(package:GetDescendants()) do
		if object:IsA("Model") or object:IsA("MeshPart") then return true end
	end
	return false
end

function AssetIntakeService:Start()
	self.Root = ensureFolder(ServerStorage, "AnimeRiftVendorAssets")
	local staging = ensureFolder(self.Root, "Staging")
	staging:SetAttribute("Instructions", "Insert Creator Store packs here first, then move approved art into its named package folder.")

	for _, pack in ipairs(self.Catalog.ApprovedEnvironmentPacks) do
		local package = ensureFolder(self.Root, pack.Folder)
		package:SetAttribute("CreatorStoreAssetId", pack.Id)
		package:SetAttribute("SourceCreator", pack.Creator)
		package:SetAttribute("SourceName", pack.Name)
		package:SetAttribute("Purpose", pack.Purpose)
		self:WatchPackage(package)
	end

	local imported = 0
	for _, pack in ipairs(self.Catalog.ApprovedEnvironmentPacks) do
		if self:HasContent(pack.Folder) then imported += 1 end
	end
	print(string.format("[Asset Intake] ready • %d/%d approved environment packs populated", imported, #self.Catalog.ApprovedEnvironmentPacks))
end

return AssetIntakeService
