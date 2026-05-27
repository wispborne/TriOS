# Theme Overrides — Tasks

- [x] Create `lib/themes/theme_modifiers.dart` with `AppIconOverride` enum (`defaultIcon`, `pride`, `hegemony`), `AppNameOverride` enum (`defaultName`, `hegOS`), and `ThemeModifiers` `@MappableClass` containing `appIconOverride`, `appNameOverride`, and `rainbowLaunchIcon` fields with defaults.
- [x] Add `themeModifiers` field (type `ThemeModifiers`, default `const ThemeModifiers()`, with `SafeDecodeHook`) to `Settings` in `lib/trios/settings/settings.dart`.
- [x] Run `dart run build_runner build --delete-conflicting-outputs` to generate mapper files.
- [x] In `TriOSAppIcon` (`lib/widgets/trios_app_icon.dart`): watch the settings provider. If `appIconOverride` is `pride`, show rainbow telos crest (skip theme `iconAsset`). If `hegemony`, show `assets/images/hegemony_crest.png` (skip rainbow). If `defaultIcon`, use existing theme-driven logic unchanged.
- [x] Add `appNameWithModifiers(ThemeModifiers modifiers)` method to `TriOSBuildContext` in `lib/utils/extensions.dart`. Returns "HegOS" if modifier is `hegOS`, otherwise falls through to existing `appNameOverride ?? Constants.appName` logic.
- [x] Update visual app-name display sites (sidebar brand header, about page) to use `appNameWithModifiers`. Leave string-interpolation sites (error messages, tips) using existing `context.appName`.
- [x] Add an `isRainbow` parameter to `StarsectorIcon` (`lib/launcher/launcher.dart`). When provided, use it instead of `theme.rainbowAccent`. Default to null (existing behavior).
- [x] In `LauncherButton` (same file): watch settings, compute `isRainbow = theme.rainbowAccent || settings.themeModifiers.rainbowLaunchIcon`, pass to `StarsectorIcon`.
- [x] Add modifier controls in `settings_page.dart` below `_ThemeDropdownRow` inside the "Interface" `SettingsGroup`: a `TriOSDropdownMenu<AppIconOverride>` (Default / Pride / Hegemony), a `TriOSDropdownMenu<AppNameOverride>` (Default / HegOS), and a `CheckboxWithLabel` for rainbow launch button. Each with a `MovingTooltipWidget.text`.
- [ ] Verify (manual): toggle each modifier, confirm the app icon, app name, and launch button update live.
