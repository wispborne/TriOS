import 'package:trios/ship_systems_manager/ship_system.dart';

/// Per-variant cache payload for ship systems.
class ShipSystemsCachePayload {
  final List<ShipSystem> systems;

  const ShipSystemsCachePayload({required this.systems});
}
