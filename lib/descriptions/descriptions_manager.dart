import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/descriptions/description_entry.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
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

    final allErrors = <String>[];
    var allDescriptions = <(String, String), DescriptionEntry>{};
    const yieldInterval = Duration(milliseconds: 500);
    var lastYieldTime = DateTime.fromMillisecondsSinceEpoch(0);
    final currentTime = DateTime.now();
    int filesProcessed = 0;

    // Parse vanilla descriptions.
    final coreResult = await _parseDescriptionsCsv(
      Directory(gameCorePath),
      null,
    );
    filesProcessed += coreResult.filesProcessed;
    allDescriptions.addAll(coreResult.descriptions);
    allErrors.addAll(coreResult.errors);

    // Parse each mod's descriptions.
    for (final variant in variants) {
      final modResult = await _parseDescriptionsCsv(variant.modFolder, variant);
      filesProcessed += modResult.filesProcessed;
      allDescriptions.addAll(modResult.descriptions);
      allErrors.addAll(modResult.errors);

      final now = DateTime.now();
      if (now.difference(lastYieldTime) >= yieldInterval) {
        yield Map.unmodifiable(allDescriptions);
        lastYieldTime = now;
      }
    }

    yield Map.unmodifiable(allDescriptions);

    if (allErrors.isNotEmpty) {
      Fimber.w('Descriptions parsing errors:\n${allErrors.join('\n')}');
    }

    ref.read(isLoadingDescriptions.notifier).state = false;
    Fimber.i(
      'Parsed ${allDescriptions.length} descriptions from '
      '${variants.length + 1} sources and $filesProcessed files in '
      '${DateTime.now().difference(currentTime).inMilliseconds}ms',
    );
  }
}

Future<_DescriptionParseResult> _parseDescriptionsCsv(
  Directory folder,
  ModVariant? modVariant,
) async {
  int filesProcessed = 0;
  final descriptions = <(String, String), DescriptionEntry>{};
  final errors = <String>[];
  final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

  final csvFile = p
      .join(folder.path, 'data/strings/descriptions.csv')
      .toFile()
      .normalize
      .toFile();

  if (!await csvFile.exists()) {
    // Missing file is normal for most mods — not an error.
    return _DescriptionParseResult(descriptions, errors, filesProcessed);
  }

  String content;
  try {
    filesProcessed++;
    content = await csvFile.readAsStringAllowMalformed();
  } on FileSystemException catch (e) {
    errors.add('[$modName] Failed to read $csvFile: $e');
    return _DescriptionParseResult(descriptions, errors, filesProcessed);
  } catch (e) {
    errors.add('[$modName] Unexpected error reading $csvFile: $e');
    return _DescriptionParseResult(descriptions, errors, filesProcessed);
  }

  final stripped = content.stripCsvCommentsAndTrackLines();

  final rows = stripped.cleanContent.tryParseCsv(
    fileName: csvFile.path,
    errors: errors,
    modName: modName,
  );

  if (rows.isEmpty) {
    return _DescriptionParseResult(descriptions, errors, filesProcessed);
  }

  final headers = rows.first.map((e) => e.toString().trim()).toList();

  for (var i = 1; i < rows.length; i++) {
    try {
      final data = rows[i].toTypedCsvMap(headers);
      final id = data['id']?.toString().trim();
      final type = data['type']?.toString().trim();

      if (id == null || id.isEmpty || type == null || type.isEmpty) continue;

      descriptions[(id, type)] = DescriptionEntry(
        id: id,
        type: type,
        text1: data['text1']?.toString(),
        text2: data['text2']?.toString(),
        text3: data['text3']?.toString(),
        text4: data['text4']?.toString(),
      );
    } catch (e) {
      final lineNumber = stripped.lineNumberMap.length > i
          ? stripped.lineNumberMap[i]
          : i;
      errors.add('[$modName] Row $lineNumber in $csvFile: $e');
    }
  }

  return _DescriptionParseResult(descriptions, errors, filesProcessed);
}

class _DescriptionParseResult {
  final Map<(String, String), DescriptionEntry> descriptions;
  final List<String> errors;
  final int filesProcessed;

  const _DescriptionParseResult(
    this.descriptions,
    this.errors,
    this.filesProcessed,
  );
}
