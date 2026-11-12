# Design

The specs in `specs/` say what save sync and mod sync do. This file says how to build them. The terms come from `CONTEXT.md`: sync folder, synced saves folder, synced save, synced copy, sync record, sync lock, sync session, common folder, and sync blocklist.

## Context

- **The fork.** imoldovavan's TriOS-sync fork (`feature/cloud-save-sync`, commit `1571f698`) branched off `56ab95f1`. Its plans are in that branch under `openspec/changes/archive/2026-11-06-cloud-save-sync/` and `.../2026-11-06-cloud-mods-sync/`. Read them for background. This design changes many of their decisions.
- **Launching.** Every launch goes through `LauncherButton.launchGame` (`lib/launcher/launcher.dart`). The game starts detached, so TriOS can't wait for it to exit.
- **Game exit.** `_GameRunningChecker` (`lib/trios/app_state.dart`) checks every 1.5 seconds. It skips checks while TriOS is unfocused, and it only runs when `checkIfGameIsRunning` is on.
- **Saves.** `AppState.savesFolder` is TriOS's saves folder. `parseSaveDescriptor` (`lib/mod_profiles/save_reader.dart`) reads a `descriptor.xml`. The game lists every folder directly inside the saves folder that holds a `descriptor.xml`, whatever its name (`CampaignGameManager`).
- **Packing.** The save archiver packs saves with 7-Zip through `SevenZip.createArchiveFromFolder` and `testArchive` (`lib/compression/seven_zip/seven_zip.dart`), wrapped by `SevenZipSaveArchiveTool`.
- **vmparams.** `vmparamsManagerProvider` lists every vmparams file TriOS detects (`detectedVmparamsFiles`).
- **Profiles.** After `explicit-profile-saving` lands, changing the enabled mods no longer rewrites the tracked profile. The profile shows Modified instead.
- **Activity panel.** `ActivitySourceType` has `download` and `archive`. The activity button shows a popup that doesn't block anything when work starts or finishes while the panel is closed (`lib/toolbar/activity_icon_button.dart`).

## Decisions

### 1. Start from the fork's code

Copy these from the fork and change them to fit this design. Credit imoldovavan with a `Co-Authored-By` line, using the name and email on the fork's commits, on each commit that brings their code in.

| Fork file | What happens |
| --- | --- |
| `save_sync_decision.dart` | Copy as is. |
| `save_content_hash.dart` | Copy. Add the blocklist filter. |
| `cloud_conflict_files.dart` | Copy as is. |
| `save_sync_backups.dart` | Copy. Add pruning to the newest 5. |
| `models/save_sync_manifest.dart`, `save_sync_lock.dart`, `save_sync_state.dart`, `mod_sync_manifest.dart` | Copy. Add the game version, and drop the enabled-mods list models. |
| `save_sync_engine.dart`, `mod_sync_engine.dart`, `mod_sync_items.dart` | Copy. Change them to use the sync folder class, 7-Zip packing, the blocklist, and the decisions below. Drop the enabled-mods list. |
| `folder_save_sync_backend.dart` | Copy as `sync_folder.dart`, a plain class with no interface (decision 2). |
| `test/save_sync/*` | Copy the tests for the parts above. |

Leave these out:
- `save_sync_backend.dart`, because there is no interface.
- `save_archiver.dart`, because packing is new (decision 3).
- `save_sync_names.dart`, because `fixFilenameForFileSystem()` replaces it (decision 13).
- `saves_folder_check.dart`. The synced saves folder replaces it (decision 5). The vmparams line parsing inside it can be reused.
- `save_credits_reader.dart`, because the hover popup no longer shows credits.
- All of the fork's UI: dialogs, the settings section, and the mod section.
- The "Save sync: <character>" profile logic.
- The fork's packaging changes.
- The fork's `readSaveFolder`. `dev` already has `parseSaveDescriptor` for the same job.

### 2. One sync folder class, no interface

`SyncFolder` reads and writes the sync folder with `dart:io`. TriOS only ever syncs through a folder, so an interface would have one implementation. Tests use temporary folders.

### 3. Pack with 7-Zip

Synced saves and mod folders are `.7z` files, made with `SevenZip.createArchiveFromFolder` and checked with `testArchive`, the same way the save archiver does it. 7-Zip runs in its own process, so a 100 MB `campaign.xml` doesn't sit in TriOS's memory. Blocked files are left out when packing.

Tests that call 7-Zip run only where the binary is present, like the save archiver's tests. Everything else (decisions, hashing, names, blocklist matching) is tested without it.

Mod folders are packed with their real `mod_info.json` file names. Hashing treats every top-level name in `Constants.modInfoFileNames` as `mod_info.json`. On a pull, the top-level file gets this PC's name back, as `mod-sync/spec.md` describes. If a folder has more than one of these names at the top level, none is renamed.

### 4. Sync folder layout, version 2

The layout is in `save-sync/spec.md`. The marker file keeps the fork's name, `trios-save-sync.json`, but uses layout version 2. The fork's folders are version 1 and hold `.zip` files. The fork's builds refuse version 2, and this TriOS refuses version 1 with a message to choose an empty folder. Only people testing the fork have version 1 folders, so converting them isn't worth the code.

A mod removed with "Stop syncing it" gets `mods/<folder>.removed.json` holding the removed copy's content hash, the PC id, and the time.

### 5. The synced saves folder

The choices are:
- `AppState.savesFolder`
- the `-Dcom.fs.starfarer.settings.paths.saves` value from each file in `detectedVmparamsFiles`, resolved against the game core folder the way `_generateVmparamOverrides` does. Plain values, quoted values, and quoted arguments are all handled.

Paths are compared after normalizing, ignoring case on Windows. For each choice, TriOS reads the save date from every `descriptor.xml` to find its newest save.

The chosen path is stored in `Settings.saveSyncSavesFolder`. Nothing else ever writes that setting. The newer-save warning is checked when the Save sync dialog opens and after each sync session.

Sync records are keyed by `<synced saves folder>|<item>`, as in the fork. Picking a different folder therefore starts with no records, and the decision table handles that.

### 6. Settings and state

Added to `Settings`, with the mapper regenerated:
- `saveSyncEnabled`: default false
- `saveSyncFolder`: `Directory?`
- `saveSyncSavesFolder`: `Directory?`
- `saveSyncSaveNames`: the synced saves on this PC
- `saveSyncCommonEnabled`: default true
- `saveSyncModsEnabled`: default false
- `modSyncScope`: `everyModFolder` or `usedBySyncedSaves`, default `everyModFolder`
- `modSyncRemoval`: `nothingPasses` or `stopSyncing`, default `nothingPasses`

The sync state stays in its own file, `trios_save_sync_state-v1.json`, through `GenericAsyncSettingsManager`, as in the fork. It holds the PC id, sync records for saves, mods and common files, and the mod fingerprints and hashes. It changes on every sync, so it doesn't belong in `Settings`.

### 7. Common folder items

Each file under `<synced saves folder>/common` is one item with the key `common/<relative path>`. Files are copied as they are, because they are small. Each file has its own manifest, so two PCs never write the same manifest. Conflicts offer keep this PC's, keep synced, or skip.

### 8. Sync blocklist matching

First look on pub.dev for a `.gitignore` matcher package that is maintained and has no native code. If none fits, write a small matcher supporting `*`, `**`, `?`, a leading `/`, a trailing `/`, `!`, and `#`.

Hashing, packing, and the fingerprint all take the same filter. On a pull, blocked files from the local folder are moved into the unpacked folder before it is swapped into place.

### 9. Temporary folders

Pulled saves are unpacked to `<synced saves folder>/.trios-sync/incoming/<save>`, and replaced saves are moved to `.../outgoing/<save>` before they go to backups. The game only looks for `descriptor.xml` one level down, so nothing inside `.trios-sync` is listed as a save. Renames stay on one drive, so they are instant. The fork put temp folders directly in the saves folder. If TriOS crashed during a pull, the game would have listed the leftover temp folder as a save.

Mods use `<mods folder>/.trios-sync-incoming/<folder>`, as in the fork. TriOS removes both temp folders at the start and end of each run.

### 10. Sessions, the game-running check, and the launch hook

`SaveSyncNotifier` owns the sync session, as in the fork.
- Opening a session writes the sync lock and sets `AppState.keepCheckingGameWhileUnfocused`.
- A `ref.listen(AppState.isGameRunning, ...)` sees the game close and runs the pushes. This is the same pattern Chipper uses.
- `LauncherButton.launchGame` first awaits `prepareForLaunch`, which returns false if the user cancels. When save sync is off, it returns true at once.
- `AppShell` listens to the save sync provider so it exists from startup.

### 11. Switching to a save's mods

"Pull and switch mods" changes the current loadout with the apply path that `explicit-profile-saving` adds, the same one Revert to profile uses, without saving to any profile. Check the exact method name once `modpack-links` is merged.

### 12. Activity panel and dialogs

- Add `ActivitySourceType.sync`.
- Each sync run writes one entry with the result for each item.
- A sync that starts or finishes while the panel is closed uses the existing popup under the activity button.
- Open questions (conflicts, mod checks, cloud conflict copies) live in `SaveSyncNotifier`'s state. The entry and the popup show a "Resolve…" button that opens the matching dialog.
- During `prepareForLaunch`, those dialogs open at once instead, because the user is waiting on the launch.

### 13. File names

`String.fixFilenameForFileSystem()` (`lib/utils/extensions.dart`) gains:
- Reserved Windows names, with or without an extension: `CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9`, `LPT1`–`LPT9`, `COM¹`–`COM³`, `LPT¹`–`LPT³`, `CONIN$`, `CONOUT$`. An `_` is added after the name.
- No trailing dot or space.
- The DEL character is replaced, like the other control characters.
- A result that is empty, `.`, or `..` becomes `_`.
- The name is cut to 255 UTF-8 bytes rather than 255 characters, without splitting a character. It is trimmed again after cutting.

This helper also names mod install folders, downloads, and save archives. Only names that hit one of these cases change. The check for names that differ only by letter case compares names with each other, so it stays in save sync.

### 14. Archiving a synced save

After `SaveArchiver.archiveSave` succeeds, the archive flow calls `SaveSyncNotifier.forgetSave(folderName)`. That removes the save from `saveSyncSaveNames` and drops its sync record. Restoring the save doesn't call anything in save sync.

## Files

New, under `lib/save_sync/`:
- `sync_folder.dart`
- `save_packer.dart`: 7-Zip pack and unpack, safe paths, and moving blocked files
- `save_content_hash.dart`
- `sync_blocklist.dart`
- `save_sync_decision.dart`
- `save_sync_backups.dart`
- `cloud_conflict_files.dart`
- `save_sync_engine.dart`, `mod_sync_engine.dart`, `mod_sync_items.dart`, `common_sync_items.dart`
- `synced_saves_folder.dart`: the folder choices and the newest-save check
- `models/`: the manifest, lock, state, and removed-mark models
- `save_sync_manager.dart`: `SaveSyncNotifier` and providers
- `save_sync_dialog.dart`, `save_sync_mods_section.dart`, `save_sync_conflict_dialogs.dart`, `save_sync_status_icon.dart`

Changed:
- `lib/trios/settings/settings.dart` and its mapper
- `lib/launcher/launcher.dart`
- `lib/trios/app_state.dart`
- `lib/app_shell.dart`
- `lib/mod_profiles/mod_profiles_page.dart` and `mod_profile_card.dart`
- `lib/save_archiver/` (the archive flow)
- `lib/trios/activity_panel/activity_entry.dart` and its mapper
- the activity panel and popup widgets
- `lib/utils/extensions.dart`
- `CLAUDE.md`, to add `save_sync/` to the feature folder list
- `changelog.md`, for the credit line, when it ships

## Risks

- **Cloud client delay.** The other PC may not have the newest copy yet. The sync lock warning and "Waiting for the cloud client to finish" make this visible.
- **First mod sync is large.** It is about 1.9 GB on the fork author's PC. The 500 MB question at launch stops it from blocking a launch.
- **Mods that write into their own folder.** Each write counts as a change. If two PCs both write before syncing, the user gets a conflict for that mod.
- **Long paths on Windows.** Temp folders add about 25 characters. Unpack errors name the file that failed.
- **Game started outside TriOS.** No pull happens first. The activity panel says so.
- **Backups.** Five backups of a large mod can still be big. The dialog shows the backups folder's size.
