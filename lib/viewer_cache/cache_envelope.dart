import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:trios/utils/logging.dart';

/// Wrapper written to every cache file. Pairs an opaque domain payload with
/// metadata needed for schema-versioning and self-healing on load.
class CacheEnvelope {
  final int schemaVersion;
  final String smolId;
  final String? gameVersion;
  final Uint8List payload;

  const CacheEnvelope({
    required this.schemaVersion,
    required this.smolId,
    required this.payload,
    this.gameVersion,
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
      );
    } catch (e) {
      Fimber.v(() => 'CacheEnvelope decode failed: $e');
      return null;
    }
  }
}
