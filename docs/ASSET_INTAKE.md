# Anime Rift Ascension — Approved Asset Intake

Version target: `4.5-asset-foundation`

The game now supports a controlled Creator Store art pipeline. External assets are treated as **visual content only**. Combat, progression, rewards, remotes and interactions remain implemented by Anime Rift code.

## Approved first-pass packs

### 1) Roblox / Synty Nature Pack
- Creator Store asset ID: `6933438443`
- Expected Studio folder: `ServerStorage/AnimeRiftVendorAssets/Roblox_SyntyNature_6933438443`
- Intended use: trees, bushes, plants, logs, rocks and general outdoor details.

### 2) Roblox / Synty Dungeon Pack: Cave & Castle Interiors
- Creator Store asset ID: `6934021345`
- Expected Studio folder: `ServerStorage/AnimeRiftVendorAssets/Roblox_SyntyDungeon_6934021345`
- Intended use: cave rocks, pillars, columns, arches, bridges and ruin pieces.

## Studio import workflow

1. Start the game once after pulling `4.5-asset-foundation`. This creates `ServerStorage/AnimeRiftVendorAssets` and the approved package folders.
2. Stop Play mode.
3. Open **Toolbox → Creator Store**.
4. Search for the exact approved pack name or asset ID.
5. Insert the pack into Studio.
6. Drag the inserted pack/model under the matching approved package folder in `ServerStorage/AnimeRiftVendorAssets`.
7. Start Play again.

At runtime, `AssetIntakeService` sanitizes approved package folders and removes embedded scripts, remotes, tools and interaction objects. Environment parts are anchored and touch events are disabled before they are used.

`EnvironmentAssetService` then searches approved packs for usable nature/dungeon pieces by name and places a curated number of them across Rift Haven, Verdant, Ember, Frost and Void. If no approved pack is present, the existing procedural fallbacks stay active.

## Rules

- Do not place random Toolbox models directly into Workspace and leave them there.
- Do not use assets ripped from other Roblox experiences.
- Do not use copyrighted anime character models as final production content.
- Do not import gameplay systems from asset packs into Anime Rift. We use assets as art/reference only.
- Creature, boss, pet and signature weapon art should remain original or purpose-built for the project.
- Always test triangle count, draw calls and mobile performance before increasing placement density.

## What we intentionally did not approve yet

- Large scripted forest packs: useful references, but we already have a cleaner nature pack for the first pass.
- Community VFX packs: many contain scripts and often clash with our art direction.
- Weapon systems: our combat is already server-authoritative and should not be replaced by Toolbox combat scripts.
- Character/anime packs: these create both identity and rights problems; our Creature Art pipeline is the correct route.

## Success output

With no external packs yet:

```text
[Asset Intake] ready • 0/2 approved environment packs populated
[Environment Assets] no approved external packs imported yet • procedural fallbacks remain active
```

After both approved packs have been inserted into their folders, the first line should report `2/2`, and Environment Assets should report the number of external props placed.
