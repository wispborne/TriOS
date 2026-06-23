import 'dart:ui';

import 'package:dart_mappable/dart_mappable.dart';

part 'sector.mapper.dart';

/// A parsed snapshot of a save's sector, sufficient to render the hyperspace
/// overview. Produced by `parseCampaignXml` (see `sector_map_parser.dart`).
@MappableClass()
class Sector with SectorMappable {
  final List<SectorSystem> systems;
  final List<SectorConstellation> constellations;

  /// Notable sector landmarks (cryosleeper, gate, coronal tap), each naming the
  /// system it sits in. Used by the finder's "near a landmark" matching.
  final List<SectorLandmark> landmarks;

  /// Player fleet position in hyperspace coordinates, if resolvable. When the
  /// player is inside a system, this is that system's hyperspace position.
  final double? playerX;
  final double? playerY;

  /// Game version the save was written with (for diagnosing alias drift).
  final String gameVersion;

  const Sector({
    this.systems = const [],
    this.constellations = const [],
    this.landmarks = const [],
    this.playerX,
    this.playerY,
    this.gameVersion = '',
  });

  Offset? get playerLocation =>
      (playerX != null && playerY != null) ? Offset(playerX!, playerY!) : null;
}

/// One star system, plotted in hyperspace.
@MappableClass()
class SectorSystem with SectorSystemMappable {
  /// The `Sstm` object id from the save (stable within a single save only).
  final String id;
  final String name;
  final String baseName;

  /// e.g. SINGLE, BINARY_CLOSE, TRINARY_1CLOSE_1FAR, NEBULA, DEEP_SPACE.
  final String type;

  final String? constellationId;

  /// Hyperspace position.
  final double x;
  final double y;

  /// Star color as RGBA ints, if a star was found for the system.
  final List<int>? starColor;

  /// Markets in this system, each a faction pie slice. Empty = uninhabited.
  final List<SectorMarket> markets;

  /// Surveyable planets in this system, with their conditions/resources. Drives
  /// the finder's per-system best-of matching. Excludes stars.
  final List<SectorPlanet> planets;

  /// Number of stable-location entities in this system (orbital build slots).
  final int stableLocationCount;

  const SectorSystem({
    required this.id,
    required this.name,
    required this.baseName,
    required this.type,
    this.constellationId,
    required this.x,
    required this.y,
    this.starColor,
    this.markets = const [],
    this.planets = const [],
    this.stableLocationCount = 0,
  });

  Offset get position => Offset(x, y);

  bool get isInhabited => markets.isNotEmpty;

  /// True if any planet here is habitable (best-of across the system).
  bool get hasHabitable =>
      planets.any((p) => p.conditionIds.contains('habitable'));

  int get planetCount => planets.length;

  Color? get starColorValue => (starColor != null && starColor!.length >= 3)
      ? Color.fromARGB(
          starColor!.length >= 4 ? starColor![3] : 255,
          starColor![0],
          starColor![1],
          starColor![2],
        )
      : null;

  /// Total population weight, used to size the dot and weight pie slices.
  int get totalMarketSize =>
      markets.fold(0, (sum, m) => sum + (m.size < 0 ? 0 : m.size));
}

/// A single market within a system. Slice angle ∝ [size].
@MappableClass()
class SectorMarket with SectorMarketMappable {
  final String factionId;
  final int size;
  final String name;

  const SectorMarket({
    required this.factionId,
    required this.size,
    required this.name,
  });
}

/// A surveyable planet within a system: its type, market conditions/resources,
/// and computed hazard. The finder reduces these to per-system best-of values.
@MappableClass()
class SectorPlanet with SectorPlanetMappable {
  /// Display name, if known (from the planet's `j0.f0`).
  final String name;

  /// Planet type id, e.g. `terran`, `lava`, `gas_giant`, `barren`.
  final String type;

  /// Raw market-condition ids present on this planet (resources + environment).
  final List<String> conditionIds;

  /// Hazard rating as a fraction (1.0 == 100%), computed from [conditionIds].
  final double hazardRating;

  const SectorPlanet({
    this.name = '',
    required this.type,
    this.conditionIds = const [],
    this.hazardRating = 1.0,
  });

  bool get isGasGiant => type == 'gas_giant' || type == 'ice_giant';
}

/// A notable sector landmark, positioned by the system it sits in.
@MappableClass()
class SectorLandmark with SectorLandmarkMappable {
  /// Landmark type id, e.g. `derelict_cryosleeper`, `inactive_gate`,
  /// `coronal_tap`.
  final String typeId;

  /// Display name (from the entity's `j0.f0`).
  final String name;

  /// Id of the [SectorSystem] this landmark is in.
  final String systemId;

  const SectorLandmark({
    required this.typeId,
    required this.name,
    required this.systemId,
  });
}

/// A constellation; its hull is computed from member systems at render time.
@MappableClass()
class SectorConstellation with SectorConstellationMappable {
  final String id;
  final String name;

  const SectorConstellation({required this.id, required this.name});
}
