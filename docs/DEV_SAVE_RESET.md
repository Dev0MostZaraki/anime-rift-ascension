# Developer Save Reset

The F8 Developer Control Room now contains a destructive `RESET SAVE` tool for clean progression testing.

## What it resets

The reset returns the current developer account to a fresh-game state:

- Level, XP, Coins, Gems and Power
- quest progress and completion flags
- zone unlocks
- style unlocks and style mastery
- equipped style
- Pet inventory
- Relic inventory
- Fighter inventory
- Fighter Copies
- Soul Shards
- Fighter summon count
- Mythic pity
- Lifetime / Daily / Session Effective Playtime
- Resonance
- Rift Tickets
- Wild Egg index

The player is returned to Rift Haven and combat stats are recalculated.

## Safety confirmation

The reset is intentionally two-step:

1. Press F8.
2. Click `RESET SAVE` once.
3. A warning says the reset is armed.
4. Click `RESET SAVE` again within 8 seconds.

If the second click does not happen within 8 seconds, nothing is deleted.

The command is server-authorized through the existing developer permission check. Normal players do not receive access to the Developer Control Room.

## Persistence behavior

When persistent DataStore access is available:

- the active ProfileStore v3 snapshot is overwritten with the fresh state
- the legacy v2 fallback is also overwritten when possible
- legacy migration is marked complete so old pre-reset v2 data cannot be automatically re-imported on a later join

When Studio has no persistent DataStore access, the reset still works for the current session but explicitly reports that it was session-only.

## Recommended test

1. Use `TEST READY`.
2. Obtain Pets, Relics and Fighters.
3. Build some Effective Playtime / Resonance / pity.
4. Click RESET SAVE twice within 8 seconds.
5. Confirm the UI returns to fresh values and inventories are empty.
6. Rejoin.
7. With API access enabled, confirm the account still starts fresh.

Use this only on development accounts / development data. Do not expose a player-facing unrestricted wipe command until a separate account-reset UX and recovery policy have been designed.
