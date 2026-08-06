# Design

## The shape of it

Four small pieces, then seven conversions.

```
DownloadTarget          what a button is about (mod id / url / catalog name / display name)
  ↓
findActiveDownload      function: downloads + target → the matching Download, if any
pendingDownloadClicks   notifier: targets clicked but not yet visible as downloads
  ↓
ModDownloadStatusBuilder   widget: target → ModDownloadStatus (phase, progress, label)
  ↓
ModDownloadButton          widget: the labelled button built on top of the builder
```

## New files

| File | What's in it |
| --- | --- |
| `lib/trios/download_manager/download_target.dart` | `DownloadTarget`, the matching rules, `findActiveDownload`, `pendingDownloadClicks` |
| `lib/widgets/mod_download/mod_download_status.dart` | `ModDownloadStatus` and `ModDownloadStatusBuilder` |
| `lib/widgets/mod_download/mod_download_button.dart` | `ModDownloadButton` |

## Key decisions

### Matching stays outside the `Download` model

`Download` already carries everything needed to identify itself: the URL on
`task.request`, `displayName`, `sourceHint.catalogName`, and (for `ModDownload`)
`modInfo.id`. So the matching rules go in one function, and the model doesn't
change. No migration, no new field to keep in sync.

Why several clues instead of one key: a catalog install genuinely does not know
the mod's id until the archive is unpacked, and a version-check update does not
know the catalog name. Neither side can be forced onto a single key, which is
exactly why the two halves of the app ended up matching differently.

Order matters: mod id first (exact), then URL, then catalog name, then display
name. Two different mods sharing a display name could give a false match. The
cost is a spinner on the wrong button, so it's acceptable — but the fuzzy checks
are deliberately last.

### Progress stays on `Listenable`, not Riverpod

`task.status`, `task.downloaded` and `installProgress` are `ValueNotifier`s. The
download manager deliberately does *not* push byte progress through Riverpod —
it would rebuild the whole mod grid several times a second.

So `ModDownloadStatusBuilder` does both halves:

1. `ref.watch(downloadManager)` and pick out *which* download matches (the list
   changes rarely — only on status changes, never per byte).
2. `ListenableBuilder` on that download's notifiers for the numbers (changes
   often, and only rebuilds inside the builder).

This is the same split every existing call site does by hand; it just lives in
one place now.

Lookup is a plain function, not a `Provider.family` keyed on the target. A
family would keep an entry alive for every target it ever saw — one per mod row
— which is a slow leak for no gain.

### The "just clicked" state is app-wide, not per-widget

The catalog card currently keeps `_clickBusy` in its own `State`, with a
`Timer` and a `ref.listen(deepLinkProcessing)`. That's why only that one button
feels responsive.

Moving it into a small `Notifier` holding a set of pending targets means:

- any button can show it, including ones inside a dialog that's about to close;
- the state survives the widget rebuilding;
- the clearing rules (a matching download appears, the deep link flow finishes,
  or 10 seconds pass) are written once.

### The button registers its own click

The pending-click set is matched by plain equality, so whoever registers a click
has to use the *exact* target the button watches. That rules out registering
inside `executeDownloadCandidate` or the download manager: they'd build their
own target from what they happen to know, and a button whose target carries one
extra clue (a mod id, say) would never see it.

So `ModDownloadButton` marks the click itself, right before running the caller's
`onPressed`. The two icon-only sites do the same in their `onTap`. Nothing in
the download-starting code changes.

`hasOwnBusyIndicator` on `executeDownloadCandidate` stays. The card's
right-click menu still runs downloads with no button attached, and that's what
the "Preparing to install…" snackbar is for.

### Two widgets, not one

`ModDownloadButton` covers the five places with a label ("Install", "Update",
"Install X (1.2.3)"). It takes the target, the idle icon, the label, a button
style, and `onPressed`.

The dashboard and mods grid don't have a button — they swap a version-check
icon for a bare progress ring. Forcing those into a button widget would mean a
pile of flags, so they use `ModDownloadStatusBuilder` directly. That's still all
the duplicated logic gone; only the eight lines of layout stay local.

## Files that change

| File | Change |
| --- | --- |
| `lib/catalog/catalog_mod_card.dart` | drop `_clickBusy`, `_busyFallback`, the two `ref.listen` blocks and the download lookup; build with `ModDownloadButton` |
| `lib/catalog/forum_post_dialog/forum_post_header.dart` | `_DownloadSplitButton` becomes a `ModDownloadButton` plus the existing ▾ menu; needs a target passed down per row |
| `lib/catalog/forum_post_dialog/catalog_mod_details_dialog.dart` | pass the target for each download row |
| `lib/catalog/forum_post_dialog/forum_post_dialog.dart` | same |
| `lib/catalog/download_candidate_actions.dart` | unchanged |
| `lib/dashboard/mod_list_basic_entry.dart` | replace the inline lookup + `ListenableBuilder` with `ModDownloadStatusBuilder` |
| `lib/mod_manager/mods_grid_page.dart` | same, in two places (update icon, missing-dependency buttons) |
| `lib/mod_manager/mod_info_dialog.dart` | replace the Update button block with `ModDownloadButton` |
| `lib/trios/download_manager/download_manager.dart` | unchanged |

## Risks

- **A missed conversion leaves two ways to do it.** Guard against this by
  grepping for `downloadManager` and `installProgress` at the end; only the
  shared files, the activity panel, the toolbar icon and toasts should remain.
- **The forum dialog rows have no obvious target.** They're keyed on the row's
  mod name and the candidate URL — both available where the row is built, so the
  target is built there and passed to the button.
- **Behaviour drift.** The dashboard and mods grid spinners currently sit at 22
  and 24 pixels with slightly different padding. Keep the sizes as they are; the
  shared builder reports the state, the call site keeps its own layout.
