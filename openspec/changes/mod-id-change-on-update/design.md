# Design

## Where the check runs

The check runs at the end of `_finalize` in `lib/mod_manager/batch_installation/batch_installation_notifier.dart`. By then:

- The mod list has been reloaded, so the new mod is in `AppState.mods`.
- The existing "switch to new version if it was enabled" step has run. It doesn't match the new mod, because the IDs differ, so the two steps don't overlap.

For each entry in `unrecorded`:

1. Skip it if it hasn't finished (`entry.status.isTerminal` is false). Don't mark it as checked. A later `_finalize` checks it once it has finished.
2. Skip it if `entry.idChangeChecked` is true. Otherwise, set it to true.
3. Skip it unless `entry.download` is a `ModDownload`. Only update and redownload buttons create a `ModDownload`, because only they pass the old mod's `ModInfo`.
4. Skip it unless the archive held exactly one mod (`entry.scanResult.allModInfos`) and that mod installed (`entry.installedMods`).
5. Skip it if that mod's ID equals `ModDownload.modInfo.id`. That is a normal update.
6. Skip it if the old mod is no longer in `AppState.mods`. This can happen if the new mod was installed into the old mod's folder. With no old mod, there is nothing to ask about.
7. Otherwise, show the dialog.

Step 4 checks both lists because `installedMods` only holds mods that installed without errors. If an archive holds two mods and one fails, `installedMods` has one mod left. TriOS can't tell whether that mod replaces the old one. For example, it could be a library bundled with the renamed mod.

Steps 3–5 go in a plain function. It takes the entry's `download`, the number of mods the archive held, and `installedMods`. It returns the old and new `ModInfo`, or null. It returns a small named class, `ModIdChange`, not a record. That function is what the tests cover.

### Checking each entry only once

`_finalize` can run twice on the same batch at the same time:

- once from `_runPipeline`, after the main extraction, and
- once from `addLateEntry`, when a download finishes scanning while the first call is still running.

Both calls build `unrecorded` before either one sets `historyRecorded`, because that happens several `await`s later. So `historyRecorded` can't tell whether an entry was already checked. Without a separate flag, "Update all" could show the same dialog twice.

`BatchEntry` gets a new field, `bool idChangeChecked = false`. Steps 1 and 2 run with no `await` between reading the flag and setting it. The rest of the loop has no `await` either, because the dialog isn't awaited. So only one of the two calls can claim an entry.

### Showing the dialog

The check calls `askAboutModIdChange` (see below) without `await`. The install queue doesn't wait for the user to answer. During "Update all", each renamed mod gets its own dialog when its install finishes.

The dialog needs a `BuildContext`. It uses `AppState.appContext`, the same as the install error dialog at the end of `_finalize`. If there is no mounted context, it skips the dialog and logs a warning.

## The dialog

New file: `lib/mod_manager/mod_id_change_dialog.dart`. It holds two things:

- `ModIdChangeDialog`, the dialog widget. It doesn't read providers or change anything. It closes with `true` when the user presses Switch. Every other way of closing it returns `false` or `null`.
- `askAboutModIdChange`, a function that shows the dialog and then acts on the answer.

`askAboutModIdChange` takes the `Ref` of `BatchInstallationNotifier`, the context, the old `Mod`, the new `ModVariant`, and the enabled mods that depend on the old ID. It does these steps in order:

1. Reads whether the old mod is enabled (`isEnabledInGame`) and passes that to the dialog. The install doesn't change it.
2. Creates a `ValueNotifier<bool>` for the mute checkbox, starting at `true`, and passes it to the dialog. The checkbox reads and writes it.
3. Awaits `showDialog`.
4. If the `ValueNotifier` is `true`, mutes the old mod. Then disposes the `ValueNotifier`.
5. If the dialog returned `true`, switches.

It's built this way for two reasons:

- Escape and clicking outside close the dialog with `null`. If the checkbox value lived inside the dialog, it would be lost. The caller holds it instead, so mute works however the dialog is closed.
- A dialog's `WidgetRef` stops working when the dialog closes, so muting and switching can't use it. They use the notifier's `Ref`, which lasts as long as the app. `ForceGameVersionWarningDialog` works around the same problem by reading its notifiers before it closes.

The whole function body is wrapped in a `try`/`catch` that logs with `Fimber.e`. Nothing awaits it, so an error would otherwise go unhandled.

### Text

The user signed off on this text. Mod IDs are drawn in monospace in both forms.

**Old mod enabled:**

> **Mod ID change**
>
> The update for {old name} (`{old id}`) installed a mod with a different id: {new name} (`{new id}`).
>
> Do you want to switch to this new mod?
>
> {dependent names} depend on the old mod (`{old id}`) and may or may not work with the new mod.
>
> ☑ Also mute updates for the old mod (`{old id}`), since it will always redownload this new mod (`{new id}`).
>
> [Don't switch] [Switch]

The dependents line only shows when at least one enabled mod depends on the old ID. Names are joined as "Mod X", "Mod X and Mod Y", or "Mod X, Mod Y and Mod Z".

**Old mod disabled:**

> **Mod ID change**
>
> The update for {old name} (`{old id}`) installed a mod with a different id: {new name} (`{new id}`).
>
> ☑ Also mute updates for the old mod (`{old id}`), since it will always redownload this new mod (`{new id}`).
>
> [OK]

Names use `nameOrId`. Closing the dialog with Escape or by clicking outside counts as "Don't switch" or "OK". The checkbox still applies.

## Switching

Switch doesn't use `changeActiveModVariantWithForceModGameVersionDialogIfNeeded`. That helper awaits `showDialog` for `ForceGameVersionWarningDialog`, but the dialog closes itself before it does any work. On Force, `_onPressedForce` closes the dialog first. Then it changes the game version, reloads the mod list, and only then calls `onForced`. On Cancel, the dialog just closes. So the helper returns before the new mod is enabled, and its caller can't tell Force from Cancel.

Instead, Switch keeps both steps together:

1. Check `isModGameVersionIncorrect` for the new variant. Use the same inputs as the helper: `lastStarsectorVersion` from settings and `AppState.isGameRunning`.
2. If the game version is wrong, show `ForceGameVersionWarningDialog` for the new variant, with an `onForced` that runs step 3. Cancel runs nothing, so the old mod stays enabled.
3. Otherwise, run step 3 directly. Step 3: enable the new variant with `changeActiveModVariant(newMod, newVariant)`, then disable the old mod with `changeActiveModVariant(oldMod, null)`. Get `newMod` with `newVariant.mod(ref.read(AppState.mods))`.

The old mod is only disabled on the same path that enabled the new one. So the user never ends up with neither mod enabled. Nothing has to wait for the force-version dialog, and the enabled list doesn't need to be re-read afterward. If enabling the new mod throws, the old mod isn't touched, and the `catch` in `askAboutModIdChange` logs the error.

## Muting

If the checkbox is checked, mute updates for the old mod the same way `buildMenuItemToggleMuteUpdates` in `lib/trios/context_menu_items.dart` does:

```dart
ref.read(AppState.modsMetadata.notifier).updateModUserMetadata(
  oldMod.id,
  (old) => old.copyWith(areUpdatesMuted: true),
);
```

This mutes the whole mod, not one version. The old mod's version file now points to the new mod, so muting one version would bring the badge back on the new mod's next release.

## "Update All" skips muted mods

Muting alone doesn't stop the old mod from being downloaded again:

- The dashboard's "Update All" button passes `modsWithUpdates` to `_onClickedDownloadModUpdatesDialog` in `lib/dashboard/mod_list_basic.dart`. That list includes muted mods. Muted mods are only left out of the list that is displayed.
- Muting doesn't clear the stored "update available" result. `refresh` in `lib/mod_manager/version_checker.dart` stops checking muted mods, but keeps their last result.

So without a change here, the next "Update All" would download the new mod again and show this dialog again.

The change: "Update All" uses `modsWithUpdates - mutedModsWithUpdates`. `mutedModsWithUpdates` already exists for the display list. It uses `isUpdateHidden`, so it covers both "mute all updates" and "mute this version". This applies whatever the dashboard's update visibility setting is.

The button's tooltip count and the "Download updates for N mods?" count use the same list. If every mod with an update is muted, the button is disabled.

## Finding dependents

The enabled mods that depend on the old mod are the enabled mods whose `modInfo.dependencies` list a dependency with the old mod's ID. A plain ID match is enough here, because the line only warns. The two existing dependents helpers (`calculateDependents` in `mod_summary_panel.dart` and `_buildDependentsContent` in `mod_info_dialog.dart`) are private widget methods that use `ref.watch`, so they can't be called from the notifier.

## Files

| File | Change |
|---|---|
| `lib/mod_manager/batch_installation/batch_installation_notifier.dart` | Run the check at the end of `_finalize` and call `askAboutModIdChange`. |
| `lib/mod_manager/batch_installation/batch_installation.dart` | Add `idChangeChecked` to `BatchEntry`. |
| `lib/mod_manager/mod_id_change_dialog.dart` | New. `ModIdChangeDialog` and `askAboutModIdChange`, which runs the mute and Switch steps. |
| `lib/mod_manager/batch_installation/mod_id_change.dart` | New. `ModIdChange` and the function that detects it. |
| `lib/dashboard/mod_list_basic.dart` | "Update All" skips muted mods. |
| `test/mod_id_change_test.dart` | New. Tests for the detection function. |
