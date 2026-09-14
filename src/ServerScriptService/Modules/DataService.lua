local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local DataService = {}
DataService.__index = DataService

function DataService.new(context)
	local self = setmetatable({}, DataService)
	-- Keep the existing store so current test progress migrates into 3.0 instead of resetting.
	self.Store = DataStoreService:GetDataStore("AnimeRiftAscension_v2")
	self.Context = context
	self.PersistenceEnabled = game.GameId ~= 0
	return self
end

local function createValue(className, name, value, parent)
	local object = Instance.new(className)
	object.Name = name
	object.Value = value
	object.Parent = parent
	return object
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

function DataService:Load(player)
	if not self.PersistenceEnabled then return end
	local ok, data = pcall(function()
		return self.Store:GetAsync("u_" .. player.UserId)
	end)
	if ok then
		self:Apply(player, data)
	else
		self.PersistenceEnabled = false
		warn("Anime Rift DataStore unavailable in this Studio session:", data)
	end
end

function DataService:Save(player)
	if not self.PersistenceEnabled then return end
	local payload = self:Serialize(player)
	if not payload then return end
	local ok, err = pcall(function()
		self.Store:UpdateAsync("u_" .. player.UserId, function()
			return payload
		end)
	end)
	if not ok then warn("Anime Rift save failed:", err) end
end

return DataService
