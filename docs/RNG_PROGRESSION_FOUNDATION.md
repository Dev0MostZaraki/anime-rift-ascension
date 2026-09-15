# RNG Progression Foundation — v5.0

This branch introduces the first foundation for the agreed Anime Rift progression direction without replacing the existing open-world/combat work.

## What changed

### Effective Playtime

Passive timed coin rewards were removed.

Effective time now advances only while the server has recent evidence of activity. Current evidence sources are:

- plausible character movement / exploration
- server-validated combat hits
- enemy / boss kills
- legitimate world discoveries such as Wild Egg claims

Simply clicking attack without hitting an enemy does not count. Standard hatching by itself also does not maintain Effective Playtime, because future Auto Hatch / Multi Hatch features must not become an AFK Resonance farm.

The server owns the timer. Clients do not submit playtime values.

Daily effective-playtime milestones currently exist at 15, 30, 60, 120 and 180 minutes. Values are development balance and are expected to change.

### Resonance

Session effective playtime builds Resonance from 0 to 100 over two effective hours.

At 100 Resonance the current maximum RNG luck contribution is +30%. Resonance itself is not purchasable and currently resets each server session.

The progression HUD shows:

- current Resonance
- current effective session time
- Rift Tickets

### Pet mutations

Normal egg hatches can now roll a mutation:

- Normal
- Shiny
- Corrupted
- Awakened
- Void
- Divine

Mutation rolls are server-side. Resonance and equipped Luck-pet bonuses can affect mutation RNG.

Mutation balance is intentionally isolated in `ProgressionConfig.lua` so it can be tuned without rewriting services.

### Hidden Wild Eggs

The old announced Wandering Egg with a finite position list has been removed.

The new Wild Egg system:

- keeps authoritative egg state on the server
- does not create a globally replicated server egg object
- does not announce spawns
- selects a random zone and random X/Z position
- raycasts to find a valid surface
- rejects water, steep ground and hatchery safe zones
- uses randomized spawn delay and lifetime
- reveals the visual only to players within discovery radius
- validates claims server-side
- requires effective session activity before claims
- temporarily rejects sensitive claims after implausible movement unless the teleport was server-authorized
- recognizes existing hub / Waystone fast travel as legitimate after the server confirms position actually changed
- tracks discoveries by Wild Egg tier

Current tiers:

White → Emerald → Azure → Arcane → Crimson → Golden → Prismatic → Void

Wild Egg color is rolled globally when the egg spawns. A player's Luck does **not** change the map egg color. Luck currently affects the pet/mutation roll after discovering the egg. This avoids one player changing a server-wide world spawn for everyone.

Golden, Prismatic and Void discoveries may broadcast only after a legitimate claim. No spawn announcement is made.

## Persistence

The existing ProfileStore v3 foundation remains intact.

The progression persistence bridge adds:

- lifetime effective seconds
- daily effective seconds
- daily reward tier
- daily key
- Rift Tickets
- Wild Egg index

Session Effective Playtime and Resonance intentionally do not persist as permanent session buffs.

Pet persistence is extended with optional metadata:

- Role
- Mutation
- MutationPower
- LuckBonus
- DropBonus
- Source
- BaseBonus

Old pets without those fields remain loadable.

## Studio test checklist

Before testing:

1. Pull `feature/rng-progression-foundation`.
2. Run `wally install` if Packages are missing.
3. Start Rojo.
4. Connect Roblox Studio to the Rojo server.
5. Use Play, not only Run.
6. Watch Server and Client Output for errors.

### Test A — boot

Expected server messages include:

- Activity effective playtime + resonance active
- Pet Mutation active
- World Events with hidden eggs delegated to WildEggService
- Wild Egg hidden randomized spawns active
- server version `5.0-rng-progression-foundation`

The top-right progression panel should appear on the client.

### Test B — AFK vs active time

1. Stand still without interacting for roughly 20 seconds.
2. Confirm Effective Playtime does not continuously climb.
3. Spam attack in empty space and confirm that alone does not maintain Active time.
4. Walk normally for 20–30 seconds.
5. Confirm Active time increases.
6. Hit enemies and use abilities against real targets.
7. Confirm activity continues while legitimately fighting.
8. Hatch repeatedly while standing still and confirm hatching alone does not indefinitely maintain Active time.

### Test C — normal hatch mutation

1. Press F8.
2. Use TEST READY if currency/unlocks are needed.
3. Hatch pets repeatedly.
4. Inspect PetInventory attributes in Studio while testing.
5. New pets should have `Mutation`, `MutationPower`, `Source`, and related metadata.

Most rolls should be Normal. Rare mutation rates are intentionally low.

### Test D — Wild Egg

1. Press F8.
2. Press TEST WILD EGG.
3. The dev tool grants only the minimum session-effective requirement for this test and teleports near the hidden egg using a server-authorized teleport.
4. The egg should **not** already be visible from arbitrary distance.
5. Walk toward its location.
6. Within reveal range the local Wild Egg visual should appear.
7. Walk up and hold the Hatch prompt.
8. A pet should be granted and the egg should disappear.
9. Check `RiftProfile/Progression/WildEggIndex`.
10. Check the new pet attributes.

### Test E — movement validation / fast travel

1. Use normal sprint and Dash and confirm no false Wild Egg claim rejection occurs.
2. Use a legitimate Waystone fast travel or return to Rift Haven.
3. Confirm the server marks that actual position change as legitimate.
4. A claim immediately after a valid game teleport should not be rejected as exploit movement.

### Test F — persistence

When API access is available:

1. Hatch at least one mutated or Wild Egg pet.
2. Earn some effective daily time.
3. Save/rejoin.
4. Confirm permanent progression, Wild Egg index and pet metadata return.
5. Confirm SessionEffectiveSeconds and Resonance start as a fresh session.

## Deliberately not implemented in this foundation

This branch is not claiming the complete design is finished. Still planned:

- full Fighter / Spirit gacha system
- fighter mutations / traits
- duplicate Soul Shards
- shard + soft pity
- Pet Fusion tiers
- distinct combat/luck/farming/utility pet stat aggregation beyond the initial Luck metadata
- broader Resonance integration into all RNG systems
- world-event expansion such as Blood Moon / Rift Storm / Meteor Shower
- secret quest conditions
- full Collection Index UI
- Ascension
- redesigned Dungeon / Infinite Dungeon progression
- raids
- trading and trade security
- monetization / gamepasses
- economy tuning and telemetry

These should be layered onto the tested foundation rather than added all at once.

## Known development caveat

Random Wild Egg positions currently validate terrain through raycasts and safe-zone checks. They can still land on a geometrically valid decorative surface. If testing finds visually bad or inaccessible placements, the next step is to add explicit spawn-surface tags / forbidden-volume tags rather than falling back to a fixed coordinate list.
