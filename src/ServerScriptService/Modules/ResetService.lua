local RunService = game:GetService("RunService")

local ResetService = {}
ResetService.__index = ResetService

local LEGACY_STORE_NAME = "AnimeRiftAscension_v2"

function ResetService.new(context)
	return setmetatable({Context = context}, ResetService)
end

local function setValue(parent, name, value)
	local object = parent and parent:FindFirstChild(name)
	if object and object:IsA("ValueBase") then object.Value = value end
end

function ResetService:ResetRuntime(player)
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	if not stats or not profile then return false, "Player data is not ready." end

	setValue(stats, "Coins", 0)
	setValue(stats, "Gems", 0)
	setValue(stats, "Level", 1)
	setValue(stats, "Power", 1)

	setValue(profile, "XP", 0)
	setValue(profile, "QuestKills", 0)
	setValue(profile, "QuestHatches", 0)
	setValue(profile, "QuestBosses", 0)
	setValue(profile, "QuestKillsDone", false)
	setValue(profile, "QuestHatchesDone", false)
	setValue(profile, "QuestBossesDone", false)
	setValue(profile, "EquippedStyle", "RiftBlade")

	local zones = profile:FindFirstChild("ZoneUnlocks")
	if zones then
		for _, value in ipairs(zones:GetChildren()) do
			if value:IsA("BoolValue") then
				value.Value = value.Name == "Zone1"
			end
		end
	end

	local styleUnlocks = profile:FindFirstChild("StyleUnlocks")
	if styleUnlocks then
		for _, value in ipairs(styleUnlocks:GetChildren()) do
			if value:IsA("BoolValue") then value.Value = value.Name == "RiftBlade" end
		end
	end
	local styleMastery = profile:FindFirstChild("StyleMastery")
	if styleMastery then
		for _, value in ipairs(styleMastery:GetChildren()) do
			if value:IsA("IntValue") or value:IsA("NumberValue") then value.Value = 0 end
		end
	end

	local progression = profile:FindFirstChild("Progression")
	if progression then
		setValue(progression, "LifetimeEffectiveSeconds", 0)
		setValue(progression, "DailyEffectiveSeconds", 0)
		setValue(progression, "DailyRewardTier", 0)
		setValue(progression, "DailyKey", os.date("!%Y-%m-%d"))
		setValue(progression, "RiftTickets", 0)
		setValue(progression, "SessionEffectiveSeconds", 0)
		setValue(progression, "Resonance", 0)
		local wildIndex = progression:FindFirstChild("WildEggIndex")
		if wildIndex then
			for _, value in ipairs(wildIndex:GetChildren()) do
				if value:IsA("IntValue") or value:IsA("NumberValue") then value.Value = 0 end
			end
		end
	end

	local fighters = profile:FindFirstChild("Fighters")
	if fighters then
		setValue(fighters, "SoulShards", 0)
		setValue(fighters, "SummonCount", 0)
		setValue(fighters, "MythicPity", 0)
	end

	for _, name in ipairs({"PetInventory", "RelicInventory", "FighterInventory"}) do
		local inventory = player:FindFirstChild(name)
		if inventory then inventory:ClearAllChildren() end
	end

	local activity = self.Context.Services.ActivityService
	if activity then activity.State[player] = nil end
	local pets = self.Context.Services.PetService
	if pets then
		pets:ClearFollowers(player)
		pets:RebuildFollowers(player)
	end

	self.Context.Services.DataService:RecalculatePower(player)
	self.Context.Services.StatsService:Recalculate(player, false)
	self.Context.Services.ActivityService:MarkLegitimateTeleport(player, 4)
	self.Context.Services.WorldService:TeleportToHub(player)
	return true
end

function ResetService:PersistReset(player)
	local data = self.Context.Services.DataService
	local payload = data:Serialize(player)
	if not payload then return false, "Could not serialize the reset state." end

	if not data.PersistenceEnabled then
		return true, "Session reset only; persistent DataStore access is unavailable in this Studio session."
	end

	if data.UsingProfileStore then
		local session = data.Sessions[player]
		if not session or not session:IsActive() then
			return false, "ProfileStore session is not active."
		end
		session.Data.SchemaVersion = 3
		session.Data.Snapshot = payload
		-- Mark legacy migration complete so an intentionally reset account can never
		-- resurrect its old v2 save on the next join.
		session.Data.LegacyMigration = {
			Completed = true,
			Found = false,
			MigratedAt = os.time(),
			Source = LEGACY_STORE_NAME,
		}
		local ok, err = pcall(function() session:Save() end)
		if not ok then return false, "ProfileStore reset save failed: " .. tostring(err) end

		-- Keep the emergency legacy fallback in the same reset state as v3.
		local legacyOk, legacyErr = pcall(function()
			data.LegacyStore:UpdateAsync("u_" .. player.UserId, function()
				return payload
			end)
		end)
		if not legacyOk then
			warn("[Reset] v3 reset saved, but legacy fallback reset failed:", legacyErr)
		end
		return true, legacyOk and "Persistent v3 + legacy fallback reset saved." or "Persistent v3 reset saved; legacy fallback write failed."
	end

	local ok = data:Save(player)
	return ok, ok and "Legacy fallback reset saved." or "Legacy fallback reset save failed."
end

function ResetService:ResetPlayer(player)
	local runtimeOk, runtimeErr = self:ResetRuntime(player)
	if not runtimeOk then return false, runtimeErr end
	local saveOk, saveMessage = self:PersistReset(player)
	if not saveOk then
		warn("[Reset] Runtime reset succeeded but persistence failed for", player.Name, saveMessage)
	end
	return saveOk, saveMessage
end

function ResetService:Start()
	print("[Reset] developer save-reset service ready" .. (RunService:IsStudio() and " • Studio" or ""))
end

return ResetService
