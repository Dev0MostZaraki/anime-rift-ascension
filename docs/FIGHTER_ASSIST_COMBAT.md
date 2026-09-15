# Fighter Assist Combat — v5.2

This layer turns equipped Fighters from passive collection entries into active combat tools.

## Controls

Equipped Fighter slots map to:

- Slot 1 → Z
- Slot 2 → X
- Slot 3 → C

The HUD buttons are also clickable/tappable, so the same system works on mobile without keyboard input.

## Fighter identity

Each Fighter now has:

- Role
- Element
- Passive
- Assist name
- Assist targeting type
- Assist cooldown
- Assist damage / utility values

The Fighter Archive displays Role, Element, Assist and Passive. The bottom-center Assist HUD displays the three currently equipped Fighters and their active cooldowns.

## Current Fighters

### Rare

- Rift Brawler — Bruiser / Rift — Rift Break
- Wind Adept — Support / Gale — Gale Spiral
- Neon Archer — Marksman / Arc — Lumen Shot

### Epic

- Ember Ronin — DPS / Flame — Blazing Cross
- Frost Monk — Control / Frost — Frozen Domain
- Thunder Duelist — Burst / Volt — Arc Chain

### Legendary

- Crimson Reaper — Execute / Blood — Blood Moon Cleave
- Celestial Vanguard — Tank / Radiant — Aegis Nova
- Void Assassin — Burst / Void — Null Step

### Mythic

- Rift Sovereign — Control / Rift — Dominion Collapse
- Starborn Warlord — DPS / Astral — Starfall Barrage

### Secret

- Nameless Ascendant — Hybrid / Origin — Ascendant Decree

## Passive rules

Only the three equipped Fighters contribute passives.

Current passive fields can affect:

- all damage
- boss damage
- execute damage against low-health enemies
- Fighter Assist damage
- Fighter Assist cooldown
- max health

Cooldown reduction is capped to prevent three support Fighters from turning Assists into a spam loop.

## Security / exploit behavior

Assist execution is server-authoritative.

The client sends only a requested slot number. The server validates:

- slot is 1–3
- a Fighter is actually equipped in that slot
- Fighter definition exists
- player is alive
- server cooldown has expired
- target requirements are met

Damage is applied through the existing server CombatService `Hit()` path. Because Effective Playtime already hooks validated server hits, empty Z/X/C spam does not create Effective Playtime.

Non-healing Assists do not consume their cooldown when there is no valid target.

After a successful Assist, Fighter team changes are locked until that Assist cooldown expires. This prevents cycling the entire collection through the three team slots to bypass cooldowns.

## Placeholder Fighter Echo

Until final character models exist, activating an Assist creates a short-lived server-replicated Fighter Echo beside the player with the Fighter and skill name. This proves the summon/assist visual pipeline without committing to placeholder character art.

Later, the Echo builder can be replaced by imported character rigs while keeping the same combat service and data definitions.

## Developer testing

`F8 → RESET COOLDOWNS` now resets:

- Q / E / R
- attack combo state
- dash cooldown
- Z / X / C Fighter Assists
- Fighter team-lock timer

## Studio test checklist

1. Pull `feature/fighter-assist-combat`.
2. Start Rojo and Studio Play.
3. Confirm server and client both report `5.2-fighter-assist-combat`.
4. Use `F8 → TEST READY` if resources are needed.
5. Open FIGHTERS and equip three Fighters.
6. Confirm the Fighter Assist HUD shows all three Fighters in slots Z/X/C.
7. Walk near enemies and use Z, X and C.
8. Confirm damage is server-authoritative and cooldown overlays appear.
9. Confirm pressing an Assist with no valid target does not start a cooldown, except Aegis Nova / Ascendant Decree which are defensive/heal skills.
10. During an active Assist cooldown, try changing the Fighter team. It should be blocked with a remaining-time message.
11. Press F8 → RESET COOLDOWNS. Z/X/C should immediately become available and team lock should clear.
12. Equip Celestial Vanguard and verify Max Health increases, then unequip it after the team lock is clear and verify Max Health returns.
13. Test Crimson Reaper against a low-HP enemy and compare damage before/after the target falls below the execute threshold.
14. Use Starborn Warlord near enemies and confirm Starfall does not trigger when there is no initial target.
15. Run RESET SAVE and confirm the Fighter Assist HUD returns to empty slots with no stale cooldown.

## Not in v5.2 yet

- permanent Fighter follower rigs
- Fighter basic attacks / autonomous AI
- Fighter leveling and Mastery
- Awakening / Soul Shard spending
- trait rerolls
- element advantage chart
- status-effect persistence
- final anime character models and animations
- summon cinematics
- featured banner rotations

The next layer should be chosen only after this Assist loop feels good in actual combat.
