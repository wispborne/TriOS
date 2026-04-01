import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/hullmodViewer/models/hullmod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

final isLoadingHullmodsList = StateProvider<bool>((ref) => false);
final isHullmodsListDirty = StateProvider<bool>((ref) => false);

final hullmodListNotifierProvider =
    StreamNotifierProvider<HullmodListNotifier, List<Hullmod>>(
      HullmodListNotifier.new,
    );

class HullmodListNotifier extends StreamNotifier<List<Hullmod>> {
  @override
  Stream<List<Hullmod>> build() async* {
    int filesProcessed = 0;

    final currentTime = DateTime.now();
    ref.read(isLoadingHullmodsList.notifier).state = true;
    filesProcessed = 0;
    final gameCorePath = ref.watch(AppState.gameCoreFolder).value?.path;

    if (gameCorePath == null || gameCorePath.isEmpty) {
      ref.read(isLoadingHullmodsList.notifier).state = false;
      return;
    }

    // Watch modVariants so we rebuild once it resolves on startup.
    final modVariantsAsync = ref.watch(AppState.modVariants);
    if (!modVariantsAsync.hasValue) {
      ref.read(isLoadingHullmodsList.notifier).state = false;
      return;
    }

    ref.listen(AppState.smolIds, (previous, next) {
      ref.read(isHullmodsListDirty.notifier).state = true;
    });

    // Don't watch for mod changes, the background processing is too expensive.
    // User has to manually refresh hullmods viewer.
    final variants = ref
        .read(AppState.mods)
        .map((mod) => mod.findFirstEnabledOrHighestVersion)
        .nonNulls
        .toList();

    final allErrors = <String>[];
    List<Hullmod> allHullmods = <Hullmod>[];
    const yieldInterval = Duration(milliseconds: 500);
    var lastYieldTime = DateTime.fromMillisecondsSinceEpoch(0);

    // Parse the core game hullmods
    final coreResult = await _parseHullmodsCsv(Directory(gameCorePath), null);
    filesProcessed += coreResult.filesProcessed;
    allHullmods.addAll(coreResult.hullmods);
    allHullmods = allHullmods.distinctBy((e) => e.id).toList();

    if (coreResult.errors.isNotEmpty) {
      allErrors.addAll(coreResult.errors);
    }

    // Parse each mod's hullmods individually
    for (final variant in variants) {
      final modResult = await _parseHullmodsCsv(variant.modFolder, variant);
      filesProcessed += modResult.filesProcessed;
      allHullmods.addAll(modResult.hullmods);
      allHullmods = allHullmods.distinctBy((e) => e.id).toList();

      if (modResult.errors.isNotEmpty) {
        allErrors.addAll(modResult.errors);
      }

      final now = DateTime.now();
      if (now.difference(lastYieldTime) >= yieldInterval) {
        yield allHullmods;
        lastYieldTime = now;
      }
    }

    // Always yield the final complete list.
    yield allHullmods;

    if (allErrors.isNotEmpty) {
      Fimber.w('Errors encountered during parsing:\n${allErrors.join('\n')}');
    }

    ref.read(isLoadingHullmodsList.notifier).state = false;
    ref.read(isHullmodsListDirty.notifier).state = false;
    Fimber.i(
      'Parsed ${allHullmods.length} hullmods from ${variants.length + 1} mods and $filesProcessed files in ${DateTime.now().difference(currentTime).inMilliseconds}ms',
    );
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
  final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

  if (!await hullmodsCsvFile.exists()) {
    errors.add('[$modName] Hullmods CSV file not found at $hullmodsCsvFile');
    return HullmodParseResult(hullmods, errors, filesProcessed);
  }

  String content;
  try {
    filesProcessed++;
    content = await hullmodsCsvFile.readAsString(encoding: utf8);
  } on FileSystemException catch (e) {
    errors.add('[$modName] Failed to read file at $hullmodsCsvFile: $e');
    return HullmodParseResult(hullmods, errors, filesProcessed);
  } catch (e) {
    errors.add(
      '[$modName] Unexpected error reading file at $hullmodsCsvFile: $e',
    );
    return HullmodParseResult(hullmods, errors, filesProcessed);
  }

  // Preprocess the content to handle comments
  final lines = content.split('\n');
  final processedLines = <String>[];
  final lineNumberMapping = <int>[];

  for (int index = 0; index < lines.length; index++) {
    String line = lines[index];
    String processedLine = line.removeCsvLineComments();

    if (processedLine.trim().isEmpty) {
      continue;
    }

    processedLines.add(processedLine);
    lineNumberMapping.add(index + 1);
  }

  final processedContent = processedLines.join('\n');

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
    return HullmodParseResult(hullmods, errors, filesProcessed);
  }

  if (rows.isEmpty) {
    errors.add('[$modName] Empty hullmods CSV file at $hullmodsCsvFile');
    return HullmodParseResult(hullmods, errors, filesProcessed);
  }

  // Extract headers from the first row
  final headers = rows.first.map((e) => e.toString().trim()).toList();

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

  return HullmodParseResult(hullmods, errors, filesProcessed);
}

class HullmodParseResult {
  final List<Hullmod> hullmods;
  final List<String> errors;
  final int filesProcessed;

  HullmodParseResult(this.hullmods, this.errors, this.filesProcessed);
}
