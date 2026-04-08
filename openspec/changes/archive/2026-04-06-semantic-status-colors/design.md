# Design: Semantic Status Colors

## Color Roles

Each semantic role has 4 variants, mirroring how M3 handles `error`:

| Role    | Base      | On          | Container          | OnContainer          |
|---------|-----------|-------------|--------------------|----------------------|
| Success | `success` | `onSuccess` | `successContainer` | `onSuccessContainer` |
| Warning | `warning` | `onWarning` | `warningContainer` | `onWarningContainer` |
| Info    | `info`    | `onInfo`    | `infoContainer`    | `onInfoContainer`    |
| Neutral | `neutral` | `onNeutral` | `neutralContainer` | `onNeutralContainer` |

## Default Seed Colors

| Role    | Seed        | Notes                              |
|---------|-------------|------------------------------------|
| Success | `#4CAF50`   | Standard green                     |
| Warning | `#FDD818`   | Close to existing vanillaWarningColor |
| Info    | `#2196F3`   | Standard blue                      |
| Neutral | `#9E9E9E`   | Grey, de-emphasized                |

## Generation Strategies

An enum `SemanticColorStrategy` controls which algorithm produces the 4 variants from a seed:

### Strategy A: `fromSeed`

```
ColorScheme.fromSeed(seedColor: seed, brightness: brightness)
  → primary       = base
  → onPrimary     = on
  → primaryContainer    = container
  → onPrimaryContainer  = onContainer
```

Pros: Simple, perfectly M3-harmonized. Cons: Indirect, less control over exact tones.

### Strategy B: `tonalPalette` (MCU)

```
material_color_utilities: Hct.fromInt(seed) → TonalPalette.of(hue, chroma)
  Dark:  base=tone(80), on=tone(20), container=tone(30), onContainer=tone(90)
  Light: base=tone(40), on=tone(100), container=tone(90), onContainer=tone(10)
```

Pros: Direct control over tonal values, true M3 spec. Cons: More code, depends on `material_color_utilities`.

### Toggle

```dart
enum SemanticColorStrategy { fromSeed, tonalPalette }

// In theme_manager.dart or a config constant:
const _semanticColorStrategy = SemanticColorStrategy.fromSeed;
```

Change this constant to swap strategies. Both produce the same shape of output (4 Colors per role).

## Theme Extension Shape

```dart
class TriOSThemeExtension extends ThemeExtension<TriOSThemeExtension> {
  final bool rainbowAccent;

  // Semantic status colors
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  final Color neutral;
  final Color onNeutral;
  final Color neutralContainer;
  final Color onNeutralContainer;
}
```

`lerp()` uses `Color.lerp` for each field for smooth theme transitions.

## Theme Author Customization (Tier 2: Seed-Customizable)

In `themes.json`, optional fields:

```json
{
  "successSeed": "#22C55E",
  "warningSeed": "#F59E0B",
  "infoSeed": "#3B82F6",
  "neutralSeed": "#6B7280"
}
```

If omitted, defaults are used. The seed is run through whichever generation strategy is active.

`TriOSTheme` gains 4 new optional `Color?` fields: `successSeed`, `warningSeed`, `infoSeed`, `neutralSeed`.

## BuildContext Convenience

```dart
extension TriOSBuildContextTheme on BuildContext {
  bool get rainbowAccent => ...;
  TriOSThemeExtension get statusColors =>
      Theme.of(this).extension<TriOSThemeExtension>()!;
}
```

Access: `context.statusColors.success`, `context.statusColors.warningContainer`, etc.

## Migration

| Current Usage                          | New Usage                              |
|----------------------------------------|----------------------------------------|
| `ThemeManager.vanillaWarningColor`     | `context.statusColors.warning`         |
| `Colors.green` (satisfied deps)        | `context.statusColors.success`         |
| `Colors.blue` (info snackbar)          | `context.statusColors.info`            |
| `vanillaErrorColor` (keep on ColorScheme.error) | No change — M3 native       |

Note: `vanillaErrorColor` and `vanillaWarningColor` statics remain available for non-widget contexts (e.g., `getStateColorForDependencyText`) but widget code should prefer the theme extension.
