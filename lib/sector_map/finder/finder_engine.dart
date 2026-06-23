import 'dart:math' as math;
import 'dart:ui';

import 'package:trios/sector_map/finder/finder_catalog.dart';
import 'package:trios/sector_map/finder/finder_criteria.dart';
import 'package:trios/sector_map/models/sector.dart';

/// Hyperspace units per light-year (vanilla `settings.json`).
const double kUnitsPerLightYear = 2000.0;

/// A system that passed all hard constraints, with its soft score (0..1) and
/// distance from the core.
class ScoredSystem {
  final SectorSystem system;
  final double score;
  final double distanceFromCoreLy;

  const ScoredSystem({
    required this.system,
    required this.score,
    required this.distanceFromCoreLy,
  });
}

/// One relaxable bottleneck: removing [constraint] would yield [countIfRemoved]
/// matches. Used by the zero-match helper.
class BottleneckHint {
  /// Human-readable name of the constraint to relax.
  final String constraint;
  final int countIfRemoved;

  const BottleneckHint(this.constraint, this.countIfRemoved);
}

/// Precomputed per-system facts, built once per [Sector].
class _SystemFacts {
  final SectorSystem system;
  final Offset pos;
  final Set<String> conditions; // union across planets
  final bool hasGasGiant;
  final bool hasHabitable;
  final bool colonized;
  final int stableLocs;

  /// Lowest planet hazard in the system (best-of), or 1.0 if no planets.
  final double minHazard;

  double distFromCoreLy = 0.0;

  _SystemFacts({
    required this.system,
    required this.pos,
    required this.conditions,
    required this.hasGasGiant,
    required this.hasHabitable,
    required this.colonized,
    required this.stableLocs,
    required this.minHazard,
  });
}

/// Pure-Dart matching + scoring over a parsed [Sector]. Build once per loaded
/// sector; the criteria-driven methods are cheap to re-run on every knob change.
class FinderEngine {
  final Sector sector;
  final List<_SystemFacts> _facts;
  final Map<String, List<Offset>> _landmarkPositions;

  FinderEngine(this.sector)
    : _facts = _buildFacts(sector),
      _landmarkPositions = _buildLandmarkPositions(sector) {
    _computeDistancesFromCore();
  }

  static List<_SystemFacts> _buildFacts(Sector sector) {
    return [
      for (final s in sector.systems)
        _SystemFacts(
          system: s,
          pos: s.position,
          conditions: {for (final p in s.planets) ...p.conditionIds},
          hasGasGiant: s.planets.any((p) => p.isGasGiant),
          hasHabitable: s.hasHabitable,
          colonized: s.markets.any((m) => m.factionId != 'neutral'),
          stableLocs: s.stableLocationCount,
          minHazard: s.planets.isEmpty
              ? 1.0
              : s.planets.map((p) => p.hazardRating).reduce(math.min),
        ),
    ];
  }

  static Map<String, List<Offset>> _buildLandmarkPositions(Sector sector) {
    final posBySystem = {for (final s in sector.systems) s.id: s.position};
    final result = <String, List<Offset>>{};
    for (final l in sector.landmarks) {
      final pos = posBySystem[l.systemId];
      if (pos != null) (result[l.typeId] ??= []).add(pos);
    }
    return result;
  }

  void _computeDistancesFromCore() {
    final anchor = _coreAnchor();
    for (final f in _facts) {
      f.distFromCoreLy = (f.pos - anchor).distance / kUnitsPerLightYear;
    }
  }

  /// Core reference = population-weighted centroid of inhabited systems, falling
  /// back to the sector origin. Adapts to any save/mod layout.
  Offset _coreAnchor() {
    var sx = 0.0, sy = 0.0, w = 0.0;
    for (final f in _facts) {
      final weight = f.system.totalMarketSize.toDouble();
      if (weight <= 0) continue;
      sx += f.pos.dx * weight;
      sy += f.pos.dy * weight;
      w += weight;
    }
    if (w <= 0) return Offset.zero;
    return Offset(sx / w, sy / w);
  }

  /// All systems passing the hard constraints, scored and sorted best-first.
  List<ScoredSystem> filter(FinderCriteria c) {
    final result = <ScoredSystem>[];
    for (final f in _facts) {
      if (!_passesHard(f, c)) continue;
      result.add(
        ScoredSystem(
          system: f.system,
          score: _score(f, c),
          distanceFromCoreLy: f.distFromCoreLy,
        ),
      );
    }
    result.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      // Tie-break: lower distance from core, then more planets.
      final byDist = a.distanceFromCoreLy.compareTo(b.distanceFromCoreLy);
      if (byDist != 0) return byDist;
      return b.system.planetCount.compareTo(a.system.planetCount);
    });
    return result;
  }

  /// Number of systems passing the hard constraints (drives the live count).
  int matchCount(FinderCriteria c) {
    var n = 0;
    for (final f in _facts) {
      if (_passesHard(f, c)) n++;
    }
    return n;
  }

  bool _passesHard(_SystemFacts f, FinderCriteria c) {
    if (c.mustBeHabitable && !f.hasHabitable) return false;
    if (c.mustHaveGasGiant && !f.hasGasGiant) return false;
    if (c.excludeColonized && f.colonized) return false;
    if (c.minStableLocations > 0 && f.stableLocs < c.minStableLocations) {
      return false;
    }

    // Resource floors (best-of: any planet meeting the tier counts).
    for (final entry in c.resources.entries) {
      final crit = entry.value;
      if (crit.minTier == null) continue;
      final family = resourceFamilyById(entry.key);
      if (family == null) continue;
      if (family.bestTier(f.conditions) < crit.minTier!) return false;
    }

    // Other-condition required toggles (best-of: any planet has it).
    for (final id in c.requiredOtherConditions) {
      if (!f.conditions.contains(id)) return false;
    }

    // Landmark proximity.
    for (final typeId in c.requiredLandmarks) {
      if (!_withinRange(f.pos, typeId, c.nearbyRangeLy)) return false;
    }

    // Distance-from-core hard cutoff.
    if (c.maxDistanceFromCoreLy != null &&
        f.distFromCoreLy > c.maxDistanceFromCoreLy!) {
      return false;
    }

    return true;
  }

  bool _withinRange(Offset pos, String landmarkTypeId, double rangeLy) {
    final positions = _landmarkPositions[landmarkTypeId];
    if (positions == null || positions.isEmpty) return false;
    final rangeUnits = rangeLy * kUnitsPerLightYear;
    for (final lp in positions) {
      if ((pos - lp).distance <= rangeUnits) return true;
    }
    return false;
  }

  /// Soft score in 0..1: weighted average of resource tiers, low-hazard, and
  /// closeness to core. Returns 0 when no soft weights are set.
  double _score(_SystemFacts f, FinderCriteria c) {
    var weighted = 0.0, totalWeight = 0.0;

    for (final entry in c.resources.entries) {
      final crit = entry.value;
      if (crit.weight <= 0) continue;
      final family = resourceFamilyById(entry.key);
      if (family == null) continue;
      final value = family.bestTier(f.conditions) / family.maxTier;
      weighted += crit.weight * value;
      totalWeight += crit.weight;
    }

    if (c.lowHazardWeight > 0) {
      // Map hazard ~[0.5 .. 3.0] to a 0..1 "lower is better" value.
      final v = (1.5 - f.minHazard) / 1.0;
      weighted += c.lowHazardWeight * v.clamp(0.0, 1.0);
      totalWeight += c.lowHazardWeight;
    }

    if (c.closeToCoreWeight > 0) {
      final maxDist = _maxDistFromCore();
      final v = maxDist <= 0 ? 0.0 : 1.0 - (f.distFromCoreLy / maxDist);
      weighted += c.closeToCoreWeight * v.clamp(0.0, 1.0);
      totalWeight += c.closeToCoreWeight;
    }

    return totalWeight <= 0 ? 0.0 : weighted / totalWeight;
  }

  double? _maxDistCache;
  double _maxDistFromCore() {
    return _maxDistCache ??= _facts.isEmpty
        ? 0.0
        : _facts.map((f) => f.distFromCoreLy).reduce(math.max);
  }

  /// For the zero-match helper: which single hard constraint, if relaxed, would
  /// unlock matches. Only constraints that currently bite are reported, sorted
  /// by how many matches they'd unlock (most first).
  List<BottleneckHint> bottleneck(FinderCriteria c) {
    final hints = <BottleneckHint>[];

    void probe(String label, FinderCriteria relaxed) {
      final n = matchCount(relaxed);
      if (n > 0) hints.add(BottleneckHint(label, n));
    }

    if (c.mustBeHabitable) {
      probe('Habitable', c.copyWith(mustBeHabitable: false));
    }
    if (c.mustHaveGasGiant) {
      probe('Gas giant', c.copyWith(mustHaveGasGiant: false));
    }
    if (c.excludeColonized) {
      probe('Unclaimed only', c.copyWith(excludeColonized: false));
    }
    if (c.minStableLocations > 0) {
      probe('Stable locations', c.copyWith(minStableLocations: 0));
    }
    if (c.maxDistanceFromCoreLy != null) {
      probe(
        'Distance from core',
        c.copyWith(maxDistanceFromCoreLy: null),
      );
    }
    for (final entry in c.resources.entries) {
      if (entry.value.minTier == null) continue;
      final family = resourceFamilyById(entry.key);
      final label = family?.label ?? entry.key;
      final relaxedResources = Map<String, ResourceCriterion>.from(c.resources);
      relaxedResources[entry.key] = ResourceCriterion(
        weight: entry.value.weight,
      );
      probe('$label floor', c.copyWith(resources: relaxedResources));
    }
    for (final typeId in c.requiredLandmarks.toList()) {
      final label = kLandmarkLabels[typeId] ?? typeId;
      final relaxed = Map<String, bool>.from(c.landmarkNearby)..[typeId] = false;
      probe('Near $label', c.copyWith(landmarkNearby: relaxed));
    }
    for (final id in c.requiredOtherConditions.toList()) {
      final relaxed = Map<String, bool>.from(c.otherConditionToggles)
        ..[id] = false;
      probe(id, c.copyWith(otherConditionToggles: relaxed));
    }

    hints.sort((a, b) => b.countIfRemoved.compareTo(a.countIfRemoved));
    return hints;
  }
}
