import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/cache_fingerprint.dart';

/// Wrapper written to every cache file. Pairs an opaque domain payload with
/// metadata needed for schema-versioning and self-healing on load.
class CacheEnvelope {
  final int schemaVersion;
  final String smolId;
  final String? gameVersion;
  final Uint8List payload;

  /// What the parse that produced [payload] read from disk. Used to skip the
  /// next parse when nothing changed. Optional in both directions with no
  /// `schemaVersion` bump: it changes nothing about how the payload is read,
  /// so old files without it and new files carrying it both decode fine.
  /// A payload with no fingerprint just gets parsed fresh.
  final CacheFingerprint? fingerprint;

  const CacheEnvelope({
    required this.schemaVersion,
    required this.smolId,
    required this.payload,
    this.gameVersion,
    this.fingerprint,
  });

  Uint8List encode() {
    final map = <String, dynamic>{
      'v': schemaVersion,
      'smolId': smolId,
      'payload': payload,
    };
    if (gameVersion != null) {
      map['gameVersion'] = gameVersion;
    }
    if (fingerprint != null) {
      map['fingerprint'] = fingerprint!.toEncodable();
    }
    return msgpack.serialize(map);
  }

  /// Returns null on any decode failure (malformed msgpack, missing fields,
  /// wrong types). Callers treat null as a cache miss.
  static CacheEnvelope? tryDecode(Uint8List bytes) {
    try {
      final raw = msgpack.deserialize(bytes);
      if (raw is! Map) return null;
      final version = raw['v'];
      final smolId = raw['smolId'];
      final payload = raw['payload'];
      if (version is! int || smolId is! String || payload == null) {
        return null;
      }
      Uint8List payloadBytes;
      if (payload is Uint8List) {
        payloadBytes = payload;
      } else if (payload is List<int>) {
        payloadBytes = Uint8List.fromList(payload);
      } else {
        return null;
      }
      final gv = raw['gameVersion'];
      return CacheEnvelope(
        schemaVersion: version,
        smolId: smolId,
        gameVersion: gv is String ? gv : null,
        payload: payloadBytes,
        // A corrupt fingerprint decodes to null and the payload still loads —
        // the variant just gets parsed fresh.
        fingerprint: CacheFingerprint.tryDecode(raw['fingerprint']),
      );
    } catch (e) {
      Fimber.v(() => 'CacheEnvelope decode failed: $e');
      return null;
    }
  }
}
