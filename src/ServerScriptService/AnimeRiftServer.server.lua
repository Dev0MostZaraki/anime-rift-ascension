local Players = game:GetService("Players")
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
		Movement = makeRemote("Movement"),
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
local CoreLoopService = require(Modules:WaitForChild("CoreLoopService"))
local AssetIntakeService = require(Modules:WaitForChild("AssetIntakeService"))
local CreatureArtService = require(Modules:WaitForChild("CreatureArtService"))
local PetService = require(Modules:WaitForChild("PetService"))
local ArsenalService = require(Modules:WaitForChild("ArsenalService"))
local LootService = require(Modules:WaitForChild("LootService"))
local WorldService = require(Modules:WaitForChild("WorldService"))
local WorldDecorService = require(Modules:WaitForChild("WorldDecorService"))
local OpenWorldSliceService = require(Modules:WaitForChild("OpenWorldSliceService"))
local OpenWorldExpansionService = require(Modules:WaitForChild("OpenWorldExpansionService"))
local EnvironmentAssetService = require(Modules:WaitForChild("EnvironmentAssetService"))
local CombatService = require(Modules:WaitForChild("CombatService"))
local EnemyVisualService = require(Modules:WaitForChild("EnemyVisualService"))
local DashService = require(Modules:WaitForChild("DashService"))
local MovementService = require(Modules:WaitForChild("MovementService"))
local EventService = require(Modules:WaitForChild("EventService"))
local DevService = require(Modules:WaitForChild("DevService"))
local PlayerService = require(Modules:WaitForChild("PlayerService"))

Context.Services.DataService = DataService.new(Context)
Context.Services.StatsService = StatsService.new(Context)
Context.Services.QuestService = QuestService.new(Context)
Context.Services.CoreLoopService = CoreLoopService.new(Context)
Context.Services.AssetIntakeService = AssetIntakeService.new(Context)
Context.Services.CreatureArtService = CreatureArtService.new(Context)
Context.Services.PetService = PetService.new(Context)
Context.Services.ArsenalService = ArsenalService.new(Context)
Context.Services.LootService = LootService.new(Context)
Context.Services.WorldService = WorldService.new(Context)
Context.Services.WorldDecorService = WorldDecorService.new(Context)
Context.Services.OpenWorldSliceService = OpenWorldSliceService.new(Context)
Context.Services.OpenWorldExpansionService = OpenWorldExpansionService.new(Context)
Context.Services.EnvironmentAssetService = EnvironmentAssetService.new(Context)
Context.Services.CombatService = CombatService.new(Context)
Context.Services.EnemyVisualService = EnemyVisualService.new(Context)
Context.Services.DashService = DashService.new(Context)
Context.Services.MovementService = MovementService.new(Context)
Context.Services.EventService = EventService.new(Context)
Context.Services.DevService = DevService.new(Context)
Context.Services.PlayerService = PlayerService.new(Context)

-- Combat remains server-authoritative while open-world services own encounter placement.
do
	local combat = Context.Services.CombatService
	local slice = Context.Services.OpenWorldSliceService
	local expansion = Context.Services.OpenWorldExpansionService
	local rawAddEnemy = combat.AddEnemy
	function combat:AddEnemy(zone, index, boss)
		local before = {}
		for model in pairs(self.Enemies) do before[model] = true end
		rawAddEnemy(self, zone, index, boss)
		for model, data in pairs(self.Enemies) do
			if not before[model] and model.Parent and model.PrimaryPart then
				local spawn = expansion:GetEnemySpawn(zone.Id, index, boss) or slice:GetEnemySpawn(zone.Id, index, boss)
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

	-- Hatcheries are peaceful pockets. Normal enemies drop aggro while players hatch.
	function combat:ClosestPlayer(position, range)
		local bestPlayer, bestRoot, bestDistance = nil, nil, range
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and root and not slice:IsSafeZone(root.Position) then
				local distance = (root.Position - position).Magnitude
				if distance <= bestDistance then
					bestPlayer, bestRoot, bestDistance = player, root, distance
				end
			end
		end
		return bestPlayer, bestRoot, bestDistance
	end
end

-- Asset intake starts first so Creator Store art is sanitized before any service can clone it.
Context.Services.AssetIntakeService:Start()
Context.Services.WorldService:Start()
Context.Services.WorldDecorService:Start()

-- Replace the older prototype landmarks while keeping useful ambient decor.
do
	local decor = Context.WorldFolder and Context.WorldFolder:FindFirstChild("Decor")
	if decor then
		local obsolete = {
			ForgeFoundation = true, ForgeTower = true, ForgeMouth = true, LavaFissure = true,
			CitadelTower = true, CitadelWallL = true, CitadelWallR = true, FrozenBanner = true,
			BossStandingStone = true, BossRune = true,
		}
		for _, object in ipairs(decor:GetDescendants()) do
			if obsolete[object.Name] then object:Destroy() end
		end
	end
end

Context.Services.OpenWorldSliceService:Start()
Context.Services.OpenWorldExpansionService:Start()
Context.Services.EnvironmentAssetService:Start()
Context.Services.CoreLoopService:Start()
Context.Services.CreatureArtService:Start()
Context.Services.StatsService:Start()
Context.Services.PetService:Start()
Context.Services.ArsenalService:Start()
Context.Services.LootService:Start()
Context.Services.CombatService:Start()
Context.Services.EnemyVisualService:Start()
Context.Services.DashService:Start()
Context.Services.MovementService:Start()
Context.Services.EventService:Start()
Context.Services.DevService:Start()
Context.Services.PlayerService:Start()

print(string.format("[%s] server started • %s", Config.Game.Name, Version.Version))
