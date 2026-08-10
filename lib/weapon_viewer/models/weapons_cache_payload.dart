import 'dart:typed_data';

/// Per-source cache payload for the weapons viewer.
///
/// The raw scanned data (CSV rows, `.wpn` files, missile specs) is only read
/// when the weapon list is merged, so it stays msgpack-encoded in
/// [rawDataBytes] instead of sitting in memory as decoded maps — the decoded
/// form was around three times the size. `mergeWeapons` decodes it with
/// `decodeWeaponsRawData` (in `weapons_manager.dart`) and the decoded form is
/// let go when the merge finishes.
class WeaponsCachePayload {
  /// The source this came from (a smolId, or `__vanilla__` for vanilla).
  final String sourceKey;

  /// Absolute path to this source's `weapon_data.csv`.
  final String? csvFilePath;

  /// This source's `weapon_data.csv` rows, `.wpn` files and missile specs,
  /// msgpack-encoded. See `encodeWeaponsRawData` / `decodeWeaponsRawData`.
  final Uint8List rawDataBytes;

  const WeaponsCachePayload({
    required this.sourceKey,
    required this.rawDataBytes,
    this.csvFilePath,
  });
}

/// The heavy part of a [WeaponsCachePayload], decoded for one merge.
class WeaponsRawData {
  /// Rows from this source's `weapon_data.csv`, keys already lower-cased.
  final List<Map<String, dynamic>> rows;

  /// This source's `.wpn` files, keyed by their path relative to
  /// `data/weapons`.
  final Map<String, Map<String, dynamic>> wpnFiles;

  /// Missile projectiles this source defines in a `.proj` file, keyed by
  /// projectile id. Each holds `sprite` (a game-relative path), `size` and
  /// `center`. Used to draw the missiles loaded on a launcher.
  final Map<String, Map<String, dynamic>> missileSpecs;

  const WeaponsRawData({
    required this.rows,
    required this.wpnFiles,
    this.missileSpecs = const {},
  });
}
