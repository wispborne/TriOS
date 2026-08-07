# BiOS Theme — Design

## Approach

Most of this is data. A theme entry in `assets/themes.json` can already set colors, an app name, and an icon image file, and `ThemeManager._loadThemes()` reads any new key without extra plumbing on the loading side.

The one new piece of code is the gradient icon. A theme can point `iconAsset` at an image file, but there is no way to say "draw the normal crest with a gradient over it". So this adds one more optional theme field, `iconGradient`, carried the same way `iconAsset` and `appNameOverride` already are: `TriOSTheme` → `TriOSThemeExtension` → read by `TriOSAppIcon`.

## The theme entry

Added to `assets/themes.json`:

```json
"BiOS": {
  "isDark": true,
  "primary": "#D60270",
  "secondary": "#2E5BD8",
  "surface": "#17101F",
  "surfaceContainer": "#1F1329",
  "onPrimary": "#FFFFFF",
  "iconGradient": "bi",
  "appNameOverride": "BiOS",
  "infoSeed": "#0038A8",
  "successSeed": "#9B4F96"
}
```

The three flag colors are magenta `#D60270`, purple `#9B4F96`, and blue `#0038A8`. The flag blue is very dark against a dark background, so `secondary` uses a lifted version of it (`#2E5BD8`). Surfaces are near-black with a purple tint. These exact values are a starting point — check them in the running app and adjust before finishing.

## The bi color list

Add next to `rainbowColors` in `lib/widgets/rainbow_accent_bar.dart`, since that is where the shared pride color list already lives:

```dart
/// Bi pride flag colors, used by the BiOS theme's app icon.
const biPrideColors = [
  Color(0xFFD60270), // Magenta
  Color(0xFF9B4F96), // Purple
  Color(0xFF0038A8), // Blue
];
```

## The `iconGradient` field

`String?`, null by default, only value used is `"bi"`. A string rather than a bool so a second gradient can be added later without another field.

Three files carry it, each already carrying `iconAsset` in exactly the same shape:

- `lib/themes/theme.dart` — add to `TriOSTheme` (constructor, `fromHexCodes`, `copyWith`, `toString`) and to `TriOSThemeExtension` (constructor, `copyWith`, `lerp` — `lerp` uses the `t < 0.5` snap the other string fields use).
- `lib/themes/theme_manager.dart` — read `themeData["iconGradient"]` in `_loadThemes()`, pass it in `_buildExtension()`.
- `lib/utils/extensions.dart` — add an `iconGradient` getter to the `TriOSBuildContextTheme` extension, next to `iconAsset`.

## Drawing the icon

In `TriOSAppIcon.build()` (`lib/widgets/trios_app_icon.dart`), the modifier switch runs first, then theme-driven logic. Both get a bi branch:

- Modifier: `case AppIconOverride.bi:` → stop the animation controller, return the crest under a still bi gradient.
- Theme: after the existing `iconAsset` check, if `theme.iconGradient == 'bi'`, do the same.

The drawing itself reuses the rainbow icon's `ShaderMask` with `BlendMode.srcIn`, minus the animation:

```dart
Widget _buildBiGradientIcon() {
  _stopController();
  final [magenta, purple, blue] = biPrideColors;
  return _maybeBlur(
    ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [magenta, magenta, purple, purple, blue, blue],
        stops: const [0.0, 0.4, 0.4, 0.65, 0.65, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: _buildTelosSvg(color: Colors.white),
    ),
  );
}
```

The real flag's stripes are magenta over the top 40%, purple through the middle 20%, and blue over the bottom 40%. Listing each color twice, at both ends of its stripe, gives hard edges instead of a blend.

`widget.color` still wins over the gradient, same as the rainbow path — the icon is drawn in a caller-chosen flat color when one is passed.

## App name

`AppNameOverride` gains `biOS`. `appNameWithModifiers` in `lib/utils/extensions.dart` is currently a ternary for the single HegOS case; it becomes a switch:

```dart
String appNameWithModifiers(ThemeModifiers modifiers) => switch (modifiers.appNameOverride) {
  AppNameOverride.hegOS => "HegOS",
  AppNameOverride.biOS => "BiOS",
  AppNameOverride.defaultName => appName,
};
```

`AppIconOverride` gains `bi`.

Both enums are `@MappableEnum`, so `theme_modifiers.mapper.dart` has to be regenerated. Both have a `defaultValue`, so an old settings file that has never seen these values still loads.

## Settings page

`_ThemeModifiersSection` in `lib/trios/settings/settings_page.dart`:

- App icon dropdown: add `DropdownMenuEntry(value: AppIconOverride.bi, label: "Bi")` after "Hegemony".
- App name dropdown: add `DropdownMenuEntry(value: AppNameOverride.biOS, label: "BiOS")` after "HegOS".

## Files changed

| File | Change |
| --- | --- |
| `assets/themes.json` | New "BiOS" entry |
| `lib/widgets/rainbow_accent_bar.dart` | New `biPrideColors` list |
| `lib/themes/theme.dart` | `iconGradient` on `TriOSTheme` and `TriOSThemeExtension` |
| `lib/themes/theme_manager.dart` | Read and pass `iconGradient` |
| `lib/themes/theme_modifiers.dart` | `AppIconOverride.bi`, `AppNameOverride.biOS` |
| `lib/themes/theme_modifiers.mapper.dart` | Regenerated |
| `lib/widgets/trios_app_icon.dart` | Still bi gradient branch |
| `lib/utils/extensions.dart` | `iconGradient` getter; `appNameWithModifiers` switch |
| `lib/trios/settings/settings_page.dart` | Two dropdown entries |

## Rejected alternatives

- **Match on the theme id or on `appNameOverride == "BiOS"` instead of adding a field.** Shorter, but ties how the icon is drawn to a display string, and breaks silently if the theme is renamed.
- **A bool `biIcon` field.** Same size as the string field but only ever supports one gradient.
- **Reuse `rainbowAccent`.** That flag also drives scrollbars, accent bars, and the animated background, none of which should change here.
