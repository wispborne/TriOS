import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/cache_envelope.dart';
import 'package:trios/viewer_cache/cache_fingerprint.dart';

/// One source's cached payload, with the fingerprint recorded when it was
/// written. [fingerprint] is null for files written before fingerprints
/// existed.
class CachedEntry {
  final Uint8List payload;
  final CacheFingerprint? fingerprint;

  const CachedEntry({required this.payload, this.fingerprint});
}

/// One-file-per-variant disk cache for a single domain (ships/weapons/hullmods).
///
/// Files live at `{root}/{domain}/{smolId}.mp`, with a reserved `_vanilla.mp`
/// for vanilla data (keyed internally by game version via the envelope).
/// Writes go through a serialized Future chain so only one write is in flight
/// at a time per store — bounds file-handle usage on large modlists.
class CachedVariantStore {
  final String domain;
  final Directory root;

  CachedVariantStore(this.domain, this.root);

  Future<void> _writeChain = Future.value();

  static const String _vanillaKey = '_vanilla';
  static const String _fileExt = '.mp';

  Directory get _domainDir => Directory(p.join(root.path, domain));

  File _fileFor(String key) => File(p.join(_domainDir.path, '$key$_fileExt'));

  /// Read every cache file for `smolIds` in parallel. Returns only successful
  /// reads whose envelope `schemaVersion` equals `currentSchemaVersion`.
  /// Version mismatches and decode failures are treated as misses, with info-
  /// level logs summarizing counts.
  Future<Map<SmolId, CachedEntry>> readAll(
    Set<SmolId> smolIds,
    int currentSchemaVersion,
  ) async {
    if (smolIds.isEmpty) return <SmolId, CachedEntry>{};

    final dir = _domainDir;
    if (!await dir.exists()) return <SmolId, CachedEntry>{};

    final results = await Future.wait(
      smolIds.map(
        (id) => _readOne(id, currentSchemaVersion, isVanilla: false),
      ),
    );

    final out = <SmolId, CachedEntry>{};
    var versionMisses = 0;
    var decodeMisses = 0;
    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      if (r.entry != null) {
        out[r.key] = r.entry!;
      } else if (r.reason == _MissReason.versionMismatch) {
        versionMisses++;
      } else if (r.reason == _MissReason.decodeFailed) {
        decodeMisses++;
      }
    }

    if (versionMisses > 0) {
      Fimber.i(
        '[$domain] cache: $versionMisses file(s) skipped due to schema version mismatch.',
      );
    }
    if (decodeMisses > 0) {
      Fimber.i(
        '[$domain] cache: $decodeMisses file(s) skipped due to decode failure (corrupt or renamed).',
      );
    }
    return out;
  }

  /// Read vanilla cache. Miss if file absent, corrupt, version mismatched, or
  /// envelope's game version doesn't match `currentGameVersion`.
  Future<CachedEntry?> readVanilla(
    String currentGameVersion,
    int currentSchemaVersion,
  ) async {
    final dir = _domainDir;
    if (!await dir.exists()) return null;
    final r = await _readOne(_vanillaKey, currentSchemaVersion, isVanilla: true);
    if (r.entry == null) return null;
    if (r.gameVersion != currentGameVersion) {
      Fimber.i(
        '[$domain] vanilla cache: game version mismatch '
        '(cached=${r.gameVersion}, current=$currentGameVersion), treating as miss.',
      );
      return null;
    }
    return r.entry;
  }

  Future<_ReadResult> _readOne(
    String key,
    int currentSchemaVersion, {
    required bool isVanilla,
  }) async {
    final file = _fileFor(key);
    try {
      if (!await file.exists()) {
        return _ReadResult(key: key, reason: _MissReason.notFound);
      }
      final bytes = await file.readAsBytes();
      final envelope = CacheEnvelope.tryDecode(bytes);
      if (envelope == null) {
        return _ReadResult(key: key, reason: _MissReason.decodeFailed);
      }
      if (envelope.schemaVersion != currentSchemaVersion) {
        return _ReadResult(key: key, reason: _MissReason.versionMismatch);
      }
      return _ReadResult(
        key: key,
        entry: CachedEntry(
          payload: envelope.payload,
          fingerprint: envelope.fingerprint,
        ),
        gameVersion: envelope.gameVersion,
      );
    } catch (e) {
      Fimber.v(() => '[$domain] cache read failed for $key: $e');
      return _ReadResult(key: key, reason: _MissReason.decodeFailed);
    }
  }

  /// Queue an atomic write: write to `.tmp`, then rename into place. Creates
  /// the domain directory lazily. Errors are logged and swallowed — the cache
  /// is a performance layer, not correctness-critical.
  Future<void> write(
    SmolId smolId,
    Uint8List payload,
    int schemaVersion, {
    CacheFingerprint? fingerprint,
  }) {
    return _queueWrite(
      key: smolId,
      envelope: CacheEnvelope(
        schemaVersion: schemaVersion,
        smolId: smolId,
        payload: payload,
        fingerprint: fingerprint,
      ),
    );
  }

  /// Queue an atomic vanilla write. `gameVersion` is stored in the envelope
  /// and must match on read or the cache is treated as a miss.
  Future<void> writeVanilla(
    String gameVersion,
    Uint8List payload,
    int schemaVersion, {
    CacheFingerprint? fingerprint,
  }) {
    return _queueWrite(
      key: _vanillaKey,
      envelope: CacheEnvelope(
        schemaVersion: schemaVersion,
        smolId: _vanillaKey,
        gameVersion: gameVersion,
        payload: payload,
        fingerprint: fingerprint,
      ),
    );
  }

  Future<void> _queueWrite({
    required String key,
    required CacheEnvelope envelope,
  }) {
    final task = _writeChain.then((_) => _doWrite(key, envelope));
    // Swallow errors on the chain so one failed write doesn't break the chain
    // for subsequent writes.
    _writeChain = task.catchError((Object _) {});
    return task;
  }

  /// Wait for every currently-queued write to complete. Used at end of scan
  /// so the cache is fully on disk before the build cycle is marked done —
  /// otherwise a hot restart between "scan finished" and "writes drained"
  /// would lose the writes that were still queued in the Future chain.
  Future<void> flushPendingWrites() => _writeChain;

  Future<void> _doWrite(String key, CacheEnvelope envelope) async {
    final dir = _domainDir;
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = _fileFor(key);
      final tmp = File('${file.path}.tmp');
      final bytes = envelope.encode();
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(file.path);
    } catch (e, st) {
      Fimber.w(
        '[$domain] cache write failed for $key: $e',
        ex: e,
        stacktrace: st,
      );
    }
  }

  /// Delete files in the domain directory whose basename (without extension)
  /// is not in `keep`. `_vanilla.mp` is always preserved — vanilla invalidates
  /// via game-version mismatch, not pruning.
  Future<void> pruneExcept(Set<SmolId> keep) async {
    final dir = _domainDir;
    if (!await dir.exists()) return;
    try {
      final entries = dir.listSync();
      for (final entry in entries) {
        if (entry is! File) continue;
        final name = p.basenameWithoutExtension(entry.path);
        final ext = p.extension(entry.path);
        if (ext != _fileExt) continue;
        if (name == _vanillaKey) continue;
        if (keep.contains(name)) continue;
        try {
          entry.deleteSync();
        } catch (e) {
          Fimber.w('[$domain] cache prune failed for ${entry.path}: $e');
        }
      }
    } catch (e, st) {
      Fimber.w(
        '[$domain] cache prune listing failed: $e',
        ex: e,
        stacktrace: st,
      );
    }
  }
}

enum _MissReason { notFound, decodeFailed, versionMismatch }

class _ReadResult {
  final String key;
  final CachedEntry? entry;
  final String? gameVersion;
  final _MissReason? reason;

  _ReadResult({
    required this.key,
    this.entry,
    this.gameVersion,
    this.reason,
  });
}
