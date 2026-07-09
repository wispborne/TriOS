# Design — Background Animation Style Picker

## Context

Today `GlitterBackground` (`lib/widgets/glitter_background.dart`) is one
`ConsumerStatefulWidget` that owns everything:

- **Host concerns** (style-agnostic): the `AnimationController` + `Stopwatch`, the
  eased fade in/out envelope tied to app lifecycle (`_tick`, `_setMotion`,
  `_envelope`), canvas size capture and rescale-on-resize (`_updateSize`, `_size`,
  `_seeded`), cursor tracking (`_cursor`, the `MouseRegion`), theme-color resolution
  (`_resolveColors`), and the on/off + location + theme gating in `build`.
- **Style concerns** (motes-specific): the 300 `_GlitterParticle`s, the Boids flocking
  step (`_simulateFlock`, `_boundaryForce`), and the `_GlitterPainter` drawing.

`ThemeModifiers` (`lib/themes/theme_modifiers.dart`, `@MappableClass`) already persists
`enableGlitter`, `glitterLocations`, and `glitterThemeKey` and is read in the settings
page. `GlitterLocation` is a `@MappableEnum` right there — the model for the new enum.

## Key decision: split host from effect

Keep the host widget (`GlitterBackground`, same class + file, minimal call-site churn)
and pull the per-style motion + drawing behind a small interface:

```dart
/// Immutable per-frame inputs the host hands each effect at paint time.
class BackgroundPaintContext {
  final List<Color> colors;
  final double opacityScale;
  final bool isRainbow;      // Pride palette → polygons instead of circles (motes)
  final double elapsedSeconds;
  final double coverage;
  final double pulseRate;
}

abstract class BackgroundEffect {
  /// Style this effect implements, so the host can detect a style change.
  BackgroundStyle get style;

  /// Whether the host should mount a MouseRegion and feed the cursor.
  bool get reactsToCursor;

  /// (Re)seed internal state for a known canvas size. Called on first layout
  /// and whenever the style switches.
  void seed(Size size, Random random);

  /// Rescale seeded positions when the canvas resizes.
  void resize(Size oldSize, Size newSize);

  /// Advance one frame. [cursor] is null when the pointer is away.
  void update(double dt, double elapsedSeconds, Size size, Offset? cursor);

  /// Draw the current frame.
  void paint(Canvas canvas, Size size, BackgroundPaintContext ctx);
}
```

The host keeps its envelope/sizing/cursor/color logic verbatim, but delegates
`seed` / `resize` / `update` / `paint` to the current effect. The `CustomPainter` it
mounts becomes a thin adapter that forwards `paint` to the effect and repaints on
`elapsedSeconds` change (same `shouldRepaint` idea as today).

**Why an interface and not a `switch`:** the three styles hold different state (motes:
300 flocking particles; starfield: drifting parallax particles; nebula: a few gradient
blobs) and different per-frame math. One interface with three implementations is
cleaner than three parallel state bags + branching in the State class. Three concrete
uses justify the one abstraction.

## Model change

Add to `theme_modifiers.dart`:

```dart
@MappableEnum(defaultValue: BackgroundStyle.motes)
enum BackgroundStyle {
  motes,
  starfield,
  nebula;

  String get label => switch (this) {
    BackgroundStyle.motes => 'Motes',
    BackgroundStyle.starfield => 'Starfield',
    BackgroundStyle.nebula => 'Nebula',
  };
}
```

and a field on `ThemeModifiers`:

```dart
final BackgroundStyle backgroundStyle;
// constructor default: this.backgroundStyle = BackgroundStyle.motes,
```

Then regenerate `theme_modifiers.mapper.dart` with build_runner. The `@MappableEnum`
default makes old saved settings (no field) and unknown future values fall back to
`motes`, so persistence is backward compatible with no migration.

`backgroundStyle` is orthogonal to `enableGlitter`: the toggle is the master on/off,
the style is *which* animation. `motesEnabled(activeThemeId)` stays the single gate for
"show anything at all"; when it's true, the style picks the effect.

## Effects

### MotesEffect
The existing code, moved wholesale. `_GlitterParticle`, `_simulateFlock`,
`_boundaryForce`, and the polygon/circle drawing become this effect's internals.
`reactsToCursor => true`. **No visual change** — this is a lift-and-shift so the default
looks identical.

### StarfieldEffect
Independent particles, each with a radius and a base drift velocity; bigger particles
drift faster (parallax). Drift direction follows the surface's long axis (tall sidebar →
downward, wide toolbar → sideways) picked from the aspect ratio at seed time. Particles
that leave one edge wrap to the opposite edge. Reuse the existing shimmer/twinkle math
for a subtle brightness pulse. No neighbor loop → cheaper than motes.
`reactsToCursor => false`. Density scales with area like motes' `_activeCount`.

### NebulaEffect
A small fixed count (≈3–5) of large, soft radial-gradient blobs in the theme colors,
each drifting on layered sine paths and slowly breathing its alpha. Drawn with a blurred
radial gradient (e.g. `Paint..maskFilter = MaskFilter.blur` or a `RadialGradient`
shader), not particles. Ambient glow; very cheap. `reactsToCursor => false`.

The rainbow/Pride branch: motes already switch to spinning polygons for the rainbow
palette. Starfield can keep drawing points in rainbow colors; nebula blends the rainbow
palette across its blobs. Nothing special needed beyond passing `isRainbow` through
`BackgroundPaintContext`.

## Runtime style switch

`build` reads `modifiers.backgroundStyle`. If it differs from the mounted effect's
`style`, the State replaces the effect and clears `_seeded` so the next `_updateSize`
reseeds for the current size. The `MouseRegion` is mounted only when
`effect.reactsToCursor && widget.reactToCursor`, so starfield/nebula skip cursor work
entirely.

## Settings UI

In `settings_page.dart`, inside the existing `if (motesEnabled)` block that already
shows `_GlitterLocationsPicker` and `_GlitterColorDropdown`, add a `_BackgroundStylePicker`
(a themed dropdown or segmented `ModeSwitcher<BackgroundStyle>` over
`BackgroundStyle.values`, matching the existing controls' style). Writing it calls
`modifiers.copyWith(backgroundStyle: value)` the same way the neighbors do. Label
"Background style"; attach a `MovingTooltipWidget.text` tooltip.

## Alternatives considered

- **One `switch` in the State class, no interface.** Rejected: three different state
  shapes and update rules would bloat the State and make each style harder to read and
  test in isolation.
- **Rename everything to `AnimatedBackground` / `backgroundEnabled`.** Cleaner naming,
  but touches every call site (sidebar, toolbar, tooltip) and the settings/persistence
  keys for zero user benefit. Out of scope; keep the `glitter*` names.
- **Layering styles.** A nebula-behind-motes compositor is appealing but is a different,
  larger feature (stacking, per-layer settings). This change is pick-one.

## Risk / Compatibility

- Backward compatible: old settings without `backgroundStyle` default to `motes`, so
  existing users see no change. The motes lift-and-shift keeps the default look
  identical.
- The refactor is the main risk — the host's fade envelope and reseed-on-resize logic
  is subtle. Mitigate by moving motes into its own effect *without editing its math*,
  and verifying the default still eases and flocks exactly as before.
