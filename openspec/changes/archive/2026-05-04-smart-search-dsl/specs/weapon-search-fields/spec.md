## ADDED Requirements

### Requirement: Weapons page registers DSL fields
The weapons page controller SHALL register `SearchField<Weapon>` definitions covering the most useful filterable weapon properties. Each field draws its value suggestions from the actual loaded weapon list.

The initial field set SHALL include:

| Key | Type | Source field | Notes |
|---|---|---|---|
| `tracking` | string | `trackingStr` | e.g. `excellent`, `none` |
| `ammo` | string/numeric | `ammo` | `none` = unlimited; numeric comparators |
| `type` | string | `weaponType` | e.g. `missile`, `energy`, `ballistic` |
| `size` | string | `size` | e.g. `small`, `medium`, `large` |
| `damage` | string | `damageType` | e.g. `kinetic`, `he`, `energy`, `fragmentation` |
| `range` | numeric | `range` | supports `>`, `<`, `>=`, `<=` |
| `op` | numeric | `ops` | supports `>`, `<`, `>=`, `<=` |
| `dps` | numeric | `damagePerSecond` | supports `>`, `<`, `>=`, `<=` |
| `hint` | string | `hintsAsSet` | multi-value: matches if any hint matches |
| `tag` | string | `tagsAsSet` | multi-value: matches if any tag matches |
| `mod` | string | `modVariant.modInfo.nameOrId` | matches substring of mod name |

#### Scenario: Tracking field filters by quality
- **WHEN** the user enters `tracking:excellent`
- **THEN** only weapons whose `trackingStr` equals `"excellent"` (case-insensitive) are shown

#### Scenario: Ammo field with none matches unlimited weapons
- **WHEN** the user enters `ammo:none`
- **THEN** only weapons with null or zero `ammo` (i.e., unlimited ammo) are shown

#### Scenario: Ammo numeric comparator
- **WHEN** the user enters `ammo:>50`
- **THEN** only weapons with `ammo > 50` are shown

#### Scenario: Range numeric comparator
- **WHEN** the user enters `range:>800`
- **THEN** only weapons with `range > 800` are shown

#### Scenario: Hint field matches multi-value hints
- **WHEN** the user enters `hint:guided`
- **THEN** weapons whose hints set contains `"guided"` are shown, regardless of other hints they have

#### Scenario: Tag field matches multi-value tags
- **WHEN** the user enters `tag:strike`
- **THEN** weapons whose tags set contains `"strike"` are shown

#### Scenario: Negated type filter excludes category
- **WHEN** the user enters `-type:missile`
- **THEN** weapons with `weaponType == "MISSILE"` are excluded

#### Scenario: Value suggestions for type field
- **WHEN** the user types `type:` in the search bar
- **THEN** the autocomplete dropdown lists distinct weapon types present in the loaded data (e.g., `missile`, `energy`, `ballistic`, `hybrid`)
