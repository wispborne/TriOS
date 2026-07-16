// lib/ship_systems_manager.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/ship_systems_manager/models/ship_systems_cache_payload.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/cached_stream_list_notifier.dart';
import 'package:trios/viewer_cache/cached_variant_store.dart';

final isLoadingShipSystems = StateProvider<bool>((ref) => false);
final isShipSystemsListDirty = StateProvider<bool>((ref) => false);

final shipSystemListNotifierProvider =
    StreamNotifierProvider<ShipSystemListNotifier, List<ShipSystem>>(
      ShipSystemListNotifier.new,
    );

class ShipSystemListNotifier
    extends CachedStreamListNotifier<ShipSystem, ShipSystemsCachePayload> {
  @override
  String get domain => 'ship_systems';

  @override
  int get schemaVersion => 1;

  @override
  late final CachedVariantStore store =
      CachedVariantStore(domain, Constants.viewerCacheDirPath);

  @override
  String itemId(ShipSystem item) => item.id;

  @override
  List<ShipSystem> itemsFromPayload(ShipSystemsCachePayload payload) =>
      payload.systems;

  /// A system's `icon` path can point at an asset that lives in another
  /// folder — most often a vanilla icon (e.g. Blackrock's Plasma Injector
  /// reuses the core `burn_drive.png`). The game resolves such paths across
  /// the merged file system, so we search core and every enabled mod folder
  /// as fallbacks. Set by `parseVanilla`, which always runs first in a scan.
  List<Directory> _assetRoots = const [];

  @override
  Directory? get gameCorePath {
    final path = ref.watch(AppState.gameCoreFolder).value?.path;
    return (path == null || path.isEmpty) ? null : Directory(path);
  }

  @override
  String? get currentGameVersion => ref.watch(AppState.starsectorVersion).value;

  @override
  Future<bool> awaitReadiness() async {
    return ref.watch(AppState.modVariants).hasValue;
  }

  @override
  void onBuildStart() {
    ref.read(isLoadingShipSystems.notifier).state = true;
    ref.listen(AppState.smolIds, (previous, next) {
      ref.read(isShipSystemsListDirty.notifier).state = true;
    });
  }

  @override
  void onBuildComplete({required bool fullScanCompleted}) {
    ref.read(isLoadingShipSystems.notifier).state = false;
    if (fullScanCompleted) {
      ref.read(isShipSystemsListDirty.notifier).state = false;
    }
    super.onBuildComplete(fullScanCompleted: fullScanCompleted);
  }

  @override
  void rehydratePayload(
    ShipSystemsCachePayload payload,
    ModVariant? sourceVariant,
  ) {
    for (final system in payload.systems) {
      system.modVariant = sourceVariant;
    }
  }

  @override
  Future<ShipSystemsCachePayload?> parseVanilla(
    Directory gameCore,
    List<ShipSystem> allItemsSoFar,
  ) {
    _assetRoots = [
      gameCore,
      for (final variant in resolveEnabledVariants()) variant.modFolder,
    ];
    return _parseOneFolder(gameCore, null);
  }

  @override
  Future<ShipSystemsCachePayload?> parseVariant(
    ModVariant variant,
    List<ShipSystem> allItemsSoFar,
  ) {
    return _parseOneFolder(variant.modFolder, variant);
  }

  Future<ShipSystemsCachePayload?> _parseOneFolder(
    Directory folder,
    ModVariant? modVariant,
  ) async {
    try {
      final result = await _parseShipSystems(folder, modVariant, _assetRoots);
      result.errors.forEach(addError);
      return ShipSystemsCachePayload(systems: result.systems);
    } catch (e, st) {
      Fimber.w(
        'Ship system parse failed for ${modVariant?.modInfo.nameOrId ?? 'Vanilla'}: $e',
        ex: e,
        stacktrace: st,
      );
      return null;
    }
  }

  @override
  Uint8List encodePayload(ShipSystemsCachePayload payload) {
    final map = <String, dynamic>{
      'systems': payload.systems.map((s) => s.toMap()).toList(),
    };
    return msgpack.serialize(map);
  }

  @override
  ShipSystemsCachePayload decodePayload(Uint8List bytes) {
    final raw = CachedStreamListNotifier.normalizeForMapper(
      msgpack.deserialize(bytes),
    ) as Map<String, dynamic>;
    final systemMaps = (raw['systems'] as List).cast<Map<String, dynamic>>();
    final systems = <ShipSystem>[];
    for (final map in systemMaps) {
      final system = ShipSystemMapper.fromMap(map);
      system.modVariant = null; // reattached by rehydratePayload.
      systems.add(system);
    }
    return ShipSystemsCachePayload(systems: systems);
  }
}

/// Reads and parses `data/ship_systems.csv` under [folder], returning
/// a list of [ShipSystem]s along with parse errors and file count.
Future<_SystemParseResult> _parseShipSystems(
  Directory folder,
  ModVariant? modVariant,
  List<Directory> assetRoots,
) async {
  int filesProcessed = 0;
  final systemsCsv = p
      .join(folder.path, 'data/shipsystems/ship_systems.csv')
      .toFile()
      .normalize
      .toFile();
  final systems = <ShipSystem>[];
  final errors = <String>[];
  final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

  if (!await systemsCsv.exists()) {
    // Most mods don't add ship systems; a missing file isn't an error.
    return _SystemParseResult(systems, errors, filesProcessed);
  }

  String content;
  try {
    filesProcessed++;
    content = await systemsCsv.readAsStringUtf8OrLatin1();
  } catch (e) {
    errors.add('[$modName] Failed to read ship_systems.csv: $e');
    return _SystemParseResult(systems, errors, filesProcessed);
  }

  // Strip `#` comments (quote-aware, multi-line safe).
  final stripped = content.stripCsvCommentsAndTrackLines();

  List<List<dynamic>> rows;
  try {
    rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(stripped.cleanContent);
  } catch (e) {
    errors.add('[$modName] Failed to parse CSV: $e');
    return _SystemParseResult(systems, errors, filesProcessed);
  }

  if (rows.isEmpty) {
    errors.add('[$modName] Empty ship_systems.csv');
    return _SystemParseResult(systems, errors, filesProcessed);
  }

  final headers = rows.first.map((e) => e.toString()).toList();

  for (var i = 1; i < rows.length; i++) {
    final data = rows[i].toTypedCsvMap(headers);
    final id = data['id']?.toString().trim();
    if (id == null || id.isEmpty) continue;

    // The `icon` column is a folder-relative path. Resolve it to an absolute
    // file path so the UI can load it directly. The defining folder wins if it
    // ships the asset (a mod override); otherwise fall back to core and other
    // mods, mirroring the game's merged file system.
    final iconRel = data['icon']?.toString().trim();
    if (iconRel != null && iconRel.isNotEmpty) {
      data['icon'] = _resolveAssetPath(iconRel, folder, assetRoots);
    }

    try {
      final sys = ShipSystemMapper.fromMap(data);
      sys.modVariant = modVariant;
      systems.add(sys);
    } catch (e, st) {
      errors.add('[$modName] Row ${i + 1}: $e');
      Fimber.w(
        '[$modName] Mapping error row ${i + 1}: $e',
        ex: e,
        stacktrace: st,
      );
    }
  }

  return _SystemParseResult(systems, errors, filesProcessed);
}

/// Resolves an asset [rel] path to an absolute file. Prefers [ownFolder] (the
/// mod or core that defines the system), then searches [assetRoots] (core plus
/// every enabled mod). Returns the own-folder path if nothing exists, so the
/// UI's missing-file handling still kicks in.
String _resolveAssetPath(
  String rel,
  Directory ownFolder,
  List<Directory> assetRoots,
) {
  final own = p.join(ownFolder.path, rel).toFile().normalize;
  if (own.existsSync()) return own.path;
  for (final root in assetRoots) {
    if (root.path == ownFolder.path) continue;
    final candidate = p.join(root.path, rel).toFile().normalize;
    if (candidate.existsSync()) return candidate.path;
  }
  return own.path;
}

class _SystemParseResult {
  final List<ShipSystem> systems;
  final List<String> errors;
  final int filesProcessed;

  _SystemParseResult(this.systems, this.errors, this.filesProcessed);
}
