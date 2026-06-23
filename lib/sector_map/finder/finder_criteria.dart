import 'package:dart_mappable/dart_mappable.dart';

part 'finder_criteria.mapper.dart';

/// One resource family's knobs: an optional hard tier floor and a soft weight.
/// Both are always shown in the UI; either may be neutral.
@MappableClass()
class ResourceCriterion with ResourceCriterionMappable {
  /// Hard cutoff: the system must have a planet at least this tier (1-based).
  /// Null = no floor.
  final int? minTier;

  /// Soft importance, 0..1. Higher means this resource pulls a system up the
  /// ranking. 0 = don't care.
  final double weight;

  const ResourceCriterion({this.minTier, this.weight = 0.0});

  bool get isNeutral => minTier == null && weight == 0.0;
}

/// The full knob state for the system finder. Persisted with page state.
@MappableClass()
class FinderCriteria with FinderCriteriaMappable {
  /// Per resource-family id (`ore`, `rare_ore`, `organics`, `volatiles`,
  /// `farmland`) → its floor + weight.
  final Map<String, ResourceCriterion> resources;

  /// Hard toggles.
  final bool mustBeHabitable;
  final bool mustHaveGasGiant;

  /// Exclude systems that already have a faction colony (find places to settle).
  final bool excludeColonized;

  /// Hard minimum number of stable locations (0 = no requirement).
  final int minStableLocations;

  /// Landmark type id → whether a system of that landmark must be within range.
  final Map<String, bool> landmarkNearby;

  /// Range in light-years for the landmark-nearby checks.
  final double nearbyRangeLy;

  /// Raw modded/uncurated condition id → must-have toggle. The escape hatch.
  final Map<String, bool> otherConditionToggles;

  /// Optional hard cutoff on distance from the core (light-years). Null = none.
  final double? maxDistanceFromCoreLy;

  /// Soft preference for being close to the core (0..1). 0 = don't care.
  final double closeToCoreWeight;

  /// Soft preference for low hazard (0..1). 0 = don't care.
  final double lowHazardWeight;

  const FinderCriteria({
    this.resources = const {},
    this.mustBeHabitable = false,
    this.mustHaveGasGiant = false,
    this.excludeColonized = false,
    this.minStableLocations = 0,
    this.landmarkNearby = const {},
    this.nearbyRangeLy = 10.0,
    this.otherConditionToggles = const {},
    this.maxDistanceFromCoreLy,
    this.closeToCoreWeight = 0.0,
    this.lowHazardWeight = 0.0,
  });

  /// Landmark type ids that are currently required.
  Iterable<String> get requiredLandmarks =>
      landmarkNearby.entries.where((e) => e.value).map((e) => e.key);

  /// Other-condition ids that are currently required.
  Iterable<String> get requiredOtherConditions =>
      otherConditionToggles.entries.where((e) => e.value).map((e) => e.key);
}
