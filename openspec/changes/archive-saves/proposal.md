# Archive saves

Status: ready-for-human

## The problem

Starsector saves are big and they pile up. A long campaign with a lot of mods
runs to hundreds of megabytes per save, and the game writes a new folder every
time you start a fresh run. People end up with a saves folder holding a dozen
campaigns they are not playing, a load list they have to scroll through, and
tens of gigabytes of disk gone.

The obvious fix — zip the old ones up and delete the folders — is something
people already do by hand, and it is exactly the kind of manual work that goes
wrong. Zip the folder, delete it, find out later the zip was written to a full
disk. That save was a few hundred hours.

Nothing in TriOS helps with any of this today. The Mod Profiles page lists
saves and can build a profile from one, and that is the whole of it.

## The solution

A save can be archived: compressed into a single `.7z` beside the saves folder,
with the folder removed afterwards. Archived saves are listed in a dialog and
can be put back at any time.

Two ways in, because the two jobs are different:

- **One at a time.** Every save card on the Mod Profiles page gets an archive
  button. One confirmation, then it runs.
- **In bulk.** "Archive saves" opens a list of every save with a checkbox, and
  a number at the top: keep the newest N. Changing the number reticks the list;
  every tick can then be changed by hand. Nothing is archived that is not
  ticked. "Restore saves" is the same dialog pointed the other way.

The whole feature is built around one rule: **a save folder is only ever
removed once there is an archive that provably holds every byte of it.**
"Provably" means, in order:

1. The archive passes 7-Zip's own integrity check.
2. Every file in the folder is found in the archive, at the same size.
3. Every one of those files matches by CRC32 checksum, computed from the file
   on disk and compared against what 7-Zip recorded.

Only then does the folder go, and it goes to the recycle bin where the system
allows it. Any failure at any step leaves both the folder and the compressed
file exactly where they were, and says what went wrong in plain words.

The same care applies in the other direction. Restoring unpacks into a
temporary folder, checks what came out against what the archive says it holds,
and only then moves it into the saves folder — and never over a save folder
that is already there. The archive is kept unless you tick the box to remove
it, and that box is off by default.

## Why 7-Zip

It is already in the app, already shipped per platform, and already wrapped
(`lib/compression/seven_zip/`). It records a CRC32 per file, which is what
makes the verification above possible without reading the archive back out.

## In scope

- Archiving a save folder to `.7z` with verification, and removing the folder
  afterwards.
- Restoring an archive back into the saves folder, with verification.
- A dialog listing archived saves, with restore, delete, and show-in-folder.
- Bulk archive and bulk restore dialogs, both with a "newest N" starting point
  and per-item checkboxes.
- A small JSON note beside each archive so the list can show a character name
  and date without unpacking anything, with the archive's own `descriptor.xml`
  as the fallback.
- Choosing where archives are kept, defaulting to `TriOS_Save_Archives` beside
  the saves folder.
- Tests: the safety rules against a stand-in archiver that can be told to fail
  in one exact way, plus a full round trip against the real 7-Zip binary.

## Out of scope

- **Archiving while the game is running.** Refused, with a message saying why.
  Working out whether the game has a particular save open is not worth it when
  "close the game first" is a complete answer.
- **Archiving to a cloud folder or a remote drive.** The archive folder can be
  set to anything the OS presents as a folder, but nothing here is aware of
  sync clients or network drops.
- **Scheduled or automatic archiving.** Nothing archives on its own. Every job
  here starts with somebody pressing a button.
- **Restoring a single file out of a save.** Whole folders only.
- **The game's own save compression** (the `compressed` flag in
  `descriptor.xml`). It is untouched; 7-Zip compresses whatever is there.
