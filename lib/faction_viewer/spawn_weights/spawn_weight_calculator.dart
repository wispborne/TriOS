import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/faction_viewer/faction_manager.dart';
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/faction_viewer/spawn_weights/ship_roles_manager.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/ship_manager.dart';

/// The roles the game uses to pick warships. The headline "how much of this
/// faction's fleet is vanilla" number is the share of weight across these.
const kCombatRoles = [
  'combatSmall',
  'combatMedium',
  'combatLarge',
  'combatCapital',
  'carrierSmall',
  'carrierMedium',
  'carrierLarge',
  'phaseSmall',
  'phaseMedium',
  'phaseLarge',
  'phaseCapital',
];

/// Which file set a ship's weight, so the UI can open the right one.
enum WeightOrigin {
  /// The mod's `default_ship_roles.json`.
  defaultShipRoles,

  /// The faction's own `.faction` file (`shipRoles` or `variantOverrides`).
  factionFile,
}

/// One ship loadout in one role list, with its final weight.
class SpawnWeightEntry {
  final String loadoutId;
  final String hullId;
  final String shipName;
  final String? hullSize;
  final double weight;

  /// The mod that set this weight, or null if we couldn't tell.
  final String? source;
  final WeightOrigin origin;

  /// This hull is in the faction's `priorityShips`, so the game favors it and
  /// it spawns more often than its weight alone suggests.
  final bool isPriority;

  const SpawnWeightEntry({
    required this.loadoutId,
    required this.hullId,
    required this.shipName,
    required this.hullSize,
    required this.weight,
    required this.source,
    required this.origin,
    this.isPriority = false,
  });
}

/// How a faction's combat spawn weight is split between the game and mods.
class FactionSpawnSummary {
  final double totalWeight;

  /// Weight whose source we couldn't name. Only non-zero before the mod scan
  /// finishes, when the cached faction data has no attribution yet.
  final double unknownWeight;

  /// Source name → weight it owns. Includes `Vanilla`.
  final Map<String, double> weightBySource;

  /// Role entries we couldn't match to a ship (mod not installed, or the
  /// loadout is created by mod code rather than a file).
  final int skippedEntries;

  const FactionSpawnSummary({
    required this.totalWeight,
    required this.unknownWeight,
    required this.weightBySource,
    required this.skippedEntries,
  });

  static const empty = FactionSpawnSummary(
    totalWeight: 0,
    unknownWeight: 0,
    weightBySource: {},
    skippedEntries: 0,
  );

  double get vanillaWeight => weightBySource[kVanillaSourceName] ?? 0;

  double get modWeight => totalWeight - unknownWeight - vanillaWeight;

  /// Share of combat spawn weight that comes from the base game, 0–1.
  /// Null when the faction spawns no warships, or when nothing is attributed
  /// yet (so we show "—" instead of a made-up 0%).
  double? get vanillaShare {
    if (totalWeight <= 0) return null;
    if (unknownWeight >= totalWeight) return null;
    return vanillaWeight / totalWeight;
  }

  /// Sources other than the base game, biggest share first.
  List<MapEntry<String, double>> get topMods {
    final mods = weightBySource.entries
        .where((e) => e.key != kVanillaSourceName)
        .toList();
    mods.sort((a, b) => b.value.compareTo(a.value));
    return mods;
  }
}

/// Every role list for one faction, plus the combat-role summary.
class FactionSpawnWeights {
  final Map<String, List<SpawnWeightEntry>> byRole;
  final FactionSpawnSummary summary;

  /// Role name → the role the game picks from instead when this one is empty.
  final Map<String, String?> fallbackByRole;

  const FactionSpawnWeights({
    required this.byRole,
    required this.summary,
    required this.fallbackByRole,
  });

  static const empty = FactionSpawnWeights(
    byRole: {},
    summary: FactionSpawnSummary.empty,
    fallbackByRole: {},
  );
}

/// Everything the calculator needs that isn't the faction itself.
class SpawnWeightContext {
  final MergedShipRoles defaults;
  final Map<String, String> variantHullIds;
  final Map<String, Ship> shipsByHullId;

  const SpawnWeightContext({
    required this.defaults,
    required this.variantHullIds,
    required this.shipsByHullId,
  });
}

/// Combat-role summary for every faction. Drives the card bar and the grid
/// column, so it only walks the combat roles.
final factionSpawnSummariesProvider =
    Provider<Map<String, FactionSpawnSummary>>((ref) {
      final factions = ref.watch(factionListNotifierProvider).value ?? const [];
      final context = ref.watch(_spawnWeightContextProvider);
      if (context == null) return const {};

      return {
        for (final faction in factions)
          faction.mergeKey: _summarize(faction, context, kCombatRoles),
      };
    });

/// Every role for one faction. Used by the detail view and the dialog.
final factionSpawnWeightsProvider =
    Provider.family<FactionSpawnWeights, String>((ref, mergeKey) {
      final factions = ref.watch(factionListNotifierProvider).value ?? const [];
      final faction = factions.firstWhere(
        (f) => f.mergeKey == mergeKey,
        orElse: () => Faction(mergeKey: mergeKey, id: mergeKey, displayName: ''),
      );
      final context = ref.watch(_spawnWeightContextProvider);
      if (context == null) return FactionSpawnWeights.empty;

      final roleNames = <String>{
        ...context.defaults.roles.keys,
        ...?faction.shipRoles?.keys,
      };

      final byRole = <String, List<SpawnWeightEntry>>{};
      final fallbackByRole = <String, String?>{};
      for (final role in roleNames) {
        byRole[role] = computeRoleWeights(
          faction: faction,
          roleName: role,
          context: context,
        ).entries;
        fallbackByRole[role] = context.defaults.roles[role]?.fallbackRole;
      }

      return FactionSpawnWeights(
        byRole: byRole,
        summary: _summarize(faction, context, kCombatRoles),
        fallbackByRole: fallbackByRole,
      );
    });

/// False until the ship list and merged role data have loaded. The summaries
/// are empty until this flips true, so the UI shows "calculating" rather than
/// a misleading empty result.
final spawnWeightsReadyProvider = Provider<bool>(
  (ref) => ref.watch(_spawnWeightContextProvider) != null,
);

final _spawnWeightContextProvider = Provider<SpawnWeightContext?>((ref) {
  final defaults = ref.watch(mergedShipRolesProvider).value;
  final ships = ref.watch(shipListNotifierProvider).value;
  final variantHullIds = ref.watch(variantHullIdMapProvider);
  if (defaults == null || ships == null || variantHullIds.isEmpty) return null;

  return SpawnWeightContext(
    defaults: defaults,
    variantHullIds: variantHullIds,
    shipsByHullId: {for (final ship in ships) ship.id: ship},
  );
});

FactionSpawnSummary _summarize(
  Faction faction,
  SpawnWeightContext context,
  List<String> roles,
) {
  var total = 0.0;
  var unknown = 0.0;
  var skipped = 0;
  final bySource = <String, double>{};

  for (final role in roles) {
    final result = computeRoleWeights(
      faction: faction,
      roleName: role,
      context: context,
    );
    skipped += result.skippedEntries;
    for (final entry in result.entries) {
      total += entry.weight;
      final source = entry.source;
      if (source == null) {
        unknown += entry.weight;
      } else {
        bySource[source] = (bySource[source] ?? 0) + entry.weight;
      }
    }
  }

  return FactionSpawnSummary(
    totalWeight: total,
    unknownWeight: unknown,
    weightBySource: bySource,
    skippedEntries: skipped,
  );
}

class RoleWeightResult {
  final List<SpawnWeightEntry> entries;
  final int skippedEntries;

  const RoleWeightResult({required this.entries, required this.skippedEntries});
}

/// The game's pipeline for one role, in order:
///   1. take the role's entry list (the faction's own, or the shared default),
///   2. drop hulls the faction doesn't know,
///   3. apply `variantOverrides`,
///   4. multiply by `hullFrequency`,
///   5. drop anything left at zero or below — the game never picks those.
RoleWeightResult computeRoleWeights({
  required Faction faction,
  required String roleName,
  required SpawnWeightContext context,
}) {
  final base = _baseEntries(faction, roleName, context.defaults);
  if (base.isEmpty) {
    return const RoleWeightResult(entries: [], skippedEntries: 0);
  }

  final knownHulls = faction.knownShipIds.toSet();
  final knownTags = faction.knownShipTags.toSet();
  final priorityHulls = faction.priorityShipIds.toSet();
  final priorityTags = faction.priorityShipTags.toSet();
  final overrides = _numberMap(faction.variantOverrides);
  final overrideSources =
      faction.itemAttributions['variantOverrides'] ?? const {};
  final overriddenHulls = {
    for (final loadoutId in overrides.keys)
      if (context.variantHullIds[loadoutId] != null)
        context.variantHullIds[loadoutId]!,
  };
  final hullMultipliers = _numberMap(
    faction.hullFrequency?['hulls'] as Map<String, dynamic>?,
  );
  final tagMultipliers = _numberMap(
    faction.hullFrequency?['tags'] as Map<String, dynamic>?,
  );

  final entries = <SpawnWeightEntry>[];
  var skipped = 0;

  for (final candidate in base) {
    final hullId = context.variantHullIds[candidate.loadoutId];
    final ship = hullId == null ? null : context.shipsByHullId[hullId];
    if (hullId == null || ship == null) {
      skipped++;
      continue;
    }

    final tags = ship.tags ?? const <String>[];

    // 2. The faction has to know the hull, either by id or by one of its tags.
    if (!knownHulls.contains(hullId) && !tags.any(knownTags.contains)) {
      continue;
    }

    var weight = candidate.weight;
    var source = candidate.source;
    var origin = candidate.origin;

    // 3. Naming any loadout of a hull hides that hull's other loadouts, and
    //    the named weight replaces the one from the role list.
    if (overriddenHulls.contains(hullId)) {
      final override = overrides[candidate.loadoutId];
      if (override == null) continue;
      weight = override;
      source = overrideSources[candidate.loadoutId] ?? source;
      origin = WeightOrigin.factionFile;
    }

    // 4. Per-hull and per-tag multipliers compound, on top of any override.
    var multiplier = hullMultipliers[hullId] ?? 1.0;
    for (final tag in tags) {
      final tagMultiplier = tagMultipliers[tag];
      if (tagMultiplier != null) multiplier *= tagMultiplier;
    }
    weight *= multiplier;

    // 5. A zero weight never enters the game's picker.
    if (weight <= 0) continue;

    entries.add(
      SpawnWeightEntry(
        loadoutId: candidate.loadoutId,
        hullId: hullId,
        shipName: ship.name ?? hullId,
        hullSize: ship.hullSize,
        weight: weight,
        source: source,
        origin: origin,
        isPriority:
            priorityHulls.contains(hullId) || tags.any(priorityTags.contains),
      ),
    );
  }

  entries.sort((a, b) => b.weight.compareTo(a.weight));
  return RoleWeightResult(entries: entries, skippedEntries: skipped);
}

class _Candidate {
  final String loadoutId;
  final double weight;
  final String? source;
  final WeightOrigin origin;

  const _Candidate(this.loadoutId, this.weight, this.source, this.origin);
}

/// Step 1: the faction's own `shipRoles` block wins. It only picks up the
/// shared defaults when it says `includeDefault: true`.
List<_Candidate> _baseEntries(
  Faction faction,
  String roleName,
  MergedShipRoles defaults,
) {
  final defaultRole = defaults.roles[roleName];
  final factionRole = faction.shipRoles?[roleName] as Map<String, dynamic>?;

  List<_Candidate> fromDefaults() => [
    if (defaultRole != null)
      for (final entry in defaultRole.weights.entries)
        _Candidate(
          entry.key,
          entry.value,
          defaultRole.sources[entry.key],
          WeightOrigin.defaultShipRoles,
        ),
  ];

  if (factionRole == null) return fromDefaults();

  final includeDefault = factionRole['includeDefault'] == true;
  final byLoadout = <String, _Candidate>{
    if (includeDefault)
      for (final candidate in fromDefaults()) candidate.loadoutId: candidate,
  };

  final sources = faction.itemAttributions['shipRoles.$roleName'] ?? const {};
  for (final entry in factionRole.entries) {
    if (entry.key == 'includeDefault' ||
        entry.key == 'fallback' ||
        entry.key == 'fallback2') {
      continue;
    }
    final weight = toDoubleOrNull(entry.value);
    if (weight == null) continue;
    byLoadout[entry.key] = _Candidate(
      entry.key,
      weight,
      sources[entry.key],
      WeightOrigin.factionFile,
    );
  }

  return byLoadout.values.toList();
}

Map<String, double> _numberMap(Map<String, dynamic>? raw) {
  if (raw == null) return const {};
  final out = <String, double>{};
  for (final entry in raw.entries) {
    final value = toDoubleOrNull(entry.value);
    if (value != null) out[entry.key] = value;
  }
  return out;
}
