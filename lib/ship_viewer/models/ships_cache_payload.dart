import 'package:trios/ship_viewer/models/ship_gpt.dart';
import 'package:trios/ship_viewer/models/ship_variant.dart';

/// Per-variant cache payload for the ships viewer. One of these is stored in
/// each `{domain}/{smolId}.mp` file. Bundles the primary ship list with the
/// side-channel data that `ShipListNotifier` used to publish separately
/// (module variants + variant-to-hull map).
class ShipsCachePayload {
  final List<Ship> ships;
  final Map<String, ShipVariant> moduleVariants;
  final Map<String, String> hullIdMap;

  const ShipsCachePayload({
    required this.ships,
    required this.moduleVariants,
    required this.hullIdMap,
  });
}
