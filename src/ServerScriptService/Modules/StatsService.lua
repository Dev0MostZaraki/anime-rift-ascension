local StatsService = {}
StatsService.__index = StatsService

function StatsService.new(context)
	return setmetatable({
		Context = context,
		HealthConnections = {},
	}, StatsService)
end

local function createValue(className, name, value, parent)
	local object = parent:FindFirstChild(name)
	if object then return object end
	object = Instance.new(className)
	object.Name = name
	object.Value = value
	object.Parent = parent
	return object
end

function StatsService:EnsureCombatStats(player)
	local folder = player:FindFirstChild("CombatStats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "CombatStats"
		folder.Parent = player
	end
	createValue("IntValue", "MaxHealth", self.Context.Config.Game.BaseHealth, folder)
	createValue("NumberValue", "Defense", self.Context.Config.Game.BaseDefense, folder)
	createValue("NumberValue", "DamageReduction", 0, folder)
	return folder
end

function StatsService:Calculate(player)
	local cfg = self.Context.Config.Game
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	if not stats or not profile then return nil end
	local combatStats = self:EnsureCombatStats(player)
	local level = math.max(1, stats.Level.Value)
	local style = self.Context.Config.Styles[profile.EquippedStyle.Value] or self.Context.Config.Styles.RiftBlade

	local health = cfg.BaseHealth + (level - 1) * cfg.HealthPerLevel
	health = math.floor(health * (style.HealthMultiplier or 1) + (style.HealthBonus or 0))
	local defense = cfg.BaseDefense + (level - 1) * cfg.DefensePerLevel + (style.DefenseBonus or 0)
	defense = math.max(0, defense)
	local reduction = defense / (defense + cfg.DefenseConstant)
	reduction = math.clamp(reduction, 0, cfg.MaxDamageReduction)

	combatStats.MaxHealth.Value = health
	combatStats.Defense.Value = math.floor(defense * 10 + 0.5) / 10
	combatStats.DamageReduction.Value = math.floor(reduction * 10000 + 0.5) / 10000
	return combatStats
end

function StatsService:ApplyCharacter(player, fullHeal)
	local combatStats = self:Calculate(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not combatStats or not humanoid then return end

	local oldMax = math.max(1, humanoid.MaxHealth)
	local ratio = math.clamp(humanoid.Health / oldMax, 0, 1)
	humanoid.MaxHealth = combatStats.MaxHealth.Value
	if fullHeal then
		humanoid.Health = humanoid.MaxHealth
	else
		humanoid.Health = math.clamp(math.max(1, humanoid.MaxHealth * ratio), 0, humanoid.MaxHealth)
	end

	self:BindDefense(player, humanoid)
end

function StatsService:BindDefense(player, humanoid)
	local previous = self.HealthConnections[player]
	if previous then previous:Disconnect() end
	local internal = false
	local lastHealth = humanoid.Health

	self.HealthConnections[player] = humanoid.HealthChanged:Connect(function(newHealth)
		if internal then
			lastHealth = newHealth
			return
		end
		if newHealth < lastHealth then
			local combatStats = player:FindFirstChild("CombatStats")
			local reductionValue = combatStats and combatStats:FindFirstChild("DamageReduction")
			local reduction = reductionValue and reductionValue.Value or 0
			if reduction > 0 then
				local rawDamage = lastHealth - newHealth
				local restored = rawDamage * reduction
				local mitigatedHealth = math.min(humanoid.MaxHealth, newHealth + restored)
				if mitigatedHealth > newHealth then
					internal = true
					humanoid.Health = mitigatedHealth
					internal = false
					newHealth = mitigatedHealth
				end
			end
		end
		lastHealth = newHealth
	end)
end

function StatsService:Recalculate(player, preserveHealth)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local oldRatio = humanoid and humanoid.MaxHealth > 0 and humanoid.Health / humanoid.MaxHealth or 1
	local combatStats = self:Calculate(player)
	self.Context.Services.DataService:RecalculatePower(player)
	if humanoid and combatStats then
		humanoid.MaxHealth = combatStats.MaxHealth.Value
		if preserveHealth == false then
			humanoid.Health = humanoid.MaxHealth
		else
			humanoid.Health = math.clamp(humanoid.MaxHealth * oldRatio, 1, humanoid.MaxHealth)
		end
	end
end

function StatsService:Cleanup(player)
	local connection = self.HealthConnections[player]
	if connection then connection:Disconnect() end
	self.HealthConnections[player] = nil
end

function StatsService:Start()
end

return StatsService
