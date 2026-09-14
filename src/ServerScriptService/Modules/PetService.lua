local RunService = game:GetService("RunService")

local PetService = {}
PetService.__index = PetService

function PetService.new(context)
	local self = setmetatable({}, PetService)
	self.Context = context
	self.Followers = {}
	return self
end

function PetService:GetEquippedCount(player)
	local inventory = player:FindFirstChild("PetInventory")
	if not inventory then return 0 end
	local count = 0
	for _, pet in ipairs(inventory:GetChildren()) do
		if pet:GetAttribute("Equipped") == true then count += 1 end
	end
	return count
end

function PetService:Roll(egg)
	local roll = math.random() * 100
	local total = 0
	for _, entry in ipairs(egg.Pets) do
		total += entry.Chance
		if roll <= total then
			return entry, entry.Names[math.random(1, #entry.Names)]
		end
	end
	return egg.Pets[1], egg.Pets[1].Names[1]
end

function PetService:Hatch(player, eggId)
	local egg = self.Context.Config.Eggs[eggId]
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	if not egg or not stats or not profile then return end

	local unlocked = profile.ZoneUnlocks:FindFirstChild("Zone" .. egg.Zone)
	if not unlocked or not unlocked.Value then
		self.Context:Notify(player, "Unlock this zone first.", "error")
		return
	end
	if stats.Coins.Value < egg.Cost then
		self.Context:Notify(player, "You need " .. egg.Cost .. " Coins.", "error")
		return
	end

	stats.Coins.Value -= egg.Cost
	local entry, petName = self:Roll(egg)
	self.Context.Services.DataService:AddPet(player, petName, entry.Rarity, entry.Bonus, true)
	profile.QuestHatches.Value += 1
	self:RebuildFollowers(player)
	self.Context.Services.QuestService:Check(player)
	self.Context:Notify(player, entry.Rarity .. " • " .. petName .. " • +" .. math.floor(entry.Bonus * 100) .. "% Power", entry.Rarity)
end

function PetService:Equip(player, petId)
	local inventory = player:FindFirstChild("PetInventory")
	if not inventory or type(petId) ~= "string" then return end

	if petId == "__BEST__" then
		local pets = inventory:GetChildren()
		table.sort(pets, function(a, b)
			return (tonumber(a:GetAttribute("Bonus")) or 0) > (tonumber(b:GetAttribute("Bonus")) or 0)
		end)
		for _, pet in ipairs(pets) do pet:SetAttribute("Equipped", false) end
		for i = 1, math.min(self.Context.Config.Game.MaxEquippedPets, #pets) do
			pets[i]:SetAttribute("Equipped", true)
		end
		self.Context.Services.DataService:RecalculatePower(player)
		self:RebuildFollowers(player)
		self.Context:Notify(player, "Best companions equipped.", "success")
		return
	end

	local pet = inventory:FindFirstChild(petId)
	if not pet then return end
	if pet:GetAttribute("Equipped") == true then
		pet:SetAttribute("Equipped", false)
	else
		if self:GetEquippedCount(player) >= self.Context.Config.Game.MaxEquippedPets then
			self.Context:Notify(player, "You can equip only " .. self.Context.Config.Game.MaxEquippedPets .. " companions.", "error")
			return
		end
		pet:SetAttribute("Equipped", true)
	end
	self.Context.Services.DataService:RecalculatePower(player)
	self:RebuildFollowers(player)
end

function PetService:ClearFollowers(player)
	local folder = self.Followers[player]
	if folder and folder.Parent then folder:Destroy() end
	self.Followers[player] = nil
end

local function billboard(parent, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 124, 0, 28)
	gui.StudsOffset = Vector3.new(0, 2.45, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 32
	gui.LightInfluence = 0
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.42
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
end

local function visualPart(model, name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Material = material or Enum.Material.Neon
	part.Color = color
	part.Parent = model
	return part
end

function PetService:RebuildFollowers(player)
	self:ClearFollowers(player)
	local inventory = player:FindFirstChild("PetInventory")
	local world = self.Context.WorldFolder
	if not inventory or not world then return end
	local rootFolder = world:FindFirstChild("Followers")
	if not rootFolder then return end

	local folder = Instance.new("Folder")
	folder.Name = tostring(player.UserId)
	folder.Parent = rootFolder
	self.Followers[player] = folder

	local slot = 0
	for _, pet in ipairs(inventory:GetChildren()) do
		if pet:GetAttribute("Equipped") == true and slot < self.Context.Config.Game.MaxEquippedPets then
			slot += 1
			local rarity = tostring(pet:GetAttribute("Rarity") or "Common")
			local color = self.Context.Config.RarityColors[rarity] or self.Context.Config.RarityColors.Common

			local model = Instance.new("Model")
			model.Name = pet.Value
			model:SetAttribute("Slot", slot)
			model.Parent = folder

			local body = visualPart(model, "Body", Vector3.new(2.35, 2.35, 2.35), color)
			body.Shape = Enum.PartType.Ball
			local core = visualPart(model, "Core", Vector3.new(0.82, 0.82, 0.82), Color3.fromRGB(250, 250, 255))
			core.Shape = Enum.PartType.Ball
			local left = visualPart(model, "LeftOrb", Vector3.new(0.55, 0.55, 0.55), color:Lerp(Color3.new(1, 1, 1), 0.35))
			left.Shape = Enum.PartType.Ball
			local right = visualPart(model, "RightOrb", Vector3.new(0.55, 0.55, 0.55), color:Lerp(Color3.new(1, 1, 1), 0.35))
			right.Shape = Enum.PartType.Ball

			billboard(body, pet.Value, color)
			model.PrimaryPart = body
		end
	end
end

function PetService:Start()
	self.Context.Remotes.EquipPet.OnServerEvent:Connect(function(player, petId)
		self:Equip(player, petId)
	end)

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for player, folder in pairs(self.Followers) do
			if not player.Parent then
				self:ClearFollowers(player)
			else
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and folder and folder.Parent then
					for _, model in ipairs(folder:GetChildren()) do
						local slot = model:GetAttribute("Slot") or 1
						local body = model:FindFirstChild("Body")
						local core = model:FindFirstChild("Core")
						local left = model:FindFirstChild("LeftOrb")
						local right = model:FindFirstChild("RightOrb")
						if body and core then
							local xOffsets = {-4.4, 0, 4.4}
							local x = xOffsets[slot] or 0
							local back = 5.4 + math.abs(slot - 2) * 0.9
							local bob = math.sin(now * 3 + slot * 1.7) * 0.3
							local target = root.Position + root.CFrame.RightVector * x - root.CFrame.LookVector * back + Vector3.new(0, 2.5 + bob, 0)
							body.CFrame = CFrame.new(target)
							core.CFrame = CFrame.new(target)
							if left then left.CFrame = CFrame.new(target + Vector3.new(-1.45, 0.15, 0)) end
							if right then right.CFrame = CFrame.new(target + Vector3.new(1.45, 0.15, 0)) end
						end
					end
				end
			end
		end
	end)
end

return PetService
