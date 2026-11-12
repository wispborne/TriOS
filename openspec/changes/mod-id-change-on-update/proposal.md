# Ask what to do when an update installs a mod with a different ID

Status: ready-for-agent

## Why

Sometimes a mod author changes their mod's ID, but the old version file still points to the new download. When the user updates the old mod, TriOS installs the new mod next to the old one. TriOS treats the two as unrelated mods.

What the user ends up with today:

- The old mod stays enabled.
- The new mod is installed but disabled. The "switch to new version if it was enabled" setting only matches mods by ID, so it doesn't apply.
- The old mod keeps showing "update available". Updating it again downloads the new mod again.

## What changes

After the install finishes, TriOS shows a "Mod ID change" dialog when all of these are true:

- The install was started from a button that knows which mod it is updating. That is the dashboard's update button, the dashboard's "Update all", the Update button in the mod details dialog, and "Redownload & Reinstall".
- The download contained exactly one mod, and it installed.
- That mod's ID is different from the ID of the mod being updated.

The dialog has two forms.

**The old mod was enabled.** The dialog asks whether to switch to the new mod.

- **Switch** disables the old mod and enables the new one.
- **Don't switch** leaves both as they are.
- If any enabled mods depend on the old mod's ID, one line names them.

**The old mod was disabled.** Nothing needs switching. The dialog only offers the mute checkbox and an OK button.

Both forms have a checkbox, checked by default, that turns on "Mute updates" for the old mod. It takes effect whichever button is pressed.

The dialog shows whatever the "switch to new version if it was enabled" setting says. That setting still controls normal updates where the ID stays the same.

"Update All" on the dashboard no longer downloads updates for muted mods. Without this, muting the old mod wouldn't stop "Update All" from downloading the new mod again.

## Out of scope

- Downloads that contain more than one mod. If none of them has the old ID, TriOS can't tell which one replaces the old mod, so no dialog is shown.
- Deleting the old mod.
- A "don't ask again" option. The dialog is rare, and the mute checkbox stops it from coming back for that mod.
- Installs that don't come from an update or redownload (catalog, drag and drop, deep links). TriOS doesn't know which mod they replace.
