local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local HuntConfig = require(AnimeRift:WaitForChild("HuntConfig"))

local RareHuntService = {}
RareHuntService.__index = RareHuntService

function RareHuntService.new(context)
	return setmetatable({
		Context = context,
		Config = HuntConfig,
		SpawnSerial = 0,
	}, RareHuntService)
end

function RareHuntService:Promote(model, data, zone)
	if not model or not model.Parent or not data or data.Boss or data.Elite or data.Rare then return false end
	local rare = self.Config.Rares[zone.Id]
	if not rare then return false end

	data.Rare = true
	data.RareId = rare.Id
	data.Name = rare.Name
	data.HP = math.floor(data.HP * rare.HPMultiplier)
	data.MaxHP = data.HP
	data.Damage = math.floor(data.Damage * rare.DamageMultiplier)
	data.Coins = math.floor(data.Coins * rare.CoinMultiplier)
	data.XP = math.floor(data.XP * rare.XPMultiplier)
	data.RareGems = math.random(rare.Gems[1], rare.Gems[2])
	data.BonusRelicChance = rare.BonusRelicChance
	model.Name = rare.Name
	model:SetAttribute("RareHunt", true)
	model:SetAttribute("RareId", rare.Id)
	pcall(function() model:ScaleTo(rare.Scale or 1.18) end)

	local highlight = Instance.new("Highlight")
	highlight.Name = "RareHuntOutline"
	highlight.FillColor = zone.Color:Lerp(Color3.fromRGB(239, 205, 112), 0.24)
	highlight.FillTransparency = 0.91
	highlight.OutlineColor = Color3.fromRGB(246, 205, 107)
	highlight.OutlineTransparency = 0.08
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model

	self.SpawnSerial += 1
	self.Context:NotifyAll("RARE HUNT • " .. rare.Hint .. " • " .. string.upper(zone.Name), "world")
	return true
end

function RareHuntService:ForceSpawn(zoneId)
	local zone = self.Context.Config.Zones[math.clamp(tonumber(zoneId) or 1, 1, #self.Context.Config.Zones)]
	local combat = self.Context.Services.CombatService
	if not zone or not combat then return nil end
	for model, data in pairs(combat.Enemies) do
		if data.Alive and data.Zone and data.Zone.Id == zone.Id and not data.Boss and not data.Elite and not data.Rare then
			if self:Promote(model, data, zone) then
				combat:UpdateLabel(model)
				return model, data
			end
		end
	end
	return nil
end

function RareHuntService:InstallCombatBridge()
	local combat = self.Context.Services.CombatService
	if combat.__RareHuntPatched then return end
	combat.__RareHuntPatched = true

	local rawAddEnemy = combat.AddEnemy
	function combat:AddEnemy(zone, index, boss)
		local before = {}
		for model in pairs(self.Enemies) do before[model] = true end
		rawAddEnemy(self, zone, index, boss)
		if boss or index == self.Context.Config.Game.EnemyCountPerZone then return end

		local hunt = self.Context.Services.RareHuntService
		local chance = hunt.Config.RareChance[zone.Id] or 0
		if math.random() > chance then return end
		for model, data in pairs(self.Enemies) do
			if not before[model] and data.Alive and not data.Elite then
				if hunt:Promote(model, data, zone) then self:UpdateLabel(model) end
				break
			end
	end

	local rawKill = combat.Kill
	function combat:Kill(player, model)
		local data = self.Enemies[model]
		if data and data.Alive and data.Rare then
			local stats = player:FindFirstChild("leaderstats")
			if stats then
				local gems = math.max(0, math.floor(data.RareGems or 0))
				stats.Gems.Value += gems
				self.Context:NotifyAll(player.Name .. " hunted " .. data.Name .. "!", "world")
				self.Context:Notify(player, "RARE HUNT CLEAR • +" .. gems .. " Gems • guaranteed relic", "success")
			end
		end
		return rawKill(self, player, model)
	end
end

function RareHuntService:Start()
	self:InstallCombatBridge()
	print("[Rare Hunt] named rare enemies active")
end

return RareHuntService
