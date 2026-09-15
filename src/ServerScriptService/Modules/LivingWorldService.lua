local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local HuntConfig = require(AnimeRift:WaitForChild("HuntConfig"))

local LivingWorldService = {}
LivingWorldService.__index = LivingWorldService

function LivingWorldService.new(context)
	return setmetatable({Context = context, Config = HuntConfig}, LivingWorldService)
end

local function part(parent, name, size, cf, color, material)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = cf
	object.Anchored = true
	object.CanCollide = name == "Body"
	object.CanTouch = false
	object.CanQuery = true
	object.Material = material or Enum.Material.SmoothPlastic
	object.Color = color
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function nameplate(head, name, title, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NPCName"
	gui.Size = UDim2.new(0, 230, 0, 54)
	gui.StudsOffset = Vector3.new(0, 3.6, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 48
	gui.LightInfluence = 0
	gui.Parent = head

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = name .. "\n" .. string.upper(title)
	text.TextColor3 = Color3.fromRGB(245, 240, 226)
	text.TextStrokeTransparency = 0.68
	text.TextSize = 15
	text.TextWrapped = true
	text.Font = Enum.Font.GothamBold
	text.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = 0.42
	stroke.Thickness = 1
	stroke.Parent = text
end

function LivingWorldService:FindRare(zoneId)
	local combat = self.Context.Services.CombatService
	if not combat then return nil end
	for _, data in pairs(combat.Enemies) do
		if data.Alive and data.Rare and data.Zone and data.Zone.Id == zoneId then
			return data
		end
	end
	return nil
end

function LivingWorldService:GetDialogue(player, npc)
	local lines = {}
	for _, line in ipairs(npc.Intro or {}) do table.insert(lines, line) end

	if npc.ZoneId and npc.ZoneId > 0 then
		local core = self.Context.Services.CoreLoopService
		local state = core and core:GetQuestState(player, npc.ZoneId)
		if state and state.Step then
			table.insert(lines, "Current request: " .. state.Step.Title .. " — " .. state.Step.Description)
			table.insert(lines, string.format("Progress %d/%d. Reward: %d Coins%s.", state.Progress, state.Step.Target, state.Step.Coins or 0, (state.Step.Gems or 0) > 0 and (" + " .. state.Step.Gems .. " Gems") or ""))
		elseif state then
			table.insert(lines, "You've done everything I can ask of you here. The region knows your name now.")
		end

		local rare = self:FindRare(npc.ZoneId)
		if rare then
			table.insert(lines, "One more thing — " .. rare.Name .. " is somewhere nearby. Named threats carry better loot than ordinary patrols.")
		end
	else
		table.insert(lines, "Regional wardens now track local threats, rare hunts and your current objectives. Talk to them when you enter a new land.")
	end

	return {
		Id = npc.Id,
		Speaker = npc.Name,
		Title = npc.Title,
		Color = npc.Color,
		Lines = lines,
	}
end

function LivingWorldService:BuildNPC(folder, npc)
	local model = Instance.new("Model")
	model.Name = "NPC_" .. npc.Id
	model:SetAttribute("AnimeRiftNPC", true)
	model:SetAttribute("NPCId", npc.Id)
	model.Parent = folder

	local pos = npc.Position
	local body = part(model, "Body", Vector3.new(3.4, 5.2, 2.4), CFrame.new(pos), npc.Color:Lerp(Color3.fromRGB(64, 61, 57), 0.30), Enum.Material.Fabric)
	local head = part(model, "Head", Vector3.new(2.7, 2.7, 2.7), CFrame.new(pos + Vector3.new(0, 3.9, 0)), Color3.fromRGB(218, 194, 173), Enum.Material.SmoothPlastic)
	head.Shape = Enum.PartType.Ball
	part(model, "Mantle", Vector3.new(4.1, 0.65, 2.9), CFrame.new(pos + Vector3.new(0, 2.0, 0)), npc.Color, Enum.Material.Fabric)
	local staff = part(model, "Staff", Vector3.new(0.35, 6.5, 0.35), CFrame.new(pos + Vector3.new(2.4, 0.2, 0)), Color3.fromRGB(86, 66, 44), Enum.Material.Wood)
	staff.CanCollide = false
	model.PrimaryPart = body
	nameplate(head, npc.Name, npc.Title, npc.Color)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Talk"
	prompt.ObjectText = npc.Name
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(function(player)
		self.Context.Remotes.Dialog:FireClient(player, self:GetDialogue(player, npc))
	end)
end

function LivingWorldService:Start()
	local old = self.Context.WorldFolder:FindFirstChild("LivingWorld")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "LivingWorld"
	folder.Parent = self.Context.WorldFolder
	for _, npc in ipairs(self.Config.NPCs) do self:BuildNPC(folder, npc) end
	print("[Living World] " .. #self.Config.NPCs .. " regional NPCs active")
end

return LivingWorldService
