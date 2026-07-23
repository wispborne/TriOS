import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/utils/game_file_resolver.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/cached_stream_list_notifier.dart';
import 'package:trios/viewer_cache/cached_variant_store.dart';

/// Image file extensions worth indexing. Everything else under `graphics/`
/// (fonts, stray text files) is skipped.
const _imageExtensions = {'.png', '.jpg', '.jpeg'};

/// The image files one source ships under its `graphics/` folder.
class GraphicsIndexPayload {
  /// The source this came from (a smolId, or `__vanilla__` for vanilla).
  final String sourceKey;

  /// Absolute path to the mod folder (or the game core folder). Not cached —
  /// it's reattached on load, so a moved game or mod folder can't go stale.
  String folderPath;

  /// Paths relative to [folderPath], forward slashes, spelled as on disk.
  final List<String> imageFiles;

  GraphicsIndexPayload({
    required this.sourceKey,
    required this.folderPath,
    required this.imageFiles,
  });

  /// This source as the resolver wants it. Built on first use, because
  /// lowercasing every path for every mod is wasted work until something asks.
  late final GameFileSource asSource = GameFileSource(
    folderPath: folderPath,
    imageFiles: {for (final path in imageFiles) path.toLowerCase(): path},
  );
}

/// The raw scan: one entry per source, listing the images that source ships.
/// Read [gameFileResolverProvider] to actually look a path up.
final graphicsIndexProvider =
    StreamNotifierProvider<GraphicsIndexNotifier, List<GraphicsIndexPayload>>(
      GraphicsIndexNotifier.new,
    );

/// Finds images the way the game does — every mod in load order, then the game
/// core. Rebuilt when the index or the mod list changes.
///
/// With [onlyEnabledMods] on, mods without an enabled variant are left out, so
/// a disabled mod can't replace a sprite it wouldn't replace in the game.
final gameFileResolverProvider = Provider.family<GameFileResolver, bool>((
  ref,
  onlyEnabledMods,
) {
  final payloads = ref.watch(graphicsIndexProvider).valueOrNull ?? const [];
  final mods = ref.watch(AppState.mods);
  final variants = mods
      .map((mod) => mod.findFirstEnabledOrHighestVersion)
      .nonNulls
      .where(
        (variant) =>
            !onlyEnabledMods || variant.mod(mods)?.hasEnabledVariant == true,
      );

  final bySourceKey = {for (final payload in payloads) payload.sourceKey: payload};
  return GameFileResolver([
    for (final source in orderedSources(variants))
      if (bySourceKey[source.key] case final payload?) payload.asSource,
  ]);
});

/// Walks every source's `graphics/` folder and remembers what it found, so the
/// viewers can resolve sprite paths without touching the disk.
class GraphicsIndexNotifier
    extends
        CachedStreamListNotifier<GraphicsIndexPayload, GraphicsIndexPayload> {
  @override
  String get domain => 'graphics_index';

  @override
  int get schemaVersion => 1;

  @override
  late final CachedVariantStore store = CachedVariantStore(
    domain,
    Constants.viewerCacheDirPath,
  );

  /// Longer interval because every yield rebuilds the resolver, and with it
  /// the ships and weapons lists.
  @override
  Duration get progressiveYieldInterval => const Duration(seconds: 3);

  /// One payload per source; nothing is merged during the scan.
  @override
  String itemId(GraphicsIndexPayload item) => item.sourceKey;

  @override
  List<GraphicsIndexPayload> itemsFromPayload(GraphicsIndexPayload payload) => [
    payload,
  ];

  @override
  Directory? get gameCorePath {
    final path = ref.watch(AppState.gameCoreFolder).value?.path;
    return (path == null || path.isEmpty) ? null : Directory(path);
  }

  @override
  String? get currentGameVersion => ref.watch(AppState.starsectorVersion).value;

  @override
  Future<bool> awaitReadiness() async {
    // Watch modVariants so this rebuilds once the initial scan resolves.
    return ref.watch(AppState.modVariants).hasValue;
  }

  @override
  void rehydratePayload(
    GraphicsIndexPayload payload,
    ModVariant? sourceVariant,
  ) {
    final folder = sourceVariant?.modFolder.path ?? gameCorePath?.path;
    if (folder != null) payload.folderPath = folder;
  }

  @override
  Future<GraphicsIndexPayload?> parseVanilla(
    Directory gameCore,
    List<GraphicsIndexPayload> allItemsSoFar,
  ) => _indexOneFolder(gameCore, kVanillaSourceKey);

  @override
  Future<GraphicsIndexPayload?> parseVariant(
    ModVariant variant,
    List<GraphicsIndexPayload> allItemsSoFar,
  ) => _indexOneFolder(variant.modFolder, variant.smolId);

  Future<GraphicsIndexPayload?> _indexOneFolder(
    Directory folder,
    String sourceKey,
  ) async {
    final graphicsDir = Directory(p.join(folder.path, 'graphics'));
    if (!await graphicsDir.exists()) return null;

    final imageFiles = <String>[];
    try {
      await for (final entry in graphicsDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entry is! File) continue;
        if (!_imageExtensions.contains(p.extension(entry.path).toLowerCase())) {
          continue;
        }
        imageFiles.add(
          p.relative(entry.path, from: folder.path).replaceAll('\\', '/'),
        );
      }
    } catch (e, st) {
      Fimber.w(
        'Could not list ${graphicsDir.path}: $e',
        ex: e,
        stacktrace: st,
      );
      return null;
    }

    if (imageFiles.isEmpty) return null;
    return GraphicsIndexPayload(
      sourceKey: sourceKey,
      folderPath: folder.path,
      imageFiles: imageFiles,
    );
  }

  @override
  Uint8List encodePayload(GraphicsIndexPayload payload) {
    return msgpack.serialize(<String, dynamic>{
      'sourceKey': payload.sourceKey,
      'imageFiles': payload.imageFiles,
    });
  }

  @override
  GraphicsIndexPayload decodePayload(Uint8List bytes) {
    final raw = CachedStreamListNotifier.normalizeForMapper(
      msgpack.deserialize(bytes),
    ) as Map<String, dynamic>;

    return GraphicsIndexPayload(
      sourceKey: raw['sourceKey'] as String,
      // Replaced in rehydratePayload, which knows the folder for this source.
      folderPath: '',
      imageFiles: (raw['imageFiles'] as List).cast<String>(),
    );
  }
}
