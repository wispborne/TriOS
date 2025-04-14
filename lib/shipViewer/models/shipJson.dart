// import 'package:json_annotation/json_annotation.dart';
//
// import 'shipEngineSlot.dart';
// import 'ship_weapon_slot.dart';
//
// part '../generated/models/shipJson.g.dart';
//
// @JsonSerializable()
// class ShipJson {
//   final List<double>? bounds;
//   final List<double>? center;
//   final double collisionRadius;
//   final List<EngineSlot>? engineSlots;
//   final double height;
//   final double width;
//   final String hullId;
//   final String hullName;
//   final String hullSize;
//   final List<double>? shieldCenter;
//   final double shieldRadius;
//   final String spriteName;
//   final String style;
//   final double viewOffset;
//   final List<ShipWeaponSlot>? weaponSlots;
//   final Map<String, String> builtInWeapons;
//   final List<String>? builtInMods;
//   final String coversColor;
//   final List<String>? builtInWings;
//   final List<double>? moduleAnchor;
//
//   const ShipJson(
//       {this.bounds = const [],
//       this.center,
//       this.collisionRadius = 0,
//       this.engineSlots,
//       this.height = 0,
//       this.width = 0,
//       this.hullId = "",
//       this.hullName = "",
//       this.hullSize = "",
//       this.shieldCenter = const [],
//       this.shieldRadius = 0,
//       this.spriteName = "",
//       this.style = "",
//       this.viewOffset = 0,
//       this.weaponSlots = const [],
//       this.builtInWeapons = const {},
//       this.builtInMods = const [],
//       this.coversColor = "",
//       this.builtInWings = const [],
//       this.moduleAnchor = const []});
//
//   /// Connect the generated function to the `fromJson`
//   /// factory.
//   factory ShipJson.fromJson(Map<String, dynamic> json) => _$ShipJsonFromJson(json);
//
//   /// Connect the generated function to the `toJson` method.
//   Map<String, dynamic> toJson() => _$ShipJsonToJson(this);
//
//   @override
//   String toString() {
//     return 'ShipJson{collisionRadius: $collisionRadius, engineSlots: $engineSlots, height: $height, width: $width, hullId: $hullId, hullName: $hullName, hullSize: $hullSize, shieldCenter: $shieldCenter, shieldRadius: $shieldRadius, spriteName: $spriteName, style: $style, viewOffset: $viewOffset, weaponSlots: $weaponSlots, builtInWeapons: $builtInWeapons, builtInMods: $builtInMods, coversColor: $coversColor, builtInWings: $builtInWings, moduleAnchor: $moduleAnchor}';
//   }
// }
