local CreatureArt = {}

-- External creature assets are intentionally kept out of Rojo-managed source.
-- Import finished models into ServerStorage/AnimeRiftAssets using the names below.
-- CreatureArtService will hot-swap them over the procedural fallbacks automatically.

CreatureArt.Enemies = {
	Brawler = {
		Asset = "Enemy_DojoRogue",
		Display = "Dojo Rogue",
		Scale = 1.00,
		PivotY = -3.0,
		Animations = {Idle = 0, Walk = 0, Attack = 0, Hit = 0, Death = 0},
	},
	Charger = {
		Asset = "Enemy_EmberRonin",
		Display = "Ember Ronin",
		Scale = 1.00,
		PivotY = -3.0,
		Animations = {Idle = 0, Walk = 0, Attack = 0, Hit = 0, Death = 0},
	},
	Guardian = {
		Asset = "Enemy_FrostWarden",
		Display = "Frost Warden",
		Scale = 1.08,
		PivotY = -3.1,
		Animations = {Idle = 0, Walk = 0, Attack = 0, Hit = 0, Death = 0},
	},
	Blinker = {
		Asset = "Enemy_VoidReaper",
		Display = "Void Reaper",
		Scale = 1.02,
		PivotY = -3.0,
		Animations = {Idle = 0, Walk = 0, Attack = 0, Hit = 0, Death = 0},
	},
}

CreatureArt.Bosses = {
	RiftTyrant = {
		Asset = "Boss_RiftTyrant",
		Display = "Rift Tyrant",
		Scale = 1.00,
		PivotY = -4.5,
		Animations = {Idle = 0, Walk = 0, Attack = 0, Slam = 0, Phase = 0, Hit = 0, Death = 0},
	},
}

-- One good family model can cover several pets. Exact-name assets take priority,
-- then family assets, then the current procedural fallback.
CreatureArt.PetFamilies = {
	{Pattern = "Dragon", Asset = "Pet_Dragon", Scale = 0.88},
	{Pattern = "Fox", Asset = "Pet_Fox", Scale = 0.82},
	{Pattern = "Oni", Asset = "Pet_Oni", Scale = 0.86},
	{Pattern = "Slime", Asset = "Pet_Slime", Scale = 0.74},
	{Pattern = "Wisp", Asset = "Pet_Wisp", Scale = 0.76},
	{Pattern = "Knight", Asset = "Pet_Knight", Scale = 0.82},
	{Pattern = "Crane", Asset = "Pet_Crane", Scale = 0.84},
	{Pattern = "Serpent", Asset = "Pet_Serpent", Scale = 0.88},
	{Pattern = "Cub", Asset = "Pet_Cub", Scale = 0.80},
	{Pattern = "Pup", Asset = "Pet_Cub", Scale = 0.80},
	{Pattern = "Tanuki", Asset = "Pet_Cub", Scale = 0.80},
	{Pattern = "Spirit", Asset = "Pet_Spirit", Scale = 0.78},
	{Pattern = "Voidling", Asset = "Pet_Spirit", Scale = 0.78},
	{Pattern = "Riftling", Asset = "Pet_Riftling", Scale = 0.82},
}

CreatureArt.PetExact = {
	["Riftling Prime"] = {Asset = "Pet_RiftlingPrime", Scale = 0.88},
	["Verdant Sovereign"] = {Asset = "Pet_VerdantSovereign", Scale = 0.90},
	["Crimson Emperor"] = {Asset = "Pet_CrimsonEmperor", Scale = 0.90},
	["Absolute Zero"] = {Asset = "Pet_AbsoluteZero", Scale = 0.90},
	["Astral Overlord"] = {Asset = "Pet_AstralOverlord", Scale = 0.92},
}

CreatureArt.PetFallback = {Asset = "Pet_Generic", Scale = 0.80}

return CreatureArt
