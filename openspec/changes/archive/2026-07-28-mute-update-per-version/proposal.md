# Mute a single update version

## Problem

When a mod author publishes a broken version-checker file — wrong version number, a download link that 404s — TriOS shows an update notice the user can't act on. Today the only way to silence it is "Mute Updates", which is permanent and hides every future update for that mod. Users who mute a broken update tend to forget, and then miss the real release.

So the user has to pick between a notice that nags about something broken, or going quiet on a mod forever.

## Proposed solution

Add a second, lighter option next to the existing one: mute just the version currently being advertised.

TriOS records the version number the user muted. While the remote version-checker file keeps advertising that same number, no update notice shows. As soon as the author changes the number — a corrected version, or a genuine new release — the notice comes back on its own. The user doesn't have to remember anything.

The permanent "Mute Updates" option stays exactly as it is. The two work independently, and permanent mute wins if both are set.

## In scope

- A new "Mute this version" option in the same context menus as "Mute Updates".
- Storing the muted version number in mod metadata, per mod.
- Hiding the update notice in the four places that already respect "Mute Updates": the mods grid's pinned updates list, the dashboard's updates list, update sort order, and the update icon.
- A distinct icon and tooltip so a paused version reads differently from a fully muted mod.
- Showing the muted version in the mod info dialog, alongside the existing mute status line.

## Out of scope

- Changing how "Mute Updates" behaves.
- The catalog, the chatbot's "what has updates" answer, and the update button inside the mod info dialog. These already ignore the existing "Mute Updates", and making them respect both mutes is a separate cleanup.
- Muting more than one version of a mod at a time.
- Any new setting. The existing "show all / hide muted" toggles treat a version-muted mod as muted.

## Known limitation

The mute is keyed to the version number, so it won't lift if the author republishes under the *same* number. The common case is an author bumping their version-checker file to 1.5.0 before the file is actually uploaded: the user mutes 1.5.0, the author later uploads the real 1.5.0, and the number never changed — so the notice stays hidden until the user unmutes by hand.

We accept this. The alternatives (fingerprinting the whole version file, or a time limit) cost more and bring their own noise. To soften it, the muted version is always visible: the icon and tooltip name it, the mod info dialog shows it, and the existing "show all updates" view still lists the mod.
