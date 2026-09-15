local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local CoreLoopConfig = require(AnimeRift:WaitForChild("CoreLoopConfig"))
local RegionalQuestUI = require(AnimeRift:WaitForChild("Client"):WaitForChild("RegionalQuestUI"))

local profile = player:WaitForChild("RiftProfile", 15)
local playerGui = player:WaitForChild("PlayerGui", 15)
if not profile or not playerGui then return end

local hud = playerGui:WaitForChild("AnimeRiftHUD", 15)
if not hud then
	warn("Regional quest UI could not find AnimeRiftHUD.")
	return
end

RegionalQuestUI.new(hud, player, profile, CoreLoopConfig)
