import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
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
import 'package:trios/viewer_cache/parse_recorder.dart';

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
  // Version 3 caches variant weapons, hull mods, and display names.
  int get schemaVersion => 3;

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
    ParseRecorder recorder,
  ) {
    return _parseOneFolder(gameCore, null, recorder);
  }

  @override
  Future<WingsCachePayload?> parseVariant(
    ModVariant variant,
    List<Wing> allItemsSoFar,
    ParseRecorder recorder,
  ) {
    return _parseOneFolder(variant.modFolder, variant, recorder);
  }

  Future<WingsCachePayload?> _parseOneFolder(
    Directory folder,
    ModVariant? modVariant,
    ParseRecorder recorder,
  ) async {
    try {
      final result = await _parseWingsCsv(folder, modVariant, recorder);
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
        // The fields read from the `.variant` file are skipped by the mapper
        // (resolved post-parse); persist them manually so a cache-only load
        // keeps them.
        m['hullId'] = w.hullId;
        m['weaponsBySlot'] = w.weaponsBySlot;
        m['variantHullMods'] = w.variantHullMods;
        m['variantDisplayName'] = w.variantDisplayName;
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
      final weaponsBySlot = map['weaponsBySlot'];
      if (weaponsBySlot is Map) {
        wing.weaponsBySlot = Map<String, String>.from(weaponsBySlot);
      }
      final variantHullMods = map['variantHullMods'];
      if (variantHullMods is List) {
        wing.variantHullMods = variantHullMods.whereType<String>().toList();
      }
      final variantDisplayName = map['variantDisplayName'];
      if (variantDisplayName is String) {
        wing.variantDisplayName = variantDisplayName;
      }
      wing.modVariant = null;
      wings.add(wing);
    }
    return WingsCachePayload(wings: wings);
  }
}

/// Reads `data/hulls/wing_data.csv` under [folder] and resolves each wing's
/// `variant` to the ship behind it and what the variant fits.
Future<_WingParseResult> _parseWingsCsv(
  Directory folder,
  ModVariant? modVariant,
  ParseRecorder recorder,
) async {
  final wingsCsv = p
      .join(folder.path, 'data/hulls/wing_data.csv')
      .toFile()
      .normalize
      .toFile();

  final wings = <Wing>[];
  final errors = <String>[];
  final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

  // The parse only looks for one file, but a mod without it still gets a
  // payload (an empty one) and so needs a fingerprint to be skippable. The
  // folder listing stands in for the existence check: the CSV appearing later
  // changes the listing.
  final hullsDir = wingsCsv.parent;
  recorder.directory(
    hullsDir,
    hullsDir.existsSync() ? hullsDir.listSync() : const [],
  );

  if (!await wingsCsv.exists()) {
    // Most mods have no wings; not an error worth surfacing.
    return _WingParseResult(wings, errors);
  }
  recorder.file(wingsCsv);

  // Missing variants leave the wing's hull and fitted data empty.
  final variants = await _buildVariantMap(folder, recorder);

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
      final variant = variants[wing.variant];
      wing.hullId = variant?.hullId;
      wing.weaponsBySlot = variant?.weaponsBySlot ?? const {};
      wing.variantHullMods = variant?.hullMods ?? const [];
      wing.variantDisplayName = variant?.displayName;
      wings.add(wing);
    } catch (e) {
      errors.add('[$modName] Row ${i + 1}: $e');
    }
  }

  return _WingParseResult(wings, errors);
}

/// Scans `data/variants` under [folder] and returns `variantId -> variant`,
/// following `ShipListNotifier`'s `.variant` parsing.
Future<Map<String, _WingVariant>> _buildVariantMap(
  Directory folder,
  ParseRecorder recorder,
) async {
  final result = <String, _WingVariant>{};
  final variantsDir = Directory(p.join(folder.path, 'data/variants'));
  if (!await variantsDir.exists()) {
    recorder.directory(variantsDir, const [], recursive: true);
    return result;
  }

  final allEntries = await variantsDir.list(recursive: true).toList();
  recorder.directory(variantsDir, allEntries, recursive: true);
  final variantFiles = allEntries
      .whereType<File>()
      .where((f) => f.path.endsWith('.variant'))
      .toList();

  for (final file in variantFiles) {
    try {
      recorder.file(file);
      final raw = await file.readAsString(encoding: utf8);
      final map = await raw.parseJsonToMapAsync();
      final variantId = map['variantId'] as String?;
      final hullId = map['hullId'] as String?;
      if (variantId != null && hullId != null) {
        final hullMods = map['hullMods'];
        final displayName = map['displayName'];
        result[variantId] = _WingVariant(
          hullId: hullId,
          weaponsBySlot: weaponsBySlotFromVariant(map),
          hullMods: hullMods is List
              ? hullMods.whereType<String>().toList()
              : const [],
          displayName: displayName is String ? displayName : null,
        );
      }
    } catch (_) {
      // Skip unparseable variant files; the wing just won't resolve its ship.
    }
  }
  return result;
}

/// Reads the fitted weapons out of a parsed `.variant` file, as
/// slot id -> weapon id. Built-in weapons live on the hull, not here.
Map<String, String> weaponsBySlotFromVariant(Map<String, dynamic> variant) {
  final result = <String, String>{};
  final groups = variant['weaponGroups'];
  if (groups is! List) return result;
  for (final group in groups) {
    if (group is! Map) continue;
    final weapons = group['weapons'];
    if (weapons is! Map) continue;
    for (final entry in weapons.entries) {
      final slotId = entry.key;
      final weaponId = entry.value;
      if (slotId is String && weaponId is String && weaponId.isNotEmpty) {
        result[slotId] = weaponId;
      }
    }
  }
  return result;
}

class _WingVariant {
  final String hullId;
  final Map<String, String> weaponsBySlot;
  final List<String> hullMods;
  final String? displayName;

  _WingVariant({
    required this.hullId,
    required this.weaponsBySlot,
    required this.hullMods,
    required this.displayName,
  });
}

class _WingParseResult {
  final List<Wing> wings;
  final List<String> errors;

  _WingParseResult(this.wings, this.errors);
}
