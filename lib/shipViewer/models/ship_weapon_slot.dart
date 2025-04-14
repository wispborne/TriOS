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
}
