## ADDED Requirements

### Requirement: Off by default, part of save sync

Mod sync SHALL be off by default. It SHALL only run while save sync is on, and SHALL use the same sync folder. Its controls SHALL be in the Mods section of the Save sync dialog. The Mods page SHALL NOT change.

#### Scenario: Turned on
- **WHEN** the user turns on mod sync
- **THEN** the Mods section shows the scope choice, the removal choice, a summary line such as "74 up to date, 2 to write", and a list of mods with problems first

### Requirement: Which mod folders sync

A mod folder SHALL be a folder directly inside the mods folder that holds a `mod_info.json` under any name in `Constants.modInfoFileNames`. Other folders SHALL be skipped, as SHALL folders whose names start with `.`. The user SHALL choose the scope:
- **Every mod folder** (the default): every mod folder, including older versions of the same mod.
- **Only mods the synced saves use**: the installed mod versions named in the synced saves' mod lists.

#### Scenario: Folder that is not a mod
- **WHEN** the mods folder holds `DDSCache/` with no `mod_info.json`
- **THEN** mod sync skips it

#### Scenario: Only mods the synced saves use
- **WHEN** the scope is "Only mods the synced saves use" and no synced save uses a mod version any more
- **THEN** its synced copy leaves the sync folder for this PC's backups, and every PC keeps its own copy of the folder

### Requirement: Each mod folder is one item

Each mod folder SHALL be stored as `mods/<folder>.7z` with a manifest, and SHALL use the same decision table, safe writes, hash check, backups, and blocklist as saves. Mod conflicts SHALL offer "Keep this PC's copy", "Keep synced copy", and "Skip for now". There SHALL be no "Keep both", because two folders of the same mod version confuse TriOS and the game.

#### Scenario: Mod updated on another PC
- **WHEN** PC A changed a mod folder since the last sync and PC B did not
- **THEN** PC B moves its copy to backups and pulls PC A's copy

### Requirement: Active version is not a change

When hashing and packing a mod folder, every top-level file named in `Constants.modInfoFileNames` SHALL count as `mod_info.json`, so switching a mod's active version does not change the folder's hash. When a pulled folder replaces a local one, the unpacked `mod_info.json` SHALL get this PC's name for it back. A pulled folder that is new on this PC SHALL get a disabled name if another version of that mod is enabled here.

#### Scenario: Version switched on one PC
- **WHEN** the user switches a mod's active version on PC A
- **THEN** neither version's folder counts as changed

### Requirement: Fast change check

For each mod folder, TriOS SHALL store a fingerprint next to its content hash: file count, total size, and newest file time. If the fingerprint matches, TriOS SHALL use the stored hash instead of hashing the folder again. After a pull, the fingerprint SHALL be taken from the unpacked folder.

#### Scenario: Nothing changed since the last launch
- **WHEN** no mod folder's fingerprint changed
- **THEN** TriOS reads no file contents to decide that mods are up to date

### Requirement: Removed mod folders

When a mod folder with a sync record is missing on this PC, TriOS SHALL do what the user chose:
- **Nothing passes** (the default): the mod shows "Missing on this PC", with "Restore from sync folder" and "Remove from sync folder". Other PCs keep their copies and write the synced copy back if it is removed.
- **Stop syncing it**: this PC moves the synced copy to its own backups and marks the folder as removed in the sync folder. Other PCs keep their own copy and stop writing it back. Pulling a new version of a mod counts as installing it, so each PC's own "keep last N versions" setting runs afterwards.

A removed mark SHALL record the content hash of the removed copy. A PC SHALL write a folder back only if its copy's content differs from that hash, and SHALL then clear the mark.

#### Scenario: Many folders disappear at once
- **WHEN** the choice is "Stop syncing it" and more than 5 mod folders are missing in one sync
- **THEN** TriOS asks before marking any of them as removed

#### Scenario: Old version cleaned up
- **GIVEN** the choice is "Stop syncing it" and PC A keeps the last version only
- **WHEN** PC A updates Nexerelin and removes the old version folder
- **THEN** the old version leaves the sync folder, and PC B keeps its copy without writing it back

### Requirement: Mod sync timing and safety

Mods SHALL sync before the common folder and saves, so the mod check compares against mods that are really there. Mod folders SHALL be pulled first, then pushed. Nothing in the mods folder SHALL be read or written while the game runs. Mod sync SHALL wait until TriOS has finished reading the mods folder. Pulled mods SHALL be unpacked to a hidden temporary folder inside the mods folder, then renamed into place.

#### Scenario: Large mod sync at launch
- **WHEN** a launch would copy more than 500 MB of mods in either direction
- **THEN** TriOS asks "Sync mods now?" with "Not now"
- **AND** "Sync now" never asks

#### Scenario: Progress
- **WHEN** mod sync runs
- **THEN** the activity panel shows lines such as "Reading mod 3 of 76: Nexerelin" and "Writing mod 3 of 76: Nexerelin"
