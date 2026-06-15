## 1. TriOSTheme Identity

- [x] 1.1 Add `id` and `displayName` fields to TriOSTheme constructor and copyWith
- [x] 1.2 Fix `_parseColor` to use `|` instead of `^` for alpha channel
- [x] 1.3 Update `StarsectorTriOSTheme` to pass id and displayName
- [x] 1.4 Update `_loadThemes` to pass map key as id/displayName when constructing from JSON
- [x] 1.5 Update `switchThemes` to use `theme.id` instead of reverse-lookup

## 2. Remove Dead Toggle

- [x] 2.1 Remove `_isMaterial3` constant from ThemeManager
- [x] 2.2 Remove the `material3` parameter from `_getDarkTheme` and `_getLightTheme`
- [x] 2.3 Inline `useMaterial3: true` in both methods

## 3. Fix Semantic Color Strategy

- [x] 3.1 Remove the hardcoded `strategy: .tonalPalette` from `_buildExtension` call to `generateAllSemanticColors`

## 4. Move Preset Themes to JSON

- [x] 4.1 Compute final hex values for HalloweenTriOSTheme colors (bake .lighter/.darker)
- [x] 4.2 Compute final hex values for XmasTriOSTheme colors (bake .lighter/.darker)
- [x] 4.3 Add Halloween and Xmas entries to assets/themes.json
- [x] 4.4 Delete HalloweenTriOSTheme and XmasTriOSTheme classes from theme_manager.dart
- [x] 4.5 Remove them from the hardcoded map in `_loadThemes`

## 5. Extract App-Specific Constants

- [x] 5.1 Create `lib/trios/constants_theme.dart` with all Starsector-specific constants (vanillaErrorColor, vanillaWarningColor, vanillaCyanColor, vanillaYellowGoldColor, orbitron, iconOpacity, iconButtonOpacity, boxShadow, cornerRadius)
- [x] 5.2 Remove those constants from ThemeManager
- [x] 5.3 Update all references across the codebase to import from constants_theme.dart

## 6. Relocate Domain Logic

- [x] 6.1 Move `getStateColorForDependencyText()` to mod_manager_logic.dart
- [x] 6.2 Move `GameCompatibilityExt` to mod_manager_logic.dart
- [x] 6.3 Move `ModDependencySatisfiedStateExt` to mod_manager_logic.dart
- [x] 6.4 Update imports in all files that reference these

## 7. Move showSnackBar

- [x] 7.1 Create `lib/widgets/snackbar.dart` with `showSnackBar()` and `SnackBarType`
- [x] 7.2 Remove from theme_manager.dart
- [x] 7.3 Update imports in all callers

## 8. Refactor PaletteGeneratorExt

- [x] 8.1 Make `convertToThemeData`, `_getDarkTheme`, `_getLightTheme`, `_customizeTheme`, `_buildExtension` static methods
- [x] 8.2 Replace `createPaletteTheme()` with `toTriOSTheme()` that returns a TriOSTheme (~20 lines extracting palette colors)
- [x] 8.3 Update call site: `lib/dashboard/mod_list_basic_entry.dart`
- [x] 8.4 Update call site: `lib/mod_manager/mods_grid_page.dart`
- [x] 8.5 Update call site: `lib/mod_manager/mod_summary_panel.dart`
- [x] 8.6 Update call site: `lib/widgets/fancy_mod_tooltip_header.dart`
- [x] 8.7 Update call site: `lib/trios/toasts/mod_download_toast.dart`
- [x] 8.8 Update call site: `lib/trios/toasts/widgets/mod_download_group_toast.dart`

## 9. Verify

- [x] 9.1 Run `dart run build_runner build --delete-conflicting-outputs` (ThemeState uses dart_mappable)
- [x] 9.2 Run `dart analyze` — zero errors in lib/themes/ (and zero errors in full lib/)
- [x] 9.3 Verify lib/themes/ has no imports from app domain code (only remaining: app_settings_logic for theme persistence, constants_theme for error color)
