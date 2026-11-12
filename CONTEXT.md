# TriOS

An all-in-one Starsector launcher, mod manager, and toolkit. This glossary fixes the words the project uses for its own concepts, so the code, the UI, and conversations about them agree.

## Appearance

**Theme**:
A named set of colours someone picks to change how TriOS looks. It covers colours, the font, and the app name, but not the app icon.
_Avoid_: Skin, palette, colour scheme

**Built-in theme**:
A theme that ships inside TriOS. Replaced wholesale whenever TriOS updates.
_Avoid_: Default theme, stock theme

**User theme**:
A theme someone wrote themselves. Kept outside the install folder so a TriOS update never removes it.
_Avoid_: Custom theme, personal theme

**Theme id**:
What TriOS remembers when someone picks a theme. Separate from the theme's display name, so renaming a theme doesn't lose the selection.
_Avoid_: Theme key, theme name

**Theme modifiers**:
Settings that change TriOS's appearance regardless of which theme is active — the app icon, the app name, and the animated background.
_Avoid_: Theme overrides, appearance settings

## Mod updates

**Muted mod**:
A mod the user has told TriOS to stop mentioning. No version check runs for it at all, so no update ever appears for it anywhere — the Mods page, the Dashboard, or the Catalog. Stays that way until the user unmutes it.
_Avoid_: Ignored mod, silenced mod, hidden mod

**Muted update**:
One version of one mod that the user has told TriOS to stop mentioning. Version checks keep running, and the mod speaks up again by itself as soon as it advertises a different version. For skipping one broken release, as opposed to going quiet on the mod. Not the same as a muted mod.
_Avoid_: Skipped version, ignored update, dismissed update

## Mod sources

**Mod source**:
A record of where TriOS learned about a mod — the version checker, the catalog, a forum thread, or a download. Collected automatically as TriOS encounters the mod.
_Avoid_: Mod origin, mod link, mod record (that's the container holding all of a mod's sources)

**Source override**:
A value the user typed in to replace what a mod source collected automatically. Wins over the automatic value, field by field, and survives automatic re-collection.
_Avoid_: Manual link, user link, custom source

## Grids

**Frozen column**:
A column the user has told a grid to keep in view while the other columns scroll sideways. Frozen columns always sit leftmost, keeping their order relative to each other. Named after Excel's "freeze panes".
_Avoid_: Pinned column (pinning is the grids' word for rows held at the top), sticky column, locked column

## Saves

**Archived save**:
A save that TriOS packed into one compressed file and moved out of the saves folder to free disk space. The user can restore it later.
_Avoid_: Save backup, compressed save

## Save sync

**Save sync**:
Opt-in copying of the saves the user picks, and of the common folder, between their PCs through a sync folder. TriOS reads and writes the folder. A cloud client the user already runs copies it between PCs.
_Avoid_: Cloud saves, save upload, save backup

**Common folder**:
The game's `saves/common` folder, where the game and mods keep settings and unlocks that every campaign shares.
_Avoid_: Shared saves folder, global settings

**Sync blocklist**:
File patterns, written like `.gitignore` lines, for files that save sync never copies.
_Avoid_: Ignore list, exclude list, sync filter

**Synced save**:
A save the user has picked for save sync on this PC. Each PC has its own synced saves.
_Avoid_: Picked save, selected save, ticked save

**Sync folder**:
The folder that save sync reads and writes. Something other than TriOS (Dropbox, OneDrive, SeaDrive, Syncthing) keeps it the same on every PC. Its path can differ between PCs.
_Avoid_: Cloud folder, remote, sync target

**Synced saves folder**:
The saves folder that save sync reads and writes on this PC. The user picks it, and it can differ from the saves folder the rest of TriOS shows.
_Avoid_: Sync folder (that's the shared one), save sync folder

**Mod sync**:
The opt-in part of save sync that also copies mod folders through the sync folder, so a pulled save has its mods on the other PC. The user chooses whether it copies every mod folder or only the mod versions the synced saves use.
_Avoid_: Mod upload, mod mirror, mod backup

**Synced copy**:
The copy of a save or mod folder that sits in the sync folder. It is what another PC takes when it pulls that save or mod.
_Avoid_: Save archive, archived save (both belong to archiving), remote save

**Sync record**:
What a PC remembers about a save or mod folder from its last successful sync. It tells whether this PC's copy, the synced copy, or both have changed since.
_Avoid_: Sync state, last-sync cache

**Sync lock**:
A file a PC puts in the sync folder while its game is running, so other PCs can warn that newer saves may still be on the way.
_Avoid_: Lock file, sync session (the session is the stretch of time; the lock is the file)

**Sync session**:
The time from the game starting until TriOS has written this PC's changed saves and mods to the sync folder after the game closes. This PC's sync lock stays in the sync folder for the whole session.
_Avoid_: Play session
