## ADDED Requirements

### Requirement: ThemeManager has no app-domain imports
ThemeManager, TriOSTheme, TriOSThemeExtension, and semantic_colors.dart SHALL NOT import any code from outside `lib/themes/`, Flutter SDK, or declared theme-related pub dependencies (flutter_color, google_fonts, palette_generator, material_color_utilities, dart_mappable, flutter_riverpod).

#### Scenario: No domain imports in theme files
- **WHEN** inspecting imports in all files under `lib/themes/`
- **THEN** no import references `mod_manager`, `trios/settings`, or any other app-specific module except through a settings abstraction (the theme key persistence callback)

### Requirement: TriOSTheme carries identity
TriOSTheme SHALL have `id` (String) and `displayName` (String) fields that identify the theme without requiring an external map lookup.

#### Scenario: Theme loaded from JSON
- **WHEN** a theme is loaded from `assets/themes.json` with key "AlexAtheos"
- **THEN** the resulting TriOSTheme has `id == "AlexAtheos"` and `displayName == "AlexAtheos"`

#### Scenario: Theme switching uses id directly
- **WHEN** `switchThemes` is called with a TriOSTheme
- **THEN** the theme key is obtained from `theme.id` without iterating `allThemes`

#### Scenario: Fallback theme has identity
- **WHEN** StarsectorTriOSTheme is constructed
- **THEN** it has `id == "StarsectorTriOSTheme"` and a displayName

### Requirement: Hardcoded preset themes are minimal
Only the fallback theme (StarsectorTriOSTheme) SHALL be a hardcoded Dart class. All other preset themes (Halloween, Xmas) SHALL be defined in `assets/themes.json`.

#### Scenario: Halloween theme in JSON
- **WHEN** `assets/themes.json` is loaded
- **THEN** it contains an entry for the Halloween theme with equivalent colors to the former `HalloweenTriOSTheme` class

#### Scenario: Xmas theme in JSON
- **WHEN** `assets/themes.json` is loaded
- **THEN** it contains an entry for the Xmas theme with equivalent colors to the former `XmasTriOSTheme` class

#### Scenario: Only one hardcoded theme class exists
- **WHEN** searching `lib/themes/` for classes extending TriOSTheme
- **THEN** only `StarsectorTriOSTheme` is found

### Requirement: Single theme construction pipeline
All ThemeData construction SHALL go through `convertToThemeData`, including palette-derived themes. There SHALL NOT be a parallel ThemeData construction path.

#### Scenario: Palette-derived theme uses normal pipeline
- **WHEN** `PaletteGeneratorExt.toTriOSTheme()` produces a TriOSTheme from an image palette
- **THEN** callers pass it to `ThemeManager.convertToThemeData()` to get ThemeData

#### Scenario: Palette themes get semantic colors
- **WHEN** a palette-derived ThemeData is created via the normal pipeline
- **THEN** it includes a `TriOSThemeExtension` with generated semantic colors

### Requirement: convertToThemeData is static
`convertToThemeData` SHALL be a static method on ThemeManager, callable without a notifier reference.

#### Scenario: Static call from widget
- **WHEN** a widget needs to convert a TriOSTheme to ThemeData
- **THEN** it calls `ThemeManager.convertToThemeData(theme)` without needing `ref`

### Requirement: No dead toggles
The `_isMaterial3` constant SHALL be removed. Material 3 SHALL be unconditionally enabled.

#### Scenario: ThemeData uses Material 3
- **WHEN** any ThemeData is constructed
- **THEN** `useMaterial3: true` is set directly without a conditional

### Requirement: App-specific constants are separate
Starsector-specific color constants (`vanillaErrorColor`, `vanillaWarningColor`, `vanillaCyanColor`, `vanillaYellowGoldColor`) and layout constants (`orbitron`, `iconOpacity`, `iconButtonOpacity`, `boxShadow`, `cornerRadius`) SHALL NOT be defined on ThemeManager.

#### Scenario: Constants in dedicated file
- **WHEN** app code needs `vanillaErrorColor`
- **THEN** it imports from `lib/trios/constants_theme.dart`, not from ThemeManager

### Requirement: showSnackBar is not in theme_manager.dart
`showSnackBar()` and `SnackBarType` SHALL be defined in a widget utility file, not in theme_manager.dart.

#### Scenario: showSnackBar location
- **WHEN** code calls `showSnackBar()`
- **THEN** it imports from `lib/widgets/snackbar.dart`

### Requirement: Domain color extensions are not in theme files
`getStateColorForDependencyText()`, `GameCompatibilityExt`, and `ModDependencySatisfiedStateExt` SHALL be defined alongside their respective domain types, not in theme_manager.dart.

#### Scenario: GameCompatibilityExt location
- **WHEN** code uses `GameCompatibility.getGameCompatibilityColor()`
- **THEN** the extension is defined in the same file as `GameCompatibility`

### Requirement: _parseColor handles 8-char hex safely
`TriOSTheme._parseColor` SHALL use bitwise OR (`|`) to set the alpha channel, not XOR (`^`), so that 8-character hex strings with an alpha prefix are handled correctly.

#### Scenario: 6-char hex input
- **WHEN** `_parseColor("#FF0000")` is called
- **THEN** it returns `Color(0xFFFF0000)` (fully opaque red)

#### Scenario: 8-char hex input with alpha
- **WHEN** `_parseColor("#80FF0000")` is called
- **THEN** it returns `Color(0xFFFF0000)` (alpha forced to FF via OR), not a corrupted value from XOR
