# Unified Codex view

## Problem

TriOS already reads and shows Starsector game data — ships, weapons, hullmods, and
factions — but each type lives in its own tab. To look something up you have to know
in advance what kind of thing it is and go to the right tab. There is no single place
to search across everything, and no way to start at a ship and walk to its weapons,
system, and hull mods the way the in-game Codex lets you.

The in-game Codex (and the community web version, StarsectorHTML by DeCEll) solves
this with one browsable encyclopedia: pick a category, search, click an entry, and
follow its links to related entries.

## Solution

Add a new **Codex** tab that mimics the in-game Codex. It does not replace the existing
tabs — it is a new way to view the same data. It reuses the loaders and the "codex card"
widgets TriOS already has.

The tab uses a three-panel layout:

- **Left:** category list (Ships, Weapons, Hullmods, Ship Systems, Fighters, Factions)
  plus a mod filter.
- **Middle:** search results, searchable across every category at once.
- **Right:** the detail panel, which reuses the existing per-type codex cards.

In the detail panel, cross-references become clickable. Click a ship's built-in weapon
and the panel switches to that weapon, with a back button to return. This is the "walk
the web of entries" feel of the real Codex.

## Scope

- New `Codex` tab and its three-panel page.
- A shared "codex entry" type so one list can hold every data type.
- A combined, mod-aware search index built from the existing loaders.
- Detail panel that reuses the existing ship, weapon, and hullmod codex cards, plus the
  existing `FactionCard`.
- Clickable cross-references with a simple back/forward history inside the panel.
- **Ship systems:** turn on the full stat fields (already sketched but commented out in
  `lib/ship_systems_manager/ship_system.dart`) and add a small detail card.
- **Fighters (wings):** add a new loader that reads `data/hulls/wing_data.csv`, a wing
  model, and a small detail card. A wing links through to the ship behind it.

## Non-goals

- No change to the existing Ships, Weapons, Hullmods, Faction, or Portrait tabs.
- Portraits are not a Codex category — they stay in their own tab.
- No new data pipeline. The Codex reads the same live game and mod files, through the
  same cached loaders, as everything else.
- Full fighter combat stats (the ship behind a wing) are shown by linking to that ship,
  not by duplicating them into the wing entry.
