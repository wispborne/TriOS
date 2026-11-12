# Tasks

## Step 0 — before starting

- [ ] Check that `modpack-links` is merged into `dev`, including `explicit-profile-saving`. Stop if it isn't.
- [ ] Find the method `explicit-profile-saving` uses to apply a mod list without saving a profile, and note its name in `design.md` decision 11.
- [ ] Fetch the fork (`https://github.com/imoldovavan/TriOS-sync`, branch `feature/cloud-save-sync`, commit `1571f698`) into a scratch folder. Treat it as reference only, and copy files from it by hand.

## Step 1 — file names

- [ ] Add the new cases to `String.fixFilenameForFileSystem()` (design decision 13).
- [ ] Unit tests: each reserved name with and without an extension, superscript digits, trailing dots and spaces, DEL, empty, `.`, `..`, and a multi-byte name over 255 bytes.

## Step 2 — models, settings, and state

- [ ] Copy the manifest, lock, and state models from the fork. Add the game version, add the removed-mark model, and drop the enabled-mods list models.
- [ ] Add the new `Settings` fields (design decision 6) and the two enums.
- [ ] Copy the sync state file manager. Add common file records and the PC id.
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`.

## Step 3 — sync folder, packing, hashing, and the blocklist

- [ ] Copy `folder_save_sync_backend.dart` as `SyncFolder`, with no interface. Use layout version 2, refuse version 1, and create the starting blocklist file.
- [ ] Refuse a sync folder that is the synced saves folder, the mods folder, or the archive folder, or a folder inside one of them.
- [ ] Look on pub.dev for a `.gitignore` matcher. Otherwise write `sync_blocklist.dart`. Test it with the cases from `save-sync/spec.md`.
- [ ] Copy `save_content_hash.dart` and add the blocklist filter.
- [ ] Write `save_packer.dart`:
  - [ ] Pack with 7-Zip, leaving out blocked files.
  - [ ] Check the packed file.
  - [ ] Unpack to `.trios-sync/incoming`, and refuse unsafe paths and a missing `descriptor.xml`.
  - [ ] Move blocked local files into the unpacked folder.
  - [ ] Swap folders through `.trios-sync/outgoing`.
- [ ] Copy `cloud_conflict_files.dart` and its tests.

## Step 4 — decisions and backups

- [ ] Copy `save_sync_decision.dart` and its tests.
- [ ] Copy `save_sync_backups.dart`. Add pruning to the newest 5 backups per item, with a test.

## Step 5 — save sync engine

- [ ] Copy `SaveSyncEngine`. Change it to use `SyncFolder`, `save_packer.dart`, and `parseSaveDescriptor`.
- [ ] Name synced copies with `fixFilenameForFileSystem()`, keep the original name in the manifest, and refuse names that differ only by letter case.
- [ ] Add "Remove from sync folder" for saves.
- [ ] Copy the two-PC engine tests and update them for 7-Zip. Mark them local-only where they need the binary.

## Step 6 — common folder

- [ ] Write `common_sync_items.dart`: one item per file, plain copies, one manifest per file.
- [ ] Add common folder pushes and pulls to the engine, after mods and before saves.
- [ ] Tests: two PCs changing different files, the same file, and a file matched by the blocklist.

## Step 7 — mod sync

- [ ] Copy `mod_sync_items.dart`: list folders that hold a `mod_info.json`, take fingerprints, and hash with every `mod_info.json` name treated as one.
- [ ] Copy `ModSyncEngine`. Drop the enabled-mods list, and add both scopes.
- [ ] Add the "Stop syncing it" removal: the removed mark, the content hash check, and asking when more than 5 folders vanish.
- [ ] After a pull of a new mod version under "Stop syncing it", run this PC's "keep last N versions" cleanup for that mod.
- [ ] Ask "Sync mods now?" at launch when more than 500 MB would be copied.
- [ ] Tests: both scopes, both removal choices, a version switch that isn't a change, and a folder without `mod_info.json`.

## Step 8 — synced saves folder

- [ ] Write `synced_saves_folder.dart`:
  - [ ] Collect the choices from `AppState.savesFolder` and every detected vmparams file.
  - [ ] Remove duplicates.
  - [ ] Find each choice's newest save.
- [ ] Add the newer-save warning check.
- [ ] Tests: quoted and unquoted vmparams values, relative paths, duplicates, and the newest-save default.

## Step 9 — session, game check, and launch

- [ ] Add `AppState.keepCheckingGameWhileUnfocused` and the 5-second unfocused check in `_GameRunningChecker`.
- [ ] Write `SaveSyncNotifier`:
  - [ ] Open and close sync sessions, and write and remove the sync lock.
  - [ ] Push after the game closes.
  - [ ] Handle this PC's leftover sync lock at TriOS start.
  - [ ] Handle a game started outside TriOS.
  - [ ] Close the session if the game doesn't start within 3 minutes.
- [ ] Call `prepareForLaunch` from `LauncherButton.launchGame`.
- [ ] Listen to the save sync provider in `AppShell`.
- [ ] Add "Pull and switch mods" using the apply method from step 0, with the newest-save rule for more than one save.

## Step 10 — activity panel

- [ ] Add `ActivitySourceType.sync` and regenerate the mapper.
- [ ] Record each sync run, with the result for each item.
- [ ] Show the existing popup for syncs that start or finish while the panel is closed.
- [ ] Add "Resolve…" to entries and popups that hold an open question.

## Step 11 — UI

- [ ] Add the "Save sync" button to the Mod Profiles page.
- [ ] Build the Save sync dialog:
  - [ ] the on/off switch, sync folder, and synced saves folder with "Change…"
  - [ ] "Sync now", backups size, and "Open backups folder"
  - [ ] the saves list, the common folder option, and the blocklist editor
  - [ ] the game-running check warning
- [ ] Build the synced saves folder picker, including the "Also show this folder's saves in the rest of TriOS" checkbox.
- [ ] Build the Mods section: the on/off switch, the scope choice, the removal choice, the summary line, and the mod list with problems first.
- [ ] Add the sync status icon (with a tooltip) and the include switch to save cards. Hide both when the folders differ.
- [ ] Add the hover popup showing both copies' save time, PC name, and sync time.
- [ ] Build the dialogs: sync lock warning, save conflict, mod conflict, common file conflict, mod check, large mod sync, and errors.
- [ ] Show the user every new visible string for sign-off before finishing this step.

## Step 12 — archiving

- [ ] Call `SaveSyncNotifier.forgetSave` after a synced save is archived. Test that restoring it doesn't pick it again.

## Step 13 — docs and checks

- [ ] Add `save_sync/` to the feature folder list in `CLAUDE.md`.
- [ ] Write a manual test plan for two PCs in this folder, based on the fork's `manual-test-plan.md`.
- [ ] Run `flutter analyze`, `dart run custom_lint`, and `flutter test`.
- [ ] When it ships, add the changelog line crediting imoldovavan.
