/// Hazard-rating math for surveyable planets.
///
/// A planet's hazard is a flat-additive stat: `1.0` (base) plus the hazard
/// delta of each market condition present. Resources and planet type add none.
/// Values transcribed from Starsector 0.98a-RC8
/// `data/campaign/procgen/condition_gen_data.csv`; see the change's
/// `hazard-reference.md`. Any condition not in this map contributes 0 — which
/// also gives correct best-effort behavior for modded conditions.
library;

const double kHazardBase = 1.0;

const Map<String, double> kConditionHazardDeltas = {
  'habitable': -0.25,
  'mild_climate': -0.25,
  'cold': 0.25,
  'very_cold': 0.50,
  'hot': 0.25,
  'very_hot': 0.50,
  'tectonic_activity': 0.25,
  'extreme_tectonic_activity': 0.50,
  'thin_atmosphere': 0.25,
  'no_atmosphere': 0.50,
  'toxic_atmosphere': 0.50,
  'dense_atmosphere': 0.50,
  'low_gravity': 0.25,
  'high_gravity': 0.50,
  'irradiated': 0.50,
  'inimical_biosphere': 0.25,
  'water_surface': 0.25,
  'poor_light': 0.25,
  'dark': 0.50,
  'meteor_impacts': 0.50,
  'extreme_weather': 0.25,
  'pollution': 0.25,
};

/// Hazard rating as a fraction (1.0 == 100%). No minimum clamp, matching the
/// game (`getHazardValue()` returns the modified value directly).
double computeHazardRating(Iterable<String> conditionIds) {
  var hazard = kHazardBase;
  for (final id in conditionIds) {
    hazard += kConditionHazardDeltas[id] ?? 0.0;
  }
  return hazard;
}
