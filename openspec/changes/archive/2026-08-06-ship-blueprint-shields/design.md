# Design: Shields on the ship blueprint view

## Approach

Follow the engine-glow pattern exactly — it's the closest existing feature: a styles manager that merges a game config file and decodes game textures, a `CustomPainter` overlay in `ShipBlueprintView`, animation controllers gated on window focus, and a toolbar toggle.

## How the game draws it (reference)

From the decompiled shield class (`com.fs.starfarer.combat.systems.G`):

1. **Fill**: a triangle fan over the drawn arc (arc + 10°), radius × 1.07. Center vertex alpha 0, edge vertices alpha = 0.55 × innerColor.alpha. The shield texture (`graphics/fx/shields64/128c/256.png`, picked by radius) is mapped as a full circle in texture space and spun. Two passes, additive blend, spinning opposite directions at 22.5°/s.
2. **Ring**: a quad strip along the radius, thickness 5 (4 frigate, 3 fighter), textured with `graphics/hud/line8x8.png` (soft-edged line) across its width, normal blend, ring color at 0.55 alpha. Each point's radius wobbles: `A·sin(phase·10 + θ·10)`, A = clamp(0.25 + 0.75·r/256, ≤1), phase speed `sqrt(20π/r)` rad/s.
3. Both fade to zero alpha over the last 10° of each end. Segment count: `max(arcLen/20 + 1, arc°/5 + 1, 2)`.
4. Colors come from `data/config/hull_styles.json` (`shieldInnerColor`, `shieldRingColor`) via the hull's `style` id. No per-ship color fields.

## Key decisions

- **Rendering with `canvas.drawVertices` + `ImageShader`.** Both the fan and the strip are textured meshes with per-vertex alpha — exactly what `drawVertices(Vertices, BlendMode, Paint)` supports (`textureCoordinates` + `colors`, paint shader = `ImageShader` of the decoded texture). Additive fill uses `BlendMode.plus` on the paint; the per-vertex color modulation uses the Vertices `colors` array. This mirrors how `_EngineGlowPainter` already draws textured quad strips.
- **Hull style colors: new small manager**, `lib/ship_viewer/hull_styles_manager.dart`, mirroring `engine_styles_manager.dart`: a provider that merges `data/config/hull_styles.json` across core + enabled mods (mods win) and exposes `{styleId: (innerColor, ringColor)}`. Fallback for unknown style: MIDLINE colors. Only the two shield color keys are parsed — nothing speculative.
- **Textures: decoded once via a provider**, like `engineGlowSpritesProvider`: resolve `graphics/fx/shields64.png`, `shields128c.png`, `shields256.png`, and `graphics/hud/line8x8.png` through `gameFileResolverProvider` and decode with the existing `loadDecodedImage()` cache (`lib/ship_viewer/utils/sprite_utils.dart`). If a texture is missing (unlikely — they're core files), skip the shield rather than crash.
- **Coordinates**: shieldCenter is ship-local with +x toward the nose. The blueprint draws ships nose-up, so screen position = `(shipPivotX - shieldCenterY, shipPivotYFlipped - shieldCenterX)` — same transform family as `_slotScreenPos()` (`ship_blueprint_view.dart:820`). Facing "up" means the drawn arc is centered on screen-up.
- **Animation**: one repeating `AnimationController` (the shield clock) started only when the shield is visible, animation is enabled, and the window is focused — same gating as `_updateEngineFlicker()` (`ship_blueprint_view.dart:312`). Painter repaints via `repaint:` listenable. Rotation and ripple phase are both derived from elapsed time so a single controller drives everything. When animation is off, the painter draws with phase 0 and no ticker runs.
- **Toggles**:
  - Show/hide: local `_showShield` state + toolbar button (shield icon, e.g. `Icons.shield_outlined`), shown only when the ship has a FRONT/OMNI shield with a radius — same pattern as the engine-glow button at `ship_blueprint_view.dart:1382`. Off by default. Tooltip via `MovingTooltipWidget.text`.
  - Animate: `animateShields` (default true) added to `ShipsPageStatePersisted` (`lib/ship_viewer/ships_page_controller.dart`), toggled from the ships page overflow menu next to "always show engine glow", and passed into `ShipBlueprintView` as a parameter so the details dialog and codex get it too.
- **Fighters/frigates ring thickness**: use `Ship.hullSize`, already on the model.
- **360° shields**: the game formula gives a 370° drawn arc that overlaps itself with end fades. Reproduce the formula as-is; the overlap region is additive-blended and matches the game.

User-visible strings (signed off): toolbar tooltip **"Show shields"**, overflow menu item **"Animate shields"**.

## Remembering the view's settings

The interactive blueprint view's toolbar toggles (bounds, modules, mounts, arcs, built-in weapons, decorative weapons, engine glow, shield) plus the "Animate shields" choice are saved to app settings as a single shared `ShipBlueprintViewState`, a property of the view itself. Both interactive call sites (ship details dialog, codex) share it, so choices carry across places and restarts. The view reads it once in `initState` (interactive only) and writes back on each toggle. Thumbnails (`.minimal`) are untouched — they keep using their constructor values with no persistence. The "Animate shields" toggle moved out of the ships-page overflow menu into the blueprint view's own three-dot menu, shown only when the ship has a shield.

## Files changed

| File | Change |
|---|---|
| `lib/ship_viewer/hull_styles_manager.dart` | New: merged hull-style shield colors + decoded shield/ring textures providers |
| `lib/ship_viewer/ship_blueprint_view_state.dart` (+ `.mapper.dart`) | New persisted model for the view's shown layers + `animateShields` |
| `lib/ship_viewer/widgets/ship_blueprint_view.dart` | New `_ShieldPainter`; `_showShield` state + toolbar button; shield clock controller; reads/writes the shared view state; new three-dot overflow menu holding "Animate shields" |
| `lib/trios/settings/settings.dart` (+ `.mapper.dart`) | `shipBlueprintViewState` field on `Settings` |
| `lib/ship_viewer/ships_page_controller.dart` (+ `.mapper.dart`) | (No longer holds `animateShields` — moved to the view) |
| `lib/ship_viewer/ships_page.dart` | Removed the "Animate shields" overflow item (moved to the view) |
| `lib/utils/game_data_merge.dart` | `mergeHullStyles` wrapper |

No changes needed to the `Ship` model — `shieldCenter`, `shieldRadius`, `shieldType`, `shieldArc`, `style`, `hullSize` are already parsed.

## Risks

- `drawVertices` with per-vertex colors multiplies vertex color with the shader differently than raw OpenGL modulation in some blend setups; may need `BlendMode.modulate` inside the Vertices vs the paint's blend mode tuned by eye against the game. The spec's "matches the game visually on a Medusa" check is the acceptance test.
- Texture spin means recomputing texture coordinates each frame (vertex counts are small — a 300° arc at radius 110 is ~62 segments — so this is cheap).
