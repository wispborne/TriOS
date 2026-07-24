# Tasks: Shields on the ship blueprint view

- [x] Create `lib/ship_viewer/hull_styles_manager.dart`: provider that merges `data/config/hull_styles.json` across core + enabled mods and exposes shield inner/ring colors per style id, with MIDLINE fallback.
- [x] Add a shield-textures provider (same file): resolve and decode `graphics/fx/shields64.png` / `shields128c.png` / `shields256.png` and `graphics/hud/line8x8.png` via `gameFileResolverProvider` + `loadDecodedImage()`.
- [x] Add `_ShieldPainter` to `ship_blueprint_view.dart`: fill (two counter-rotating additive textured fans, per-vertex alpha 0→edge, radius × 1.07) and ring (textured strip, thickness by hull size, ripple wobble), with 10° end fades and the game's segment-count formula.
- [x] Wire the painter into the blueprint stack above the hull/weapon layers, positioned from `shieldCenter`/`shieldRadius` using the ship-space transform, drawn only for FRONT/OMNI shields.
- [x] Add the shield clock `AnimationController`: runs only when shield shown + animation on + window focused; painter repaints from it; phase 0 static frame when off.
- [x] Add `_showShield` state and a toolbar toggle button (only when the ship has a shield), tooltip via `MovingTooltipWidget.text`, off by default.
- [x] Add `animateShields` (default true) to `ShipsPageStatePersisted` with a toggle method; run `dart run build_runner build --delete-conflicting-outputs`.
- [x] Add "Animate shields" to the ships page overflow menu. (Note: the blueprint view reads the `animateShields` setting straight from `shipsPageControllerProvider`, the same way it already reads `alwaysShowEngineGlow`, so no param threading through the details dialog / codex was needed.)
- [x] Get user sign-off on the two visible strings. Signed off as "Show shields" (toolbar) and "Animate shields" (menu).
- [ ] Verify by eye against the game: Medusa (blue, 300° front), a low-tech ship (red fill), a fighter (thin ring), a 360° shield; check animation toggle freezes it and unfocusing the window pauses it.
- [x] Run `fvm flutter analyze` and `fvm flutter test`. (Analyzer clean for the changed files — 3 pre-existing unused-import warnings in `ships_page.dart` left untouched; all 532 tests pass.)

Follow-up (requested after first pass):

- [x] Move the "Animate shields" toggle out of the ships-page overflow menu into the blueprint view's own new three-dot overflow menu (shown only when the ship has a shield).
- [x] Persist the interactive blueprint view's shown layers (bounds, modules, mounts, arcs, built-in weapons, decorative weapons, engine glow, shield) plus `animateShields` in a new shared `ShipBlueprintViewState` on app settings; read once in `initState`, write on each toggle. Scoped to the view itself so it's shared across every interactive place and across restarts; thumbnails unaffected. Re-ran build_runner, analyze, and tests (532 pass).
- [ ] Verify by eye against the game (still pending): shields look right, and the shown-layer toggles + animate toggle come back after a restart and are shared between the ship details dialog and the codex view.
