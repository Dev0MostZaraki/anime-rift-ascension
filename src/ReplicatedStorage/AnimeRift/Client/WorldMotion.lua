local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WorldMotion = {}
WorldMotion.__index = WorldMotion

local function trackedName(name)
	return name == "NexusCrystal"
		or string.find(name, "NexusFloatingShard", 1, true)
		or string.find(name, "NexusCoreRing", 1, true)
		or string.find(name, "PortalCore_", 1, true)
		or string.find(name, "PortalSurface_", 1, true)
		or string.find(name, "EggOrb_", 1, true)
		or string.find(name, "VoidMonolith", 1, true)
end

function WorldMotion.new()
	return setmetatable({Items = {}, Connection = nil}, WorldMotion)
end

function WorldMotion:Collect()
	table.clear(self.Items)
	local world = Workspace:FindFirstChild("AnimeRiftWorld") or Workspace:WaitForChild("AnimeRiftWorld", 15)
	if not world then return end
	local index = 0
	for _, object in ipairs(world:GetDescendants()) do
		if object:IsA("BasePart") and trackedName(object.Name) then
			index += 1
			table.insert(self.Items, {
				Part = object,
				Base = object.CFrame,
				Transparency = object.Transparency,
				Index = index,
			})
		end
	end
end

function WorldMotion:Start()
	self:Collect()
	local lastRefresh = os.clock()
	self.Connection = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if now - lastRefresh > 5 then
			lastRefresh = now
			self:Collect()
		end

		for _, item in ipairs(self.Items) do
			local p = item.Part
			if p and p.Parent then
				local phase = item.Index * 0.73
				if p.Name == "NexusCrystal" then
					p.CFrame = item.Base * CFrame.new(0, math.sin(now * 1.4) * 0.55, 0) * CFrame.Angles(0, now * 0.45, 0)
				elseif string.find(p.Name, "NexusFloatingShard", 1, true) then
					p.CFrame = item.Base * CFrame.new(0, math.sin(now * 1.25 + phase) * 0.65, 0) * CFrame.Angles(now * 0.08, now * 0.22, now * 0.05)
				elseif string.find(p.Name, "NexusCoreRing", 1, true) then
					p.CFrame = item.Base * CFrame.Angles(0, now * (0.12 + (item.Index % 3) * 0.035), 0)
				elseif string.find(p.Name, "PortalCore_", 1, true) then
					p.Transparency = math.clamp(item.Transparency + math.sin(now * 2.5 + phase) * 0.08, 0.30, 0.75)
				elseif string.find(p.Name, "PortalSurface_", 1, true) then
					p.Transparency = math.clamp(item.Transparency + math.sin(now * 1.8 + phase) * 0.04, 0.22, 0.48)
				elseif string.find(p.Name, "EggOrb_", 1, true) then
					p.CFrame = item.Base * CFrame.new(0, math.sin(now * 1.9 + phase) * 0.38, 0) * CFrame.Angles(0, now * 0.28, 0)
				elseif string.find(p.Name, "VoidMonolith", 1, true) then
					p.CFrame = item.Base * CFrame.new(0, math.sin(now * 0.65 + phase) * 0.55, 0) * CFrame.Angles(0, now * 0.025, 0)
				end
			end
		end
	end)
end

function WorldMotion:Destroy()
	if self.Connection then self.Connection:Disconnect() end
	self.Connection = nil
end

return WorldMotion
