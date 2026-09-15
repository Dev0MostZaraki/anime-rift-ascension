local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local CoreLoopConfig = require(AnimeRift:WaitForChild("CoreLoopConfig"))

local CoreLoopService = {}
CoreLoopService.__index = CoreLoopService

function CoreLoopService.new(context)
	return setmetatable({
		Context = context,
		Config = CoreLoopConfig,
	}, CoreLoopService)
end

local function intValue(parent, name, default)
	local found = parent:FindFirstChild(name)
	if found and found:IsA("IntValue") then return found end
	if found then found:Destroy() end
	local value = Instance.new("IntValue")
	value.Name = name
	value.Value = default or 0
	value.Parent = parent
	return value
end

function CoreLoopService:EnsureRegionalProgress(player)
	local profile = player:FindFirstChild("RiftProfile")
	if not profile then return nil end
	local folder = profile:FindFirstChild("RegionalQuest")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RegionalQuest"
		folder.Parent = profile
	end
	for zoneId in pairs(self.Config.RegionQuestChains) do
		intValue(folder, "Zone" .. zoneId .. "Stage", 1)
		intValue(folder, "Zone" .. zoneId .. "Progress", 0)
	end
	return folder
end

function CoreLoopService:InstallPersistenceBridge()
	local dataService = self.Context.Services.DataService
	if dataService.__CoreLoopPersistencePatched then return end
	dataService.__CoreLoopPersistencePatched = true

	local rawCreateProfile = dataService.CreateProfile
	function dataService:CreateProfile(player)
		rawCreateProfile(self, player)
		local core = self.Context.Services.CoreLoopService
		if core then core:EnsureRegionalProgress(player) end
	end

	local rawSerialize = dataService.Serialize
	function dataService:Serialize(player)
		local payload = rawSerialize(self, player)
		if not payload then return nil end
		local core = self.Context.Services.CoreLoopService
		local folder = core and core:EnsureRegionalProgress(player)
		payload.RegionQuest = {}
		if folder then
			for zoneId in pairs(core.Config.RegionQuestChains) do
				local stage = folder:FindFirstChild("Zone" .. zoneId .. "Stage")
				local progress = folder:FindFirstChild("Zone" .. zoneId .. "Progress")
				payload.RegionQuest["Zone" .. zoneId] = {
					Stage = stage and stage.Value or 1,
					Progress = progress and progress.Value or 0,
				}
			end
		end
		return payload
	end

	local rawApply = dataService.Apply
	function dataService:Apply(player, savedData)
		rawApply(self, player, savedData)
		local core = self.Context.Services.CoreLoopService
		local folder = core and core:EnsureRegionalProgress(player)
		local regionData = type(savedData) == "table" and savedData.RegionQuest or nil
		if folder and type(regionData) == "table" then
			for zoneId, chain in pairs(core.Config.RegionQuestChains) do
				local saved = regionData["Zone" .. zoneId]
				local stage = folder:FindFirstChild("Zone" .. zoneId .. "Stage")
				local progress = folder:FindFirstChild("Zone" .. zoneId .. "Progress")
				if stage and progress and type(saved) == "table" then
					stage.Value = math.clamp(math.floor(tonumber(saved.Stage) or 1), 1, #chain + 1)
					progress.Value = math.max(0, math.floor(tonumber(saved.Progress) or 0))
				end
			end
		end
	end
end

function CoreLoopService:GetQuestState(player, zoneId)
	local chain = self.Config.RegionQuestChains[zoneId]
	local folder = self:EnsureRegionalProgress(player)
	if not chain or not folder then return nil end
	local stageValue = folder:FindFirstChild("Zone" .. zoneId .. "Stage")
	local progressValue = folder:FindFirstChild("Zone" .. zoneId .. "Progress")
	if not stageValue or not progressValue then return nil end
	local stage = stageValue.Value
	return {
		Chain = chain,
		Stage = stage,
		Progress = progressValue.Value,
		Step = chain[stage],
		StageValue = stageValue,
		ProgressValue = progressValue,
	}
end

function CoreLoopService:CompleteStep(player, zoneId, state)
	local step = state.Step
	if not step then return end
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end

	stats.Coins.Value += math.max(0, math.floor(step.Coins or 0))
	stats.Gems.Value += math.max(0, math.floor(step.Gems or 0))
	if (step.XP or 0) > 0 then
		self.Context.Services.DataService:AddXP(player, step.XP)
	end

	local chain = state.Chain
	state.ProgressValue.Value = 0
	state.StageValue.Value = math.min(#chain + 1, state.StageValue.Value + 1)

	local reward = "+" .. tostring(step.Coins or 0) .. " Coins"
	if (step.Gems or 0) > 0 then reward ..= " • +" .. tostring(step.Gems) .. " Gems" end
	if (step.XP or 0) > 0 then reward ..= " • +" .. tostring(step.XP) .. " XP" end
	self.Context:Notify(player, "REGION QUEST COMPLETE • " .. step.Title .. " • " .. reward, "success")

	if state.StageValue.Value > #chain then
		self.Context:Notify(player, string.upper(chain.Region) .. " • QUEST CHAIN MASTERED", "level")
	else
		local nextStep = chain[state.StageValue.Value]
		self.Context:Notify(player, "NEW REGION QUEST • " .. nextStep.Title .. " • " .. nextStep.Description, "info")
	end
end

function CoreLoopService:RecordKill(player, data)
	local zoneId = data and data.Zone and data.Zone.Id
	if not zoneId then return end
	local state = self:GetQuestState(player, zoneId)
	if not state or not state.Step then return end
	local step = state.Step

	local qualifies = false
	if step.Type == "Kills" then
		qualifies = data.Boss ~= true
	elseif step.Type == "Elites" then
		qualifies = data.Elite == true and data.Boss ~= true
	elseif step.Type == "Boss" then
		qualifies = data.Boss == true
	end
	if not qualifies then return end

	state.ProgressValue.Value = math.min(step.Target, state.ProgressValue.Value + 1)
	if state.ProgressValue.Value >= step.Target then
		self:CompleteStep(player, zoneId, state)
	end
end

function CoreLoopService:ApplyElite(model, data, zone)
	if not model or not model.Parent or not data or data.Boss or data.Elite then return end
	local elite = self.Config.Elite
	data.Elite = true
	data.Name = elite.Names[zone.Id] or ("Elite " .. tostring(data.Name))
	data.HP = math.floor(data.HP * elite.HPMultiplier)
	data.MaxHP = data.HP
	data.Damage = math.floor(data.Damage * elite.DamageMultiplier)
	data.Coins = math.floor(data.Coins * elite.CoinMultiplier)
	data.XP = math.floor(data.XP * elite.XPMultiplier)
	model.Name = data.Name
	model:SetAttribute("Elite", true)
	pcall(function() model:ScaleTo(elite.Scale or 1.12) end)

	local highlight = Instance.new("Highlight")
	highlight.Name = "EliteOutline"
	highlight.FillColor = zone.Color:Lerp(Color3.fromRGB(230, 194, 104), 0.35)
	highlight.FillTransparency = 0.88
	highlight.OutlineColor = Color3.fromRGB(231, 196, 111)
	highlight.OutlineTransparency = 0.18
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model
end

function CoreLoopService:InstallCombatBridge()
	local combat = self.Context.Services.CombatService
	if combat.__CoreLoopCombatPatched then return end
	combat.__CoreLoopCombatPatched = true

	local rawAddEnemy = combat.AddEnemy
	function combat:AddEnemy(zone, index, boss)
		local before = {}
		for model in pairs(self.Enemies) do before[model] = true end
		rawAddEnemy(self, zone, index, boss)
		if boss or index ~= self.Context.Config.Game.EnemyCountPerZone then return end
		local core = self.Context.Services.CoreLoopService
		for model, data in pairs(self.Enemies) do
			if not before[model] and data.Alive then
				core:ApplyElite(model, data, zone)
				self:UpdateLabel(model)
				break
			end
		end
	end

	local rawKill = combat.Kill
	function combat:Kill(player, model)
		local data = self.Enemies[model]
		if data and data.Alive then
			local core = self.Context.Services.CoreLoopService
			if core then core:RecordKill(player, data) end
		end
		return rawKill(self, player, model)
	end
end

function CoreLoopService:Start()
	self:InstallPersistenceBridge()
	self:InstallCombatBridge()
	print("[Core Loop] regional quest chains + elites active")
end

return CoreLoopService
