local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local DataService = {}
DataService.__index = DataService

function DataService.new(context)
	local self = setmetatable({}, DataService)
	self.Context = context
	self.Store = DataStoreService:GetDataStore("AnimeRiftAscension_v2")
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
	if player:FindFirstChild("leaderstats") then
		return
	end

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

	local zones = Instance.new("Folder")
	zones.Name = "ZoneUnlocks"
	zones.Parent = profile

	for i = 1, #self.Context.Config.Zones do
		createValue("BoolValue", "Zone" .. i, i == 1, zones)
	end

	local inventory = Instance.new("Folder")
	inventory.Name = "PetInventory"
	inventory.Parent = player
end

function DataService:XPNeeded(level)
	return 100 + math.floor((level - 1) * 85)
end

function DataService:RecalculatePower(player)
	local stats = player:FindFirstChild("leaderstats")
	local inventory = player:FindFirstChild("PetInventory")
	if not stats or not inventory then
		return
	end

	local level = stats:FindFirstChild("Level")
	local power = stats:FindFirstChild("Power")
	if not level or not power then
		return
	end

	local petBonus = 0
	for _, pet in ipairs(inventory:GetChildren()) do
		if pet:GetAttribute("Equipped") == true then
			petBonus += tonumber(pet:GetAttribute("Bonus")) or 0
		end
	end

	local levelBonus = math.max(level.Value - 1, 0) * 0.08
	power.Value = math.floor((1 + levelBonus + petBonus) * 100 + 0.5) / 100
end

function DataService:AddXP(player, amount)
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	if not stats or not profile then
		return
	end

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
	if not inventory then
		return nil
	end

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
			if item:GetAttribute("Equipped") == true then
				equipped += 1
			end
		end
		if equipped < self.Context.Config.Game.MaxEquippedPets then
			pet:SetAttribute("Equipped", true)
		end
	end

	self:RecalculatePower(player)
	return pet
end

function DataService:Serialize(player)
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	local inventory = player:FindFirstChild("PetInventory")
	if not stats or not profile or not inventory then
		return nil
	end

	local pets = {}
	for _, pet in ipairs(inventory:GetChildren()) do
		table.insert(pets, {
			Id = pet.Name,
			Name = pet.Value,
			Rarity = pet:GetAttribute("Rarity"),
			Bonus = pet:GetAttribute("Bonus"),
			Equipped = pet:GetAttribute("Equipped") == true,
		})
	end

	local unlocked = {}
	for i = 1, #self.Context.Config.Zones do
		local value = profile.ZoneUnlocks:FindFirstChild("Zone" .. i)
		unlocked[i] = value and value.Value or false
	end

	return {
		Coins = stats.Coins.Value,
		Gems = stats.Gems.Value,
		Level = stats.Level.Value,
		XP = profile.XP.Value,
		Unlocked = unlocked,
		Pets = pets,
		QuestKills = profile.QuestKills.Value,
		QuestHatches = profile.QuestHatches.Value,
		QuestBosses = profile.QuestBosses.Value,
		QuestKillsDone = profile.QuestKillsDone.Value,
		QuestHatchesDone = profile.QuestHatchesDone.Value,
		QuestBossesDone = profile.QuestBossesDone.Value,
	}
end

function DataService:Apply(player, data)
	if type(data) ~= "table" then
		return
	end

	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	local inventory = player:FindFirstChild("PetInventory")
	if not stats or not profile or not inventory then
		return
	end

	stats.Coins.Value = tonumber(data.Coins) or 0
	stats.Gems.Value = tonumber(data.Gems) or 0
	stats.Level.Value = math.max(1, tonumber(data.Level) or 1)
	profile.XP.Value = math.max(0, tonumber(data.XP) or 0)

	if type(data.Unlocked) == "table" then
		for i = 1, #self.Context.Config.Zones do
			local value = profile.ZoneUnlocks:FindFirstChild("Zone" .. i)
			if value then
				value.Value = i == 1 or data.Unlocked[i] == true
			end
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
				pet.Parent = inventory
			end
		end
	end

	for _, key in ipairs({"QuestKills", "QuestHatches", "QuestBosses"}) do
		profile[key].Value = tonumber(data[key]) or 0
	end
	for _, key in ipairs({"QuestKillsDone", "QuestHatchesDone", "QuestBossesDone"}) do
		profile[key].Value = data[key] == true
	end

	self:RecalculatePower(player)
end

function DataService:Load(player)
	if not self.PersistenceEnabled then
		return
	end

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
	if not self.PersistenceEnabled then
		return
	end

	local payload = self:Serialize(player)
	if not payload then
		return
	end

	local ok, err = pcall(function()
		self.Store:UpdateAsync("u_" .. player.UserId, function()
			return payload
		end)
	end)
	if not ok then
		warn("Anime Rift save failed:", err)
	end
end

return DataService
