// import 'package:freezed_annotation/freezed_annotation.dart';
//
// import 'converters/alexMapConverter.dart';
// import 'shipEngineSlotChange.dart';
// import 'shipWeaponSlotChange.dart';
//
// part '../generated/models/shipSkin.freezed.dart';
// part '../generated/models/shipSkin.g.dart';
//
// @freezed
// sealed class ShipSkin with _$ShipSkin {
//   factory ShipSkin({
//     @Default("base_hull") final String? baseHullId,
//     @Default("base_hull_skin") final String? skinHullId,
//     @Default("Hull Skin") final String? hullName,
//     @Default(false) final bool? restoreToBaseHull,
//     @Default("FRIGATE") final String? hullDesignation,
//     final String? manufacturer,
//     final String? tech,
//     @Default("graphics/ships/skins/new_skin.png") final String? spriteName,
//     @Default("base_hull") final String? descriptionId,
//     final String? descriptionPrefix,
//     final int? fleetPoints,
//     final int? fpMod,
//     final int? fighterBays,
//     final int? ordnancePoints,
//     final String? systemId,
//     @Default(0) final int? baseValue,
//     @Default(1) final double? baseValueMult,
//     final List<String>? removeHints,
//     final List<String>? addHints,
//     final List<String>? removeBuiltInMods, // hullmod ids,
//     final List<String>? builtInMods, // hullmod ids,
//     final List<String>? removeWeaponSlots, // weapon slot id's,
//     @AlexMapConverter()
//     final Map<String, ShipWeaponSlotChange>?
//         weaponSlotChanges, //<String,TStarfarerShipWeaponChange>  weapon slot id --> TStarfarerShipWeapon,
//     final List<String>? removeBuiltInWeapons, // weapon slot id's,
//     @AlexMapConverter() final Map<String, String>? builtInWeapons, //<String,String>  weapon slot id --> weapon id,
//     final List<int>? removeEngineSlots, // engine slot indices (no id's),
//     @AlexMapConverter()
//     final Map<String, ShipEngineSlotChange>?
//         engineSlotChanges, //<String,TStarfarerShipEngineChange>  engine slot index (as string) --> TStarfarerShipEngine,
//     final List<int>? coversColor,
//   }) = _ShipSkin;
//
//   factory ShipSkin.fromJson(Map<String, Object?> json) => _$ShipSkinFromJson(json);
// }
