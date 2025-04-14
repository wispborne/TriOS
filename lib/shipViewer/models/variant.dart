// import 'package:freezed_annotation/freezed_annotation.dart';
//
// import 'converters/alexMapConverter.dart';
// import 'variantWeapon.dart';
//
// part '../generated/models/variant.freezed.dart';
// part '../generated/models/variant.g.dart';
//
// @freezed
// sealed class Variant with _$Variant {
//   factory Variant({
//     @Default("New Variant") final String displayName,
//     @Default("") final String hullId,
//     @Default("") final String variantId,
//     @Default(0) final int fluxVents,
//     @Default(0) final int fluxCapacitors,
//     @Default([]) final List<String> hullMods,
//     @Default([]) final List<VariantWeapon> weaponGroups,
//     @Default(false) final bool goalVariant,
//     @Default(1.0) final double quality,
//     @Default([]) final List<String> permaMods,
//     @Default([]) final List<String> wings,
//     @AlexMapConverter() @Default({}) final Map<String, dynamic> modules,
//   }) = _Variant;
//
//   factory Variant.fromJson(Map<String, Object?> json) => _$VariantFromJson(json);
// }
