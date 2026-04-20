import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:trios/portraits/models/portraits_cache_payload.dart';
import 'package:trios/portraits/portrait_metadata.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/cached_stream_list_notifier.dart';
import 'package:trios/viewer_cache/cached_variant_store.dart';

import '../models/mod_variant.dart';
import 'portrait_scanner.dart';

class PortraitsNotifier
    extends AsyncNotifier<Map<ModVariant?, List<Portrait>>> {
  /// Whether portraits are still being loaded.
  /// [PortraitsNotifier] streams its results, meaning that even at 1% loaded, it's considered to be loaded since it has a value.
  /// This is a separate state tracker.
  var isLoadingPortraits = false;

  var _lastState = <ModVariant?, List<Portrait>>{};
  var _lastGameFolder = "";
  var _fullRescanRequested = false;

  /// Incremented each time build() starts. Stale builds compare against this
  /// and break early, preventing concurrent scans from flooding the message queue.
  var _buildToken = 0;

  static const int _schemaVersion = 1;
  late final CachedVariantStore _store =
      CachedVariantStore('portraits', Constants.viewerCacheDirPath);

  @override
  Future<Map<ModVariant?, List<Portrait>>> build() async {
    // Rebuild when these change (mods added/removed, game folder change)
    ref.watch(AppState.smolIds);
    final gameCoreFolder = ref.watch(AppState.gameCoreFolder).value;

    // Capture a token so stale concurrent builds can bail out early.
    final myToken = ++_buildToken;

    // Mark loading
    isLoadingPortraits = true;

    // Wait for metadata to finish loading.
    while (ref.read(AppState.portraitMetadata.notifier).isLoading) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_buildToken != myToken) return _lastState;
    }

    final metadata = ref.watch(AppState.portraitMetadata);

    try {
      if (gameCoreFolder == null) {
        // No game folder set: return empty but not error
        isLoadingPortraits = false;
        return _lastState;
      }

      final mods = ref.read(AppState.mods);
      final variants = mods
          .map((mod) => mod.findFirstEnabledOrHighestVersion)
          .toList();

      // Always include null (Vanilla) in the variants list
      if (!variants.contains(null)) {
        variants.add(null);
      }

      final enabledSmolIds = variants
          .whereType<ModVariant>()
          .map((v) => v.smolId)
          .toSet();
      final gameVersion = ref.read(AppState.starsectorVersion).value;

      // Phase 1: seed state from per-variant disk cache before any filesystem
      // work. Gives every variant (vanilla + mods) an instant first paint on
      // warm launches.
      if (_lastState.isEmpty) {
        final cached = await _seedFromCache(variants, gameVersion, myToken);
        if (_buildToken != myToken) return _lastState;
        if (cached.isNotEmpty) {
          _lastState = cached;
          state = AsyncValue.data(cached);
        }
      }

      if (_lastState.isEmpty) {
        Fimber.i("Scanning all portraits for the first time.");
        _fullRescanRequested = true;
      }

      if (_lastGameFolder.isNotEmpty &&
          gameCoreFolder.path != _lastGameFolder) {
        Fimber.i("Game folder changed, invalidating portraits.");
        _fullRescanRequested = true;
      }

      final scanner = PortraitScanner();

      if (!_fullRescanRequested) {
        // Fast path: remove deleted variants, keep existing ones, then stream-in new ones.
        final removedVariants = _lastState.keys.subtract(variants).toList();
        final result = Map<ModVariant?, List<Portrait>>.from(_lastState);
        for (final variant in removedVariants) {
          result.remove(variant);
          Fimber.i(
            "Removed variant ${variant?.smolId} from portrait scanning.",
          );
        }

        final existingSmolIds = _lastState.keys
            .whereType<ModVariant>()
            .map((v) => v.smolId)
            .toSet();

        final newVariants = variants
            .where((v) => !existingSmolIds.contains(v?.smolId))
            .nonNulls // Remove vanilla, it's never a "new" mod.
            .toList();

        Fimber.i(
          "Differential scan: removed ${removedVariants.length} variants, added ${newVariants.length} variants.",
        );

        // 1) Immediately publish current known state
        state = AsyncValue.data(result);
        _lastState = result;

        // 2) Stream updates for newly added variants, merging as we go
        if (newVariants.isNotEmpty) {
          final seenKeys = <String>{};
          await for (final partial in scanner.scanVariantsStream(
            newVariants,
            gameCoreFolder,
          )) {
            if (_buildToken != myToken) return _lastState;
            Fimber.i(
              "Added variant ${partial.keys.first?.smolId} to portrait scanning.",
            );
            final merged = <ModVariant?, List<Portrait>>{...result, ...partial};
            state = AsyncValue.data(merged);
            _lastState = merged;
            _writeNewEntriesToCache(partial, seenKeys, myToken, gameVersion);
          }
        }
      } else {
        // Full rescan path
        final metadataMap = metadata.value ?? {};
        var baseState = <ModVariant?, List<Portrait>>{};
        if (metadataMap.isNotEmpty) {
          if (_buildToken != myToken) return _lastState;
          final knownPortraits = await _loadKnownPortraitsFromMetadata(
            scanner,
            variants,
            gameCoreFolder,
            metadataMap,
            myToken,
          );
          if (knownPortraits.isNotEmpty) {
            baseState = Map.from(knownPortraits);
            state = AsyncValue.data(knownPortraits);
            _lastState = knownPortraits;
          }
        }

        final knownReplacementPaths = await ref
            .read(AppState.portraitReplacementsManager.notifier)
            .getKnownReplacementRelativePaths();
        if (knownReplacementPaths.isNotEmpty) {
          if (_buildToken != myToken) return _lastState;
          final knownReplacementPortraits = await _loadKnownPortraitsFromPaths(
            scanner,
            variants,
            gameCoreFolder,
            knownReplacementPaths,
            myToken,
          );
          if (knownReplacementPortraits.isNotEmpty) {
            baseState = _mergeKnownPortraits(
              baseState,
              knownReplacementPortraits,
            );
            state = AsyncValue.data(baseState);
            _lastState = baseState;
          }
        }

        final seenKeys = <String>{};
        await for (final result in scanner.scanVariantsStream(
          variants,
          gameCoreFolder,
        )) {
          if (_buildToken != myToken) return _lastState;
          final merged = <ModVariant?, List<Portrait>>{...baseState, ...result};
          state = AsyncValue.data(merged);
          _lastState = merged;
          baseState = merged;
          _writeNewEntriesToCache(result, seenKeys, myToken, gameVersion);
        }
      }

      _lastGameFolder = gameCoreFolder.path;
      _fullRescanRequested = false;

      // Phase 3: flush pending writes then prune stale cache entries.
      // Guarded on token so cancelled builds don't prune a newer build's work.
      if (_buildToken == myToken) {
        try {
          await _store.flushPendingWrites();
        } catch (e, st) {
          Fimber.w(
            '[portraits] flushing pending writes: $e',
            ex: e,
            stacktrace: st,
          );
        }
        if (_buildToken == myToken) {
          try {
            await _store.pruneExcept(enabledSmolIds);
          } catch (e, st) {
            Fimber.w('[portraits] prune failed: $e', ex: e, stacktrace: st);
          }
        }
      }

      return _lastState;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    } finally {
      isLoadingPortraits = false;
    }
  }

  Future<void> rescan() async {
    _fullRescanRequested = true;
    await build();
  }

  Future<Map<ModVariant?, List<Portrait>>> _loadKnownPortraitsFromMetadata(
    PortraitScanner scanner,
    List<ModVariant?> variants,
    Directory gameCoreFolder,
    Map<String, PortraitMetadata> metadataMap,
    int buildToken,
  ) async {
    return _loadKnownPortraitsFromPaths(
      scanner,
      variants,
      gameCoreFolder,
      metadataMap.keys,
      buildToken,
    );
  }

  Future<Map<ModVariant?, List<Portrait>>> _loadKnownPortraitsFromPaths(
    PortraitScanner scanner,
    List<ModVariant?> variants,
    Directory gameCoreFolder,
    Iterable<String> relativePaths,
    int buildToken,
  ) async {
    final knownPortraits = <ModVariant?, List<Portrait>>{};

    for (final variant in variants) {
      if (_buildToken != buildToken) return {};
      final knownPortraitsForVariant = await scanner.scanKnownPortraits(
        variant,
        gameCoreFolder,
        relativePaths,
        isCancelled: () => _buildToken != buildToken,
      );
      if (knownPortraitsForVariant.isNotEmpty) {
        knownPortraits[variant] = knownPortraitsForVariant;
      }
    }

    return knownPortraits;
  }

  /// Read cached portrait payloads for every enabled variant in parallel and
  /// assemble a `Map<ModVariant?, List<Portrait>>` ready to drop into `state`.
  /// Missed reads (schema mismatch, decode failure, absent file) are silently
  /// skipped — the fresh scan fills them in. Vanilla is keyed on `null`.
  Future<Map<ModVariant?, List<Portrait>>> _seedFromCache(
    List<ModVariant?> variants,
    String? gameVersion,
    int myToken,
  ) async {
    final enabledVariants = variants.whereType<ModVariant>().toList();
    final enabledSmolIds = enabledVariants.map((v) => v.smolId).toSet();

    final vanillaF = gameVersion == null
        ? Future<Uint8List?>.value(null)
        : _store.readVanilla(gameVersion, _schemaVersion);
    final modF = _store.readAll(enabledSmolIds, _schemaVersion);

    final results = await Future.wait<dynamic>([vanillaF, modF]);
    if (_buildToken != myToken) return {};

    final seeded = <ModVariant?, List<Portrait>>{};

    final vanillaBytes = results[0] as Uint8List?;
    if (vanillaBytes != null) {
      final payload = _tryDecode(vanillaBytes, 'vanilla');
      if (payload != null) {
        for (final p in payload.portraits) {
          p.modVariant = null;
        }
        seeded[null] = payload.portraits;
      }
    }

    final modBytes = results[1] as Map<String, Uint8List>;
    for (final variant in enabledVariants) {
      final bytes = modBytes[variant.smolId];
      if (bytes == null) continue;
      final payload = _tryDecode(bytes, variant.smolId);
      if (payload != null) {
        for (final p in payload.portraits) {
          p.modVariant = variant;
        }
        seeded[variant] = payload.portraits;
      }
    }

    return seeded;
  }

  /// Walk a streamed partial result and fire-and-forget a cache write for any
  /// entry whose key hasn't been written yet this build. `seenKeys` threads
  /// between iterations so each variant is written exactly once per scan.
  void _writeNewEntriesToCache(
    Map<ModVariant?, List<Portrait>> partial,
    Set<String> seenKeys,
    int myToken,
    String? gameVersion,
  ) {
    for (final entry in partial.entries) {
      final variant = entry.key;
      final smolId = variant?.smolId ?? '__vanilla__';
      if (!seenKeys.add(smolId)) continue;
      _writePortraitsToCache(variant, entry.value, myToken, gameVersion);
    }
  }

  /// Fire-and-forget cache write for a single variant's portraits. Build-token
  /// guarded at write time so a superseded scan can't clobber a newer build's
  /// cache entry.
  void _writePortraitsToCache(
    ModVariant? variant,
    List<Portrait> portraits,
    int myToken,
    String? gameVersion,
  ) {
    final Uint8List bytes;
    try {
      bytes = _encode(PortraitsCachePayload(portraits: portraits));
    } catch (e, st) {
      Fimber.w(
        '[portraits] encode failed for ${variant?.smolId ?? 'vanilla'}: $e',
        ex: e,
        stacktrace: st,
      );
      return;
    }

    if (variant == null) {
      if (gameVersion == null) return;
      final token = myToken;
      unawaited(() async {
        if (_buildToken != token) return;
        await _store.writeVanilla(gameVersion, bytes, _schemaVersion);
      }());
    } else {
      final token = myToken;
      final smolId = variant.smolId;
      unawaited(() async {
        if (_buildToken != token) return;
        await _store.write(smolId, bytes, _schemaVersion);
      }());
    }
  }

  Uint8List _encode(PortraitsCachePayload payload) {
    // Drop `modVariant` from the serialized map — it's a full ModVariant
    // subtree that would bloat the cache file, and the current variant is
    // reattached on decode anyway.
    final portraitMaps = payload.portraits.map((p) {
      final m = p.toMap();
      m.remove('modVariant');
      return m;
    }).toList();
    return msgpack.serialize(<String, dynamic>{'portraits': portraitMaps});
  }

  PortraitsCachePayload? _tryDecode(Uint8List bytes, String keyForLog) {
    try {
      final raw = CachedStreamListNotifier.normalizeForMapper(
        msgpack.deserialize(bytes),
      ) as Map<String, dynamic>;
      final portraitMaps = (raw['portraits'] as List).cast<Map<String, dynamic>>();
      final portraits = <Portrait>[];
      for (final m in portraitMaps) {
        final portrait = PortraitMapper.fromMap(m);
        portrait.modVariant = null;
        portraits.add(portrait);
      }
      return PortraitsCachePayload(portraits: portraits);
    } catch (e, st) {
      Fimber.w(
        '[portraits] decode failed for $keyForLog: $e',
        ex: e,
        stacktrace: st,
      );
      return null;
    }
  }

  Map<ModVariant?, List<Portrait>> _mergeKnownPortraits(
    Map<ModVariant?, List<Portrait>> base,
    Map<ModVariant?, List<Portrait>> additions,
  ) {
    final merged = Map<ModVariant?, List<Portrait>>.from(base);

    for (final entry in additions.entries) {
      final existing = merged[entry.key] ?? const <Portrait>[];
      if (existing.isEmpty) {
        merged[entry.key] = entry.value;
        continue;
      }

      final hashes = existing.map((portrait) => portrait.hash).toSet();
      final combined = <Portrait>[...existing];
      for (final portrait in entry.value) {
        if (hashes.add(portrait.hash)) {
          combined.add(portrait);
        }
      }
      merged[entry.key] = combined;
    }

    return merged;
  }
}
