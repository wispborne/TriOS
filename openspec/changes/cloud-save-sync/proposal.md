# Cloud save sync

Status: ready-for-agent

Depends on: `explicit-profile-saving` (on the `modpack-links` branch). Do not start until `modpack-links` is merged into `dev`.

## The problem

Players who use more than one PC can't continue a campaign on both without copying save folders by hand. Copying by hand goes wrong easily. An older save can overwrite a newer one, or a half-copied save gets loaded. A save also only loads if the other PC has the same mods, so players copy mod folders by hand too.

Many players already run a cloud client (Dropbox, OneDrive, Google Drive, SeaDrive, Syncthing) that keeps a folder the same on every PC. TriOS already launches the game and notices when it closes. So TriOS can move saves and mods in and out of such a folder at the right moments.

## The solution

Add **save sync**. It is off by default.

- The user picks a **sync folder** that their cloud client keeps the same on every PC. TriOS never uploads anything or handles accounts.
- The user picks which saves to sync on each PC. TriOS stores each one in the sync folder as a 7-Zip file with a small manifest next to it.
- Before a launch from TriOS, TriOS pulls saves that changed on another PC. After the game closes, it pushes saves that changed on this PC. It also syncs at TriOS start when it finds its own leftover sync lock, and when the user clicks "Sync now".
- TriOS decides what changed by comparing content hashes with what it remembers from the last sync. If both PCs changed a save, TriOS asks. It never picks a side by itself.
- Nothing is deleted outright. A replaced save goes to a local backups folder first.
- **Mod sync** copies mod folders through the same sync folder, so a pulled save has its mods. The user chooses between every mod folder and only the mod versions the synced saves use.
- The game's **common folder** (`saves/common`) syncs too, one file at a time, unless the user turns it off.
- A **sync blocklist**, written like a `.gitignore` file, keeps matching files out of the sync on every PC.

This builds on imoldovavan's fork ([TriOS-sync, `feature/cloud-save-sync`](https://github.com/imoldovavan/TriOS-sync/commits/feature/cloud-save-sync), commit `1571f698`). The parts of the fork that still fit are copied in, with imoldovavan credited as co-author. The rest is written to match the decisions in `design.md`.

## In scope

- Save sync of the saves the user picks on each PC, from a saves folder the user picks for save sync.
- Mod sync, with a choice of every mod folder or only the mod versions the synced saves use.
- Common folder sync, on by default.
- The sync blocklist.
- Sync locks, conflict handling, cloud-client conflict copies, backups, and a mod check before a save is pulled.
- A "Save sync" dialog on the Mod Profiles page, and a sync status icon and include switch on each save card.
- Sync progress and results in the activity panel.
- The game-running check keeps checking while TriOS is in the background during a sync session.
- `String.fixFilenameForFileSystem()` handles reserved Windows names and the other cases listed in `design.md`.

## Out of scope

- TriOS uploading, downloading, or signing in to any cloud service.
- Syncing while the game runs.
- Syncing which mods are enabled. Each PC keeps its own list.
- Passing a deleted save to another PC.
- Downloading mods from their websites.
- Pre-launch pulls when the game is started outside TriOS. TriOS still pushes after the game closes, and says the pull was skipped.
- The fork's own packaging: its self-updater, version tag, and build workflow changes.

## Credit

When this ships, `changelog.md` gets one line crediting imoldovavan for the fork this is based on. The user approved that line.
