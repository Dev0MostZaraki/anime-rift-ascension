local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Version = require(ReplicatedStorage:WaitForChild("AnimeRift"):WaitForChild("Version"))

print(string.format("[%s] server sync active - %s", Version.Name, Version.Version))

local marker = workspace:FindFirstChild("AnimeRiftRojoConnected")
if not marker then
    marker = Instance.new("Folder")
    marker.Name = "AnimeRiftRojoConnected"
    marker.Parent = workspace
end

marker:SetAttribute("Version", Version.Version)
marker:SetAttribute("Source", "GitHub + Rojo")
