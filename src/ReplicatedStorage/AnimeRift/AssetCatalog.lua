return {
	ApprovedEnvironmentPacks = {
		{
			Id = 6933438443,
			Name = "Synty Nature Pack",
			Creator = "Roblox",
			Folder = "Roblox_SyntyNature_6933438443",
			Purpose = "Trees, bushes, plants, flowers, logs, boulders, rocks and outdoor props",
			Priority = 1,
		},
		{
			Id = 6934021345,
			Name = "Synty Dungeon Pack: Cave & Castle Interiors",
			Creator = "Roblox",
			Folder = "Roblox_SyntyDungeon_6934021345",
			Purpose = "Cave, castle, bridge, rune, tunnel and rock pieces for ruins/dungeons",
			Priority = 2,
		},
	},

	-- We deliberately keep gameplay scripts, weapons and third-party character packs out of
	-- the approved list. Imported Creator Store content is used as art only; Anime Rift keeps
	-- combat, progression and interaction logic under our own server-authoritative code.
	Rules = {
		StripScripts = true,
		StripRemotes = true,
		StripTools = true,
		StripInteractiveObjects = true,
		AnchorEnvironment = true,
		DisableTouch = true,
	},

	EnvironmentKeywords = {
		Nature = {
			Tree = {"tree", "pine", "trunk"},
			Bush = {"bush", "plant", "fern", "flower", "grass"},
			Rock = {"rock", "boulder", "stone"},
			Log = {"log", "stump"},
		},
		Dungeon = {
			Rock = {"rock", "boulder", "stone"},
			Ruin = {"rune", "pillar", "column", "arch", "bridge", "cave"},
		},
	},
}
