import 'package:trios/sector_map/finder/finder_criteria.dart';
import 'package:trios/sector_map/models/sector.dart';

/// One resource family with an ordered tier ladder. The tier index is 1-based:
/// `tiers[0]` is tier 1 (worst), `tiers.last` is the best.
class ResourceFamily {
  final String id;
  final String label;

  /// Condition ids from worst to best.
  final List<String> tiers;

  /// Short tier names aligned with [tiers], for the min-tier dropdown.
  final List<String> tierLabels;

  const ResourceFamily({
    required this.id,
    required this.label,
    required this.tiers,
    required this.tierLabels,
  });

  int get maxTier => tiers.length;

  /// Best tier (1-based) present in [conditions], or 0 if none.
  int bestTier(Set<String> conditions) {
    for (var i = tiers.length - 1; i >= 0; i--) {
      if (conditions.contains(tiers[i])) return i + 1;
    }
    return 0;
  }
}

/// The vanilla resource ladders (0.98a). Tier order from `condition_gen_data.csv`.
const List<ResourceFamily> kResourceFamilies = [
  ResourceFamily(
    id: 'ore',
    label: 'Ore',
    tiers: ['ore_sparse', 'ore_moderate', 'ore_abundant', 'ore_rich', 'ore_ultrarich'],
    tierLabels: ['Sparse', 'Moderate', 'Abundant', 'Rich', 'Ultrarich'],
  ),
  ResourceFamily(
    id: 'rare_ore',
    label: 'Rare ore',
    tiers: [
      'rare_ore_sparse',
      'rare_ore_moderate',
      'rare_ore_abundant',
      'rare_ore_rich',
      'rare_ore_ultrarich',
    ],
    tierLabels: ['Sparse', 'Moderate', 'Abundant', 'Rich', 'Ultrarich'],
  ),
  ResourceFamily(
    id: 'organics',
    label: 'Organics',
    tiers: [
      'organics_trace',
      'organics_common',
      'organics_abundant',
      'organics_plentiful',
    ],
    tierLabels: ['Trace', 'Common', 'Abundant', 'Plentiful'],
  ),
  ResourceFamily(
    id: 'volatiles',
    label: 'Volatiles',
    tiers: [
      'volatiles_trace',
      'volatiles_diffuse',
      'volatiles_abundant',
      'volatiles_plentiful',
    ],
    tierLabels: ['Trace', 'Diffuse', 'Abundant', 'Plentiful'],
  ),
  ResourceFamily(
    id: 'farmland',
    label: 'Farmland',
    tiers: [
      'farmland_poor',
      'farmland_adequate',
      'farmland_rich',
      'farmland_bountiful',
    ],
    tierLabels: ['Poor', 'Adequate', 'Rich', 'Bountiful'],
  ),
];

ResourceFamily? resourceFamilyById(String id) {
  for (final f in kResourceFamilies) {
    if (f.id == id) return f;
  }
  return null;
}

/// Every condition id that belongs to a resource family.
final Set<String> kAllResourceConditionIds = {
  for (final f in kResourceFamilies) ...f.tiers,
};

/// Curated colony-relevant planet conditions → nice labels. These get first
/// class toggles; anything else present in a save falls into "Other conditions".
const Map<String, String> kCuratedConditionLabels = {
  'mild_climate': 'Mild climate',
  'hot': 'Hot',
  'very_hot': 'Very hot',
  'cold': 'Cold',
  'very_cold': 'Very cold',
  'tectonic_activity': 'Tectonic activity',
  'extreme_tectonic_activity': 'Extreme tectonic activity',
  'thin_atmosphere': 'Thin atmosphere',
  'no_atmosphere': 'No atmosphere',
  'toxic_atmosphere': 'Toxic atmosphere',
  'dense_atmosphere': 'Dense atmosphere',
  'low_gravity': 'Low gravity',
  'high_gravity': 'High gravity',
  'irradiated': 'Irradiated',
  'inimical_biosphere': 'Inimical biosphere',
  'water_surface': 'Water surface',
  'poor_light': 'Poor light',
  'dark': 'Dark',
  'meteor_impacts': 'Meteor impacts',
  'extreme_weather': 'Extreme weather',
  'pollution': 'Pollution',
  'ruins_scattered': 'Scattered ruins',
  'ruins_widespread': 'Widespread ruins',
  'ruins_extensive': 'Extensive ruins',
  'ruins_vast': 'Vast ruins',
  'decivilized': 'Decivilized',
};

/// Landmark type id → label (and the order shown in the UI).
const Map<String, String> kLandmarkLabels = {
  'derelict_cryosleeper': 'Cryosleeper',
  'coronal_tap': 'Coronal hypershunt',
  'inactive_gate': 'Gate',
};

/// Condition ids/prefixes that are economy/colony bookkeeping, never finder
/// knobs (kept out of both curated and "Other conditions").
const List<String> _ignoredConditionPrefixes = [
  'population_',
  'comm_relay',
  'free_market',
  'established_polity',
  'ai_core_admin',
  'shipping_disruption',
  'decivilized_subpop',
  'habitable', // handled by the dedicated "Habitable" hard toggle
];

bool _isIgnoredCondition(String id) {
  if (id.endsWith('_no_pick')) return true;
  for (final p in _ignoredConditionPrefixes) {
    if (id == p || id.startsWith(p)) return true;
  }
  return false;
}

/// The modded/uncurated escape hatch: every distinct planet condition present in
/// [sector] that isn't a resource, a curated condition, or ignored bookkeeping.
/// Sorted for stable UI order.
List<String> otherConditionIds(Sector sector) {
  final present = <String>{};
  for (final s in sector.systems) {
    for (final p in s.planets) {
      present.addAll(p.conditionIds);
    }
  }
  final other = present.where(
    (id) =>
        !kAllResourceConditionIds.contains(id) &&
        !kCuratedConditionLabels.containsKey(id) &&
        !_isIgnoredCondition(id),
  );
  return other.toList()..sort();
}

/// Named starting points. A preset just replaces the current criteria.
class FinderPreset {
  final String name;
  final FinderCriteria criteria;
  const FinderPreset(this.name, this.criteria);
}

const List<FinderPreset> kFinderPresets = [
  FinderPreset(
    'Colony Hunter',
    FinderCriteria(
      mustBeHabitable: true,
      minStableLocations: 2,
      resources: {
        'ore': ResourceCriterion(weight: 0.5),
        'rare_ore': ResourceCriterion(weight: 0.5),
        'organics': ResourceCriterion(weight: 0.5),
        'volatiles': ResourceCriterion(weight: 0.5),
        'farmland': ResourceCriterion(weight: 0.5),
      },
      lowHazardWeight: 0.6,
    ),
  ),
  FinderPreset(
    'Resource Baron',
    FinderCriteria(
      resources: {
        'ore': ResourceCriterion(minTier: 4, weight: 1.0),
        'rare_ore': ResourceCriterion(minTier: 3, weight: 1.0),
        'volatiles': ResourceCriterion(weight: 0.5),
      },
    ),
  ),
  FinderPreset(
    'Cryosleeper Nearby',
    FinderCriteria(
      landmarkNearby: {'derelict_cryosleeper': true},
      nearbyRangeLy: 10.0,
      mustBeHabitable: true,
      resources: {
        'farmland': ResourceCriterion(weight: 0.7),
        'organics': ResourceCriterion(weight: 0.5),
      },
    ),
  ),
  FinderPreset(
    'Self-Sufficient',
    FinderCriteria(
      mustBeHabitable: true,
      resources: {
        'farmland': ResourceCriterion(minTier: 2, weight: 1.0),
        'organics': ResourceCriterion(minTier: 2, weight: 0.6),
        'ore': ResourceCriterion(weight: 0.4),
      },
      lowHazardWeight: 0.8,
    ),
  ),
];
