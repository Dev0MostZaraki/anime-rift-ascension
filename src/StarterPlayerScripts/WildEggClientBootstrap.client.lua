local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local remotes = AnimeRift:WaitForChild("Remotes", 15)
if not remotes then
	warn("[Wild Egg] remotes unavailable")
	return
end

local clientFolder = AnimeRift:WaitForChild("Client")
local WildEggClient = require(clientFolder:WaitForChild("WildEggClient"))
WildEggClient.new(remotes:WaitForChild("WildEgg"))
