# Proposal: Zip up the backup files TriOS makes

## Problem

TriOS copies its own settings and cache files to plain `.bak` files in its config folder, then never reads them again. They exist only so a person can restore a file by hand after something goes wrong.

That means they sit on disk uncompressed for no reason:

- `GenericAsyncSettingsManager.createBackup()` (`lib/utils/generic_settings_manager.dart:251`) writes `<file>_backup.bak` next to each settings file. It runs when a file fails to load, and again on a timer (at most once every 30 minutes) for every settings file. The VRAM cache is one of these, and it can be large.
- `SettingsFileManager._createBackupSync()` (`lib/trios/settings/app_settings_logic.dart:200`) writes numbered `trios_settings-v1.json_backup_N.bak` files whenever the main settings file won't parse. The number keeps climbing, so these stack up.

TriOS already ships a 7-Zip binary and already knows how to create archives (`SevenZip.createArchive`), so this is mostly wiring.

## Proposed Solution

After making a backup copy, compress it to a `.7z` in the same folder and delete the plain copy.

- One small shared helper does the work, so both backup paths behave the same.
- If compression fails for any reason — 7-Zip missing, antivirus, a locked file — the plain `.bak` is left exactly where it is. A backup is never lost to save space.
- Nothing about *when* a backup is made changes.

## Scope

- Backups TriOS writes in its own config folder: the `GenericAsyncSettingsManager` ones (mod profiles, VRAM cache, mod records, and anything else built on it) and the numbered `trios_settings-v1.json` ones.
- The 30-minute "is the backup fresh enough?" check has to look at the `.7z` as well as the `.bak`, or it will make a new backup on every launch.

## Non-Goals

- Backups TriOS writes inside the game folder or a mod folder — the game's `settings.json.bak` (`lib/dashboard/game_settings_manager.dart:130`) and a mod's tips `.bak` (`lib/tips/tips_notifier.dart:183`). They are tiny, and leaving them as plain files means a person can restore them by hand without unzipping anything.
- The one-off legacy rename in `mod_profiles_manager.dart:93`.
- Capping or deleting old numbered settings backups. They still pile up; that's a separate decision.
- Restoring from a backup inside the app. Backups stay a manual, unzip-it-yourself safety net.
