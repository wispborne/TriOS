import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:path/path.dart' as p;
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/hullmod_viewer/models/hullmods_cache_payload.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/cached_stream_list_notifier.dart';
import 'package:trios/viewer_cache/cached_variant_store.dart';

final isLoadingHullmodsList = StateProvider<bool>((ref) => false);
final isHullmodsListDirty = StateProvider<bool>((ref) => false);

final hullmodListNotifierProvider =
    StreamNotifierProvider<HullmodListNotifier, List<Hullmod>>(
      HullmodListNotifier.new,
    );

class HullmodListNotifier
    extends CachedStreamListNotifier<Hullmod, HullmodsCachePayload> {
  @override
  String get domain => 'hullmods';

  @override
  int get schemaVersion => 1;

  @override
  late final CachedVariantStore store =
      CachedVariantStore(domain, Constants.viewerCacheDirPath);

  @override
  String itemId(Hullmod item) => item.id;

  @override
  List<Hullmod> itemsFromPayload(HullmodsCachePayload payload) =>
      payload.hullmods;

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
    ref.read(isLoadingHullmodsList.notifier).state = true;
    ref.listen(AppState.smolIds, (previous, next) {
      ref.read(isHullmodsListDirty.notifier).state = true;
    });
  }

  @override
  void onBuildComplete({required bool fullScanCompleted}) {
    ref.read(isLoadingHullmodsList.notifier).state = false;
    if (fullScanCompleted) {
      ref.read(isHullmodsListDirty.notifier).state = false;
    }
    super.onBuildComplete(fullScanCompleted: fullScanCompleted);
  }

  @override
  void rehydratePayload(
    HullmodsCachePayload payload,
    ModVariant? sourceVariant,
  ) {
    for (final hullmod in payload.hullmods) {
      hullmod.modVariant = sourceVariant;
    }
  }

  @override
  Future<HullmodsCachePayload?> parseVanilla(
    Directory gameCore,
    List<Hullmod> allItemsSoFar,
  ) {
    return _parseOneFolder(gameCore, null);
  }

  @override
  Future<HullmodsCachePayload?> parseVariant(
    ModVariant variant,
    List<Hullmod> allItemsSoFar,
  ) {
    return _parseOneFolder(variant.modFolder, variant);
  }

  Future<HullmodsCachePayload?> _parseOneFolder(
    Directory folder,
    ModVariant? modVariant,
  ) async {
    try {
      final result = await _parseHullmodsCsv(folder, modVariant);
      result.errors.forEach(addError);
      result.infos.forEach(addInfo);
      return HullmodsCachePayload(hullmods: result.hullmods);
    } catch (e, st) {
      Fimber.w(
        'Hullmod parse failed for ${modVariant?.modInfo.nameOrId ?? 'Vanilla'}: $e',
        ex: e,
        stacktrace: st,
      );
      return null;
    }
  }

  @override
  Uint8List encodePayload(HullmodsCachePayload payload) {
    final map = <String, dynamic>{
      'hullmods': payload.hullmods.map((h) => h.toMap()).toList(),
    };
    return msgpack.serialize(map);
  }

  @override
  HullmodsCachePayload decodePayload(Uint8List bytes) {
    final raw = CachedStreamListNotifier.normalizeForMapper(
      msgpack.deserialize(bytes),
    ) as Map<String, dynamic>;
    final hullmodMaps = (raw['hullmods'] as List).cast<Map<String, dynamic>>();
    final hullmods = <Hullmod>[];
    for (final map in hullmodMaps) {
      final hullmod = HullmodMapper.fromMap(map);
      final csvPath = map['csvFile'];
      if (csvPath is String) hullmod.csvFile = File(csvPath);
      hullmod.modVariant = null;
      hullmods.add(hullmod);
    }
    return HullmodsCachePayload(hullmods: hullmods);
  }

  String allHullmodsAsCsv() {
    final allHullmods = state.value ?? [];

    final hullmodFields = allHullmods.isNotEmpty
        ? allHullmods.first.toMap().keys.toList()
        : [];
    List<List<dynamic>> rows = [hullmodFields];

    if (allHullmods.isNotEmpty) {
      rows.addAll(
        allHullmods.map((hullmod) => hullmod.toMap().values.toList()).toList(),
      );
    }

    final csvContent = const ListToCsvConverter(
      convertNullTo: "",
    ).convert(rows);

    return csvContent;
  }
}

Future<HullmodParseResult> _parseHullmodsCsv(
  Directory folder,
  ModVariant? modVariant,
) async {
  int filesProcessed = 0;

  final hullmodsCsvFile = p
      .join(folder.path, 'data/hullmods/hull_mods.csv')
      .toFile()
      .normalize
      .toFile();

  final hullmods = <Hullmod>[];
  final errors = <String>[];
  final infos = <String>[];
  final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

  if (!await hullmodsCsvFile.exists()) {
    infos.add('[$modName] Hullmods CSV file not found at $hullmodsCsvFile');
    return HullmodParseResult(hullmods, errors, infos, filesProcessed);
  }

  String content;
  try {
    filesProcessed++;
    content = await hullmodsCsvFile.readAsStringUtf8OrLatin1();
  } on FileSystemException catch (e) {
    errors.add('[$modName] Failed to read file at $hullmodsCsvFile: $e');
    return HullmodParseResult(hullmods, errors, infos, filesProcessed);
  } catch (e) {
    errors.add(
      '[$modName] Unexpected error reading file at $hullmodsCsvFile: $e',
    );
    return HullmodParseResult(hullmods, errors, infos, filesProcessed);
  }

  // Strip `#` comments (quote-aware, multi-line safe) and track source lines.
  final stripped = content.stripCsvCommentsAndTrackLines();
  final processedContent = stripped.cleanContent;
  final lineNumberMapping = stripped.lineNumberMap;

  List<List<dynamic>> rows;
  try {
    rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(processedContent);
  } catch (e) {
    errors.add(
      '[$modName] Failed to parse CSV content in file $hullmodsCsvFile: $e',
    );
    return HullmodParseResult(hullmods, errors, infos, filesProcessed);
  }

  if (rows.isEmpty) {
    errors.add('[$modName] Empty hullmods CSV file at $hullmodsCsvFile');
    return HullmodParseResult(hullmods, errors, infos, filesProcessed);
  }

  // Extract headers from the first row
  final headers = rows.first
      .map((e) => e.toString().trim().toLowerCase())
      .toList();

  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final Map<String, dynamic> hullmodData = {};

    for (var j = 0; j < headers.length; j++) {
      final key = headers[j];
      dynamic value = row.length > j ? row[j] : null;

      if (value == null || (value is String && value.trim().isEmpty)) {
        hullmodData[key] = null;
        continue;
      }

      if (value.toString().toUpperCase() == 'TRUE') {
        value = true;
      } else if (value.toString().toUpperCase() == 'FALSE') {
        value = false;
      } else {
        final numValue = num.tryParse(value.toString());
        value = numValue ?? value.toString();
      }

      hullmodData[key] = value;
    }

    try {
      final hullmodId = hullmodData['id'] as String?;
      if (hullmodId == null || hullmodId.isEmpty) {
        continue;
      }

      // Resolve sprite path relative to mod/game folder
      final spritePath = hullmodData['sprite'] as String?;
      if (spritePath != null && spritePath.isNotEmpty) {
        hullmodData['sprite'] = p
            .join(folder.path, spritePath)
            .toFile()
            .normalize
            .path;
      }

      // Create Hullmod instance
      final hullmod = HullmodMapper.fromMap(hullmodData)
        ..modVariant = modVariant
        ..csvFile = hullmodsCsvFile;
      hullmods.add(hullmod);
    } catch (e) {
      final lineNumber = lineNumberMapping[i];
      errors.add('[$modName] Row $lineNumber: $e');
    }
  }

  return HullmodParseResult(hullmods, errors, infos, filesProcessed);
}

class HullmodParseResult {
  final List<Hullmod> hullmods;
  final List<String> errors;
  final List<String> infos;
  final int filesProcessed;

  HullmodParseResult(
    this.hullmods,
    this.errors,
    this.infos,
    this.filesProcessed,
  );
}
