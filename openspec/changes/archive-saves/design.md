# Design

## Layout

Everything new is under `lib/save_archiver/`:

| File | What it does |
| --- | --- |
| `save_archiver.dart` | The rules. Archives and restores, and decides when a folder may be removed. No Flutter, no Riverpod. |
| `save_archive_tool.dart` | The four archive operations the rules need, plus the 7-Zip implementation. |
| `models/archived_save.dart` | The note written beside an archive. |
| `archived_save_store.dart` | Writes and reads that note, and lists the archive folder. |
| `save_archive_selection.dart` | The "keep the newest N" arithmetic. |
| `save_archive_manager.dart` | Riverpod providers, and the two calls the UI makes. |
| `save_archives_dialog.dart` | The archive list, and the flows that start a job. |
| `bulk_save_selection_dialog.dart` | The checkbox list with the "newest N" number. |
| `save_archive_runner_dialog.dart` | Runs a batch and shows how each item went. |

Two methods are added to the existing `SevenZip` wrapper:
`listEntriesWithDetails` (sizes and checksums, which `listFiles` does not
return) and `createArchiveFromFolder`.

`lib/mod_profiles/save_reader.dart` gains a top-level `parseSaveDescriptor`,
split out of `SaveFileNotifier.readSave`, so a descriptor read out of an
archive is parsed by the same code as one read off disk.

## Why the tool is behind an interface

`SaveArchiveTool` has four methods and exists so tests can hand the archiver an
archiver that fails in one exact way: writes nothing, writes a damaged file,
loses one entry from its listing, reports a size that is one byte off, reports
a checksum that does not match, unpacks the wrong bytes. Those are the cases
that would cost somebody their save, and none of them can be triggered on
demand with a real 7-Zip.

The real 7-Zip is then tested separately, end to end, on real files — including
an empty file, a non-ASCII filename, 200 KB of random bytes, and a nested
folder — checking the bytes match after a round trip.

## The order of operations, and why

Archiving:

1. Refuse anything that is not a folder sitting **directly inside** the saves
   folder. This is the guard that means a wrong path can never take out
   something else, and it is checked before anything is read or written.
2. Read the folder: every file, its size, and its CRC32. A shortcut or symlink
   stops the job, because there is no way to check one against an archive.
3. Compress to `<name>.7z.part`. The partial name matters: a crash halfway
   through cannot leave a file that looks like a finished archive.
4. Integrity check, then compare every file in the folder against the archive
   listing by name, size, and checksum.
5. Rename `.part` to `.7z`, after checking nothing else took that name while
   the compression was running.
6. Only now remove the folder, to the recycle bin.
7. Check the folder is actually gone. A remover that quietly does nothing must
   not be reported as success.

The `.part` file is deleted on every exit path, because it only ever survives
when something failed.

Restoring:

1. Integrity check the archive.
2. Work out the folder name inside the archive and refuse if a save folder of
   that name is already in the saves folder.
3. Unpack into a temporary folder next to the archive.
4. Check what came out against the archive's listing, by size and checksum.
5. Check the target name is *still* free — unpacking takes time, and the game
   can write a save while it runs.
6. Move into place. If the move fails partway, take the half-copied folder back
   out, so nothing in the saves folder looks like a save and fails to load.
7. Remove the archive only if it was asked for, and only after all of the above.

## The note beside an archive

`save_Wisp_1.7z.info.json`, named after the whole archive file so it can never
collide with an archive. It holds the character name, level, save date, mod
names, and sizes, so the list can be drawn without unpacking anything.

It is a convenience, never a source of truth. Three fallbacks, in order:

1. Read the note.
2. Read `descriptor.xml` out of the archive, and write the note for next time.
3. List the archive with just its file name.

An archive TriOS cannot describe still shows up and can still be restored.
Failing to *write* the note is logged and otherwise ignored — the archive is
already safe by then, and a failed note must not turn a finished archive into a
failed one.

## Where archives go

`TriOS_Save_Archives`, beside the saves folder rather than inside it. The game
scans the saves folder for folders, and there is no reason to make it look at
ours. Changeable in the archive dialog, stored as
`Settings.customSavesArchivePath` plus `useCustomSavesArchivePath`, matching
how the other custom paths work.

Archiving refuses outright when the archive folder is inside the save folder
being archived, which would have it compressing its own output.

## Naming an archive

`<save folder name>.7z`, and if that name is taken, `<name> (2).7z` and so on.
Never an overwrite: the file that is already there might be the only copy of
something.

## Progress and cancelling

The batch dialog is modal and runs one job at a time. "Stop after this one"
skips everything remaining but never interrupts the job in flight, because a
half-finished job is the only way this feature could lose anything.

7-Zip is run through `Process.run`, which gives no progress inside a single
file, so each row shows the step it is on — compressing, verifying, removing
original — rather than a percentage.

## What is checked before every job, not once per dialog

Whether the game is running, and whether the saves folder is known. A batch of
big saves takes minutes, and somebody can start the game in the middle of one.
