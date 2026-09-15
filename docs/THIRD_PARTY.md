# Third-party foundations

Anime Rift Ascension uses or adapts a small number of open-source Roblox foundations. Gameplay, balance, world layout, characters, quests, rare hunts and presentation remain project-specific.

## ProfileStore

- Source: `lm-loleris/profilestore`
- Package: `lm-loleris/profilestore@1.0.3`
- License: Apache-2.0
- Use: persistent profile sessions, autosaving and session locking.

## ZonePlus

- Source: `1ForeverHD/ZonePlus`
- Package: `1foreverhd/zoneplus@3.2.0`
- License: MIT
- Use: world-region and hatchery sanctuary detection.

## Roblox resources / NPC state-machine example

- Source: `Roblox/resources/experiences/npc-state-machine`
- Copyright: Roblox Corporation
- License: MIT
- Use: the small state transition pattern in `Modules/StateMachine.lua` is adapted from Roblox's public `SimpleStateMachine` example. Anime Rift enemy states and behavior are project-specific.

## SimplePath research

- Source reference: `ahmicy/simplepath` / the public RBLX-SimplePath project lineage
- License: MIT
- Use: architectural reference only. Anime Rift's `NavigationService.lua` is its own PathfindingService wrapper and does not vendor SimplePath source.

Do not add code or assets from leaked/decompiled Roblox games. Any future third-party code must have an explicit license compatible with this project and be listed here.
