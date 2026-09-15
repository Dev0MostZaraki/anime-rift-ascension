# Fighter Gacha Foundation — v5.1

This branch adds the first standalone Fighter collection and summon system on top of the tested v5 progression foundation.

## Design goal

Fighters are intentionally separate from Companions/Pets.

- Pets remain the exploration / hatch collection system.
- Fighters become the character-team / summon collection system.
- Both can contribute to Power, but they have separate inventory, progression and RNG state.

This avoids turning every collectible into the same system with a different skin.

## Current summon economy

### Gem summons

- 1 summon: 60 Gems
- 10 summons: 540 Gems
- the 10th result of a 10-pull is guaranteed Epic or better

### Rift Ticket summons

- 1 Rift Ticket = 1 summon
- Rift Tickets continue to come from Effective Playtime rewards

These numbers are development balance, not final economy tuning.

## Fighter rarities

Base rarity weights:

- Rare: 55%
- Epic: 28%
- Legendary: 12%
- Mythic: 4.5%
- Secret: 0.5%

The actual rate changes while soft pity is active.

## Pity

`MythicPity` stores consecutive pulls without Mythic or Secret.

- Soft pity begins on pull 55.
- Mythic+ weight increases on every dry pull after soft pity starts.
- Pull 80 is hard pity and guarantees Mythic or Secret.
- Pulling Mythic or Secret resets MythicPity to zero.
- Pity is server-owned and persisted, so leaving and rejoining cannot reset it.

## Traits

A newly discovered Fighter rolls one server-side trait:

- Normal
- Empowered
- Prodigy
- Ascended

Traits currently modify the Fighter's contribution to team Power.

Duplicates do not replace the owned Fighter's trait in this foundation. Trait rerolls / trait inheritance can later become an explicit shard-based progression system instead of silently changing a player's build.

## Duplicates and Soul Shards

The Fighter archive stores one entry per Fighter ID.

Duplicate pulls:

- increase the Fighter's `Copies` count
- grant Soul Shards based on rarity
- do not create duplicate inventory rows

Current duplicate shard rewards:

- Rare: 1
- Epic: 3
- Legendary: 8
- Mythic: 20
- Secret: 50

Soul Shards are deliberately persisted now even though their upgrade sink is not implemented yet. The next layer can use them for Awakening, limit breaks or trait rerolls without migrating the inventory again.

## Fighter team

Players can equip up to three Fighters.

Current base team-Power contributions:

- Rare: +2.0%
- Epic: +3.5%
- Legendary: +5.5%
- Mythic: +8.5%
- Secret: +12.0%

Trait multipliers modify the individual Fighter contribution.

The existing DataService Power calculation remains authoritative. Fighter bonuses are applied after normal Level + Pet + Relic Power has been rebuilt, which prevents repeated equip/unequip from compounding the same bonus.

## Persistence

The existing ProfileStore snapshot is extended with:

- SoulShards
- SummonCount
- MythicPity
- owned Fighter IDs
- Copies
- EquippedSlot
- Trait
- TraitPowerMultiplier

Old profiles without Fighter data remain valid and begin with an empty Fighter archive.

## Client UI

The existing right-side menu dock gains a `FIGHTERS` button.

The Fighter Archive shows:

- Gems
- Rift Tickets
- Soul Shards
- Mythic pity
- summon controls
- owned Fighter rarity
- trait
- duplicate copy count
- team Power contribution
- equipped slot

## Studio test checklist

### Preparation

1. Pull `feature/fighter-gacha-foundation`.
2. Keep Rojo running and connect Studio.
3. Use Play.
4. Press F8 and click `TEST READY`.
5. TEST READY now grants 6,000 Gems and 10 Rift Tickets in addition to the existing test resources.

### Test A — boot

Expected server output includes:

- `[Fighters] server-authoritative summons + pity + Soul Shards active`
- version `5.1-fighter-gacha-foundation`

The right-side menu should contain `FIGHTERS`.

### Test B — single pulls

1. Open FIGHTERS.
2. Use a 60-Gem single summon.
3. Confirm Gems decrease on the server.
4. Confirm one Fighter appears in `FighterInventory`.
5. Confirm the row shows rarity, trait and copy count.

### Test C — duplicate conversion

1. Continue summoning until a duplicate appears.
2. Confirm a second inventory row is NOT created.
3. Confirm `Copies` increases on the existing Fighter.
4. Confirm `RiftProfile/Fighters/SoulShards` increases.

### Test D — 10-pull guarantee

1. Use a 10x Gem summon.
2. Confirm exactly 540 Gems are consumed.
3. Confirm the pull contains at least one Epic-or-better result from the guaranteed final slot.

The result display only summarizes several names when a 10-pull is large; inspect FighterInventory for the authoritative result.

### Test E — team Power

1. Note leaderstats Power.
2. Equip one Fighter.
3. Confirm Power increases.
4. Unequip the same Fighter.
5. Confirm Power returns to the previous value rather than remaining multiplied.
6. Equip three Fighters and confirm a fourth cannot be equipped until a slot is freed.

### Test F — persistence

With API access enabled:

1. Obtain Fighters, at least one duplicate and some pity progress.
2. Equip a team.
3. Save/rejoin.
4. Confirm Fighters, Copies, Traits, Soul Shards, pity and equipped slots return.

## Deliberately not in this branch

This foundation does not yet implement:

- active Fighter NPCs following or attacking
- Fighter leveling
- Awakening / limit breaks
- Soul Shard spending
- trait rerolls
- featured or rotating banners
- banner-specific pity
- Fighter-specific skills
- Spirit gacha
- Fighter mutations beyond the initial trait layer
- Collection Index rewards
- summon animations / cinematic reveals
- monetization

Those systems should be layered onto the tested roster/pity/persistence foundation instead of all being coupled into the first implementation.
