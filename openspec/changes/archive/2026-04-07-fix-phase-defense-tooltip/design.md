## Context

The decompiled game code reveals a two-tier check for phase ships:

1. `isPhase()` (in `g_1.java:776`): returns true if ship has `PHASE` hint OR (`shield_type == PHASE` AND `defense_id == "phasecloak"`).
2. In the codex renderer (`new.java:193-210`):
   - If `shield_type == PHASE` and `isPhaseShip()` is true: shows "Defense: Phase Cloak" + "Cloak activation cost" + "Cloak upkeep/sec"
   - If `shield_type == PHASE` and `isPhaseShip()` is false: shows "Special: [system name]" (no cost/upkeep rows)
   - The label switches from "Defense" to "Special" when the phase cloak name isn't "Phase Cloak"

The TriOS tooltip already has access to `ship.defenseId` and `shipSystemsMap` in the `buildShipContent` method. The `Ship` model has `phaseCost` and `phaseUpkeep` fields.

## Goals / Non-Goals

**Goals:**
- Replicate the game's defense row logic for phase ships exactly.
- Use existing model fields — no new data needed.

**Non-Goals:**
- Checking the `PHASE` ship type hint (TriOS doesn't parse hints from hull files; `defense_id == "phasecloak"` is sufficient for the CSV-based approach).
- Changing non-tooltip ship views (grid, blueprint).

## Decisions

**Use `defense_id == "phasecloak"` as the "true phase ship" check.** The game also checks for a PHASE hint, but TriOS works from CSV data where `defense_id` is the distinguishing field. This matches the game behavior for all practical cases.

**Resolve defense system name via `shipSystemsMap`.** The ships page already does this: `shipSystemsMap[ship.defenseId]?.name ?? ship.defenseId`. Reuse the same pattern in the tooltip.

**Restructure the defense label logic** from a simple ternary into a branching block:
- `hasPhase && isTruePhaseShip` → label "Defense", value "Phase cloak", show cost/upkeep rows
- `hasPhase && !isTruePhaseShip` → label "Special", value from shipSystemsMap, no cost/upkeep rows
- `hasShield` → label "Defense", value "[Type] shield", show shield stats (unchanged)
- else → label "Defense", value "None" (unchanged)

## Risks / Trade-offs

- [PHASE hint not checked] → Could mismatch for a hypothetical mod that sets PHASE hint without `defense_id = phasecloak`. Acceptable since TriOS uses CSV data, not hull file hints.
- [Phase cost/upkeep null for some ships] → Null-guard each row, consistent with existing shield stat guards.
