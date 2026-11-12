# Tasks

## 1. Detection

- [x] 1.1 Write `lib/mod_manager/batch_installation/mod_id_change.dart` with a `ModIdChange` class (old `ModInfo`, new `ModInfo`) and a function that takes the entry's `download`, the number of mods the archive held, and `installedMods`. It returns a `ModIdChange` or null. It returns null unless the entry's download is a `ModDownload`, the archive held exactly one mod, that mod installed, and its ID differs from the old one.
- [x] 1.2 Add `test/mod_id_change_test.dart`. Cover: same ID returns null; different ID returns both `ModInfo`s; two installed mods returns null; an archive that held two mods with only one installed returns null; a plain `Download` (not a `ModDownload`) returns null; no installed mods returns null.

## 2. Dialog

- [x] 2.1 Write `ModIdChangeDialog` in `lib/mod_manager/mod_id_change_dialog.dart` with both forms of the dialog and the signed-off text from `design.md`. Mod IDs in monospace. It doesn't read providers. It closes with `true` on Switch. The mute checkbox reads and writes a `ValueNotifier<bool>` passed in by the caller.
- [x] 2.2 Show the dependents line only when at least one enabled mod lists the old ID in its `modInfo.dependencies`. Join names as "X", "X and Y", "X, Y and Z".
- [x] 2.3 Write `askAboutModIdChange` in the same file. It takes the notifier's `Ref`, the context, the old `Mod`, the new `ModVariant`, and the dependents. It creates the mute `ValueNotifier` (starting at `true`), awaits `showDialog`, then mutes if the notifier is `true` and switches if the dialog returned `true`. It uses the `Ref` it was given, never the dialog's `WidgetRef`. Wrap the body in `try`/`catch` and log errors with `Fimber.e`.
- [x] 2.4 Mute: set `areUpdatesMuted: true` on the old mod with `updateModUserMetadata`.
- [x] 2.5 Switch: don't use `changeActiveModVariantWithForceModGameVersionDialogIfNeeded`. If `isModGameVersionIncorrect` is true for the new variant, show `ForceGameVersionWarningDialog` with an `onForced` that enables the new mod and then disables the old one. Otherwise do those two steps directly. Use `changeActiveModVariant` for both.

## 3. Hook into the installer

- [x] 3.1 Add `bool idChangeChecked = false` to `BatchEntry` in `batch_installation.dart`.
- [x] 3.2 At the end of `_finalize` in `batch_installation_notifier.dart`, loop over `unrecorded`. Skip entries that haven't finished, without marking them. Skip entries where `idChangeChecked` is true; otherwise set it. Keep the loop free of `await`. Then run the detection. Skip it if the old mod is no longer in `AppState.mods`.
- [x] 3.3 Call `askAboutModIdChange` without `await`, using `AppState.appContext`. Log a warning and skip it if there is no mounted context.

## 4. "Update All"

- [x] 4.1 In `lib/dashboard/mod_list_basic.dart`, make "Update All" use `modsWithUpdates - mutedModsWithUpdates`. Use the same list for the tooltip count and the confirmation dialog count. Disable the button when that list is empty.

## 5. Check

- [x] 5.1 Run `fvm flutter analyze` and `fvm flutter test test/mod_id_change_test.dart`.
- [ ] 5.2 Ask the user to test it by hand:
  - Update a mod whose new download has a different ID, once with the old mod enabled and once with it disabled.
  - Close the dialog with Escape while the mute box is checked, and check that the old mod is muted.
  - Try Switch with a new mod built for a different game version, then cancel the warning. The old mod should stay enabled.
  - Mute a mod that has an update, then press "Update All". The muted mod shouldn't be downloaded.
- [ ] 5.3 Ask the user whether to add a line to `changelog.md`.
