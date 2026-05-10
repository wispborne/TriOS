# Design: Finish weapons smart search parameters

## Approach

Add new `SearchField<Weapon>` entries to `_buildSearchFields()` in `lib/weapon_viewer/weapons_page_controller.dart`. Each field follows the established pattern — string fields use exact/substring matching with value suggestions, numeric fields support comparator operators.

## New fields

### Combat stats (numeric, all support >, <, >=, <=)

| Key           | Source field | Description |
|---------------|---|---|
| `dpshot`      | `damagePerShot` | Damage per shot |
| `emp`         | `emp` | EMP damage |
| `energy`      | `energyPerShot` | Flux per shot |
| `eps`         | `energyPerSecond` | Flux per second |
| `chargeup`    | `chargeup` | Charge-up time in seconds |
| `chargedown`  | `chargedown` | Charge-down time in seconds |
| `burst`       | `burstSize` | Burst size (number of shots) |
| `burstdelay`  | `burstDelay` | Delay between burst shots |
| `turnrate`    | `turnRate` | Projectile/beam turn rate |
| `speed`       | `projSpeed` | Projectile speed |
| `beamspeed`   | `beamSpeed` | Beam speed |
| `launchspeed` | `launchSpeed` | Missile launch speed |
| `flighttime`  | `flightTime` | Projectile flight time |
| `projhp`      | `projHitpoints` | Projectile hitpoints |
| `ammopersec`  | `ammoPerSec` | Ammo regeneration per second |
| `reload`      | `reloadSize` | Reload size |
| `impact`      | `impact` | Impact/force value |
| `autofire`    | `autofireAccBonus` | Autofire accuracy bonus |

### Spread/accuracy (numeric)

| Key | Source field | Description |
|---|---|---|
| `spread` | `maxSpread` | Maximum spread |
| `minspread` | `minSpread` | Minimum spread |
| `spreadshot` | `spreadPerShot` | Spread added per shot |
| `spreaddecay` | `spreadDecayPerSec` | Spread decay per second |

### Weapon identity (string, with value suggestions)

| Key | Source field | Description |
|---|---|---|
| `specclass` | `specClass` | Weapon class (beam, projectile, missile, etc.) |
| `mount` | `effectiveMountType` | Mount type (TURRET, HARDPOINT, HIDDEN) |
| `manufacturer` | `techManufacturer` | Tech/manufacturer |
| `role` | `primaryRoleStr` | Primary role description |
| `group` | `groupTag` | Weapon group tag |

### Metadata (numeric)

| Key | Source field | Description |
|---|---|---|
| `tier` | `tier` | Weapon tier |
| `rarity` | `rarity` | Rarity value |
| `cost` | `baseValue` | Base credit value |

## Key decisions

- **`dps` key conflict**: `dps` is already taken for damage/second. Use `dpshot` for damage-per-shot.
- **Short keys preferred**: e.g. `emp`, `burst`, `speed` — matches how players talk about these stats.
- **No suggestions for pure-numeric fields**: Same as existing `range`/`op`/`dps` — no useful discrete values to suggest.
- **String fields get suggestions**: `specclass`, `mount`, `manufacturer`, `role`, and `group` pull distinct values from loaded weapons.
- **`mount` uses `effectiveMountType`**: This getter already considers `mountTypeOverride`, which is the correct behavior.

## Files changed

- `lib/weapon_viewer/weapons_page_controller.dart` — add ~28 new SearchField entries to `_buildSearchFields()`
- `openspec/specs/weapon-search-fields/spec.md` — update spec table with new fields
