import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:path/path.dart' as p;
import 'package:trios/fighter_viewer/models/wing.dart';
import 'package:trios/fighter_viewer/models/wings_cache_payload.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/cached_stream_list_notifier.dart';
import 'package:trios/viewer_cache/cached_variant_store.dart';

final isLoadingWingsList = StateProvider<bool>((ref) => false);

final wingListNotifierProvider =
    StreamNotifierProvider<WingListNotifier, List<Wing>>(
      WingListNotifier.new,
    );

/// Loads fighter wings from `data/hulls/wing_data.csv` in vanilla and each
/// enabled mod. The simplest of the viewer loaders: one CSV per folder, plus a
/// `.variant` lookup to resolve the ship behind each wing.
class WingListNotifier extends CachedStreamListNotifier<Wing, WingsCachePayload> {
  @override
  String get domain => 'wings';

  @override
  int get schemaVersion => 1;

  @override
  late final CachedVariantStore store =
      CachedVariantStore(domain, Constants.viewerCacheDirPath);

  @override
  String itemId(Wing item) => item.id;

  @override
  List<Wing> itemsFromPayload(WingsCachePayload payload) => payload.wings;

  @override
  Directory? get gameCorePath {
    final path = ref.watch(AppState.gameCoreFolder).value?.path;
    return (path == null || path.isEmpty) ? null : Directory(path);
  }

  @override
  String? get currentGameVersion => ref.watch(AppState.starsectorVersion).value;

  @override
  List<ModVariant> resolveEnabledVariants() {
    return ref
        .read(AppState.mods)
        .map((mod) => mod.findFirstEnabledOrHighestVersion)
        .nonNulls
        .toList();
  }

  @override
  Future<bool> awaitReadiness() async {
    return ref.watch(AppState.modVariants).hasValue;
  }

  @override
  void onBuildStart() {
    ref.read(isLoadingWingsList.notifier).state = true;
  }

  @override
  void onBuildComplete({required bool fullScanCompleted}) {
    ref.read(isLoadingWingsList.notifier).state = false;
    super.onBuildComplete(fullScanCompleted: fullScanCompleted);
  }

  @override
  void rehydratePayload(WingsCachePayload payload, ModVariant? sourceVariant) {
    for (final wing in payload.wings) {
      wing.modVariant = sourceVariant;
    }
  }

  @override
  Future<WingsCachePayload?> parseVanilla(
    Directory gameCore,
    List<Wing> allItemsSoFar,
  ) {
    return _parseOneFolder(gameCore, null);
  }

  @override
  Future<WingsCachePayload?> parseVariant(
    ModVariant variant,
    List<Wing> allItemsSoFar,
  ) {
    return _parseOneFolder(variant.modFolder, variant);
  }

  Future<WingsCachePayload?> _parseOneFolder(
    Directory folder,
    ModVariant? modVariant,
  ) async {
    try {
      final result = await _parseWingsCsv(folder, modVariant);
      result.errors.forEach(addError);
      return WingsCachePayload(wings: result.wings);
    } catch (e, st) {
      Fimber.w(
        'Wing parse failed for ${modVariant?.modInfo.nameOrId ?? 'Vanilla'}: $e',
        ex: e,
        stacktrace: st,
      );
      return null;
    }
  }

  @override
  Uint8List encodePayload(WingsCachePayload payload) {
    final map = <String, dynamic>{
      'wings': payload.wings.map((w) {
        final m = w.toMap();
        // hullId is skipped by the mapper (resolved post-parse); persist it
        // manually so a cache-only load keeps the wing → ship link.
        m['hullId'] = w.hullId;
        return m;
      }).toList(),
    };
    return msgpack.serialize(map);
  }

  @override
  WingsCachePayload decodePayload(Uint8List bytes) {
    final raw = CachedStreamListNotifier.normalizeForMapper(
      msgpack.deserialize(bytes),
    ) as Map<String, dynamic>;
    final wingMaps = (raw['wings'] as List).cast<Map<String, dynamic>>();
    final wings = <Wing>[];
    for (final map in wingMaps) {
      final wing = WingMapper.fromMap(map);
      final hullId = map['hullId'];
      if (hullId is String) wing.hullId = hullId;
      wing.modVariant = null;
      wings.add(wing);
    }
    return WingsCachePayload(wings: wings);
  }
}

/// Reads `data/hulls/wing_data.csv` under [folder] and resolves each wing's
/// `variant` to the hull id of the ship behind it.
Future<_WingParseResult> _parseWingsCsv(
  Directory folder,
  ModVariant? modVariant,
) async {
  final wingsCsv = p
      .join(folder.path, 'data/hulls/wing_data.csv')
      .toFile()
      .normalize
      .toFile();

  final wings = <Wing>[];
  final errors = <String>[];
  final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

  if (!await wingsCsv.exists()) {
    // Most mods have no wings; not an error worth surfacing.
    return _WingParseResult(wings, errors);
  }

  // Map every variant id in this folder to its hull id, so a wing's `variant`
  // resolves to the ship behind it. Missing entries degrade to a null hull id.
  final variantHullIds = await _buildVariantHullIdMap(folder);

  String content;
  try {
    content = await wingsCsv.readAsStringUtf8OrLatin1();
  } catch (e) {
    errors.add('[$modName] Failed to read wing_data.csv: $e');
    return _WingParseResult(wings, errors);
  }

  final stripped = content.stripCsvCommentsAndTrackLines();

  List<List<dynamic>> rows;
  try {
    rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(stripped.cleanContent);
  } catch (e) {
    errors.add('[$modName] Failed to parse wing_data.csv: $e');
    return _WingParseResult(wings, errors);
  }

  if (rows.isEmpty) return _WingParseResult(wings, errors);

  final headers = rows.first.map((e) => e.toString()).toList();

  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final data = <String, dynamic>{};
    for (var j = 0; j < headers.length; j++) {
      var value = row.length > j ? row[j] : null;
      if (value is String) {
        if (value.trim().isEmpty) {
          value = null;
        } else {
          final up = value.toUpperCase();
          if (up == 'TRUE') {
            value = true;
          } else if (up == 'FALSE') {
            value = false;
          } else {
            value = num.tryParse(value) ?? value;
          }
        }
      }
      data[headers[j]] = value;
    }

    final wingId = data['id'] as String?;
    if (wingId == null || wingId.isEmpty) continue;

    try {
      final wing = WingMapper.fromMap(data);
      wing.modVariant = modVariant;
      final variantId = wing.variant;
      wing.hullId = variantId == null ? null : variantHullIds[variantId];
      wings.add(wing);
    } catch (e) {
      errors.add('[$modName] Row ${i + 1}: $e');
    }
  }

  return _WingParseResult(wings, errors);
}

/// Scans `data/variants` under [folder] and returns `variantId -> hullId`,
/// following `ShipListNotifier`'s `.variant` parsing.
Future<Map<String, String>> _buildVariantHullIdMap(Directory folder) async {
  final result = <String, String>{};
  final variantsDir = Directory(p.join(folder.path, 'data/variants'));
  if (!await variantsDir.exists()) return result;

  final variantFiles = await variantsDir
      .list(recursive: true)
      .where((e) => e is File && e.path.endsWith('.variant'))
      .cast<File>()
      .toList();

  for (final file in variantFiles) {
    try {
      final raw = await file.readAsString(encoding: utf8);
      final map = await raw.removeJsonComments().parseJsonToMapAsync();
      final variantId = map['variantId'] as String?;
      final hullId = map['hullId'] as String?;
      if (variantId != null && hullId != null) {
        result[variantId] = hullId;
      }
    } catch (_) {
      // Skip unparseable variant files; the wing just won't resolve its ship.
    }
  }
  return result;
}

class _WingParseResult {
  final List<Wing> wings;
  final List<String> errors;

  _WingParseResult(this.wings, this.errors);
}
