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
  -  Mod grid now shows more info at once and has more column features (move columns, filter, hide, etc).
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