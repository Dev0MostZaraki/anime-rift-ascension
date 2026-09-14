local EventService = {}
EventService.__index = EventService

function EventService.new(context)
	local self = setmetatable({}, EventService)
	self.Context = context
	self.WorldEgg = nil
	return self
end

local function makeBillboard(parent, text)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 210, 0, 52)
	gui.StudsOffset = Vector3.new(0, 6.5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 52
	gui.LightInfluence = 0
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 232, 142)
	label.TextStrokeTransparency = 0.58
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
end

function EventService:GetWorldEggPositions()
	local positions = {}
	local expansion = self.Context.Services.OpenWorldExpansionService
	if expansion and expansion.GetSecretEggPositions then
		for _, position in ipairs(expansion:GetSecretEggPositions()) do table.insert(positions, position) end
	end
	local slice = self.Context.Services.OpenWorldSliceService
	if slice and slice.GetSecretEggPositions then
		for _, position in ipairs(slice:GetSecretEggPositions()) do table.insert(positions, position) end
	end
	if #positions > 0 then return positions end

	for _, zone in ipairs(self.Context.Config.Zones) do
		for _, offset in ipairs({
			Vector3.new(42, 4, 42), Vector3.new(-42, 4, 40),
			Vector3.new(45, 4, -38), Vector3.new(-40, 4, -43),
		}) do
			table.insert(positions, zone.Center + offset)
		end
	end
	return positions
end

function EventService:ScheduleSecretEgg()
	local cfg = self.Context.Config.WorldEvents
	task.delay(math.random(cfg.SecretEggRespawnMin, cfg.SecretEggRespawnMax), function()
		self:SpawnSecretEgg()
	end)
end

function EventService:SpawnSecretEgg()
	if self.WorldEgg or not self.Context.WorldFolder or not self.Context.WorldFolder.Parent then return end
	local eventsFolder = self.Context.WorldFolder:FindFirstChild("WorldEvents")
	if not eventsFolder then return end

	local positions = self:GetWorldEggPositions()
	local position = positions[math.random(1, #positions)]
	local egg = Instance.new("Part")
	egg.Name = "SecretRiftEgg"
	egg.Size = Vector3.new(6.2, 7.6, 6.2)
	egg.CFrame = CFrame.new(position)
	egg.Anchored = true
	egg.CanCollide = false
	egg.CanTouch = false
	egg.Shape = Enum.PartType.Ball
	egg.Material = Enum.Material.Glass
	egg.Transparency = 0.08
	egg.Color = Color3.fromRGB(214, 185, 93)
	egg.Parent = eventsFolder
	self.WorldEgg = egg

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(244, 209, 118)
	light.Brightness = 1.25
	light.Range = 16
	light.Shadows = true
	light.Parent = egg
	makeBillboard(egg, "??? WANDERING EGG ???")

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Claim"
	prompt.ObjectText = "Mysterious Egg"
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.65
	prompt.RequiresLineOfSight = true
	prompt.Parent = egg

	self.Context:NotifyAll("A mysterious egg has appeared somewhere in the open world.", "event")
	local claimed = false
	prompt.Triggered:Connect(function(player)
		if claimed or self.WorldEgg ~= egg then return end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - egg.Position).Magnitude > 12 then return end
		claimed = true

		local stats = player:FindFirstChild("leaderstats")
		if stats then stats.Gems.Value += 10 end
		self.Context.Services.DataService:AddPet(player, "Riftling Prime", "WORLD", 0.85, true)
		self.Context.Services.PetService:RebuildFollowers(player)
		self.Context:NotifyAll(player.Name .. " discovered the WANDERING EGG!", "world")
		self.Context:Notify(player, "Riftling Prime • +85% Power • +10 Gems", "success")

		if egg.Parent then egg:Destroy() end
		self.WorldEgg = nil
		self:ScheduleSecretEgg()
	end)
end

function EventService:StartRiftSurge()
	if self.Context.RewardMultiplier and self.Context.RewardMultiplier > 1 then return end
	local cfg = self.Context.Config.WorldEvents
	self.Context.RewardMultiplier = 2
	self.Context.Remotes.WorldEvent:FireAllClients("RIFT SURGE", cfg.RiftSurgeDuration)
	self.Context:NotifyAll("RIFT SURGE! Enemy Coins and XP are doubled for " .. cfg.RiftSurgeDuration .. " seconds.", "event")

	task.delay(cfg.RiftSurgeDuration, function()
		self.Context.RewardMultiplier = 1
		self.Context:NotifyAll("The Rift Surge has ended.", "info")
	end)
end

function EventService:Start()
	local cfg = self.Context.Config.WorldEvents
	task.delay(cfg.SecretEggFirstDelay, function() self:SpawnSecretEgg() end)
	task.spawn(function()
		task.wait(cfg.RiftSurgeFirstDelay)
		while self.Context.WorldFolder and self.Context.WorldFolder.Parent do
			self:StartRiftSurge()
			task.wait(cfg.RiftSurgeInterval)
		end
	end)
end

return EventService
