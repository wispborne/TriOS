import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/utils/interned_strings.dart';
import 'package:trios/utils/packed_numbers.dart';

part 'ship_weapon_slot.mapper.dart';

@MappableClass()
class ShipWeaponSlot with ShipWeaponSlotMappable {
  final double angle;
  final double arc;
  final String id;

  final Float64List _locations;
  final Float64List _position;

  /// Where the slot sits on the hull, and where its weapon is drawn. Packed,
  /// because there are two of these per slot and well over a hundred thousand
  /// slots. See [packNumbers].
  List<double> get locations => _locations;

  /// See [locations].
  List<double> get position => _position;

  final String mount;
  final String size;
  final String type;
  final double? renderOrderMod;

  /// A big mod list has well over a hundred thousand weapon slots, and these
  /// four strings are drawn from a short list of words repeated across all of
  /// them — `TURRET`, `LARGE`, `BALLISTIC`, `WS0001`. Sharing one copy of each
  /// saves around fifteen megabytes without changing anything.
  ShipWeaponSlot({
    this.angle = 0,
    String id = '',
    this.arc = 0,
    List<double> locations = const [],
    List<double> position = const [],
    String mount = '',
    String size = '',
    String type = '',
    this.renderOrderMod,
  }) : id = internString(id),
       _locations = packNumbers(locations),
       _position = packNumbers(position),
       mount = internString(mount),
       size = internString(size),
       type = internString(type);

  static const _mountableTypes = {
    'BALLISTIC',
    'ENERGY',
    'MISSILE',
    'COMPOSITE',
    'HYBRID',
    'SYNERGY',
    'UNIVERSAL',
  };

  late final String typeUppercase = internString(type.toUpperCase());
  late final String sizeUppercase = internString(size.toUpperCase());

  /// Whether this slot is an actual mountable weapon slot (not decorative,
  /// system, built-in, launch bay, or station module).
  late final bool isMountable = _mountableTypes.contains(typeUppercase);

  /// Whether this slot is a station module docking point.
  late final bool isStationModule = typeUppercase == 'STATION_MODULE';
}
