# Design: Enhance Pride Theme

## Key Decisions

### 1. Self-checking wrapper widgets (Option 1)

Instead of call sites branching on `theme.rainbowAccent`, widgets check internally and render the appropriate variant. This keeps feature code theme-agnostic.

**Pattern:**

```dart
// BEFORE — caller branches
if (rainbowAccent) RainbowAccentBar(axis: Axis.vertical)

// AFTER — widget self-checks
ThemedAccentBar(axis: Axis.vertical)
// internally: reads theme.rainbowAccent, renders rainbow or nothing
```

Widgets that already self-check (like `TooltipFrame`, `TriOSAppIcon`) stay as-is. The mod version dropdown's 6 external checks get absorbed into a wrapper.

### 2. Animation lifecycle — pause in background

No existing `AppLifecycleListener` or `WidgetsBindingObserver` in the codebase. Introduce a shared Riverpod provider that tracks whether the app is in the foreground:

```
appLifecycleProvider → AppLifecycleState (resumed | paused | ...)
```

All animated pride widgets watch this provider and stop their `AnimationController` when paused. This also benefits the existing `AnimatedGradientBorder` used by the chatbot, though fixing that is out of scope.

Implementation: a single `AppLifecycleListener` (Flutter 3.13+) registered near the app root, exposed as a Riverpod provider.

### 3. Animation approach — gradient offset, not rotation

For the accent bars (A) and app icon (E), use a translating gradient offset rather than rotation. The gradient slides along its axis continuously. This feels organic ("flowing") rather than mechanical ("spinning").

Technique: animate a `GradientTransform` that shifts the gradient's start/end points. Use a doubled color list (`[...colors, ...colors]`) so the shift wraps seamlessly.

For the app icon specifically, a slow rotation of the gradient angle (not the icon itself) works well since the icon is small and roughly circular.

Cycle time: ~8-10 seconds for bars, ~6 seconds for the icon. Slow enough to be ambient.

### 4. Rainbow scrollbar (C)

Flutter's `ScrollbarThemeData` accepts `thumbColor` as a `WidgetStateProperty<Color?>`, but not a gradient. Two approaches:

- **a) Custom `ScrollBehavior`** that returns a custom `RawScrollbar` with a gradient-painted thumb. Invasive — replaces the scroll behavior app-wide.
- **b) `scrollbarTheme` with `thumbColor` cycling through rainbow colors** based on scroll position. Simpler but not a true gradient.
- **c) Theme-level `scrollbarTheme.thumbColor`** set to the theme's primary (magenta). Not a gradient, but a noticeable pride touch with zero complexity.

**Decision: start with (c)** — set `scrollbarTheme.thumbColor` to the pride primary in `ThemeManager.convertToThemeData` when `rainbowAccent` is true. If we want a true gradient thumb later, that's a follow-up. The magenta thumb against a near-black background is already distinctive and on-brand.

### 5. Rainbow progress indicators (I)

Wrap `LinearProgressIndicator` / `CircularProgressIndicator` in a `ShaderMask` with the rainbow gradient when `rainbowAccent` is true. Create a `ThemedProgressIndicator` widget that self-checks.

For indeterminate progress (the common case), the built-in animation already moves the indicator — layering a static rainbow gradient over it via `ShaderMask` produces a nice effect where the moving indicator "reveals" different rainbow colors as it slides.

### 6. Shimmer on activation (M)

A one-time `AnimationController` that runs a horizontal gradient sweep across the sidebar on mount. Triggered by:
- App startup when pride theme is active
- Theme switch to pride

Implementation: a `StatefulWidget` wrapper around the sidebar content that plays once on `initState`. Uses a `ShaderMask` with a narrow white highlight gradient that translates from left to right over ~1 second.

The shimmer should be subtle — low opacity (~0.15-0.2), narrow highlight band, quick duration.

## File Changes

### New files

| File | Purpose |
|------|---------|
| `lib/widgets/rainbow/themed_accent_bar.dart` | Self-checking animated accent bar |
| `lib/widgets/rainbow/themed_progress_indicator.dart` | Self-checking rainbow progress wrapper |
| `lib/widgets/rainbow/pride_shimmer.dart` | One-time shimmer effect |
| `lib/widgets/rainbow/rainbow_animation_mixin.dart` | Shared mixin: creates `AnimationController`, pauses in background |
| `lib/trios/app_lifecycle_provider.dart` | Riverpod provider for app foreground/background state |

### Modified files

| File | Change |
|------|--------|
| `lib/widgets/rainbow_accent_bar.dart` | Keep `rainbowColors` const and `RainbowBorder`. Remove `RainbowAccentBar` (replaced by `ThemedAccentBar`). |
| `lib/widgets/trios_app_icon.dart` | Add animation to the gradient (slow rotation). Use the shared mixin for lifecycle. |
| `lib/app_shell.dart` | Replace `if (rainbowAccent) RainbowAccentBar(...)` with `ThemedAccentBar(...)`. Add `PrideShimmer` wrapper. Remove `rainbowAccent` local variable and border toggle. |
| `lib/mod_manager/mod_version_selection_dropdown.dart` | Absorb rainbow branching into the existing `RainbowBorder` / `ConditionalWrap` pattern. Reduce the 6 external checks. |
| `lib/themes/theme_manager.dart` | Set `scrollbarTheme.thumbColor` to primary when `rainbowAccent` is true. |
| `lib/main.dart` or `lib/app_shell.dart` | Register `AppLifecycleListener` and feed the provider. |

### Untouched

- `lib/widgets/tooltip_frame.dart` — already self-checks, no change needed
- `lib/themes/theme.dart` — no schema changes
- `assets/themes.json` — no color changes
