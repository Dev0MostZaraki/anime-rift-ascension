local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Version = require(ReplicatedStorage:WaitForChild("AnimeRift"):WaitForChild("Version"))

print(string.format("[%s] client sync active - %s", Version.Name, Version.Version))
