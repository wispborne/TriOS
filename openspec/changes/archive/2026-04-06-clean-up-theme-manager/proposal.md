## Why

ThemeManager is tightly coupled to TriOS domain logic (mod dependency colors, game compatibility states, Starsector-specific color constants) making it impossible to reuse in another project without importing the entire mod management system. It also contains dead code paths, duplicated theme construction logic, and missing identity metadata on themes.

## What Changes

- Remove TriOS domain logic from theme_manager.dart: `getStateColorForDependencyText()`, `GameCompatibilityExt`, `ModDependencySatisfiedStateExt` relocate to their respective domain files.
- Move TriOS-specific constants (`vanillaErrorColor`, `vanillaWarningColor`, `vanillaCyanColor`, `vanillaYellowGoldColor`, `orbitron`, `iconOpacity`, `iconButtonOpacity`, `boxShadow`, `cornerRadius`) to a new app-specific constants file.
- Move `showSnackBar()` and `SnackBarType` to a widget utility file.
- Remove dead `_isMaterial3` toggle (always true, never flipped).
- Fix semantic color strategy mismatch: `_buildExtension` hardcodes `.tonalPalette` but the declared constant is `.fromSeed`. Remove the hardcoding so the constant is respected.
- Refactor `PaletteGeneratorExt.createPaletteTheme()` to produce a `TriOSTheme` instead of building `ThemeData` from scratch, then route through the normal `convertToThemeData` pipeline.
- Move `HalloweenTriOSTheme` and `XmasTriOSTheme` into `assets/themes.json`; keep `StarsectorTriOSTheme` as the hardcoded fallback.
- Add `id` and `displayName` fields to `TriOSTheme`, eliminating reverse-lookups in `switchThemes`.
- Fix `_parseColor` XOR bug (`^` → `|`) for safe 8-char hex input.

## Capabilities

### New Capabilities

- `reusable-theme-manager`: Decoupling ThemeManager from TriOS domain concerns so it can be dropped into any Flutter project with minimal adaptation.

### Modified Capabilities

- `semantic-color-extension`: Fix strategy mismatch where `_buildExtension` ignores the declared `semanticColorStrategy` constant.

## Impact

- **Core theme files**: theme_manager.dart (major), theme.dart (moderate), semantic_colors.dart (unchanged)
- **New files**: `lib/trios/constants_theme.dart`, `lib/widgets/snackbar.dart`
- **Asset changes**: `assets/themes.json` gains Halloween and Xmas entries
- **Relocated domain logic**: references to `ThemeManager.vanillaErrorColor` etc. update across ~20+ files
- **Palette call sites**: 6 files updated to use new `toTriOSTheme()` + `convertToThemeData()` flow
- **Settings page**: theme selector updated for new `id`/`displayName` fields on TriOSTheme
- **No breaking changes to end users**: all changes are internal refactoring
