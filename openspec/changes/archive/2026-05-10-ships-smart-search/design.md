# Design: Ships Smart Search

## Approach
Mirror the weapons page pattern exactly. The weapons page (`weapons_page_controller.dart`) defines `SearchField<Weapon>` entries, converts them to `SearchFieldMeta` via `toMeta()`, parses queries with `SearchDslParser`, and filters with `_applyParsedQuery()`. We replicate this for `Ship`.

## Search Fields

### String fields (equality, value suggestions, negation)
| Key | Source | Notes |
|---|---|---|
| `size` | `hullSize` | frigate, destroyer, cruiser, capital_ship |
| `shield` | `shieldType` | FRONT, OMNI, PHASE, NONE |
| `system` | `systemId` | ship system ID |
| `defense` | `defenseId` | defense system ID |
| `manufacturer` | `techManufacturer` | tech/manufacturer |
| `style` | `style` | visual style |
| `mod` | `modVariant.modInfo.nameOrId` | substring match on mod name |
| `hint` | `hints` | multi-value (STATION, CARRIER, etc.) |
| `tag` | `tags` | multi-value |

### Numeric fields (supports >, <, >=, <=)
| Key | Source | Notes |
|---|---|---|
| `hp` | `hitpoints` | hull hitpoints |
| `armor` | `armorRating` | armor rating |
| `flux` | `maxFlux` | max flux capacity |
| `dissipation` | `fluxDissipation` | flux dissipation |
| `op` | `ordnancePoints` | ordnance points |
| `speed` | `maxSpeed` | max speed |
| `bays` | `fighterBays` | fighter bays |
| `shieldarc` | `shieldArc` | shield arc |
| `shieldeff` | `shieldEfficiency` | shield efficiency |
| `crew` | `minCrew` | minimum crew |
| `cargo` | `cargo` | cargo capacity |
| `fuel` | `fuel` | fuel capacity |
| `burn` | `maxBurn` | max burn |
| `mass` | `mass` | ship mass |
| `dp` | `deploymentPoints` | deployment points (supplies/rec) |
| `cost` | `baseValue` | base credit value |
| `slots` | `mountableWeaponSlotCount` | mountable weapon slots |
| `peak` | `peakCrSec` | peak CR seconds |

## File Changes

### `lib/ship_viewer/ships_page_controller.dart`
- Add `_buildSearchFields()` returning `List<SearchField<Ship>>`
- Add `searchFieldsMeta` getter (calls `toMeta()` with current ship list)
- Add `submitSearchQuery()` method for history persistence
- Replace `_filterBySearch()` with `_applyParsedQuery()` using `SearchDslParser`
- Import `search_dsl_field.dart`

### `lib/ship_viewer/ships_page.dart`
- Replace `ViewerSearchBox` with `SmartSearchBar`
- Remove `SearchController` field (SmartSearchBar manages its own)
- Wire `onChanged`, `onSubmitted`, `fields`, `recentHistory`

### `lib/trios/settings/settings.dart`
- Add `shipsSearchHistory` field (List<String>, default empty)
- Run `build_runner` to regenerate mapper

### `lib/trios/settings/app_settings_logic.dart`
- Add helper to update `shipsSearchHistory` (same as weapons pattern)

## Key Decisions
- **Field set**: Prioritize fields users will actually search by (size, shield type, OP, speed, HP). Include less common ones (peak CR, sensor values) only if trivial to add. Start with the set above; easy to extend later.
- **Free-text fallback**: Unqualified text (no `field:` prefix) still does substring matching against all ship properties, preserving existing behavior.
- **History cap**: Same as weapons (10 entries).
