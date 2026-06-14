# Unify mod installation onto one path

## Problem

There are two completely separate code paths that install a mod, and they
duplicate a lot of the same work in slightly different ways:

- **The batch installer** (`BatchInstallationNotifier`, in
  `lib/mod_manager/batch_installation/`). Handles archives (`.zip`, `.7z`, …)
  picked or dropped. Scans everything first, shows one combined picker, and
  extracts several mods at once.
- **The single-mod installer** (`installModFromSourceWithDefaultUI` /
  `installModFromDisk`, in `lib/mod_manager/mod_manager_logic.dart`). Handles
  one source at a time: a folder, or an archive that just finished downloading.
  Feeds the floating download notification, writes install info to the mod
  records, and pops up an error dialog when something fails.

Both parse `mod_info.json`, check for an already-installed copy, show the same
selection dialog, delete-then-replace on conflict, pick the destination folder
name, call the shared `installMod()`, reload the mod list, and re-enable the new
version if the old one was on. Keeping both means every change to install
behavior has to be made twice, and the two paths have already drifted (for
example, archives installed through the batch installer never get an
`InstalledSource` mod record, but folders installed through the single-mod
installer do).

The single-mod installer is the older path; the batch installer is the newer,
more capable one (it already does concurrent extraction, pre-scanning, and a
combined picker). We want to keep the batch installer and retire the single-mod
installer.

## What we're doing

Teach the batch installer the few things only the single-mod installer can do,
point every caller at the batch installer, then delete the single-mod installer.

Features the batch installer needs to gain:

1. **Install from a folder**, not just an archive. Today its scanner only reads
   archives.
2. **Drive the floating download/install notification.** The notification reads
   live progress, the finished result, and cancellation from a `Download`
   object. The batch installer currently tracks progress on its own entries and
   never touches a `Download`.
3. **Write install info to the mod records** (the `InstalledSource` entry, plus
   merging a catalog-sourced placeholder record into the real one once the mod
   is actually installed).
4. **Show the install-error dialog** when one or more mods fail.

Callers to repoint at the batch installer:

- Picking a `mod_info.json` file — `lib/widgets/add_new_mods_button.dart`
- Dropping a folder — `lib/trios/drag_drop_handler.dart`
- Finishing a download — `lib/trios/download_manager/download_manager.dart`

Then remove `installModFromSourceWithDefaultUI` and `installModFromDisk`,
keeping the shared helpers they call (`installMod`,
`setUpNewHighestModVersionFolder`, the variant-cleanup and activation helpers),
which the batch installer already uses.

## Scope

In scope:
- Folder support in the batch installer's scanner and entry model.
- Linking an optional `Download` to a batch entry and driving its notifiers.
- Moving the mod-records write and the error dialog into the batch installer.
- Repointing the three callers above.
- Deleting the two retired methods and any code left unused only by their
  removal.

## Non-goals

- No change to the actual extraction/copy step (`installMod` and the
  `ModInstallSource` classes stay as they are).
- No change to how downloads are fetched over the network, redirect handling,
  or the download queue.
- No redesign of the batch installer's UI, the activity panel, or the toast.
- No new install entry points; this only consolidates existing ones.
