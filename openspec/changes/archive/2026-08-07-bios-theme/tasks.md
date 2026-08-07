# BiOS Theme — Tasks

- [x] Add `biPrideColors` (magenta `#D60270`, purple `#9B4F96`, blue `#0038A8`) next to `rainbowColors` in `lib/widgets/rainbow_accent_bar.dart`.
- [x] Add an optional `String? iconGradient` field to `TriOSTheme` in `lib/themes/theme.dart` — constructor, `fromHexCodes`, `copyWith`, and `toString`.
- [x] Add the same `iconGradient` field to `TriOSThemeExtension` in `lib/themes/theme.dart` — constructor, `copyWith`, and `lerp` (snap at `t < 0.5`, like `iconAsset`).
- [x] In `lib/themes/theme_manager.dart`, read `themeData["iconGradient"]` in `_loadThemes()` and pass `swatch.iconGradient` in `_buildExtension()`.
- [x] Add an `iconGradient` getter to the `TriOSBuildContextTheme` extension in `lib/utils/extensions.dart`, next to `iconAsset`.
- [x] Add `bi` to `AppIconOverride` and `biOS` to `AppNameOverride` in `lib/themes/theme_modifiers.dart`.
- [x] Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `theme_modifiers.mapper.dart`.
- [x] Turn `appNameWithModifiers` in `lib/utils/extensions.dart` into a switch that returns "HegOS" for `hegOS`, "BiOS" for `biOS`, and the theme's name otherwise.
- [x] Add a `_buildBiGradientIcon()` method to `TriOSAppIcon` in `lib/widgets/trios_app_icon.dart` — the crest under a still `ShaderMask` using `biPrideColors`, top to bottom, no animation controller.
- [x] Call it from two places in `TriOSAppIcon.build()`: the `AppIconOverride.bi` case in the modifier switch, and after the theme `iconAsset` check when `theme.iconGradient == 'bi'`. Keep `widget.color` winning over the gradient, as the rainbow path does.
- [x] Add the "BiOS" theme entry to `assets/themes.json` with the colors, `appNameOverride`, and `iconGradient` from the design.
- [x] Add `DropdownMenuEntry(value: AppIconOverride.bi, label: "Bi")` to the app icon dropdown in `_ThemeModifiersSection` (`lib/trios/settings/settings_page.dart`).
- [x] Add `DropdownMenuEntry(value: AppNameOverride.biOS, label: "BiOS")` to the app name dropdown in the same place.
- [x] Run `flutter analyze` and fix anything it reports in the touched files.
- [x] Verify (manual): pick the BiOS theme, check the colors, the app name in the sidebar and About dialog, and the gradient icon. Compare the blended gradient against hard flag bands and keep whichever looks better. Hard bands won; the purple stripe was widened to 0.4–0.65.
- [x] Verify (manual): with a different theme active, set the app icon dropdown to "Bi" and the app name dropdown to "BiOS", and confirm both take effect on their own.
- [x] Add a changelog line to `changelog.md`. (Added, then dropped by the user before committing — the theme ships without a changelog entry.)
