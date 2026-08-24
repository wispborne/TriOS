# Muting mod updates from the Mod Catalog

Status: ready-for-agent

## The problem

The Mods page lets you mute a mod's updates. There are two kinds of mute, and
they behave differently:

- **Mute the mod.** `areUpdatesMuted` on the mod's metadata. TriOS stops
  checking that mod's version altogether and never mentions it again.
- **Mute one update.** `mutedUpdateVersion` holds a single remote version
  string. Checks keep running, and once the mod advertises a different version
  the mute stops matching on its own. This is for one broken release, not for
  going quiet on a mod forever.

Both live in `ModMetadata` (`lib/trios/mod_metadata.dart`), and both the Mods
grid and the Dashboard respect them.

The Mod Catalog does not. A muted mod's catalog card still gets a blue status
bar down its edge and an "Update" button, and still counts toward the
"Has Update" filter's badge. There is no way to mute or unmute from the Catalog
at all.

It is worse than just an omission. Muting a mod stops future version checks but
leaves the last cached result in place, so the Catalog keeps advertising an
update the user already silenced — and keeps advertising it forever, because no
new check will ever come along to clear it.

## The solution

Teach the Catalog card and the Catalog's filter about the mutes that already
exist. No new setting, no new storage: one mute, read and written from both
pages.

**On the card.** A muted mod stops looking like it has an update. The button
falls back to the inert "Installed" marker and the left status bar goes back to
green or grey. In its place, a small bell sits just left of that marker,
showing whenever the mod is muted entirely or its current update is the muted
one. Right-clicking the bell gives "Recheck" plus the shared mute item, the
same pair the Mods grid's version-check cell offers. The card's own right-click
menu gains the shared mute item too, in its existing "Installed Mod" section.

**In the filter.** The "Has Update" filter and the badge count beside it both
leave out muted mods. A count that includes things you asked not to hear about
is simply wrong. Next to that count, "+ 3" and a bell say how many were left
out, so a muted mod isn't just quietly missing — the same thing the Dashboard's
updates header shows.

The bell and its hover text move out of `VersionCheckIcon` into a small shared
widget, so the icon and the wording are written down once rather than twice.

## In scope

- The shared mute menu item in the Catalog card's right-click menu.
- A muted card presenting as "Installed" rather than "Update available".
- A bell marker on muted cards, with its own small right-click menu.
- The "Has Update" filter and its badge count skipping muted mods, with a
  "+ N" and a bell beside the count for the ones left out.
- Lifting the muted-bell branch out of `VersionCheckIcon` into a shared widget.
- Two glossary entries in `CONTEXT.md`.
- A test that the Catalog's update count and filter leave out muted mods, for
  both kinds of mute.

## Out of scope

- **A show/hide-muted toggle for the Catalog.** The Mods grid and Dashboard
  have one because each has a dedicated Updates section that can hide rows. The
  Catalog lists every mod regardless, and "Has Update" is an opt-in filter, so
  nothing is being hidden and there is nothing for a toggle to reveal.
- **A separate Catalog-only mute.** Muting from the Catalog quiets the Mods
  page and Dashboard too, and vice versa. Two mutes for one mod would be
  confusing to explain and worse to use.
- **Catalog entries with nothing installed.** A mod you do not have cannot have
  an update, so there is nothing to mute. The item only appears inside the
  "Installed Mod" section, which is already hidden in that case.
- **Clearing the stale cached version-check result for a fully muted mod.**
  Hiding it is enough for this change. Purging the cache entry would mean
  deciding what happens on unmute, and unmuting already forces a fresh check.
- **The Catalog's mod details dialog.** It shows no update state today, so
  there is nothing there to make consistent.
