local TweenService = game:GetService("TweenService")

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(context)
	local self = setmetatable({}, CombatService)
	self.Context = context
	self.Enemies = {}
	self.LastAttack = {}
	return self
end

local function makeBillboard(parent, boss)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HP"
	gui.Size = boss and UDim2.new(0, 280, 0, 70) or UDim2.new(0, 200, 0, 55)
	gui.StudsOffset = Vector3.new(0, boss and 6 or 4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 140
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	label.BackgroundTransparency = 0.15
	label.BorderSizePixel = 0
	label.TextColor3 = Color3.fromRGB(255, 238, 220)
	label.TextStrokeTransparency = 0.5
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

function CombatService:CreateModel(name, position, color, boss)
	local enemiesFolder = self.Context.WorldFolder:WaitForChild("Enemies")
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = enemiesFolder

	local body = Instance.new("Part")
	body.Name = "HumanoidRootPart"
	body.Size = boss and Vector3.new(7, 9, 5) or Vector3.new(4, 6, 3)
	body.CFrame = CFrame.new(position)
	body.Anchored = true
	body.CanCollide = true
	body.Material = Enum.Material.SmoothPlastic
	body.Color = color:Lerp(Color3.fromRGB(35, 35, 42), 0.22)
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = boss and Vector3.new(5, 5, 5) or Vector3.new(3.4, 3.4, 3.4)
	head.Shape = Enum.PartType.Ball
	head.CFrame = CFrame.new(position + Vector3.new(0, boss and 7 or 4.5, 0))
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(224, 204, 188)
	head.Parent = model

	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = boss and 3 or 1.4
	light.Range = boss and 24 or 12
	light.Parent = body

	makeBillboard(head, boss)
	model.PrimaryPart = body
	return model
end

function CombatService:UpdateLabel(model)
	local data = self.Enemies[model]
	if not data then return end
	local head = model:FindFirstChild("Head")
	local gui = head and head:FindFirstChild("HP")
	local label = gui and gui:FindFirstChild("Label")
	if label then
		local prefix = data.Boss and "BOSS • " or ""
		label.Text = prefix .. data.Name .. "\n" .. math.max(0, math.floor(data.HP)) .. " / " .. math.floor(data.MaxHP) .. " HP"
	end
end

function CombatService:SpawnEnemy(zone, index)
	local angle = ((index - 1) / 7) * math.pi * 2
	local position = zone.Center + Vector3.new(math.cos(angle) * 29, 6, math.sin(angle) * 29)
	local model = self:CreateModel(zone.EnemyName, position, zone.Color, false)
	self.Enemies[model] = {
		Name = zone.EnemyName,
		HP = zone.EnemyHP,
		MaxHP = zone.EnemyHP,
		Damage = zone.EnemyDamage,
		Coins = zone.RewardCoins,
		XP = zone.RewardXP,
		Zone = zone,
		Index = index,
		Boss = false,
		Alive = true,
		Retaliate = {},
	}
	self:UpdateLabel(model)
end

function CombatService:SpawnBoss()
	local zone = self.Context.Config.Zones[4]
	local model = self:CreateModel("Rift Tyrant", zone.Center + Vector3.new(0, 8, -34), Color3.fromRGB(235, 70, 150), true)
	self.Enemies[model] = {
		Name = "Rift Tyrant",
		HP = 9500,
		MaxHP = 9500,
		Damage = 46,
		Coins = 2400,
		XP = 1200,
		Gems = 18,
		Zone = zone,
		Index = 0,
		Boss = true,
		Alive = true,
		Retaliate = {},
	}
	self:UpdateLabel(model)
end

function CombatService:ClosestEnemy(position, maxDistance)
	local best, bestDistance = nil, maxDistance
	for model, data in pairs(self.Enemies) do
		if data.Alive and model.Parent and model.PrimaryPart then
			local distance = (model.PrimaryPart.Position - position).Magnitude
			if distance <= bestDistance then
				best = model
				bestDistance = distance
			end
		end
	end
	return best, bestDistance
end

function CombatService:DamageNumber(model, amount, crit)
	if not model.PrimaryPart then return end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 110, 0, 42)
	gui.StudsOffset = Vector3.new(math.random(-10, 10) / 10, 4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model.PrimaryPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = (crit and "CRIT " or "") .. "-" .. amount
	label.TextColor3 = crit and Color3.fromRGB(255, 222, 90) or Color3.fromRGB(255, 110, 110)
	label.TextStrokeTransparency = 0.25
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = gui

	TweenService:Create(gui, TweenInfo.new(0.5), {StudsOffset = gui.StudsOffset + Vector3.new(0, 2.5, 0)}):Play()
	TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	task.delay(0.55, function()
		if gui.Parent then gui:Destroy() end
	end)
end

function CombatService:AttackEffect(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local eventsFolder = self.Context.WorldFolder and self.Context.WorldFolder:FindFirstChild("WorldEvents")
	if not root or not eventsFolder then return end

	local effect = Instance.new("Part")
	effect.Name = "SlashFX"
	effect.Shape = Enum.PartType.Ball
	effect.Size = Vector3.new(1, 1, 1)
	effect.CFrame = root.CFrame * CFrame.new(0, 0, -4)
	effect.Anchored = true
	effect.CanCollide = false
	effect.CanTouch = false
	effect.CanQuery = false
	effect.Material = Enum.Material.Neon
	effect.Color = Color3.fromRGB(185, 120, 255)
	effect.Transparency = 0.2
	effect.Parent = eventsFolder
	TweenService:Create(effect, TweenInfo.new(0.18), {Size = Vector3.new(7, 7, 7), Transparency = 1}):Play()
	task.delay(0.2, function()
		if effect.Parent then effect:Destroy() end
	end)
end

function CombatService:Kill(player, model)
	local data = self.Enemies[model]
	if not data or not data.Alive then return end
	data.Alive = false

	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	if not stats or not profile then return end

	local multiplier = self.Context.RewardMultiplier or 1
	local coins = math.floor(data.Coins * multiplier)
	local xp = math.floor(data.XP * multiplier)
	stats.Coins.Value += coins
	self.Context.Services.DataService:AddXP(player, xp)
	profile.QuestKills.Value += 1

	if data.Boss then
		stats.Gems.Value += data.Gems or 0
		profile.QuestBosses.Value += 1
		self.Context:NotifyAll(player.Name .. " defeated the RIFT TYRANT!", "boss")
		self.Context:Notify(player, "Boss reward: +" .. coins .. " Coins • +" .. xp .. " XP • +" .. (data.Gems or 0) .. " Gems", "success")
	else
		self.Context:Notify(player, "+" .. coins .. " Coins • +" .. xp .. " XP", "loot")
	end
	self.Context.Services.QuestService:Check(player)

	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") then
			object.CanCollide = false
			TweenService:Create(object, TweenInfo.new(0.28), {Transparency = 1}):Play()
		end
	end

	local zone, index, boss = data.Zone, data.Index, data.Boss
	task.delay(0.35, function()
		self.Enemies[model] = nil
		if model.Parent then model:Destroy() end
	end)

	local delayTime = boss and self.Context.Config.Game.BossRespawnSeconds or self.Context.Config.Game.EnemyRespawnSeconds
	task.delay(delayTime, function()
		if self.Context.WorldFolder and self.Context.WorldFolder.Parent then
			if boss then self:SpawnBoss() else self:SpawnEnemy(zone, index) end
		end
	end)
end

function CombatService:Attack(player)
	local now = os.clock()
	if now - (self.LastAttack[player] or 0) < self.Context.Config.Game.AttackCooldown then return end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local equipped = character and character:FindFirstChild("Rift Blade")
	if not humanoid or humanoid.Health <= 0 or not root or not equipped or not equipped:IsA("Tool") then return end

	self.LastAttack[player] = now
	self:AttackEffect(player)

	local target, distance = self:ClosestEnemy(root.Position, self.Context.Config.Game.AttackRange)
	if not target then return end
	local data = self.Enemies[target]
	if not data or not data.Alive then return end

	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end
	local crit = math.random() <= 0.08
	local damage = math.floor(self.Context.Config.Game.BaseDamage * stats.Power.Value * (crit and 1.75 or 1))
	data.HP -= damage
	self:DamageNumber(target, damage, crit)
	self:UpdateLabel(target)

	if distance <= 7 then
		local previous = data.Retaliate[player.UserId] or 0
		if now - previous >= 1.15 then
			data.Retaliate[player.UserId] = now
			humanoid:TakeDamage(data.Damage)
		end
	end

	if data.HP <= 0 then
		self:Kill(player, target)
	end
end

function CombatService:GiveBlade(player)
	local backpack = player:WaitForChild("Backpack")
	for _, container in ipairs({backpack, player.Character}) do
		if container then
			local old = container:FindFirstChild("Rift Blade")
			if old then old:Destroy() end
		end
	end

	local tool = Instance.new("Tool")
	tool.Name = "Rift Blade"
	tool.ToolTip = "Click / Tap to attack"
	tool.CanBeDropped = false
	tool.RequiresHandle = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.45, 4.5, 0.65)
	handle.Color = Color3.fromRGB(184, 118, 255)
	handle.Material = Enum.Material.Neon
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local light = Instance.new("PointLight")
	light.Color = handle.Color
	light.Brightness = 1.4
	light.Range = 8
	light.Parent = handle
	tool.Grip = CFrame.new(0, -1.2, 0) * CFrame.Angles(0, 0, math.rad(12))
	tool.Parent = backpack

	task.delay(0.4, function()
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and tool.Parent == backpack then
			humanoid:EquipTool(tool)
		end
	end)
end

function CombatService:Start()
	for _, zone in ipairs(self.Context.Config.Zones) do
		for index = 1, 7 do
			self:SpawnEnemy(zone, index)
		end
	end
	self:SpawnBoss()
	self.Context.Remotes.Attack.OnServerEvent:Connect(function(player)
		self:Attack(player)
	end)
end

return CombatService
