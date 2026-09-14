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
		if roll <= total then return entry, entry.Names[math.random(1, #entry.Names)] end
	end
	return egg.Pets[1], egg.Pets[1].Names[1]
end

function PetService:Hatch(player, eggId)
	local egg = self.Context.Config.Eggs[eggId]
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	if not egg or not stats or not profile then return end
	local unlocked = profile.ZoneUnlocks:FindFirstChild("Zone" .. egg.Zone)
	if not unlocked or not unlocked.Value then self.Context:Notify(player, "Unlock this zone first.", "error") return end
	if stats.Coins.Value < egg.Cost then self.Context:Notify(player, "You need " .. egg.Cost .. " Coins.", "error") return end
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
		table.sort(pets, function(a, b) return (tonumber(a:GetAttribute("Bonus")) or 0) > (tonumber(b:GetAttribute("Bonus")) or 0) end)
		for _, pet in ipairs(pets) do pet:SetAttribute("Equipped", false) end
		for i = 1, math.min(self.Context.Config.Game.MaxEquippedPets, #pets) do pets[i]:SetAttribute("Equipped", true) end
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
	gui.Name = "CompanionLabel"
	gui.Size = UDim2.new(0, 138, 0, 30)
	gui.StudsOffset = Vector3.new(0, 2.8, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 24
	gui.LightInfluence = 0
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
	label.BackgroundTransparency = 0.34
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.68
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

local function visualPart(model, name, size, color, material, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local rarityRank = {Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, WORLD = 6}

function PetService:BuildCompanionModel(parent, pet, slot)
	local rarity = tostring(pet:GetAttribute("Rarity") or "Common")
	local color = self.Context.Config.RarityColors[rarity] or self.Context.Config.RarityColors.Common

	-- Imported creature art wins automatically. This lets Blender models replace the
	-- prototype one family at a time without touching inventory or follow logic.
	local art = self.Context.Services.CreatureArtService
	if art then
		local imported = art:TryBuildPet(parent, pet, slot)
		if imported then
			billboard(imported.PrimaryPart, pet.Value, color)
			return imported
		end
	end

	local rank = rarityRank[rarity] or 1
	local dark = color:Lerp(Color3.fromRGB(24, 25, 34), 0.68)
	local highlight = color:Lerp(Color3.new(1, 1, 1), 0.28)
	local model = Instance.new("Model")
	model.Name = pet.Value
	model:SetAttribute("Slot", slot)
	model:SetAttribute("Rarity", rarity)
	model:SetAttribute("ProceduralCompanion", true)
	model.Parent = parent
	local body = visualPart(model, "Body", Vector3.new(2.45, 2.1, 2.8), dark, Enum.Material.SmoothPlastic)
	body.Shape = Enum.PartType.Ball
	local head = visualPart(model, "Head", Vector3.new(1.9, 1.8, 1.9), color:Lerp(Color3.fromRGB(40, 42, 52), 0.46), Enum.Material.SmoothPlastic)
	head.Shape = Enum.PartType.Ball
	local core = visualPart(model, "Core", Vector3.new(0.72, 0.72, 0.38), highlight, Enum.Material.Glass, 0.10)
	core.Shape = Enum.PartType.Ball
	visualPart(model, "EarL", Vector3.new(0.48, 1.15, 0.58), color, Enum.Material.SmoothPlastic)
	visualPart(model, "EarR", Vector3.new(0.48, 1.15, 0.58), color, Enum.Material.SmoothPlastic)
	visualPart(model, "WingL", Vector3.new(1.65 + rank * 0.12, 0.38, 1.2), highlight, Enum.Material.Glass, rank >= 2 and 0.16 or 0.32)
	visualPart(model, "WingR", Vector3.new(1.65 + rank * 0.12, 0.38, 1.2), highlight, Enum.Material.Glass, rank >= 2 and 0.16 or 0.32)
	visualPart(model, "Tail", Vector3.new(0.52, 0.52, 1.85), color, Enum.Material.SmoothPlastic)
	if rank >= 4 then local crown = visualPart(model, "Crown", Vector3.new(2.3, 0.34, 2.3), highlight, Enum.Material.Glass, 0.16); crown.Shape = Enum.PartType.Cylinder end
	if rank >= 5 then local halo = visualPart(model, "Halo", Vector3.new(3.2, 0.22, 3.2), color, Enum.Material.Glass, 0.20); halo.Shape = Enum.PartType.Cylinder end
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = 0.12 + rank * 0.055
	l.Range = 5 + rank * 0.55
	l.Shadows = false
	l.Parent = core
	billboard(head, pet.Value, color)
	model.PrimaryPart = body
	return model
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
	local pets = {}
	for _, pet in ipairs(inventory:GetChildren()) do if pet:GetAttribute("Equipped") == true then table.insert(pets, pet) end end
	table.sort(pets, function(a, b) return (tonumber(a:GetAttribute("Bonus")) or 0) > (tonumber(b:GetAttribute("Bonus")) or 0) end)
	for slot = 1, math.min(self.Context.Config.Game.MaxEquippedPets, #pets) do self:BuildCompanionModel(folder, pets[slot], slot) end
end

local function placePart(p, cf)
	if p then p.CFrame = cf end
end

function PetService:Start()
	self.Context.Remotes.EquipPet.OnServerEvent:Connect(function(player, petId) self:Equip(player, petId) end)
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
						local xOffsets = {-4.7, 0, 4.7}
						local x = xOffsets[slot] or 0
						local back = 6.1 + math.abs(slot - 2) * 0.7
						local bob = math.sin(now * 2.7 + slot * 1.8) * 0.36
						local target = root.Position + root.CFrame.RightVector * x - root.CFrame.LookVector * back + Vector3.new(0, 2.8 + bob, 0)
						local base = CFrame.lookAt(target, target + root.CFrame.LookVector)

						if model:GetAttribute("ImportedCompanion") == true and model.PrimaryPart then
							local sway = math.sin(now * 1.7 + slot) * math.rad(3.5)
							model:PivotTo(base * CFrame.Angles(0, 0, sway))
						else
							local body = model:FindFirstChild("Body")
							if body then
								body.CFrame = base
								placePart(model:FindFirstChild("Head"), base * CFrame.new(0, 0.75, -1.15))
								placePart(model:FindFirstChild("Core"), base * CFrame.new(0, 0.65, -2.05))
								placePart(model:FindFirstChild("EarL"), base * CFrame.new(-0.65, 1.75, -1.1) * CFrame.Angles(0, 0, math.rad(-18)))
								placePart(model:FindFirstChild("EarR"), base * CFrame.new(0.65, 1.75, -1.1) * CFrame.Angles(0, 0, math.rad(18)))
								local flap = math.sin(now * 5 + slot) * 0.18
								placePart(model:FindFirstChild("WingL"), base * CFrame.new(-1.75, 0.25, 0.05) * CFrame.Angles(0, math.rad(-12), math.rad(-20 - flap * 25)))
								placePart(model:FindFirstChild("WingR"), base * CFrame.new(1.75, 0.25, 0.05) * CFrame.Angles(0, math.rad(12), math.rad(20 + flap * 25)))
								placePart(model:FindFirstChild("Tail"), base * CFrame.new(0, -0.35, 1.95) * CFrame.Angles(math.rad(20), 0, 0))
								placePart(model:FindFirstChild("Crown"), base * CFrame.new(0, 2.45, -1.05) * CFrame.Angles(0, 0, math.rad(90)))
								placePart(model:FindFirstChild("Halo"), base * CFrame.new(0, 2.75, -0.95) * CFrame.Angles(0, 0, math.rad(90)))
							end
						end
					end
				end
			end
		end
	end)
end

return PetService
