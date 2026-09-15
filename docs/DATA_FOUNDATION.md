# Anime Rift Ascension — Data Foundation

Version target: `4.7-data-foundation`

This build moves the game toward ProfileStore-backed persistence while preserving the existing `AnimeRiftAscension_v2` data as a read-only migration source.

## Dependency

The project uses MadStudioRoblox/ProfileStore `1.0.3` through Wally:

```toml
ProfileStore = "lm-loleris/profilestore@1.0.3"
```

Install packages from the repository root:

```powershell
wally install
```

Rojo maps the generated root `Packages` directory into `ServerScriptService/Packages`.

If ProfileStore is missing, the game does **not** hard-fail. `DataService` falls back to the legacy v2 store and prints a warning. Restart Studio/Rojo after installing packages so the backend can switch to ProfileStore v3.

## Stores

Legacy source (never deleted by 4.7):

```text
AnimeRiftAscension_v2
```

New ProfileStore destination:

```text
AnimeRiftAscension_v3
```

Both use the player key format:

```text
u_<UserId>
```

## First live load migration

For a player whose v3 profile has not completed migration:

1. Start a ProfileStore session for `AnimeRiftAscension_v3`.
2. Add the Roblox user id to the profile for data ownership/GDPR association.
3. Read the matching key from `AnimeRiftAscension_v2`.
4. If legacy data exists, copy the full existing game payload into `Profile.Data.Snapshot`.
5. Mark `LegacyMigration.Completed = true` and save the v3 profile immediately.
6. Apply the snapshot to the existing Instance-based runtime profile.

The old v2 entry is intentionally left untouched as a rollback source.

If the legacy read fails on a live server, the game refuses to open/save an empty v3 profile and asks the player to rejoin. This is intentional data-loss protection.

In Studio without DataStore access, migration remains pending and ProfileStore can operate as a non-persistent mock session.

## Runtime ownership

The current game still represents active player state using Roblox Instances (`leaderstats`, `RiftProfile`, pet/relic folders). This avoids rewriting every gameplay system at once.

Every autosave:

```text
Runtime Instances -> DataService:Serialize() -> Profile.Data.Snapshot -> ProfileStore save
```

On leave/shutdown:

```text
Serialize -> Snapshot -> Profile:EndSession()
```

Ending the session releases the cross-server lock. This is the important prerequisite for future trading and high-value inventory systems.

## Core-loop compatibility

`CoreLoopService` still decorates `DataService:Serialize`, `Apply`, and `CreateProfile`, so regional quest progress is included automatically in both migrated legacy payloads and new ProfileStore snapshots.

## Test checklist

After `wally install`, start Studio and verify:

```text
[Data Foundation] ProfileStore v3 ready • v2 migration armed • session locking active
[Core Loop] regional quest chains + elites active
[Anime Rift Ascension] server started • 4.7-data-foundation
[Anime Rift Ascension] client started - 4.7-data-foundation
```

On the first live load of an account that already has v2 data, also expect:

```text
[Data Foundation] migrated <PlayerName> from AnimeRiftAscension_v2 -> AnimeRiftAscension_v3
```

Then verify coins, gems, level, XP, zone unlocks, styles/mastery, pets, relics, base quests and regional quest progress survived. Change one small value, leave cleanly, rejoin and verify it remains.

## Do not do yet

Do not delete `AnimeRiftAscension_v2`, enable player trading, or make irreversible inventory migrations until several live migration/rejoin tests have succeeded.
