// lib/ship_systems_manager.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/shipSystemsManager/ship_system.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

final isLoadingShipSystems = StateProvider<bool>((ref) => false);

/// Emits an updated list of ship systems any time [AppState.mods] changes.
/// Reads from vanilla (core) and each enabled mod, merging and deduplicating.
final shipSystemsStreamProvider = StreamProvider<List<ShipSystem>>((
  ref,
) async* {
  ref.watch(isLoadingShipSystems.notifier).state = true;
  final currentTime = DateTime.now();
  int filesProcessed = 0;

  final gameCorePath = ref
      .watch(AppState.gameCoreFolder).value
      ?.path;
  if (gameCorePath == null || gameCorePath.isEmpty) {
    throw Exception('Game folder path is not set.');
  }

  final variants = ref
      .watch(AppState.mods)
      .map((mod) => mod.findFirstEnabledOrHighestVersion)
      .nonNulls
      .toList();

  final allErrors = <String>[];
  var allSystems = <ShipSystem>[];

  // Parse core (vanilla) ship systems
  final coreResult = await _parseShipSystems(Directory(gameCorePath), null);
  filesProcessed += coreResult.filesProcessed;
  allSystems.addAll(coreResult.systems);
  allSystems = allSystems.distinctBy((s) => s.id).toList();
  if (coreResult.errors.isNotEmpty) allErrors.addAll(coreResult.errors);
  yield allSystems;

  // Parse each mod's ship systems
  for (final variant in variants) {
    final modResult = await _parseShipSystems(variant.modFolder, variant);
    filesProcessed += modResult.filesProcessed;
    allSystems.addAll(modResult.systems);
    allSystems = allSystems.distinctBy((s) => s.id).toList();
    if (modResult.errors.isNotEmpty) allErrors.addAll(modResult.errors);
    yield allSystems;
  }

  // Log errors if any
  if (allErrors.isNotEmpty) {
    Fimber.w('Ship systems parsing errors:\n${allErrors.join('\n')}');
  }

  ref.watch(isLoadingShipSystems.notifier).state = false;
  Fimber.i(
    'Parsed ${allSystems.length} ship systems from ${variants.length + 1} sources and $filesProcessed files in ${DateTime.now().difference(currentTime).inMilliseconds}ms',
  );
});

/// Reads and parses `data/ship_systems.csv` under [folder], returning
/// a list of [ShipSystem]s along with parse errors and file count.
Future<_SystemParseResult> _parseShipSystems(
  Directory folder,
  ModVariant? modVariant,
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
    errors.add('[$modName] ship_systems.csv not found at ${systemsCsv.path}');
    return _SystemParseResult(systems, errors, filesProcessed);
  }

  String content;
  try {
    filesProcessed++;
    content = await systemsCsv.readAsString(encoding: utf8);
  } catch (e) {
    errors.add('[$modName] Failed to read ship_systems.csv: $e');
    return _SystemParseResult(systems, errors, filesProcessed);
  }

  // Strip comments and blank lines
  final lines = content.split('\n');
  final processed = <String>[];
  for (var line in lines) {
    final cleaned = line.removeCsvLineComments();
    if (cleaned.trim().isEmpty) continue;
    processed.add(cleaned);
  }

  List<List<dynamic>> rows;
  try {
    rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(processed.join('\n'));
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
    final row = rows[i];
    final data = <String, dynamic>{};
    for (var j = 0; j < headers.length; j++) {
      var value = row.length > j ? row[j] : null;
      if (value is String) {
        final up = value.toUpperCase();
        if (up == 'TRUE') {
          value = true;
        } else if (up == 'FALSE') {
          value = false;
        } else {
          final n = num.tryParse(value);
          value = n ?? value;
        }
      }
      data[headers[j]] = value;
    }

    try {
      final sys = ShipSystemMapper.fromMap(data);
      // sys.modVariant = modVariant;
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

class _SystemParseResult {
  final List<ShipSystem> systems;
  final List<String> errors;
  final int filesProcessed;

  _SystemParseResult(this.systems, this.errors, this.filesProcessed);
}
