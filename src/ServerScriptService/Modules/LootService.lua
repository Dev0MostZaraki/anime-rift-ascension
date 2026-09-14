local LootService = {}
LootService.__index = LootService

local normalOrder = {"Common", "Rare", "Epic", "Legendary", "Mythic"}

function LootService.new(context)
	return setmetatable({Context = context}, LootService)
end

function LootService:RollRarity(boss)
	if boss then
		local roll = math.random() * 100
		if roll <= 10 then return "Mythic" end
		if roll <= 45 then return "Legendary" end
		return "Epic"
	end

	local roll = math.random() * 100
	local total = 0
	for _, rarity in ipairs(normalOrder) do
		local data = self.Context.Config.RelicRarities[rarity]
		total += data.Weight
		if roll <= total then return rarity end
	end
	return "Common"
end

function LootService:GrantRelic(player, zoneId, boss)
	zoneId = math.clamp(tonumber(zoneId) or 1, 1, #self.Context.Config.Zones)
	local rarity = self:RollRarity(boss)
	local rarityData = self.Context.Config.RelicRarities[rarity]
	local names = self.Context.Config.RelicNames[zoneId]
	local name = names[math.random(1, #names)]
	local zoneScale = 1 + (zoneId - 1) * 0.35
	local powerBonus = rarityData.Power * zoneScale
	local critBonus = rarityData.Crit * (1 + (zoneId - 1) * 0.12)
	powerBonus = math.floor(powerBonus * 1000 + 0.5) / 1000
	critBonus = math.floor(critBonus * 10000 + 0.5) / 10000

	local relic = self.Context.Services.DataService:AddRelic(player, name, rarity, powerBonus, critBonus, zoneId)
	if relic then
		local critText = critBonus > 0 and (" • +" .. string.format("%.1f", critBonus * 100) .. "% Crit") or ""
		self.Context:Notify(player, "RELIC DROP • " .. rarity .. " " .. name .. " • +" .. math.floor(powerBonus * 100) .. "% Power" .. critText, rarity)
	end
	return relic
end

function LootService:DropFromEnemy(player, enemyData)
	if not enemyData or not enemyData.Zone then return end
	local cfg = self.Context.Config.Game
	if enemyData.Boss then
		for _ = 1, cfg.BossRelicDrops do
			self:GrantRelic(player, enemyData.Zone.Id, true)
		end
		return
	end
	if math.random() <= cfg.RelicDropChance then
		self:GrantRelic(player, enemyData.Zone.Id, false)
	end
end

function LootService:GetEquippedCount(player)
	local inventory = player:FindFirstChild("RelicInventory")
	if not inventory then return 0 end
	local count = 0
	for _, relic in ipairs(inventory:GetChildren()) do
		if relic:GetAttribute("Equipped") == true then count += 1 end
	end
	return count
end

local function relicScore(relic)
	local power = tonumber(relic:GetAttribute("PowerBonus")) or 0
	local crit = tonumber(relic:GetAttribute("CritBonus")) or 0
	return power + crit * 5
end

function LootService:Equip(player, relicId)
	local inventory = player:FindFirstChild("RelicInventory")
	if not inventory or type(relicId) ~= "string" then return end

	if relicId == "__BEST__" then
		local relics = inventory:GetChildren()
		table.sort(relics, function(a, b) return relicScore(a) > relicScore(b) end)
		for _, relic in ipairs(relics) do relic:SetAttribute("Equipped", false) end
		for i = 1, math.min(self.Context.Config.Game.MaxEquippedRelics, #relics) do
			relics[i]:SetAttribute("Equipped", true)
		end
		self.Context.Services.DataService:RecalculatePower(player)
		self.Context:Notify(player, "Best relics equipped.", "success")
		return
	end

	local relic = inventory:FindFirstChild(relicId)
	if not relic then return end
	if relic:GetAttribute("Equipped") == true then
		relic:SetAttribute("Equipped", false)
	else
		if self:GetEquippedCount(player) >= self.Context.Config.Game.MaxEquippedRelics then
			self.Context:Notify(player, "You can equip only " .. self.Context.Config.Game.MaxEquippedRelics .. " relics.", "error")
			return
		end
		relic:SetAttribute("Equipped", true)
	end
	self.Context.Services.DataService:RecalculatePower(player)
end

function LootService:Start()
	self.Context.Remotes.EquipRelic.OnServerEvent:Connect(function(player, relicId)
		self:Equip(player, relicId)
	end)
end

return LootService
