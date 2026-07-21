/// Per-source cache payload for the weapons viewer.
///
/// Raw scanned data (CSV rows, `.wpn` files) kept separate so `mergeWeapons`
/// can resolve them independently.
class WeaponsCachePayload {
  /// The source this came from (a smolId, or `__vanilla__` for vanilla).
  final String sourceKey;

  /// Rows from this source's `weapon_data.csv`, keys already lower-cased.
  final List<Map<String, dynamic>> rows;

  /// This source's `.wpn` files, keyed by their path relative to
  /// `data/weapons`.
  final Map<String, Map<String, dynamic>> wpnFiles;

  /// Absolute path to this source's `weapon_data.csv`.
  final String? csvFilePath;

  const WeaponsCachePayload({
    required this.sourceKey,
    required this.rows,
    required this.wpnFiles,
    this.csvFilePath,
  });
}
