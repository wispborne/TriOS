import 'package:dart_mappable/dart_mappable.dart';

part 'ship_system.mapper.dart';

@MappableClass()
class ShipSystem with ShipSystemMappable {
  /// Unique identifier, from the CSV `id` column.
  final String id;

  /// Display name, from the CSV `name` column.
  final String? name;

  // @MappableField(key: 'flux/second')
  // final double? fluxPerSecond;
  //
  // @MappableField(key: 'f/s (base rate)')
  // final double? fsBaseRate;
  //
  // @MappableField(key: 'f/s (base cap)')
  // final double? fsBaseCap;
  //
  // @MappableField(key: 'flux/use')
  // final double? fluxUse;
  //
  // @MappableField(key: 'f/u (base rate)')
  // final double? fuBaseRate;
  //
  // @MappableField(key: 'f/u (base cap)')
  // final double? fuBaseCap;
  //
  // @MappableField(key: 'cr/u')
  // final double? crUse;
  //
  // @MappableField(key: 'max uses')
  // final double? maxUses;
  //
  // final double? regen;
  //
  // @MappableField(key: 'regen flat')
  // final double? regenFlat;
  //
  // final double? down;
  // final double? cooldown;
  //
  // /// Many flags are stored as booleans in the CSV (TRUE/FALSE).
  // final bool? toggle;
  // final bool? noDissipation;
  // final bool? noHardDissipation;
  // final bool? hardFlux;
  // final bool? noFiring;
  // final bool? noTurning;
  // final bool? noStrafing;
  // final bool? noAccel;
  // final bool? noShield;
  // final bool? noVent;
  // final bool? isPhaseCloak;
  //
  // /// Comma-separated tags (just passed through as raw String here).
  // final String? tags;
  //
  // /// Path to icon file, from the CSV `icon` column.
  // final String? icon;

  const ShipSystem({
    required this.id,
    this.name,
    // this.fluxPerSecond,
    // this.fsBaseRate,
    // this.fsBaseCap,
    // this.fluxUse,
    // this.fuBaseRate,
    // this.fuBaseCap,
    // this.crUse,
    // this.maxUses,
    // this.regen,
    // this.regenFlat,
    // this.down,
    // this.cooldown,
    // this.toggle,
    // this.noDissipation,
    // this.noHardDissipation,
    // this.hardFlux,
    // this.noFiring,
    // this.noTurning,
    // this.noStrafing,
    // this.noAccel,
    // this.noShield,
    // this.noVent,
    // this.isPhaseCloak,
    // this.tags,
    // this.icon,
  });
}
