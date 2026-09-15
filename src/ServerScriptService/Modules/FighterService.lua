local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local FighterConfig = require(AnimeRift:WaitForChild("FighterConfig"))

local FighterService = {}
FighterService.__index = FighterService

local function ensureValue(className, parent, name, default)
	local found = parent:FindFirstChild(name)
	if found and found.ClassName == className then return found end
	if found then found:Destroy() end
	local value = Instance.new(className)
	value.Name = name
	value.Value = default
	value.Parent = parent
	return value
end

function FighterService.new(context)
	local self = setmetatable({
		Context = context,
		Config = FighterConfig,
		LastSummon = {},
		Definitions = {},
	}, FighterService)
	for rarity, entries in pairs(FighterConfig.Fighters) do
		for _, fighter in ipairs(entries) do
			self.Definitions[fighter.Id] = {
				Id = fighter.Id,
				Name = fighter.Name,
				Rarity = rarity,
			}
		end
	end
	return self
end

function FighterService:EnsureProfile(player)
	local profile = player:FindFirstChild("RiftProfile")
	if not profile then return nil, nil end
	local folder = profile:FindFirstChild("Fighters")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Fighters"
		folder.Parent = profile
	end
	ensureValue("IntValue", folder, "SoulShards", 0)
	ensureValue("IntValue", folder, "SummonCount", 0)
	ensureValue("IntValue", folder, "MythicPity", 0)

	local inventory = player:FindFirstChild("FighterInventory")
	if not inventory then
		inventory = Instance.new("Folder")
		inventory.Name = "FighterInventory"
		inventory.Parent = player
	end
	return folder, inventory
end

function FighterService:GetDefinition(fighterId)
	return self.Definitions[fighterId]
end

function FighterService:GetEquippedCount(player)
	local _, inventory = self:EnsureProfile(player)
	if not inventory then return 0 end
	local count = 0
	for _, fighter in ipairs(inventory:GetChildren()) do
		if (tonumber(fighter:GetAttribute("EquippedSlot")) or 0) > 0 then count += 1 end
	end
	return count
end

function FighterService:GetTeamPowerBonus(player)
	local _, inventory = self:EnsureProfile(player)
	if not inventory then return 0 end
	local bonus = 0
	for _, fighter in ipairs(inventory:GetChildren()) do
		if (tonumber(fighter:GetAttribute("EquippedSlot")) or 0) > 0 then
			local rarity = tostring(fighter:GetAttribute("Rarity") or "Rare")
			local rarityData = self.Config.Rarities[rarity]
			local base = rarityData and rarityData.TeamPower or 0
			local traitPower = tonumber(fighter:GetAttribute("TraitPowerMultiplier")) or 1
			bonus += base * traitPower
		end
	end
	return bonus
end

function FighterService:RefreshPower(player)
	self.Context.Services.DataService:RecalculatePower(player)
	local statsService = self.Context.Services.StatsService
	if statsService then statsService:Recalculate(player, true) end
end

function FighterService:RollTrait()
	local total = 0
	for _, trait in ipairs(self.Config.Traits) do total += math.max(0, trait.Weight or 0) end
	local roll = math.random() * total
	local cursor = 0
	for _, trait in ipairs(self.Config.Traits) do
		cursor += math.max(0, trait.Weight or 0)
		if roll <= cursor then return trait end
	end
	return self.Config.Traits[1]
end

function FighterService:RollRarity(pity, minimumRank)
	local settings = self.Config.Settings
	local pullNumber = math.max(1, (tonumber(pity) or 0) + 1)
	local hardPity = pullNumber >= settings.HardPity
	local minRank = hardPity and 4 or math.max(1, tonumber(minimumRank) or 1)
	local total = 0
	local weighted = {}

	for _, rarity in ipairs(self.Config.RarityOrder) do
		local data = self.Config.Rarities[rarity]
		if data and data.Rank >= minRank then
			local weight = math.max(0, data.Weight or 0)
			if data.Rank >= 4 and pullNumber >= settings.SoftPityStarts and not hardPity then
				local softSteps = pullNumber - settings.SoftPityStarts + 1
				weight *= 1 + softSteps * settings.SoftPityBoostPerPull
			end
			table.insert(weighted, {Rarity = rarity, Weight = weight})
			total += weight
		end
	end

	if total <= 0 then return "Rare" end
	local roll = math.random() * total
	local cursor = 0
	for _, entry in ipairs(weighted) do
		cursor += entry.Weight
		if roll <= cursor then return entry.Rarity end
	end
	return weighted[#weighted].Rarity
end

function FighterService:RollFighter(rarity)
	local pool = self.Config.Fighters[rarity]
	if not pool or #pool == 0 then return nil end
	return pool[math.random(1, #pool)]
end

function FighterService:GrantRoll(player, rarity, fighterData, trait)
	local profile, inventory = self:EnsureProfile(player)
	if not profile or not inventory or not fighterData then return nil end
	local rarityData = self.Config.Rarities[rarity]
	local existing = inventory:FindFirstChild(fighterData.Id)
	local duplicate = existing ~= nil
	local shards = 0

	if existing then
		existing:SetAttribute("Copies", (tonumber(existing:GetAttribute("Copies")) or 1) + 1)
		shards = rarityData and rarityData.Shards or 0
		profile.SoulShards.Value += shards
	else
		local fighter = Instance.new("StringValue")
		fighter.Name = fighterData.Id
		fighter.Value = fighterData.Name
		fighter:SetAttribute("Rarity", rarity)
		fighter:SetAttribute("Copies", 1)
		fighter:SetAttribute("EquippedSlot", 0)
		fighter:SetAttribute("Trait", trait.Id)
		fighter:SetAttribute("TraitPowerMultiplier", trait.PowerMultiplier or 1)
		fighter.Parent = inventory
		existing = fighter
	end

	return {
		Id = fighterData.Id,
		Name = fighterData.Name,
		Rarity = rarity,
		Trait = trait.Id,
		Duplicate = duplicate,
		Shards = shards,
	}
end

function FighterService:Pay(player, currency, count)
	local stats = player:FindFirstChild("leaderstats")
	local profile = self:EnsureProfile(player)
	if not stats or not profile then return false end
	count = count == 10 and 10 or 1

	if currency == "Tickets" then
		local progression = player:FindFirstChild("RiftProfile") and player.RiftProfile:FindFirstChild("Progression")
		local tickets = progression and progression:FindFirstChild("RiftTickets")
		local cost = self.Config.Settings.TicketCostPerSummon * count
		if not tickets or tickets.Value < cost then
			self.Context:Notify(player, "You need " .. cost .. " Rift Ticket" .. (cost == 1 and "" or "s") .. ".", "error")
			return false
		end
		tickets.Value -= cost
		return true
	end

	local cost = count == 10 and self.Config.Settings.TenSummonGems or self.Config.Settings.SingleSummonGems
	if stats.Gems.Value < cost then
		self.Context:Notify(player, "You need " .. cost .. " Gems.", "error")
		return false
	end
	stats.Gems.Value -= cost
	return true
end

function FighterService:Summon(player, currency, count)
	count = count == 10 and 10 or 1
	currency = currency == "Tickets" and "Tickets" or "Gems"
	local now = os.clock()
	if now - (self.LastSummon[player] or 0) < 0.55 then return end
	self.LastSummon[player] = now

	local profile = self:EnsureProfile(player)
	if not profile or not self:Pay(player, currency, count) then return end

	local results = {}
	for index = 1, count do
		local minimumRank = count == 10 and index == count and self.Config.Settings.TenPullGuaranteeRank or 1
		local rarity = self:RollRarity(profile.MythicPity.Value, minimumRank)
		local rarityData = self.Config.Rarities[rarity]
		local fighterData = self:RollFighter(rarity)
		local trait = self:RollTrait()
		local result = self:GrantRoll(player, rarity, fighterData, trait)
		if result then table.insert(results, result) end

		profile.SummonCount.Value += 1
		if rarityData and rarityData.Rank >= 4 then
			profile.MythicPity.Value = 0
		else
			profile.MythicPity.Value = math.min(self.Config.Settings.HardPity - 1, profile.MythicPity.Value + 1)
		end
	end

	self.Context.Remotes.FighterAction:FireClient(player, "SummonResults", results)
	if #results == 1 then
		local result = results[1]
		local extra = result.Duplicate and (" • DUPLICATE +" .. result.Shards .. " Soul Shards") or (" • " .. result.Trait)
		self.Context:Notify(player, result.Rarity .. " • " .. result.Name .. extra, result.Rarity)
	else
		local best = results[1]
		for _, result in ipairs(results) do
			local rank = self.Config.Rarities[result.Rarity] and self.Config.Rarities[result.Rarity].Rank or 1
			local bestRank = best and self.Config.Rarities[best.Rarity] and self.Config.Rarities[best.Rarity].Rank or 0
			if rank > bestRank then best = result end
		end
		if best then self.Context:Notify(player, "10x SUMMON • Best: " .. best.Rarity .. " " .. best.Name, "success") end
	end
end

function FighterService:Equip(player, fighterId)
	if type(fighterId) ~= "string" then return end
	local _, inventory = self:EnsureProfile(player)
	if not inventory then return end
	local fighter = inventory:FindFirstChild(fighterId)
	if not fighter then return end
	local currentSlot = tonumber(fighter:GetAttribute("EquippedSlot")) or 0
	if currentSlot > 0 then
		fighter:SetAttribute("EquippedSlot", 0)
		self:RefreshPower(player)
		return
	end

	local used = {}
	for _, item in ipairs(inventory:GetChildren()) do
		local slot = tonumber(item:GetAttribute("EquippedSlot")) or 0
		if slot > 0 then used[slot] = true end
	end
	local slot
	for index = 1, self.Config.Settings.MaxEquipped do
		if not used[index] then slot = index break end
	end
	if not slot then
		self.Context:Notify(player, "Your Fighter team is full. Unequip one first.", "error")
		return
	end
	fighter:SetAttribute("EquippedSlot", slot)
	self:RefreshPower(player)
end

function FighterService:InstallPersistenceBridge()
	local dataService = self.Context.Services.DataService
	if dataService.__FighterPersistencePatched then return end
	dataService.__FighterPersistencePatched = true

	local rawCreateProfile = dataService.CreateProfile
	function dataService:CreateProfile(player)
		rawCreateProfile(self, player)
		local fighters = self.Context.Services.FighterService
		if fighters then fighters:EnsureProfile(player) end
	end

	local rawSerialize = dataService.Serialize
	function dataService:Serialize(player)
		local payload = rawSerialize(self, player)
		if not payload then return nil end
		local fighters = self.Context.Services.FighterService
		local profile, inventory = fighters and fighters:EnsureProfile(player)
		if profile and inventory then
			payload.Fighters = {
				SoulShards = profile.SoulShards.Value,
				SummonCount = profile.SummonCount.Value,
				MythicPity = profile.MythicPity.Value,
				Inventory = {},
			}
			for _, fighter in ipairs(inventory:GetChildren()) do
				table.insert(payload.Fighters.Inventory, {
					Id = fighter.Name,
					Copies = tonumber(fighter:GetAttribute("Copies")) or 1,
					EquippedSlot = tonumber(fighter:GetAttribute("EquippedSlot")) or 0,
					Trait = fighter:GetAttribute("Trait"),
					TraitPowerMultiplier = tonumber(fighter:GetAttribute("TraitPowerMultiplier")) or 1,
				})
			end
		end
		return payload
	end

	local rawApply = dataService.Apply
	function dataService:Apply(player, savedData)
		rawApply(self, player, savedData)
		local fighters = self.Context.Services.FighterService
		local profile, inventory = fighters and fighters:EnsureProfile(player)
		local saved = type(savedData) == "table" and savedData.Fighters or nil
		if not profile or not inventory or type(saved) ~= "table" then return end

		profile.SoulShards.Value = math.max(0, math.floor(tonumber(saved.SoulShards) or 0))
		profile.SummonCount.Value = math.max(0, math.floor(tonumber(saved.SummonCount) or 0))
		profile.MythicPity.Value = math.clamp(math.floor(tonumber(saved.MythicPity) or 0), 0, fighters.Config.Settings.HardPity - 1)
		inventory:ClearAllChildren()
		if type(saved.Inventory) == "table" then
			local usedSlots = {}
			for _, item in ipairs(saved.Inventory) do
				local definition = type(item) == "table" and fighters:GetDefinition(item.Id) or nil
				if definition then
					local fighter = Instance.new("StringValue")
					fighter.Name = definition.Id
					fighter.Value = definition.Name
					fighter:SetAttribute("Rarity", definition.Rarity)
					fighter:SetAttribute("Copies", math.max(1, math.floor(tonumber(item.Copies) or 1)))
					local slot = math.clamp(math.floor(tonumber(item.EquippedSlot) or 0), 0, fighters.Config.Settings.MaxEquipped)
					if slot > 0 and usedSlots[slot] then slot = 0 end
					if slot > 0 then usedSlots[slot] = true end
					fighter:SetAttribute("EquippedSlot", slot)
					fighter:SetAttribute("Trait", type(item.Trait) == "string" and item.Trait or "Normal")
					fighter:SetAttribute("TraitPowerMultiplier", math.max(1, tonumber(item.TraitPowerMultiplier) or 1))
					fighter.Parent = inventory
				end
			end
		end
		self:RecalculatePower(player)
	end
end

function FighterService:InstallPowerBridge()
	local dataService = self.Context.Services.DataService
	if dataService.__FighterPowerPatched then return end
	dataService.__FighterPowerPatched = true
	local rawRecalculatePower = dataService.RecalculatePower
	function dataService:RecalculatePower(player)
		rawRecalculatePower(self, player)
		local stats = player:FindFirstChild("leaderstats")
		local power = stats and stats:FindFirstChild("Power")
		local fighters = self.Context.Services.FighterService
		if power and fighters then
			local bonus = fighters:GetTeamPowerBonus(player)
			power.Value = math.floor(power.Value * (1 + bonus) * 100 + 0.5) / 100
		end
	end
end

function FighterService:Start()
	self:InstallPersistenceBridge()
	self:InstallPowerBridge()
	self.Context.Remotes.FighterAction.OnServerEvent:Connect(function(player, action, a, b)
		if action == "Summon" then
			self:Summon(player, a, b)
		elseif action == "Equip" then
			self:Equip(player, a)
		end
	end)
	Players.PlayerRemoving:Connect(function(player) self.LastSummon[player] = nil end)
	print("[Fighters] server-authoritative summons + pity + Soul Shards active")
end

return FighterService
