local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerService = {}
PlayerService.__index = PlayerService

function PlayerService.new(context)
	local self = setmetatable({}, PlayerService)
	self.Context = context
	return self
end

function PlayerService:SetupPlayer(player)
	local data = self.Context.Services.DataService
	data:CreateProfile(player)
	data:Load(player)
	data:RecalculatePower(player)

	local inventory = player:WaitForChild("PetInventory")
	inventory.ChildAdded:Connect(function(child)
		child:GetAttributeChangedSignal("Equipped"):Connect(function()
			data:RecalculatePower(player)
		end)
	end)

	player.CharacterAdded:Connect(function()
		task.wait(0.25)
		self.Context.Services.WorldService:TeleportToHub(player)
		task.wait(0.45)
		self.Context.Services.CombatService:GiveBlade(player)
		self.Context.Services.PetService:RebuildFollowers(player)
		task.wait(1)
		self.Context:Notify(player, "Welcome to Anime Rift Ascension. Farm • Hatch • Ascend.", "info")
		if not data.PersistenceEnabled then
			self.Context:Notify(player, "Studio session mode: persistent saving is currently unavailable.", "info")
		end
	end)

	if player.Character then
		task.defer(function()
			task.wait(0.25)
			self.Context.Services.WorldService:TeleportToHub(player)
			task.wait(0.45)
			self.Context.Services.CombatService:GiveBlade(player)
			self.Context.Services.PetService:RebuildFollowers(player)
		end)
	end

	task.spawn(function()
		while player.Parent do
			task.wait(self.Context.Config.Game.PlaytimeRewardSeconds)
			if not player.Parent then break end
			local stats = player:FindFirstChild("leaderstats")
			if stats then
				stats.Coins.Value += self.Context.Config.Game.PlaytimeRewardCoins
				self.Context:Notify(player, "PLAYTIME REWARD • +" .. self.Context.Config.Game.PlaytimeRewardCoins .. " Coins", "loot")
			end
		end
	end)
end

function PlayerService:Start()
	Players.PlayerAdded:Connect(function(player)
		self:SetupPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.Context.Services.DataService:Save(player)
		self.Context.Services.PetService:ClearFollowers(player)
		self.Context.Services.CombatService.LastAttack[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:SetupPlayer(player)
		end)
	end

	RunService.Heartbeat:Connect(function()
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 and root.Position.Y < -25 then
				self.Context.Services.WorldService:TeleportToHub(player)
				self.Context:Notify(player, "You fell into the Rift and were returned to the Hub.", "info")
			end
		end
	end)

	task.spawn(function()
		while self.Context.WorldFolder and self.Context.WorldFolder.Parent do
			task.wait(self.Context.Config.Game.AutosaveSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				self.Context.Services.DataService:Save(player)
			end
		end
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			self.Context.Services.DataService:Save(player)
		end
		task.wait(2)
	end)
end

return PlayerService
