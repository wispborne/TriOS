# Tasks: Mute a single update version

## 1. Data model

- [x] Add `String? mutedUpdateVersion` to `ModMetadata` in `lib/trios/mod_metadata.dart`.
- [x] In `backfillWith`, pass the user value straight through (`mutedUpdateVersion: mutedUpdateVersion`) — no `?? base`, or unmuting won't stick.
- [x] Add the `isUpdateHidden(String? remoteVersion)` method to `ModMetadata`.
- [x] Run `dart run build_runner build --delete-conflicting-outputs`.
- [x] Add `remoteVersionString` getter to `VersionCheckComparison` in `lib/mod_manager/mod_manager_logic.dart`.

## 2. Tests (write these before the UI work)

Add to `test/mod_metadata_test.dart`:

- [x] `isUpdateHidden` returns true when the remote version matches the muted one.
- [x] `isUpdateHidden` returns false when the remote version differs — this is the auto-expiry.
- [x] `isUpdateHidden` returns false when `mutedUpdateVersion` is null.
- [x] `isUpdateHidden` returns true when `areUpdatesMuted` is set, whatever the remote version.
- [x] `copyWith(mutedUpdateVersion: null)` really clears the field.
- [x] `backfillWith` keeps a cleared user value cleared.

## 3. Swap the four existing mute checks over

Each of these already reads `areUpdatesMuted` by hand. Replace with `isUpdateHidden(...)`, keeping current behaviour for permanently muted mods.

- [x] Pinned updates filter, `lib/mod_manager/mods_grid_page.dart` (~line 131).
- [x] Dashboard updates filter, `lib/dashboard/mod_list_basic.dart` (~line 524).
- [x] Update sort value, `lib/mod_manager/mod_manager_extensions.dart` (~lines 148, 159, 166).
- [x] Update icon, `lib/dashboard/version_check_icon.dart` (~line 54). Icon and tooltip done at the same time (section 5).

## 4. Context menu

Built as **one** entry rather than two, at the user's request: clicking the top level mutes just this update, and the submenu also offers muting everything.

- [x] Rework `buildMenuItemToggleMuteUpdates` in `lib/trios/context_menu_items.dart`:
  - Submenu when there's an update and a remote version number exists.
  - Clicking the top level mutes/unmutes just that update.
  - Submenu also offers "Mute all updates".
  - Falls back to the plain all-updates mute when there's no single update to pick out, or the mod is already fully muted.
  - Muting writes the remote version string; unmuting writes null.
  - No forced version-check refresh when unmuting a version — the cache is already current. Still refreshes when unmuting a fully muted mod.
- [x] Mod right-click menu, `lib/mod_manager/mod_context_menu.dart` — already calls it, no change needed.
- [x] Version-column menu, `lib/mod_manager/mods_grid_page.dart` — already calls it, no change needed.
- [x] "Recheck" stays visible for version-muted mods (it's still gated on the full mute only).

## 5. Icons and text

- [x] Use the agreed strings from the wording table in `design.md`.
- [x] Version-muted icon in `lib/dashboard/version_check_icon.dart`: `Icons.notifications_paused` plus tooltip naming the version.
- [x] Same icon and tooltip in the mods grid version column, `lib/mod_manager/mods_grid_page.dart` (~line 2053).
- [x] Mute status line in `lib/mod_manager/mod_info_dialog.dart` (~line 573) shows the muted version. Leave the update button at ~line 719 as it is.

## 6. Check it over

- [x] `flutter analyze` on the changed files adds no new problems (32 remaining are all pre-existing).
- [x] `flutter test` passes — 569 tests, including 10 new ones.
- [ ] By hand: mute a version, confirm the notice disappears from the mods grid, the dashboard, and the icon.
- [ ] By hand: confirm "show all updates" still lists the muted mod, with the paused icon.
- [ ] By hand: confirm permanent mute still behaves exactly as before.
- [ ] By hand: check how the submenu feels — clicking the top level mutes but leaves the menu open.
