local Config = {}

Config.Game = {
	Name = "Anime Rift Ascension",
	Version = "3.5-visual",

	-- Basic combat
	BaseDamage = 12,
	AttackRange = 16,
	AttackCooldown = 0.42,
	AttackArcDot = 0.08,
	ComboResetSeconds = 1.05,
	ComboMultipliers = {1.0, 1.18, 1.55},
	CritChance = 0.08,
	CritMultiplier = 1.75,

	-- Abilities
	DashCooldown = 2.4,
	DashSpeed = 82,
	DashDistance = 17,
	BurstCooldown = 6.5,
	BurstRange = 20,
	BurstDamageMultiplier = 2.35,
	NovaCooldown = 18,
	NovaRange = 29,
	NovaDamageMultiplier = 5.25,

	-- Enemy AI
	EnemyAggroRange = 40,
	EnemyAttackRange = 6.5,
	EnemyAttackCooldown = 1.25,
	EnemyMoveSpeed = 8.5,
	EnemyLeashRange = 50,
	EnemyBlinkCooldown = 5.0,
	BossMoveSpeed = 6.2,
	BossTelegraphInterval = 7.5,
	BossTelegraphDelay = 1.35,
	BossSlamRange = 18,
	BossSlamDamage = 42,
	EnemyCountPerZone = 7,

	-- Progression
	MaxEquippedPets = 3,
	MaxEquippedRelics = 2,
	RelicDropChance = 0.18,
	BossRelicDrops = 2,
	MasteryPerKill = 3,
	MasteryPerBoss = 30,
	MasteryDamagePerPoint = 0.001,
	MasteryDamageCap = 0.50,
	PlaytimeRewardSeconds = 120,
	PlaytimeRewardCoins = 250,
	AutosaveSeconds = 75,
	EnemyRespawnSeconds = 4,
	BossRespawnSeconds = 70,
}

Config.RarityColors = {
	Common = Color3.fromRGB(185, 190, 200),
	Rare = Color3.fromRGB(72, 155, 255),
	Epic = Color3.fromRGB(172, 80, 255),
	Legendary = Color3.fromRGB(255, 183, 48),
	Mythic = Color3.fromRGB(255, 68, 145),
	WORLD = Color3.fromRGB(255, 228, 92),
}

Config.Styles = {
	RiftBlade = {
		Id = "RiftBlade",
		Name = "Rift Blade",
		Description = "Balanced starter style with stable combo damage.",
		UnlockLevel = 1,
		UnlockCost = 0,
		DamageMultiplier = 1.00,
		AttackCooldown = 0.42,
		Range = 16,
		CritBonus = 0,
		AbilityMultiplier = 1.00,
		StaggerBonus = 0,
		Color = Color3.fromRGB(184, 118, 255),
		Order = 1,
	},
	EmberKatana = {
		Id = "EmberKatana",
		Name = "Ember Katana",
		Description = "Fast slashes with stronger abilities and bonus crit.",
		UnlockLevel = 4,
		UnlockCost = 1200,
		DamageMultiplier = 1.12,
		AttackCooldown = 0.34,
		Range = 17,
		CritBonus = 0.03,
		AbilityMultiplier = 1.12,
		StaggerBonus = 0,
		Color = Color3.fromRGB(255, 105, 48),
		Order = 2,
	},
	FrostGauntlets = {
		Id = "FrostGauntlets",
		Name = "Frost Gauntlets",
		Description = "Heavy close-range hits that stagger enemies longer.",
		UnlockLevel = 8,
		UnlockCost = 5200,
		DamageMultiplier = 1.30,
		AttackCooldown = 0.48,
		Range = 13.5,
		CritBonus = 0.01,
		AbilityMultiplier = 1.20,
		StaggerBonus = 0.35,
		Color = Color3.fromRGB(90, 205, 255),
		Order = 3,
	},
	VoidScythe = {
		Id = "VoidScythe",
		Name = "Void Scythe",
		Description = "Slow, wide attacks with huge damage and crit potential.",
		UnlockLevel = 14,
		UnlockCost = 21000,
		DamageMultiplier = 1.58,
		AttackCooldown = 0.58,
		Range = 21,
		CritBonus = 0.07,
		AbilityMultiplier = 1.34,
		StaggerBonus = 0.15,
		Color = Color3.fromRGB(215, 75, 255),
		Order = 4,
	},
}

Config.RelicRarities = {
	Common = {Weight = 58, Power = 0.05, Crit = 0.000},
	Rare = {Weight = 27, Power = 0.10, Crit = 0.005},
	Epic = {Weight = 10, Power = 0.19, Crit = 0.010},
	Legendary = {Weight = 4, Power = 0.34, Crit = 0.020},
	Mythic = {Weight = 1, Power = 0.58, Crit = 0.035},
}

Config.RelicNames = {
	[1] = {"Verdant Charm", "Dojo Crest", "Spirit Leaf"},
	[2] = {"Ember Core", "Ronin Seal", "Phoenix Ash"},
	[3] = {"Frost Sigil", "Glacier Heart", "Aurora Shard"},
	[4] = {"Void Eye", "Abyss Fragment", "Rift Crown"},
}

Config.Zones = {
	[1] = {
		Id = 1,
		Name = "Verdant Dojo",
		Center = Vector3.new(0, 0, 270),
		Color = Color3.fromRGB(66, 145, 94),
		UnlockLevel = 1,
		UnlockCost = 0,
		EnemyName = "Dojo Rogue",
		Archetype = "Brawler",
		EnemyHP = 70,
		EnemyDamage = 7,
		RewardCoins = 24,
		RewardXP = 20,
	},
	[2] = {
		Id = 2,
		Name = "Ember District",
		Center = Vector3.new(270, 0, 0),
		Color = Color3.fromRGB(190, 92, 55),
		UnlockLevel = 4,
		UnlockCost = 850,
		EnemyName = "Ember Ronin",
		Archetype = "Charger",
		EnemyHP = 220,
		EnemyDamage = 12,
		RewardCoins = 68,
		RewardXP = 50,
	},
	[3] = {
		Id = 3,
		Name = "Frost Citadel",
		Center = Vector3.new(0, 0, -270),
		Color = Color3.fromRGB(75, 145, 200),
		UnlockLevel = 8,
		UnlockCost = 4200,
		EnemyName = "Frost Warden",
		Archetype = "Guardian",
		EnemyHP = 620,
		EnemyDamage = 20,
		RewardCoins = 185,
		RewardXP = 125,
	},
	[4] = {
		Id = 4,
		Name = "Void Sanctum",
		Center = Vector3.new(-270, 0, 0),
		Color = Color3.fromRGB(120, 74, 175),
		UnlockLevel = 14,
		UnlockCost = 16000,
		EnemyName = "Void Reaper",
		Archetype = "Blinker",
		EnemyHP = 1700,
		EnemyDamage = 32,
		RewardCoins = 510,
		RewardXP = 310,
	},
}

Config.Eggs = {
	[1] = {
		Name = "Verdant Egg",
		Cost = 180,
		Zone = 1,
		Pets = {
			{Rarity = "Common", Chance = 55, Bonus = 0.08, Names = {"Sprout Spirit", "Tiny Tanuki", "Dojo Slime"}},
			{Rarity = "Rare", Chance = 28, Bonus = 0.18, Names = {"Leaf Fox", "Wind Cub", "Bamboo Knight"}},
			{Rarity = "Epic", Chance = 12, Bonus = 0.34, Names = {"Storm Crane", "Emerald Oni"}},
			{Rarity = "Legendary", Chance = 4, Bonus = 0.58, Names = {"Jade Dragon"}},
			{Rarity = "Mythic", Chance = 1, Bonus = 0.92, Names = {"Verdant Sovereign"}},
		},
	},
	[2] = {
		Name = "Ember Egg",
		Cost = 900,
		Zone = 2,
		Pets = {
			{Rarity = "Common", Chance = 55, Bonus = 0.16, Names = {"Coal Imp", "Ember Pup", "Ash Spirit"}},
			{Rarity = "Rare", Chance = 28, Bonus = 0.30, Names = {"Flame Fox", "Blaze Ronin"}},
			{Rarity = "Epic", Chance = 12, Bonus = 0.52, Names = {"Inferno Oni", "Phoenix Cub"}},
			{Rarity = "Legendary", Chance = 4, Bonus = 0.86, Names = {"Sunfire Dragon"}},
			{Rarity = "Mythic", Chance = 1, Bonus = 1.30, Names = {"Crimson Emperor"}},
		},
	},
	[3] = {
		Name = "Frost Egg",
		Cost = 3300,
		Zone = 3,
		Pets = {
			{Rarity = "Common", Chance = 55, Bonus = 0.26, Names = {"Snow Wisp", "Frost Pup", "Ice Slime"}},
			{Rarity = "Rare", Chance = 28, Bonus = 0.46, Names = {"Glacier Fox", "Frozen Knight"}},
			{Rarity = "Epic", Chance = 12, Bonus = 0.76, Names = {"Winter Oni", "Aurora Crane"}},
			{Rarity = "Legendary", Chance = 4, Bonus = 1.20, Names = {"Glacial Dragon"}},
			{Rarity = "Mythic", Chance = 1, Bonus = 1.80, Names = {"Absolute Zero"}},
		},
	},
	[4] = {
		Name = "Void Egg",
		Cost = 9800,
		Zone = 4,
		Pets = {
			{Rarity = "Common", Chance = 55, Bonus = 0.42, Names = {"Voidling", "Dark Wisp", "Rift Cub"}},
			{Rarity = "Rare", Chance = 28, Bonus = 0.72, Names = {"Shadow Fox", "Abyss Knight"}},
			{Rarity = "Epic", Chance = 12, Bonus = 1.12, Names = {"Void Oni", "Nebula Serpent"}},
			{Rarity = "Legendary", Chance = 4, Bonus = 1.80, Names = {"Rift Dragon"}},
			{Rarity = "Mythic", Chance = 1, Bonus = 2.80, Names = {"Astral Overlord"}},
		},
	},
}

Config.Quests = {
	{Id = "Kills", Title = "Rift Initiate", Target = 12, Coins = 500, Gems = 0},
	{Id = "Hatches", Title = "Companion Hunter", Target = 3, Coins = 300, Gems = 5},
	{Id = "Bosses", Title = "Break the Rift", Target = 1, Coins = 1000, Gems = 15},
}

Config.WorldEvents = {
	SecretEggFirstDelay = 45,
	SecretEggRespawnMin = 100,
	SecretEggRespawnMax = 160,
	RiftSurgeFirstDelay = 110,
	RiftSurgeInterval = 240,
	RiftSurgeDuration = 55,
}

return Config
