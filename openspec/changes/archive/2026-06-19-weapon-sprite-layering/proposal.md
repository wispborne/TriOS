# Proposal: Render weapon sprites as layered composites to match in-game

## Problem

The Weapon Viewer draws only **one** of a weapon's sprite layers, so multi-layer
weapons look broken. Example: `HWI_Ragnarok` (Halo Dynamics Ship Industry). In-game the
codex shows the full cannon — the housing/base plus the barrel stacked — but TriOS shows
only the recoiling barrel piece, floating with no base behind it.

The root cause: `WeaponImageCell` picks the **first file that exists** from a
mount-mixed list `[hardpointGunSprite, hardpointSprite, turretGunSprite, turretSprite]`.
Because the gun (recoil) sprites come first, *every* weapon that defines a gun sprite —
not just the Ragnarok — shows the bare barrel instead of the assembled weapon.

Starsector composes a weapon from several layers, and the assembled look also depends on
several switches we currently ignore:

- **Sprite layers** (per mount): `…UnderSprite` → `…GunSprite` (barrel) → `…Sprite`
  (main) → `…GlowSprite` (additive). The game's weapon `render()` (verified in
  decompiled `combat.entities`, 0.98a-RC8) draws them bottom→top as
  **under → [barrel if `RENDER_BARREL_BELOW`] → main → [barrel otherwise] → glow**.
- **`renderHints`** (a list in the `.wpn`): `RENDER_BARREL_BELOW` flips the barrel under
  the main sprite; `RENDER_LOADED_MISSILES` draws loaded missiles on the rack;
  `RENDER_ADDITIVE` blends the whole sprite additively.
- **`numFrames` / `frameRate`** (animated weapons): frames are *separate numbered files*
  and the `.wpn` points at frame `00`, so rendering that path already yields a correct
  static frame — no special handling needed.
- **Loaded missiles** (`RENDER_LOADED_MISSILES`, ~50+ vanilla weapons): the rack shows a
  missile per tube. Each tube is a fire offset in `turretOffsets`/`hardpointOffsets`
  (flat `[x1,y1,x2,y2,…]`); the missile sprite + pivot come from the `.proj` referenced
  by `projectileSpecId`.

## Proposed solution

Composite a weapon's full appearance instead of picking one file:

1. **Model + parsing** — parse the missing fields: `turretUnderSprite`/
   `hardpointUnderSprite`, `turretGlowSprite`/`hardpointGlowSprite`, the `renderHints`
   list, and `projectileSpecId`. Build an ordered, single-mount layer list (prefer
   turret, fall back to hardpoint).
2. **Layered compositing widget** — replace `WeaponImageCell`'s single-image logic with
   a painter that draws all layers in game order, center-aligned at the mount origin,
   with the barrel z-order driven by `RENDER_BARREL_BELOW` and the glow drawn additively.
3. **Loaded missiles** — resolve `projectileSpecId` to a missile sprite (via a global
   `.proj` index across all mods), and draw one missile per tube at its fire offset,
   oriented along the weapon axis, on top of the rack.

## Scope

- `lib/weapon_viewer/models/weapon.dart` — new sprite/hint/projectile fields, ordered
  layer getter, render-hint accessors
- `lib/weapon_viewer/models/` — small missile-render spec model (sprite + size + center)
- `lib/weapon_viewer/weapons_manager.dart` — parse new `.wpn` fields; build a global
  `projectileSpecId → missile sprite` index from `.proj` files
- `lib/weapon_viewer/weapons_page.dart` — `WeaponImageCell` becomes a multi-layer
  composite (CustomPainter over decoded images); grid + detail callers feed it the
  ordered layers
- `lib/weapon_viewer/widgets/weapon_mount_indicator.dart` — inherits the fix
- Regenerated `weapon.mapper.dart` (build_runner)

## Non-goals

- **Animation playback / recoil / muzzle flash / smoke.** The composite is the at-rest
  pose (frame 0, zero recoil) — what the codex shows.
- **`RENDER_ADDITIVE` whole-sprite blend.** Affects a couple of decorative blinkers;
  rendered with normal blend (cosmetic only, not a correctness issue).
- **Per-missile ammo counts / partial-rack states.** Draw one missile per defined tube
  (the full rack), matching the codex's loaded appearance.
- **The detail dialog's per-file sprite list.** It already lists each sprite file and
  stays as-is.
