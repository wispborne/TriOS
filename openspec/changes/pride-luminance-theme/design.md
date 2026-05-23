# Design: Pride Luminance Theme

## Theme Colors

New entry in `assets/themes.json`:

```json
"Pride Luminance": {
  "isDark": true,
  "primary": "#FF2D78",
  "secondary": "#B24DFF",
  "surface": "#0A0A0A",
  "surfaceContainer": "#050505",
  "onPrimary": "#FFFFFF",
  "onSecondary": "#FFFFFF",
  "rainbowAccent": true,
  "luminanceAccent": true
}
```

Deep black backgrounds with a vivid hot pink primary. `rainbowAccent: true` enables existing shared rainbow behaviors (scrollbar tinting, progress indicator gradients, app icon gradient). `luminanceAccent: true` switches the accent bar to the new luminance rendering.

## Luminance Color Palette

Defined in `rainbow_accent_bar.dart` alongside the existing `rainbowColors`:

```dart
const luminanceColors = [
  Color(0xFFFF1493), // Deep pink
  Color(0xFFFF6B35), // Vivid orange
  Color(0xFFFFD700), // Gold
  Color(0xFF00E676), // Vivid green
  Color(0xFF00B0FF), // Light blue
  Color(0xFF7C4DFF), // Vivid purple
];
```

These are brighter/more neon than the standard `rainbowColors` to match the luminance glow aesthetic.

## Model Changes

### `TriOSTheme` (`lib/themes/theme.dart`)

Add `luminanceAccent` boolean field (default `false`), following the same pattern as `rainbowAccent`.

### `TriOSThemeExtension` (`lib/themes/theme.dart`)

Add `luminanceAccent` boolean field. Wire through `copyWith` and `lerp`.

### `ThemeManager` (`lib/themes/theme_manager.dart`)

- Parse `luminanceAccent` from JSON in `_loadThemes()`.
- Pass it through `_buildExtension()` into the extension.
- Add a `luminanceAccent` getter on the `ThemeData` extension (in `extensions.dart`), same pattern as `rainbowAccent`.

## Accent Bar Changes

### `ThemedAccentBar` (`lib/widgets/rainbow/themed_accent_bar.dart`)

In `build()`, after the existing `rainbowAccent` check, branch on `luminanceAccent`:
- If `luminanceAccent`: render `_LuminanceGradientPainter` instead of `_FlowingGradientPainter`.
- Otherwise: existing behavior.

### `_LuminanceGradientPainter` (new, same file)

A `CustomPainter` that draws vertical glowing ribbons:

1. Divide the bar width into segments (one per color in `luminanceColors`).
2. For each segment, draw:
   - A wider, blurred rectangle at ~20% opacity (the glow/bloom).
   - A narrower, solid rectangle at full opacity (the ribbon core).
3. The animation drives a subtle intensity pulse (breathing effect): opacity oscillates between ~0.7 and 1.0 using a sine wave derived from the animation progress.
4. A slight horizontal drift (ribbons shift left/right slowly) for gentle motion.

The glow effect uses `MaskFilter.blur(BlurStyle.normal, sigma)` on the paint for the wider background pass, creating a soft bloom without needing `BackdropFilter` or `ImageFilter` (which would be heavier).

## File Changes Summary

| File | Change |
|------|--------|
| `assets/themes.json` | Add "Pride Luminance" entry |
| `lib/themes/theme.dart` | Add `luminanceAccent` field to `TriOSTheme` and `TriOSThemeExtension` |
| `lib/themes/theme_manager.dart` | Parse and wire `luminanceAccent` |
| `lib/utils/extensions.dart` | Add `luminanceAccent` getter on `ThemeData` |
| `lib/widgets/rainbow_accent_bar.dart` | Add `luminanceColors` palette |
| `lib/widgets/rainbow/themed_accent_bar.dart` | Add `_LuminanceGradientPainter`, branch in `build()` |

## Key Decisions

1. **Separate boolean vs. enum**: Using a separate `luminanceAccent` boolean rather than refactoring `rainbowAccent` into an enum. This is additive -- no changes to existing themes or behavior. If more accent styles are added later, these can be consolidated into an enum then.

2. **Glow via MaskFilter**: Using `Paint.maskFilter` with blur for the glow effect rather than `BackdropFilter` or stacking blurred widgets. This keeps the effect entirely within the `CustomPainter` and avoids performance overhead from raster cache invalidation.

3. **Reusing rainbowAccent**: The new theme sets both `rainbowAccent: true` and `luminanceAccent: true`. This means scrollbar tinting, progress indicator gradients, and app icon effects all work without any additional code. Only the accent bar rendering differs.
