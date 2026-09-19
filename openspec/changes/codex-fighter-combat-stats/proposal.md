# Codex fighter page: combat stats

Status: ready-for-agent

## Problem

The Codex fighter page shows only the wing's own data: role, fleet points, OP cost, fighters in wing, tier, rarity, refit time, system, and armaments. To see how tough or fast a fighter is, the user has to click through to the ship behind the wing.

The game's own fighter Codex page shows all of this on one page. Players compare the two and find TriOS's page thin.

## Solution

Rebuild the wing card to follow the game's fighter Codex page (`campaign/ui/trade/D.java` for the stats, `codex2/CodexDetailPanel.java` around line 789 for the page). Most values come from the ship behind the wing, which TriOS already loads.

In scope, in the game's order:

1. **Technical data** block:
   - Primary role (the wing's `role desc`, or the role name when that is empty)
   - Ordnance points
   - Crew per fighter (the ship's min crew)
   - Maximum engagement range (labelled "Maximum support range" for SUPPORT wings)
   - Fighters in wing
   - Base replacement time (seconds) (the wing's refit time)
   - Hull integrity
   - Armor rating (hidden when 1 or less, like the game)
   - Shield row: "Omni shield" or "Front shield" with the ship's max flux, or the phase row. Nothing when the ship has no shield.
   - Top speed
2. **System, Armaments, Hull mods** lines. System and Armaments already exist. Hull mods is the ship's built-in hull mods, reusing the ship card's hull mod line.
3. **Description box**: design type, the ship's description from `descriptions.csv`, and "Base value" (the wing's base value, hidden when the wing has the `no_sell` tag).
4. **Factions** that use the fighter, shown as chips below the card, like the ship page's "used by" section.
5. **Formation picture**: the fighter sprite drawn once per craft, in the wing's formation (V, BOX, or CLAW in vanilla).

Out of scope:

- The "Related entries" panel. The Armaments line already links to the weapons.
- Fleet points, tier, and rarity. The game doesn't show them. They stay as they are in a smaller "Wing data" block, so no information is lost.
- Any changes to the ship card or the ship page.

## Why now

Changes 1 and 2 from the same round of user requests just added the "Fighters in wing" filter and the System and Armaments lines. This finishes the page.
