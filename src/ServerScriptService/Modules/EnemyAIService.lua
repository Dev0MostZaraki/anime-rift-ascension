local StateMachine = require(script.Parent:WaitForChild("StateMachine"))

local EnemyAIService = {}
EnemyAIService.__index = EnemyAIService

function EnemyAIService.new(context)
	return setmetatable({
		Context = context,
		Machines = setmetatable({}, {__mode = "k"}),
	}, EnemyAIService)
end

local function flatDistance(a, b)
	return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
end

function EnemyAIService:SetState(model, data, name)
	data.AIState = name
	if model and model.Parent then model:SetAttribute("AIState", name) end
end

function EnemyAIService:MoveToward(model, data, target, speed, dt)
	if not model.PrimaryPart then return end
	local body = model.PrimaryPart
	local nav = self.Context.Services.NavigationService
	local nextPoint = nav and nav:GetNextPoint(model, body.Position, target) or target
	local delta = Vector3.new(nextPoint.X - body.Position.X, 0, nextPoint.Z - body.Position.Z)
	if delta.Magnitude <= 0.2 then return end
	local step = math.min(delta.Magnitude, speed * dt)
	local nextPos = body.Position + delta.Unit * step
	local lookTarget = Vector3.new(nextPoint.X, nextPos.Y, nextPoint.Z)
	model:PivotTo(CFrame.lookAt(nextPos, lookTarget))
end

function EnemyAIService:ChoosePatrol(data)
	local angle = math.random() * math.pi * 2
	local radius = math.random(7, data.Elite and 18 or 15)
	return data.Spawn + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

function EnemyAIService:AttackTarget(ctx)
	local combat = ctx.Combat
	local data = ctx.Data
	local model = ctx.Model
	local player = ctx.TargetPlayer
	local root = ctx.TargetRoot
	if not player or not root or not model.PrimaryPart then return end
	local now = ctx.Now

	if data.Boss and now >= (data.NextSlam or 0) and now >= (data.CastingUntil or 0) then
		combat:BossSlam(model, data, root)
		return
	end
	if now < (data.CastingUntil or 0) then return end

	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 and now - (data.LastHit or 0) >= ctx.AttackCooldown then
		data.LastHit = now
		humanoid:TakeDamage(ctx.Damage)
		combat:Pulse(root.Position, data.Boss and Color3.fromRGB(255, 70, 145) or data.Zone.Color, data.Boss and 8 or 5, 0.16)
		data.RecoverUntil = now + math.min(0.45, ctx.AttackCooldown * 0.32)
	end
end

function EnemyAIService:HandleBlink(ctx)
	local data = ctx.Data
	local model = ctx.Model
	local root = ctx.TargetRoot
	local combat = ctx.Combat
	if data.Archetype ~= "Blinker" or not root or not ctx.Distance then return false end
	if ctx.Distance <= 13 or ctx.Distance >= 33 or ctx.Now < (data.NextSpecial or 0) then return false end

	data.NextSpecial = ctx.Now + self.Context.Config.Game.EnemyBlinkCooldown
	local body = model.PrimaryPart
	local away = Vector3.new(body.Position.X - root.Position.X, 0, body.Position.Z - root.Position.Z)
	if away.Magnitude < 0.1 then away = Vector3.new(1, 0, 0) end
	local newPos = root.Position + away.Unit * 7
	newPos = Vector3.new(newPos.X, body.Position.Y, newPos.Z)
	combat:Pulse(body.Position, data.Zone.Color, 6, 0.18)
	model:PivotTo(CFrame.lookAt(newPos, Vector3.new(root.Position.X, newPos.Y, root.Position.Z)))
	combat:Pulse(newPos, data.Zone.Color, 6, 0.18)
	local nav = self.Context.Services.NavigationService
	if nav then nav:Clear(model) end
	return true
end

function EnemyAIService:CreateMachine(combat, model, data)
	local ctx = {
		Service = self,
		Combat = combat,
		Model = model,
		Data = data,
		Now = os.clock(),
		Dt = 0,
		TargetPlayer = nil,
		TargetRoot = nil,
		Distance = nil,
		AttackRange = self.Context.Config.Game.EnemyAttackRange,
		AttackCooldown = self.Context.Config.Game.EnemyAttackCooldown,
		Damage = data.Damage,
	}

	local idle = {name = "Idle"}
	local patrol = {name = "Patrol"}
	local chase = {name = "Chase"}
	local attack = {name = "Attack"}
	local recover = {name = "Recover"}
	local returning = {name = "Return"}

	local function enter(name)
		return function(c)
			self:SetState(c.Model, c.Data, name)
		end
	end
	idle.onEnter = function(c)
		enter("Idle")(c)
		c.Data.NextPatrolAt = c.Now + math.random(12, 30) / 10
	end
	patrol.onEnter = function(c)
		enter("Patrol")(c)
		c.Data.PatrolTarget = self:ChoosePatrol(c.Data)
	end
	chase.onEnter = enter("Chase")
	attack.onEnter = enter("Attack")
	recover.onEnter = enter("Recover")
	returning.onEnter = function(c)
		enter("Return")(c)
		local nav = self.Context.Services.NavigationService
		if nav then nav:Clear(c.Model) end
	end

	patrol.onStay = function(c)
		local speed = self.Context.Config.Game.EnemyMoveSpeed * 0.46
		self:MoveToward(c.Model, c.Data, c.Data.PatrolTarget or c.Data.Spawn, speed, c.Dt)
	end
	chase.onStay = function(c)
		if not c.TargetRoot or not c.Model.PrimaryPart then return end
		if self:HandleBlink(c) then return end
		local speed = c.Data.Boss and self.Context.Config.Game.BossMoveSpeed * (1 + ((c.Data.Phase or 1) - 1) * 0.22) or self.Context.Config.Game.EnemyMoveSpeed
		if c.Data.Archetype == "Charger" then speed *= 1.42 end
		if c.Data.Archetype == "Guardian" then speed *= 0.72 end
		if c.Data.Rare then speed *= 1.08 end
		self:MoveToward(c.Model, c.Data, c.TargetRoot.Position, speed, c.Dt)
	end
	attack.onStay = function(c) self:AttackTarget(c) end
	recover.onStay = function() end
	returning.onStay = function(c)
		local speed = c.Data.Boss and self.Context.Config.Game.BossMoveSpeed or self.Context.Config.Game.EnemyMoveSpeed
		self:MoveToward(c.Model, c.Data, c.Data.Spawn, speed, c.Dt)
	end

	local machine = StateMachine.new(idle, ctx)
	StateMachine.addTransition(machine, {idle}, chase, function(c) return c.TargetRoot ~= nil end)
	StateMachine.addTransition(machine, {idle}, patrol, function(c) return c.Now >= (c.Data.NextPatrolAt or 0) end)
	StateMachine.addTransition(machine, {patrol}, chase, function(c) return c.TargetRoot ~= nil end)
	StateMachine.addTransition(machine, {patrol}, idle, function(c)
		return c.Data.PatrolTarget and c.Model.PrimaryPart and flatDistance(c.Model.PrimaryPart.Position, c.Data.PatrolTarget) <= 2.5
	end)
	StateMachine.addTransition(machine, {chase}, returning, function(c) return c.TargetRoot == nil end)
	StateMachine.addTransition(machine, {chase}, attack, function(c) return c.TargetRoot ~= nil and c.Distance and c.Distance <= c.AttackRange end)
	StateMachine.addTransition(machine, {attack}, returning, function(c) return c.TargetRoot == nil end)
	StateMachine.addTransition(machine, {attack}, chase, function(c) return c.Distance and c.Distance > c.AttackRange + 1.5 end)
	StateMachine.addTransition(machine, {attack}, recover, function(c) return c.Now < (c.Data.RecoverUntil or 0) end)
	StateMachine.addTransition(machine, {recover}, returning, function(c) return c.TargetRoot == nil end)
	StateMachine.addTransition(machine, {recover}, chase, function(c) return c.Now >= (c.Data.RecoverUntil or 0) and c.Distance and c.Distance > c.AttackRange end)
	StateMachine.addTransition(machine, {recover}, attack, function(c) return c.Now >= (c.Data.RecoverUntil or 0) and c.TargetRoot ~= nil end)
	StateMachine.addTransition(machine, {returning}, chase, function(c) return c.TargetRoot ~= nil end)
	StateMachine.addTransition(machine, {returning}, idle, function(c)
		return c.Model.PrimaryPart and flatDistance(c.Model.PrimaryPart.Position, c.Data.Spawn) <= 2.5
	end)

	idle.onEnter(ctx)
	self.Machines[model] = machine
	return machine
end

function EnemyAIService:StepEnemy(combat, model, data, dt)
	if not data.Alive or not model.Parent or not model.PrimaryPart then return end
	if os.clock() < (data.StaggerUntil or 0) then return end

	local cfg = self.Context.Config.Game
	local body = model.PrimaryPart
	local player, root, distance = combat:ClosestPlayer(body.Position, cfg.EnemyAggroRange + (data.Rare and 8 or 0))
	if flatDistance(body.Position, data.Spawn) > cfg.EnemyLeashRange then
		player, root, distance = nil, nil, nil
	end

	local attackRange = cfg.EnemyAttackRange
	local cooldown = cfg.EnemyAttackCooldown
	local damage = data.Damage
	if data.Archetype == "Guardian" then attackRange += 1.5; cooldown *= 1.3; damage = math.floor(damage * 1.2) end
	if data.Boss then
		local phase = data.Phase or 1
		damage = math.floor(damage * (1 + (phase - 1) * 0.22))
		cooldown = cooldown / (1 + (phase - 1) * 0.16)
	end

	local machine = self.Machines[model] or self:CreateMachine(combat, model, data)
	local c = machine.context
	c.Now = os.clock()
	c.Dt = dt
	c.TargetPlayer = player
	c.TargetRoot = root
	c.Distance = distance
	c.AttackRange = attackRange
	c.AttackCooldown = cooldown
	c.Damage = damage
	StateMachine.tick(machine)
end

function EnemyAIService:Install()
	local combat = self.Context.Services.CombatService
	if combat.__StateDrivenAI then return end
	combat.__StateDrivenAI = true
	local service = self
	function combat:StepAI(dt)
		for model, data in pairs(self.Enemies) do
			service:StepEnemy(self, model, data, dt)
		end
	end
end

function EnemyAIService:Start()
	self:Install()
	print("[Enemy AI] state machine + pathfinding active")
end

return EnemyAIService
