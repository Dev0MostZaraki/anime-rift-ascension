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
		if pet:GetAttribute("Equipped") == true then
			count += 1
		end
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
		for _, pet in ipairs(pets) do
			pet:SetAttribute("Equipped", false)
		end
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
	if folder and folder.Parent then
		folder:Destroy()
	end
	self.Followers[player] = nil
end

local function billboard(parent, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 150, 0, 36)
	gui.StudsOffset = Vector3.new(0, 2.7, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 100
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
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

			local body = Instance.new("Part")
			body.Name = "Body"
			body.Size = Vector3.new(2.8, 2.8, 2.8)
			body.Shape = Enum.PartType.Ball
			body.Anchored = true
			body.CanCollide = false
			body.CanTouch = false
			body.CanQuery = false
			body.Material = Enum.Material.Neon
			body.Color = color
			body.Parent = model

			local core = Instance.new("Part")
			core.Name = "Core"
			core.Size = Vector3.new(1.15, 1.15, 1.15)
			core.Shape = Enum.PartType.Ball
			core.Anchored = true
			core.CanCollide = false
			core.CanTouch = false
			core.CanQuery = false
			core.Material = Enum.Material.Neon
			core.Color = Color3.fromRGB(245, 245, 255)
			core.Parent = model

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
						if body and core then
							local xOffsets = {-3.5, 0, 3.5}
							local x = xOffsets[slot] or 0
							local back = 4.3 + math.abs(slot - 2) * 0.7
							local bob = math.sin(now * 3 + slot) * 0.32
							local target = root.Position + root.CFrame.RightVector * x - root.CFrame.LookVector * back + Vector3.new(0, 2.3 + bob, 0)
							body.CFrame = CFrame.new(target)
							core.CFrame = CFrame.new(target)
						end
					end
				end
			end
		end
	end)
end

return PetService
