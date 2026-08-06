# Tasks

## The shared pieces

- [x] Add `DownloadTarget` in `lib/trios/download_manager/download_target.dart`,
      holding mod id, URL, catalog name and display name.
- [x] Write the matching function: does this `Download` match this target?
      Order: mod id, URL (normalised with `fixModDownloadUrl()`), catalog name,
      display name. Names compared without case or surrounding spaces.
- [x] Add `findActiveDownload(downloads, target)` — the first in-progress
      download matching the target. A plain function, not a `Provider.family`,
      which would keep an entry alive per mod row.
- [x] Add `pendingDownloadClicks` — a `Notifier` holding the set of targets
      clicked but not yet seen as downloads, with `markClicked(target)` and
      `clear(target)`.
- [x] Clear a pending click when a matching download appears, when
      `deepLinkProcessing` goes from true to false, and after 10 seconds.
- [x] Add `ModDownloadStatus` (phase, progress ratio or null, message) and
      `ModDownloadStatusBuilder` in
      `lib/widgets/mod_download/mod_download_status.dart`. Watch
      `downloadManager` for *which* download; use `ListenableBuilder` for the
      numbers.
- [x] Add `ModDownloadButton` in
      `lib/widgets/mod_download/mod_download_button.dart`: target, idle icon,
      label, button style, `onPressed`. Shows the spinner in place of the icon,
      blocks clicks while busy, sets the tooltip, and marks the pending click
      itself so its target always matches what it watches.

## Convert the buttons

- [x] Catalog card (`catalog_mod_card.dart`): deleted `_clickBusy`,
      `_busyFallback`, `dispose`, the two `ref.listen` blocks and the
      `firstWhereOrNull` lookup; the whole widget dropped from
      `ConsumerStatefulWidget` to `ConsumerWidget`. The tie-break chooser
      passes `markPendingOnPress: false` (opening a menu isn't a download);
      its menu items mark the click themselves.
- [x] Forum post header (`forum_post_header.dart`): `_DownloadSplitButton` is
      now a `ConsumerWidget` built on `ModDownloadButton`, keeping the ▾ menu.
      It builds the row's target itself from the mod name and main candidate —
      no need to thread one down from the dialogs.
- [x] Catalog details dialog and forum post dialog: no change needed, since the
      split button owns the target.
- [x] Dashboard mod list (`mod_list_basic_entry.dart`): replaced the inline
      lookup and `ListenableBuilder` with `ModDownloadStatusBuilder`.
- [x] Mods grid update icon (`mods_grid_page.dart`): same.
- [x] Mods grid missing-dependency buttons (`mods_grid_page.dart`): wrapped in
      `ModDownloadStatusBuilder` so they show progress for the first time. They
      keep their `OutlinedButton` + `TextWithIcon` layout rather than being
      forced into `ModDownloadButton`.
- [x] Mod info dialog (`mod_info_dialog.dart`): replaced the Update button block
      with `ModDownloadButton`.

## Finish up

- [x] Grep for `installProgress`, `task.status` and `task.downloaded` outside the
      shared files, the activity panel, the toolbar icon and toasts — none left.
- [x] Remove imports and helpers left unused by the conversions
      (`dart:async` in the catalog card, `version_checker.dart` in the mods
      grid, `download_status.dart` in three files).
- [x] `fvm flutter analyze lib` — no errors. Remaining warnings are all
      pre-existing.
- [x] `fvm flutter test` — 614 tests pass.
- [ ] Check by hand: start an update from the dashboard and confirm the catalog
      card for the same mod shows progress too.
- [ ] Check by hand: click Install in the catalog details dialog and the forum
      post dialog, including a TriOS deep link, and confirm the button shows
      busy right away and stays busy through install.
- [ ] Check by hand: a background download doesn't make the mod grid flicker or
      rebuild on every progress tick.
