// import 'package:json_annotation/json_annotation.dart';
//
// import 'shipEngineStyleSpec.dart';
//
// part '../generated/models/shipEngineSlot.g.dart';
//
// /// TStarfarerShipEngine
// @JsonSerializable()
// class EngineSlot {
//   final List<double>? location;
//   final double length;
//   final double width;
//   final double angle;
//   final String style;
//   final String? styleId;
//   final EngineStyleSpec? styleSpec;
//   final double contrailSize;
//
//   EngineSlot(
//       {this.location,
//       this.length = 0,
//       this.width = 0,
//       this.angle = 0,
//       this.style = "",
//       this.styleId = "",
//       this.styleSpec,
//       this.contrailSize = 0});
//
//   /// Connect the generated function to the `fromJson`
//   /// factory.
//   factory EngineSlot.fromJson(Map<String, dynamic> json) => _$EngineSlotFromJson(json);
//
//   /// Connect the generated function to the `toJson` method.
//   Map<String, dynamic> toJson() => _$EngineSlotToJson(this);
//
//   @override
//   String toString() {
//     return 'EngineSlot{location: $location, length: $length, width: $width, angle: $angle, style: $style, styleId: $styleId, styleSpec: $styleSpec, contrailSize: $contrailSize}';
//   }
// }
