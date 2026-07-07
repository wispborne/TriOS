import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/dart_mappable_utils.dart';

part 'wing.mapper.dart';

/// A fighter wing, from `data/hulls/wing_data.csv`.
///
/// Full combat stats live on the ship behind the wing (resolved via [hullId]);
/// this model only carries the wing-level fields the Codex needs.
@MappableClass()
class Wing with WingMappable {
  /// Wing id, from the CSV `id` column.
  final String id;

  /// The fighter variant file name (without extension), from the `variant`
  /// column. Used to resolve the ship behind the wing.
  final String? variant;

  /// Comma-separated tags, passed through as a raw String.
  final String? tags;

  final int? tier;
  final double? rarity;

  @MappableField(key: 'fleet pts')
  final int? fleetPts;

  @MappableField(key: 'op cost')
  final int? opCost;

  final String? formation;
  final double? range;

  /// Number of craft in the wing. Maps the CSV `num` column, NOT the separate
  /// trailing `number` column (a plain row counter).
  @MappableField(key: 'num')
  final int? numCraft;

  final String? role;

  @MappableField(key: 'role desc')
  final String? roleDesc;

  final int? refit;

  @MappableField(key: 'base value')
  final double? baseValue;

  /// Hull id of the ship behind this wing, resolved from its `.variant` file.
  /// Null when the variant file or its `hullId` could not be found. Persisted
  /// to the cache manually (see the loader's encode/decode), so it survives a
  /// cache-only load.
  @MappableField(hook: SkipSerializationHook())
  String? hullId;

  /// The mod this wing came from (null = vanilla). Set by the loader after
  /// parsing, so it is skipped during serialization and rehydrated on decode.
  @MappableField(hook: SkipSerializationHook())
  late ModVariant? modVariant;

  Wing({
    required this.id,
    this.variant,
    this.tags,
    this.tier,
    this.rarity,
    this.fleetPts,
    this.opCost,
    this.formation,
    this.range,
    this.numCraft,
    this.role,
    this.roleDesc,
    this.refit,
    this.baseValue,
  });
}
