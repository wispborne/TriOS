## Why

The ship tooltip in TriOS always shows "Defense: Phase cloak" for any ship with `shield_type = PHASE`. The in-game codex has more nuanced logic: it distinguishes between "true phase ships" (`defense_id == "phasecloak"`) and ships that have PHASE shield type but a custom defense system (e.g., the Alysse with `defense_id = kol_damper`). For true phase ships, the game shows "Defense: Phase Cloak" with cloak cost/upkeep stats. For non-standard phase ships, it shows "Special: [system name]" with no phase stats. TriOS currently treats all PHASE ships identically.

Verified against decompiled game code at `decompiled_obf/com/fs/starfarer/campaign/ui/trade/new.java` (lines 193-210) and `decompiled_obf/com/fs/starfarer/loading/specs/g_1.java` (line 776, `isPhase()` method).

## What Changes

- For true phase ships (`shield_type=PHASE` and `defense_id=phasecloak`): keep "Defense: Phase cloak" and add "Cloak activation cost" and "Cloak upkeep/sec" rows.
- For non-standard phase ships (`shield_type=PHASE` and `defense_id != phasecloak`): show "Special: [defense system name]" instead of "Defense: Phase cloak", with no phase cost/upkeep rows.
- No changes to shielded ships or no-defense ships.

## Capabilities

### New Capabilities
- `phase-tooltip-stats`: Match in-game codex defense rendering for phase ships, distinguishing true phase cloaks from custom defense systems.

### Modified Capabilities

## Impact

- `lib/ship_viewer/widgets/ingame_ship_tooltip.dart` — defense row rendering logic. Uses existing `ship.defenseId` field and `shipSystemsMap` (both already available in the tooltip builder).
- No model or data changes required.
