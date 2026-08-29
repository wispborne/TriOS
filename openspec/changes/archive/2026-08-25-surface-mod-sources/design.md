# Design: Surface mod sources

## What exists

- `ModRecord` (`lib/mod_records/mod_record.dart:14-40`): per-mod, holds `sources` (auto-collected) and `userOverrides` (user-typed, wins field by field via `_computeResolvedSources`, `mod_record.dart:56-86`).
- Source types in `lib/mod_records/mod_record_source.dart`: `InstalledSource`, `VersionCheckerSource`, `CatalogSource`, `DownloadHistorySource` (`lastDownloadedFrom`, `lastDownloadedAt`), `ForumDataSource`.
- The Mod Sources dialog (`lib/mod_records/mod_record_sources_dialog.dart`) already edits Version Checker and Catalog fields as overrides, saving only values that differ from the automatic ones (`_diffField`, `:173-177`). Download History renders read-only (`:488-527`) — no controllers wired.
- The mod details dialog builds link buttons from `versionCheckerInfo` and the live catalog entry directly (`lib/mod_manager/mod_info_dialog.dart:240-292`), bypassing `ModRecord` entirely.
- The menu entry lives at right-click → Troubleshoot… → "Mod Sources" (`lib/trios/context_menu_items.dart:384-392`).
- Separate from all this: the per-version download address (`ModVariantMetadata.downloadedFrom`, `lib/trios/mod_metadata.dart:313`) used by Redownload. Untouched by this change.

## Changes

### 1. Editable "Downloaded from"

In the Mod Sources dialog, give the Download History section an editable URL field like the Version Checker/Catalog sections have: a controller for `lastDownloadedFrom`, saved as a `DownloadHistorySource` override only when it differs from the automatic value (same `_diffField` pattern). `lastDownloadedAt` stays read-only. If `ModRecord` lacks a typed accessor for the resolved downloaded-from value, add one next to `forumThreadId` / `nexusModsId` (`mod_record.dart:134-139`).

The override holds whatever URL the user pastes — a Discord message link, a forum post, a Google Drive folder. No validation beyond "looks like a URL".

### 2. Details dialog reads the resolved record

Rework `mod_info_dialog.dart:240-292` so each link button's URL comes from the resolved `ModRecord` (auto + overrides) instead of raw `versionCheckerInfo` / catalog data. Behavior is unchanged for mods without overrides — the resolved value is the automatic value. Add a "Downloaded from" button when the resolved record has one. Keep the existing icons/order; the new button needs a tooltip like the others.

### 3. Promote the menu entry

Move the "Mod Sources" item from the Troubleshoot… submenu (`context_menu_items.dart:384-392`) to the top level of the mod right-click menu, near the other information items. Label: "Mod Sources…".

## Files that change

- `lib/mod_records/mod_record_sources_dialog.dart` — Download History editor.
- `lib/mod_records/mod_record.dart` — typed accessor for downloaded-from, if missing.
- `lib/mod_manager/mod_info_dialog.dart` — link buttons read the resolved record; new Downloaded-from button.
- `lib/trios/context_menu_items.dart` — menu entry moves up.
