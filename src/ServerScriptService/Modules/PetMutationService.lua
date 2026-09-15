local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local ProgressionConfig = require(AnimeRift:WaitForChild("ProgressionConfig"))

local PetMutationService = {}
PetMutationService.__index = PetMutationService

local function weightedMutation(entries, luckMultiplier)
	luckMultiplier = math.max(1, tonumber(luckMultiplier) or 1)
	local total = 0
	local adjusted = table.create(#entries)
	for index, mutation in ipairs(entries) do
		local rank = math.max(0, tonumber(mutation.Rank) or (index - 1))
		local weight = math.max(0, tonumber(mutation.Weight) or 0) * (luckMultiplier ^ (rank * 0.32))
		adjusted[index] = weight
		total += weight
	end
	if total <= 0 then return entries[1] end
	local roll = math.random() * total
	local cursor = 0
	for index, mutation in ipairs(entries) do
		cursor += adjusted[index]
		if roll <= cursor then return mutation end
	end
	return entries[#entries]
end

function PetMutationService.new(context)
	return setmetatable({Context = context, Config = ProgressionConfig}, PetMutationService)
end

function PetMutationService:Roll(player)
	local activity = self.Context.Services.ActivityService
	local luck = activity and activity:GetLuckMultiplier(player) or 1
	return weightedMutation(self.Config.Mutations, luck)
end

function PetMutationService:ApplyToPet(player, pet)
	if not pet or pet:GetAttribute("Mutation") ~= nil then return end
	local mutation = self:Roll(player)
	local baseBonus = math.max(0, tonumber(pet:GetAttribute("Bonus")) or 0)
	pet:SetAttribute("Role", "Combat")
	pet:SetAttribute("Mutation", mutation.Id)
	pet:SetAttribute("MutationPower", mutation.PowerMultiplier or 1)
	pet:SetAttribute("LuckBonus", 0)
	pet:SetAttribute("DropBonus", 0)
	pet:SetAttribute("Source", "Hatch")
	pet:SetAttribute("BaseBonus", baseBonus)
	pet:SetAttribute("Bonus", baseBonus * (tonumber(mutation.PowerMultiplier) or 1))
	self.Context.Services.DataService:RecalculatePower(player)
	if mutation.Id ~= "Normal" then
		self.Context:Notify(player, "MUTATION • " .. mutation.Id .. " " .. pet.Value, mutation.Id == "Divine" and "world" or "success")
	end
end

function PetMutationService:InstallBridge()
	local pets = self.Context.Services.PetService
	if not pets or pets.__MutationPatched then return end
	pets.__MutationPatched = true
	local rawHatch = pets.Hatch
	function pets:Hatch(player, eggId)
		local inventory = player:FindFirstChild("PetInventory")
		local before = {}
		if inventory then
			for _, pet in ipairs(inventory:GetChildren()) do before[pet] = true end
		end
		rawHatch(self, player, eggId)
		inventory = player:FindFirstChild("PetInventory")
		if not inventory then return end
		for _, pet in ipairs(inventory:GetChildren()) do
			if not before[pet] then
				self.Context.Services.PetMutationService:ApplyToPet(player, pet)
				break
			end
		end
	end
end

function PetMutationService:Start()
	self:InstallBridge()
	print("[Pet Mutation] standard hatches can roll mutations")
end

return PetMutationService
