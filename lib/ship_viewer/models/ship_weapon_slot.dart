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

  ShipWeaponSlot({
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

  late final String typeUppercase = type.toUpperCase();
  late final String sizeUppercase = size.toUpperCase();

  /// Whether this slot is an actual mountable weapon slot (not decorative,
  /// system, built-in, launch bay, or station module).
  late final bool isMountable = _mountableTypes.contains(typeUppercase);

  /// Whether this slot is a station module docking point.
  late final bool isStationModule = typeUppercase == 'STATION_MODULE';

}
