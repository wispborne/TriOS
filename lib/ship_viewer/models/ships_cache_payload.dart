import 'dart:typed_data';

import 'package:trios/ship_viewer/models/ship_variant.dart';

/// Per-source cache payload for the ships viewer.
///
/// The raw scanned data (CSV rows, `.ship` files, `.skin` files) is only read
/// when the ship list is merged, so it stays msgpack-encoded in [rawDataBytes]
/// instead of sitting in memory as decoded maps — the decoded form was around
/// three times the size. `mergeShips` decodes it with `decodeShipsRawData`
/// (in `ship_manager.dart`) and the decoded form is let go when the merge
/// finishes. Module/variant data is small and read outside merges, so it
/// stays decoded.
class ShipsCachePayload {
  /// The source this came from (a smolId, or `__vanilla__` for vanilla).
  final String sourceKey;

  /// Absolute path to this source's `ship_data.csv`.
  final String? csvFilePath;

  final Map<String, ShipVariant> moduleVariants;
  final Map<String, String> hullIdMap;

  /// This source's `ship_data.csv` rows, `.ship` files and `.skin` files,
  /// msgpack-encoded. See `encodeShipsRawData` / `decodeShipsRawData`.
  final Uint8List rawDataBytes;

  const ShipsCachePayload({
    required this.sourceKey,
    required this.moduleVariants,
    required this.hullIdMap,
    required this.rawDataBytes,
    this.csvFilePath,
  });
}

/// The heavy part of a [ShipsCachePayload], decoded for one merge.
class ShipsRawData {
  /// Rows from this source's `ship_data.csv`, keys already lower-cased.
  final List<Map<String, dynamic>> rows;

  /// This source's `.ship` files, keyed by their path relative to `data/hulls`.
  final Map<String, Map<String, dynamic>> shipFiles;

  /// This source's `.skin` files, keyed by their path relative to
  /// `data/hulls/skins`.
  final Map<String, Map<String, dynamic>> skinFiles;

  const ShipsRawData({
    required this.rows,
    required this.shipFiles,
    required this.skinFiles,
  });
}
