# Tasks: Semantic Status Colors

## Implementation

- [x] Add `SemanticColorStrategy` enum and generation functions (both `fromSeed` and `tonalPalette`) in a new file `lib/themes/semantic_colors.dart`
- [x] Add `successSeed`, `warningSeed`, `infoSeed`, `neutralSeed` optional fields to `TriOSTheme`
- [x] Expand `TriOSThemeExtension` with 16 semantic color properties and `lerp()`
- [x] Update `ThemeManager._getDarkTheme` and `_getLightTheme` to generate and attach semantic colors
- [x] Parse optional seed fields in `themes.json` loading (`_loadThemes`)
- [x] Add `statusColors` convenience getter to `TriOSBuildContextTheme` extension
- [x] Migrate widget usages: snackbar colors (centralized dispatch migrated; dependency/compatibility utility functions kept on statics for non-widget contexts)
