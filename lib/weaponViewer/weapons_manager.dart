import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/weaponViewer/models/weapon.dart';

final isLoadingWeaponsList = StateProvider<bool>((ref) => false);
final weaponListNotifierProvider = StreamProvider<List<Weapon>>((ref) async* {
  int filesProcessed = 0;

  final currentTime = DateTime.now();
  ref.watch(isLoadingWeaponsList.notifier).state = true;
  filesProcessed = 0;
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

  final allErrors = <String>[]; // To store all error messages
  List<Weapon> allWeapons = <Weapon>[]; // To store all parsed weapons

  // Parse the core game weapons
  final coreResult = await _parseWeaponsCsv(Directory(gameCorePath), null);
  filesProcessed += coreResult.filesProcessed;
  // only add non-duplicate weapons
  allWeapons.addAll(coreResult.weapons);
  allWeapons = allWeapons.distinctBy((e) => e.id).toList();

  if (coreResult.errors.isNotEmpty) {
    allErrors.addAll(coreResult.errors);
  }

  // Parse each mod's weapons individually
  for (final variant in variants) {
    final modResult = await _parseWeaponsCsv(variant.modFolder, variant);
    filesProcessed += modResult.filesProcessed;
    allWeapons.addAll(modResult.weapons);
    allWeapons = allWeapons.distinctBy((e) => e.id).toList();

    if (modResult.errors.isNotEmpty) {
      allErrors.addAll(modResult.errors);
    }

    yield allWeapons;
  }

  // Print out all collected errors at the end
  if (allErrors.isNotEmpty) {
    Fimber.w('Errors encountered during parsing:\n${allErrors.join('\n')}');
  }

  ref.watch(isLoadingWeaponsList.notifier).state = false;
  Fimber.i(
    'Parsed ${allWeapons.length} weapons from ${variants.length + 1} mods and $filesProcessed files in ${DateTime.now().difference(currentTime).inMilliseconds}ms',
  );

  // yield weapons;
});

/// Takes fields from the weapon_data.csv and all .wpn files,
/// dumps them into a 2d map (all weapon key-value pairs, grouped by id),
/// then iterates over the map and creates a Weapon object for each entry.
Future<ParseResult> _parseWeaponsCsv(
  Directory folder,
  ModVariant? modVariant,
) async {
  int filesProcessed = 0;

  final weaponsCsvFile = p
      .join(folder.path, 'data/weapons/weapon_data.csv')
      .toFile()
      .normalize
      .toFile();

  final weapons = <Weapon>[];
  final errors = <String>[];
  final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

  if (!await weaponsCsvFile.exists()) {
    errors.add('[$modName] Weapons CSV file not found at $weaponsCsvFile');
    return ParseResult(weapons, errors, filesProcessed);
  }

  // Read and parse the .wpn files
  final wpnFilesDir = p.join(folder.path, 'data/weapons');
  final wpnFiles = Directory(wpnFilesDir)
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.wpn'))
      .toList();

  final wpnDataMap = <String, Map<String, dynamic>>{};

  for (final wpnFile in wpnFiles) {
    filesProcessed++;
    try {
      final wpnContent = await wpnFile.readAsString(encoding: utf8);
      final cleanedContent = wpnContent.removeJsonComments();
      final jsonData = cleanedContent.fixJsonToMap();
      final weaponId = jsonData['id'] as String?;
      if (weaponId != null) {
        // Extract only the specified fields
        final Map<String, dynamic> wpnFields = {
          'specClass': jsonData['specClass'],
          'type': jsonData['type'],
          'size': jsonData['size'],
          'turretSprite': p
              .join(folder.path, jsonData['turretSprite'])
              .toFile()
              .normalize
              .path,
          'turretGunSprite': p
              .join(folder.path, jsonData['turretGunSprite'])
              .toFile()
              .normalize
              .path,
          'hardpointSprite': p
              .join(folder.path, jsonData['hardpointSprite'])
              .toFile()
              .normalize
              .path,
          'hardpointGunSprite': p
              .join(folder.path, jsonData['hardpointGunSprite'])
              .toFile()
              .normalize
              .path,
          'wpnFile': wpnFile,
        };
        wpnDataMap[weaponId] = wpnFields;
      } else {
        errors.add('[$modName] .wpn file ${wpnFile.path} missing "id" field');
      }
    } catch (e) {
      errors.add('[$modName] Failed to parse .wpn file ${wpnFile.path}: $e');
      continue;
    }
  }

  String content;
  try {
    filesProcessed++;
    content = await weaponsCsvFile.readAsString(encoding: utf8);
  } on FileSystemException catch (e) {
    errors.add('[$modName] Failed to read file at $weaponsCsvFile: $e');
    return ParseResult(weapons, errors, filesProcessed);
  } catch (e) {
    errors.add(
      '[$modName] Unexpected error reading file at $weaponsCsvFile: $e',
    );
    return ParseResult(weapons, errors, filesProcessed);
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
    lineNumberMapping.add(index + 1); // Original line number in the file
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
      '[$modName] Failed to parse CSV content in file $weaponsCsvFile: $e',
    );
    return ParseResult(weapons, errors, filesProcessed);
  }

  if (rows.isEmpty) {
    errors.add('[$modName] Empty weapons CSV file at $weaponsCsvFile');
    return ParseResult(weapons, errors, filesProcessed);
  }

  // Extract headers from the first row
  final headers = rows.first.map((e) => e.toString()).toList();

  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final Map<String, dynamic> weaponData = {};

    for (var j = 0; j < headers.length; j++) {
      final key = headers[j];
      dynamic value = row.length > j ? row[j] : null;

      if (value == null || (value is String && value.trim().isEmpty)) {
        weaponData[key] = null;
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

      weaponData[key] = value;
    }

    try {
      final weaponId = weaponData['id'] as String?;
      if (weaponId == null || weaponId.isEmpty) {
        final lineNumber = lineNumberMapping[i];
        errors.add('[$modName] Weapon in CSV without id at line $lineNumber');
        continue;
      }

      // Merge the .wpn data into weaponData
      final wpnData = wpnDataMap[weaponId];
      if (wpnData != null) {
        weaponData.addAll(wpnData);
      } else {
        errors.add(
          '[$modName] No .wpn data found for weapon id "$weaponId" (addon mods sometimes tweak weapons in their parent mod or vanilla)',
        );
      }

      // Create Weapon instance
      final weapon = WeaponMapper.fromMap(weaponData)
        ..modVariant = modVariant
        ..csvFile = weaponsCsvFile
        ..wpnFile = weaponData['wpnFile'];
      weapons.add(weapon);
    } catch (e) {
      final lineNumber = lineNumberMapping[i];
      errors.add('[$modName] Row $lineNumber: $e');
    }
  }

  return ParseResult(weapons, errors, filesProcessed);
}

// Helper class to hold parsing results
class ParseResult {
  final List<Weapon> weapons;
  final List<String> errors;
  final int filesProcessed;

  ParseResult(this.weapons, this.errors, this.filesProcessed);
}
