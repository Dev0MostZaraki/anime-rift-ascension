# Anime Rift Ascension

Roblox project for **Anime Rift Ascension**.

## Development workflow

This repository is structured for [Rojo](https://rojo.space/) so source files can be edited outside Roblox Studio and synchronized directly into Studio.

### Project layout

- `src/ServerScriptService/AnimeRiftServer.server.lua` — server-authoritative game logic
- `src/StarterPlayer/StarterPlayerScripts/AnimeRiftClient.client.lua` — client HUD, input and presentation
- `default.project.json` — Rojo project mapping

### Roblox Studio mapping

- `src/ServerScriptService` → `ServerScriptService`
- `src/StarterPlayer/StarterPlayerScripts` → `StarterPlayer > StarterPlayerScripts`

The current build is based on the working v1.2 prototype and will be developed directly in this repository from now on.
