# Modpacks: create, save, share, and maintain mod lists

Status: ready-for-agent

## The problem

TriOS can share one mod and its dependencies, and mod profiles can copy an
exact local loadout as text. Neither workflow supports a curated mod list that
another player can save, inspect, update, and install over time.

Players currently assemble large mod lists by hand. Recipients install each
mod separately and have no durable view of the list inside TriOS. Creators
cannot publish membership changes to people who already saved the list.

## The solution

Add a Modpacks library and editor to TriOS. A modpack is a versioned,
shareable definition of mods and their download sources. It may label the
intended Starsector version and include a creator note and optional label for
each item. People can create a pack from installed mods, add and remove items with drag-and-
drop or checkboxes, save unfinished drafts, and share finished packs with one
link.

Opening a link or dropping a modpack file shows a preview. The person chooses
whether to add it to the library or install from it. Installation remains
selective, runs in the background, and enables mods only when the person asks.
The library calculates which items are installed and checks versioned online
definitions for updates.

The complete pack remains compressed inside every link. TriLink stays a
static launcher with no pack database. An optional update URL lets a creator
host newer integer versions of the definition elsewhere.

## In scope

- A persistent Modpacks library with search, useful filters, installed-item
  counts, source problems, drafts, and in-page installation progress.
- A two-pane editor with drag-and-drop and checkbox-based bulk actions.
- Creation from an empty pack, selected installed mods, or a mod profile.
- Compact stable pack IDs and required positive integer versions managed by
  TriOS.
- Item source selection, dependency checks, catalog recovery hints, shared item
  notes and statuses, a display-only Starsector-version label, and per-pack
  drafts containing unresolved items.
- Link and file import, preview, add-without-installing, selective install,
  partial failure recovery, and optional enabling during or after installation.
- Online update checks, version comparisons, definition comparisons, and
  explicit handling for pack-ID changes.
- Readable modpack file import and export.
- TriLink launcher-page support, released with the TriOS changes.
- Replacing prominent profile copying with Create modpack while retaining
  legacy profile import and export in an overflow menu.

## Related change

`explicit-profile-saving` must ship before, or in the same release as, the
bulk-enable action. It stops tracked profiles from changing automatically when
the enabled loadout changes.

## Out of scope

- Creating a profile from a modpack. The exact-variant behavior needs a later
  design.
- Adding a brand-new item that is not installed locally. Existing remote items
  remain editable when their mods are absent.
- A hosted pack registry, short codes, accounts, or proof of authorship.
- Automatic uninstalling or disabling when a pack changes.
- Automatic field-by-field merges, revision history, or rollback UI.
- Forum BBCode and pack badges.
- Removing support for the legacy shared-profile text format.
