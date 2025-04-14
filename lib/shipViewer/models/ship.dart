// import 'dart:ui';
//
// import 'package:dart_extensions_methods/dart_extension_methods.dart';
//
// import '../utils.dart';
// import 'shipCsv.dart';
// import 'shipJson.dart';
//
// class OldShip {
//   String id;
//   Color color = const Color(0x00000000);
//   ShipCsv shipCsv;
//   ShipJson shipJson;
//   String? modId;
//   String? modName;
//
//   Ship({required this.id, required this.shipCsv, required this.shipJson, required this.modId, required this.modName}) {
//     color = stringToColor(id);
//   }
//
//   Set<String> hintsSplitUppercase() => shipCsv.hints?.split(",").map((e) => e.trim().toUpperCase()).toSet() ?? {};
//
//   Set<String> tagsSplitUppercase() => shipCsv.tags?.split(",").map((e) => e.trim().toUpperCase()).toSet() ?? {};
//
//   // tostring
//   @override
//   String toString() {
//     return 'Name: ${shipCsv.name} ($id)\nMod: ${modName ?? "(vanilla)"}${modId?.let((e) => " ($e)") ?? ""}\nCSV: $shipCsv\nJSON: $shipJson';
//   }
// }
