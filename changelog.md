# 0.2.0
- Added
  - Mod Profiles
    - Quickly swap between mod lists.
    - Different mod versions can be assigned to different profiles.
  - "Delete Mod" context menu item.
  - "Edit mod_info.json" context menu item.
  - "Open Folder" menu item now shows all versions installed.
  - "Dependents" info in the mod details panel, showing which mods depend on the selected mod.
  - About page.
- Fixed
  - Chipper log viewer not correctly condensing consecutive lines.
  - Grey screen if using an old TriOS version after using a newer one that added a new setting.
    - Will reset settings to default if this happens, after making a backup.
  - Mod grid showed mods as Enabled incorrectly sometimes.
    - The "enabled" checked `enabled_mods.json`, but didn't check whether TriOS disabled the `mod_info.json` file.
  - Force Game Version didn't work for mods that were disabled and had multiple versions (i.e. had `mod_info.json.disabled-by-TriOS`).
  - Incorrect sorting in same cases (e.g. LazyLib `2.0` and `2.0b`).
    - Now sorts using `.version` file first, then by `mod_info.json`'s version with everything but numbers and periods removed, and finally by `mod_info.json`'s version without anything removed.
  - Toolbar icons needing to be scrolled to unnecessarily.
- Changed
  - Moved the JRE tab into the Dashboard.
  - Mods tab: in the version selector, `versions are a different color if they are for a different version of the game.`
  - Disabled mods with multiple versions will now use `mod_info.json.disabled` instead of `mod_info.json.disabled-by-TriOS`.
    - It's less obvious now why it's called `.disabled`, but it makes it cross-compatible with SMOL.

# 0.1.4
- Added
  - Drag'n'drop now supports urls. Drag a url from your browser and it'll download and install the mod.
- Fixed
  - (Hopefully fixed) Self-update and installing mods not working for some users 
    - Error mentioned system32, I swear that's some null fallback path, I don't touch that.
  - Notification timers resetting.
  - Notifications could time out when still downloading a mod.

# 0.1.3
- Fixed
  - Internal error when switching from JRE 23 to any other.
  - "Admin permission required" warning if not using JRE 23.
    - And added more info about what the issue is if the warning does appear.
- Changed
  - Settings page is now scrollable.
  - Polished "Debugging" section in Settings a little.

# 0.1.2
- Fixed
  - Bugs where sometimes UI wouldn't update after changing out a mod  (found using error reporting).
  - Instance of launcher breaking if unable to read default game settings from registry (found using error reporting).
  - Portrait Viewer: Error if unable to get image size (found using error reporting).

# 0.1.1
- Fixed
  - Notifications defaulting to 7000 seconds instead of 7 seconds.

# 0.1.0

- Added
    - Opt-in crash & error reporting.
        - Not enabled by default.
        - No personal data is sent. No IP address, no language/timezone, no PC name, nothing.
        - Example of the report I see: https://i.imgur.com/k9E6zxO.png.
        - Generates a random id for you, so I can tell if 10 of the same error is from 10 people or 1 person.
        - This will help me find bugs that may otherwise not get reported.
    - Changelog viewer, for mods that include a link to a changelog in their .version files.
    - When a mod is added, shows a notification allowing you to enable it.
        - Bonus: if the mod has an icon, the notification is themed (lol).
    - Portrait Viewer. 
      - Can't yet change portraits; decided to work on Mod Profiles next instead of finishing this.
    - Added write permission check for vmparams.
- Fixed
    - Dashboard: Hide the Updates section if there aren't any updates.
    - Chipper: Handled error if a folder is dropped instead of a file.
    - When updating a mod, the new version is no longer automatically enabled.
        - Click "Enable" in the notification that appears.
        - This is to allow you to update a mod but still decide whether to use the update (it may be save-breaking).
    - Hide the "Skip Game Launcher" option if using JRE 23 (thanks Zon).
    - Checks for when a mod is "enabled" in `enabled_mods.json` but the mod doesn't actually exist anymore.
    - Checks to ensure sliders on Settings page can't break the page if value is invalid.
- Changed
  - Notifications disappear after a configurable amount of time.
  - Dashboard: "Copy mod info" now only copies enabled mods, and they are sorted by name.

# 0.0.58

- Added
    - Search box to filter mods.
    - "Skip Game Launcher" option in the Dashboard.
        - Enabled by default, disable it to act like double-clicking Starsector.exe.
    - "Add Mod(s)" button on Mods tab.
- Fixed
    - Unable to install mods with tabs in the mod_info.json file (e.g. VIC).
    - "Add Mods" button didn't work if you selected more than one mod.
    - If you unplug a monitor and TriOS was on that monitor, it'll now switch to another plugged-in monitor.
    - Mod folder names had the last character removed (e.g.`LunaLi-1.0.0`).
    - Some light theme fixes.
- Changed
    - Dashboard: tooltip moved to top-left of cursor to avoid it hiding the mod list so much.
    - Now caches icon paths, should be a little faster when scrolling mods.

# 0.0.57

- Fixed
    - Broken Mods tab (grey screen).
    - YOU WERE SEEING THE WRONG THEME THIS WHOLE TIME?!
        - Toolbar icons are now aligned properly and other little UI things now look the way I've been seeing them this whole time.
    - First install now sets the mods folder correctly.
- Changed
    - Checks for mod folder changes every 15 seconds instead of every 5.
        - Always checks whenever TriOS is re-focused (i.e. you switch back to it).

# 0.0.56

- Fixed
    - Mods tab: Enabled/Disabled groups not expanding/collapsing on click.

# 0.0.55

- Added
    - JRE 23: May now hide the console window.
    - Mods tab: Enabled and Disabled mod categories.
    - Mods tab: More info on the side panel for mods.
    - Dashboard: Shows mods folder and current JRE below the Launch button.
- Fixed
    - Various tiny UI fixes.
- Changed
    - Mods tab: is quicker to load after the first time.
    - Hid unusable launch settings on Dashboard if using JRE 23.

# 0.0.54

- Fixed
    - Mod grid showing wrong mod info for many columns.

# 0.0.53

- Added
    - On first run, uses your most recent Starsector install instead of the default install location.
    - Mod grid now shows more info at once and has more column features (move columns, filter, hide, etc).
    - **The grid column controls are still a little janky and don't yet persist between restarts.**
- Fixed
    - Tooltips going off-screen.
    - Letters in mod versions are no longer ignored by Version Checker.
    - Dashboard: First mod in "Updates" wasn't shown.
    - Changing game path via filepicker changes text field.
    - Unable to install (certain?) mods due to "Invalid value: Not in inclusive range" error.
    - Unable to update mods on Bitbucket due to it 403ing when asked if a file exists to download.
    - Update All Mods confirmation prompt always said you have 0 mods.
- Changed
    - Can select text in the mod details panel.
    - Clearer errors when Version Checker fails.
    - Always show the Version Checker remote (online) url in tooltips.

# 0.0.52

- Added
    - Mods tab: side panel to display mod info.
- Fixed
    - JRE manager failing if JRE 23 isn't present.
- Changed
    - Limit changelog to not show unreleased versions (except when viewed from self-update notification).

# 0.0.51

- Fixed
    - Self-update toast didn't display.

# 0.0.50

(pulled in mins due to self-update bug)

- Added
    - Hide mod updates button.
    - Changelog viewer.
- Fixed
    - Enabling not-latest dependencies or ones for incompatible game versions.
    - Mod update count was wrong.
    - Version Checker was based on which version of a mod was enabled instead of the highest version you have.
- Changed
    - Show Mod Info menu item now shows all versions and is prettier.