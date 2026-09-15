local ProgressionConfig = {}

ProgressionConfig.EffectivePlaytime = {
	TickSeconds = 1,
	ActiveGraceSeconds = 12,
	MinimumMovementStuds = 3.5,
	-- Sprint is 27 studs/s and a valid dash is ~17 studs. 60 leaves jitter room
	-- without giving teleport/sweep scripts a 95+ studs/s allowance.
	MaximumPlausibleMovementStudsPerSample = 60,
	DailyRewards = {
		{Seconds = 15 * 60, Coins = 750, Gems = 0, RiftTickets = 0},
		{Seconds = 30 * 60, Coins = 1500, Gems = 3, RiftTickets = 0},
		{Seconds = 60 * 60, Coins = 2500, Gems = 5, RiftTickets = 1},
		{Seconds = 120 * 60, Coins = 5000, Gems = 10, RiftTickets = 1},
		{Seconds = 180 * 60, Coins = 8000, Gems = 15, RiftTickets = 2},
	},
}

ProgressionConfig.Resonance = {
	SecondsToCap = 120 * 60,
	MaxLuckBonus = 0.30,
}

ProgressionConfig.Mutations = {
	{Id = "Normal", Weight = 990000, Rank = 0, PowerMultiplier = 1.00},
	{Id = "Shiny", Weight = 8500, Rank = 1, PowerMultiplier = 1.05},
	{Id = "Corrupted", Weight = 1200, Rank = 2, PowerMultiplier = 1.10},
	{Id = "Awakened", Weight = 250, Rank = 3, PowerMultiplier = 1.18},
	{Id = "Void", Weight = 45, Rank = 4, PowerMultiplier = 1.28},
	{Id = "Divine", Weight = 5, Rank = 5, PowerMultiplier = 1.40},
}

ProgressionConfig.WildEgg = {
	FirstSpawnMinSeconds = 75,
	FirstSpawnMaxSeconds = 150,
	RespawnMinSeconds = 12 * 60,
	RespawnMaxSeconds = 40 * 60,
	LifetimeMinSeconds = 6 * 60,
	LifetimeMaxSeconds = 14 * 60,
	RevealRadius = 60,
	ClaimRadius = 12,
	MinimumRevealDwellSeconds = 1.5,
	RequiredSessionEffectiveSeconds = 5 * 60,
	ScanIntervalSeconds = 0.5,
	SpawnAttempts = 50,
	MinimumSlopeNormalY = 0.78,
	MinimumRadiusFromZoneCenter = 42,
	MaximumRadiusFromZoneCenter = 122,
	TeleportSuspicionSeconds = 5,
	Tiers = {
		{Id = "White", Weight = 5200, Color = Color3.fromRGB(235, 238, 245), BroadcastClaim = false, Pets = {
			{Name = "Rift Bunny", Weight = 70, Role = "Utility", Bonus = 0.12},
			{Name = "Cloud Pup", Weight = 25, Role = "Farming", Bonus = 0.16},
			{Name = "Moon Sprite", Weight = 5, Role = "Luck", Bonus = 0.20, LuckBonus = 0.02},
		}},
		{Id = "Emerald", Weight = 2600, Color = Color3.fromRGB(76, 220, 128), BroadcastClaim = false, Pets = {
			{Name = "Emerald Kitsune", Weight = 68, Role = "Farming", Bonus = 0.24, DropBonus = 0.03},
			{Name = "Bamboo Guardian", Weight = 27, Role = "Combat", Bonus = 0.30},
			{Name = "Lucky Tanuki", Weight = 5, Role = "Luck", Bonus = 0.26, LuckBonus = 0.035},
		}},
		{Id = "Azure", Weight = 1350, Color = Color3.fromRGB(80, 165, 255), BroadcastClaim = false, Pets = {
			{Name = "Azure Kirin", Weight = 66, Role = "Combat", Bonus = 0.38},
			{Name = "Tide Familiar", Weight = 28, Role = "Utility", Bonus = 0.32},
			{Name = "Starfin Spirit", Weight = 6, Role = "Luck", Bonus = 0.34, LuckBonus = 0.05},
		}},
		{Id = "Arcane", Weight = 600, Color = Color3.fromRGB(184, 95, 255), BroadcastClaim = false, Pets = {
			{Name = "Arcane Wolf", Weight = 65, Role = "Combat", Bonus = 0.52},
			{Name = "Spirit Fox", Weight = 25, Role = "Luck", Bonus = 0.46, LuckBonus = 0.06},
			{Name = "Astral Dragon", Weight = 9, Role = "Combat", Bonus = 0.72},
			{Name = "Veiled Familiar", Weight = 1, Role = "Luck", Bonus = 0.68, LuckBonus = 0.085},
		}},
		{Id = "Crimson", Weight = 190, Color = Color3.fromRGB(255, 78, 90), BroadcastClaim = false, Pets = {
			{Name = "Crimson Oni", Weight = 68, Role = "Combat", Bonus = 0.82},
			{Name = "Bloodmoon Raven", Weight = 27, Role = "Combat", Bonus = 0.94},
			{Name = "Scarlet Sovereign", Weight = 5, Role = "Combat", Bonus = 1.14},
		}},
		{Id = "Golden", Weight = 50, Color = Color3.fromRGB(255, 211, 72), BroadcastClaim = true, Pets = {
			{Name = "Golden Qilin", Weight = 75, Role = "Farming", Bonus = 1.05, DropBonus = 0.08},
			{Name = "Sun Crown Familiar", Weight = 22, Role = "Luck", Bonus = 1.00, LuckBonus = 0.10},
			{Name = "Dawn Emperor", Weight = 3, Role = "Combat", Bonus = 1.38},
		}},
		{Id = "Prismatic", Weight = 9, Color = Color3.fromRGB(255, 115, 235), BroadcastClaim = true, Pets = {
			{Name = "Prismatic Seraph", Weight = 82, Role = "Luck", Bonus = 1.35, LuckBonus = 0.14},
			{Name = "Spectrum Dragon", Weight = 17, Role = "Combat", Bonus = 1.62},
			{Name = "Mirage Zero", Weight = 1, Role = "Luck", Bonus = 1.55, LuckBonus = 0.19},
		}},
		{Id = "Void", Weight = 1, Color = Color3.fromRGB(90, 67, 126), BroadcastClaim = true, Pets = {
			{Name = "Voidborn Eclipse", Weight = 90, Role = "Combat", Bonus = 2.00},
			{Name = "Nameless Riftling", Weight = 10, Role = "Luck", Bonus = 1.90, LuckBonus = 0.24},
		}},
	},
}

return ProgressionConfig
