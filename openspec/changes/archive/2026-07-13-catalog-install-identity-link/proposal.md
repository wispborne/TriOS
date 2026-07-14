# Catalog install identity link

## Problem

When you install a mod from the Catalog, its card can keep saying "Install" instead of "Installed". This happens when the name the catalog shows is not the same as the name inside the mod's `mod_info.json`. Real example: the catalog lists "Ashpad" but the mod calls itself "Aashpad", so after you install it, nothing in the app connects the two.

The mod records store (`lib/mod_records/`) was meant to be that connection — each record can hold a mod ID plus a catalog source with the forum thread ID. But a code review found the link is never made reliably:

1. **Catalog installs forget where they came from.** Every install that starts from a catalog entry (card button, card menu, forum post dialog, "Install with TriOS" deep links) passes only a display name and a download URL to the download manager. By the time the file is installed and we know the real mod ID, nothing remembers which catalog entry or forum thread it came from.
2. **The record merge uses the wrong name.** When an install finishes, `batch_installation_notifier.dart` tries to join the catalog-only record onto the real mod's record — but it looks it up by the *installed* mod's name ("Aashpad"), while catalog-only records are filed under the *catalog* name ("Ashpad"). So the merge fails in exactly the case it was built for. When the names already match, matching by name works on its own, so the merge as written adds almost nothing.
3. **Download history records are left disconnected.** `downloadAndInstallMod` writes a download-history record under the raw display name when it doesn't know the mod ID (which is every catalog install). That record never gets joined to the real mod's record.
4. **Matching is only guesses.** The Catalog page matches catalog entries to installed mods by version-checker thread ID, then exact name, then close-enough name. All three fail for Ashpad/Aashpad: the name differs, and the thread-ID match only works if the installed mod ships a `.version` file pointing at the same thread.
5. **The matching code is copied and out of step.** The records store and the Catalog page each have their own copy of nearly the same matching, using different clues (the store checks NexusMods IDs; the page doesn't). They can disagree — a card can show "Installed" while the record store failed to link the same mod. On top of that, three different ways of cleaning up names are used as keys for the same thing (`toLowerCase().trim()`, `alphanumericLower()`, and `ModRecord.syntheticKey()`); the failed merge in point 2 is a wrong-key bug of exactly this kind. Any new feature that needs the link would today become a third copy of the matcher and a fourth way of cleaning up names.

## Proposed solution

Two parts: make the link *get made* reliably, and make it *get read* from one place.

**Making the link.** Carry the catalog identity (catalog name, forum thread ID, NexusMods ID) along with the download, all the way through installation. When the install finishes and we know the real mod ID, write the link into the mod records store: attach the catalog source to the real record, and join in any catalog-only record filed under the *catalog* name. The source is a required parameter (it can be null, but you have to say so) at the one place installs pass through, so any future install path won't compile until its author decides what the source is.

**Reading the link.** Pull the matching into one shared module: a single standard name-key function, one matching function (saved install-time link first, then thread ID, NexusMods ID, exact name, close-enough name), and a `catalogLinksProvider` that exposes the links both ways (catalog entry → installed mod, and mod ID → catalog entry). The records store, the Catalog page, and any future feature that needs the link all read from it, so they can never disagree. The old guesses stay inside the matcher as a fallback for mods installed outside the catalog.

## Scope

- New shared linking module: one standard catalog-entry key, one matching function with clues in a set order, and a provider that exposes links both ways plus which clue produced each match.
- Carry a small "where this download came from" value through: catalog card/menu/dialog install actions → download confirm → download manager → batch installer finish. Required parameter at the entry points.
- Same for the "Install with TriOS" deep-link path when the deep link points at a single mod.
- When the install finishes, write the catalog link (and download history) onto the real mod ID's record; fix the record merge to use the catalog name (through the standard key).
- Rewire the records store's auto-populate and the Catalog page's status map onto the shared matcher/provider, treating the saved install-time link as the one to trust.
- Confirm cards, the forum post dialog, and the details dialog all show "Installed" through the shared provider.

## Non-goals

- No fixing of mods that are already installed and unlinked (e.g. the existing Aashpad install). Reinstalling from the catalog will make the link; the mod record sources dialog's manual override is still the way out.
- No changes to how the catalog is read from the forum or how names are made upstream.
- No new matching guesses (e.g. matching download URLs against catalog links); the exact install-time link makes those unnecessary.
