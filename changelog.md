# 0.0.55

- Added
- Fixed
- Changed
  - Mods tab is quicker to load after the first time.

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