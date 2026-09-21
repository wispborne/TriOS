# Tasks

## Step 1 — the archive operations

- [x] Add `listEntriesWithDetails` to `SevenZip`: parses `7z l -slt` into path,
      size, CRC32, and whether the item is a folder. `listFiles` only returns
      paths, which is not enough to tell a complete archive from a truncated one.
- [x] Skip everything before the line of ten dashes when parsing, so the
      archive's own file name is never read as an entry.
- [x] Read folders off the DOS attribute letters (`D`), which work the same on
      Windows and Unix output.
- [x] Add `createArchiveFromFolder` to `SevenZip`. Refuses when the target file
      exists, because `7z a` adds to an archive rather than replacing it.
- [x] Add `SaveArchiveTool` with the four operations the rules need, and
      `SevenZipSaveArchiveTool` on top of the wrapper.
- [x] Add `normalizeArchivePath`, since 7-Zip writes `\` on Windows and `/`
      elsewhere for the same archive.
- [x] Unit tests for the listing parser, including Windows-shaped output, an
      empty listing, and two blocks with no blank line between them.

## Step 2 — the rules

- [x] Add `SaveArchiver` with `archiveSave` and `restoreSave`. No Flutter, no
      Riverpod, and the deleters are handed in so tests can watch them.
- [x] Read a folder's manifest: every file, size, and CRC32, streamed so a
      multi-gigabyte save does not have to fit in memory.
- [x] Refuse a folder holding a shortcut or symlink, which cannot be checked
      against an archive.
- [x] Refuse anything that is not directly inside the saves folder, and the
      saves folder itself.
- [x] Refuse when the archive folder is inside the save folder being archived.
- [x] Compress to a `.part` name, verify, then rename into place.
- [x] Verify: integrity check, then name, size, and checksum for every file.
- [x] Treat a missing checksum on a non-empty file as a failure, not a pass.
- [x] Fall back to a case-insensitive path match only when exactly one entry
      matches, so two files differing only in case can never be confused.
- [x] Remove the folder only after all of that, and check it actually went.
- [x] Delete the `.part` file on every exit path.
- [x] Restore: integrity check, refuse an existing save folder, unpack to a
      temporary folder, verify, recheck the name is free, move into place.
- [x] Take a half-copied folder back out of the saves folder if the move fails.
- [x] Keep the archive unless asked otherwise, and only remove it last.
- [x] Work out the folder name inside an archive, handling an archive somebody
      made by hand with no single root folder.
- [x] Tests against a stand-in tool for each way a job can fail, checking every
      time that the save folder survived.
- [x] Tests against the real 7-Zip binary: round trip byte for byte with an
      empty file, a non-ASCII name, random bytes, and a nested folder; a
      damaged archive; a truncated archive; two saves of the same name.

## Step 3 — knowing what is in an archive

- [x] Split `parseSaveDescriptor` out of `SaveFileNotifier.readSave`, so a
      descriptor from an archive is parsed by the same code as one from disk.
- [x] Add the `ArchivedSave` note model and write it beside each archive.
- [x] Fall back to reading `descriptor.xml` out of the archive when the note is
      missing or unreadable, and write the note for next time.
- [x] List an archive even when neither works, so it can still be restored.
- [x] Sort newest save first, tie-breaking on the file path so a list never
      reshuffles between openings.
- [x] Tests for the round trip, the fallbacks, the sorting, and an archive that
      is not an archive at all.

## Step 4 — picking what to act on

- [x] Add `savesToArchiveKeepingNewest` and `archivesToRestoreNewest`, with
      undated items last and a stable tie-break.
- [x] Tests: keeping none, keeping all, keeping more than there are, a negative
      number, and never returning something that was not passed in.

## Step 5 — the app layer

- [x] Providers for the archive folder, the tool, the archiver, and the list.
- [x] `saveArchivingBlockedReason`, checked before every job rather than once
      per dialog.
- [x] `archiveOneSave` writes the note afterwards, and a failure to write it
      never turns a finished archive into a failed one.
- [x] Deletions go to the recycle bin, falling back to a plain delete.
- [x] Settings: `customSavesArchivePath`, `useCustomSavesArchivePath`, and
      `saveArchiveKeepNewestCount`.
- [x] `Constants.savesArchiveFolderName`.

## Step 6 — the UI

- [x] The archive list dialog: restore, delete, show in folder, and the folder
      row with change and reset.
- [x] The bulk dialog: a "newest N" number that reticks the list, per-item
      checkboxes, select all and none, a running total, and rows that cannot be
      ticked with the reason why.
- [x] The runner dialog: one job at a time, a step label per row, and "stop
      after this one" rather than an interrupt.
- [x] An archive button on each save card on the Mod Profiles page, disabled
      while the game is running.
- [x] An archived-saves button in the Save Games column header.
- [x] Deleting an archive says whether it is the only copy.

## Step 7 — before it ships

- [ ] Try it by hand on a real Starsector install: archive a save, load the
      game and confirm it is gone from the load list, restore it, and load it.
- [ ] Check the archive folder ends up beside the saves folder on Windows,
      macOS, and Linux, including when a custom saves path is set.
