local Workspace = game:GetService("Workspace")

local WildEggClient = {}
WildEggClient.__index = WildEggClient

function WildEggClient.new(remote)
	local self = setmetatable({
		Remote = remote,
		Model = nil,
		EggId = nil,
	}, WildEggClient)
	self:Start()
	return self
end

function WildEggClient:Clear(eggId)
	if eggId and self.EggId and eggId ~= self.EggId then return end
	if self.Model and self.Model.Parent then self.Model:Destroy() end
	self.Model = nil
	self.EggId = nil
end

function WildEggClient:Reveal(payload)
	if type(payload) ~= "table" or typeof(payload.Position) ~= "Vector3" or type(payload.EggId) ~= "string" then return end
	self:Clear()

	local model = Instance.new("Model")
	model.Name = "DiscoveredWildEgg"
	model:SetAttribute("LocalOnly", true)
	model.Parent = Workspace

	local shell = Instance.new("Part")
	shell.Name = "Egg"
	shell.Shape = Enum.PartType.Ball
	shell.Size = Vector3.new(5.4, 7.2, 5.4)
	shell.CFrame = CFrame.new(payload.Position)
	shell.Anchored = true
	shell.CanCollide = false
	shell.CanTouch = false
	shell.CanQuery = false
	shell.Material = Enum.Material.Glass
	shell.Transparency = 0.10
	shell.Color = typeof(payload.Color) == "Color3" and payload.Color or Color3.fromRGB(235, 238, 245)
	shell.Parent = model
	model.PrimaryPart = shell

	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(2.6, 3.6, 2.6)
	core.CFrame = shell.CFrame
	core.Anchored = true
	core.CanCollide = false
	core.CanTouch = false
	core.CanQuery = false
	core.Material = Enum.Material.Neon
	core.Transparency = 0.22
	core.Color = shell.Color:Lerp(Color3.new(1, 1, 1), 0.28)
	core.Parent = model

	local light = Instance.new("PointLight")
	light.Color = shell.Color
	light.Brightness = 1.35
	light.Range = 18
	light.Shadows = false
	light.Parent = core

	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = shell.Color
	sparkles.Parent = shell

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Hatch"
	prompt.ObjectText = tostring(payload.Tier or "Unknown") .. " Wild Egg"
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.8
	prompt.RequiresLineOfSight = true
	prompt.Parent = shell
	prompt.Triggered:Connect(function()
		if self.EggId == payload.EggId then
			self.Remote:FireServer("Claim", {EggId = payload.EggId})
		end
	end)

	self.Model = model
	self.EggId = payload.EggId
end

function WildEggClient:Start()
	self.Remote.OnClientEvent:Connect(function(action, payload)
		if action == "Reveal" then
			self:Reveal(payload)
		elseif action == "Hide" then
			self:Clear(type(payload) == "table" and payload.EggId or nil)
		end
	end)
end

return WildEggClient
