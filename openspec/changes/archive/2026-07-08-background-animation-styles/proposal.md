# Background Animation Style Picker

## Problem

The animated background (`GlitterBackground`, `lib/widgets/glitter_background.dart`)
has exactly one look: the drifting, flocking "motes." The user can turn it on or off,
pick which surfaces it shows on (sidebar, toolbar, tooltips), and pick which theme's
colors it borrows — but not *what kind* of animation plays. It's motes or nothing.

The motes effect is also the most expensive kind we could have picked: every frame it
compares every particle against every other one (the flocking loop) to make them swarm.
Simpler, calmer, and more space-game-flavored looks are cheaper to run, but there's no
way to offer them.

## Proposed Solution

Turn the single background into a **style picker**: the user chooses one animated
background style from a short list. The on/off toggle, the surface locations, and the
color source all stay exactly as they are — the new choice sits alongside them.

Ship nine styles in this change:

- **Motes** — the current flocking glitter, unchanged in look. Stays the default.
- **Starfield** — points of light drifting slowly across the surface, big ones faster
  than small ones (a parallax "moving through space" feel).
- **Nebula** — a few soft, slow clouds of theme color that bloom and fade.
- **Constellation** — drifting points joined by thin lines when they're close (a
  "network" web).
- **Embers** — flickering specks rising with a gentle side-to-side wobble.
- **Aurora** — soft waving curtains of theme color along the surface's long axis.
- **Rain** — thin falling streaks with a fading trail.
- **Radar** — a rotating sweep line with range rings and blips that flare as it passes.
- **Circuitry** — faint grid traces with bright pulses running along them.

Motes is the only one that flocks (an all-pairs step each frame); the rest are lighter.
Under the hood, the shared scaffolding (fade in/out with app focus, sizing, cursor
tracking, color resolution, on/off + location gating) stays in one place, and each
style plugs in its own motion and drawing. That keeps future styles easy to add.

## Scope

- `lib/themes/theme_modifiers.dart` — add a `BackgroundStyle` enum and a
  `backgroundStyle` field on `ThemeModifiers` (persisted; defaults to Motes).
  Regenerate the `.mapper.dart`.
- `lib/widgets/glitter_background.dart` — extract the per-style motion and drawing
  behind a small `BackgroundEffect` interface; keep the host widget's lifecycle,
  sizing, cursor, gating, and color logic. Move the existing motes code into a
  `MotesEffect` with no visual change.
- New `lib/widgets/background_effects/` — the effect interface plus one file per style:
  `MotesEffect`, `StarfieldEffect`, `NebulaEffect`, `ConstellationEffect`,
  `EmbersEffect`, `AuroraEffect`, `RainEffect`, `RadarEffect`, `CircuitryEffect`.
- `lib/trios/settings/settings_page.dart` — add a "Background style" picker next to
  the existing color/locations controls, shown only when the background is enabled.

## Non-Goals

- **Layering / stacking styles** (e.g. motes over a nebula glow). This is a
  pick-one picker, not a compositor.
- **Renaming `GlitterBackground`, `enableGlitter`, `glitterLocations`, or
  `glitterThemeKey`.** "Glitter" is now a slight misnomer, but renaming touches many
  call sites for no user benefit. Keep the names; add `backgroundStyle` alongside.
- No change to the on/off toggle, the surface locations, or the color-source dropdown.

## User-facing text (needs sign-off)

- Picker label: **"Background style"**
- Style names: **Motes**, **Starfield**, **Nebula**, **Constellation**, **Embers**,
  **Aurora**, **Rain**, **Radar**, **Circuitry**
- Picker tooltip: **"Which animation plays in the background."**
