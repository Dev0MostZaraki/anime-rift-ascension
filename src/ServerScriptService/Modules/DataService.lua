local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local DataService = {}
DataService.__index = DataService

local LEGACY_STORE_NAME = "AnimeRiftAscension_v2"
local PROFILE_STORE_NAME = "AnimeRiftAscension_v3"

local PROFILE_TEMPLATE = {
	SchemaVersion = 3,
	LegacyMigration = {
		Completed = false,
		Found = false,
		MigratedAt = 0,
		Source = LEGACY_STORE_NAME,
	},
	Snapshot = {},
}

function DataService.new(context)
	local self = setmetatable({}, DataService)
	self.Context = context
	self.LegacyStore = DataStoreService:GetDataStore(LEGACY_STORE_NAME)
	self.ProfileStoreName = PROFILE_STORE_NAME
	self.PersistenceEnabled = game.GameId ~= 0
	self.ProfileStoreInitialized = false
	self.ProfileStore = nil
	self.PlayerStore = nil
	self.UsingProfileStore = false
	self.Backend = "LegacyFallback"
	self.Sessions = {}
	self.Releasing = {}
	return self
end

local function createValue(className, name, value, parent)
	local object = Instance.new(className)
	object.Name = name
	object.Value = value
	object.Parent = parent
	return object
end

local function findProfileStoreModule()
	local packages = ServerScriptService:FindFirstChild("Packages")
	local candidate = packages and packages:FindFirstChild("ProfileStore")
	if not candidate then return nil end
	if candidate:IsA("ModuleScript") then return candidate end
	if candidate:IsA("Folder") then
		return candidate:FindFirstChild("init")
			or candidate:FindFirstChild("ProfileStore")
			or candidate:FindFirstChildWhichIsA("ModuleScript", true)
	end
	return nil
end

function DataService:InitializeProfileStore()
	if self.ProfileStoreInitialized then return self.UsingProfileStore end
	self.ProfileStoreInitialized = true

	local module = findProfileStoreModule()
	if not module then
		warn("[Data Foundation] ProfileStore package missing; using legacy v2 fallback. Run `wally install` and restart Rojo.")
		return false
	end

	local ok, library = pcall(require, module)
	if not ok or type(library) ~= "table" or type(library.New) ~= "function" then
		warn("[Data Foundation] ProfileStore failed to load; using legacy v2 fallback:", library)
		return false
	end

	self.ProfileStore = library
	self.PlayerStore = library.New(self.ProfileStoreName, PROFILE_TEMPLATE)
	self.UsingProfileStore = true
	self.Backend = "ProfileStoreV3"
	print("[Data Foundation] ProfileStore v3 ready • v2 migration armed • session locking active")
	return true
end

function DataService:GetBackendName()
	return self.Backend
end

function DataService:CreateProfile(player)
	if player:FindFirstChild("leaderstats") then return end

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	createValue("IntValue", "Coins", 0, stats)
	createValue("IntValue", "Gems", 0, stats)
	createValue("IntValue", "Level", 1, stats)
	createValue("NumberValue", "Power", 1, stats)

	local profile = Instance.new("Folder")
	profile.Name = "RiftProfile"
	profile.Parent = player
	createValue("IntValue", "XP", 0, profile)
	createValue("IntValue", "QuestKills", 0, profile)
	createValue("IntValue", "QuestHatches", 0, profile)
	createValue("IntValue", "QuestBosses", 0, profile)
	createValue("BoolValue", "QuestKillsDone", false, profile)
	createValue("BoolValue", "QuestHatchesDone", false, profile)
	createValue("BoolValue", "QuestBossesDone", false, profile)
	createValue("StringValue", "EquippedStyle", "RiftBlade", profile)

	local zones = Instance.new("Folder")
	zones.Name = "ZoneUnlocks"
	zones.Parent = profile
	for i = 1, #self.Context.Config.Zones do
		createValue("BoolValue", "Zone" .. i, i == 1, zones)
	end

	local styleUnlocks = Instance.new("Folder")
	styleUnlocks.Name = "StyleUnlocks"
	styleUnlocks.Parent = profile
	local styleMastery = Instance.new("Folder")
	styleMastery.Name = "StyleMastery"
	styleMastery.Parent = profile
	for styleId in pairs(self.Context.Config.Styles) do
		createValue("BoolValue", styleId, styleId == "RiftBlade", styleUnlocks)
		createValue("IntValue", styleId, 0, styleMastery)
	end

	local petInventory = Instance.new("Folder")
	petInventory.Name = "PetInventory"
	petInventory.Parent = player

	local relicInventory = Instance.new("Folder")
	relicInventory.Name = "RelicInventory"
	relicInventory.Parent = player
end

function DataService:XPNeeded(level)
	return 100 + math.floor((level - 1) * 85)
end

function DataService:RecalculatePower(player)
	local stats = player:FindFirstChild("leaderstats")
	local petInventory = player:FindFirstChild("PetInventory")
	local relicInventory = player:FindFirstChild("RelicInventory")
	if not stats or not petInventory or not relicInventory then return end

	local level = stats:FindFirstChild("Level")
	local power = stats:FindFirstChild("Power")
	if not level or not power then return end

	local petBonus = 0
	for _, pet in ipairs(petInventory:GetChildren()) do
		if pet:GetAttribute("Equipped") == true then
			petBonus += tonumber(pet:GetAttribute("Bonus")) or 0
		end
	end

	local relicBonus = 0
	for _, relic in ipairs(relicInventory:GetChildren()) do
		if relic:GetAttribute("Equipped") == true then
			relicBonus += tonumber(relic:GetAttribute("PowerBonus")) or 0
		end
	end

	local levelBonus = math.max(level.Value - 1, 0) * 0.08
	power.Value = math.floor((1 + levelBonus + petBonus + relicBonus) * 100 + 0.5) / 100
end

function DataService:GetRelicCritBonus(player)
	local inventory = player:FindFirstChild("RelicInventory")
	if not inventory then return 0 end
	local bonus = 0
	for _, relic in ipairs(inventory:GetChildren()) do
		if relic:GetAttribute("Equipped") == true then
			bonus += tonumber(relic:GetAttribute("CritBonus")) or 0
		end
	end
	return bonus
end

function DataService:AddXP(player, amount)
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	if not stats or not profile then return end

	profile.XP.Value += math.max(0, math.floor(amount))
	while profile.XP.Value >= self:XPNeeded(stats.Level.Value) do
		profile.XP.Value -= self:XPNeeded(stats.Level.Value)
		stats.Level.Value += 1
		stats.Gems.Value += 2
		self:RecalculatePower(player)
		self.Context:Notify(player, "LEVEL UP! Level " .. stats.Level.Value .. " • +2 Gems", "level")
	end
end

function DataService:AddPet(player, name, rarity, bonus, equipIfPossible)
	local inventory = player:FindFirstChild("PetInventory")
	if not inventory then return nil end

	local pet = Instance.new("StringValue")
	pet.Name = HttpService:GenerateGUID(false)
	pet.Value = name
	pet:SetAttribute("Rarity", rarity)
	pet:SetAttribute("Bonus", bonus)
	pet:SetAttribute("Equipped", false)
	pet.Parent = inventory

	if equipIfPossible then
		local equipped = 0
		for _, item in ipairs(inventory:GetChildren()) do
			if item:GetAttribute("Equipped") == true then equipped += 1 end
		end
		if equipped < self.Context.Config.Game.MaxEquippedPets then pet:SetAttribute("Equipped", true) end
	end

	self:RecalculatePower(player)
	return pet
end

function DataService:AddRelic(player, name, rarity, powerBonus, critBonus, zoneId)
	local inventory = player:FindFirstChild("RelicInventory")
	if not inventory then return nil end
	local relic = Instance.new("StringValue")
	relic.Name = HttpService:GenerateGUID(false)
	relic.Value = name
	relic:SetAttribute("Rarity", rarity)
	relic:SetAttribute("PowerBonus", tonumber(powerBonus) or 0)
	relic:SetAttribute("CritBonus", tonumber(critBonus) or 0)
	relic:SetAttribute("Zone", tonumber(zoneId) or 1)
	relic:SetAttribute("Equipped", false)
	relic.Parent = inventory
	return relic
end

function DataService:Serialize(player)
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	local petInventory = player:FindFirstChild("PetInventory")
	local relicInventory = player:FindFirstChild("RelicInventory")
	if not stats or not profile or not petInventory or not relicInventory then return nil end

	local pets = {}
	for _, pet in ipairs(petInventory:GetChildren()) do
		table.insert(pets, {
			Id = pet.Name,
			Name = pet.Value,
			Rarity = pet:GetAttribute("Rarity"),
			Bonus = pet:GetAttribute("Bonus"),
			Equipped = pet:GetAttribute("Equipped") == true,
		})
	end

	local relics = {}
	for _, relic in ipairs(relicInventory:GetChildren()) do
		table.insert(relics, {
			Id = relic.Name,
			Name = relic.Value,
			Rarity = relic:GetAttribute("Rarity"),
			PowerBonus = relic:GetAttribute("PowerBonus"),
			CritBonus = relic:GetAttribute("CritBonus"),
			Zone = relic:GetAttribute("Zone"),
			Equipped = relic:GetAttribute("Equipped") == true,
		})
	end

	local unlocked = {}
	for i = 1, #self.Context.Config.Zones do
		local value = profile.ZoneUnlocks:FindFirstChild("Zone" .. i)
		unlocked[i] = value and value.Value or false
	end

	local styleUnlocks = {}
	local styleMastery = {}
	for styleId in pairs(self.Context.Config.Styles) do
		local unlock = profile.StyleUnlocks:FindFirstChild(styleId)
		local mastery = profile.StyleMastery:FindFirstChild(styleId)
		styleUnlocks[styleId] = unlock and unlock.Value or styleId == "RiftBlade"
		styleMastery[styleId] = mastery and mastery.Value or 0
	end

	return {
		Coins = stats.Coins.Value,
		Gems = stats.Gems.Value,
		Level = stats.Level.Value,
		XP = profile.XP.Value,
		Unlocked = unlocked,
		Pets = pets,
		Relics = relics,
		EquippedStyle = profile.EquippedStyle.Value,
		StyleUnlocks = styleUnlocks,
		StyleMastery = styleMastery,
		QuestKills = profile.QuestKills.Value,
		QuestHatches = profile.QuestHatches.Value,
		QuestBosses = profile.QuestBosses.Value,
		QuestKillsDone = profile.QuestKillsDone.Value,
		QuestHatchesDone = profile.QuestHatchesDone.Value,
		QuestBossesDone = profile.QuestBossesDone.Value,
	}
end

function DataService:Apply(player, data)
	if type(data) ~= "table" then return end

	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	local petInventory = player:FindFirstChild("PetInventory")
	local relicInventory = player:FindFirstChild("RelicInventory")
	if not stats or not profile or not petInventory or not relicInventory then return end

	stats.Coins.Value = tonumber(data.Coins) or 0
	stats.Gems.Value = tonumber(data.Gems) or 0
	stats.Level.Value = math.max(1, tonumber(data.Level) or 1)
	profile.XP.Value = math.max(0, tonumber(data.XP) or 0)

	if type(data.Unlocked) == "table" then
		for i = 1, #self.Context.Config.Zones do
			local value = profile.ZoneUnlocks:FindFirstChild("Zone" .. i)
			if value then value.Value = i == 1 or data.Unlocked[i] == true end
		end
	end

	if type(data.Pets) == "table" then
		for _, saved in ipairs(data.Pets) do
			if type(saved) == "table" and type(saved.Name) == "string" then
				local pet = Instance.new("StringValue")
				pet.Name = type(saved.Id) == "string" and saved.Id or HttpService:GenerateGUID(false)
				pet.Value = saved.Name
				pet:SetAttribute("Rarity", saved.Rarity or "Common")
				pet:SetAttribute("Bonus", tonumber(saved.Bonus) or 0)
				pet:SetAttribute("Equipped", saved.Equipped == true)
				pet.Parent = petInventory
			end
		end
	end

	if type(data.Relics) == "table" then
		for _, saved in ipairs(data.Relics) do
			if type(saved) == "table" and type(saved.Name) == "string" then
				local relic = Instance.new("StringValue")
				relic.Name = type(saved.Id) == "string" and saved.Id or HttpService:GenerateGUID(false)
				relic.Value = saved.Name
				relic:SetAttribute("Rarity", saved.Rarity or "Common")
				relic:SetAttribute("PowerBonus", tonumber(saved.PowerBonus) or 0)
				relic:SetAttribute("CritBonus", tonumber(saved.CritBonus) or 0)
				relic:SetAttribute("Zone", tonumber(saved.Zone) or 1)
				relic:SetAttribute("Equipped", saved.Equipped == true)
				relic.Parent = relicInventory
			end
		end
	end

	if type(data.StyleUnlocks) == "table" then
		for styleId in pairs(self.Context.Config.Styles) do
			local value = profile.StyleUnlocks:FindFirstChild(styleId)
			if value then value.Value = styleId == "RiftBlade" or data.StyleUnlocks[styleId] == true end
		end
	end
	if type(data.StyleMastery) == "table" then
		for styleId in pairs(self.Context.Config.Styles) do
			local value = profile.StyleMastery:FindFirstChild(styleId)
			if value then value.Value = math.max(0, math.floor(tonumber(data.StyleMastery[styleId]) or 0)) end
		end
	end

	local equippedStyle = type(data.EquippedStyle) == "string" and data.EquippedStyle or "RiftBlade"
	local unlock = profile.StyleUnlocks:FindFirstChild(equippedStyle)
	profile.EquippedStyle.Value = unlock and unlock.Value and equippedStyle or "RiftBlade"

	for _, key in ipairs({"QuestKills", "QuestHatches", "QuestBosses"}) do
		profile[key].Value = tonumber(data[key]) or 0
	end
	for _, key in ipairs({"QuestKillsDone", "QuestHatchesDone", "QuestBossesDone"}) do
		profile[key].Value = data[key] == true
	end

	self:RecalculatePower(player)
end

function DataService:ReadLegacy(player)
	if not self.PersistenceEnabled then return true, nil end
	local ok, data = pcall(function()
		return self.LegacyStore:GetAsync("u_" .. player.UserId)
	end)
	if ok then return true, data end
	if RunService:IsStudio() then
		self.PersistenceEnabled = false
		warn("[Data Foundation] legacy v2 DataStore unavailable in this Studio session; using non-persistent ProfileStore mock:", data)
		return true, nil
	end
	return false, data
end

function DataService:MigrateLegacy(player, profile)
	profile:Reconcile()
	local migration = profile.Data.LegacyMigration
	if type(migration) ~= "table" then
		migration = {Completed = false, Found = false, MigratedAt = 0, Source = LEGACY_STORE_NAME}
		profile.Data.LegacyMigration = migration
	end
	if migration.Completed == true then return true end

	local ok, legacy = self:ReadLegacy(player)
	if not ok then
		warn("[Data Foundation] refused to create a v3 snapshot because legacy v2 could not be read:", legacy)
		return false
	end

	if not self.PersistenceEnabled and RunService:IsStudio() then
		-- Keep migration pending. A live server with DataStore access will retry it later.
		return true
	end

	if type(legacy) == "table" then
		profile.Data.Snapshot = legacy
		migration.Found = true
		migration.MigratedAt = os.time()
		print(string.format("[Data Foundation] migrated %s from %s -> %s", player.Name, LEGACY_STORE_NAME, PROFILE_STORE_NAME))
	else
		migration.Found = false
		migration.MigratedAt = 0
	end
	migration.Completed = true
	migration.Source = LEGACY_STORE_NAME
	profile.Data.SchemaVersion = 3

	local saved, saveErr = pcall(function() profile:Save() end)
	if not saved then
		warn("[Data Foundation] initial v3 migration save failed:", saveErr)
		return false
	end
	return true
end

function DataService:LoadLegacyFallback(player)
	if not self.PersistenceEnabled then return true end
	local ok, data = pcall(function()
		return self.LegacyStore:GetAsync("u_" .. player.UserId)
	end)
	if ok then
		self:Apply(player, data)
		return true
	end
	if RunService:IsStudio() then
		self.PersistenceEnabled = false
		warn("Anime Rift legacy DataStore unavailable in this Studio session:", data)
		return true
	end
	warn("Anime Rift legacy load failed:", data)
	return false
end

function DataService:Load(player)
	self:InitializeProfileStore()

	if not self.UsingProfileStore then
		self.Backend = "LegacyFallback"
		player:SetAttribute("DataBackend", self.Backend)
		return self:LoadLegacyFallback(player)
	end

	local key = "u_" .. player.UserId
	local profile = self.PlayerStore:StartSessionAsync(key, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if not profile then
		warn("[Data Foundation] failed to start ProfileStore session for", player.Name)
		return false
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	self.Sessions[player] = profile
	player:SetAttribute("DataBackend", self.Backend)

	profile.OnSessionEnd:Connect(function()
		if self.Sessions[player] == profile then self.Sessions[player] = nil end
		if player.Parent == Players and self.Releasing[player] ~= true then
			player:Kick("Your data session ended safely. Please rejoin.")
		end
	end)

	if not self:MigrateLegacy(player, profile) then
		self.Releasing[player] = true
		pcall(function() profile:EndSession() end)
		self.Sessions[player] = nil
		self.Releasing[player] = nil
		return false
	end

	self:Apply(player, profile.Data.Snapshot)
	return true
end

function DataService:SaveLegacyFallback(player)
	if not self.PersistenceEnabled then return true end
	local payload = self:Serialize(player)
	if not payload then return false end
	local ok, err = pcall(function()
		self.LegacyStore:UpdateAsync("u_" .. player.UserId, function()
			return payload
		end)
	end)
	if not ok then warn("Anime Rift legacy save failed:", err) end
	return ok
end

function DataService:Save(player)
	if not self.UsingProfileStore then return self:SaveLegacyFallback(player) end
	local profile = self.Sessions[player]
	if not profile or not profile:IsActive() then return false end
	local payload = self:Serialize(player)
	if not payload then return false end
	profile.Data.SchemaVersion = 3
	profile.Data.Snapshot = payload
	local ok, err = pcall(function() profile:Save() end)
	if not ok then warn("[Data Foundation] ProfileStore save failed:", err) end
	return ok
end

function DataService:Release(player)
	if not self.UsingProfileStore then
		return self:SaveLegacyFallback(player)
	end

	local profile = self.Sessions[player]
	if not profile then return true end
	local payload = self:Serialize(player)
	if payload then
		profile.Data.SchemaVersion = 3
		profile.Data.Snapshot = payload
	end

	self.Releasing[player] = true
	local ok, err = pcall(function()
		if profile:IsActive() then profile:EndSession() end
	end)
	self.Sessions[player] = nil
	self.Releasing[player] = nil
	if not ok then warn("[Data Foundation] ProfileStore session release failed:", err) end
	return ok
end

return DataService
