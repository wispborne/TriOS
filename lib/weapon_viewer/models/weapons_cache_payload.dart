import 'dart:typed_data';

import 'package:trios/viewer_cache/packed_bytes.dart';

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
  ///
  /// Held zipped, for the same reason as the ships one: there is one per
  /// installed mod for the whole session, and on a big mod list that was over
  /// fourteen megabytes of msgpack nobody was reading.
  final Uint8List _rawDataZipped;

  /// See [_rawDataZipped]. A fresh copy each time, so read it once per merge
  /// rather than in a loop.
  Uint8List get rawDataBytes => unsqueeze(_rawDataZipped);

  WeaponsCachePayload({
    required this.sourceKey,
    required Uint8List rawDataBytes,
    this.csvFilePath,
  }) : _rawDataZipped = squeeze(rawDataBytes);
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
