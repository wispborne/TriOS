# Tasks: Codex fighter page combat stats

## 1. Shared pieces

- [x] 1.1 Rename `_hullModWrap` to `hullModWrap` in `ship_codex_card.dart`, and update its one caller.
- [x] 1.2 Add a `hullmodsMap` parameter to `WingCodexCard.create`, and pass it from `codex_detail_panel.dart` and `codex_entry_tooltip.dart`.

## 2. Technical data block

- [x] 2.1 Add the "Technical data" section header and the wing rows: Primary role, Ordnance points, Maximum engagement/support range, Fighters in wing, Base replacement time (seconds). Hide the rows the game hides for `swarm_fighter` wings.
- [x] 2.2 Add the ship rows when the ship resolved: Crew per fighter, Hull integrity, Armor rating (hidden at 1 or less), shield or phase row, Top speed.
- [x] 2.3 Keep the game's row order and the blank gaps between the three groups.
- [x] 2.4 Move fleet points, tier, and rarity to a small "Wing data" block below the description box.

## 3. Lines under the stats

- [x] 3.1 Add the "Hull mods:" line after Armaments, using `hullModWrap`.

## 4. Description box

- [x] 4.1 Show the design type (hidden for "Common"), the ship's SHIP description, and "Base value" (hidden for `no_sell` wings), framed like the ship card's description.

## 5. Factions

- [x] 5.1 Turn `_ShipUsedByFactions` into a shared `_UsedByFactions` in `codex_detail_panel.dart`. Show it below wing cards with the game's rule and tooltip text.

## 6. Formation picture

- [x] 6.1 Find the offsets the game uses for the Codex formation picture. Found in `combat/new/A.java`; see design.md.
- [x] 6.2 Build a formation picture widget that draws the ship sprite once per craft at those offsets. Unknown formations use the game's default table.
- [x] 6.3 Place it beside the technical data, stacking below the breakpoint like the ship card.

## 7. Check

- [x] 7.1 Run `fvm flutter analyze` on the changed files.
- [ ] 7.2 The user checks these pages against the game's Codex: Claw (omni shield), Flash (drone, no crew), Mining Pod (support range), a phase fighter, and a modded fighter with hull mods.
