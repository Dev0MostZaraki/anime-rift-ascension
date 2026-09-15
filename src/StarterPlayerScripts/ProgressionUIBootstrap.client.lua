local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local clientFolder = AnimeRift:WaitForChild("Client")
local ProgressionUI = require(clientFolder:WaitForChild("ProgressionUI"))

ProgressionUI.new(player)
