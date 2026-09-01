# Tasks

## 1 - Comparison and manager behavior

- [ ] 1.1 Add a pure comparison of a profile's mod IDs and smol variant IDs
      against the current enabled variants. Ignore list order and display data.
- [ ] 1.2 Expose the tracked profile and Modified result through one provider
      or manager API used by every profile UI. Expose loading until the first
      mod-folder scan and enabled-mod file are both ready.
- [ ] 1.3 Remove the enabled-mod listener that calls `updateFromModList()` and
      remove the automatic profile-rewrite path, `_pauseAutomaticProfileUpdates`,
      and its remaining set, clear, guard, and logging code.
- [ ] 1.4 Make explicit Save changes replace the requested tracked profile with
      the current enabled variants and update its modification time.
- [ ] 1.5 Add Stop using profile by clearing `activeModProfileId` without
      changing enabled mods.
- [ ] 1.6 Allow the tracked profile to be reapplied so Revert to profile is not
      blocked by the existing same-ID early return.
- [ ] 1.7 Treat an invalid stored profile ID as no tracked profile without a
      special cleanup flow.

## 2 - Confirmation flows

- [ ] 2.1 When stopping an unchanged profile, stop immediately.
- [ ] 2.2 When stopping with a Modified loadout, show Save and stop, Stop without
      saving, and Cancel.
- [ ] 2.3 When switching from an unchanged profile, retain one target activation
      confirmation.
- [ ] 2.4 When switching from a Modified loadout, show one combined dialog with
      the target changes and warnings plus Save and switch, Switch without
      saving, and Cancel.
- [ ] 2.5 Save nothing when the combined switch dialog is cancelled. If saving
      fails, do not switch profiles.
- [ ] 2.6 Preserve ordinary missing-mod and missing-variant activation behavior
      when reverting or switching. Rewrite warnings that claim missing members
      will be discarded from the saved profile.
- [ ] 2.7 Make choosing the already tracked profile in the picker a no-op and
      keep Revert to profile as the explicit reapply action.
- [ ] 2.8 Remove Back up Profile & Activate because activation no longer
      rewrites the previous profile.

## 3 - UI

- [ ] 3.1 Show the tracked profile name and Modified state in the Mod Manager
      profile picker, describing Modified as a current-loadout state.
- [ ] 3.2 Add Stop using profile to the profile picker.
- [ ] 3.3 On the tracked profile card, show Save changes, Revert to profile, and
      Stop using profile when Modified.
- [ ] 3.4 On an unchanged tracked profile card, show Stop using profile.
- [ ] 3.5 Keep Enable on untracked profiles and keep deletion disabled for the
      tracked profile.
- [ ] 3.6 Update the Profiles information dialog to explain explicit saving
      instead of automatic updates.
- [ ] 3.7 Show loading and disable profile actions until both comparison inputs
      are ready.
- [ ] 3.8 While Starsector is running, allow Save changes and Stop using profile
      but disable Revert and profile switching.

## 4 - Tests and verification

- [ ] 4.1 Test exact matches, added mods, removed mods, swapped variants, and
      order-only differences.
- [ ] 4.2 Test Save changes and Revert changing the loadout as intended, and
      test that Stop using profile never changes the loadout.
- [ ] 4.3 Test every Modified stop result and every result from the combined
      switch dialog, including save failure.
- [ ] 4.4 Test dependency validation leaving a profile Modified instead of
      rewriting it.
- [ ] 4.5 Test that ordinary individual and bulk loadout changes never mutate
      the tracked profile automatically. The modpack change owns its end-to-end
      Enable installed members integration test.
- [ ] 4.6 Test startup loading, missing profile IDs, missing members during
      Revert, same-profile picker selection, and game-running action states.
- [ ] 4.7 Run formatting, targeted profile tests, all Flutter tests, Flutter
      analysis, and custom lint.
