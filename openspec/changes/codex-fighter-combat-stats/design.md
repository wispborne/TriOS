# Design: Codex fighter page combat stats

## Where the data comes from

Almost everything is already loaded. No loader or cache changes are needed.

| Row | Source |
| --- | --- |
| Primary role | `Wing.roleDesc`, else `Wing.role` in title case |
| Ordnance points | `Wing.opCost` |
| Crew per fighter | `Ship.minCrew` |
| Maximum engagement / support range | `Wing.range`. The label is "Maximum support range" when `Wing.role` is `SUPPORT`. |
| Fighters in wing | `Wing.numCraft` |
| Base replacement time (seconds) | `Wing.refit` |
| Hull integrity | `Ship.hitpoints` |
| Armor rating | `Ship.armorRating`, hidden when 1 or less |
| Omni / Front shield | `Ship.maxFlux`. The game's decompiled code (`campaign/ui/trade/D.java`) reads the reactor's flux capacity here, not the shield arc. Checked against vanilla: the Claw shows 150, and its `max flux` is 150 while its shield arc is 160. |
| Phase row | Same rule as the ship card: "Defense: Phase Cloak", or "Special: <system name>" when the phase system isn't the standard cloak |
| Top speed | `Ship.maxSpeed` |
| Hull mods | `Ship.builtInMods` |
| Description | `descriptions.csv`, type SHIP, id = the ship's hull id |
| Design type | `Ship.techManufacturer`, hidden when it is "Common", like the game |
| Base value | `Wing.baseValue`, hidden when the wing's tags include `no_sell` |
| Factions | Factions with `showInIntelTab` whose `knownFighterIds` contain the wing id, or whose `knownFighterTags` match a wing tag |

Wings tagged `swarm_fighter` hide Ordnance points, Crew per fighter, the range row, Fighters in wing, and Base replacement time, like the game.

When the ship behind the wing didn't resolve (for example, its mod is disabled), the ship rows are left out. The wing rows still show.

## Key decisions

**Numbers are whole numbers.** The game casts every value to `int`. The card shows `tooltipFmt` output, which already drops `.0`. Use the same.

**Keep the extra wing data.** Fleet points, tier, and rarity aren't on the game's page. They stay in a small "Wing data" block under the description box. Dropping them would lose information TriOS users can see today.

**Reuse the ship card's pieces.** `shipSystemRows`, `groupWeaponArmaments`, and `armamentWrap` are already public in `ship_codex_card.dart`. Make `_hullModWrap` public the same way (as `hullModWrap`) for the Hull mods line. The phase-row label logic is small, so copy it into the wing card rather than extracting it.

**Layout follows the ship card.** Technical data sits on the left with the formation picture on the right. Below a width breakpoint, they stack, with the picture first. The ship card's `_statsSection` does the same. The hover tooltip is 300 px wide, so it always stacks. The detail panel is wide enough for side by side.

**Factions go in the detail panel, not the card.** The ship page already does this with `_ShipUsedByFactions` in `codex_detail_panel.dart`. Turn it into a shared `_UsedByFactions` widget that takes the matching rule and the tooltip text, so ships and wings use the same chips. The wing tooltip text is the game's: "This fighter is used by this faction, and may be found for sale at this faction's colonies." The hover tooltip doesn't show factions, just as it doesn't for ships.

**Formation picture.** The Codex picture does not use the combat formation code. `title/Object/do.java` draws it from a fixed position table in `combat/new/A.java` (`A.super(FighterWingSpec)`):
- There is one table per formation: BOX, CLAW, V, and a default for everything else (DIAMOND and modded values).
- Each table has one row per wing size from 1 to 6. Each row is a list of (x, y) positions, as fractions of a scale.
- The scale is 75% of the picture's shorter side, capped at 125 px. It is multiplied by 0.667 for 2-fighter wings.
- Wings with more than 6 fighters draw only the first 6 positions.
- Each fighter is drawn at its own sprite size (`Ship.width` × `Ship.height`), centered on its position. The game's y axis points up, so y is flipped.
- The sprite is drawn with `ShipBlueprintView.minimal`, as the ship card does. It shows the hull's built-in weapons. It doesn't show the wing's `.variant` weapons, because the blueprint view doesn't read variants.

The picture is built last, as a separate widget, so the rest of the change can ship without it.

## Files that change

- `lib/fighter_viewer/widgets/wing_codex_card.dart`: technical data block, hull mods line, description box, formation picture.
- `lib/ship_viewer/widgets/ship_codex_card.dart`: rename `_hullModWrap` to `hullModWrap`. No behavior change for ships.
- `lib/codex/widgets/codex_detail_panel.dart`: pass `hullmodsMap` to the wing card, and turn `_ShipUsedByFactions` into a shared `_UsedByFactions` used for ships and wings.
- `lib/codex/widgets/codex_entry_tooltip.dart`: pass `hullmodsMap` to the wing card.

## User-facing text

Row labels copy the game word for word: "Primary role", "Ordnance points", "Crew per fighter", "Maximum engagement range", "Maximum support range", "Fighters in wing", "Base replacement time (seconds)", "Hull integrity", "Armor rating", "Omni shield", "Front shield", "Top speed", "Hull mods:", "Base value". Get the user's sign-off before finalizing any text that isn't a copy of the game's.
