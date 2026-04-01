import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/shipViewer/models/ship_variant.dart';
import 'package:trios/shipViewer/models/ship_weapon_slot.dart';

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

  // Index ships by ID for fast lookup.
  final shipById = <String, Ship>{};
  for (final s in allShips) {
    shipById[s.id] = s;
  }

  final resolved = <ResolvedModule>[];
  for (final slot in stationSlots) {
    final moduleVariantId = matchedVariant.modules![slot.id];
    if (moduleVariantId == null) continue;

    // Look up the module variant's hullId from the full variant→hull map.
    final moduleHullId = variantHullIdMap[moduleVariantId];
    if (moduleHullId == null) continue;

    final moduleShip = shipById[moduleHullId];
    if (moduleShip == null) continue;

    resolved.add(ResolvedModule(parentSlot: slot, moduleShip: moduleShip));
  }

  return resolved;
}
