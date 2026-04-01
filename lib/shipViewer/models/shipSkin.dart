import 'package:dart_mappable/dart_mappable.dart';

part 'shipSkin.mapper.dart';

@MappableClass()
class ShipSkin with ShipSkinMappable {
  final String baseHullId;
  final String skinHullId;
  final String? hullName;
  final String? hullDesignation;
  final String? manufacturer;
  final String? tech;
  final String? spriteName;
  final String? systemId;
  final String? descriptionId;
  final String? descriptionPrefix;
  final num? fleetPoints;
  final num? ordnancePoints;
  final num? baseValue;
  final double? baseValueMult;
  final num? fighterBays;
  final num? fpMod;
  final bool? restoreToBaseHull;
  final List<String>? builtInMods;
  final List<String>? removeBuiltInMods;
  final Map<String, String>? builtInWeapons;
  final List<String>? removeBuiltInWeapons;
  final List<String>? removeWeaponSlots;
  final Map<String, dynamic>? weaponSlotChanges;
  final List<String>? removeHints;
  final List<String>? addHints;
  final List<String>? tags;
  final List<String>? builtInWings;
  final List<int>? removeEngineSlots;
  final Map<String, dynamic>? engineSlotChanges;
  final List<int>? coversColor;

  ShipSkin({
    required this.baseHullId,
    required this.skinHullId,
    this.hullName,
    this.hullDesignation,
    this.manufacturer,
    this.tech,
    this.spriteName,
    this.systemId,
    this.descriptionId,
    this.descriptionPrefix,
    this.fleetPoints,
    this.ordnancePoints,
    this.baseValue,
    this.baseValueMult,
    this.fighterBays,
    this.fpMod,
    this.restoreToBaseHull,
    this.builtInMods,
    this.removeBuiltInMods,
    this.builtInWeapons,
    this.removeBuiltInWeapons,
    this.removeWeaponSlots,
    this.weaponSlotChanges,
    this.removeHints,
    this.addHints,
    this.tags,
    this.builtInWings,
    this.removeEngineSlots,
    this.engineSlotChanges,
    this.coversColor,
  });
}
