# Spec: Shield rendering on the ship blueprint view

How the shield should look and behave. All rules below come from the decompiled game code (0.98a-RC8) so the blueprint matches what players see in combat.

## When a shield is drawn

- Only for ships whose shield type is FRONT or OMNI. NONE and PHASE ships get no shield and no toolbar button.
- The shield is drawn on top of everything else for that ship (hull, weapons, engine glow), matching the game's draw order.
- Shown/hidden by a toolbar toggle on the interactive blueprint view. Off by default, like engine glow.

## Geometry

- Shield center: the `.ship` file's `shieldCenter` `[x, y]`, an offset from the ship's pivot (`center`) in ship-local units, +x toward the nose. Radius: `shieldRadius` in the same units (1 unit = 1 sprite pixel of the declared ship size).
- Drawn arc = (shield arc from `ship_data.csv` + 10°), centered on the ship's facing (straight up in the blueprint view). Blank arc in the CSV means 30°. OMNI shields are drawn the same way, centered forward.
- Both fill and ring fade linearly to invisible over the last 10° at each end of the drawn arc, so the full-brightness region matches the stated arc.
- The fill extends to radius × 1.07; the ring sits at the radius itself.

## Inner fill

- Texture picked by radius: `graphics/fx/shields256.png` at radius ≥ 128, `graphics/fx/shields128c.png` at ≥ 64, else `graphics/fx/shields64.png`. The texture is a soft rim glow with cloudy mottling, mapped as a full circle across the shield.
- Drawn twice with additive blending, the two copies counter-rotating. Color is the hull style's `shieldInnerColor`; its alpha (75 in vanilla) scales the whole fill.
- Vertex alpha runs from 0 at the shield center to full at the edge, times the idle brightness factor 0.55.

## Ring

- A soft-edged white band (the game uses `graphics/hud/line8x8.png`, an 8-pixel line with a smooth alpha gradient) drawn with normal blending on top of the fill.
- Thickness 5 units; 4 for frigates; 3 for fighters. Color is the hull style's `shieldRingColor`, at idle alpha ≈ 0.55.

## Colors

- Read `shieldInnerColor` and `shieldRingColor` from `data/config/hull_styles.json`, merged vanilla + enabled mods like other game config, looked up by the hull's `style` id. Unknown style falls back to MIDLINE colors (inner 125,125,255,75; ring white).

## Idle animation

- Fill: the two texture copies rotate in opposite directions at 22.5°/second.
- Ring: each edge point's radius wobbles by `A × sin(phase × 10 + angle × 10)` where A = clamp(0.25 + 0.75 × radius/256, max 1.0) units and the phase advances at `sqrt(20π / radius)` radians/second.
- No alpha pulsing at idle — brightness is constant.
- An "Animate shields" toggle turns animation on or off. It lives in the blueprint view's own three-dot overflow menu (shown only for ships that have a shield). Off = a single static frame, no tickers running. Animation also pauses while the TriOS window is not focused, like engine glow flicker.

## Remembering what's shown

- The interactive blueprint view remembers which layers are shown (bounds, modules, mounts, arcs, built-in weapons, decorative weapons, engine glow, shield) and whether shields animate, saved to app settings.
- These are a property of the blueprint view itself, so they're shared by every interactive place it appears (ship details dialog, codex) and stay the same across restarts.
- Thumbnails (the small non-interactive previews) are unaffected — they keep using their own fixed look.

## Done when

- A Medusa (high tech, radius 110, 300° front shield) shows a blue-tinted shimmering dome with a white rippling edge that visibly matches the game.
- A low-tech ship's fill is red-tinted (per hull style).
- Toggling animation off freezes the visual and stops all tickers; toggling the shield button off removes it entirely.
- Ships without shields (or with PHASE) show no shield button.
