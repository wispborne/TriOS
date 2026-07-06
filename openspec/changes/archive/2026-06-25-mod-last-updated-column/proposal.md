# Proposal: "Last Updated" column for the Mods page

## Problem

The mod manager grid shows when a mod was **First Seen** and when it was **Last Enabled**, but
there is no way to see when a mod was last *updated* — i.e. when the user most recently installed a
newer version of it. Users who want to know "what have I updated recently?" or sort their mod list by
recency-of-update have no column for it.

## Proposed solution

Add a new sortable, hideable **Last Updated** column to the mod manager grid, modelled on the existing
**First Seen** / **Last Enabled** columns.

"Last updated" is defined as **the timestamp at which the highest-version variant the user currently
has installed was first seen by TriOS** — regardless of whether that variant is enabled. For a mod the
user has installed exactly once, this equals its first-install time; when they later install a newer
version, it advances to the new version's install time.

The underlying data already exists: `ModVariantMetadata.firstSeen` is recorded per variant when each
version is first seen, and `Mod.findHighestVersion` already identifies the newest installed variant. No
new persisted state or write paths are needed — the value is **derived** at render time, exactly like
the existing date columns.

## Scope

- Add a `lastUpdated` entry to `ModGridHeader` and `ModGridSortField`.
- Add the column definition (cell, header, sort value, CSV value) to the mods grid, hidden by default.
- Add a `getSortValueForLastUpdated` helper alongside the existing sort-value extensions.
- Wire the new header into the header-text and sort-field `switch` statements.

## Non-goals

- No new persisted field and no changes to install/enable logic — the value is derived from existing
  metadata.
- No change to the **First Seen** or **Last Enabled** columns.
- No backfill: mods present before TriOS was first installed will show their TriOS-first-run time, the
  same limitation the existing **First Seen** column already has.
- No special handling for variants the user has since deleted (see design for the edge case).
