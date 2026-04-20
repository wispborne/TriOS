import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/ship_viewer/models/ship_gpt.dart';
import 'package:trios/ship_viewer/models/ship_variant.dart';
import 'package:trios/ship_viewer/models/ship_weapon_slot.dart';
import 'package:trios/ship_viewer/ship_manager.dart';

/// A resolved module: the parent's STATION slot paired with the actual module
/// [Ship] that docks there.
class ResolvedModule {
  final ShipWeaponSlot parentSlot;
  final Ship moduleShip;

  const ResolvedModule({
    required this.parentSlot,
    required this.moduleShip,
  });
}

/// Riverpod provider that resolves station modules for a ship by ID.
final resolvedModulesProvider =
    Provider.family<List<ResolvedModule>, String>((ref, shipId) {
  final allShips = ref.watch(shipListNotifierProvider).valueOrNull ?? [];
  final moduleVariants = ref.watch(moduleVariantsProvider);
  final variantHullIdMap = ref.watch(variantHullIdMapProvider);

  final parentShip = allShips.firstWhereOrNull((s) => s.id == shipId);
  if (parentShip == null) return const [];

  return resolveModules(parentShip, allShips, moduleVariants, variantHullIdMap);
});

/// Resolve station modules for [parentShip] by finding a variant that maps
/// its STATION_MODULE slots to module hull IDs, then looking up those hulls
/// in [allShips].
///
/// [moduleVariants] contains only variants that have a `modules` field.
/// [variantHullIdMap] maps ALL variant IDs to their hull IDs (needed to
/// resolve module variant ID → hull ID).
///
/// Returns an empty list if the ship has no station module slots or no
/// matching variant is found.
List<ResolvedModule> resolveModules(
  Ship parentShip,
  List<Ship> allShips,
  Map<String, ShipVariant> moduleVariants,
  Map<String, String> variantHullIdMap,
) {
  if (!parentShip.hasStationSlots) return const [];

  // Index ships by ID for fast lookup.
  final shipById = <String, Ship>{};
  for (final s in allShips) {
    shipById[s.id] = s;
  }

  return _resolveModulesWithIndex(
    parentShip,
    shipById,
    moduleVariants,
    variantHullIdMap,
  );
}

/// Variant of [resolveModules] that accepts a pre-built `shipById` index and
/// avoids rebuilding it per call. Intended for batch/set-building loops.
List<ResolvedModule> _resolveModulesWithIndex(
  Ship parentShip,
  Map<String, Ship> shipById,
  Map<String, ShipVariant> moduleVariants,
  Map<String, String> variantHullIdMap,
) {
  if (!parentShip.hasStationSlots) return const [];

  final stationSlots =
      parentShip.weaponSlots!.where((s) => s.isStationModule).toList();

  // Find a variant whose hullId matches this ship and that defines modules.
  // Take the first one found (any variant for this hull will do since we
  // just need the slot → module mapping).
  ShipVariant? matchedVariant;
  for (final v in moduleVariants.values) {
    if (v.hullId != parentShip.id) continue;
    if (v.modules == null || v.modules!.isEmpty) continue;
    matchedVariant = v;
    break;
  }

  if (matchedVariant == null) return const [];

  final resolved = <ResolvedModule>[];
  for (final slot in stationSlots) {
    final moduleVariantId = matchedVariant.modules![slot.id];
    if (moduleVariantId == null) continue;

    final moduleHullId = variantHullIdMap[moduleVariantId];
    if (moduleHullId == null) continue;

    final moduleShip = shipById[moduleHullId];
    if (moduleShip == null) continue;

    resolved.add(ResolvedModule(parentSlot: slot, moduleShip: moduleShip));
  }

  return resolved;
}

/// Compute the set of ship IDs that have at least one resolvable station
/// module. Builds `shipById` once and reuses it across all ships, so the
/// inner loop is O(1) map lookups per ship instead of O(N) inserts.
Set<String> computeShipsWithModuleIds(
  List<Ship> allShips,
  Map<String, ShipVariant> moduleVariants,
  Map<String, String> variantHullIdMap,
) {
  final shipById = <String, Ship>{};
  for (final s in allShips) {
    shipById[s.id] = s;
  }

  final result = <String>{};
  for (final ship in allShips) {
    if (_resolveModulesWithIndex(
      ship,
      shipById,
      moduleVariants,
      variantHullIdMap,
    ).isNotEmpty) {
      result.add(ship.id);
    }
  }
  return result;
}
