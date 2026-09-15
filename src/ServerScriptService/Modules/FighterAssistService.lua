local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local FighterConfig = require(AnimeRift:WaitForChild("FighterConfig"))

local FighterAssistService = {}
FighterAssistService.__index = FighterAssistService

function FighterAssistService.new(context)
	return setmetatable({
		Context = context,
		Config = FighterConfig,
		LastAssist = {},
	}, FighterAssistService)
end

function FighterAssistService:GetEquippedFighter(player, slot)
	local inventory = player:FindFirstChild("FighterInventory")
	if not inventory then return nil, nil end
	for _, item in ipairs(inventory:GetChildren()) do
		if (tonumber(item:GetAttribute("EquippedSlot")) or 0) == slot then
			local definition, rarity = self.Config.GetById(item.Name)
			if definition then return item, definition, rarity end
		end
	end
	return nil, nil, nil
end

function FighterAssistService:GetModifiers(player, targetData)
	local modifiers = {
		Damage = 0,
		BossDamage = 0,
		ExecuteDamage = 0,
		AssistDamage = 0,
		AssistCooldownReduction = 0,
		MaxHealth = 0,
	}
	local inventory = player:FindFirstChild("FighterInventory")
	if not inventory then return modifiers end

	for _, item in ipairs(inventory:GetChildren()) do
		if (tonumber(item:GetAttribute("EquippedSlot")) or 0) > 0 then
			local definition = self.Config.GetById(item.Name)
			local passive = definition and definition.Passive
			if passive then
				modifiers.Damage += math.max(0, tonumber(passive.Damage) or 0)
				modifiers.AssistDamage += math.max(0, tonumber(passive.AssistDamage) or 0)
				modifiers.AssistCooldownReduction += math.max(0, tonumber(passive.AssistCooldownReduction) or 0)
				modifiers.MaxHealth += math.max(0, tonumber(passive.MaxHealth) or 0)
				if targetData and targetData.Boss then
					modifiers.BossDamage += math.max(0, tonumber(passive.BossDamage) or 0)
				end
				if targetData and targetData.MaxHP and targetData.MaxHP > 0 then
					local threshold = tonumber(passive.ExecuteThreshold)
					if threshold and targetData.HP / targetData.MaxHP <= threshold then
						modifiers.ExecuteDamage += math.max(0, tonumber(passive.ExecuteDamage) or 0)
					end
				end
			end
		end
	end

	-- Keep early-game passive stacking useful without allowing three support units to
	-- collapse Assist cooldowns into an automation loop.
	modifiers.AssistCooldownReduction = math.clamp(modifiers.AssistCooldownReduction, 0, 0.28)
	modifiers.MaxHealth = math.clamp(modifiers.MaxHealth, 0, 0.30)
	return modifiers
end

function FighterAssistService:GetCooldown(player, definition)
	local base = definition.Assist and tonumber(definition.Assist.Cooldown) or 20
	local modifiers = self:GetModifiers(player)
	return math.max(self.Config.Settings.AssistMinimumCooldown or 8, base * (1 - modifiers.AssistCooldownReduction))
end

function FighterAssistService:GetTargetsAround(position, range)
	local combat = self.Context.Services.CombatService
	local targets = {}
	for model, data in pairs(combat.Enemies) do
		if data.Alive and model.Parent and model.PrimaryPart then
			local distance = (model.PrimaryPart.Position - position).Magnitude
			if distance <= range then
				table.insert(targets, {Model = model, Data = data, Distance = distance})
			end
		end
	end
	table.sort(targets, function(a, b) return a.Distance < b.Distance end)
	return targets
end

function FighterAssistService:BaseDamage(player, assist)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return 0 end
	local power = stats:FindFirstChild("Power")
	if not power then return 0 end
	local modifiers = self:GetModifiers(player)
	local multiplier = math.max(0.1, tonumber(assist.DamageMultiplier) or 1)
	return math.max(1, math.floor(self.Context.Config.Game.BaseDamage * power.Value * multiplier * (1 + modifiers.AssistDamage)))
end

function FighterAssistService:SpawnEcho(player, slot, definition)
	local world = self.Context.WorldFolder
	local folder = world and world:FindFirstChild("WorldEvents")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not folder or not root then return end

	local color = self.Config.Elements[definition.Element] or Color3.fromRGB(185, 125, 255)
	local model = Instance.new("Model")
	model.Name = "FighterEcho_" .. definition.Id
	model.Parent = folder
	local side = ({-1, 0, 1})[slot] or 0
	local base = root.CFrame * CFrame.new(side * 4.2, 1.2, -2.8)

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2.5, 4.2, 1.4)
	torso.CFrame = base
	torso.Anchored = true
	torso.CanCollide = false
	torso.CanTouch = false
	torso.CanQuery = false
	torso.Material = Enum.Material.Neon
	torso.Color = color
	torso.Transparency = 0.20
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2.1, 2.1, 2.1)
	head.CFrame = base * CFrame.new(0, 3.05, 0)
	head.Anchored = true
	head.CanCollide = false
	head.CanTouch = false
	head.CanQuery = false
	head.Material = Enum.Material.Neon
	head.Color = color:Lerp(Color3.new(1, 1, 1), 0.18)
	head.Transparency = 0.16
	head.Parent = model

	local aura = Instance.new("PointLight")
	aura.Color = color
	aura.Brightness = 2.1
	aura.Range = 14
	aura.Shadows = false
	aura.Parent = torso

	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.new(0, 190, 0, 48)
	tag.StudsOffset = Vector3.new(0, 4.9, 0)
	tag.AlwaysOnTop = true
	tag.MaxDistance = 55
	tag.Parent = head
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = definition.Name .. "\n" .. definition.Assist.Name
	text.TextColor3 = color
	text.TextStrokeTransparency = 0.30
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Parent = tag

	for _, part in ipairs({torso, head}) do
		TweenService:Create(part, TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Transparency = 1,
			CFrame = part.CFrame * CFrame.new(0, 1.8, -1.2),
		}):Play()
	end
	TweenService:Create(text, TweenInfo.new(0.55), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	task.delay(0.72, function()
		if model.Parent then model:Destroy() end
	end)
end

function FighterAssistService:DoFront(player, root, definition, assist, burn)
	local combat = self.Context.Services.CombatService
	local targets = combat:EnemiesInFront(root, assist.Range or 20, assist.Dot or 0.25)
	local damage = self:BaseDamage(player, assist)
	local hitCount = 0
	for _, entry in ipairs(targets) do
		if hitCount >= 5 then break end
		combat:Hit(player, entry.Model, damage, false, assist.Stagger or 0)
		hitCount += 1
		if burn then
			local model = entry.Model
			local burnDamage = math.max(1, math.floor(damage * (assist.BurnMultiplier or 0.35)))
			task.delay(0.45, function()
				local data = combat.Enemies[model]
				if data and data.Alive then combat:Hit(player, model, burnDamage, false, 0) end
			end)
		end
	end
	return hitCount
end

function FighterAssistService:DoArea(player, root, definition, assist)
	local combat = self.Context.Services.CombatService
	local damage = self:BaseDamage(player, assist)
	local targets = self:GetTargetsAround(root.Position, assist.Range or 15)
	for _, entry in ipairs(targets) do
		combat:Hit(player, entry.Model, damage, false, assist.Stagger or 0)
	end
	return #targets
end

function FighterAssistService:DoNearest(player, root, definition, assist)
	local combat = self.Context.Services.CombatService
	local targets = self:GetTargetsAround(root.Position, assist.Range or 35)
	local target = targets[1]
	if not target then return 0 end
	combat:Hit(player, target.Model, self:BaseDamage(player, assist), false, assist.Stagger or 0)
	return 1
end

function FighterAssistService:DoChain(player, root, definition, assist)
	local combat = self.Context.Services.CombatService
	local targets = self:GetTargetsAround(root.Position, assist.Range or 30)
	local maxTargets = math.max(1, math.floor(tonumber(assist.MaxTargets) or 3))
	local baseDamage = self:BaseDamage(player, assist)
	local count = 0
	for index = 1, math.min(maxTargets, #targets) do
		local falloff = math.clamp(1 - (index - 1) * (assist.ChainFalloff or 0.15), 0.35, 1)
		combat:Hit(player, targets[index].Model, math.max(1, math.floor(baseDamage * falloff)), false, assist.Stagger or 0)
		count += 1
	end
	return count
end

function FighterAssistService:DoHealArea(player, root, definition, assist)
	local hitCount = self:DoArea(player, root, definition, assist)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		local heal = humanoid.MaxHealth * math.clamp(tonumber(assist.HealFraction) or 0, 0, 0.40)
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + heal)
	end
	return hitCount
end

function FighterAssistService:DoBarrage(player, root, definition, assist)
	local combat = self.Context.Services.CombatService
	local pulses = math.clamp(math.floor(tonumber(assist.Pulses) or 3), 1, 5)
	local baseDamage = self:BaseDamage(player, assist)
	for pulse = 1, pulses do
		task.delay((pulse - 1) * 0.20, function()
			if not player.Parent then return end
			local currentRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not currentRoot then return end
			local targets = self:GetTargetsAround(currentRoot.Position, assist.Range or 22)
			for index = 1, math.min(3, #targets) do
				combat:Hit(player, targets[index].Model, baseDamage, false, assist.Stagger or 0)
			end
			local color = self.Config.Elements[definition.Element] or Color3.fromRGB(255, 120, 220)
			combat:Pulse(currentRoot.Position, color, (assist.Range or 22) * (0.65 + pulse * 0.08), 0.25)
		end)
	end
	return #self:GetTargetsAround(root.Position, assist.Range or 22)
end

function FighterAssistService:Activate(player, slot)
	slot = math.floor(tonumber(slot) or 0)
	if slot < 1 or slot > self.Config.Settings.MaxEquipped then return end
	local item, definition, rarity = self:GetEquippedFighter(player, slot)
	if not item or not definition or not definition.Assist then return end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then return end

	local now = os.clock()
	local byPlayer = self.LastAssist[player]
	if not byPlayer then byPlayer = {}; self.LastAssist[player] = byPlayer end
	local cooldown = self:GetCooldown(player, definition)
	local last = byPlayer[item.Name] or -math.huge
	local remaining = cooldown - (now - last)
	if remaining > 0 then
		self.Context.Remotes.FighterAssist:FireClient(player, "Cooldown", slot, remaining, item.Name, definition.Assist.Name)
		return
	end

	local assist = definition.Assist
	local assistType = tostring(assist.Type)
	local color = self.Config.Elements[definition.Element] or Color3.fromRGB(185, 125, 255)
	local hitCount = 0

	if assistType == "Front" then
		hitCount = self:DoFront(player, root, definition, assist, false)
	elseif assistType == "FrontBurn" then
		hitCount = self:DoFront(player, root, definition, assist, true)
	elseif assistType == "Area" then
		hitCount = self:DoArea(player, root, definition, assist)
	elseif assistType == "Nearest" then
		hitCount = self:DoNearest(player, root, definition, assist)
	elseif assistType == "Chain" then
		hitCount = self:DoChain(player, root, definition, assist)
	elseif assistType == "HealArea" then
		hitCount = self:DoHealArea(player, root, definition, assist)
	elseif assistType == "Barrage" then
		hitCount = self:DoBarrage(player, root, definition, assist)
	else
		return
	end

	-- Empty target spam must not consume the cooldown except for explicit defensive/heal skills.
	if hitCount <= 0 and assistType ~= "HealArea" then
		self.Context:Notify(player, definition.Assist.Name .. " needs a target in range.", "info")
		return
	end

	byPlayer[item.Name] = now
	player:SetAttribute("FighterTeamLockedUntil", now + cooldown)
	self:SpawnEcho(player, slot, definition)
	self.Context.Services.CombatService:Pulse(root.Position, color, math.max(8, (assist.Range or 14) * 0.8), 0.32)
	self.Context.Remotes.FighterAssist:FireClient(player, "Activated", slot, cooldown, item.Name, definition.Assist.Name)
	self.Context:Notify(player, definition.Name .. " • " .. definition.Assist.Name, rarity or "info")
end

function FighterAssistService:InstallCombatPassiveBridge()
	local combat = self.Context.Services.CombatService
	if combat.__FighterPassivePatched then return end
	combat.__FighterPassivePatched = true
	local rawHit = combat.Hit
	function combat:Hit(player, model, damage, crit, stagger)
		local data = self.Enemies[model]
		local service = self.Context.Services.FighterAssistService
		if service and data and data.Alive and player and player.Parent then
			local modifiers = service:GetModifiers(player, data)
			local multiplier = 1 + modifiers.Damage + modifiers.BossDamage + modifiers.ExecuteDamage
			damage = math.max(1, math.floor((tonumber(damage) or 0) * multiplier))
		end
		return rawHit(self, player, model, damage, crit, stagger)
	end
end

function FighterAssistService:InstallHealthPassiveBridge()
	local statsService = self.Context.Services.StatsService
	if statsService.__FighterHealthPatched then return end
	statsService.__FighterHealthPatched = true
	local rawCalculate = statsService.Calculate
	function statsService:Calculate(player)
		local combatStats = rawCalculate(self, player)
		local service = self.Context.Services.FighterAssistService
		if combatStats and service then
			local modifiers = service:GetModifiers(player)
			combatStats.MaxHealth.Value = math.max(1, math.floor(combatStats.MaxHealth.Value * (1 + modifiers.MaxHealth)))
		end
		return combatStats
	end
end

function FighterAssistService:InstallTeamLockBridge()
	local fighterService = self.Context.Services.FighterService
	if fighterService.__AssistTeamLockPatched then return end
	fighterService.__AssistTeamLockPatched = true
	local rawEquip = fighterService.Equip
	function fighterService:Equip(player, fighterId)
		local lockedUntil = tonumber(player:GetAttribute("FighterTeamLockedUntil")) or 0
		if os.clock() < lockedUntil then
			local remaining = math.ceil(lockedUntil - os.clock())
			self.Context:Notify(player, "Fighter team locked while an Assist recovers • " .. remaining .. "s", "error")
			return
		end
		return rawEquip(self, player, fighterId)
	end
end

function FighterAssistService:Start()
	self:InstallCombatPassiveBridge()
	self:InstallHealthPassiveBridge()
	self:InstallTeamLockBridge()
	self.Context.Remotes.FighterAssist.OnServerEvent:Connect(function(player, slot)
		self:Activate(player, slot)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self.LastAssist[player] = nil
	end)
	print("[Fighter Assist] roles + passives + Z/X/C assists active")
end

return FighterAssistService
