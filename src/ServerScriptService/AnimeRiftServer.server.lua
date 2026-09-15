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
		Dialog = makeRemote("Dialog"),
		WildEgg = makeRemote("WildEgg"),
		FighterAction = makeRemote("FighterAction"),
		FighterAssist = makeRemote("FighterAssist"),
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
local PetMutationService = require(Modules:WaitForChild("PetMutationService"))
local ArsenalService = require(Modules:WaitForChild("ArsenalService"))
local LootService = require(Modules:WaitForChild("LootService"))
local WorldService = require(Modules:WaitForChild("WorldService"))
local WorldDecorService = require(Modules:WaitForChild("WorldDecorService"))
local OpenWorldSliceService = require(Modules:WaitForChild("OpenWorldSliceService"))
local OpenWorldExpansionService = require(Modules:WaitForChild("OpenWorldExpansionService"))
local EnvironmentAssetService = require(Modules:WaitForChild("EnvironmentAssetService"))
local WorldZoneService = require(Modules:WaitForChild("WorldZoneService"))
local LivingWorldService = require(Modules:WaitForChild("LivingWorldService"))
local CombatService = require(Modules:WaitForChild("CombatService"))
local NavigationService = require(Modules:WaitForChild("NavigationService"))
local EnemyAIService = require(Modules:WaitForChild("EnemyAIService"))
local RareHuntService = require(Modules:WaitForChild("RareHuntService"))
local EnemyVisualService = require(Modules:WaitForChild("EnemyVisualService"))
local DashService = require(Modules:WaitForChild("DashService"))
local MovementService = require(Modules:WaitForChild("MovementService"))
local EventService = require(Modules:WaitForChild("EventService"))
local ActivityService = require(Modules:WaitForChild("ActivityService"))
local WildEggService = require(Modules:WaitForChild("WildEggService"))
local FighterService = require(Modules:WaitForChild("FighterService"))
local FighterAssistService = require(Modules:WaitForChild("FighterAssistService"))
local ResetService = require(Modules:WaitForChild("ResetService"))
local DevService = require(Modules:WaitForChild("DevService"))
local PlayerService = require(Modules:WaitForChild("PlayerService"))

Context.Services.DataService = DataService.new(Context)
Context.Services.StatsService = StatsService.new(Context)
Context.Services.QuestService = QuestService.new(Context)
Context.Services.CoreLoopService = CoreLoopService.new(Context)
Context.Services.AssetIntakeService = AssetIntakeService.new(Context)
Context.Services.CreatureArtService = CreatureArtService.new(Context)
Context.Services.PetService = PetService.new(Context)
Context.Services.PetMutationService = PetMutationService.new(Context)
Context.Services.ArsenalService = ArsenalService.new(Context)
Context.Services.LootService = LootService.new(Context)
Context.Services.WorldService = WorldService.new(Context)
Context.Services.WorldDecorService = WorldDecorService.new(Context)
Context.Services.OpenWorldSliceService = OpenWorldSliceService.new(Context)
Context.Services.OpenWorldExpansionService = OpenWorldExpansionService.new(Context)
Context.Services.EnvironmentAssetService = EnvironmentAssetService.new(Context)
Context.Services.WorldZoneService = WorldZoneService.new(Context)
Context.Services.LivingWorldService = LivingWorldService.new(Context)
Context.Services.CombatService = CombatService.new(Context)
Context.Services.NavigationService = NavigationService.new(Context)
Context.Services.EnemyAIService = EnemyAIService.new(Context)
Context.Services.RareHuntService = RareHuntService.new(Context)
Context.Services.EnemyVisualService = EnemyVisualService.new(Context)
Context.Services.DashService = DashService.new(Context)
Context.Services.MovementService = MovementService.new(Context)
Context.Services.EventService = EventService.new(Context)
Context.Services.ActivityService = ActivityService.new(Context)
Context.Services.WildEggService = WildEggService.new(Context)
Context.Services.FighterService = FighterService.new(Context)
Context.Services.FighterAssistService = FighterAssistService.new(Context)
Context.Services.ResetService = ResetService.new(Context)
Context.Services.DevService = DevService.new(Context)
Context.Services.PlayerService = PlayerService.new(Context)

-- Resolve the persistence backend before players load. If Wally/ProfileStore is not
-- installed yet, DataService deliberately falls back to the untouched v2 store.
Context.Services.DataService:InitializeProfileStore()

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

	-- Hatcheries are peaceful pockets. ZonePlus provides the primary flag while
	-- the original distance test remains as a safe fallback if packages are missing.
	function combat:ClosestPlayer(position, range)
		local bestPlayer, bestRoot, bestDistance = nil, nil, range
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local safe = player:GetAttribute("InHatcherySafeZone") == true or (root and slice:IsSafeZone(root.Position))
			if humanoid and humanoid.Health > 0 and root and not safe then
				local distance = (root.Position - position).Magnitude
				if distance <= bestDistance then
					bestPlayer, bestRoot, bestDistance = player, root, distance
				end
			end
		end
		return bestPlayer, bestRoot, bestDistance
	end
end

-- The world already has legitimate Waystone and hub fast-travel. Mark movement as
-- legitimate only after the server-side world method actually changed position.
do
	local world = Context.Services.WorldService
	local activity = Context.Services.ActivityService
	local rawTryEnterZone = world.TryEnterZone
	function world:TryEnterZone(player, zoneId, stone)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local before = root and root.Position or nil
		local result = rawTryEnterZone(self, player, zoneId, stone)
		root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if before and root and (root.Position - before).Magnitude > 25 then
			activity:MarkLegitimateTeleport(player, 4)
		end
		return result
	end

	local rawTeleportToHub = world.TeleportToHub
	function world:TeleportToHub(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local before = root and root.Position or nil
		local result = rawTeleportToHub(self, player)
		root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if before and root and (root.Position - before).Magnitude > 25 then
			activity:MarkLegitimateTeleport(player, 4)
		end
		return result
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
Context.Services.WorldZoneService:Start()
Context.Services.ActivityService:Start()
Context.Services.CoreLoopService:Start()
Context.Services.NavigationService:Start()
Context.Services.EnemyAIService:Start()
Context.Services.RareHuntService:Start()
Context.Services.LivingWorldService:Start()
Context.Services.CreatureArtService:Start()
Context.Services.StatsService:Start()
Context.Services.PetService:Start()
Context.Services.PetMutationService:Start()
Context.Services.ArsenalService:Start()
Context.Services.LootService:Start()
Context.Services.CombatService:Start()
Context.Services.EnemyVisualService:Start()
Context.Services.DashService:Start()
Context.Services.MovementService:Start()
Context.Services.EventService:Start()
Context.Services.WildEggService:Start()
Context.Services.FighterService:Start()
Context.Services.FighterAssistService:Start()
Context.Services.ResetService:Start()
Context.Services.DevService:Start()
Context.Services.PlayerService:Start()

print(string.format("[%s] server started • %s", Config.Game.Name, Version.Version))