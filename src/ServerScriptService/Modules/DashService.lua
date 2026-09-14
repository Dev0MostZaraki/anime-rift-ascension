local Workspace = game:GetService("Workspace")

local DashService = {}
DashService.__index = DashService

function DashService.new(context)
	return setmetatable({
		Context = context,
		LastDash = {},
	}, DashService)
end

local function flatDirection(vector)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude < 0.05 then
		return nil
	end
	return flat.Unit
end

function DashService:GetDirection(humanoid, root)
	-- Prefer movement input when Roblox exposes it on the server; otherwise dash forward.
	local move = flatDirection(humanoid.MoveDirection)
	if move then
		return move
	end
	return flatDirection(root.CFrame.LookVector)
end

function DashService:Dash(player)
	local cfg = self.Context.Config.Game
	local now = os.clock()
	local last = self.LastDash[player] or 0
	if now - last < cfg.DashCooldown then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health <= 0 or not root then
		return
	end

	local direction = self:GetDirection(humanoid, root)
	if not direction then
		return
	end

	self.LastDash[player] = now

	-- A one-frame velocity impulse can be swallowed by Roblox's character controller.
	-- Move a fixed distance instead, while raycasting so the player cannot dash through walls.
	local desiredDistance = cfg.DashDistance or math.clamp((cfg.DashSpeed or 82) * 0.20, 14, 18)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.IgnoreWater = true

	local origin = root.Position
	local cast = Workspace:Raycast(origin, direction * desiredDistance, params)
	local actualDistance = desiredDistance
	if cast then
		actualDistance = math.max(0, cast.Distance - 2.5)
	end

	if actualDistance < 1 then
		return
	end

	local startPosition = root.Position
	local delta = direction * actualDistance
	character:PivotTo(root.CFrame + delta)

	-- Keep a little momentum so the dash reads as movement instead of a teleport.
	root.AssemblyLinearVelocity = direction * math.min(cfg.DashSpeed or 82, 62) + Vector3.new(0, math.max(root.AssemblyLinearVelocity.Y, 0), 0)

	local combat = self.Context.Services.CombatService
	if combat and combat.Pulse then
		combat:Pulse(startPosition, Color3.fromRGB(90, 170, 255), 5, 0.16)
		combat:Pulse(root.Position, Color3.fromRGB(160, 220, 255), 7, 0.20)
	end
end

function DashService:Start()
	self.Context.Remotes.Ability.OnServerEvent:Connect(function(player, name)
		if name == "Dash" then
			self:Dash(player)
		end
	end)
end

return DashService
