# Anime Rift Ascension — Open-source reference plan

Target build: `4.6-core-loop`

We use outside projects in three different ways and keep those categories separate:

## 1. Safe code candidates

### MadStudioRoblox / ProfileStore
- Repository: `MadStudioRoblox/ProfileStore`
- License: Apache-2.0
- Why it is useful: autosaving, player-profile session locking, conflict handling and anti-dupe safety for future trading.
- Decision: adopt in a dedicated data-hardening migration after the 4.6 gameplay loop is stable. Existing `AnimeRiftAscension_v2` progress must be migrated instead of overwritten.

### Sleitnick / RbxUtil
- Repository: `Sleitnick/RbxUtil`
- License: MIT
- First candidate: `Trove` 1.8.0 for connection/object cleanup.
- Decision: use selected modules where they reduce lifecycle bugs; do not replace the whole service architecture.

## 2. Architecture/design references only

### A-Ricemusic / RPG-Template
- Useful reference: separates shared quest definitions, server quest handling and client quest presentation.
- The repository README describes it as free to use, but we do not rely on that wording as a blanket code license.
- Decision: study the architecture and independently implement our own regional quest system.

### Successful Roblox RPG/simulator patterns
We copy **abstract game design patterns**, not proprietary source/assets:
- region-based quest chains;
- normal → elite → boss encounter hierarchy;
- weapon/style mastery with milestone unlocks;
- collection systems that feed combat progression;
- exploration rewards that make travel worthwhile.

## 3. Never import

- leaked/decompiled code from another Roblox experience;
- ripped maps, UI, models, sounds or animations;
- copyrighted anime character models as production art;
- unknown Toolbox scripts/remotes/gameplay systems.

## 4.6 implementation derived from the research

`4.6-core-loop` introduces our own implementation of:
- persistent regional quest-chain progress;
- one guaranteed elite encounter in every region spawn set;
- elite HP/damage/reward scaling;
- region-aware quest HUD;
- mastery milestone perks at 50 / 150 / 300 / 500 mastery;
- existing global missions remain as parallel account goals.

The next infrastructure milestone is a ProfileStore-backed save layer with safe `v2 -> v3` migration before valuable trading is enabled.
