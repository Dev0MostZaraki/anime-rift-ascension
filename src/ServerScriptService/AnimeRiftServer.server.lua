local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local Config = require(AnimeRift:WaitForChild("Config"))
local Version = require(AnimeRift:WaitForChild("Version"))

local existingRemotes = AnimeRift:FindFirstChild("Remotes")
if existingRemotes then
	existingRemotes:Destroy()
end

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = AnimeRift

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	return remote
end

local Context = {
	Config = Config,
	Version = Version,
	WorldFolder = nil,
	RewardMultiplier = 1,
	Remotes = {
		Attack = makeRemote("Attack"),
		EquipPet = makeRemote("EquipPet"),
		Notify = makeRemote("Notify"),
		WorldEvent = makeRemote("WorldEvent"),
	},
	Services = {},
}

function Context:Notify(player, text, kind)
	self.Remotes.Notify:FireClient(player, text, kind or "info")
end

function Context:NotifyAll(text, kind)
	self.Remotes.Notify:FireAllClients(text, kind or "event")
end

local Modules = script.Parent:WaitForChild("Modules")
local DataService = require(Modules:WaitForChild("DataService"))
local QuestService = require(Modules:WaitForChild("QuestService"))
local PetService = require(Modules:WaitForChild("PetService"))
local WorldService = require(Modules:WaitForChild("WorldService"))
local CombatService = require(Modules:WaitForChild("CombatService"))
local EventService = require(Modules:WaitForChild("EventService"))
local PlayerService = require(Modules:WaitForChild("PlayerService"))

Context.Services.DataService = DataService.new(Context)
Context.Services.QuestService = QuestService.new(Context)
Context.Services.PetService = PetService.new(Context)
Context.Services.WorldService = WorldService.new(Context)
Context.Services.CombatService = CombatService.new(Context)
Context.Services.EventService = EventService.new(Context)
Context.Services.PlayerService = PlayerService.new(Context)

-- The world must exist before enemies, followers, events and players are started.
Context.Services.WorldService:Start()
Context.Services.PetService:Start()
Context.Services.CombatService:Start()
Context.Services.EventService:Start()
Context.Services.PlayerService:Start()

print(string.format("[%s] server started • %s", Config.Game.Name, Config.Game.Version))
