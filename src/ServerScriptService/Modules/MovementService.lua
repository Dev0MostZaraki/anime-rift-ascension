local Players = game:GetService("Players")

local MovementService = {}
MovementService.__index = MovementService

function MovementService.new(context)
	return setmetatable({
		Context = context,
		SprintState = {},
	}, MovementService)
end

function MovementService:GetSpeeds()
	local cfg = self.Context.Config.Game
	return cfg.WalkSpeed or 16, cfg.SprintSpeed or 27
end

function MovementService:Apply(player, sprinting)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	local walkSpeed, sprintSpeed = self:GetSpeeds()
	local sprint = sprinting == true
	self.SprintState[player] = sprint
	player:SetAttribute("AnimeRiftSprinting", sprint)
	humanoid.WalkSpeed = sprint and sprintSpeed or walkSpeed
end

function MovementService:PrepareCharacter(player, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	self.SprintState[player] = false
	player:SetAttribute("AnimeRiftSprinting", false)
	local walkSpeed = self:GetSpeeds()
	humanoid.WalkSpeed = walkSpeed
	humanoid.Died:Connect(function()
		self.SprintState[player] = false
		player:SetAttribute("AnimeRiftSprinting", false)
	end)
end

function MovementService:SetupPlayer(player)
	if player.Character then task.defer(function() self:PrepareCharacter(player, player.Character) end) end
	player.CharacterAdded:Connect(function(character)
		self:PrepareCharacter(player, character)
	end)
end

function MovementService:Start()
	for _, player in ipairs(Players:GetPlayers()) do self:SetupPlayer(player) end
	Players.PlayerAdded:Connect(function(player) self:SetupPlayer(player) end)
	Players.PlayerRemoving:Connect(function(player)
		self.SprintState[player] = nil
	end)

	self.Context.Remotes.Movement.OnServerEvent:Connect(function(player, action, value)
		if action ~= "Sprint" then return end
		self:Apply(player, value == true)
	end)
end

return MovementService
