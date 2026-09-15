local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DevService = {}
DevService.__index = DevService

function DevService.new(context)
	return setmetatable({
		Context = context,
		SurgeToken = 0,
		ResetArmedUntil = {},
	}, DevService)
end

function DevService:IsAuthorized(player)
	if RunService:IsStudio() then return true end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then return true end
	local extra = self.Context.Config.DevUserIds
	if type(extra) == "table" then
		for _, userId in ipairs(extra) do
			if tonumber(userId) == player.UserId then return true end
		end
	end
	return false
end

function DevService:SetAccess(player)
	player:SetAttribute("AnimeRiftDev", self:IsAuthorized(player))
end

local function getPlayerObjects(player)
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return stats, profile, humanoid, root
end

function DevService:UnlockZones(profile)
	local folder = profile and profile:FindFirstChild("ZoneUnlocks")
	if not folder then return end
	for _, value in ipairs(folder:GetChildren()) do
		if value:IsA("BoolValue") then value.Value = true end
	end
end

function DevService:UnlockStyles(profile)
	local folder = profile and profile:FindFirstChild("StyleUnlocks")
	if not folder then return end
	for _, value in ipairs(folder:GetChildren()) do
		if value:IsA("BoolValue") then value.Value = true end
	end
end

function DevService:FindBoss()
	local combat = self.Context.Services.CombatService
	if not combat then return nil, nil end
	for model, data in pairs(combat.Enemies) do
		if data.Boss and data.Alive and model.Parent and model.PrimaryPart then
			return model, data
		end
	end
	return nil, nil
end

function DevService:SpawnFreshBoss()
	local combat = self.Context.Services.CombatService
	if not combat then return nil end
	for model, data in pairs(combat.Enemies) do
		if data.Boss then
			combat.Enemies[model] = nil
			if model.Parent then model:Destroy() end
		end
	end
	combat:AddEnemy(self.Context.Config.Zones[4], 0, true)
	local model = self:FindBoss()
	return model
end

function DevService:TeleportToBoss(player)
	local _, profile, _, root = getPlayerObjects(player)
	if not root then return end
	self:UnlockZones(profile)
	local boss = self:FindBoss()
	if not boss then boss = self:SpawnFreshBoss() end
	if not boss or not boss.PrimaryPart then return end
	self.Context.Services.ActivityService:MarkLegitimateTeleport(player, 4)
	root.AssemblyLinearVelocity = Vector3.zero
	local target = boss.PrimaryPart.Position + Vector3.new(0, 0, 28)
	root.CFrame = CFrame.lookAt(target, boss.PrimaryPart.Position)
	self.Context.Remotes.ZoneEntered:FireClient(player, "DEV • RIFT TYRANT", Color3.fromRGB(255, 75, 155))
end

function DevService:ResetCooldowns(player)
	local combat = self.Context.Services.CombatService
	if combat then
		combat.LastAttack[player] = nil
		combat.Combos[player] = nil
		local prefix = tostring(player.UserId) .. ":"
		for key in pairs(combat.LastAbility) do
			if string.sub(tostring(key), 1, #prefix) == prefix then
				combat.LastAbility[key] = nil
			end
		end
	end
	local dash = self.Context.Services.DashService
	if dash then dash.LastDash[player] = nil end
	self.Context.Remotes.CombatFeedback:FireClient(player, "ResetCooldowns")
end

function DevService:StartSurge(seconds)
	self.SurgeToken += 1
	local token = self.SurgeToken
	local duration = math.clamp(tonumber(seconds) or 60, 10, 300)
	self.Context.RewardMultiplier = 2
	self.Context.Remotes.WorldEvent:FireAllClients("RIFT SURGE", duration)
	self.Context:NotifyAll("DEV RIFT SURGE • 2x Coins & XP", "event")
	task.delay(duration, function()
		if token ~= self.SurgeToken then return end
		self.Context.RewardMultiplier = 1
	end)
end

function DevService:ForceRare(player)
	local region = player:GetAttribute("OpenWorldRegion")
	local zoneId = 1
	for _, zone in ipairs(self.Context.Config.Zones) do
		if zone.Name == region then zoneId = zone.Id break end
	end
	local model, rare = self.Context.Services.RareHuntService:ForceSpawn(zoneId)
	if model and rare then
		self.Context:Notify(player, "DEV • Forced rare hunt in " .. self.Context.Config.Zones[zoneId].Name, "world")
	else
		self.Context:Notify(player, "DEV • No eligible normal enemy available for rare promotion.", "error")
	end
end

function DevService:TestWildEgg(player)
	local wild = self.Context.Services.WildEggService
	local activity = self.Context.Services.ActivityService
	local _, _, _, root = getPlayerObjects(player)
	if not wild or not activity or not root then return end

	wild.ScheduleToken += 1
	wild:ClearActiveEgg()
	wild:Spawn()
	local egg = wild.ActiveEgg
	if not egg then
		self.Context:Notify(player, "DEV • Could not find a valid Wild Egg surface.", "error")
		return
	end

	local progression = activity:EnsureProfile(player)
	if progression then
		progression.SessionEffectiveSeconds.Value = math.max(
			progression.SessionEffectiveSeconds.Value,
			wild.Config.WildEgg.RequiredSessionEffectiveSeconds
		)
	end
	activity:MarkLegitimateTeleport(player, 5)
	root.AssemblyLinearVelocity = Vector3.zero
	local target = egg.Position + Vector3.new(0, 2.5, 16)
	root.CFrame = CFrame.lookAt(target, egg.Position)
	self.Context:Notify(player, "DEV • Wild Egg spawned nearby. Walk toward it to test reveal + claim validation.", "success")
end

function DevService:RequestSaveReset(player)
	local now = os.clock()
	local armedUntil = self.ResetArmedUntil[player] or 0
	if now > armedUntil then
		self.ResetArmedUntil[player] = now + 8
		self.Context:Notify(player, "DEV RESET ARMED • Click RESET SAVE again within 8 seconds to permanently wipe your current save.", "error")
		return
	end

	self.ResetArmedUntil[player] = nil
	local ok, message = self.Context.Services.ResetService:ResetPlayer(player)
	if ok then
		self.Context:Notify(player, "DEV SAVE RESET COMPLETE • " .. tostring(message), "success")
	else
		self.Context:Notify(player, "DEV SAVE RESET ERROR • " .. tostring(message), "error")
	end
end

function DevService:Execute(player, command)
	if not self:IsAuthorized(player) then
		warn("Blocked unauthorized Anime Rift dev command from", player.Name, command)
		return
	end
	if type(command) ~= "string" then return end

	local stats, profile, humanoid = getPlayerObjects(player)
	if not stats or not profile then return end
	local data = self.Context.Services.DataService

	if command == "TestReady" then
		stats.Level.Value = math.max(stats.Level.Value, 25)
		stats.Coins.Value += 100000
		stats.Gems.Value += 6000
		local progression = profile:FindFirstChild("Progression")
		local tickets = progression and progression:FindFirstChild("RiftTickets")
		if tickets then tickets.Value += 10 end
		self:UnlockZones(profile)
		self:UnlockStyles(profile)
		data:RecalculatePower(player)
		self.Context:Notify(player, "DEV TEST READY • Lv25+ • 100k Coins • 6k Gems • 10 Tickets • all zones/styles", "success")
	elseif command == "Level10" then
		stats.Level.Value += 10
		data:RecalculatePower(player)
		self.Context:Notify(player, "DEV • +10 Levels", "level")
	elseif command == "Coins10K" then
		stats.Coins.Value += 10000
		self.Context:Notify(player, "DEV • +10,000 Coins", "loot")
	elseif command == "Gems100" then
		stats.Gems.Value += 100
		self.Context:Notify(player, "DEV • +100 Gems", "loot")
	elseif command == "UnlockZones" then
		self:UnlockZones(profile)
		self.Context:Notify(player, "DEV • All zones unlocked", "success")
	elseif command == "UnlockStyles" then
		self:UnlockStyles(profile)
		self.Context:Notify(player, "DEV • All styles unlocked", "success")
	elseif command == "Heal" then
		if humanoid then humanoid.Health = humanoid.MaxHealth end
		self.Context:Notify(player, "DEV • Full heal", "success")
	elseif command == "ResetCooldowns" then
		self:ResetCooldowns(player)
		self.Context:Notify(player, "DEV • Cooldowns reset", "success")
	elseif command == "Boss" then
		self:TeleportToBoss(player)
	elseif command == "RespawnBoss" then
		self:SpawnFreshBoss()
		self.Context:Notify(player, "DEV • Rift Tyrant respawned", "boss")
	elseif command == "Rare" then
		self:ForceRare(player)
	elseif command == "WildEgg" then
		self:TestWildEgg(player)
	elseif command == "TestRelic" then
		self.Context.Services.LootService:GrantRelic(player, 4, true)
	elseif command == "Save" then
		data:Save(player)
		self.Context:Notify(player, "DEV • Save requested", "success")
	elseif command == "ResetSave" then
		self:RequestSaveReset(player)
	elseif command == "Hub" then
		self.Context.Services.ActivityService:MarkLegitimateTeleport(player, 4)
		self.Context.Services.WorldService:TeleportToHub(player)
		self.Context.Remotes.ZoneEntered:FireClient(player, "Central Hub", Color3.fromRGB(154, 102, 235))
	elseif command == "Surge" then
		self:StartSurge(60)
	end
end

function DevService:Start()
	for _, player in ipairs(Players:GetPlayers()) do self:SetAccess(player) end
	Players.PlayerAdded:Connect(function(player) self:SetAccess(player) end)
	Players.PlayerRemoving:Connect(function(player) self.ResetArmedUntil[player] = nil end)
	self.Context.Remotes.DevCommand.OnServerEvent:Connect(function(player, command)
		self:Execute(player, command)
	end)
end

return DevService
