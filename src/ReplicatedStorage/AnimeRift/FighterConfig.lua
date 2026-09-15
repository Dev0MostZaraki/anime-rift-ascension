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
	AssistMinimumCooldown = 8,
}

FighterConfig.RarityOrder = {"Rare", "Epic", "Legendary", "Mythic", "Secret"}

FighterConfig.Rarities = {
	Rare = {Rank = 1, Weight = 5500, Shards = 1, Color = Color3.fromRGB(80, 158, 255), TeamPower = 0.020},
	Epic = {Rank = 2, Weight = 2800, Shards = 3, Color = Color3.fromRGB(174, 92, 255), TeamPower = 0.035},
	Legendary = {Rank = 3, Weight = 1200, Shards = 8, Color = Color3.fromRGB(255, 184, 61), TeamPower = 0.055},
	Mythic = {Rank = 4, Weight = 450, Shards = 20, Color = Color3.fromRGB(255, 75, 145), TeamPower = 0.085},
	Secret = {Rank = 5, Weight = 50, Shards = 50, Color = Color3.fromRGB(246, 239, 169), TeamPower = 0.120},
}

FighterConfig.Elements = {
	Rift = Color3.fromRGB(151, 85, 245),
	Gale = Color3.fromRGB(105, 225, 189),
	Arc = Color3.fromRGB(75, 205, 255),
	Flame = Color3.fromRGB(255, 102, 55),
	Frost = Color3.fromRGB(117, 210, 255),
	Volt = Color3.fromRGB(255, 226, 83),
	Blood = Color3.fromRGB(225, 55, 90),
	Radiant = Color3.fromRGB(255, 225, 145),
	Void = Color3.fromRGB(137, 75, 214),
	Astral = Color3.fromRGB(255, 125, 218),
	Origin = Color3.fromRGB(245, 239, 190),
}

FighterConfig.Traits = {
	{Id = "Normal", Weight = 9000, PowerMultiplier = 1.00},
	{Id = "Empowered", Weight = 700, PowerMultiplier = 1.05},
	{Id = "Prodigy", Weight = 250, PowerMultiplier = 1.10},
	{Id = "Ascended", Weight = 50, PowerMultiplier = 1.18},
}

-- Passive fields are deliberately additive and modest. They are aggregated only from
-- the three equipped Fighters so a large collection does not become hidden account power.
-- Supported fields in v5.2: Damage, BossDamage, ExecuteDamage/ExecuteThreshold,
-- AssistDamage, AssistCooldownReduction and MaxHealth.
FighterConfig.Fighters = {
	Rare = {
		{
			Id = "RiftBrawler", Name = "Rift Brawler", Role = "Bruiser", Element = "Rift",
			Passive = {Name = "Battle Rhythm", Description = "+3% all damage", Damage = 0.03},
			Assist = {Name = "Rift Break", Type = "Front", Cooldown = 16, Range = 19, Dot = 0.34, DamageMultiplier = 2.05, Stagger = 0.35},
		},
		{
			Id = "WindAdept", Name = "Wind Adept", Role = "Support", Element = "Gale",
			Passive = {Name = "Tailwind", Description = "-6% Fighter Assist cooldowns", AssistCooldownReduction = 0.06},
			Assist = {Name = "Gale Spiral", Type = "Area", Cooldown = 17, Range = 14, DamageMultiplier = 1.15, Stagger = 0.45},
		},
		{
			Id = "NeonArcher", Name = "Neon Archer", Role = "Marksman", Element = "Arc",
			Passive = {Name = "Hunter Signal", Description = "+6% damage to bosses", BossDamage = 0.06},
			Assist = {Name = "Lumen Shot", Type = "Nearest", Cooldown = 18, Range = 46, DamageMultiplier = 2.35, Stagger = 0.15},
		},
	},
	Epic = {
		{
			Id = "EmberRonin", Name = "Ember Ronin", Role = "DPS", Element = "Flame",
			Passive = {Name = "Burning Edge", Description = "+5% all damage", Damage = 0.05},
			Assist = {Name = "Blazing Cross", Type = "FrontBurn", Cooldown = 19, Range = 22, Dot = 0.25, DamageMultiplier = 2.55, BurnMultiplier = 0.45, Stagger = 0.35},
		},
		{
			Id = "FrostMonk", Name = "Frost Monk", Role = "Control", Element = "Frost",
			Passive = {Name = "Still Mind", Description = "-9% Fighter Assist cooldowns", AssistCooldownReduction = 0.09},
			Assist = {Name = "Frozen Domain", Type = "Area", Cooldown = 21, Range = 17, DamageMultiplier = 1.45, Stagger = 1.65},
		},
		{
			Id = "ThunderDuelist", Name = "Thunder Duelist", Role = "Burst", Element = "Volt",
			Passive = {Name = "Overcharge", Description = "+8% Fighter Assist damage", AssistDamage = 0.08},
			Assist = {Name = "Arc Chain", Type = "Chain", Cooldown = 20, Range = 32, MaxTargets = 3, DamageMultiplier = 2.20, ChainFalloff = 0.18, Stagger = 0.25},
		},
	},
	Legendary = {
		{
			Id = "CrimsonReaper", Name = "Crimson Reaper", Role = "Execute", Element = "Blood",
			Passive = {Name = "Final Hour", Description = "+12% damage to enemies below 35% HP", ExecuteDamage = 0.12, ExecuteThreshold = 0.35},
			Assist = {Name = "Blood Moon Cleave", Type = "Front", Cooldown = 23, Range = 25, Dot = 0.15, DamageMultiplier = 3.45, Stagger = 0.75},
		},
		{
			Id = "CelestialVanguard", Name = "Celestial Vanguard", Role = "Tank", Element = "Radiant",
			Passive = {Name = "Guardian Aura", Description = "+8% max health", MaxHealth = 0.08},
			Assist = {Name = "Aegis Nova", Type = "HealArea", Cooldown = 24, Range = 15, DamageMultiplier = 1.50, HealFraction = 0.20, Stagger = 0.65},
		},
		{
			Id = "VoidAssassin", Name = "Void Assassin", Role = "Burst", Element = "Void",
			Passive = {Name = "Ambush Protocol", Description = "+11% Fighter Assist damage", AssistDamage = 0.11},
			Assist = {Name = "Null Step", Type = "Nearest", Cooldown = 22, Range = 38, DamageMultiplier = 4.00, Stagger = 0.85},
		},
	},
	Mythic = {
		{
			Id = "RiftSovereign", Name = "Rift Sovereign", Role = "Control", Element = "Rift",
			Passive = {Name = "Dominion", Description = "+7% all damage", Damage = 0.07},
			Assist = {Name = "Dominion Collapse", Type = "Area", Cooldown = 27, Range = 24, DamageMultiplier = 3.25, Stagger = 1.90},
		},
		{
			Id = "StarbornWarlord", Name = "Starborn Warlord", Role = "DPS", Element = "Astral",
			Passive = {Name = "Warpath", Description = "+6% all damage and +5% Assist damage", Damage = 0.06, AssistDamage = 0.05},
			Assist = {Name = "Starfall Barrage", Type = "Barrage", Cooldown = 28, Range = 23, Pulses = 3, DamageMultiplier = 1.45, Stagger = 0.25},
		},
	},
	Secret = {
		{
			Id = "NamelessAscendant", Name = "Nameless Ascendant", Role = "Hybrid", Element = "Origin",
			Passive = {Name = "Transcendence", Description = "+9% all damage, +10% max health, -8% Assist cooldown", Damage = 0.09, MaxHealth = 0.10, AssistCooldownReduction = 0.08},
			Assist = {Name = "Ascendant Decree", Type = "HealArea", Cooldown = 34, Range = 30, DamageMultiplier = 4.80, HealFraction = 0.25, Stagger = 2.10},
		},
	},
}

function FighterConfig.GetById(fighterId)
	for rarity, entries in pairs(FighterConfig.Fighters) do
		for _, fighter in ipairs(entries) do
			if fighter.Id == fighterId then
				return fighter, rarity
			end
		end
	end
	return nil, nil
end

return FighterConfig
