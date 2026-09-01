# Tasks

## 1 - Comparison and manager behavior

- [x] 1.1 Add a pure comparison of a profile's mod IDs and smol variant IDs
      against the current enabled variants. Ignore list order and display data.
- [x] 1.2 Expose the tracked profile and Modified result through one provider
      or manager API used by every profile UI. Expose loading until the first
      mod-folder scan and enabled-mod file are both ready.
- [x] 1.3 Remove the enabled-mod listener that calls `updateFromModList()` and
      remove the automatic profile-rewrite path, `_pauseAutomaticProfileUpdates`,
      and its remaining set, clear, guard, and logging code.
- [x] 1.4 Make explicit Save changes replace the requested tracked profile with
      the current enabled variants and update its modification time.
- [x] 1.5 Add Stop using profile by clearing `activeModProfileId` without
      changing enabled mods.
- [x] 1.6 Allow the tracked profile to be reapplied so Revert to profile is not
      blocked by the existing same-ID early return.
- [x] 1.7 Treat an invalid stored profile ID as no tracked profile without a
      special cleanup flow.

## 2 - Confirmation flows

- [x] 2.1 When stopping an unchanged profile, stop immediately.
- [x] 2.2 When stopping with a Modified loadout, show Save and stop, Stop without
      saving, and Cancel.
- [x] 2.3 When switching from an unchanged profile, retain one target activation
      confirmation.
- [x] 2.4 When switching from a Modified loadout, show one combined dialog with
      the target changes and warnings plus Save and switch, Switch without
      saving, and Cancel.
- [x] 2.5 Save nothing when the combined switch dialog is cancelled. If saving
      fails, do not switch profiles.
- [x] 2.6 Preserve ordinary missing-mod and missing-variant activation behavior
      when reverting or switching. Rewrite warnings that claim missing members
      will be discarded from the saved profile.
- [x] 2.7 Make choosing the already tracked profile in the picker a no-op and
      keep Revert to profile as the explicit reapply action.
- [x] 2.8 Remove Back up Profile & Activate because activation no longer
      rewrites the previous profile.

## 3 - UI

- [x] 3.1 Show the tracked profile name and Modified state in the Mod Manager
      profile picker, describing Modified as a current-loadout state.
- [x] 3.2 Add Stop using profile to the profile picker.
- [x] 3.3 On the tracked profile card, show Save changes, Revert to profile, and
      Stop using profile when Modified.
- [x] 3.4 On an unchanged tracked profile card, show Stop using profile.
- [x] 3.5 Keep Enable on untracked profiles and keep deletion disabled for the
      tracked profile.
- [x] 3.6 Update the Profiles information dialog to explain explicit saving
      instead of automatic updates.
- [x] 3.7 Show loading and disable profile actions until both comparison inputs
      are ready.
- [x] 3.8 While Starsector is running, allow Save changes and Stop using profile
      but disable Revert and profile switching.

## 4 - Tests and verification

- [x] 4.1 Test exact matches, added mods, removed mods, swapped variants, and
      order-only differences.
- [x] 4.2 Test Save changes and Revert changing the loadout as intended, and
      test that Stop using profile never changes the loadout.
- [x] 4.3 Test every Modified stop result and every result from the combined
      switch dialog, including save failure.
- [x] 4.4 Test dependency validation leaving a profile Modified instead of
      rewriting it.
- [x] 4.5 Test that ordinary individual and bulk loadout changes never mutate
      the tracked profile automatically. The modpack change owns its end-to-end
      Enable installed members integration test.
- [x] 4.6 Test startup loading, missing profile IDs, missing members during
      Revert, same-profile picker selection, and game-running action states.
- [x] 4.7 Run formatting, targeted profile tests, all Flutter tests, Flutter
      analysis, and custom lint.
