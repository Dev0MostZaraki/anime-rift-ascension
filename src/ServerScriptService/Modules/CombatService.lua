local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(context)
	return setmetatable({
		Context = context,
		Enemies = {},
		LastAttack = {},
		LastAbility = {},
		Combos = {},
	}, CombatService)
end

local function hpGui(parent, boss)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HP"
	gui.Size = boss and UDim2.new(0, 300, 0, 72) or UDim2.new(0, 190, 0, 52)
	gui.StudsOffset = Vector3.new(0, boss and 6.5 or 4.5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = boss and 95 or 52
	gui.LightInfluence = 0
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
	label.BackgroundTransparency = 0.12
	label.BorderSizePixel = 0
	label.TextColor3 = Color3.fromRGB(255, 238, 220)
	label.TextStrokeTransparency = 0.55
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

local function makeBodyPart(model, name, size, cf, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color
	part.Parent = model
	return part
end

function CombatService:CreateModel(name, position, color, boss, archetype)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = self.Context.WorldFolder:WaitForChild("Enemies")

	local body = makeBodyPart(
		model,
		"HumanoidRootPart",
		boss and Vector3.new(7, 9, 5) or Vector3.new(4, 6, 3),
		CFrame.new(position),
		color:Lerp(Color3.fromRGB(35, 35, 42), 0.22),
		Enum.Material.SmoothPlastic
	)
	body.CanCollide = true

	local head = makeBodyPart(
		model,
		"Head",
		boss and Vector3.new(5, 5, 5) or Vector3.new(3.4, 3.4, 3.4),
		CFrame.new(position + Vector3.new(0, boss and 7 or 4.5, 0)),
		Color3.fromRGB(224, 204, 188),
		Enum.Material.SmoothPlastic
	)
	head.Shape = Enum.PartType.Ball

	local shoulderY = boss and 3.5 or 2.2
	local shoulderX = boss and 5 or 3.1
	makeBodyPart(model, "LeftAura", Vector3.new(1.1, boss and 6 or 4, 1.1), CFrame.new(position + Vector3.new(-shoulderX, shoulderY, 0)), color, Enum.Material.Neon)
	makeBodyPart(model, "RightAura", Vector3.new(1.1, boss and 6 or 4, 1.1), CFrame.new(position + Vector3.new(shoulderX, shoulderY, 0)), color, Enum.Material.Neon)

	if boss then
		makeBodyPart(model, "Crown", Vector3.new(7.5, 1.1, 1.1), CFrame.new(position + Vector3.new(0, 10.2, 0)), Color3.fromRGB(255, 75, 160), Enum.Material.Neon)
	elseif archetype == "Guardian" then
		makeBodyPart(model, "Shield", Vector3.new(0.7, 4.4, 3.8), CFrame.new(position + Vector3.new(-3, 1.2, -0.3)), color:Lerp(Color3.new(1, 1, 1), 0.18), Enum.Material.Ice)
	elseif archetype == "Blinker" then
		local halo = makeBodyPart(model, "VoidHalo", Vector3.new(5.5, 0.5, 5.5), CFrame.new(position + Vector3.new(0, 5.7, 0)), color, Enum.Material.Neon)
		halo.Shape = Enum.PartType.Cylinder
		halo.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	end

	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = boss and 3.2 or 1.35
	light.Range = boss and 26 or 12
	light.Parent = body

	hpGui(head, boss)
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
		local prefix = data.Boss and "RIFT TYRANT  •  " or ""
		label.Text = prefix .. data.Name .. "\n" .. math.max(0, math.floor(data.HP)) .. " / " .. math.floor(data.MaxHP) .. " HP"
	end
end

function CombatService:AddEnemy(zone, index, boss)
	local position
	if boss then
		position = zone.Center + Vector3.new(0, 8, -34)
	else
		local angle = ((index - 1) / self.Context.Config.Game.EnemyCountPerZone) * math.pi * 2
		position = zone.Center + Vector3.new(math.cos(angle) * 29, 6, math.sin(angle) * 29)
	end

	local archetype = boss and "Boss" or (zone.Archetype or "Brawler")
	local model = self:CreateModel(
		boss and "Rift Tyrant" or zone.EnemyName,
		position,
		boss and Color3.fromRGB(235, 70, 150) or zone.Color,
		boss,
		archetype
	)

	self.Enemies[model] = {
		Name = boss and "Rift Tyrant" or zone.EnemyName,
		HP = boss and 9500 or zone.EnemyHP,
		MaxHP = boss and 9500 or zone.EnemyHP,
		Damage = boss and 46 or zone.EnemyDamage,
		Coins = boss and 2400 or zone.RewardCoins,
		XP = boss and 1200 or zone.RewardXP,
		Gems = boss and 18 or 0,
		Zone = zone,
		Index = index,
		Boss = boss,
		Archetype = archetype,
		Alive = true,
		Spawn = position,
		LastHit = 0,
		NextSpecial = os.clock() + 2 + math.random(),
		NextSlam = os.clock() + 4,
		CastingUntil = 0,
		StaggerUntil = 0,
	}
	self:UpdateLabel(model)
end

function CombatService:ClosestPlayer(position, range)
	local bestPlayer, bestRoot, bestDistance = nil, nil, range
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root then
			local distance = (root.Position - position).Magnitude
			if distance <= bestDistance then
				bestPlayer, bestRoot, bestDistance = player, root, distance
			end
		end
	end
	return bestPlayer, bestRoot, bestDistance
end

function CombatService:ClosestEnemyInFront(root, range)
	local best, bestDistance = nil, range
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if look.Magnitude < 0.01 then return nil end
	look = look.Unit

	for model, data in pairs(self.Enemies) do
		if data.Alive and model.Parent and model.PrimaryPart then
			local delta = model.PrimaryPart.Position - root.Position
			local flat = Vector3.new(delta.X, 0, delta.Z)
			local distance = flat.Magnitude
			if distance > 0.01 and distance <= bestDistance then
				local dot = look:Dot(flat.Unit)
				if dot >= self.Context.Config.Game.AttackArcDot then
					best = model
					bestDistance = distance
				end
			end
		end
	end
	return best, bestDistance
end

function CombatService:Pulse(position, color, size, duration)
	local folder = self.Context.WorldFolder and self.Context.WorldFolder:FindFirstChild("WorldEvents")
	if not folder then return end
	local pulse = Instance.new("Part")
	pulse.Name = "CombatPulse"
	pulse.Shape = Enum.PartType.Ball
	pulse.Size = Vector3.one
	pulse.CFrame = CFrame.new(position)
	pulse.Anchored = true
	pulse.CanCollide = false
	pulse.CanTouch = false
	pulse.CanQuery = false
	pulse.Material = Enum.Material.Neon
	pulse.Color = color
	pulse.Transparency = 0.18
	pulse.Parent = folder
	TweenService:Create(pulse, TweenInfo.new(duration), {Size = Vector3.new(size, size, size), Transparency = 1}):Play()
	task.delay(duration + 0.05, function()
		if pulse.Parent then pulse:Destroy() end
	end)
end

function CombatService:Ring(position, radius, color, duration)
	local folder = self.Context.WorldFolder and self.Context.WorldFolder:FindFirstChild("WorldEvents")
	if not folder then return nil end
	local ring = Instance.new("Part")
	ring.Name = "Telegraph"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.25, radius * 2, radius * 2)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.55
	ring.Parent = folder
	TweenService:Create(ring, TweenInfo.new(duration), {Transparency = 0.15}):Play()
	return ring
end

function CombatService:DamageNumber(model, amount, crit)
	if not model.PrimaryPart then return end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 118, 0, 42)
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
		stats.Gems.Value += data.Gems
		profile.QuestBosses.Value += 1
		self.Context:NotifyAll(player.Name .. " defeated the RIFT TYRANT!", "boss")
		self.Context:Notify(player, "+" .. coins .. " Coins  •  +" .. xp .. " XP  •  +" .. data.Gems .. " Gems", "success")
	else
		self.Context:Notify(player, "+" .. coins .. " Coins  •  +" .. xp .. " XP", "loot")
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

	local respawn = boss and self.Context.Config.Game.BossRespawnSeconds or self.Context.Config.Game.EnemyRespawnSeconds
	task.delay(respawn, function()
		if self.Context.WorldFolder and self.Context.WorldFolder.Parent then
			self:AddEnemy(zone, index, boss)
		end
	end)
end

function CombatService:Hit(player, model, damage, crit, stagger)
	local data = self.Enemies[model]
	if not data or not data.Alive then return end
	data.HP -= damage
	if stagger and stagger > 0 then
		data.StaggerUntil = math.max(data.StaggerUntil or 0, os.clock() + stagger)
	end
	self:DamageNumber(model, damage, crit)
	self:UpdateLabel(model)
	if data.HP <= 0 then
		self:Kill(player, model)
	end
end

function CombatService:GetComboStage(player, now)
	local cfg = self.Context.Config.Game
	local state = self.Combos[player]
	if not state or now - state.Last > cfg.ComboResetSeconds then
		state = {Stage = 1, Last = now}
	else
		state.Stage = (state.Stage % 3) + 1
		state.Last = now
	end
	self.Combos[player] = state
	return state.Stage
end

function CombatService:Attack(player)
	local now = os.clock()
	local cfg = self.Context.Config.Game
	if now - (self.LastAttack[player] or 0) < cfg.AttackCooldown then return end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local tool = character and character:FindFirstChild("Rift Blade")
	if not humanoid or humanoid.Health <= 0 or not root or not tool then return end

	self.LastAttack[player] = now
	local stage = self:GetComboStage(player, now)
	local colors = {
		Color3.fromRGB(150, 115, 255),
		Color3.fromRGB(195, 100, 255),
		Color3.fromRGB(255, 150, 95),
	}
	self:Pulse((root.CFrame * CFrame.new(0, 0, -4)).Position, colors[stage], 6 + stage * 1.4, 0.18)

	local target = self:ClosestEnemyInFront(root, cfg.AttackRange)
	local stats = player:FindFirstChild("leaderstats")
	if not target or not stats then return end

	local crit = math.random() <= cfg.CritChance
	local multiplier = cfg.ComboMultipliers[stage] or 1
	local damage = math.floor(cfg.BaseDamage * stats.Power.Value * multiplier * (crit and cfg.CritMultiplier or 1))
	self:Hit(player, target, damage, crit, stage == 3 and 0.35 or 0)
	self.Context.Remotes.CombatFeedback:FireClient(player, "Combo", stage)
end

function CombatService:Ability(player, name)
	local cfg = self.Context.Config.Game
	local cooldowns = {
		Dash = cfg.DashCooldown,
		Burst = cfg.BurstCooldown,
		Nova = cfg.NovaCooldown,
	}
	local cooldown = cooldowns[name]
	if not cooldown then return end

	local now = os.clock()
	local key = tostring(player.UserId) .. ":" .. name
	if now - (self.LastAbility[key] or 0) < cooldown then return end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then return end
	self.LastAbility[key] = now

	if name == "Dash" then
		local look = root.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.1 then
			root.AssemblyLinearVelocity = flat.Unit * cfg.DashSpeed + Vector3.new(0, math.max(root.AssemblyLinearVelocity.Y, 0), 0)
			self:Pulse(root.Position, Color3.fromRGB(110, 185, 255), 6, 0.22)
		end
		return
	end

	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end

	local range = name == "Nova" and cfg.NovaRange or cfg.BurstRange
	local damageMultiplier = name == "Nova" and cfg.NovaDamageMultiplier or cfg.BurstDamageMultiplier
	local damage = math.floor(cfg.BaseDamage * stats.Power.Value * damageMultiplier)
	local color = name == "Nova" and Color3.fromRGB(255, 75, 165) or Color3.fromRGB(210, 95, 255)
	local stagger = name == "Nova" and 1.1 or 0.45

	self:Pulse(root.Position, color, range * 2, name == "Nova" and 0.55 or 0.35)
	if name == "Nova" then
		task.delay(0.08, function() self:Pulse(root.Position, Color3.fromRGB(255, 205, 95), range * 1.45, 0.45) end)
	end

	local hits = {}
	for model, data in pairs(self.Enemies) do
		if data.Alive and model.Parent and model.PrimaryPart and (model.PrimaryPart.Position - root.Position).Magnitude <= range then
			table.insert(hits, model)
		end
	end
	for _, model in ipairs(hits) do
		self:Hit(player, model, damage, false, stagger)
	end

	if name == "Nova" then
		self.Context:Notify(player, "RIFT NOVA unleashed!", "boss")
	end
end

function CombatService:BossSlam(model, data, targetRoot)
	if not model.Parent or not model.PrimaryPart or not targetRoot then return end
	local cfg = self.Context.Config.Game
	local floorPosition = Vector3.new(targetRoot.Position.X, targetRoot.Position.Y - 3, targetRoot.Position.Z)
	data.CastingUntil = os.clock() + cfg.BossTelegraphDelay
	data.NextSlam = os.clock() + cfg.BossTelegraphInterval

	local telegraph = self:Ring(floorPosition, cfg.BossSlamRange, Color3.fromRGB(255, 55, 105), cfg.BossTelegraphDelay)
	self.Context:NotifyAll("Rift Tyrant is charging VOID CRUSH — move!", "boss")

	task.delay(cfg.BossTelegraphDelay, function()
		if telegraph and telegraph.Parent then telegraph:Destroy() end
		if not data.Alive or not model.Parent then return end
		self:Pulse(floorPosition + Vector3.new(0, 2, 0), Color3.fromRGB(255, 60, 130), cfg.BossSlamRange * 2, 0.38)
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and root then
				local flat = Vector3.new(root.Position.X - floorPosition.X, 0, root.Position.Z - floorPosition.Z)
				if flat.Magnitude <= cfg.BossSlamRange then
					humanoid:TakeDamage(cfg.BossSlamDamage)
				end
			end
		end
	end)
end

function CombatService:StepAI(dt)
	local cfg = self.Context.Config.Game
	local now = os.clock()

	for model, data in pairs(self.Enemies) do
		if data.Alive and model.Parent and model.PrimaryPart then
			local body = model.PrimaryPart
			if now < (data.StaggerUntil or 0) then
				continue
			end

			local player, playerRoot, distance = self:ClosestPlayer(body.Position, cfg.EnemyAggroRange)
			local distanceFromSpawn = (body.Position - data.Spawn).Magnitude
			if distanceFromSpawn > cfg.EnemyLeashRange then
				player, playerRoot, distance = nil, nil, nil
			end

			if data.Boss and player and playerRoot and now >= data.NextSlam and now >= data.CastingUntil then
				self:BossSlam(model, data, playerRoot)
			end

			if now < (data.CastingUntil or 0) then
				continue
			end

			if data.Archetype == "Blinker" and player and playerRoot and distance and distance > 13 and distance < 33 and now >= data.NextSpecial then
				data.NextSpecial = now + cfg.EnemyBlinkCooldown
				local away = Vector3.new(body.Position.X - playerRoot.Position.X, 0, body.Position.Z - playerRoot.Position.Z)
				if away.Magnitude < 0.1 then away = Vector3.new(1, 0, 0) end
				local newPos = playerRoot.Position + away.Unit * 7
				newPos = Vector3.new(newPos.X, data.Spawn.Y, newPos.Z)
				self:Pulse(body.Position, data.Zone.Color, 6, 0.18)
				model:PivotTo(CFrame.lookAt(newPos, Vector3.new(playerRoot.Position.X, newPos.Y, playerRoot.Position.Z)))
				self:Pulse(newPos, data.Zone.Color, 6, 0.18)
				body = model.PrimaryPart
				distance = (playerRoot.Position - body.Position).Magnitude
			end

			local attackRange = cfg.EnemyAttackRange
			local attackCooldown = cfg.EnemyAttackCooldown
			local damage = data.Damage
			if data.Archetype == "Guardian" then
				attackRange += 1.5
				attackCooldown *= 1.3
				damage = math.floor(damage * 1.2)
			end

			if player and playerRoot and distance and distance <= attackRange then
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid and now - data.LastHit >= attackCooldown then
					data.LastHit = now
					humanoid:TakeDamage(damage)
					self:Pulse(playerRoot.Position, data.Boss and Color3.fromRGB(255, 70, 145) or data.Zone.Color, data.Boss and 8 or 5, 0.16)
				end
			else
				local target = playerRoot and Vector3.new(playerRoot.Position.X, data.Spawn.Y, playerRoot.Position.Z) or data.Spawn
				local delta = target - body.Position
				local flat = Vector3.new(delta.X, 0, delta.Z)
				if flat.Magnitude > 0.5 then
					local speed = data.Boss and cfg.BossMoveSpeed or cfg.EnemyMoveSpeed
					if data.Archetype == "Charger" then speed *= 1.42 end
					if data.Archetype == "Guardian" then speed *= 0.72 end
					local nextPos = body.Position + flat.Unit * math.min(flat.Magnitude, speed * dt)
					nextPos = Vector3.new(nextPos.X, data.Spawn.Y, nextPos.Z)
					model:PivotTo(CFrame.lookAt(nextPos, Vector3.new(target.X, nextPos.Y, target.Z)))
				end
			end
		end
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
	tool.ToolTip = "Click / Tap for a 3-hit combo"
	tool.CanBeDropped = false
	tool.RequiresHandle = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.45, 4.8, 0.65)
	handle.Color = Color3.fromRGB(184, 118, 255)
	handle.Material = Enum.Material.Neon
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local light = Instance.new("PointLight")
	light.Color = handle.Color
	light.Brightness = 1.5
	light.Range = 9
	light.Parent = handle
	tool.Grip = CFrame.new(0, -1.3, 0) * CFrame.Angles(0, 0, math.rad(12))
	tool.Parent = backpack

	task.delay(0.4, function()
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and tool.Parent == backpack then humanoid:EquipTool(tool) end
	end)
end

function CombatService:Start()
	for _, zone in ipairs(self.Context.Config.Zones) do
		for index = 1, self.Context.Config.Game.EnemyCountPerZone do
			self:AddEnemy(zone, index, false)
		end
	end
	self:AddEnemy(self.Context.Config.Zones[4], 0, true)

	self.Context.Remotes.Attack.OnServerEvent:Connect(function(player)
		self:Attack(player)
	end)
	self.Context.Remotes.Ability.OnServerEvent:Connect(function(player, name)
		if typeof(name) == "string" and (name == "Dash" or name == "Burst" or name == "Nova") then
			self:Ability(player, name)
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		self:StepAI(dt)
	end)
end

return CombatService
