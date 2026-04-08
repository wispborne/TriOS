## ADDED Requirements

### Requirement: Show cloak stats for true phase ships
The ship tooltip SHALL display "Defense: Phase cloak" followed by "Cloak activation cost" and "Cloak upkeep/sec" rows for ships where `shield_type = PHASE` and `defense_id = "phasecloak"`.

#### Scenario: True phase ship with cost and upkeep
- **WHEN** viewing the tooltip for a ship with `shield_type = PHASE`, `defense_id = "phasecloak"`, and non-null `phaseCost` and `phaseUpkeep`
- **THEN** the tooltip shows "Defense: Phase cloak", "Cloak activation cost: [value]", and "Cloak upkeep/sec: [value]"

#### Scenario: True phase ship with null cost/upkeep
- **WHEN** viewing the tooltip for a ship with `shield_type = PHASE`, `defense_id = "phasecloak"`, and null `phaseCost` or `phaseUpkeep`
- **THEN** the null stat rows are omitted; the "Defense: Phase cloak" row still appears

### Requirement: Show special label for non-standard phase ships
The ship tooltip SHALL display "Special: [defense system name]" for ships where `shield_type = PHASE` and `defense_id` is NOT `"phasecloak"`. No phase cost/upkeep rows SHALL be shown.

#### Scenario: Non-standard phase ship (e.g., Alysse)
- **WHEN** viewing the tooltip for a ship with `shield_type = PHASE` and `defense_id = "kol_damper"`
- **THEN** the tooltip shows "Special: [resolved system name from shipSystemsMap]" with no "Cloak activation cost" or "Cloak upkeep/sec" rows

#### Scenario: Non-standard phase ship with unknown defense_id
- **WHEN** viewing the tooltip for a ship with `shield_type = PHASE` and `defense_id` not found in `shipSystemsMap`
- **THEN** the tooltip shows "Special: [raw defense_id value]" as a fallback

### Requirement: No change to shielded and no-defense ships
Shielded ships and no-defense ships MUST continue to render exactly as before.

#### Scenario: Shielded ship unchanged
- **WHEN** viewing the tooltip for a ship with `shield_type = FRONT` or `OMNI`
- **THEN** the "Defense" row and shield stats are displayed as before

#### Scenario: No-defense ship unchanged
- **WHEN** viewing the tooltip for a ship with `shield_type = NONE` or null
- **THEN** the "Defense: None" row is displayed as before
