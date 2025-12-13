import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/shipViewer/models/ship_weapon_slot.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

final isLoadingShipsList = StateProvider<bool>((ref) => false);
final isShipsListDirty = StateProvider<bool>((ref) => false);
final shipListNotifierProvider = StreamProvider<List<Ship>>((ref) async* {
  int filesProcessed = 0;

  final currentTime = DateTime.now();
  ref.read(isLoadingShipsList.notifier).state = true;
  filesProcessed = 0;
  final gameCorePath = ref
      .watch(AppState.gameCoreFolder).value
      ?.path;

  if (gameCorePath == null || gameCorePath.isEmpty) {
    throw Exception('Game folder path is not set.');
  }

  ref.listen(AppState.variantSmolIds, (previous, next) {
    ref.read(isShipsListDirty.notifier).state = true;
  });

  // Don't watch for mod changes, the background processing is too expensive.
  // User has to manually refresh ships viewer.
  final variants = ref
      .read(AppState.mods)
      .map((mod) => mod.findFirstEnabledOrHighestVersion)
      .nonNulls
      .toList();

  final allErrors = <String>[];
  List<Ship> allShips = <Ship>[];

  final coreResult = await _parseShips(Directory(gameCorePath), null);
  filesProcessed += coreResult.filesProcessed;
  allShips.addAll(coreResult.ships);
  allShips = allShips.distinctBy((e) => e.id).toList();

  if (coreResult.errors.isNotEmpty) {
    allErrors.addAll(coreResult.errors);
  }

  for (final variant in variants) {
    final modResult = await _parseShips(variant.modFolder, variant);
    filesProcessed += modResult.filesProcessed;
    allShips.addAll(modResult.ships);
    allShips = allShips.distinctBy((e) => e.id).toList();

    if (modResult.errors.isNotEmpty) {
      allErrors.addAll(modResult.errors);
    }

    yield allShips;
  }

  if (allErrors.isNotEmpty) {
    Fimber.w('Ship parsing errors:\n${allErrors.join('\n')}');
  }

  ref.read(isLoadingShipsList.notifier).state = false;
  ref.read(isShipsListDirty.notifier).state = false;
  Fimber.i(
    'Parsed ${allShips.length} ships from ${variants.length + 1} mods and $filesProcessed files in ${DateTime.now().difference(currentTime).inMilliseconds}ms',
  );
});

Future<ShipParseResult> _parseShips(
  Directory folder,
  ModVariant? modVariant,
) async {
  int filesProcessed = 0;
  final shipsCsvFile = p
      .join(folder.path, 'data/hulls/ship_data.csv')
      .toFile()
      .normalize
      .toFile();
  final ships = <Ship>[];
  final errors = <String>[];
  final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

  if (!await shipsCsvFile.exists()) {
    // No ships in the mod.
    return ShipParseResult(ships, errors, filesProcessed);
  }

  // Load and index .ship files
  final shipDir = Directory(p.join(folder.path, 'data/hulls'));
  final shipFiles = shipDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.ship'))
      .toList();

  final shipJsonData = <String, Map<String, dynamic>>{};
  for (final shipFile in shipFiles) {
    filesProcessed++;
    try {
      final raw = await shipFile.readAsString(encoding: utf8);
      final cleaned = raw.removeJsonComments();
      final map = cleaned.fixJsonToMap();
      final id = map['hullId'] as String?;
      if (id != null) {
        shipJsonData[id] = map;
      } else {
        errors.add('[$modName] .ship file ${shipFile.path} missing "hullId"');
      }
    } catch (e) {
      errors.add('[$modName] Failed to parse .ship file ${shipFile.path}: $e');
    }
  }

  String content;
  try {
    filesProcessed++;
    content = await shipsCsvFile.readAsString(encoding: utf8);
  } catch (e) {
    errors.add('[$modName] Failed to read ship_data.csv: $e');
    return ShipParseResult(ships, errors, filesProcessed);
  }

  final lines = content.split('\n');
  final processedLines = <String>[];
  final lineNumberMap = <int>[];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].removeCsvLineComments();
    if (line.trim().isEmpty) continue;
    processedLines.add(line);
    lineNumberMap.add(i);
  }

  List<List<dynamic>> rows;
  try {
    rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(processedLines.join('\n'));
  } catch (e) {
    errors.add('[$modName] Failed to parse CSV: $e');
    return ShipParseResult(ships, errors, filesProcessed);
  }

  if (rows.isEmpty) {
    errors.add('[$modName] Empty ship_data.csv');
    return ShipParseResult(ships, errors, filesProcessed);
  }

  final headers = rows.first.map((e) => e.toString()).toList();

  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final data = <String, dynamic>{};

    for (var j = 0; j < headers.length; j++) {
      final key = headers[j];
      dynamic value = row.length > j ? row[j] : null;

      if (value == null || (value is String && value.trim().isEmpty)) {
        data[key] = null;
        continue;
      }

      if (value.toString().toUpperCase() == 'TRUE') {
        value = true;
      } else if (value.toString().toUpperCase() == 'FALSE') {
        value = false;
      } else {
        value = num.tryParse(value.toString()) ?? value.toString();
      }

      data[key] = value;
    }

    final shipId = data['id'] as String?;
    if (shipId == null || shipId.isEmpty) {
      // Blank line in the csv, almost definitely for spacing.
      continue;
    }

    final json = shipJsonData[shipId];
    if (json == null) {
      errors.add(
        '[$modName] Missing .ship data for $shipId, defined on line ${lineNumberMap[i]} of ship_data.csv (addon mods sometimes tweak ships in their parent mod)).',
      );
      continue;
    }

    final rawSlots = json.remove('weaponSlots');
    if (rawSlots is List) {
      data['weaponSlots'] = rawSlots
          .map(
            (e) => ShipWeaponSlotMapper.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList();
    }

    data.addAll(json);

    try {
      final ship = ShipMapper.fromMap(data)..modVariant = modVariant;
      ships.add(ship);
    } catch (e) {
      errors.add('[$modName] Failed to create ship for id "$shipId": $e');
    }
  }

  return ShipParseResult(ships, errors, filesProcessed);
}

class ShipParseResult {
  final List<Ship> ships;
  final List<String> errors;
  final int filesProcessed;

  ShipParseResult(this.ships, this.errors, this.filesProcessed);
}
