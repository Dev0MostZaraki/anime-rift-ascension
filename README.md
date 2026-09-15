# Anime Rift Ascension

Roblox project for **Anime Rift Ascension**.

## Development workflow

This project is developed through **GitHub + Rojo**. Roblox Studio should not be the primary place to edit project source.

Typical workflow:

1. ChatGPT updates this repository.
2. Pull the newest changes in GitHub Desktop.
3. Install/update Wally packages when `wally.toml` changes: `wally install`.
4. Keep the Rojo server running in VS Code.
5. Roblox Studio previews the synced changes.
6. Test with Play and send Output errors back for fixes.

## Project layout

- `src/ReplicatedStorage/AnimeRift/Config.lua` - shared balance, zones, eggs, quests and game settings
- `src/ReplicatedStorage/AnimeRift/Client/` - client UI modules
- `src/ServerScriptService/AnimeRiftServer.server.lua` - server entrypoint
- `src/ServerScriptService/Modules/` - server game systems
- `src/StarterPlayerScripts/AnimeRiftClient.client.lua` - client entrypoint
- `Packages/` - generated Wally dependencies, mapped server-side by Rojo
- `wally.toml` - pinned Roblox package dependencies
- `default.project.json` - Rojo project mapping

## Current systems

- connected open-world regions and Rift Haven
- zone unlocking and progression
- regional quest chains and elite enemies
- server-authoritative combat
- fighting styles and mastery perks
- XP, Levels, Coins, Gems, Power, Health and Defense
- four egg tiers and rarity pools
- three equipped companion slots
- follower pets and Auto Equip Best
- relic drops and equipment
- Rift Tyrant boss
- Wandering Egg world event
- Rift Surge double reward event
- sprint, dash and safe hatchery pockets
- controlled Creator Store environment-asset intake
- external Blender/Roblox creature-art pipeline
- ProfileStore v3 data foundation with session locking and safe legacy-v2 migration
- fall recovery and safe hub spawning

## Data migration

`4.7-data-foundation` introduces the Wally dependency `lm-loleris/profilestore@1.0.3`.

Run this from the repository root before starting Rojo:

```powershell
wally install
```

Existing player progress remains in `AnimeRiftAscension_v2`. On the first live ProfileStore load, the game copies that payload into `AnimeRiftAscension_v3` and leaves the v2 entry untouched as a rollback source. See `docs/DATA_FOUNDATION.md` for the migration/test procedure.

## Important Rojo note

`default.project.json` intentionally manages all scripts inside `ServerScriptService` and `StarterPlayerScripts`.
Rojo also maps the local `Packages` directory into `ServerScriptService/Packages`; generated package contents are intentionally ignored by Git.

Rojo itself can be managed locally by the VS Code Rojo extension. A local `aftman.toml` created by the extension does not need to be committed for this project to sync.
