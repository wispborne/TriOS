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

Add a new **Codex** tab that works like the in-game Codex (the current "V2" one — see
`game-codex-reference.md` in this folder for the full analysis). It does not replace
the existing tabs — it is a new way to view the same data. It reuses the loaders and
the "codex card" widgets TriOS already has.

The tab copies the game's layout and behavior:

- **Toolbar:** back / forward / up / random buttons with the game's keyboard
  shortcuts (Q, W, E, R, arrow keys), and a search box (Ctrl-F).
- **Left:** one drill-down list, like the game. The top level shows the six
  categories (Ships, Weapons, Hullmods, Ship Systems, Fighters, Factions); clicking
  one drills in, with a "go up" row at the top. Rows show the entry's image (ship
  sprite, weapon sprite, hullmod icon), reusing the viewer pages' image widgets and
  their hover effects — engines still glow when you hover a ship row. Unlike the
  game, the list's title is also a dropdown, so you can jump straight to another
  category without going up first.
- **Middle:** the detail panel, which reuses the existing per-type codex cards.
- **Right:** a **related entries** panel — the game's "see also" list. A build pass
  links entries both ways (a ship to its system, built-in weapons, hullmods, and
  wings; a wing to its ship; skins of the same hull to each other), so a weapon also
  lists every ship that mounts it.
- **Bottom:** the game's tag filters — checkable groups with live counts per category
  (tech/manufacturer, size, type, damage type, role), all checked by default; uncheck
  to narrow. TriOS's mod filter is an extra group the game doesn't have.

Search works the way the game's does: it searches within the current category (from
the top level, that means everything), matches by substring, ranks names that start
with the query first, and shows results in the same left list.

In the detail panel, cross-references are also clickable, just like in the related
panel. Click a ship's built-in weapon and the panel switches to that weapon; back and
forward walk the history.

## Scope

- New `Codex` tab with the game-style layout above: toolbar, drill-down list with a
  category quick-switch dropdown, detail panel, related-entries panel, tag filters.
- A shared "codex entry" type so one list can hold every data type.
- A combined, mod-aware index built from the existing loaders, plus the game-style
  search behavior (scoped to the current category, starts-with ranked first).
- A **related-entries linking pass** that wires two-way links between entries, and the
  panel that shows them.
- **Tag filter groups with live counts** per category, mirroring the game's facets,
  plus the mod filter.
- **Full navigation:** back / forward / up / random with keyboard shortcuts, and a
  history that restores the list, selected entry, search, and filters together.
- **Spoiler levels**, like the viewer pages: one Codex-wide control (no spoilers /
  slight / all, defaulting to none) that hides spoiler-tagged content everywhere —
  the list, search, related entries, and the random button.
- A **"show hidden" toggle** for system/decorative weapons, off by default (the game
  never shows these; the weapons page has the same toggle). Hidden weapons and
  fighter hulls stay reachable through links — a ship's built-in weapon and a wing's
  ship always work — they just aren't listed.
- Detail panel that reuses the existing ship, weapon, and hullmod codex cards, plus
  the existing `FactionCard`.
- Clickable cross-references inside the detail cards.
- **Ship systems:** turn on the full stat fields (already sketched but commented out in
  `lib/ship_systems_manager/ship_system.dart`) and add a small detail card.
- **Fighters (wings):** add a new loader that reads `data/hulls/wing_data.csv`, a wing
  model, and a small detail card. A wing links through to the ship behind it.

## Non-goals

- No change to the existing Ships, Weapons, Hullmods, Faction, or Portrait tabs.
- Portraits are not a Codex category — they stay in their own tab.
- No locking/unlocking of entries. That whole subsystem in the game is campaign-only
  (entries unlock as the player encounters things); TriOS has no campaign. The spoiler
  levels above are TriOS's stand-in — the same content the game locks behind
  encounters is what the spoiler filter hides by default.
- None of the game's other categories (planets, commodities, industries, skills,
  abilities, special items, gallery) — just the six TriOS has data for.
- No new data pipeline. The Codex reads the same live game and mod files, through the
  same cached loaders, as everything else.
- Full fighter combat stats (the ship behind a wing) are shown by linking to that ship,
  not by duplicating them into the wing entry.
