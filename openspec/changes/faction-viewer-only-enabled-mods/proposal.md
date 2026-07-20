# Faction Viewer: "Only Enabled Mods" filters the data, not just the list

## Problem

The faction viewer (dedicated page and codex page) shows data merged from **every installed mod**, whether the mod is enabled or not. A disabled mod's ships, weapons, doctrine changes, and spawn weights all show up as if they were active.

Both pages already have an "Only enabled mods" checkbox, but it only **hides entries from the list**:

- Dedicated page: a "Only Enabled Mods" field in the filter panel hides factions that come only from disabled mods.
- Codex page: a "Only enabled mods" checkbox hides entries whose mods are all disabled.

Neither checkbox changes the faction data itself. A vanilla faction patched by a disabled mod still shows the patched ship lists and spawn weights. This is misleading: the numbers on screen don't match what the game would actually do with the current mod setup.

The root cause is in the data layer: faction files are merged across all installed mods once, at scan time, and only the merged result is kept. There is no way to filter it afterward.

## Proposed solution

Make "Only Enabled Mods" a real data filter. When checked:

- Faction data is merged from vanilla plus **enabled mods only**. Ship lists, doctrine values, colors, portraits — everything reflects only enabled mods.
- Spawn weights are computed from enabled mods only (both the faction files and `default_ship_roles.json`).
- Factions that only exist because of a disabled mod disappear entirely.
- Vanilla data is always included.

To make this possible, the faction scanner will keep each mod's **raw faction files** instead of the merged result, and the merge will happen on demand in a provider that knows about the toggle. Toggling is then instant — no rescan, no cache rebuild.

Where the checkbox lives:

- **Dedicated page**: a checkbox in the toolbar, labeled "Only Enabled Mods", replacing the current filter-panel field (one checkbox, one meaning). State is saved across sessions.
- **Codex page**: the existing "Only enabled mods" checkbox gains this behavior for faction entries. No new control.

Draft user-facing text (needs sign-off before shipping):
- Checkbox label: `Only Enabled Mods`
- Tooltip: `Show faction data from enabled mods only. Ships, weapons, and spawn weights added by disabled mods are hidden.`

## In scope

- Refactor of the faction data pipeline (raw per-mod cache + on-demand merge).
- The toggle on both pages, wired to the data.
- Spawn weight calculation respecting the toggle.
- The faction profile dialog showing whatever data the opening page has (it receives a faction object, so it follows automatically).

## Out of scope

- Other viewers (ships, weapons, hullmods) — their "only enabled" filters stay list-only.
- The sector map and context menus keep using all-installed-mods faction data (unchanged behavior).
- Filtering the ship list used to *look up* hull names/sizes during spawn weight math — it's a lookup table, not displayed data.
