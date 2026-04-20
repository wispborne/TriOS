import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/cached_variant_store.dart';

/// Pseudo-smolId used for vanilla slices. Vanilla has no ModVariant so we key
/// its entry in `_slices` with this sentinel. Distinct from the on-disk
/// `_vanilla.mp` path to keep in-memory bookkeeping independent of file names.
const String _kVanillaSliceKey = '__vanilla__';

/// Generic cache-first streaming notifier for viewer lists.
///
/// Subclasses define: a `domain` string, a `schemaVersion`, a payload type `P`
/// (with dart_mappable round-trip), and per-variant parse / item-extract /
/// item-id functions. The base owns the three-phase flow:
///   Phase 1: read cached envelopes for all enabled variants in parallel,
///     decode into payloads, yield the flattened dedup'd item list.
///   Phase 2: iterate vanilla + variants in mod order; for each, parse fresh,
///     replace that variant's slice, yield (throttled 500ms), fire-and-forget
///     a cache write guarded by the build token.
///   Phase 3: prune cache files not in the fresh scan's smolId set.
abstract class CachedStreamListNotifier<T, P> extends StreamNotifier<List<T>> {
  /// Incremented each time `build()` starts. Stale builds and queued writes
  /// compare against this and drop out, preventing superseded scans from
  /// clobbering newer cache data.
  int _buildToken = 0;

  /// Per-variant slices in insertion order. Vanilla is always first if
  /// present. `_flatten()` walks this map to produce the yielded list.
  final Map<String, P> _slices = <String, P>{};

  /// Parse diagnostics accumulated during the current build. Reset in
  /// `build()` and flushed to the logger in `onBuildComplete` by default.
  /// Subclasses call `addError` / `addInfo` from their parse impls.
  final List<String> _buildErrors = [];
  final List<String> _buildInfos = [];

  /// Subclasses call this from their parse impls to queue a diagnostic; the
  /// base class flushes them in `onBuildComplete`.
  void addError(String message) => _buildErrors.add(message);

  /// See [addError].
  void addInfo(String message) => _buildInfos.add(message);

  /// Domain name used as the cache subdirectory (e.g. `ships`, `weapons`).
  /// Must be stable across app versions.
  String get domain;

  /// Per-domain cache schema version. Bump manually on breaking payload
  /// changes; mismatched cache files are treated as misses.
  int get schemaVersion;

  /// The concrete store instance. Subclasses typically construct this once
  /// against `Constants.viewerCacheDirPath`.
  CachedVariantStore get store;

  /// Stable item id for cross-variant first-occurrence-wins dedup.
  String itemId(T item);

  /// Deserialize a msgpack payload into the domain's payload type.
  P decodePayload(Uint8List bytes);

  /// Serialize the domain's payload type to msgpack.
  Uint8List encodePayload(P payload);

  /// Extract the list of items contributed by a payload for yield / dedup.
  List<T> itemsFromPayload(P payload);

  /// Resolved list of enabled variants to scan. Called once per build, after
  /// vanilla. Order determines dedup winner (first occurrence wins).
  List<ModVariant> resolveEnabledVariants();

  /// Path to the game core folder. Null means vanilla parsing is skipped for
  /// this build — used if game detection hasn't resolved yet.
  Directory? get gameCorePath;

  /// Current game version for vanilla envelope keying. Null skips vanilla
  /// caching entirely (fresh parse still runs if `gameCorePath` is set).
  String? get currentGameVersion;

  /// Whether this domain's `parseVanilla` / `parseVariant` actually reads
  /// `allItemsSoFar`. Defaults to false; ships overrides to `true` for skin
  /// resolution. When false, the base class skips flattening the slice map
  /// before each parse call (saves O(total items) per variant on cold scan).
  bool get providesItemContext => false;

  /// Parse vanilla data. `allItemsSoFar` is the cache-seeded union available
  /// at the time of parse — used by ship skin resolution for cross-variant
  /// lookups. Empty if `providesItemContext` is false.
  Future<P?> parseVanilla(Directory gameCore, List<T> allItemsSoFar);

  /// Parse a single mod variant. Return `null` to skip (parse error); the
  /// variant's existing cache entry (if any) is preserved rather than
  /// overwritten or pruned.
  Future<P?> parseVariant(ModVariant variant, List<T> allItemsSoFar);

  /// Hook called immediately after a cached payload is decoded in Phase 1.
  /// Subclasses use this to reattach late member fields whose values aren't
  /// serialized (e.g. `ModVariant` back-references on `Ship`/`Weapon`/`Hullmod`).
  /// `sourceVariant` is null for vanilla payloads.
  void rehydratePayload(P payload, ModVariant? sourceVariant) {}

  /// Hook called at the end of Phase 2 with every payload in the fresh scan.
  /// Used by ships to reassemble `moduleVariantsProvider` / `variantHullIdMapProvider`
  /// side-channels. Default is a no-op.
  void onFullScanComplete(Map<String, P> allPayloads) {}

  /// Called before Phase 1 starts; subclasses typically flip loading-state
  /// providers here and/or attach dirty listeners. Default is a no-op.
  void onBuildStart() {}

  /// Optional async wait for upstream providers (e.g. `AppState.modVariants`)
  /// to resolve before the scan starts. Default returns immediately. Return
  /// false to skip the build entirely (e.g. game path unavailable).
  Future<bool> awaitReadiness() async => true;

  /// Called after Phase 3 completes (or after an early return if vanilla/
  /// no-op). Subclasses typically clear loading-state flags here. The default
  /// impl flushes accumulated errors/infos to the log — subclasses that
  /// override should call `super.onBuildComplete(...)` if they want the same.
  void onBuildComplete({required bool fullScanCompleted}) {
    if (_buildErrors.isNotEmpty) {
      Fimber.w('[$domain] parsing errors:\n${_buildErrors.join('\n')}');
    }
    if (_buildInfos.isNotEmpty) {
      Fimber.i('[$domain] parsing info:\n${_buildInfos.join('\n')}');
    }
  }

  @override
  Stream<List<T>> build() async* {
    final myToken = ++_buildToken;
    _slices.clear();
    _buildErrors.clear();
    _buildInfos.clear();

    onBuildStart();

    final ready = await awaitReadiness();
    if (_buildToken != myToken) return;
    if (!ready) {
      onBuildComplete(fullScanCompleted: false);
      return;
    }

    final coreDir = gameCorePath;
    if (coreDir == null) {
      onBuildComplete(fullScanCompleted: false);
      return;
    }

    final variants = resolveEnabledVariants();
    final enabledSmolIds = variants.map((v) => v.smolId).toSet();

    // ── Phase 1: parallel cache read ──────────────────────────────────────
    final cacheStart = DateTime.now();
    final gameVersion = currentGameVersion;

    final vanillaBytesF = gameVersion == null
        ? Future<Uint8List?>.value(null)
        : store.readVanilla(gameVersion, schemaVersion);
    final cachedBytesF = store.readAll(enabledSmolIds, schemaVersion);

    final results = await Future.wait<dynamic>([vanillaBytesF, cachedBytesF]);
    if (_buildToken != myToken) return;

    final vanillaBytes = results[0] as Uint8List?;
    final cachedBytes = results[1] as Map<SmolId, Uint8List>;

    var cacheHits = 0;

    if (vanillaBytes != null) {
      final decoded = _tryDecode(vanillaBytes);
      if (decoded != null) {
        rehydratePayload(decoded, null);
        _slices[_kVanillaSliceKey] = decoded;
        cacheHits++;
      }
    }

    // Seed variant slices in mod order so the flatten respects dedup priority.
    for (final variant in variants) {
      final bytes = cachedBytes[variant.smolId];
      if (bytes == null) continue;
      final decoded = _tryDecode(bytes);
      if (decoded != null) {
        rehydratePayload(decoded, variant);
        _slices[variant.smolId] = decoded;
        cacheHits++;
      }
    }

    yield _flatten();
    final cacheMs = DateTime.now().difference(cacheStart).inMilliseconds;

    // ── Phase 2: fresh scan, progressive replacement ─────────────────────
    final scanStart = DateTime.now();
    const yieldInterval = Duration(milliseconds: 500);
    var lastYieldTime = DateTime.fromMillisecondsSinceEpoch(0);
    var freshCount = 0;
    var fullScanCompleted = false;

    final wantsContext = providesItemContext;

    try {
      // Vanilla first.
      {
        if (_buildToken != myToken) return;
        final vanillaPayload = await parseVanilla(
          coreDir,
          wantsContext ? _flatten() : const [],
        );
        if (_buildToken != myToken) return;
        if (vanillaPayload != null) {
          _slices[_kVanillaSliceKey] = vanillaPayload;
          freshCount++;
          final now = DateTime.now();
          if (now.difference(lastYieldTime) >= yieldInterval) {
            yield _flatten();
            lastYieldTime = now;
          }
          if (gameVersion != null) {
            final bytes = _tryEncode(vanillaPayload);
            if (bytes != null) {
              final token = myToken;
              // Fire-and-forget; guard token at write time.
              unawaited(() async {
                if (_buildToken != token) return;
                await store.writeVanilla(gameVersion, bytes, schemaVersion);
              }());
            }
          }
        }
      }

      for (final variant in variants) {
        if (_buildToken != myToken) return;
        final payload = await parseVariant(
          variant,
          wantsContext ? _flatten() : const [],
        );
        if (_buildToken != myToken) return;
        if (payload == null) continue;
        _slices[variant.smolId] = payload;
        freshCount++;
        final now = DateTime.now();
        if (now.difference(lastYieldTime) >= yieldInterval) {
          yield _flatten();
          lastYieldTime = now;
        }
        final bytes = _tryEncode(payload);
        if (bytes != null) {
          final token = myToken;
          final smolId = variant.smolId;
          unawaited(() async {
            if (_buildToken != token) return;
            await store.write(smolId, bytes, schemaVersion);
          }());
        }
      }

      // Final yield guarantees the UI sees the complete fresh list regardless
      // of where we were in the throttle window.
      yield _flatten();
      fullScanCompleted = true;
    } catch (e, st) {
      Fimber.w('[$domain] fresh scan aborted: $e', ex: e, stacktrace: st);
    }

    if (_buildToken != myToken) return;

    // Drain pending fire-and-forget writes before signaling completion.
    // Yields already happened, so the UI is updated; this just ensures the
    // cache is persisted to disk before the user can hot-restart.
    if (fullScanCompleted) {
      try {
        await store.flushPendingWrites();
      } catch (e, st) {
        Fimber.w(
          '[$domain] flushing pending writes: $e',
          ex: e,
          stacktrace: st,
        );
      }
      if (_buildToken != myToken) return;
    }

    // ── onFullScanComplete side-channel hook ─────────────────────────────
    if (fullScanCompleted) {
      try {
        onFullScanComplete(Map<String, P>.from(_slices));
      } catch (e, st) {
        Fimber.w(
          '[$domain] onFullScanComplete failed: $e',
          ex: e,
          stacktrace: st,
        );
      }
    }

    // ── Phase 3: prune (only on a clean full scan) ────────────────────────
    if (fullScanCompleted) {
      try {
        await store.pruneExcept(enabledSmolIds);
      } catch (e, st) {
        Fimber.w('[$domain] prune failed: $e', ex: e, stacktrace: st);
      }
    }

    final scanMs = DateTime.now().difference(scanStart).inMilliseconds;
    Fimber.i(
      'Loaded $cacheHits from cache in ${cacheMs}ms; '
      'refreshed $freshCount variants in ${scanMs}ms ($domain).',
    );

    onBuildComplete(fullScanCompleted: fullScanCompleted);
  }

  P? _tryDecode(Uint8List bytes) {
    try {
      return decodePayload(bytes);
    } catch (e, st) {
      Fimber.w(
        '[$domain] payload decode failed (treating as miss): $e',
        ex: e,
        stacktrace: st,
      );
      return null;
    }
  }

  /// Recursively normalize msgpack-deserialized structures so nested maps are
  /// `Map<String, dynamic>` (dart_mappable's `fromMap` requires this top-to-
  /// bottom; msgpack returns `Map<dynamic, dynamic>` at every level).
  static dynamic normalizeForMapper(dynamic value) {
    if (value is Map) {
      return <String, dynamic>{
        for (final e in value.entries)
          e.key.toString(): normalizeForMapper(e.value),
      };
    }
    if (value is List) {
      return value.map(normalizeForMapper).toList();
    }
    return value;
  }

  Uint8List? _tryEncode(P payload) {
    try {
      return encodePayload(payload);
    } catch (e, st) {
      Fimber.w(
        '[$domain] payload encode failed (skipping cache write): $e',
        ex: e,
        stacktrace: st,
      );
      return null;
    }
  }

  /// Flatten `_slices` in insertion order with first-occurrence-wins dedup
  /// by `itemId`. Matches today's `distinctBy` semantics.
  List<T> _flatten() {
    final seen = <String>{};
    final out = <T>[];
    for (final payload in _slices.values) {
      for (final item in itemsFromPayload(payload)) {
        if (seen.add(itemId(item))) out.add(item);
      }
    }
    return out;
  }
}
