import 'package:trios/ship_viewer/models/ship_variant.dart';

/// Per-source cache payload for the ships viewer.
///
/// Raw scanned data (CSV rows, `.ship` files, `.skin` files) kept separate so
/// `mergeShips` can resolve them independently. Module/variant data is included
/// because it comes from the same scan.
class ShipsCachePayload {
  /// The source this came from (a smolId, or `__vanilla__` for vanilla).
  final String sourceKey;

  /// Rows from this source's `ship_data.csv`, keys already lower-cased.
  final List<Map<String, dynamic>> rows;

  /// This source's `.ship` files, keyed by their path relative to `data/hulls`.
  final Map<String, Map<String, dynamic>> shipFiles;

  /// This source's `.skin` files, keyed by their path relative to
  /// `data/hulls/skins`.
  final Map<String, Map<String, dynamic>> skinFiles;

  /// Absolute path to this source's `ship_data.csv`.
  final String? csvFilePath;

  final Map<String, ShipVariant> moduleVariants;
  final Map<String, String> hullIdMap;

  const ShipsCachePayload({
    required this.sourceKey,
    required this.rows,
    required this.shipFiles,
    required this.skinFiles,
    required this.moduleVariants,
    required this.hullIdMap,
    this.csvFilePath,
  });
}
