# Design: Mute a single update version

## Approach

Store the muted version number on the mod's metadata. Everywhere that currently asks "are this mod's updates muted?", ask instead "is this mod's update hidden?" — which is true if the mod is permanently muted, or if the version being advertised right now matches the muted one.

Nothing about how or when version checks run changes.

## Data model

One new field on `ModMetadata` ([lib/trios/mod_metadata.dart:233](lib/trios/mod_metadata.dart:233)):

```dart
/// The remote version the user chose to ignore, e.g. "1.5.0".
/// Null means no version is muted. Clears itself in effect once the
/// remote version-checker file advertises a different number.
final String? mutedUpdateVersion;
```

It holds `VersionObject.toString()` of the remote version — that is `[major, minor, patch].nonNulls.join(".")`, exactly the text the user sees in the UI. Plain string equality is the test; no version parsing.

Two details worth knowing before writing the code:

**Clearing it works.** dart_mappable generates a `$none` sentinel for nullable fields, so `copyWith(mutedUpdateVersion: null)` really does clear it (see the generated `color` handling at [mod_metadata.mapper.dart:368](lib/trios/mod_metadata.mapper.dart:368)). Non-nullable fields like `areUpdatesMuted` use `if (x != null)` instead, where null just means "leave alone". Nullable is the behaviour we want here.

**In `backfillWith`, take the user value outright** — write `mutedUpdateVersion: mutedUpdateVersion`, not `mutedUpdateVersion ?? base.mutedUpdateVersion`. This field is only ever written by the user, and `??` would mean an unmute silently falls back to whatever the base layer held.

Unrelated, but you'll see it while editing: line 278 already has `areUpdatesMuted ?? base.areUpdatesMuted` on a non-nullable `bool`, so the `??` never runs. Leave it alone; it's pre-existing and harmless.

Changing this class means running:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## The one shared check

The "is this muted?" test is currently hand-written in four places. Rather than write the new condition four more times, add one method to `ModMetadata`:

```dart
/// Whether an update to [remoteVersion] should be hidden from the user.
bool isUpdateHidden(String? remoteVersion) =>
    areUpdatesMuted ||
    (mutedUpdateVersion != null && mutedUpdateVersion == remoteVersion);
```

It takes no Riverpod ref and touches no widgets, so it's easy to unit test.

To save every caller repeating the same chain, add a getter to `VersionCheckComparison` ([mod_manager_logic.dart:1084](lib/mod_manager/mod_manager_logic.dart:1084)):

```dart
String? get remoteVersionString =>
    remoteVersionCheck?.remoteVersion?.modVersion?.toString();
```

Callers then read `metadata.isUpdateHidden(comparison.remoteVersionString)`. All four sites already have the comparison in hand.

## Key decisions

### Version checks keep running

The permanent mute drops muted mods from the check list before any network request ([version_checker.dart:87](lib/mod_manager/version_checker.dart:87)). A version mute must **not** do that — we need the remote version on every check to know whether the mute still applies. **No change to `version_checker.dart` at all.**

A side effect: the mute lifts on its own within one check cycle of the author fixing things. The cooldown is 60 minutes ([version_checker.dart:48](lib/mod_manager/version_checker.dart:48)), and "Recheck" forces it immediately.

### Unmuting needs no forced refresh

Unmuting a permanent mute fires `refresh(skipCache: true, evenIfMuted: true)` because checks had stopped and the cached result is stale ([context_menu_items.dart:489](lib/trios/context_menu_items.dart:489)). Unmuting a version doesn't need any of that — checks never stopped, so the cache is already current. Just clear the field.

### Permanent mute wins

If `areUpdatesMuted` is true the mod is fully muted, whatever `mutedUpdateVersion` says. The `isUpdateHidden` short-circuit above handles this. The menu drops the per-version option entirely when a mod is permanently muted, since it would do nothing.

### No new settings

`ModsGridUpdateVisibility.showUnmuted` and `DashboardGridModUpdateVisibility.hideMuted` keep their meaning — a version-muted mod counts as muted. No new enum values, no settings migration.

### "Recheck" stays available

The version column hides its "Recheck" item when a mod is permanently muted ([mods_grid_page.dart:1952](lib/mod_manager/mods_grid_page.dart:1952)). Keep it visible for a version-muted mod: it's how a user confirms the author has pushed a fix.

## Files that change

| File | What changes |
|---|---|
| [lib/trios/mod_metadata.dart](lib/trios/mod_metadata.dart) | New field, `backfillWith` line, `isUpdateHidden` method. |
| [lib/mod_manager/mod_manager_logic.dart](lib/mod_manager/mod_manager_logic.dart) | `remoteVersionString` getter on `VersionCheckComparison`. |
| [lib/trios/context_menu_items.dart](lib/trios/context_menu_items.dart) | Rework `buildMenuItemToggleMuteUpdates` into the one combined entry. |
| [lib/mod_manager/mod_context_menu.dart](lib/mod_manager/mod_context_menu.dart) | No change needed — it already calls the combined entry. |
| [lib/mod_manager/mods_grid_page.dart](lib/mod_manager/mods_grid_page.dart) | Pinned-updates filter (line ~131), version-column icon (~2053), menu (~1952, ~1967). |
| [lib/dashboard/mod_list_basic.dart](lib/dashboard/mod_list_basic.dart) | Dashboard updates filter (line ~524). |
| [lib/dashboard/version_check_icon.dart](lib/dashboard/version_check_icon.dart) | Icon and tooltip (line ~54). |
| [lib/mod_manager/mod_manager_extensions.dart](lib/mod_manager/mod_manager_extensions.dart) | Update sort value (lines ~148, ~159, ~166). |
| [lib/mod_manager/mod_info_dialog.dart](lib/mod_manager/mod_info_dialog.dart) | Mute status line only (~573). Leave the update button at ~719 alone. |

Deliberately untouched: `version_checker.dart`, everything under `catalog/` and `chatbot/`, and `version_check_text_readout.dart`. These already ignore the existing mute; bringing them in line is separate work.

## UI

**One menu entry, not two.** `buildMenuItemToggleMuteUpdates` stays the single place updates get muted. What it shows depends on the mod:

| Mod's state | What the entry is |
|---|---|
| An update is being advertised | A submenu. Clicking the top level mutes just that update. The submenu holds the same option plus "Mute all updates". |
| That update is already muted | The same submenu, with the top level flipped to unmute. |
| No single update to pick out | A plain "Mute updates" — what it does today. |
| Already fully muted | A plain "Unmute updates" — what it does today. |

Clicking a submenu parent runs its action *and* opens the submenu, so the menu stays open after muting instead of closing. That's the library's behaviour: [context_menu_item.dart:79](lib/thirdparty/flutter_context_menu/core/models/context_menu_item.dart:79) calls `onSelected` for submenu parents too.

**Icon.** `Icons.notifications_paused` for a version mute, so it reads differently from permanent mute's `Icons.notifications_off`. Same size and muted colour as the existing one.

### Wording

| Where | Text |
|---|---|
| Menu, update not muted | `Mute only this update (1.5.0)` |
| Menu, update muted | `Unmute only this update (1.5.0)` |
| Submenu, second option | `Mute all updates` |
| Menu, nothing to single out | `Mute updates` / `Unmute updates` |
| Icon tooltip | `Update 1.5.0 is muted. You'll be notified for the next version.` |
| Mod info dialog | `Updates: 1.5.0 muted` |

Merging the two entries changed the old labels from `Mute Updates` / `Unmute Updates` to sentence case, so the whole entry reads consistently.

The dialog line follows the existing `Updates: Muted` / `Updates: Unmuted` pattern already at [mod_info_dialog.dart:573](lib/mod_manager/mod_info_dialog.dart:573).
