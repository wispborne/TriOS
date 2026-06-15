import 'package:trios/weapon_viewer/models/weapon.dart';

/// Per-variant cache payload for the weapons viewer.
class WeaponsCachePayload {
  final List<Weapon> weapons;

  const WeaponsCachePayload({required this.weapons});
}
