local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimeRift = ReplicatedStorage:WaitForChild("AnimeRift")
local Config = require(AnimeRift:WaitForChild("Config"))
local Version = require(AnimeRift:WaitForChild("Version"))

local existingRemotes = AnimeRift:FindFirstChild("Remotes")
if existingRemotes then existingRemotes:Destroy() end

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
		Ability = makeRemote("Ability"),
		CombatFeedback = makeRemote("CombatFeedback"),
		EquipPet = makeRemote("EquipPet"),
		EquipRelic = makeRemote("EquipRelic"),
		StyleAction = makeRemote("StyleAction"),
		DevCommand = makeRemote("DevCommand"),
		Notify = makeRemote("Notify"),
		WorldEvent = makeRemote("WorldEvent"),
		ZoneEntered = makeRemote("ZoneEntered"),
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
local StatsService = require(Modules:WaitForChild("StatsService"))
local QuestService = require(Modules:WaitForChild("QuestService"))
local PetService = require(Modules:WaitForChild("PetService"))
local ArsenalService = require(Modules:WaitForChild("ArsenalService"))
local LootService = require(Modules:WaitForChild("LootService"))
local WorldService = require(Modules:WaitForChild("WorldService"))
local WorldDecorService = require(Modules:WaitForChild("WorldDecorService"))
local OpenWorldSliceService = require(Modules:WaitForChild("OpenWorldSliceService"))
local CombatService = require(Modules:WaitForChild("CombatService"))
local EnemyVisualService = require(Modules:WaitForChild("EnemyVisualService"))
local DashService = require(Modules:WaitForChild("DashService"))
local EventService = require(Modules:WaitForChild("EventService"))
local DevService = require(Modules:WaitForChild("DevService"))
local PlayerService = require(Modules:WaitForChild("PlayerService"))

Context.Services.DataService = DataService.new(Context)
Context.Services.StatsService = StatsService.new(Context)
Context.Services.QuestService = QuestService.new(Context)
Context.Services.PetService = PetService.new(Context)
Context.Services.ArsenalService = ArsenalService.new(Context)
Context.Services.LootService = LootService.new(Context)
Context.Services.WorldService = WorldService.new(Context)
Context.Services.WorldDecorService = WorldDecorService.new(Context)
Context.Services.OpenWorldSliceService = OpenWorldSliceService.new(Context)
Context.Services.CombatService = CombatService.new(Context)
Context.Services.EnemyVisualService = EnemyVisualService.new(Context)
Context.Services.DashService = DashService.new(Context)
Context.Services.EventService = EventService.new(Context)
Context.Services.DevService = DevService.new(Context)
Context.Services.PlayerService = PlayerService.new(Context)

-- Keep CombatService server authoritative while 4.1 moves enemy placement out of arena circles.
-- The existing combat module still creates the model; this wrapper relocates the newly-created
-- model to hand-authored world POIs and applies current boss balance from Config.
do
	local combat = Context.Services.CombatService
	local slice = Context.Services.OpenWorldSliceService
	local rawAddEnemy = combat.AddEnemy
	function combat:AddEnemy(zone, index, boss)
		local before = {}
		for model in pairs(self.Enemies) do before[model] = true end
		rawAddEnemy(self, zone, index, boss)
		for model, data in pairs(self.Enemies) do
			if not before[model] and model.Parent and model.PrimaryPart then
				local spawn = slice:GetEnemySpawn(zone.Id, index, boss)
				if spawn then
					data.Spawn = spawn
					model:PivotTo(CFrame.new(spawn))
				end
				if boss then
					data.HP = Config.Game.BossHP or data.HP
					data.MaxHP = Config.Game.BossHP or data.MaxHP
					data.Damage = Config.Game.BossDamage or data.Damage
				end
				self:UpdateLabel(model)
				break
			end
		end
	end
end

Context.Services.WorldService:Start()
Context.Services.WorldDecorService:Start()
Context.Services.OpenWorldSliceService:Start()
Context.Services.StatsService:Start()
Context.Services.PetService:Start()
Context.Services.ArsenalService:Start()
Context.Services.LootService:Start()
Context.Services.CombatService:Start()
Context.Services.EnemyVisualService:Start()
Context.Services.DashService:Start()
Context.Services.EventService:Start()
Context.Services.DevService:Start()
Context.Services.PlayerService:Start()

print(string.format("[%s] server started • %s", Config.Game.Name, Config.Game.Version))
