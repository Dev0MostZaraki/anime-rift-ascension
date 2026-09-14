local ArsenalService = {}
ArsenalService.__index = ArsenalService

function ArsenalService.new(context)
	return setmetatable({Context = context}, ArsenalService)
end

function ArsenalService:GetStyle(player)
	local profile = player:FindFirstChild("RiftProfile")
	local styleId = profile and profile:FindFirstChild("EquippedStyle") and profile.EquippedStyle.Value or "RiftBlade"
	local style = self.Context.Config.Styles[styleId]
	if not style then
		styleId = "RiftBlade"
		style = self.Context.Config.Styles.RiftBlade
	end
	return style, styleId
end

function ArsenalService:GetMastery(player, styleId)
	local profile = player:FindFirstChild("RiftProfile")
	local folder = profile and profile:FindFirstChild("StyleMastery")
	local value = folder and folder:FindFirstChild(styleId)
	return value and value.Value or 0
end

function ArsenalService:GetMasteryMultiplier(player, styleId)
	local cfg = self.Context.Config.Game
	local mastery = self:GetMastery(player, styleId)
	local bonus = math.min(cfg.MasteryDamageCap, mastery * cfg.MasteryDamagePerPoint)
	return 1 + bonus
end

function ArsenalService:AddMastery(player, amount)
	local profile = player:FindFirstChild("RiftProfile")
	if not profile then return end
	local styleId = profile.EquippedStyle.Value
	local mastery = profile.StyleMastery:FindFirstChild(styleId)
	if not mastery then return end
	mastery.Value += math.max(0, math.floor(amount or 0))
	local milestones = {50, 100, 200, 350, 500}
	for _, mark in ipairs(milestones) do
		if mastery.Value >= mark and mastery.Value - math.max(0, math.floor(amount or 0)) < mark then
			self.Context:Notify(player, "STYLE MASTERY • " .. self.Context.Config.Styles[styleId].Name .. " reached " .. mark, "level")
			break
		end
	end
end

function ArsenalService:Equip(player, styleId)
	local profile = player:FindFirstChild("RiftProfile")
	local style = self.Context.Config.Styles[styleId]
	if not profile or not style then return end
	local unlocked = profile.StyleUnlocks:FindFirstChild(styleId)
	if not unlocked or not unlocked.Value then return end
	profile.EquippedStyle.Value = styleId
	self.Context.Services.CombatService:GiveWeapon(player)
	self.Context:Notify(player, style.Name .. " equipped.", "success")
end

function ArsenalService:PurchaseOrEquip(player, styleId)
	if type(styleId) ~= "string" then return end
	local style = self.Context.Config.Styles[styleId]
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	if not style or not stats or not profile then return end
	local unlocked = profile.StyleUnlocks:FindFirstChild(styleId)
	if not unlocked then return end

	if unlocked.Value then
		self:Equip(player, styleId)
		return
	end

	if stats.Level.Value < style.UnlockLevel then
		self.Context:Notify(player, style.Name .. " requires Level " .. style.UnlockLevel .. ".", "error")
		return
	end
	if stats.Coins.Value < style.UnlockCost then
		self.Context:Notify(player, style.Name .. " costs " .. style.UnlockCost .. " Coins.", "error")
		return
	end

	stats.Coins.Value -= style.UnlockCost
	unlocked.Value = true
	self.Context:Notify(player, "STYLE UNLOCKED • " .. style.Name, "level")
	self:Equip(player, styleId)
end

function ArsenalService:Start()
	self.Context.Remotes.StyleAction.OnServerEvent:Connect(function(player, styleId)
		self:PurchaseOrEquip(player, styleId)
	end)
end

return ArsenalService
