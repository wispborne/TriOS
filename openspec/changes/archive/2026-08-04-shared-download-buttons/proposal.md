# One download button, reused everywhere

## The problem

TriOS has at least seven places where you can start a mod download, and every
one of them was written from scratch:

| Where | How it knows a download is running | What it shows |
| --- | --- | --- |
| Catalog card button (`catalog_mod_card.dart`) | matches by mod name | spinner in the button, plus a hand-rolled 10-second "clicked" timer |
| Catalog details dialog (`catalog_mod_details_dialog.dart`) | **it doesn't** | nothing |
| Forum post dialog (`forum_post_dialog.dart`) | **it doesn't** | nothing |
| Dashboard mod list (`mod_list_basic_entry.dart`) | matches by download URL | spinner in place of the update icon |
| Mods grid (`mods_grid_page.dart`) | matches by download URL | spinner in place of the update icon |
| Mod info dialog (`mod_info_dialog.dart`) | matches by download URL | spinner in the Update button |
| Missing-dependency buttons (`mods_grid_page.dart`) | **it doesn't** | nothing |

Three problems come out of that:

1. **The dialog buttons look broken.** You click Install in the catalog details
   dialog or the forum post dialog, and nothing about the button changes. This
   is the bug that started this.
2. **The same code is copy-pasted.** The spinner block — a `ListenableBuilder`
   over the task's status, byte count and install progress, working out whether
   to say "Downloading…" or "Installing…" — is written out almost identically
   three times.
3. **The buttons disagree with each other.** The catalog button matches
   downloads by mod name; the update buttons match by URL. So starting an update
   from the dashboard doesn't light up the catalog card for the same mod, and a
   catalog install doesn't light up the dashboard row. Neither match is
   reliable: a catalog install doesn't know the mod's real id until the archive
   is unpacked, and a version-check update doesn't know the catalog name.

Adding an eighth download button today means writing all of this again, badly.

## The solution

Put the "is this thing downloading, and how far along is it?" question in one
place, and give the app one download button widget that answers it.

Three new pieces:

- **A download target.** A small value that says what a button is about — a mod
  id, a download URL, or a catalog entry name. One lookup matches a target
  against the live downloads using every clue a download carries (its URL, its
  mod id once known, its catalog name, its display name), so the catalog card
  and the dashboard row finally agree.
- **A "just clicked" state.** The catalog card's private busy timer becomes
  shared. Some downloads take a moment to register — a TriOS deep link has to
  resolve and ask for confirmation first — so every button can now show it's
  working straight away instead of looking dead.
- **A shared button and a shared builder.** `ModDownloadButton` for the buttons
  that have a label ("Install", "Update"); `ModDownloadStatusBuilder` for the
  places that swap a small icon for a progress ring. Both handle the spinner,
  the percentage, the "Downloading…" / "Installing…" tooltip, and blocking
  repeat clicks.

Then convert all seven call sites to use them.

## In scope

- The shared target, lookup, "just clicked" state, button and builder.
- Converting all seven download buttons listed above, including the two dialog
  buttons and the missing-dependency buttons that show no progress today.
- Deleting the copy-pasted spinner blocks and the catalog card's private timer.

## Out of scope

- The download engine itself (`downloader.dart`, queueing, retries, resume).
  Nothing about how files are fetched changes.
- The Activity Panel, the toolbar activity icon, and toasts. They summarise
  *all* downloads at once, which is a different job. They may reuse the new
  status type later, but not in this change.
- Pausing, resuming or retrying a download from a button.
- Any change to what a click actually does — the same download starts, the same
  dialogs appear.
