## Context

ThemeManager (664 lines) is the central theming class. It works well but has accumulated TriOS-specific domain logic, dead toggles, and a parallel theme construction path (PaletteGeneratorExt). The goal is to make the `lib/themes/` directory portable to a new project while preserving all current behavior in TriOS.

Current file layout:
- `lib/themes/theme_manager.dart` — ThemeManager notifier + mixed-in domain logic + utils
- `lib/themes/theme.dart` — TriOSTheme data class + TriOSThemeExtension
- `lib/themes/semantic_colors.dart` — Semantic color generation strategies

## Goals / Non-Goals

**Goals:**
- ThemeManager, TriOSTheme, TriOSThemeExtension, and semantic_colors.dart should have zero imports from TriOS domain code (mod_manager, etc.)
- Remove dead code paths and fix latent bugs
- Route all ThemeData construction through a single pipeline
- Add identity (id/displayName) to TriOSTheme for cleaner APIs

**Non-Goals:**
- Extracting into a separate package (just making it extractable)
- Changing light theme behavior or fixing light/dark asymmetry
- Changing the visual appearance of any theme
- Changing the public API of how widgets consume themes (Theme.of, ref.watch)

## Decisions

### 1. Keep utility code in theme_manager.dart

PaletteGeneratorExt, ColorSchemeExt, createMaterialColor, greyscale filter stay in theme_manager.dart. One file is simpler to move than a file + utils file.

Alternative: Split into theme_manager.dart + theme_utils.dart. Rejected — adds a file for no real benefit since they're all theme-related.

### 2. TriOS constants → `lib/trios/constants_theme.dart`

New file alongside existing `lib/trios/constants.dart`. Contains all Starsector-specific colors and layout constants currently on ThemeManager statics. References change from `ThemeManager.vanillaErrorColor` to e.g. `TriOSThemeConstants.vanillaErrorColor`.

Alternative: Add them to existing `constants.dart`. Could work, but theme constants are a distinct group and constants.dart may already be large.

### 3. showSnackBar → `lib/widgets/snackbar.dart`

Moves `showSnackBar()` function and `SnackBarType` enum. It depends on `TriOSThemeExtension` which is fine — widgets can depend on themes. The reverse (themes depending on widget helpers) was the problem.

### 4. PaletteGeneratorExt: toTriOSTheme() + static convertToThemeData

Replace `createPaletteTheme(BuildContext context)` → `ThemeData` with `toTriOSTheme(BuildContext context)` → `TriOSTheme`.

Make `convertToThemeData` a static method (it doesn't use any instance state — `_isMaterial3` is being removed, and `_buildExtension`/`_customizeTheme`/`_getDarkTheme`/`_getLightTheme` can all be static). This avoids call sites needing a ref to the ThemeManager notifier just to convert.

Call sites change from:
```dart
data: palette.createPaletteTheme(context)
```
to:
```dart
data: ThemeManager.convertToThemeData(palette.toTriOSTheme(context))
```

The `toTriOSTheme` method extracts dominant/dark/light palette colors into a TriOSTheme (~20 lines), replacing the 120-line manual ThemeData construction. Fallback colors come from the current theme via `Theme.of(context)`.

### 5. TriOSTheme identity fields

Add `final String id` and `final String displayName` to TriOSTheme. Both are required in the constructor. During JSON loading, `id` = map key, `displayName` = map key (can be overridden via JSON field later). `StarsectorTriOSTheme` gets `id: "StarsectorTriOSTheme"`, `displayName: "Starsector"`.

`switchThemes` changes from:
```dart
final themeKey = allThemes.entries.firstWhere((entry) => entry.value == theme).key;
```
to:
```dart
final themeKey = theme.id;
```

### 6. Domain logic relocation

| Function | Current location | New location |
|----------|-----------------|-------------|
| `getStateColorForDependencyText()` | theme_manager.dart (top-level) | mod_manager_logic.dart (already imported there) |
| `GameCompatibilityExt` | theme_manager.dart | mod_manager_logic.dart (GameCompatibility is defined there) |
| `ModDependencySatisfiedStateExt` | theme_manager.dart | mod_manager_logic.dart (ModDependencySatisfiedState is defined there) |

These functions reference the vanilla colors, so they'll import from `constants_theme.dart`.

### 7. themes.json additions

Add Halloween and Xmas as JSON entries. Convert the Dart color values to hex:

- Halloween: primary `#FF0000`, secondary `#FF4D00` (note: the Dart code applies `.lighter(10)` to secondary — bake the lightened value into the hex), surface `#272121`, surfaceContainer slightly lighter.
- Xmas: primary `#f23942` darkened, secondary `#70BA7F` lightened, surface dark green, surfaceContainer `#171e13` lightened.

Bake the `.darker()`/`.lighter()` adjustments into the final hex values since JSON themes don't support color transforms.

## Risks / Trade-offs

- **Palette theme visual changes** → Palette-derived themes will now go through `_customizeTheme`, which applies component-level overrides (card elevation, button styles, slider theme, etc.) that `createPaletteTheme` didn't have. This is intentionally more consistent, but is a visible change. Verify palette themes still look good after the refactor.

- **Baked color transforms for Halloween/Xmas** → The Dart classes apply `.lighter(10)`, `.darker(5)` etc. at runtime. When moving to JSON, we bake the computed hex values. If the `flutter_color` library changes its lighter/darker algorithm, the JSON values won't update. Acceptable since these are static presets.

- **Static convertToThemeData** → Making this static means it can't access instance state in the future. Currently it doesn't need to, and adding instance state to theme conversion would be a design smell anyway.
