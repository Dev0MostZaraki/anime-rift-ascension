local PathfindingService = game:GetService("PathfindingService")

local NavigationService = {}
NavigationService.__index = NavigationService

function NavigationService.new(context)
	return setmetatable({
		Context = context,
		Cache = setmetatable({}, {__mode = "k"}),
	}, NavigationService)
end

local function flatDistance(a, b)
	return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
end

function NavigationService:Clear(model)
	self.Cache[model] = nil
end

function NavigationService:Compute(model, fromPosition, targetPosition, force)
	if not model or not model.Parent then return nil end
	local now = os.clock()
	local cached = self.Cache[model]
	if cached and not force then
		local targetMoved = flatDistance(cached.Target, targetPosition)
		if now - cached.Time < 0.8 and targetMoved < 7 then
			return cached
		end
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2.2,
		AgentHeight = 6,
		AgentCanJump = false,
		WaypointSpacing = 7,
		Costs = {
			Water = 35,
		},
	})

	local success = pcall(function()
		path:ComputeAsync(fromPosition, targetPosition)
	end)

	local points = {}
	if success and path.Status == Enum.PathStatus.Success then
		for _, waypoint in ipairs(path:GetWaypoints()) do
			table.insert(points, waypoint.Position)
		end
	end
	if #points == 0 then
		table.insert(points, targetPosition)
	end

	cached = {
		Time = now,
		Target = targetPosition,
		Points = points,
		Index = math.min(2, #points),
	}
	self.Cache[model] = cached
	return cached
end

function NavigationService:GetNextPoint(model, fromPosition, targetPosition)
	local cached = self:Compute(model, fromPosition, targetPosition, false)
	if not cached then return targetPosition end

	while cached.Index <= #cached.Points do
		local point = cached.Points[cached.Index]
		if flatDistance(fromPosition, point) <= 4.5 then
			cached.Index += 1
		else
			return point
		end
	end
	return targetPosition
end

function NavigationService:Start()
	print("[Navigation] pathfinding cache ready")
end

return NavigationService
