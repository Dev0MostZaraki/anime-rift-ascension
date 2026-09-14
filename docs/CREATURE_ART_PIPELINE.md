# Anime Rift Ascension — Creature Art Pipeline

This pipeline replaces the procedural enemy/pet placeholders one asset at a time without changing combat, stats, drops, AI or inventory code.

## Runtime asset folders

Imported models live in **ServerStorage**, outside the Rojo-managed tree:

```text
ServerStorage
└─ AnimeRiftAssets
   ├─ Enemies
   │  ├─ Enemy_DojoRogue
   │  ├─ Enemy_EmberRonin
   │  ├─ Enemy_FrostWarden
   │  └─ Enemy_VoidReaper
   ├─ Bosses
   │  └─ Boss_RiftTyrant
   └─ Pets
      ├─ Pet_RiftlingPrime
      ├─ Pet_Dragon
      ├─ Pet_Fox
      ├─ Pet_Oni
      ├─ Pet_Slime
      ├─ Pet_Wisp
      ├─ Pet_Knight
      ├─ Pet_Crane
      ├─ Pet_Serpent
      ├─ Pet_Cub
      ├─ Pet_Spirit
      └─ Pet_Generic
```

`CreatureArtService` creates these folders automatically when the server starts. Imported models placed there are preserved because ServerStorage is not managed by the current Rojo project.

## Automatic fallback behavior

1. The server looks for an imported model matching `CreatureArt.lua`.
2. If found, it clones the imported model into the enemy/pet and hides the procedural placeholder.
3. If not found, the game continues to use the procedural development model.

This means art can be replaced gradually. One finished Dojo Rogue can ship while every other creature still uses a fallback.

## First three art targets

The first quality benchmark is intentionally small:

- `Enemy_DojoRogue`
- `Boss_RiftTyrant`
- `Pet_RiftlingPrime`

Do not mass-produce 30 creatures until these three establish the visual language.

## Blender starter

Open `tools/blender/anime_rift_creature_starter.py` in Blender's **Scripting** workspace.

At the top of the file, choose one:

```python
ASSET = "Enemy_DojoRogue"
ASSET = "Boss_RiftTyrant"
ASSET = "Pet_RiftlingPrime"
```

Run Script. The helper creates an original anime-inspired rigged blockout. It is a production starting point, not final art.

Optional FBX export:

```python
EXPORT_DIR = r"C:\AnimeRift\exports"
```

The exported filename already matches the runtime manifest.

## Art direction

The current target is **stylized anime fantasy**, not neon sci-fi.

### Dojo Rogue
- readable human silhouette
- cloth + leather + limited metal
- muted green/brown palette
- wrapped fists / martial-arts language
- no glowing body parts except very small supernatural accents

### Rift Tyrant
- imposing silhouette visible from a distance
- broad shoulders and broken ceremonial armor
- dark stone/metal palette
- a single readable Rift core
- glow is reserved for phase/attack moments

### Riftling Prime
- cute, readable shape at small screen size
- recognizable head/body/wings/tail silhouette
- rarity color used as an accent, not as the entire material
- enough surface detail to look intentional without becoming noisy

## Roblox import checklist

For each FBX:

1. Import through Roblox Studio's **3D Importer**.
2. Confirm the model faces Roblox forward consistently.
3. Give the resulting top-level Model the exact manifest name.
4. Set a sensible `PrimaryPart` / root if Studio did not do so.
5. Drag the Model into the appropriate `ServerStorage/AnimeRiftAssets/...` folder.
6. Press Play.
7. Look for the startup line:

```text
[Creature Art] pipeline ready • X enemy • Y boss • Z pet external models
```

8. The matching runtime creature should now use the imported model automatically.

## Tintable parts

Pet family models can receive rarity accents automatically. Mark any Roblox BasePart/MeshPart that should be recolored with the Boolean attribute:

```text
AnimeRiftTint = true
```

Parts with names containing `Accent`, `Core`, or `Tint` are also treated as tintable.

Do **not** make the whole model tintable. Use rarity color on eyes, gems, cloth trim, feathers, runes, etc.

## Scale and pivot

Scale/pivot values are controlled in:

```text
src/ReplicatedStorage/AnimeRift/CreatureArt.lua
```

If an imported enemy floats or sinks, adjust only its `PivotY` first. If it is globally too large/small, adjust `Scale`.

Do not hard-code per-asset offsets in CombatService or PetService.

## Animation path

`CreatureArt.lua` already includes animation slots. They are `0` until animations are published:

```lua
Animations = {
    Idle = 0,
    Walk = 0,
    Attack = 0,
    Hit = 0,
    Death = 0,
}
```

Once Roblox animation IDs exist, add them to the manifest. `CreatureArtService` can already create/use an Animator and play the imported Idle track. Combat-state animation wiring is the next animation pass.

## Production rule

The gameplay root remains server authoritative and separate from visuals. Imported meshes must not contain gameplay scripts, hitboxes, reward logic or damage code. `CreatureArtService` strips scripts from imported clones as an additional safety boundary.
