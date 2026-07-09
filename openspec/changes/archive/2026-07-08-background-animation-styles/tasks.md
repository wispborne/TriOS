# Tasks — Background Animation Style Picker

## 1. Model

- [x] Add a `BackgroundStyle` `@MappableEnum` (`motes`, `starfield`, `nebula`) with a
      `label` getter to `lib/themes/theme_modifiers.dart`, default `motes`.
- [x] Add a `backgroundStyle` field to `ThemeModifiers` (default `BackgroundStyle.motes`).
- [x] Run `dart run build_runner build --delete-conflicting-outputs` to regenerate
      `theme_modifiers.mapper.dart`.

## 2. Effect interface

- [x] Create `lib/widgets/background_effects/background_effect.dart` with the
      `BackgroundEffect` interface and the `BackgroundPaintContext` value class
      (`seed` / `resize` / `update` / `paint`, plus `style` and `reactsToCursor`).

## 3. Extract motes (no visual change)

- [x] Create `lib/widgets/background_effects/motes_effect.dart`. Move `_GlitterParticle`,
      `_simulateFlock`, `_boundaryForce`, and the circle/polygon drawing from
      `glitter_background.dart` into a `MotesEffect` implementing `BackgroundEffect`.
      Do not change the flocking math or the drawing.
- [x] `reactsToCursor => true`; keep the cursor-shove behavior identical.

## 4. Host widget refactor

- [x] In `glitter_background.dart`, keep the host concerns (envelope easing, size
      capture/rescale, cursor tracking, `_resolveColors`, on/off + location + theme
      gating). Replace the inline flock/paint with delegation to the current
      `BackgroundEffect`.
- [x] Turn `_GlitterPainter` into a thin adapter that forwards `paint` to the effect.
- [x] On `build`, if `modifiers.backgroundStyle` differs from the mounted effect's
      `style`, swap the effect and clear `_seeded` so it reseeds at the next layout.
- [x] Mount the `MouseRegion` only when `effect.reactsToCursor && widget.reactToCursor`.
- [ ] Verify the default (Motes) still eases in/out with app focus and flocks exactly
      as before. (User verifies in-app.)

## 5. Starfield

- [x] Create `lib/widgets/background_effects/starfield_effect.dart`: parallax drifting
      points (bigger = faster), drift along the surface's long axis, wrap at edges,
      subtle twinkle. Density scales with area. `reactsToCursor => false`.

## 6. Nebula

- [x] Create `lib/widgets/background_effects/nebula_effect.dart`: a few large blurred
      radial-gradient blobs in theme colors, drifting on sine paths and breathing their
      alpha. `reactsToCursor => false`.
- [x] Handle the rainbow/Pride palette for both new effects (blend rainbow colors).

## 6b. Remaining brainstormed styles

- [x] Add the six styles to the `BackgroundStyle` enum (`constellation`, `embers`,
      `aurora`, `rain`, `radar`, `circuitry`) with labels; regenerate the mapper.
- [x] `constellation_effect.dart` — drifting nodes that bounce off edges, with thin
      links between near neighbors. `reactsToCursor => false`.
- [x] `embers_effect.dart` — flickering specks rising with a horizontal wobble, wrap
      at the top. `reactsToCursor => false`.
- [x] `aurora_effect.dart` — a few soft waving color curtains along the long axis;
      resolution-independent. `reactsToCursor => false`.
- [x] `rain_effect.dart` — thin falling streaks with a gradient trail, wrap at bottom.
      `reactsToCursor => false`.
- [x] `radar_effect.dart` — rotating sweep with range rings and blips that flare as the
      sweep passes; resolution-independent. `reactsToCursor => false`.
- [x] `circuitry_effect.dart` — grid-aligned traces with pulses running along them.
      `reactsToCursor => false`.
- [x] Add all six to the host's `_ensureEffect` style switch.

## 7. Settings UI

- [x] Add a `_BackgroundStylePicker` in `settings_page.dart` inside the existing
      `if (motesEnabled)` block, next to the locations and color controls. Style it like
      the neighboring controls; write via `copyWith(backgroundStyle: ...)`.
- [x] Label it "Background style" and attach a `MovingTooltipWidget.text` tooltip
      ("Which animation plays in the background.").
- [ ] Confirm the final style names and label wording with the user before finalizing.

## 8. Verify

- [x] `flutter analyze` clean (no new issues in the changed code).
- [ ] Manually switch between Motes / Starfield / Nebula and confirm each renders on the
      sidebar, toolbar, and tooltips, fades with app focus, follows the color source,
      and that switching styles at runtime reseeds cleanly. (User verifies in-app.)
