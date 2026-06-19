# Design: Layered weapon sprite rendering

## Background: how the game assembles a weapon's appearance

Verified against the decompiled weapon `render()` in `combat.entities` and real `.wpn`/
`.proj` data (Starsector 0.98a-RC8). For one mount (turret or hardpoint), the at-rest
draw order is bottom → top:

1. **Under sprite** (`…UnderSprite`)
2. **Barrel / gun sprite** (`…GunSprite`) — *here only if `RENDER_BARREL_BELOW`*
3. **Main sprite** (`…Sprite`)
4. **Barrel / gun sprite** — *here otherwise* (the default; barrel on top)
5. **Loaded missiles** — one per tube, if `RENDER_LOADED_MISSILES`
6. **Glow sprite** (`…GlowSprite`) — additive

Each full-frame sprite is drawn `renderAtCenter(mountLoc)` with the same angle, so the
PNG's center coincides with the mount origin. Fire offsets and missile positions are
expressed in that same pixel space, relative to the mount origin.

## Config matrix — every switch and how it's handled

| Switch / field | Source | Handling |
|---|---|---|
| main + gun sprite | `…Sprite`, `…GunSprite` | Composited; barrel on top by default. **The core fix.** |
| `RENDER_BARREL_BELOW` | `renderHints` list (string) | Moves barrel below main sprite. |
| `…UnderSprite` | `.wpn` field (0 vanilla, modder-only) | Bottom layer. |
| `…GlowSprite` + `glowColor` | `.wpn` fields (35 vanilla) | Top layer, additive (`BlendMode.plus`). |
| `numFrames` / `frameRate` | `.wpn` fields | **No-op**: path already points to frame `00`. |
| `RENDER_LOADED_MISSILES` | `renderHints` + `projectileSpecId` | Missile per tube (see below). |
| turret vs hardpoint | which `…Sprite` exists | Prefer turret; fall back to hardpoint. |
| `RENDER_ADDITIVE` | `renderHints` | Ignored — normal blend (non-goal). |
| recoil / muzzle flash / smoke | various | Ignored — at-rest pose (non-goal). |
| `specClass` beam vs projectile | `.wpn` | Same layer handling; beams simply lack gun sprites. |
| decorative / system | existing `isDecorative` / codex hints | Already filtered upstream. |

## Decisions

### Single mount, prefer turret
Build the composite from one mount's layers (the current bug is that the pick-list mixes
turret and hardpoint files). Use turret when a turret main sprite exists, else hardpoint.

### CustomPainter over decoded images, not a Stack of `Image.file`
Center-aligned same-size layers (under/main/gun/glow) plus *positioned* missiles at
sub-pixel offsets — possibly extending beyond the base sprite's bounds — don't fit a
naive `Stack`. A painter working in the weapon's pixel space handles all layers uniformly
and lets us compute the true bounding box. Images are pre-decoded to `ui.Image`; a failed
decode just skips that layer (replaces the old per-file `File.exists()` check).

### Glow additive, at rest
Glow draws with `BlendMode.plus` tinted by `glowColor`. At rest there's no charge pulse,
so it's a static tint — matches the codex's idle energy-weapon look.

## Geometry: coordinate space

- **Origin** = the main sprite's center (the mount location).
- Full-frame layers (under/main/gun/glow): drawn centered on the origin, same size — they
  already encode their own positioning via transparent padding.
- **Fire offsets**: `…Offsets` is flat `[x1,y1,x2,y2,…]`. `x` is *along the barrel*
  (weapon-forward), `y` is lateral. Weapon sprites are authored pointing **up**, so in the
  static (codex) pose map weapon-space → sprite-space as: `dx = y`, `dy = -x` (forward =
  up = negative screen-y). `…AngleOffsets[i]` rotates that tube's missile.
- **Missile placement** (per tube `i`): translate to `(originX + y_i, originY - x_i)`,
  rotate by `angleOffset_i`, draw the missile sprite so its `center` (from the `.proj`)
  sits at that point, pointing up.
- **Canvas / bounding box**: union of the base layer bounds and all missile bounds.
  Paint into that box, then scale to the cell via `FittedBox` so missiles that overhang
  the rack aren't clipped.

## File changes

### `lib/weapon_viewer/models/weapon.dart`
Add fields alongside the existing sprite fields (95–98):
```dart
final String? turretUnderSprite;
final String? hardpointUnderSprite;
final String? turretGlowSprite;
final String? hardpointGlowSprite;
final List<String>? renderHints;     // e.g. ["RENDER_BARREL_BELOW", "RENDER_LOADED_MISSILES"]
final String? projectileSpecId;
// turretOffsets / hardpointOffsets / angle offsets if not already parsed
```
Convenience getters:
```dart
bool get renderBarrelBelow => renderHints?.contains('RENDER_BARREL_BELOW') ?? false;
bool get renderLoadedMissiles => renderHints?.contains('RENDER_LOADED_MISSILES') ?? false;
```
Replace the mount-mixed `spritesForWeapon` (306–311) with:
```dart
/// Full-frame layers for the preferred mount, back→front, at-rest order.
/// (Missiles and glow handled separately by the painter.)
late final List<String> spriteLayers = _buildSpriteLayers(); // under, [gun if below], main, [gun if !below]

/// Flat list of every sprite file, for the detail dialog's per-file view.
late final List<String> allSpriteFiles = [...];
```

### Loaded-missile resolution — **implemented as per-folder, not a global index**
Rather than a runtime global `MissileRenderSpec` index + new mapped model, the missile
sprite/size/center are resolved **at parse time within the weapon's own mod folder**
(`_indexMissileSpecs` recursively scans `data/weapons` for `.proj` files with
`specClass == "missile"`) and stored directly on `Weapon` as
`loadedMissileSprite`/`loadedMissileSize`/`loadedMissileCenter`. This fits the existing
per-folder, per-variant cache model. Trade-off: a launcher firing a projectile defined in
a *different* mod won't show missiles (rare; documented non-goal).

### `lib/weapon_viewer/weapons_manager.dart`
- In `wpnFields` (226–253): add `turretUnderSprite`, `hardpointUnderSprite`,
  `turretGlowSprite`, `hardpointGlowSprite`, `renderHints`, `projectileSpecId`, and the
  fire-offset arrays. Resolve sprite paths with the existing
  `p.join(folder.path, …).normalize.path` pattern, **but only when the JSON key is
  present** (joining a null currently yields the folder path; null-check first).
- Build a **global `projectileSpecId → MissileRenderSpec` index** by scanning `.proj`
  files across all mods (+ vanilla), since a weapon in one mod may fire a projectile
  defined elsewhere. Resolve the missile sprite path relative to the `.proj`'s own mod
  folder. Expose it so the painter can look up a launcher's missile sprite.

### `lib/weapon_viewer/weapons_page.dart`
- Replace `_getWeaponImagePath` (1019) with async loading that decodes each layer image
  to `ui.Image` (skip failures), keyed by a cache.
- Rework `_WeaponImageCellState` to paint via a `WeaponSpritePainter`: under → barrel/main
  (ordered by `renderBarrelBelow`) → missiles (per tube) → glow (additive), inside a
  `FittedBox` over the computed bounding box. Empty → existing `image_not_supported`
  placeholder. Tooltip / `InkWell` / `showInExplorer` target the main sprite file.
- Grid `spritePaths` column (737–748): pass the weapon (painter pulls layers + missiles).
- Detail dialog (374–460): pass `weapon.allSpriteFiles`; per-file rendering unchanged.

### `lib/weapon_viewer/widgets/weapon_mount_indicator.dart`
Update `weapon.spritesForWeapon` references (~37–41) to the new composite cell.

### Code generation
New `@MappableClass` fields → rerun
`dart run build_runner build --delete-conflicting-outputs`.

## Risks / edge cases

- **Sizing.** The painter must share one coordinate space and scale via `FittedBox`; the
  old hardcoded 40×40 in `WeaponImageCell.build` is replaced by fit-to-cell.
- **Missile draw order vs rack.** Assumed missiles-on-top-of-base (open racks). A few
  closed racks may want missiles behind; verify on implement and flag if a hint controls
  it.
- **Non-full-frame offset barrels.** Center-stacking is correct for the dominant
  full-frame convention (Ragnarok, vanilla). Rare hand-offset barrels may be imperfect.
- **`.proj` index cost.** Scanning every mod's `.proj` adds load work; build it lazily /
  alongside the existing weapon scan and cache it.
