# Faction Spawn Weights (read-only)

## The problem

When the game builds a fleet for a faction, it picks each ship at random from a weighted list. That list is assembled at load time from `default_ship_roles.json` and the faction's `.faction` file, merged across every enabled mod. There is no way to see the assembled list anywhere — not in the game, not in any tool.

On heavily modded installs this matters: mods keep appending ships to the same lists, so vanilla ships become a small slice of the total. Measured on a real ~200-mod install, vanilla was 16% of Hegemony's combat weight and 3% of Pirates'. Players notice their fleets "feel wrong" but have no way to see why, or which mod is responsible.

## The solution

Show the assembled list. TriOS already merges `.faction` files across mods (faction viewer) and tracks which mod contributed each list entry. This change extends that to the spawn-weight data and displays it in three places, sorted from glance to detail.

Two fixes come first, because the numbers are wrong without them: mods are currently merged in mods-folder order rather than the game's load order, and attribution is only recorded for lists, not for the plain numbers that spawn weights are made of. See `design.md`.

The three surfaces:

1. **Faction card / grid column** — one number per faction: what percent of its spawn weight is vanilla. Sortable, so the worst-hit faction jumps to the top.
2. **Faction dialog section** — for one faction: vanilla vs. mods split, plus a per-mod breakdown showing which mods own how much of the list.
3. **Ship list view** — the full weighted list for a faction, per role (small combat ships, mid-size, carriers, etc.), showing each ship's weight, its share of the total, and which mod set it. Rows group by ship and expand to the individual loadout entries the file actually stores. Each entry links to the file that set its weight, so the user can make edits themselves.

## Strictly read-only

TriOS does not write, edit, or generate any mod files. No weight editing, no patch-mod export. The tool finds the problem and points at the exact file and line responsible; the user makes changes outside TriOS.

## In scope

- Merging `default_ship_roles.json` across enabled mods, same rules as `.faction` merging.
- Keeping the `shipRoles`, `hullFrequency`, and `variantOverrides` sections of `.faction` files (currently parsed but discarded).
- Computing final per-ship weights the way the game does: role weight → known-ships filter → variant overrides → hull frequency multiplier.
- The three UI surfaces above.
- "Open the file that set this weight" per entry.

## Out of scope

- Any file writing or mod generation.
- Simulating actual fleets (doctrine splits, fleet-point budgets, size rolls). The weight list is the input to that process, not the output; simulating would mean re-implementing ~500 lines of game logic that drifts with each game update.
- Ships added by mod code at runtime (`addKnownShip` etc.) — invisible to file-based analysis; noted in the UI as a limitation.
- Nexerelin's runtime doctrine changes.
- A mod-by-faction overview matrix (possible later; not the core ask).
