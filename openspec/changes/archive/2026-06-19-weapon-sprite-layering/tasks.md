# Tasks: Layered weapon sprite rendering

## Phase A — Model & parsing (foundation)

- [x] In `lib/weapon_viewer/models/weapon.dart`, add fields: `turretUnderSprite`,
      `hardpointUnderSprite`, `turretGlowSprite`, `hardpointGlowSprite` (`String?`),
      `glowColor` (`List<double>?`), `renderHints` (`List<String>?`),
      `projectileSpecId` (`String?`), the fire-offset arrays
      (`turretOffsets`/`hardpointOffsets`/`…AngleOffsets`), and the resolved
      loaded-missile fields (`loadedMissileSprite`/`loadedMissileSize`/`loadedMissileCenter`).
- [x] Add getters `renderBarrelBelow` and `renderLoadedMissiles` that test `renderHints`.
- [x] Replace `spritesForWeapon` with `spriteLayers` (ordered back→front for the preferred
      mount: `[under, if(renderBarrelBelow) gun, main, if(!renderBarrelBelow) gun]`) and
      `allSpriteFiles` (flat, both mounts, for the detail dialog). Also exposed
      `mainSprite`/`glowSprite`/`mountOffsets`/`mountAngleOffsets` for the painter.
- [x] In `lib/weapon_viewer/weapons_manager.dart`, parse the new `.wpn` fields via a
      null-safe `_resolveSpritePath` helper (only joins when the key is present). Parse
      `renderHints`/`projectileSpecId`/offsets verbatim.
- [x] Run build_runner (handled by the running watcher); `dart analyze` clean; confirmed
      no remaining `spritesForWeapon` references.

## Phase B — Layered compositing (core fix: base + under + gun + glow)

- [x] Added a decoded-image cache (`_loadWeaponImage` → `ui.Image`, skipping failures).
      Kept `_getWeaponImagePath` for the per-file detail view (it legitimately needs
      per-file existence checks).
- [x] Added `_WeaponSpritePainter` (CustomPainter) that draws, in a shared pixel space:
      under → barrel/main (ordered by `renderBarrelBelow`) → loaded missiles → glow
      (additive `BlendMode.plus`, tinted by `glowColor` via `BlendMode.modulate`). Layers
      are positioned via a `_WeaponLayer` model (image + center + pivot + rotation + paint).
- [x] Reworked `WeaponImageCell` to take a `Weapon`, load images, compute the union
      bounding box, and paint via `FittedBox`. Empty → `image_not_supported` placeholder.
      Tooltip / `InkWell` / `showInExplorer` target the main sprite.
- [x] Updated the grid `spritePaths` column and `weapon_mount_indicator.dart` to the new cell.
- [x] Updated the detail dialog to pass `weapon.allSpriteFiles`.
- [x] **Verified (live session):** `HWI_Ragnarok` shows the full cannon (base + barrel);
      glow weapons render correctly. Sprite scale tuned to fill the mount indicator.

## Phase C — Loaded missiles

> **Refinement:** instead of a runtime global `MissileRenderSpec` index + separate model,
> the missile sprite/size/center are resolved **at parse time within the weapon's own mod
> folder** (`_indexMissileSpecs` scans `data/weapons` recursively for missile `.proj`s) and
> stored directly on `Weapon` (`loadedMissileSprite`/`Size`/`Center`). This fits the
> existing per-folder, per-variant cache model and needs no new mapped model. Trade-off:
> cross-mod projectile references (a launcher firing a projectile defined in another mod)
> won't show missiles — rare, and documented as a non-goal.

- [x] Resolve missile render data (`sprite`, `size`, `center`) from `.proj` files where
      `specClass == "missile"` via `_indexMissileSpecs`, stored on `Weapon`.
- [x] Build the per-folder `projectileSpecId → _MissileSpec` index (recursive `.proj` scan)
      and link it to launchers with the `RENDER_LOADED_MISSILES` hint.
- [x] In the painter, for each tube `i` place the missile sprite at `(y_i, -x_i)` relative
      to the mount center, rotated by `angleOffset_i`, on its `.proj` `center` pivot, drawn
      above the rack base and below glow; bounding box expands to include missiles.
- [x] **Verified (live session):** loaded-missile racks render with missiles composited
      onto the launcher.

## Phase D — Final

- [x] `dart analyze` clean (no new issues; remaining warnings are pre-existing dead code).
- [x] **Verified (live session):** no regressions on single-sprite/beam/decorative weapons.

## Post-plan enhancements (added during the session)

- [x] Glow drawn only on hover, with a fade-in/out animation.
- [x] "Always show weapon glow" persisted toggle in the overflow menu.
- [x] Right-click context menu on the sprite: open sprite folder, copy composite to
      clipboard (with/without glow) via `super_clipboard`.
- [x] Hover tooltip shows the 1:1 composite (with and without glow) on a dark background.
- [x] Fixed the mount-indicator ring being clipped (inset `_MountShapePainter` radius by
      the stroke width so its drawn bounds fit the canvas).
