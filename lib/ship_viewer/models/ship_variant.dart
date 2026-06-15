import 'package:dart_mappable/dart_mappable.dart';

part 'ship_variant.mapper.dart';

/// Minimal representation of a Starsector `.variant` file, containing only
/// the fields needed for module resolution.
@MappableClass()
class ShipVariant with ShipVariantMappable {
  final String variantId;
  final String hullId;

  /// Maps STATION weapon slot IDs on the parent hull to module variant IDs.
  /// Only present on variants for ships that have station modules.
  final Map<String, String>? modules;

  const ShipVariant({
    required this.variantId,
    required this.hullId,
    this.modules,
  });
}
