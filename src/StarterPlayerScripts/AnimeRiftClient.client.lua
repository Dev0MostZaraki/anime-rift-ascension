local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local Config = require(AnimeRift:WaitForChild("Config"))
local Version = require(AnimeRift:WaitForChild("Version"))
local FighterConfig = require(AnimeRift:WaitForChild("FighterConfig"))
local Hud = require(AnimeRift:WaitForChild("Client"):WaitForChild("Hud"))
local PetUI = require(AnimeRift:WaitForChild("Client"):WaitForChild("PetUI"))
local FighterUI = require(AnimeRift:WaitForChild("Client"):WaitForChild("FighterUI"))
local CombatUI = require(AnimeRift:WaitForChild("Client"):WaitForChild("CombatUI"))
local ArsenalUI = require(AnimeRift:WaitForChild("Client"):WaitForChild("ArsenalUI"))
local RelicUI = require(AnimeRift:WaitForChild("Client"):WaitForChild("RelicUI"))
local DevUI = require(AnimeRift:WaitForChild("Client"):WaitForChild("DevUI"))
local VisualFX = require(AnimeRift:WaitForChild("Client"):WaitForChild("VisualFX"))
local WorldMotion = require(AnimeRift:WaitForChild("Client"):WaitForChild("WorldMotion"))
local MovementUI = require(AnimeRift:WaitForChild("Client"):WaitForChild("MovementUI"))
local DialogUI = require(AnimeRift:WaitForChild("Client"):WaitForChild("DialogUI"))

local remotes = AnimeRift:WaitForChild("Remotes", 15)
if not remotes then warn("Anime Rift remotes were not created. Check ServerScriptService output.") return end

local stats = player:WaitForChild("leaderstats", 15)
local profile = player:WaitForChild("RiftProfile", 15)
local petInventory = player:WaitForChild("PetInventory", 15)
local relicInventory = player:WaitForChild("RelicInventory", 15)
local fighterInventory = player:WaitForChild("FighterInventory", 15)
local fighterProfile = profile and profile:WaitForChild("Fighters", 15)
if not stats or not profile or not petInventory or not relicInventory or not fighterInventory or not fighterProfile then
	warn("Anime Rift client could not find server-created player data.")
	return
end

task.spawn(function()
	for _ = 1, 8 do
		local ok = pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
		if ok then break end
		task.wait(0.5)
	end
end)

local hud = Hud.new(player, stats, profile, Config)
local visualFX = VisualFX.new(hud.Gui)
local worldMotion = WorldMotion.new()
worldMotion:Start()
PetUI.new(hud.Gui, petInventory, Config, remotes:WaitForChild("EquipPet"))
FighterUI.new(hud.Gui, player, fighterInventory, fighterProfile, FighterConfig, remotes:WaitForChild("FighterAction"))
ArsenalUI.new(hud.Gui, player, profile, stats, Config, remotes:WaitForChild("StyleAction"))
RelicUI.new(hud.Gui, relicInventory, Config, remotes:WaitForChild("EquipRelic"))
MovementUI.new(hud.Gui, Config, remotes:WaitForChild("Movement"))
DialogUI.new(hud.Gui, remotes:WaitForChild("Dialog"))

local devUI
local function ensureDevUI()
	if devUI or player:GetAttribute("AnimeRiftDev") ~= true then return end
	devUI = DevUI.new(hud.Gui, player, remotes:WaitForChild("DevCommand"))
end
ensureDevUI()
player:GetAttributeChangedSignal("AnimeRiftDev"):Connect(ensureDevUI)

local combatUI
combatUI = CombatUI.new(hud.Gui, Config, function(name)
	visualFX:Ability(name)
	remotes.Ability:FireServer(name)
end)

local function refreshStyle()
	local style = Config.Styles[profile.EquippedStyle.Value] or Config.Styles.RiftBlade
	combatUI:SetStyle(style)
end
refreshStyle()
profile.EquippedStyle.Changed:Connect(refreshStyle)

local zoneBanner = Instance.new("Frame")
zoneBanner.Name = "ZoneBanner"
zoneBanner.AnchorPoint = Vector2.new(0.5, 0.5)
zoneBanner.Position = UDim2.new(0.5, 0, 0.34, 0)
zoneBanner.Size = UDim2.new(0, 520, 0, 72)
zoneBanner.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
zoneBanner.BackgroundTransparency = 1
zoneBanner.BorderSizePixel = 0
zoneBanner.Visible = false
zoneBanner.Parent = hud.Gui
local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 12)
bannerCorner.Parent = zoneBanner
local bannerStroke = Instance.new("UIStroke")
bannerStroke.Transparency = 1
bannerStroke.Thickness = 1
bannerStroke.Parent = zoneBanner

local zoneKicker = Instance.new("TextLabel")
zoneKicker.Size = UDim2.new(1, 0, 0, 18)
zoneKicker.Position = UDim2.new(0, 0, 0, 8)
zoneKicker.BackgroundTransparency = 1
zoneKicker.Text = "RIFT ATTUNEMENT"
zoneKicker.TextColor3 = Color3.fromRGB(174, 178, 195)
zoneKicker.TextTransparency = 1
zoneKicker.TextSize = 10
zoneKicker.Font = Enum.Font.GothamBold
zoneKicker.Parent = zoneBanner

local zoneTitle = Instance.new("TextLabel")
zoneTitle.Size = UDim2.new(1, 0, 0, 38)
zoneTitle.Position = UDim2.new(0, 0, 0, 25)
zoneTitle.BackgroundTransparency = 1
zoneTitle.TextTransparency = 1
zoneTitle.TextScaled = true
zoneTitle.Font = Enum.Font.GothamBlack
zoneTitle.Parent = zoneBanner

local zoneToken = 0
local function showZone(name, color)
	zoneToken += 1
	local token = zoneToken
	local tint = color or Color3.fromRGB(230, 220, 255)
	visualFX:Zone(tint)
	zoneTitle.Text = string.upper(tostring(name))
	zoneTitle.TextColor3 = tint
	bannerStroke.Color = tint
	zoneTitle.TextTransparency = 1
	zoneKicker.TextTransparency = 1
	zoneBanner.BackgroundTransparency = 1
	bannerStroke.Transparency = 1
	zoneBanner.Visible = true
	zoneBanner.Position = UDim2.new(0.5, 0, 0.36, 0)
	TweenService:Create(zoneBanner, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.22, Position = UDim2.new(0.5, 0, 0.34, 0)}):Play()
	TweenService:Create(zoneTitle, TweenInfo.new(0.22), {TextTransparency = 0}):Play()
	TweenService:Create(zoneKicker, TweenInfo.new(0.22), {TextTransparency = 0.18}):Play()
	TweenService:Create(bannerStroke, TweenInfo.new(0.22), {Transparency = 0.42}):Play()
	task.delay(1.55, function()
		if token ~= zoneToken then return end
		local tween = TweenService:Create(zoneBanner, TweenInfo.new(0.30), {BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.32, 0)})
		TweenService:Create(zoneTitle, TweenInfo.new(0.30), {TextTransparency = 1}):Play()
		TweenService:Create(zoneKicker, TweenInfo.new(0.30), {TextTransparency = 1}):Play()
		TweenService:Create(bannerStroke, TweenInfo.new(0.30), {Transparency = 1}):Play()
		tween:Play(); tween.Completed:Wait()
		if token == zoneToken then zoneBanner.Visible = false end
	end)
end

remotes.Notify.OnClientEvent:Connect(function(text, kind) hud:Notify(text, kind) end)
remotes.WorldEvent.OnClientEvent:Connect(function(eventName, duration)
	if eventName == "RIFT SURGE" then hud:ShowRiftSurge(duration) end
end)
remotes.ZoneEntered.OnClientEvent:Connect(showZone)
remotes.CombatFeedback.OnClientEvent:Connect(function(kind, value)
	if kind == "Combo" then
		local stage = tonumber(value) or 1
		combatUI:ShowCombo(stage)
		visualFX:Combo(stage)
	elseif kind == "ResetCooldowns" then
		combatUI:ResetCooldowns()
	end
end)

local wired = setmetatable({}, {__mode = "k"})
local function wireTool(tool)
	if not tool:IsA("Tool") or tool:GetAttribute("AnimeRiftWeapon") ~= true or wired[tool] then return end
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

print("[Anime Rift Ascension] client started - " .. Version.Version)
