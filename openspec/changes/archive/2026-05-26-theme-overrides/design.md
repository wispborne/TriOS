# Theme Overrides — Design

## Approach

Add a `ThemeModifiers` class that groups all theme override settings into one object. `Settings` holds a single `ThemeModifiers` field instead of loose fields — keeps things contained as more overrides get added later.

## ThemeModifiers class

New file: `lib/themes/theme_modifiers.dart`

```dart
@MappableEnum()
enum AppIconOverride { defaultIcon, pride, hegemony }

@MappableEnum()
enum AppNameOverride { defaultName, hegOS }

@MappableClass()
class ThemeModifiers with ThemeModifiersMappable {
  final AppIconOverride appIconOverride;
  final AppNameOverride appNameOverride;
  final bool rainbowLaunchIcon;

  const ThemeModifiers({
    this.appIconOverride = AppIconOverride.defaultIcon,
    this.appNameOverride = AppNameOverride.defaultName,
    this.rainbowLaunchIcon = false,
  });
}
```

- `appIconOverride`: which app icon to show. `defaultIcon` = use whatever the theme says. `pride` = rainbow telos crest. `hegemony` = hegemony crest PNG.
- `appNameOverride`: `defaultName` = use theme's name or "TriOS". `hegOS` = show "HegOS".
- `rainbowLaunchIcon`: boolean toggle for the Starsector "S" button (only two states, so a bool is fine).

## Settings changes

Add one field to `Settings` in `lib/trios/settings/settings.dart`:

```dart
@MappableField(hook: SafeDecodeHook())
final ThemeModifiers themeModifiers;
```

Default: `const ThemeModifiers()`. The `SafeDecodeHook` ensures old settings files without this field deserialize cleanly.

## Widget changes

### `TriOSAppIcon` (`lib/widgets/trios_app_icon.dart`)

Currently checks `theme.iconAsset` first (for themed icons like hegemony), then `theme.rainbowAccent` for the rainbow shader. Change to check `themeModifiers.appIconOverride` first:

- `pride` → rainbow telos crest (same as current Pride theme behavior), skipping any theme `iconAsset`.
- `hegemony` → `Image.asset("assets/images/hegemony_crest.png")`, skipping rainbow.
- `defaultIcon` → existing logic unchanged (theme `iconAsset` if present, then rainbow if theme says so, otherwise plain telos crest).

Since `TriOSAppIcon` is already a `ConsumerStatefulWidget`, it can `ref.watch` the settings provider.

### `context.appName` (`lib/utils/extensions.dart`)

Currently: `theme.appNameOverride ?? Constants.appName`.

Change to also check `themeModifiers.appNameOverride`:

```
themeModifiers.appNameOverride == AppNameOverride.hegOS
    ? "HegOS"
    : theme.appNameOverride ?? Constants.appName
```

This means the modifier wins over the theme. The extension is on `BuildContext`, so it needs access to the settings provider. Since it's not a widget, the cleanest approach is to add a helper that takes both the theme extension and the modifiers, and call it from a place with `ref` access. Alternatively, make it a top-level function or a static on `ThemeModifiers`.

**Chosen approach**: Keep `context.appName` as-is for backward compat, but add a `resolveAppName(ThemeModifiers, TriOSThemeExtension?)` top-level function in `theme_modifiers.dart`. Callers that need override-awareness use it. The `context.appName` getter can remain for places that don't care about modifiers, or be updated to call through if a convenient provider accessor exists.

Actually, simpler: since the `appName` getter is on `BuildContext`, we can't easily access Riverpod from there. Instead, change `TriOSBuildContext.appName` to also accept an optional `ThemeModifiers?` parameter — but extension getters can't take parameters.

**Simplest approach**: Add a new `appNameWithModifiers` method on `BuildContext` that takes `ThemeModifiers`, used by the few places that show the app name visually (sidebar, about page). The existing `context.appName` stays for string interpolation in messages where the override doesn't matter (error messages, tips).

### `StarsectorIcon` (`lib/launcher/launcher.dart`)

Add an optional `isRainbow` parameter. When provided, use it instead of reading `theme.rainbowAccent` internally. The parent (`LauncherButton`, a `HookConsumerWidget`) computes:

```
final isRainbow = theme.rainbowAccent || settings.themeModifiers.rainbowLaunchIcon;
```

and passes it down.

## Settings UI

Add controls in `settings_page.dart` below `_ThemeDropdownRow` (line 222) inside the "Interface" `SettingsGroup`:

1. **App icon** — `TriOSDropdownMenu<AppIconOverride>` with three entries: Default, Pride, Hegemony.
2. **App name** — `TriOSDropdownMenu<AppNameOverride>` with two entries: Default, HegOS.
3. **Rainbow launch button** — `CheckboxWithLabel` toggle.

Each control gets a `MovingTooltipWidget.text` explaining what it does.

## File changes summary

| File | Change |
|------|--------|
| `lib/themes/theme_modifiers.dart` | New — `ThemeModifiers`, `AppIconOverride`, `AppNameOverride` |
| `lib/trios/settings/settings.dart` | Add `themeModifiers` field |
| `lib/widgets/trios_app_icon.dart` | Check `appIconOverride` before theme flags |
| `lib/utils/extensions.dart` | Add `appNameWithModifiers` method |
| `lib/launcher/launcher.dart` | Add `isRainbow` param to `StarsectorIcon`; compute override in `LauncherButton` |
| `lib/trios/settings/settings_page.dart` | Add dropdown + toggle UI for modifiers |
| Generated `.mapper.dart` files | Regenerated via `build_runner` |
