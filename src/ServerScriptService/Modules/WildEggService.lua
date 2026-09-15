local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local ProgressionConfig = require(AnimeRift:WaitForChild("ProgressionConfig"))

local WildEggService = {}
WildEggService.__index = WildEggService

local function weightedRoll(entries, luckMultiplier)
	luckMultiplier = math.max(1, tonumber(luckMultiplier) or 1)
	local total = 0
	local weights = table.create(#entries)
	for index, entry in ipairs(entries) do
		local rank = tonumber(entry.Rank) or (index - 1)
		local weight = math.max(0, tonumber(entry.Weight) or 0) * (luckMultiplier ^ math.max(0, rank * 0.32))
		weights[index] = weight
		total += weight
	end
	if total <= 0 then return entries[1] end
	local roll = math.random() * total
	local cursor = 0
	for index, entry in ipairs(entries) do
		cursor += weights[index]
		if roll <= cursor then return entry end
	end
	return entries[#entries]
end

function WildEggService.new(context)
	return setmetatable({
		Context = context,
		Config = ProgressionConfig,
		ActiveEgg = nil,
		Revealed = {},
		RevealAt = {},
		ScheduleToken = 0,
	}, WildEggService)
end

function WildEggService:InstallPetMetadataPersistence()
	local dataService = self.Context.Services.DataService
	if dataService.__PetMetadataPersistencePatched then return end
	dataService.__PetMetadataPersistencePatched = true

	local rawSerialize = dataService.Serialize
	function dataService:Serialize(player)
		local payload = rawSerialize(self, player)
		if not payload or type(payload.Pets) ~= "table" then return payload end
		local inventory = player:FindFirstChild("PetInventory")
		if not inventory then return payload end
		for _, saved in ipairs(payload.Pets) do
			local pet = type(saved.Id) == "string" and inventory:FindFirstChild(saved.Id) or nil
			if pet then
				saved.Role = pet:GetAttribute("Role")
				saved.Mutation = pet:GetAttribute("Mutation")
				saved.MutationPower = pet:GetAttribute("MutationPower")
				saved.LuckBonus = pet:GetAttribute("LuckBonus")
				saved.DropBonus = pet:GetAttribute("DropBonus")
				saved.Source = pet:GetAttribute("Source")
				saved.BaseBonus = pet:GetAttribute("BaseBonus")
			end
		end
		return payload
	end

	local rawApply = dataService.Apply
	function dataService:Apply(player, savedData)
		rawApply(self, player, savedData)
		if type(savedData) ~= "table" or type(savedData.Pets) ~= "table" then return end
		local inventory = player:FindFirstChild("PetInventory")
		if not inventory then return end
		for _, saved in ipairs(savedData.Pets) do
			local pet = type(saved.Id) == "string" and inventory:FindFirstChild(saved.Id) or nil
			if pet and type(saved) == "table" then
				pet:SetAttribute("Role", type(saved.Role) == "string" and saved.Role or "Combat")
				pet:SetAttribute("Mutation", type(saved.Mutation) == "string" and saved.Mutation or "Normal")
				pet:SetAttribute("MutationPower", tonumber(saved.MutationPower) or 1)
				pet:SetAttribute("LuckBonus", math.max(0, tonumber(saved.LuckBonus) or 0))
				pet:SetAttribute("DropBonus", math.max(0, tonumber(saved.DropBonus) or 0))
				pet:SetAttribute("Source", type(saved.Source) == "string" and saved.Source or "Hatch")
				pet:SetAttribute("BaseBonus", tonumber(saved.BaseBonus) or tonumber(saved.Bonus) or 0)
			end
		end
	end
end

function WildEggService:RollTier()
	return weightedRoll(self.Config.WildEgg.Tiers, 1)
end

function WildEggService:RollPet(tier, luckMultiplier)
	return weightedRoll(tier.Pets, luckMultiplier)
end

function WildEggService:RollMutation(luckMultiplier)
	return weightedRoll(self.Config.Mutations, luckMultiplier)
end

function WildEggService:BuildRaycastParams()
	local excluded = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then table.insert(excluded, player.Character) end
	end
	local world = self.Context.WorldFolder
	if world then
		for _, name in ipairs({"Enemies", "Followers", "WorldEvents"}) do
			local folder = world:FindFirstChild(name)
			if folder then table.insert(excluded, folder) end
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluded
	params.IgnoreWater = false
	return params
end

function WildEggService:IsValidSpawn(position, result, zone)
	local cfg = self.Config.WildEgg
	if not result or result.Material == Enum.Material.Water then return false end
	if result.Normal.Y < cfg.MinimumSlopeNormalY then return false end
	local flat = Vector3.new(position.X - zone.Center.X, 0, position.Z - zone.Center.Z)
	if flat.Magnitude < cfg.MinimumRadiusFromZoneCenter or flat.Magnitude > cfg.MaximumRadiusFromZoneCenter then return false end
	local slice = self.Context.Services.OpenWorldSliceService
	if slice and slice.IsSafeZone and slice:IsSafeZone(position) then return false end
	return true
end

function WildEggService:FindSpawnPosition()
	local cfg = self.Config.WildEgg
	local zones = self.Context.Config.Zones
	local params = self:BuildRaycastParams()
	for _ = 1, cfg.SpawnAttempts do
		local zone = zones[math.random(1, #zones)]
		local radius = cfg.MinimumRadiusFromZoneCenter + math.random() * (cfg.MaximumRadiusFromZoneCenter - cfg.MinimumRadiusFromZoneCenter)
		local angle = math.random() * math.pi * 2
		local x = zone.Center.X + math.cos(angle) * radius
		local z = zone.Center.Z + math.sin(angle) * radius
		local origin = Vector3.new(x, zone.Center.Y + 180, z)
		local result = Workspace:Raycast(origin, Vector3.new(0, -420, 0), params)
		if result then
			local position = result.Position + Vector3.new(0, 3.9, 0)
			if self:IsValidSpawn(position, result, zone) then return position, zone.Id end
		end
	end
	return nil, nil
end

function WildEggService:HideFor(player, eggId)
	if self.Revealed[player] ~= eggId then return end
	self.Context.Remotes.WildEgg:FireClient(player, "Hide", {EggId = eggId})
	self.Revealed[player] = nil
	self.RevealAt[player] = nil
end

function WildEggService:ClearActiveEgg()
	local egg = self.ActiveEgg
	if egg then
		for player, revealedId in pairs(self.Revealed) do
			if revealedId == egg.Id and player.Parent == Players then self:HideFor(player, egg.Id) end
		end
	end
	self.ActiveEgg = nil
end

function WildEggService:ScheduleNext(initial)
	self.ScheduleToken += 1
	local token = self.ScheduleToken
	local cfg = self.Config.WildEgg
	local minDelay = initial and cfg.FirstSpawnMinSeconds or cfg.RespawnMinSeconds
	local maxDelay = initial and cfg.FirstSpawnMaxSeconds or cfg.RespawnMaxSeconds
	local delaySeconds = math.random(minDelay, maxDelay)
	task.delay(delaySeconds, function()
		if token ~= self.ScheduleToken or self.ActiveEgg then return end
		self:Spawn()
	end)
end

function WildEggService:Spawn()
	if self.ActiveEgg then return end
	local position, zoneId = self:FindSpawnPosition()
	if not position then
		task.delay(30, function() if not self.ActiveEgg then self:Spawn() end end)
		return
	end
	local tier = self:RollTier()
	local cfg = self.Config.WildEgg
	local lifetime = math.random(cfg.LifetimeMinSeconds, cfg.LifetimeMaxSeconds)
	local egg = {
		Id = HttpService:GenerateGUID(false),
		Tier = tier,
		Position = position,
		ZoneId = zoneId,
		SpawnedAt = os.clock(),
		ExpiresAt = os.clock() + lifetime,
		Claimed = false,
	}
	self.ActiveEgg = egg

	task.delay(lifetime, function()
		if self.ActiveEgg ~= egg or egg.Claimed then return end
		self:ClearActiveEgg()
		self:ScheduleNext(false)
	end)
end

function WildEggService:RevealNearby()
	local egg = self.ActiveEgg
	if not egg or egg.Claimed then return end
	local radius = self.Config.WildEgg.RevealRadius
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local inRange = humanoid and humanoid.Health > 0 and root and (root.Position - egg.Position).Magnitude <= radius
		if inRange then
			if self.Revealed[player] ~= egg.Id then
				self.Revealed[player] = egg.Id
				self.RevealAt[player] = os.clock()
				self.Context.Remotes.WildEgg:FireClient(player, "Reveal", {
					EggId = egg.Id,
					Tier = egg.Tier.Id,
					Color = egg.Tier.Color,
					Position = egg.Position,
				})
			end
		elseif self.Revealed[player] == egg.Id then
			self:HideFor(player, egg.Id)
		end
	end
end

function WildEggService:IncrementIndex(player, tierId)
	local activity = self.Context.Services.ActivityService
	local folder = activity and activity:EnsureProfile(player)
	local index = folder and folder:FindFirstChild("WildEggIndex")
	local value = index and index:FindFirstChild(tierId)
	if value and value:IsA("IntValue") then value.Value += 1 end
end

function WildEggService:Claim(player, eggId)
	local egg = self.ActiveEgg
	if not egg or egg.Claimed or type(eggId) ~= "string" or egg.Id ~= eggId then return end
	if self.Revealed[player] ~= egg.Id then return end
	local revealAt = self.RevealAt[player] or math.huge
	if os.clock() - revealAt < self.Config.WildEgg.MinimumRevealDwellSeconds then return end

	local activity = self.Context.Services.ActivityService
	if not activity then return end
	if activity:GetSessionEffectiveSeconds(player) < self.Config.WildEgg.RequiredSessionEffectiveSeconds then
		self.Context:Notify(player, "Wild Eggs require 5 minutes of effective playtime in this server.", "error")
		return
	end
	if not activity:IsSensitiveRewardAllowed(player) then
		self.Context:Notify(player, "Wild Egg claim rejected: movement could not be verified yet.", "error")
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then return end
	if (root.Position - egg.Position).Magnitude > self.Config.WildEgg.ClaimRadius then return end

	egg.Claimed = true
	local luck = activity:GetLuckMultiplier(player)
	local petData = self:RollPet(egg.Tier, luck)
	local mutation = self:RollMutation(luck)
	local baseBonus = math.max(0, tonumber(petData.Bonus) or 0)
	local effectiveBonus = baseBonus * (tonumber(mutation.PowerMultiplier) or 1)
	local pet = self.Context.Services.DataService:AddPet(player, petData.Name, egg.Tier.Id, effectiveBonus, true)
	if pet then
		pet:SetAttribute("Role", petData.Role or "Combat")
		pet:SetAttribute("Mutation", mutation.Id)
		pet:SetAttribute("MutationPower", mutation.PowerMultiplier or 1)
		pet:SetAttribute("LuckBonus", math.max(0, tonumber(petData.LuckBonus) or 0))
		pet:SetAttribute("DropBonus", math.max(0, tonumber(petData.DropBonus) or 0))
		pet:SetAttribute("Source", "WildEgg")
		pet:SetAttribute("BaseBonus", baseBonus)
	end
	self.Context.Services.DataService:RecalculatePower(player)
	self.Context.Services.PetService:RebuildFollowers(player)
	activity:Record(player, "wild_egg", 3)
	self:IncrementIndex(player, egg.Tier.Id)

	local mutationPrefix = mutation.Id ~= "Normal" and (mutation.Id .. " ") or ""
	self.Context:Notify(player, mutationPrefix .. petData.Name .. " • " .. egg.Tier.Id .. " Wild Egg", "success")
	if egg.Tier.BroadcastClaim then
		self.Context:NotifyAll(player.Name .. " discovered a " .. string.upper(egg.Tier.Id) .. " WILD EGG!", "world")
	end

	self:ClearActiveEgg()
	self:ScheduleNext(false)
end

function WildEggService:Start()
	self:InstallPetMetadataPersistence()
	self.Context.Remotes.WildEgg.OnServerEvent:Connect(function(player, action, payload)
		if action ~= "Claim" or type(payload) ~= "table" then return end
		self:Claim(player, payload.EggId)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self.Revealed[player] = nil
		self.RevealAt[player] = nil
	end)
	task.spawn(function()
		while true do
			self:RevealNearby()
			task.wait(self.Config.WildEgg.ScanIntervalSeconds)
		end
	end)
	self:ScheduleNext(true)
	print("[Wild Egg] hidden randomized spawns + server validation active")
end

return WildEggService
