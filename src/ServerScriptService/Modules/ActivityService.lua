local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local ProgressionConfig = require(AnimeRift:WaitForChild("ProgressionConfig"))

local ActivityService = {}
ActivityService.__index = ActivityService

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

local function dayKey()
	return os.date("!%Y-%m-%d")
end

function ActivityService.new(context)
	return setmetatable({
		Context = context,
		Config = ProgressionConfig,
		State = {},
	}, ActivityService)
end

function ActivityService:EnsureProfile(player)
	local profile = player:FindFirstChild("RiftProfile")
	if not profile then return nil end

	local folder = profile:FindFirstChild("Progression")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Progression"
		folder.Parent = profile
	end

	ensureValue("IntValue", folder, "LifetimeEffectiveSeconds", 0)
	ensureValue("IntValue", folder, "DailyEffectiveSeconds", 0)
	ensureValue("IntValue", folder, "DailyRewardTier", 0)
	ensureValue("StringValue", folder, "DailyKey", dayKey())
	ensureValue("IntValue", folder, "RiftTickets", 0)
	ensureValue("IntValue", folder, "SessionEffectiveSeconds", 0)
	ensureValue("NumberValue", folder, "Resonance", 0)

	local wildIndex = folder:FindFirstChild("WildEggIndex")
	if not wildIndex then
		wildIndex = Instance.new("Folder")
		wildIndex.Name = "WildEggIndex"
		wildIndex.Parent = folder
	end
	for _, tier in ipairs(self.Config.WildEgg.Tiers) do
		ensureValue("IntValue", wildIndex, tier.Id, 0)
	end

	if folder.DailyKey.Value ~= dayKey() then
		folder.DailyKey.Value = dayKey()
		folder.DailyEffectiveSeconds.Value = 0
		folder.DailyRewardTier.Value = 0
	end
	return folder
end

function ActivityService:GetState(player)
	local state = self.State[player]
	if state then return state end
	state = {
		ActiveUntil = 0,
		LastPosition = nil,
		LastRoot = nil,
		SuspiciousUntil = 0,
	}
	self.State[player] = state
	return state
end

function ActivityService:Record(player, source, strength)
	if not player or player.Parent ~= Players then return end
	local state = self:GetState(player)
	local grace = self.Config.EffectivePlaytime.ActiveGraceSeconds
	local extension = math.clamp(tonumber(strength) or 1, 0, 3) * 1.5
	state.ActiveUntil = math.max(state.ActiveUntil, os.clock() + grace + extension)
	state.LastSource = tostring(source or "activity")
end

function ActivityService:MarkLegitimateTeleport(player, seconds)
	player:SetAttribute("LegitimateTeleportUntil", os.clock() + math.max(1, tonumber(seconds) or 3))
end

function ActivityService:IsSensitiveRewardAllowed(player)
	local state = self:GetState(player)
	return os.clock() >= (state.SuspiciousUntil or 0)
end

function ActivityService:GetSessionEffectiveSeconds(player)
	local folder = self:EnsureProfile(player)
	return folder and folder.SessionEffectiveSeconds.Value or 0
end

function ActivityService:GetLuckMultiplier(player)
	local folder = self:EnsureProfile(player)
	local resonanceBonus = 0
	if folder then
		resonanceBonus = (folder.Resonance.Value / 100) * self.Config.Resonance.MaxLuckBonus
	end

	local petLuck = 0
	local inventory = player:FindFirstChild("PetInventory")
	if inventory then
		for _, pet in ipairs(inventory:GetChildren()) do
			if pet:GetAttribute("Equipped") == true then
				petLuck += math.max(0, tonumber(pet:GetAttribute("LuckBonus")) or 0)
			end
		end
	end
	return 1 + resonanceBonus + petLuck
end

function ActivityService:GrantReachedDailyRewards(player, folder)
	local cfg = self.Config.EffectivePlaytime
	local tier = folder.DailyRewardTier.Value
	while tier < #cfg.DailyRewards do
		local nextReward = cfg.DailyRewards[tier + 1]
		if folder.DailyEffectiveSeconds.Value < nextReward.Seconds then break end
		tier += 1
		folder.DailyRewardTier.Value = tier
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			stats.Coins.Value += math.max(0, math.floor(nextReward.Coins or 0))
			stats.Gems.Value += math.max(0, math.floor(nextReward.Gems or 0))
		end
		folder.RiftTickets.Value += math.max(0, math.floor(nextReward.RiftTickets or 0))
		local minutes = math.floor(nextReward.Seconds / 60)
		local rewardText = string.format("%dm EFFECTIVE PLAYTIME", minutes)
		if (nextReward.RiftTickets or 0) > 0 then rewardText ..= " • +" .. nextReward.RiftTickets .. " Rift Ticket" end
		self.Context:Notify(player, rewardText, "success")
	end
end

function ActivityService:StepPlayer(player, dt)
	local folder = self:EnsureProfile(player)
	if not folder then return end
	if folder.DailyKey.Value ~= dayKey() then
		folder.DailyKey.Value = dayKey()
		folder.DailyEffectiveSeconds.Value = 0
		folder.DailyRewardTier.Value = 0
	end

	local state = self:GetState(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and humanoid and humanoid.Health > 0 then
		if state.LastRoot ~= root then
			state.LastRoot = root
			state.LastPosition = root.Position
		else
			local previous = state.LastPosition
			state.LastPosition = root.Position
			if previous then
				local distance = (root.Position - previous).Magnitude
				local cfg = self.Config.EffectivePlaytime
				if distance >= cfg.MinimumMovementStuds and distance <= cfg.MaximumPlausibleMovementStudsPerSample then
					self:Record(player, "movement", 0.25)
				elseif distance > cfg.MaximumPlausibleMovementStudsPerSample then
					local legitimateUntil = tonumber(player:GetAttribute("LegitimateTeleportUntil")) or 0
					if os.clock() > legitimateUntil then
						state.SuspiciousUntil = os.clock() + self.Config.WildEgg.TeleportSuspicionSeconds
					end
				end
			end
		end
	end

	if os.clock() <= (state.ActiveUntil or 0) then
		state.TickCarry = (state.TickCarry or 0) + dt
		while state.TickCarry >= 1 do
			state.TickCarry -= 1
			folder.LifetimeEffectiveSeconds.Value += 1
			folder.DailyEffectiveSeconds.Value += 1
			folder.SessionEffectiveSeconds.Value += 1
		end
	end

	local resonance = math.clamp(folder.SessionEffectiveSeconds.Value / self.Config.Resonance.SecondsToCap, 0, 1) * 100
	folder.Resonance.Value = math.floor(resonance * 10 + 0.5) / 10
	self:GrantReachedDailyRewards(player, folder)
end

function ActivityService:InstallPersistenceBridge()
	local dataService = self.Context.Services.DataService
	if dataService.__ActivityPersistencePatched then return end
	dataService.__ActivityPersistencePatched = true

	local rawCreateProfile = dataService.CreateProfile
	function dataService:CreateProfile(player)
		rawCreateProfile(self, player)
		local activity = self.Context.Services.ActivityService
		if activity then activity:EnsureProfile(player) end
	end

	local rawSerialize = dataService.Serialize
	function dataService:Serialize(player)
		local payload = rawSerialize(self, player)
		if not payload then return nil end
		local activity = self.Context.Services.ActivityService
		local folder = activity and activity:EnsureProfile(player)
		if folder then
			payload.Progression = {
				LifetimeEffectiveSeconds = folder.LifetimeEffectiveSeconds.Value,
				DailyEffectiveSeconds = folder.DailyEffectiveSeconds.Value,
				DailyRewardTier = folder.DailyRewardTier.Value,
				DailyKey = folder.DailyKey.Value,
				RiftTickets = folder.RiftTickets.Value,
				WildEggIndex = {},
			}
			for _, item in ipairs(folder.WildEggIndex:GetChildren()) do
				if item:IsA("IntValue") then payload.Progression.WildEggIndex[item.Name] = item.Value end
			end
		end
		return payload
	end

	local rawApply = dataService.Apply
	function dataService:Apply(player, savedData)
		rawApply(self, player, savedData)
		local activity = self.Context.Services.ActivityService
		local folder = activity and activity:EnsureProfile(player)
		local saved = type(savedData) == "table" and savedData.Progression or nil
		if not folder or type(saved) ~= "table" then return end
		folder.LifetimeEffectiveSeconds.Value = math.max(0, math.floor(tonumber(saved.LifetimeEffectiveSeconds) or 0))
		folder.DailyKey.Value = type(saved.DailyKey) == "string" and saved.DailyKey or dayKey()
		folder.DailyEffectiveSeconds.Value = math.max(0, math.floor(tonumber(saved.DailyEffectiveSeconds) or 0))
		folder.DailyRewardTier.Value = math.max(0, math.floor(tonumber(saved.DailyRewardTier) or 0))
		folder.RiftTickets.Value = math.max(0, math.floor(tonumber(saved.RiftTickets) or 0))
		if type(saved.WildEggIndex) == "table" then
			for name, amount in pairs(saved.WildEggIndex) do
				local value = folder.WildEggIndex:FindFirstChild(name)
				if value and value:IsA("IntValue") then value.Value = math.max(0, math.floor(tonumber(amount) or 0)) end
			end
		end
		if folder.DailyKey.Value ~= dayKey() then
			folder.DailyKey.Value = dayKey()
			folder.DailyEffectiveSeconds.Value = 0
			folder.DailyRewardTier.Value = 0
		end
	end
end

function ActivityService:InstallGameplayBridges()
	local combat = self.Context.Services.CombatService
	if combat and not combat.__ActivityPatched then
		combat.__ActivityPatched = true
		local rawAttack = combat.Attack
		function combat:Attack(player)
			local before = self.LastAttack[player] or 0
			rawAttack(self, player)
			if (self.LastAttack[player] or 0) ~= before then
				self.Context.Services.ActivityService:Record(player, "combat", 1)
			end
		end

		local rawAbility = combat.Ability
		function combat:Ability(player, name)
			local key = tostring(player.UserId) .. ":" .. tostring(name)
			local before = self.LastAbility[key] or 0
			rawAbility(self, player, name)
			if (self.LastAbility[key] or 0) ~= before then
				self.Context.Services.ActivityService:Record(player, "ability", 1.5)
			end
		end

		local rawKill = combat.Kill
		function combat:Kill(player, model)
			local data = self.Enemies[model]
			if data and data.Alive then
				self.Context.Services.ActivityService:Record(player, data.Boss and "boss" or "kill", data.Boss and 3 or 2)
			end
			return rawKill(self, player, model)
		end
	end

	local pets = self.Context.Services.PetService
	if pets and not pets.__ActivityPatched then
		pets.__ActivityPatched = true
		local rawHatch = pets.Hatch
		function pets:Hatch(player, eggId)
			local inventory = player:FindFirstChild("PetInventory")
			local before = inventory and #inventory:GetChildren() or 0
			rawHatch(self, player, eggId)
			inventory = player:FindFirstChild("PetInventory")
			local after = inventory and #inventory:GetChildren() or 0
			if after > before then self.Context.Services.ActivityService:Record(player, "hatch", 1.25) end
		end
	end
end

function ActivityService:Start()
	self:InstallPersistenceBridge()
	self:InstallGameplayBridges()
	Players.PlayerRemoving:Connect(function(player) self.State[player] = nil end)
	task.spawn(function()
		local tickSeconds = self.Config.EffectivePlaytime.TickSeconds
		while true do
			local started = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do self:StepPlayer(player, tickSeconds) end
			task.wait(math.max(0.05, tickSeconds - (os.clock() - started)))
		end
	end)
	print("[Activity] effective playtime + resonance active")
end

return ActivityService
