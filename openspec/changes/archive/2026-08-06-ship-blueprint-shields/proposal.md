# Proposal: Shields on the ship blueprint view

## Problem

The ship blueprint view (`lib/ship_viewer/widgets/ship_blueprint_view.dart`) shows the hull sprite, bounds, weapon mounts, arcs, and engine glow — but not shields. Shield size and coverage are a big part of how a ship plays, and the data is already parsed (`shieldCenter`, `shieldRadius`, `shieldType`, `shieldArc` on the `Ship` model). Nothing draws it.

## Solution

Draw the shield on the blueprint view the way the game draws it in combat, based on the decompiled game code:

- A translucent inner fill (the game's cloudy shield texture, additive blend, tinted by the hull style's inner color) covering the shield arc.
- A soft white ring along the shield edge.
- Correct geometry: shield center and radius from the `.ship` file, arc from `ship_data.csv`, drawn 10° wider than the stated arc with a fade at each end, front shields centered on the ship's nose.

Include the game's idle animation — the two fill texture copies slowly counter-rotate and the ring ripples — with a toggle to turn animation off. A static frame is drawn when animation is off.

A new toolbar button on the blueprint view shows/hides the shield, matching the existing bounds/mounts/arcs/engine-glow buttons.

## Scope

- Shield fill + ring rendering for the main hull, for FRONT and OMNI shields (OMNI drawn centered forward).
- Shield colors read from `data/config/hull_styles.json`, merged across vanilla + mods like other game config.
- Idle animation (texture rotation + ring ripple) with an on/off toggle, persisted. Animation pauses when the TriOS window loses focus, like engine glow.
- Show/hide toolbar toggle on the interactive blueprint view.

## Out of scope

- Shields on docked station modules (can follow later; geometry helpers exist).
- Hit effects, raise/lower unfold animation, ship-system color overrides (fortress shield etc.).
- PHASE and NONE shield types (nothing to draw).
- Shields in the small non-interactive thumbnails (grid cards, codex rows).
