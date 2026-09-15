local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerService = {}
PlayerService.__index = PlayerService

function PlayerService.new(context)
	return setmetatable({Context = context}, PlayerService)
end

local function connectEquipmentRecalc(context, player, inventory)
	local function recalc()
		context.Services.StatsService:Recalculate(player, true)
	end
	local function hook(child)
		child:GetAttributeChangedSignal("Equipped"):Connect(recalc)
	end
	for _, child in ipairs(inventory:GetChildren()) do hook(child) end
	inventory.ChildAdded:Connect(function(child)
		hook(child)
		recalc()
	end)
	inventory.ChildRemoved:Connect(recalc)
end

function PlayerService:PrepareCharacter(player)
	task.wait(0.2)
	if not player.Parent then return end
	self.Context.Services.StatsService:ApplyCharacter(player, true)
	self.Context.Services.WorldService:TeleportToHub(player)
	task.wait(0.35)
	if not player.Parent then return end
	self.Context.Services.CombatService:GiveWeapon(player)
	self.Context.Services.PetService:RebuildFollowers(player)
end

function PlayerService:SetupPlayer(player)
	local data = self.Context.Services.DataService
	data:CreateProfile(player)
	local loaded = data:Load(player)
	if loaded == false then
		if player.Parent == Players then
			player:Kick("Your save could not be opened safely. Please rejoin in a moment.")
		end
		return
	end

	data:RecalculatePower(player)
	self.Context.Services.StatsService:EnsureCombatStats(player)
	self.Context.Services.StatsService:Calculate(player)

	local petInventory = player:WaitForChild("PetInventory")
	local relicInventory = player:WaitForChild("RelicInventory")
	connectEquipmentRecalc(self.Context, player, petInventory)
	connectEquipmentRecalc(self.Context, player, relicInventory)

	local stats = player:WaitForChild("leaderstats")
	stats.Level.Changed:Connect(function()
		self.Context.Services.StatsService:Recalculate(player, true)
	end)

	player.CharacterAdded:Connect(function()
		self:PrepareCharacter(player)
		task.wait(0.9)
		if not player.Parent then return end
		local combatStats = player:FindFirstChild("CombatStats")
		if combatStats then
			self.Context:Notify(player, string.format("Lv.%d • %d HP • %.0f Defense", stats.Level.Value, combatStats.MaxHealth.Value, combatStats.Defense.Value), "info")
		end
		self.Context:Notify(player, string.upper(self.Context.Version.Version) .. " • Explore, master styles, clear regional quests and hunt elites.", "info")
		self.Context:Notify(player, "DATA • " .. data:GetBackendName(), data.UsingProfileStore and "success" or "info")
		if not data.PersistenceEnabled then
			self.Context:Notify(player, "Studio session mode: persistent saving is currently unavailable.", "info")
		end
	end)

	if player.Character then task.defer(function() self:PrepareCharacter(player) end) end

	task.spawn(function()
		while player.Parent do
			task.wait(self.Context.Config.Game.PlaytimeRewardSeconds)
			if not player.Parent then break end
			local currentStats = player:FindFirstChild("leaderstats")
			if currentStats then
				currentStats.Coins.Value += self.Context.Config.Game.PlaytimeRewardCoins
				self.Context:Notify(player, "PLAYTIME REWARD • +" .. self.Context.Config.Game.PlaytimeRewardCoins .. " Coins", "loot")
			end
		end
	end)
end

function PlayerService:Start()
	Players.PlayerAdded:Connect(function(player) self:SetupPlayer(player) end)

	Players.PlayerRemoving:Connect(function(player)
		self.Context.Services.DataService:Release(player)
		self.Context.Services.PetService:ClearFollowers(player)
		self.Context.Services.StatsService:Cleanup(player)
		self.Context.Services.CombatService.LastAttack[player] = nil
		self.Context.Services.CombatService.Combos[player] = nil
		self.Context.Services.DashService.LastDash[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do task.spawn(function() self:SetupPlayer(player) end) end

	RunService.Heartbeat:Connect(function()
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 and root.Position.Y < -35 then
				self.Context.Services.WorldService:TeleportToHub(player)
				self.Context:Notify(player, "You fell beyond the world and were returned to Rift Haven.", "info")
			end
		end
	end)

	-- Runtime state still lives in Instances. Snapshot it frequently; ProfileStore owns
	-- the DataStore write, autosave and session lock around those snapshots.
	task.spawn(function()
		while self.Context.WorldFolder and self.Context.WorldFolder.Parent do
			task.wait(self.Context.Config.Game.AutosaveSeconds)
			for _, player in ipairs(Players:GetPlayers()) do self.Context.Services.DataService:Save(player) end
		end
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			self.Context.Services.DataService:Release(player)
		end
		task.wait(1)
	end)
end

return PlayerService
