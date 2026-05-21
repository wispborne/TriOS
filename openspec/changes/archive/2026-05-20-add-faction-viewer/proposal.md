# Faction Viewer

## Problem

TriOS has viewers for ships, weapons, hullmods, and portraits, but no way to browse faction data. Players frequently want to know:

- What ships/weapons does a faction use?
- How aggressive is their doctrine? Do they favor carriers or warships?
- What factions do my installed mods add or modify?
- How do two factions compare in fleet composition?

This information is buried in `.faction` files (JSON with comments) that most players never read.

## Solution

Add a Faction Viewer as a new tool in the viewers group. Two display modes:

1. **Gallery mode** (default) -- Compact faction cards in a wrapping grid. Each card shows logo, name, color, and key stats. Click a card to open a full profile dialog.

2. **Grid mode** -- WispGrid with sortable columns (doctrine stats, blueprint counts, source mod). Click a row to open the same profile dialog.

### Profile dialog

Full detail view for a single faction:

- **Header**: Logo, crest, display name, color swatch, ship name prefix.
- **Faction-colored theming**: The dialog's color scheme is derived from the faction's color via palette generation. Toggleable off from an overflow menu button.
- **Doctrine**: Visual bars (0-5 scale) for warships, carriers, phase, aggression, ship quality, officer quality, ship size, fleet size.
- **Fleet overview**: Counts of known ships, weapons, fighters, hullmods -- expandable to show items with inline thumbnails. When multiple sources contribute to a section, items are grouped by source mod with subtle group headers (e.g., "Vanilla", "ModName"), so it's clear which mod added each ship/weapon.
- **Cross-references**: Clicking a ship/weapon/hullmod item navigates to it in the corresponding viewer.
- **Portraits**: Thumbnail grid of the faction's portraits.
- **Behavior flags**: Chips showing key custom flags (offers commissions, engages in hostilities, pirate behavior, buys AI cores, etc.).
- **Source**: Which mod(s) contribute to this faction's data.

### Filters

- **Show hidden factions** -- Factions with `showInIntelTab: false` (Remnants, Omega, Derelict, etc.) are hidden by default. Toggle to show.
- **Show mod factions** -- Factions added by mods. On by default.
- **Search** -- Filter by faction name.

### Data merging

Starsector merges faction files across mods, not replaces. The viewer replicates this:

- Arrays (knownShips, knownWeapons, portraits, etc.) are additive.
- Scalars (displayName, color, doctrine values) are last-write-wins.
- Nested objects are recursively merged.
- Per-section attribution tracks how many items each source (vanilla or mod) contributed.
- Per-item attribution tracks exactly which source added each individual asset ID.

## Non-goals

- Faction relationship/diplomacy data (runtime-only, not in files).
- Editing faction files.
- Fleet simulation or combat strength estimation.

## Files changed

New feature directory: `lib/faction_viewer/`

Modified:
- `lib/trios/navigation.dart` -- Add `TriOSTools.factions` to `NavGroup.viewers`
- `lib/app_shell.dart` -- Wire up the new tab
