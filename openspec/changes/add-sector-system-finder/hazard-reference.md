# Hazard rating — authoritative formula & values

Source: **Starsector 0.98a-RC8** (via the starsector-knowledge skill). Verify against the
user's installed game version before trusting.

## Formula

A planet's hazard rating is a flat-additive stat:

```
hazard = 1.0 (base)  +  Σ (hazard delta of each market condition present)
displayed % = round(hazard * 100)
```

- **Base = 1.0 (100%).** From `MutableMarket`: `hazard.modifyFlat("haz_base", 1.0F, "Base value")`
  (`sources-obf/campaign.econ.java:809`).
- Each condition contributes its `hazard` column value from
  `data/campaign/procgen/condition_gen_data.csv` via `BaseHazardCondition.apply()`
  (`sources-api/.../econ/BaseHazardCondition.java`): `market.getHazard().modifyFlat(id, spec.getHazard(), …)`.
- **No minimum clamp.** `getHazardValue()` returns `hazard.getModifiedValue()` directly
  (`campaign.econ.java:1132`) — unlike stability, it is not floored at 0. In practice the
  lowest realistic value is ~50% (habitable −0.25 + mild_climate −0.25).
- **Planet type does NOT add hazard.** `planets.json` has no hazard field; the planet type
  only influences which conditions spawn. So hazard depends solely on the condition list we
  already parse.

## Per-condition hazard deltas (the full set with a non-zero value)

| Condition id | Hazard delta |
|---|---|
| `habitable` | −0.25 |
| `mild_climate` | −0.25 |
| `cold` | +0.25 |
| `very_cold` | +0.50 |
| `hot` | +0.25 |
| `very_hot` | +0.50 |
| `tectonic_activity` | +0.25 |
| `extreme_tectonic_activity` | +0.50 |
| `thin_atmosphere` | +0.25 |
| `no_atmosphere` | +0.50 |
| `toxic_atmosphere` | +0.50 |
| `dense_atmosphere` | +0.50 |
| `low_gravity` | +0.25 |
| `high_gravity` | +0.50 |
| `irradiated` | +0.50 |
| `inimical_biosphere` | +0.25 |
| `water_surface` | +0.25 |
| `poor_light` | +0.25 |
| `dark` | +0.50 |
| `meteor_impacts` | +0.50 |
| `extreme_weather` | +0.25 |
| `pollution` | +0.25 |

**Resources contribute 0 hazard.** All `ore_*`, `rare_ore_*`, `volatiles_*`, `organics_*`,
and farmland tiers have a blank `hazard` column — they do not affect hazard.

## Implementation note

This is a small, stable constant table. Encode it as a `const Map<String, double>` in
`lib/sector_map/finder/hazard.dart` (do not ship the game CSV). Any condition id not in the
map contributes 0 — which also gives correct best-effort behavior for modded conditions
(non-goal to match modded hazard formulas).

## Worked examples (for a unit test)

- Bare habitable world (only `habitable`): `1.0 − 0.25 = 0.75` → **75%**.
- `very_hot` + `toxic_atmosphere` + `extreme_tectonic_activity`:
  `1.0 + 0.5 + 0.5 + 0.5 = 2.5` → **250%**.
- No environmental conditions at all: `1.0` → **100%**.
