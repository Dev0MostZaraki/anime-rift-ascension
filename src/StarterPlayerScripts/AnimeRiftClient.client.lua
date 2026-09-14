local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local Config = require(AnimeRift:WaitForChild("Config"))
local Hud = require(AnimeRift:WaitForChild("Client"):WaitForChild("Hud"))
local PetUI = require(AnimeRift:WaitForChild("Client"):WaitForChild("PetUI"))
local CombatUI = require(AnimeRift:WaitForChild("Client"):WaitForChild("CombatUI"))

local remotes = AnimeRift:WaitForChild("Remotes", 15)
if not remotes then
	warn("Anime Rift remotes were not created. Check ServerScriptService output.")
	return
end

local stats = player:WaitForChild("leaderstats", 15)
local profile = player:WaitForChild("RiftProfile", 15)
local inventory = player:WaitForChild("PetInventory", 15)
if not stats or not profile or not inventory then
	warn("Anime Rift client could not find server-created player data.")
	return
end

-- The blade is auto-equipped, so Roblox's default backpack only collides with our combat HUD.
task.spawn(function()
	for _ = 1, 8 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if ok then break end
		task.wait(0.5)
	end
end)

local hud = Hud.new(player, stats, profile, Config)
PetUI.new(hud.Gui, inventory, Config, remotes:WaitForChild("EquipPet"))

local combatUI
combatUI = CombatUI.new(hud.Gui, Config, function(name)
	remotes.Ability:FireServer(name)
end)

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
	zoneBanner.TextColor3 = color or Color3.fromRGB(230, 220, 255)
	zoneBanner.TextTransparency = 1
	zoneBanner.TextStrokeTransparency = 1
	zoneBanner.Visible = true
	TweenService:Create(zoneBanner, TweenInfo.new(0.22), {TextTransparency = 0, TextStrokeTransparency = 0.35}):Play()
	task.delay(1.6, function()
		if token ~= zoneToken then return end
		local tween = TweenService:Create(zoneBanner, TweenInfo.new(0.35), {TextTransparency = 1, TextStrokeTransparency = 1})
		tween:Play()
		tween.Completed:Wait()
		if token == zoneToken then zoneBanner.Visible = false end
	end)
end

remotes.Notify.OnClientEvent:Connect(function(text, kind)
	hud:Notify(text, kind)
end)

remotes.WorldEvent.OnClientEvent:Connect(function(eventName, duration)
	if eventName == "RIFT SURGE" then hud:ShowRiftSurge(duration) end
end)

remotes.ZoneEntered.OnClientEvent:Connect(showZone)
remotes.CombatFeedback.OnClientEvent:Connect(function(kind, value)
	if kind == "Combo" then
		combatUI:ShowCombo(tonumber(value) or 1)
	end
end)

local wired = setmetatable({}, {__mode = "k"})
local function wireTool(tool)
	if not tool:IsA("Tool") or tool.Name ~= "Rift Blade" or wired[tool] then return end
	wired[tool] = true
	tool.Activated:Connect(function()
		remotes.Attack:FireServer()
	end)
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

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		combatUI:TryUse("Dash")
	elseif input.KeyCode == Enum.KeyCode.E then
		combatUI:TryUse("Burst")
	elseif input.KeyCode == Enum.KeyCode.R then
		combatUI:TryUse("Nova")
	end
end)

print("[Anime Rift Ascension] client started - " .. Config.Game.Version)
