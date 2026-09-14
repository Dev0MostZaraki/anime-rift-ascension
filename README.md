# Anime Rift Ascension

Roblox project for **Anime Rift Ascension**.

## Development workflow

This project is now developed through **GitHub + Rojo**. Roblox Studio should no longer be used as the primary place to edit the project source.

Typical workflow:

1. ChatGPT updates this repository.
2. Pull the newest changes in GitHub Desktop.
3. Keep the Rojo server running in VS Code.
4. Roblox Studio previews the sync changes.
5. Review and accept them in the Rojo plugin.
6. Test with Play and send any Output errors back for fixes.

## Project layout

- `src/ReplicatedStorage/AnimeRift/Config.lua` - shared balance, zones, eggs, quests and game settings
- `src/ReplicatedStorage/AnimeRift/Client/` - client UI modules
- `src/ServerScriptService/AnimeRiftServer.server.lua` - server entrypoint
- `src/ServerScriptService/Modules/` - server game systems
- `src/StarterPlayerScripts/AnimeRiftClient.client.lua` - client entrypoint
- `default.project.json` - Rojo project mapping

## Current systems

- generated central hub and four worlds
- zone unlocking and progression
- server-authoritative combat
- XP, Levels, Coins, Gems and Power
- four egg tiers and rarity pools
- three equipped companion slots
- follower pets and Auto Equip Best
- starter missions
- Rift Tyrant boss
- Secret Rift Egg world event
- Rift Surge double reward event
- playtime rewards
- DataStore save/load with Studio-safe fallback
- fall recovery and safe hub spawning

## Important migration note

`default.project.json` intentionally manages all scripts inside `ServerScriptService` and `StarterPlayerScripts`.
On the first sync after the v2 migration, Rojo may propose deleting the manually-created old prototype scripts such as `AnimeFarmPrototype`, `AnimeRiftServer`, `AnimeRiftClient` or the temporary Bootstrap scripts. That cleanup is expected.

Rojo itself can be managed locally by the VS Code Rojo extension. A local `aftman.toml` created by the extension does not need to be committed for this project to sync.
