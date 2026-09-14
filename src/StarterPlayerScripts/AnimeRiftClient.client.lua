local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local Config = require(AnimeRift:WaitForChild("Config"))
local Hud = require(AnimeRift:WaitForChild("Client"):WaitForChild("Hud"))
local PetUI = require(AnimeRift:WaitForChild("Client"):WaitForChild("PetUI"))

local remotes = AnimeRift:WaitForChild("Remotes", 15)
if not remotes then warn("Anime Rift remotes were not created. Check ServerScriptService output.") return end

local stats = player:WaitForChild("leaderstats", 15)
local profile = player:WaitForChild("RiftProfile", 15)
local inventory = player:WaitForChild("PetInventory", 15)
if not stats or not profile or not inventory then warn("Anime Rift client could not find server-created player data.") return end

local hud = Hud.new(player, stats, profile, Config)
PetUI.new(hud.Gui, inventory, Config, remotes:WaitForChild("EquipPet"))

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
end

local skillBar = Instance.new("Frame")
skillBar.AnchorPoint = Vector2.new(0.5, 1)
skillBar.Position = UDim2.new(0.5, 0, 1, -18)
skillBar.Size = UDim2.new(0, 360, 0, 52)
skillBar.BackgroundColor3 = Color3.fromRGB(18, 20, 29)
skillBar.BackgroundTransparency = 0.08
skillBar.BorderSizePixel = 0
skillBar.Parent = hud.Gui
corner(skillBar, 12)

local function skillLabel(text, x, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 166, 0, 38)
	label.Position = UDim2.new(0, x, 0, 7)
	label.BackgroundColor3 = color
	label.BackgroundTransparency = 0.12
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = Color3.fromRGB(245,245,250)
	label.TextSize = 14
	label.Font = Enum.Font.GothamBold
	label.Parent = skillBar
	corner(label, 9)
	return label
end

skillLabel("Q  DASH", 8, Color3.fromRGB(50, 115, 165))
skillLabel("E  RIFT BURST", 186, Color3.fromRGB(125, 65, 165))

local zoneBanner = Instance.new("TextLabel")
zoneBanner.AnchorPoint = Vector2.new(0.5, 0.5)
zoneBanner.Position = UDim2.new(0.5, 0, 0.33, 0)
zoneBanner.Size = UDim2.new(0, 520, 0, 72)
zoneBanner.BackgroundTransparency = 1
zoneBanner.TextTransparency = 1
zoneBanner.TextStrokeTransparency = 1
zoneBanner.TextScaled = true
zoneBanner.Font = Enum.Font.GothamBlack
zoneBanner.Visible = false
zoneBanner.Parent = hud.Gui

local zoneToken = 0
local function showZone(name, color)
	zoneToken += 1
	local token = zoneToken
	zoneBanner.Text = tostring(name)
	zoneBanner.TextColor3 = color or Color3.fromRGB(230,220,255)
	zoneBanner.TextTransparency = 1
	zoneBanner.TextStrokeTransparency = 1
	zoneBanner.Visible = true
	TweenService:Create(zoneBanner, TweenInfo.new(0.22), {TextTransparency = 0, TextStrokeTransparency = 0.35}):Play()
	task.delay(1.6, function()
		if token ~= zoneToken then return end
		local tween = TweenService:Create(zoneBanner, TweenInfo.new(0.35), {TextTransparency = 1, TextStrokeTransparency = 1})
		tween:Play(); tween.Completed:Wait()
		if token == zoneToken then zoneBanner.Visible = false end
	end)
end

remotes.Notify.OnClientEvent:Connect(function(text, kind) hud:Notify(text, kind) end)
remotes.WorldEvent.OnClientEvent:Connect(function(eventName, duration)
	if eventName == "RIFT SURGE" then hud:ShowRiftSurge(duration) end
end)
remotes.ZoneEntered.OnClientEvent:Connect(showZone)

local wired = setmetatable({}, {__mode = "k"})
local function wireTool(tool)
	if not tool:IsA("Tool") or tool.Name ~= "Rift Blade" or wired[tool] then return end
	wired[tool] = true
	tool.Activated:Connect(function() remotes.Attack:FireServer() end)
end

local backpack = player:WaitForChild("Backpack")
for _, tool in ipairs(backpack:GetChildren()) do wireTool(tool) end
backpack.ChildAdded:Connect(wireTool)

local function hookCharacter(character)
	for _, tool in ipairs(character:GetChildren()) do wireTool(tool) end
	character.ChildAdded:Connect(wireTool)
end
if player.Character then hookCharacter(player.Character) end
player.CharacterAdded:Connect(hookCharacter)

local localCooldowns = {Dash = 0, Burst = 0}
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	local now = os.clock()
	if input.KeyCode == Enum.KeyCode.Q then
		if now >= localCooldowns.Dash then
			localCooldowns.Dash = now + Config.Game.DashCooldown
			remotes.Ability:FireServer("Dash")
		end
	elseif input.KeyCode == Enum.KeyCode.E then
		if now >= localCooldowns.Burst then
			localCooldowns.Burst = now + Config.Game.BurstCooldown
			remotes.Ability:FireServer("Burst")
		end
	end
end)

print("[Anime Rift Ascension] client started - " .. Config.Game.Version)
