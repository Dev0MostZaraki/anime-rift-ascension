local FighterConfig = {}

FighterConfig.Settings = {
	MaxEquipped = 3,
	SingleSummonGems = 60,
	TenSummonGems = 540,
	TicketCostPerSummon = 1,
	SoftPityStarts = 55,
	HardPity = 80,
	SoftPityBoostPerPull = 0.18,
	TenPullGuaranteeRank = 2, -- Epic+
}

FighterConfig.RarityOrder = {"Rare", "Epic", "Legendary", "Mythic", "Secret"}

FighterConfig.Rarities = {
	Rare = {Rank = 1, Weight = 5500, Shards = 1, Color = Color3.fromRGB(80, 158, 255), TeamPower = 0.020},
	Epic = {Rank = 2, Weight = 2800, Shards = 3, Color = Color3.fromRGB(174, 92, 255), TeamPower = 0.035},
	Legendary = {Rank = 3, Weight = 1200, Shards = 8, Color = Color3.fromRGB(255, 184, 61), TeamPower = 0.055},
	Mythic = {Rank = 4, Weight = 450, Shards = 20, Color = Color3.fromRGB(255, 75, 145), TeamPower = 0.085},
	Secret = {Rank = 5, Weight = 50, Shards = 50, Color = Color3.fromRGB(246, 239, 169), TeamPower = 0.120},
}

FighterConfig.Traits = {
	{Id = "Normal", Weight = 9000, PowerMultiplier = 1.00},
	{Id = "Empowered", Weight = 700, PowerMultiplier = 1.05},
	{Id = "Prodigy", Weight = 250, PowerMultiplier = 1.10},
	{Id = "Ascended", Weight = 50, PowerMultiplier = 1.18},
}

FighterConfig.Fighters = {
	Rare = {
		{Id = "RiftBrawler", Name = "Rift Brawler"},
		{Id = "WindAdept", Name = "Wind Adept"},
		{Id = "NeonArcher", Name = "Neon Archer"},
	},
	Epic = {
		{Id = "EmberRonin", Name = "Ember Ronin"},
		{Id = "FrostMonk", Name = "Frost Monk"},
		{Id = "ThunderDuelist", Name = "Thunder Duelist"},
	},
	Legendary = {
		{Id = "CrimsonReaper", Name = "Crimson Reaper"},
		{Id = "CelestialVanguard", Name = "Celestial Vanguard"},
		{Id = "VoidAssassin", Name = "Void Assassin"},
	},
	Mythic = {
		{Id = "RiftSovereign", Name = "Rift Sovereign"},
		{Id = "StarbornWarlord", Name = "Starborn Warlord"},
	},
	Secret = {
		{Id = "NamelessAscendant", Name = "Nameless Ascendant"},
	},
}

return FighterConfig
