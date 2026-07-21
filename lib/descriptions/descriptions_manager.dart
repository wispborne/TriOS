import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/descriptions/description_entry.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/utils/logging.dart';

final isLoadingDescriptions = StateProvider<bool>((ref) => false);

final descriptionsNotifierProvider =
    StreamNotifierProvider<
      DescriptionsNotifier,
      Map<(String, String), DescriptionEntry>
    >(DescriptionsNotifier.new);

/// Returns the [DescriptionEntry] for a given `(id, type)` key, or null.
final descriptionProvider =
    Provider.family<DescriptionEntry?, (String, String)>((ref, key) {
      return ref.watch(descriptionsNotifierProvider).valueOrNull?[key];
    });

class DescriptionsNotifier
    extends StreamNotifier<Map<(String, String), DescriptionEntry>> {
  static const _kVanillaKey = kVanillaSourceKey;

  /// Raw `descriptions.csv` rows per source, for `mergeDescriptions`.
  final Map<String, List<Map<String, dynamic>>> _cachedRowsByVariant = {};
  String? _cachedGameCorePath;

  @override
  Stream<Map<(String, String), DescriptionEntry>> build() async* {
    ref.read(isLoadingDescriptions.notifier).state = true;
    final gameCorePath = ref.watch(AppState.gameCoreFolder).value?.path;

    if (gameCorePath == null || gameCorePath.isEmpty) {
      ref.read(isLoadingDescriptions.notifier).state = false;
      return;
    }

    // Watch modVariants so we rebuild once it resolves on startup.
    final modVariantsAsync = ref.watch(AppState.modVariants);
    if (!modVariantsAsync.hasValue) {
      ref.read(isLoadingDescriptions.notifier).state = false;
      return;
    }

    final variants = ref
        .read(AppState.mods)
        .map((mod) => mod.findFirstEnabledOrHighestVersion)
        .nonNulls
        .toList();

    // Invalidate vanilla cache if game path changed.
    if (gameCorePath != _cachedGameCorePath) {
      _cachedRowsByVariant.remove(_kVanillaKey);
      _cachedGameCorePath = gameCorePath;
    }

    // Prune cached entries for variants no longer needed.
    final neededSmolIds = variants.map((v) => v.smolId).toSet();
    _cachedRowsByVariant.removeWhere(
      (key, _) => key != _kVanillaKey && !neededSmolIds.contains(key),
    );

    final allErrors = <String>[];
    const yieldInterval = Duration(milliseconds: 500);
    var lastYieldTime = DateTime.fromMillisecondsSinceEpoch(0);
    final currentTime = DateTime.now();
    int filesParsedFresh = 0;

    // Parse vanilla descriptions if not cached.
    if (!_cachedRowsByVariant.containsKey(_kVanillaKey)) {
      final coreResult = await _parseDescriptionsCsv(
        Directory(gameCorePath),
        null,
      );
      filesParsedFresh += coreResult.filesProcessed;
      _cachedRowsByVariant[_kVanillaKey] = coreResult.rows;
      allErrors.addAll(coreResult.errors);
    }

    // Parse each mod's descriptions if not cached.
    for (final variant in variants) {
      if (_cachedRowsByVariant.containsKey(variant.smolId)) continue;

      final modResult = await _parseDescriptionsCsv(variant.modFolder, variant);
      filesParsedFresh += modResult.filesProcessed;
      _cachedRowsByVariant[variant.smolId] = modResult.rows;
      allErrors.addAll(modResult.errors);

      final now = DateTime.now();
      if (now.difference(lastYieldTime) >= yieldInterval) {
        yield Map.unmodifiable(_composeDescriptions(variants));
        lastYieldTime = now;
      }
    }

    final composed = _composeDescriptions(variants);
    yield Map.unmodifiable(composed);

    if (allErrors.isNotEmpty) {
      Fimber.w('Descriptions parsing errors:\n${allErrors.join('\n')}');
    }

    ref.read(isLoadingDescriptions.notifier).state = false;
    Fimber.i(
      'Descriptions: ${composed.length} entries from '
      '${variants.length + 1} sources ($filesParsedFresh files parsed fresh) '
      'in ${DateTime.now().difference(currentTime).inMilliseconds}ms',
    );
  }

  /// Merges `descriptions.csv` rows across sources. See `mergeDescriptions`.
  Map<(String, String), DescriptionEntry> _composeDescriptions(
    List<ModVariant> variants,
  ) {
    final merged = mergeDescriptions([
      for (final source in orderedSources(variants))
        if (_cachedRowsByVariant[source.key] case final rows?)
          (source: source, items: rows),
    ]);

    return {
      for (final entry in merged)
        (entry.row['id'] as String, entry.row['type'] as String):
            DescriptionEntry(
              id: entry.row['id'] as String,
              type: entry.row['type'] as String,
              text1: entry.row['text1'] as String?,
              text2: entry.row['text2'] as String?,
              text3: entry.row['text3'] as String?,
              text4: entry.row['text4'] as String?,
            ),
    };
  }
}

Future<_DescriptionParseResult> _parseDescriptionsCsv(
  Directory folder,
  ModVariant? modVariant,
) async {
  int filesProcessed = 0;
  final parsedRows = <Map<String, dynamic>>[];
  final errors = <String>[];
  final modName = modVariant?.modInfo.nameOrId ?? kVanillaSourceName;

  final csvFile = p
      .join(folder.path, 'data/strings/descriptions.csv')
      .toFile()
      .normalize
      .toFile();

  if (!await csvFile.exists()) {
    // Missing file is normal for most mods — not an error.
    return _DescriptionParseResult(parsedRows, errors, filesProcessed);
  }

  String content;
  try {
    filesProcessed++;
    content = await csvFile.readAsStringUtf8OrLatin1();
  } on FileSystemException catch (e) {
    errors.add('[$modName] Failed to read $csvFile: $e');
    return _DescriptionParseResult(parsedRows, errors, filesProcessed);
  } catch (e) {
    errors.add('[$modName] Unexpected error reading $csvFile: $e');
    return _DescriptionParseResult(parsedRows, errors, filesProcessed);
  }

  final stripped = content.stripCsvCommentsAndTrackLines();

  final rows = stripped.cleanContent.tryParseCsv(
    fileName: csvFile.path,
    errors: errors,
    modName: modName,
  );

  if (rows.isEmpty) {
    return _DescriptionParseResult(parsedRows, errors, filesProcessed);
  }

  final headers = rows.first.map((e) => e.toString().trim()).toList();

  for (var i = 1; i < rows.length; i++) {
    try {
      final data = rows[i].toTypedCsvMap(headers);
      final id = data['id']?.toString().trim();
      final type = data['type']?.toString().trim();

      // Both key columns are required; skip rows missing either.
      if (id == null || id.isEmpty || type == null || type.isEmpty) continue;

      parsedRows.add({
        'id': id,
        'type': type,
        'text1': data['text1']?.toString(),
        'text2': data['text2']?.toString(),
        'text3': data['text3']?.toString(),
        'text4': data['text4']?.toString(),
      });
    } catch (e) {
      final lineNumber = stripped.lineNumberMap.length > i
          ? stripped.lineNumberMap[i]
          : i;
      errors.add('[$modName] Row $lineNumber in $csvFile: $e');
    }
  }

  return _DescriptionParseResult(parsedRows, errors, filesProcessed);
}

class _DescriptionParseResult {
  final List<Map<String, dynamic>> rows;
  final List<String> errors;
  final int filesProcessed;

  const _DescriptionParseResult(this.rows, this.errors, this.filesProcessed);
}
