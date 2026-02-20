import 'package:dart_mappable/dart_mappable.dart';

part 'ship_weapon_slot.mapper.dart';

@MappableClass()
class ShipWeaponSlot with ShipWeaponSlotMappable {
  final double angle;
  final double arc;
  final String id;
  final List<double> locations;
  final List<double> position;
  final String mount;
  final String size;
  final String type;
  final double? renderOrderMod;

  const ShipWeaponSlot({
    this.angle = 0,
    this.arc = 0,
    this.id = '',
    this.locations = const [],
    this.position = const [],
    this.mount = '',
    this.size = '',
    this.type = '',
    this.renderOrderMod,
  });

  static const _mountableTypes = {
    'BALLISTIC',
    'ENERGY',
    'MISSILE',
    'COMPOSITE',
    'HYBRID',
    'SYNERGY',
    'UNIVERSAL',
  };

  /// Whether this slot is an actual mountable weapon slot (not decorative,
  /// system, built-in, launch bay, or station module).
  bool get isMountable => _mountableTypes.contains(type.toUpperCase());
}
