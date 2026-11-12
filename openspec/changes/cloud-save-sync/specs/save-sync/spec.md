## ADDED Requirements

### Requirement: Off by default

Save sync SHALL be off by default. It SHALL do nothing until the user turns it on, chooses a sync folder, and picks at least one save, or leaves the common folder option on. The sync folder SHALL be a user setting, never a hardcoded path.

#### Scenario: Fresh install
- **WHEN** TriOS starts with default settings
- **THEN** no file is read from or written to any sync folder, and launching the game behaves exactly as before

#### Scenario: Turned on without a sync folder
- **WHEN** save sync is on but no sync folder is set
- **THEN** the Save sync dialog shows "Choose a sync folder to start syncing", and launching behaves as before

### Requirement: Synced saves folder

Save sync SHALL read and write one saves folder, the synced saves folder, which the user picks. The choices SHALL be TriOS's saves folder plus the saves path named in every vmparams file TriOS detects, resolved against the game core folder the way the launcher does. Choices that point to the same folder SHALL appear once. Each choice SHALL show where it came from (TriOS, or the vmparams file's name) and its newest save.

- The default choice SHALL be the folder holding the newest save, judged by the save date in each save's `descriptor.xml`.
- TriOS SHALL ask when save sync is first turned on. If every choice points to the same folder, TriOS SHALL use it without asking.
- The choice SHALL be stored as a fixed path. Changing TriOS's custom saves folder or a vmparams file SHALL NOT change it.
- The common folder that save sync uses SHALL be `<synced saves folder>/common`.

#### Scenario: vmparams moves the saves folder
- **GIVEN** `Miko_R3.txt` sets the saves path to `D:\StarsectorSaves`, and TriOS reads `<game folder>/saves`
- **WHEN** the user turns on save sync
- **THEN** TriOS lists both folders, with the one holding the newest save picked by default

#### Scenario: Only one folder
- **WHEN** no vmparams file names a saves path, or every one names TriOS's saves folder
- **THEN** TriOS uses that folder without asking, and the Save sync dialog shows it with a "Change…" button

#### Scenario: The game later saves somewhere else
- **WHEN** another choice holds a newer save than the synced saves folder
- **THEN** TriOS shows a warning that does not block anything: "Your newest save is in <folder>. Save sync uses <synced saves folder>." with a "Change…" button
- **AND** TriOS does not change the synced saves folder by itself

#### Scenario: Show the same folder everywhere
- **WHEN** the user picks a folder that differs from TriOS's saves folder and ticks "Also show this folder's saves in the rest of TriOS"
- **THEN** TriOS sets its custom saves folder setting to that folder

### Requirement: Sync folder layout

The sync folder SHALL contain:
- `trios-save-sync.json`: a marker file holding the layout version.
- `sync-blocklist.txt`: the sync blocklist.
- `saves/<save folder name>.7z` and `saves/<save folder name>.manifest.json`: one synced copy per save.
- `mods/<mod folder name>.7z` and `mods/<mod folder name>.manifest.json`: one synced copy per mod folder.
- `common/<path>` and `common/<path>.manifest.json`: one synced copy per common folder file.
- `locks/<PC id>.lock.json`: one sync lock per PC while that PC's game runs.

Each PC SHALL write only its own sync lock.

#### Scenario: First use of an empty folder
- **WHEN** the user picks an empty folder as the sync folder
- **THEN** TriOS creates the marker file, the starting blocklist, and the `saves`, `mods`, `common`, and `locks` folders

#### Scenario: Folder from a newer TriOS
- **WHEN** the marker file has a layout version higher than this TriOS supports
- **THEN** TriOS does not read or write the folder, and shows "This sync folder was written by a newer version of TriOS. Update TriOS on this PC."

#### Scenario: Folder from the TriOS-sync test build
- **WHEN** the marker file has layout version 1
- **THEN** TriOS does not read or write the folder, and shows "This sync folder was made by a test build of save sync. Choose a new, empty folder."

#### Scenario: Sync folder inside another TriOS folder
- **WHEN** the user picks the synced saves folder, the mods folder, or the archive folder as the sync folder, or a folder inside one of them
- **THEN** TriOS refuses it and says why

### Requirement: Manifest contents

Each manifest SHALL be UTF-8 JSON and SHALL contain: layout version, the original save folder name, character name, content hash, the SHA-256 of the 7-Zip file, the save date from `descriptor.xml`, the time it was written to the sync folder (UTC), PC id, PC name, OS, the writing PC's game version, TriOS version, and the save's enabled mods (id, name, version).

#### Scenario: Paths inside a synced copy
- **WHEN** a save is packed on Windows
- **THEN** every path inside the 7-Zip file uses `/` and is relative to the save folder

### Requirement: Change detection by content hash

TriOS SHALL decide whether a save changed by comparing content hashes, never file times. The content hash SHALL be a SHA-256 over every file's relative path (with `/`) and SHA-256 contents, sorted by path. Files matched by the sync blocklist SHALL be left out of the hash. For each synced save, TriOS SHALL keep a sync record with the content hash and manifest from the last successful sync.

#### Scenario: Cloud client changes only the file time
- **WHEN** a synced copy's file time changes but its manifest's content hash matches the sync record
- **THEN** TriOS treats the save as unchanged

#### Scenario: Decision table
- **WHEN** TriOS compares a synced save's local copy (L), synced copy (S), and sync record (R)
- **THEN** it SHALL decide:
  - L and S both match R: up to date.
  - Only L differs from R: push.
  - Only S differs from R: pull.
  - Both differ from R and L equals S: up to date, and the record is updated.
  - Both differ from R and L differs from S: conflict.
  - No record, L exists, S missing: push.
  - No record, S exists, L missing: pull.
  - No record, both exist and are equal: up to date, and a record is created.
  - No record, both exist and differ: conflict.
  - Record exists, L missing: "Missing on this PC". Nothing is pushed or deleted.
  - Record exists, S missing: push.

### Requirement: Picking saves

Each PC SHALL keep its own list of synced saves. Picking a save on one PC SHALL NOT pick it on another.

#### Scenario: Pick a save from its card
- **WHEN** the synced saves folder is the folder the save cards show, and the user turns on a save card's include switch
- **THEN** that save becomes a synced save on this PC

#### Scenario: Save only in the sync folder
- **WHEN** the sync folder holds a save that is not in the synced saves folder
- **THEN** the Save sync dialog lists it with a "Pull" button, and pulling it makes it a synced save on this PC

#### Scenario: Folders differ
- **WHEN** the synced saves folder differs from the folder the save cards show
- **THEN** the save cards hide their sync status icon and include switch, and the Save sync dialog lists the synced saves folder's saves with their status and include switches

### Requirement: When sync runs

Save sync SHALL run at these times, in the order mods, common folder, then saves:
- Before a launch from TriOS, before the existing launch precheck.
- After the game closes, when this PC has an open sync session. Only pushes run after the game closes.
- At TriOS start, when TriOS finds this PC's own sync lock and the game is not running.
- When the user clicks "Sync now".

Nothing SHALL be synced while the game is running.

#### Scenario: Game closed while TriOS is in the background
- **WHEN** the game closes and TriOS is not focused
- **THEN** TriOS notices within a few seconds and pushes changed saves

#### Scenario: TriOS closed while the game ran
- **WHEN** TriOS starts, finds this PC's own sync lock, and the game is not running
- **THEN** TriOS pushes changed saves and removes the lock

#### Scenario: Game started outside TriOS
- **WHEN** TriOS sees the game start without a TriOS launch
- **THEN** TriOS opens a sync session, writes the sync lock, notes in the activity panel "Starsector was started outside TriOS, so synced saves were not checked first", and pushes changes after the game closes

#### Scenario: Launch never starts the game
- **WHEN** the game has not started 3 minutes after a TriOS launch
- **THEN** the sync session closes and the sync lock is removed

### Requirement: Sync locks

A sync lock SHALL contain PC id, PC name, OS, TriOS version, and start time (UTC). A lock older than 24 hours is stale. The PC id SHALL be a random id made once per TriOS install. The PC name SHALL be for display only.

#### Scenario: Another PC's lock at launch
- **WHEN** the user launches and a lock from another PC exists
- **THEN** TriOS shows "Starsector may be running on <PC> (<OS>), started <relative time>. Its saves may not have reached this PC yet." with "Launch anyway" and "Cancel"

#### Scenario: Stale lock
- **WHEN** that lock is older than 24 hours
- **THEN** the same dialog adds "This lock is over a day old and is probably left over from a crash."

### Requirement: Conflicts

TriOS SHALL never resolve a conflict by itself. The conflict dialog SHALL show both copies' save date, character name, PC name, and sync time, and offer "Keep this PC's save", "Keep synced save", "Keep both", and "Skip for now".

#### Scenario: Keep this PC's save
- **WHEN** the user picks "Keep this PC's save"
- **THEN** the synced copy goes to backups and the local save is pushed

#### Scenario: Keep synced save
- **WHEN** the user picks "Keep synced save"
- **THEN** the local save goes to backups and the synced copy is pulled

#### Scenario: Keep both
- **WHEN** the user picks "Keep both"
- **THEN** the synced copy is unpacked next to the local save in a folder whose name ends in `_synced_<timestamp>`, which is not a synced save, and the local save is pushed

#### Scenario: Skip
- **WHEN** the user picks "Skip for now"
- **THEN** nothing changes for that save, and its status stays "Conflict"

### Requirement: Cloud-client conflict copies

TriOS SHALL recognize conflict copies that cloud clients make in the sync folder: Seafile (`(SFConflict <user> <yyyy-MM-dd-HH-mm-ss>)`), Dropbox (`(<PC>'s conflicted copy <date>)`), and Syncthing (`.sync-conflict-<date>-<time>-<id>`). These SHALL never be read as a synced copy or manifest.

#### Scenario: Seafile conflict copy of a manifest
- **WHEN** `saves/save_foo_123.manifest (SFConflict ionut 2026-11-04-15-20-00).json` exists
- **THEN** that save shows "Cloud conflict copy found", syncing that save pauses, and the Save sync dialog offers "Move conflict copies to backups"

### Requirement: Mod check before a pull

Before replacing a local save with its synced copy, TriOS SHALL compare the manifest's mod list with the current loadout, the way Mod Profiles compares a profile.

#### Scenario: Mods differ
- **WHEN** the synced copy's mods differ from the current loadout
- **THEN** TriOS lists the mods to turn on, turn off, or switch version, and the mods that are not installed
- **AND** it offers "Pull and switch mods" (when at least one difference can be fixed with installed mods), "Pull, keep my mods", "Skip this save", and, before a launch, "Cancel launch"

#### Scenario: Switch mods
- **WHEN** the user picks "Pull and switch mods"
- **THEN** after the pull, TriOS changes the current loadout to the save's mods. The tracked profile is not changed and shows Modified. Mods that are not installed are skipped and stay listed.

#### Scenario: Several saves want their mods
- **WHEN** "Pull and switch mods" was picked for more than one save in one sync
- **THEN** TriOS uses the mods of the save with the newest save date

#### Scenario: Different game version
- **WHEN** the manifest's game version differs from this PC's game version
- **THEN** the mod check also says "This save was written by Starsector <version>. This PC has <version>."

### Requirement: Safe writes and backups

TriOS SHALL write each synced copy and manifest under a `.tmp` name and rename it when complete. The synced copy SHALL be renamed before its manifest. TriOS SHALL check a pulled copy's SHA-256 against its manifest before unpacking it. Temporary folders SHALL go one level down, inside a hidden `.trios-sync` folder in the synced saves folder, and SHALL be removed after each run. The game lists every folder directly inside the saves folder that holds a `descriptor.xml`, whatever its name, so a temporary save folder must never sit there. TriOS SHALL never delete save data outright. A replaced save or synced copy SHALL first go to `<TriOS config folder>/save_sync_backups/<item>/<timestamp>_<reason>/`. TriOS SHALL keep the newest 5 backups of each item and remove older ones.

#### Scenario: Copy is newer than its manifest
- **WHEN** another PC has renamed a new synced copy into place but not yet its manifest
- **THEN** the SHA-256 does not match, and TriOS shows "Waiting for the cloud client to finish" instead of pulling

#### Scenario: Unpacking fails
- **WHEN** unpacking a pulled copy fails part-way
- **THEN** the temporary folder is removed and the local save is unchanged

#### Scenario: Sixth backup
- **WHEN** a save gets its sixth backup
- **THEN** its oldest backup is removed

### Requirement: Slow and offline cloud drives

A read from the sync folder SHALL fail with a clear message if no data arrives for 60 seconds. A pulled copy SHALL be copied to a local temporary file before it is unpacked.

#### Scenario: Cloud client offline
- **WHEN** a synced copy is a cloud-only placeholder that the cloud client cannot download
- **THEN** TriOS reports "Could not read <file> from the sync folder. Your cloud client may be offline or still downloading it." and the local save is unchanged

### Requirement: Missing saves and removing synced copies

A synced save that is missing on this PC SHALL never be restored by itself, and its synced copy SHALL never be removed by itself. The user SHALL be able to do either with a button.

#### Scenario: Restore a missing save
- **WHEN** a synced save is "Missing on this PC" and the user clicks "Restore from sync folder"
- **THEN** TriOS pulls it, with the same checks as any pull

#### Scenario: Remove a synced copy
- **WHEN** the user clicks "Remove from sync folder" on a save
- **THEN** its synced copy and manifest go to backups, and its sync record is dropped
- **AND** any PC that still syncs that save writes it back at its next sync

### Requirement: Archiving a synced save

When the save archiver archives a synced save, save sync SHALL stop syncing it on this PC without asking. Restoring the archived save SHALL NOT make it a synced save again.

#### Scenario: Archive a synced save
- **WHEN** the user archives a synced save
- **THEN** it is no longer a synced save on this PC, and it does not show "Missing on this PC"

### Requirement: Save names

TriOS SHALL name synced copies with `String.fixFilenameForFileSystem()`, and the manifest SHALL keep the original folder name. A pulled save SHALL be unpacked under its original folder name. TriOS SHALL refuse to sync two saves whose folder names differ only by letter case.

#### Scenario: Case clash
- **WHEN** the sync folder holds `save_Foo_1` and the synced saves folder holds `save_foo_1`
- **THEN** both show "Name differs only by letter case from another save", and neither is synced

### Requirement: Common folder

When the common folder option is on, which it SHALL be by default, TriOS SHALL sync each file in `<synced saves folder>/common` as its own item, using the same decision table, conflict choices (without "Keep both"), backups, and blocklist as saves. Files SHALL be stored in the sync folder as plain copies, not packed.

#### Scenario: Two PCs change different files
- **WHEN** PC A changed `LunaSettings/nexerelin.json.data` and PC B changed `magic_achievements.json.data` since the last sync
- **THEN** each file syncs on its own, and there is no conflict

#### Scenario: Turned off
- **WHEN** the user turns the common folder option off
- **THEN** TriOS stops reading and writing common folder files, and leaves the synced copies in place

### Requirement: Sync blocklist

The sync blocklist SHALL be `sync-blocklist.txt` in the sync folder, shared by every PC. It SHALL use `.gitignore` rules against paths that start with `saves/<save folder>/`, `mods/<mod folder>/`, or `common/`:
- A pattern with no slash, or only a trailing slash, matches at any depth.
- A pattern with a slash in the middle matches from the start of the path.
- `!` takes a file back out of the blocklist. `#` starts a comment.

TriOS SHALL create the file once, with comments explaining the rules and the lines `.git/` and `common/*cache*`. The user SHALL be able to edit it in the Save sync dialog or in any text editor. TriOS SHALL NOT rewrite the file except when the user saves it from the dialog.

#### Scenario: Blocked file is not copied
- **WHEN** a mod folder contains `.git/`
- **THEN** the `.git` folder is not packed, not hashed, and not written to the sync folder

#### Scenario: Blocked files survive a pull
- **WHEN** a pulled copy replaces a local folder that holds blocked files
- **THEN** this PC's blocked files are moved into the new folder

#### Scenario: Blocklist changed
- **WHEN** the blocklist changes
- **THEN** content hashes are worked out again with the new list, and items whose copies now match are marked up to date

### Requirement: Where sync shows

Every sync SHALL be recorded in the activity panel. A sync that starts or finishes while the panel is closed SHALL show the activity button's popup, which does not block anything. Save sync SHALL open a dialog by itself only right after the user clicks Launch, for questions that hold up the launch: another PC's sync lock, a conflict, the mod check, or a large mod sync. At any other time, a question SHALL appear in the popup and the activity panel with a "Resolve…" button, and the dialog SHALL open only when the user clicks it.

#### Scenario: Conflict found after the game closes
- **WHEN** the push after the game closes finds a conflict
- **THEN** the popup and the activity panel show it with "Resolve…", no dialog opens by itself, and the save stays "Conflict" until the user resolves it

### Requirement: Save sync dialog and save cards

The Mod Profiles page SHALL have a "Save sync" button that opens the Save sync dialog. The dialog SHALL hold the on/off switch, the sync folder, the synced saves folder, "Sync now", the backups folder with its size and an "Open backups folder" button, the saves list (when needed, as described above), the Mods section, the common folder option, and the blocklist editor.

Each save card SHALL show a sync status icon with a tooltip and an include switch, except when the folders differ. Hovering the icon SHALL show this PC's copy and the synced copy: save time, PC name, and sync time.

#### Scenario: Status values
- **WHEN** a synced save is shown
- **THEN** its status is one of: up to date, will push, will pull, conflict, missing on this PC, waiting for the cloud client, cloud conflict copy found, or error

#### Scenario: Game-running check is off
- **WHEN** save sync is on and the "check if game is running" setting is off
- **THEN** the dialog warns that TriOS can't tell when the game closes, with a button to turn the check on
