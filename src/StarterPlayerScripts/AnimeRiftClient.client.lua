local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local Config = require(AnimeRift:WaitForChild("Config"))
local Hud = require(AnimeRift:WaitForChild("Client"):WaitForChild("Hud"))
local PetUI = require(AnimeRift:WaitForChild("Client"):WaitForChild("PetUI"))

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

local hud = Hud.new(player, stats, profile, Config)
PetUI.new(hud.Gui, inventory, Config, remotes:WaitForChild("EquipPet"))

remotes.Notify.OnClientEvent:Connect(function(text, kind)
	hud:Notify(text, kind)
end)

remotes.WorldEvent.OnClientEvent:Connect(function(eventName, duration)
	if eventName == "RIFT SURGE" then
		hud:ShowRiftSurge(duration)
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
for _, tool in ipairs(backpack:GetChildren()) do
	wireTool(tool)
end
backpack.ChildAdded:Connect(wireTool)

local function hookCharacter(character)
	for _, tool in ipairs(character:GetChildren()) do
		wireTool(tool)
	end
	character.ChildAdded:Connect(wireTool)
end

if player.Character then
	hookCharacter(player.Character)
end
player.CharacterAdded:Connect(hookCharacter)

print("[Anime Rift Ascension] client started - " .. Config.Game.Version)
