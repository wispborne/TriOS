## 1. Update Defense Row Logic

- [x] 1.1 In `ingame_ship_tooltip.dart`, add a `isTruePhaseShip` boolean: `hasPhase && ship.defenseId == 'phasecloak'`.
- [x] 1.2 Change the defense label/row logic: for `isTruePhaseShip` show "Defense: Phase cloak"; for `hasPhase && !isTruePhaseShip` show "Special: [shipSystemsMap[ship.defenseId]?.name ?? ship.defenseId]"; keep existing behavior for shielded and no-defense ships.

## 2. Add Phase Cost/Upkeep Rows

- [x] 2.1 Add a `if (isTruePhaseShip) ...[...]` block after the shield stats block, with null-guarded rows for "Cloak activation cost" (`ship.phaseCost`) and "Cloak upkeep/sec" (`ship.phaseUpkeep`).

## 3. Verify

- [x] 3.1 Confirm the project analyzes cleanly (`dart analyze`).
