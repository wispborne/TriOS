# Tasks: Pride Luminance Theme

- [ ] Add `luminanceAccent` boolean field to `TriOSTheme` (constructor, `fromHexCodes`, `copyWith`, `toString`)
- [ ] Add `luminanceAccent` boolean field to `TriOSThemeExtension` (`copyWith`, `lerp`)
- [ ] Wire `luminanceAccent` through `ThemeManager`: parse from JSON in `_loadThemes()`, pass through `_buildExtension()`
- [ ] Add `luminanceAccent` getter to the `ThemeData` extension in `extensions.dart`
- [ ] Add `luminanceColors` palette to `rainbow_accent_bar.dart`
- [ ] Create `_LuminanceGradientPainter` in `themed_accent_bar.dart` with glowing vertical ribbons and breathing animation
- [ ] Update `ThemedAccentBar.build()` to branch on `luminanceAccent` and use the new painter
- [ ] Add "Pride Luminance" entry to `assets/themes.json`
- [ ] Visually verify the theme in the app (accent bar glow, scrollbar tinting, progress indicators)
