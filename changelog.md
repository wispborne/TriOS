# 1.2.0 (in dev)
- Added
  - Ships Viewer
  - Mods page: copy selected rows to clipboard (right-click).
  - Weapons Viewer: may now click on image to open in Explorer, and right-click to open data folder (same as Ships Viewer grid).
  - MacOS and Linux now show the current JRE and RAM allocation (when hovering the launch button).
  - Right-click option to force re-estimate mods in a group (e.g. all enabled).
- Fixed
  - Mods Grid: If two mod versions had the same Version Checker version but different mod_info.json versions, the "Click to use newer version" button could suggest updating to the wrong version.
  - Reordering columns on Mods/Weapons/Ships pages.
  - MacOS and Linux incorrectly showing warnings that the JRE wasn't supported.
- Changed
  - Remove GraphicsLib from VRAM estimation.
    - With GraphicsLib dynamically unloading textures, estimating VRAM becomes complex.
  - Mods page: Split the changelogs & Version Checker icons part of the `Version` column into their own column and added sorting for it.
    - Sorting is, in order: has update, then no update but has changelog, then no update and no changelog, then doesn't support version checker.
  - Added "Show Enabled [Only]" to Weapons Viewer.
  - Updated to Flutter 3.32.0 and updated various dependencies.
  - "Update All" button now asks if you're sure if updating more than one mod, rather than 5+.
  - Mentioning that errors in the log don't mean there's a problem with the game or mods.
  - Further clarify that TriOS isn't needed to launch Starsector.

# 1.1.11
- Fixed
  - A mod archive (zip/rar/7z) without a root-level folder would be installed to /mods, rather than creating a subfolder.
    - Bug introduced in some recent version, it handled this correctly in the past.
- Changed
  - Mods page: When sorting by a column other than Name, mods will be secondarily-sorted alphabetically.

# 1.1.10
- Added
  - Enable/Disable All mods
    - Found in the new menu at the top-right of the Mods page.
  - Button to switch to the latest version of a mod if you're using an outdated one.
  - Button in Settings to hide the donation button.
  - Shortcut to open `settings.json`, found under Game Settings on Dashboard.
  - On log section of Dashboard, added explanatory tooltip and slight UI refresh.
- Fixed
  - Unreadable font color on "change version" button if multiple mods were enabled and lowest one was for wrong game version (thanks, SirHartley...)
  - Alignment of mod dependency buttons (thanks SirHartley!)
  - Window scaling not applying on load.
  - Mods with a Version Checker `modThreadId` in the format of `1234.0` was being read as `12340` (e.g. Detailed Combat Results).
  - Added game compatibility checks to more places that you can enable mods from.
  - If app was maximized on close, it would not be properly maximized when reopened.
  - Catalog didn't show loading indicator when the mod list was loading.
  - Fixed/reduced notification spam. No longer shows useless notifications for mods when you swap versions, and fixed dupes probably  (introduced last update I think).
  - Mods no longer disappear and reappear when enabling/disabling (introduced last update).
  - Reduced how often mods are reloaded from disk if there are many changes in a short time.
  - Sped up downloads from Bitbucket.
  - Launch button on dashboard now shows a warning if you have the wrong JRE selected, same as the toolbar launch button does.
- Changed
  - Clearer popup when there is an error installing a mod (usually happens when there is a Unicode character in the path).
  - Catalog items now indicate better that they may be clicked.
  - Improved changelog parsing, now highlights versions more reliably.
  - Changelogs are now fetched on program start.
  - Some settings files, like mod metadata and mod profiles, now have a backup (.bak) created on app launch.
  - Cleaned up Mods tab toolbar.
    - Removed the "Est. VRAM" button, since there are buttons on the mod groups (Enabled/Disable) now that do that.
  - New license (from GPLv3 to "usually not GPLv3"). 
  - Aligned versions on Mods page.

# 1.1.9
- Added
  - Editor for game FPS limit and vsync toggle.
  - Post-install validation to check that mod files were installed as expected.
- Fixed
  - Disabled semantics for Linux builds to prevent text input field freezes.
  - Restoring window position did not respect scaling.
  - Restoring window position did not remember your monitor.
  - Edge case where mods folder could be deleted.
    - A `mods/mod_info.json` file (directly in the mods folder) would be read as a mod. Deleting it would delete its parent folder, which would be `mods`.
- Changed
  - Mods Grid: Cut-off text now has a tooltip on hover.

# 1.1.8
- Fixed
  - Version Checker error for mods on Bitbucket, such as GraphicsLib and other Dark.Revenant mods.

# 1.1.7
- Added
  - Setting to scale TriOS larger or smaller.
- Fixed
  - Mods not switching to enabled or being deleted after installing a new version.
    - Only affected 7zip, not libarchive.

# 1.1.6
- Added
  - .webp icon support for mod icons.
- Fixed
  - Mods could sometimes be partially installed or split across two folders.
  - Empty folders left in `mods` folder (same root cause as partial install bug).
  - Mods unable to be installed if Starsector not on C: drive (or same as temp folder).
- Changed
  - Downloaded mod archives (zip/7z/rar) are now cleaned out of the OS's temp folder after being installed.

# 1.1.5
- Changed
  - Launcher icon now shows a warning if you have an unsupported JRE selected.
    - For example, if you have JRE 23/24 selected for Starsector 0.98a.

# 1.1.4
- Added
  - Catalog now shows the game version of a downloadable mod.
- Fixed
  - "File is being used by another process" error when installing mods sometimes.
  - Game version not being read correctly. (please let me know if this still happens)

# 1.1.3
- Added
  - VRAM Estimator can can now filter to only enabled mods.
- Fixed
  - Disabled JRE 23/24 for Starsector 0.98a.
    - Mikohime is not updated for it, breaks it, and is not needed because vanilla uses Java 17 now.
  - Downloads taking more than 30 seconds were getting messed up.
- Changed
  - A bit of UI polish to the VRAM Estimator page to bring it more in line with other pages.
- Fixed
  - Trailing comma in mod_info.json top-level object wouldn't load (e.g. Extra Skills mod).

# 1.1.2
- Fixed
  - Multiple versions of same mod showing in VRAM Estimator (since 1.1.0).
  - Unable to sort by VRAM on mods tab (since 1.0.0).

# 1.1.1
- Fixed
  - Some downloads very slow to start.
    - Fixed for certain sites (e.g. github) that don't require a slower method of getting file download info.

# 1.1.0 
- TriOS settings may be reset (sorry). Profiles are safe.
- Added
  - Tips manager.
    - View in-game tips by mod and select which ones to hide. 
  - Mods tab: May now group by Enabled (default), Mod Type, Game Version, and Author.
  - Support for MediaFire download links (thanks, AtlanticAccent & ChatGPT).
  - VRAM Estimator now shows the top 10 most "expensive" images per mod.
- Fixed
  - Searching on the Mods tab also filtered the Dashboard mods.
  - Search included some less relevant results and didn't include perfect matches (e.g. searching "iron shell" didn't show it, but "iron shel" did).
  - Mods tab performance improvement.
    - VRAM estimate was recalculated from cached data each time it was displayed. The sum is now cached.
  - Mod downloads not showing download progress. 
  - MacOS: Catalog WebView breaking everything and not loading. Now loads.
  - MacOS: 'New Mod' notification's Open button not working.
  - MacOS: Custom game executable not working right.
- Changed
  - 7zip is now the default compression library, rather than libarchive.
    - MacOS users won't need to install compression libraries manually anymore.
    - Weird Linux users (like those on Debian 12) will be able to use it (the build of libarchive in TriOS didn't support it).
    - There is an option to use libarchive if you want to, in Settings. If you need it, let me know, otherwise it'll be removed (a large amount of TriOS's filesize is libarchive).
  - Weapons tab: massively decreased RAM usage.
    - For my setup, with 4,514 weapons loaded, it went from using 820MB to using 195MB.
    - Accomplished by switching to my own grid implementation, which is the same as on the Mods tab.
    - Also added ability to group weapons by mod.
  - Removed "more tools" dropdown, now displays the tool icons directly on the toolbar.
  - VRAM Estimator performance improvement.
    - Analyzing perf showed that it was spending a ton of time creating relative file paths. Cached them.
    - Also removed multithreading.
    - Time to check GraphicsLib went from 5000ms to ~100ms.
  - Reduced chance of double-clicking "Update" of TriOS. 
  - Added quick button to estimate VRAM for a group of mods (e.g. all enabled).

# 1.0.6
- Fixed
  - JRE & RAM Settings dropdown error if Miko_R3.txt or Miko_R4.txt is missing.
  - Searching on the Mods tab also filtered the Dashboard mods.
- Changed
  - [Removed in 1.1.0 due to bugs] Cannot run multiple instances of TriOS anymore. Opening a second instance instead focuses the existing one (Windows and Linux).

# 1.0.5
- Added
  - Mute updates option for mods.
- Fixed
  -  Spawned java.exe processes would stay open.
    - These are used to detect whether Starsector is running.
  - TriOS changelog showing unreleased versions when it shouldn't.
  - Mod Catalog list performance improvements.
  - .dmp files being created every launch (some WebView library bug, fixed by updating it to a beta). 
  - Catalog browser scrolling too fast (also fixed by updating the library).
  - Set a limit on how much RAM the JRE version check uses (min 32mb, max 128mb).
    - This is the code that scans which JREs are present in the game folder and detects their version.
  - Linux: Show a message on the Catalog webview explaining that it's not supported.
    - The mod catalog itself still works, just not the webview.

# 1.0.4
- Added
  - New setting to override the path of the Starsector launcher. 
- Fixed
  - During onboarding, selecting your game folder using the dialog didn't actually select it.

# 1.0.3
- Added
  - Mods tab: right-click on a version number for a menu to recheck updates.
  - Mods tab: side panel now opens using a button, rather than a click on the mod row
  - Debug feature to update to a specific release.
- Fixed
  - All mods sometimes showing as not supporting Version Checker.
  - Changelogs not shown correctly for mods using Google Drive to host the text. 
  - Double scrollbar on Mods tab.
  - WebView not working because the data folder couldn't be accessed (showed a popup warning).
    - WebView data folder is now `C:\Users\%USERPROFLE%\AppData\Roaming\org.wisp\TriOS\EBWebView`.
    - If you logged in to the forum, you'll need to log in again.
  - Tall tooltips on Portraits Viewer.
  - App not checking correctly if game/mods folders exist in some cases.
  - Errors sent to Sentry not including my custom messages.
  - Mods tab: removed "Disable" option for already-disabled mods.
  - Linux & others probably: During onboarding, fixed selecting a game folder not actually selecting it.
  - Linux: fixed "Run as admin" always showing.
  - Linux: fixed "Open log folder" not working.
- Changed
  - Mods tab: Side panel now has a dedicated button to open it, rather than a single-click.

# 1.0.2
- Fixed
  - Crash on Mod Catalog for some Windows 10 users.
    - Hopefully.
  - Too-tall VRAM tooltip on Enabled/Disabled groups. 
  - Search on Dashboard not allowing typing properly.
  - Game version compatibility treating different RCs as different game versions.
  - No tooltip explaining why a mod missing a dependency cannot be enabled.

# 1.0.1
- Fixed
  - No/hidden scrollbars on mod grid.

# 1.0.0
- Added
  - **Onboarding** popup on first launch.
    - Prompts for game location and how many versions of each mod to keep.
    - Will reset your settings to default due to new settings format.
  - **Mod Catalog**
    - Browse & download mods from the Official Forum and the Unofficial Discord.
    - Same mods as here: https://starmodder2.pages.dev
  - **JRE 24** (by Himemi) download support.
  - **Mod Grid rewritten** from scratch.
    - Improved performance.
    - Saves column width, position, visibility, and sorting.
    - Switched to reuse my old SMOL code :)
  - **VRAM Estimator** polish
    - Now displayed on the Mods tab.
    - Now remembered across restarts.
    - You may now estimate one mod at a time.
    - Shows VRAM taken by your GraphicsLib settings for mods.
  - May now select outdated mods to be asked if you want to **force them to run** anyway.
    - Mods "updated" this way will show asterisks next to their version. Hover to see the original version.
    - Do this at your own risk! Mods sometimes work on a newer game version, and sometimes don't.
  - **Mass-enable/disable** mods, using control-click and shift-click to select mods.
    - Can also mass-force mods to work with the current Starsector version.
  - **Favorites** let you pin a mod on the Mods tab.
  - Mods can now be sorted by **"First Seen" or "Last Enabled"**.
    - This is the date the mod was first seen or enabled by TriOS, not when it was first installed.
  - May now **install a mod from folder**, not just from zip/7z/rar.
    - Either drag'n'drop a folder or select the `mod_info.json` file from the Add button.
  - **Tooltips are now more responsive** and have replaced most of the old, "standard" styled tooltips.
  - Setting to **disable "game is running"** check.
  - Warning for 2+ enabled mod folders for the same mod.
- Fixed
  - Mod grid no longer resets itself constantly.
    - e.g. sorting now works.
  - Mod download notification url can't show more than 3 lines anymore.
  - Creating a new mod profile now uses your current mods.
  - TriOS update notification shows download size before downloading and doesn't endlessly animate.
  - Delete Mods not working.
  - Logfile not properly rolling over at 25MB until app restart.
  - Mods folder path used `/` instead of `\`.
  - Launch precheck no longer full height.
  - Version checker errors now have a capped height.
  - MacOS running the game when clicking "Open Game Folder".
  - On settings page, game folder and mods folder paths had opposite-facing slashes and it was awful.
- Changed
  - Note: TriOS settings have been reset due to a new format. 
    - Mod profiles should be fine. 
  - "Launch" button now reacts to clicks a bit faster and is more clear that the game's running.
  - Mod Audit Log on Profiles page is now persisted across restarts.
  - Starsector log shown on the Dashboard now automatically refreshes when the game closes.
    - And shows when it was last refreshed.
  - Slightly faster + more reliable VRAM checker thanks to @deliagwath.
    - No longer re-parsing `mod_info.json` files every time.
  - TriOS log button now opens folder instead of file.
  - Tooltip border uses a theme color.
  - Removed sticky headers, as they had some bugs I couldn't fix.
  - Moved "Disable" button to the top of the dropdown.
  - Removed auto-update setting in order to prevent potential crash loops.
  - Tons of other small UI fixes and tweaks.

# 0.3.4
- Added
  - **Weapon browser** (in Toolbox dropdown).
    - Includes spoilers for modded weapons!
- Fixed
  - `__MACOSX` folders breaking mod installs.
    - e.g. Diktat Enhancement.
  - More Google Drive handling fixes
    - Thank you to @DRE4DNOUGHT for all these bug reports!
  - Mod installs sometimes failing if they required user input (dialog window) and took a long time.
    - e.g. AotD or any other mod that uses google drive.

# 0.3.3
- Added
  - Now checks if the game is running and disables mod changes through TriOS.
  - Setting to switch to a newly updated version of a mod automatically.
- Fixed
  - Some Google Drive downloads not working (if they didn't link directly to the download).
- Changed
  - Downloads now show up immediately when clicked.
    - Before, it would wait until it retrieved the file name, which in the case of Google Drive, could take a while.
  - Combined two http calls into one (get file name + check if there is a file to download).
    - Should slightly speed up download of mods that use Google Drive (e.g. AotD).
  - Now reads the game's version directly from `starfarer_obf.jar`, rather than from your log file.
    - This fixes rare cases where the logfile has a different version than the game (e.g. right after updating), or has none (e.g. right after installing).

# 0.3.2
- Fixed
  - Removed "work in progress" tooltip on Mod Profiles tab.

# 0.3.1
- Fixed 
  - Forgot to enable Mod Profiles.

# 0.3.0
- Added
  - **Mod Profiles**
  - Tooltip when launching game showing version, Java version, and RAM assigned.
  - "Dependents" in the side panel now shows any specific version wanted.
  - Installing a zip with multiple mods inside now shows the paths of each detected mod to make it easier to figure out which one you want.
- Fixed
  - Timeout when checking for mod updates in some cases (tons of mods, slow PC, spotty internet).
    - TriOS now has a max of 10 API requests active at a time, rather than sending one per mod all at once.
    - Switched to a new HTTP client (wrapper around the native one), so let me know if network calls regress.
    - New setting to control this added to Settings page.
  - "Cannot write to vmparams file Miko_R3.txt" error when not using JRE 23.
  - Mod version dropdowns sometimes breaking.
    - Caused by dirty state and equality comparison comparing the whole object. Now compares just ids.
- Changed
  - Roboto as default text theme again, instead of Ibm Plex Sans.
    - It's clearer at small sizes.

# 0.2.7
- Added
  - Option to never rename mod folders (requested by Nissa).
    - CAUTION: You probably don't want to use this. If you install a new mod version and there's a folder name conflict, it'll overwrite data.
    - The UI for is it pretty dirty, will change it to a dropdown menu later.
    - Help I can't stop playing Satisfactory.
- Fixed
  - TriOS logfile button not working.
  - Starsector logfile button not working.
  - No longer warned if you have a newer dependency than a mod wants.
    - e.g. If a mod requires MagicLib 1.0.0 and you have 1.1.0, it will no longer warn you.
  - When installing a mod update, no longer overwrites previous version if "Rename all mod folders" is unchecked and previous version folder name has its name set by TriOS.
    - e.g. If you have a folder `Tahlan Shipworks-1.2.3` and update to a new version of Tahlan, it would put the new version in `Tahlan Shipworks-1.2.3` and delete the actual 1.2.3.
    - Now, if this is detected, it uses whatever the new version's folder is in the .zip file (e.g. `Tahlan Shipworks`) and doesn't change the older version.

# 0.2.6
- Fixed
  - Mod Profiles tab being accidentally enabled. The feature isn't ready yet.

# 0.2.5
- Added
  - Launch precheck now warns about mods incompatible with the current game version.
    - It also gives you a button to force-update their game version. 
- Fixed
  - Launch precheck warned about dependencies because of different versions that were still probably compatible.
    - Now only warns if there's a more serious version mismatch (and the dependency requires a specific version).
    - For example, if a mod requires MagicLib 1.0.0 and you have 1.0.1, it won't warn you, but if you only have 0.9.9, it will.

# 0.2.4
- Changed
  - May now bypass the launcher precheck, or turn it off in Settings.

# 0.2.3
- Added
  - If a dependency is missing, a button with a fix appears.
    - If dependency is disabled, button enables it.
    - If not found, searches Google for it.
    - **No longer automatically enables dependencies nor disables mods with unmet dependencies.**
- Fixed
  - Delete now tries to permanently delete if moving to Trash/Recycle Bin fails.
  - Game launch precheck didn't seem to be working.
- Changed
  - "Admin required" warning now shows a bit more info about what the issue is.

# 0.2.2
- Fixed
  - Crash introduced in 0.2.0 that could happen if an invalid tab was selected.
  
# 0.2.1
- Added
  - **Self-update for Linux and MacOS**.
    - MacOS doesn't automatically restart after updating.
  - When running as Admin, shows a shield icon in the toolbar notifying you that drag'n'drop won't work.
- Fixed
  - Scanner for mod changes on disk broke sometimes when a file was deleted.
- Changed
  - Moved VRAM and Portraits tools into a new dropdown menu to save space on the toolbar.

# 0.2.0
- Added
  - **Retain last N versions** of a mod.
    - Keep only the latest version of a mod by setting this to 1.
  - Option to keep the **same folder name when updating** a mod.
    - This is the new default. It is useful for modders who create a dependency on a folder path and don't want that path to change. 
- Fixed
  - Self-update failed if there were any non-ASCII characters in the TriOS or temp folder paths.
    - The Windows self-updater now works completely differently, doing an in-place update with no .bat script.
    - Windows, you so crazy.
- Changed
  - Incompatible mods are now dimmed on the Dashboard.
  - Tab bar cleanup. More compact, **icons won't be cut off** if narrow, Settings moved again.
  - Settings page always shows the scrollbar to make it more obvious that there are more settings.
  - Deleting a mod now sends it to the recycling bin/trash, rather than permanently deleting it.
  - Added timer to error logging so duplicate errors don't eat my quota.

# 0.1.10
- Fixed
  - RAM changer error if current RAM is set to an invalid number.
  - More rare/internal error fixes.
- Changed
  - White flashbang on startup is now black.
  - Cleaner error messages when a download fails.

# 0.1.9
- Added
  - Troubleshooting option to redownload and reinstall a mod, if direct download is supported.
  - Prettified tooltips if mod has an icon.
- Fixed
  - Non-ASCII characters in file paths causing mod installation to fail.
  - Another source of error spam, hopefully.
- Changed
  - Dashboard mod listing now shows versions on the right, making the mod name easier to read.

# 0.1.8
- Added
  - Mod Audit Log in the Profiles tab shows when mods are enabled/disabled and why.
  - "I don't believe you" option for if the TriOS self-updater says there's no update but you know there is.
  - Context menu option to change mod version on the Dashboard tab.
- Fixed
  - Version Checker updates failing if there was a certificate error (specifically sc2mafia.com).
  - When installing a new version of a mod while another version was enabled, both would end up enabled.
    - Now, the newly installed one will be disabled (unless you select Enable on the notification that appears).
  - If a file failed to extract, the mod install wouldn't fail and you'd have to check the log to know some file was missed.
    - Now, a dialog will appear with the error message as well as buttons to open the folders for manual install.
- Changed
  - Shiny new version comparison algorithm that takes into account dev/alpha/beta/rc, plus a ton of weird edge cases modders love putting in.
    - Nes and Timid, wtf.
  - When a mod is disabled, now sets all mod info files to `mod_info.json` instead of `mod_info.json.disabled`.
    - This improves compatibility with MOSS and manual mod management.
    - The only time `mod_info.json.disabled` is needed is when you want to enable one version and you have others installed.
  - Mod details panel is now cooler looking for mods with icons.

# 0.1.7
- Added
  - New prerelease update channel.
    - Updates will go to the prerelease channel first, then to the stable channel after.
    - You can switch between channels in the Settings page.
    - This lets me test bug fixes and hopefully catch catastrophic bugs early.
  - More info shown in the install dialog, now shows all mod_info.json info.
- Fixed
  - Maybe fixed a crash due to Chipper's parsing thread and the UI thread fighting over the same file.
  - Mod ending up disabled after updating and enabling them.
  - Version checker wasn't ignoring mods without a .version file, so if it misidentified the highest version of a mod, which didn't have a .version file, it wouldn't look for a different version with one.
    - tldr: version checking is more reliable for certain weird cases.
  - Mods showing enabled in the Dashboard modlist even when disabled (happened when enabled in `enabled_mods.json` but the mod info file was `mod_info.json.disabled`).
- Changed
  - Condensed toolbar, which was getting bloated.
  - Renamed log file to `TriOS-log.log` instead of `latest.log`.
    - (will show up as only `TriOS-log` if you have file extensions hidden, which is the Windows default)

# 0.1.6
- Added
  - More info shown in the the install dialog, now shows all mod_info.json info.
- Fixed
  - Some logspam that's blowing up my error reporting data quota.

# 0.1.5
- Added
  - "Delete Mod" context menu item.
  - "Edit mod_info.json" context menu item.
  - "Open Folder" menu item now shows all versions installed.
  - "Dependents" info in the mod details panel, showing which mods depend on the selected mod.
  - About page on toolbar.
  - Shortcut to open Starsector folder on toolbar, which is getting a little crowded (but moved JRE tab off the toolbar, see below).
- Fixed
  - Chipper log viewer not correctly condensing consecutive lines.
  - MacOS LibArchive path (i.e. MacOS should work now).
  - MacOS grey screen if unable to create log file.
    - Now falls back to only console output if cannot create log file.
    - Also, now uses AppData on Windows and Library/Application Support on MacOS for the log file.
      - This avoids permissions issues to create the log file.
  - Freeze+crash when installing mods and the dialog came up (either multiple mods at once or reinstalling a mod).
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
  - "Skip Game Launcher" is now disabled by default, since it can cause very weird issues.
    - e.g. zoomed-in combat, no Windows title bar, invisible ships.
  - Improved toolbar icons for game folder, changelog, and log file.

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