import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/shipWeaponViewer/models/weapon.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

final weaponListNotifierProvider =
    AsyncNotifierProvider<WeaponsManager, List<Weapon>>(WeaponsManager.new);

class WeaponsManager extends AsyncNotifier<List<Weapon>> {
  int filesProcessed = 0;

  @override
  FutureOr<List<Weapon>> build() async {
    final currentTime = DateTime.now();
    filesProcessed = 0;
    final gameCorePath =
        ref.watch(appSettings.select((s) => s.gameCoreDir))?.path;

    if (gameCorePath == null || gameCorePath.isEmpty) {
      throw Exception('Game folder path is not set.');
    }

    final variants = ref
        .watch(AppState.mods)
        .map((mod) => mod.findFirstEnabledOrHighestVersion)
        .whereNotNull()
        .toList();

    final weapons = await parseAllWeapons(variants, gameCorePath);
    Fimber.i(
        'Parsed ${weapons.length} weapons from ${variants.length + 1} mods and $filesProcessed files in ${DateTime.now().difference(currentTime).inMilliseconds}ms');
    return weapons;
  }

  Future<List<Weapon>> parseAllWeapons(
      List<ModVariant> variants, String gameCorePath) async {
    final allErrors = <String>[]; // To store all error messages
    final allWeapons = <Weapon>[]; // To store all parsed weapons

    // Parse the core game weapons
    final coreResult = await _parseWeaponsCsv(Directory(gameCorePath), null);
    allWeapons.addAll(coreResult.weapons);
    if (coreResult.errors.isNotEmpty) {
      allErrors.addAll(coreResult.errors);
    }

    // Parse each mod's weapons individually
    for (final variant in variants) {
      final modResult = await _parseWeaponsCsv(variant.modFolder, variant);
      allWeapons.addAll(modResult.weapons);
      if (modResult.errors.isNotEmpty) {
        allErrors.addAll(modResult.errors);
      }
    }

    // Print out all collected errors at the end
    if (allErrors.isNotEmpty) {
      Fimber.w('Errors encountered during parsing:\n${allErrors.join('\n')}');
    }

    return allWeapons;
  }

  Future<ParseResult> _parseWeaponsCsv(
      Directory folder, ModVariant? modVariant) async {
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
      return ParseResult(weapons, errors);
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
        final cleanedContent = _removeCommentsFromJson(wpnContent);
        final jsonData = cleanedContent.fixJsonToMap();
        final weaponId = jsonData['id'] as String?;
        if (weaponId != null) {
          // Extract only the specified fields
          final Map<String, dynamic> wpnFields = {
            'specClass': jsonData['specClass'],
            'type': jsonData['type'],
            'size': jsonData['size'],
            'turretSprite': p.join(folder.path, jsonData['turretSprite']).toFile().normalize.path,
            'turretGunSprite': p.join(folder.path, jsonData['turretGunSprite']).toFile().normalize.path,
            'hardpointSprite': p.join(folder.path, jsonData['hardpointSprite']).toFile().normalize.path,
            'hardpointGunSprite': p.join(folder.path, jsonData['hardpointGunSprite']).toFile().normalize.path,
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
      return ParseResult(weapons, errors);
    } catch (e) {
      errors.add(
          '[$modName] Unexpected error reading file at $weaponsCsvFile: $e');
      return ParseResult(weapons, errors);
    }

    // Preprocess the content to handle comments
    final lines = content.split('\n');
    final processedLines = <String>[];
    final lineNumberMapping = <int>[];

    for (int index = 0; index < lines.length; index++) {
      String line = lines[index];
      String processedLine = _removeCommentOutsideQuotes(line);

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
          '[$modName] Failed to parse CSV content in file $weaponsCsvFile: $e');
      return ParseResult(weapons, errors);
    }

    if (rows.isEmpty) {
      errors.add('[$modName] Empty weapons CSV file at $weaponsCsvFile');
      return ParseResult(weapons, errors);
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
          errors.add('[$modName] No .wpn data found for weapon id "$weaponId"');
        }

        // Create Weapon instance
        final weapon = WeaponMapper.fromMap(weaponData)
          ..modVariant = modVariant;
        weapons.add(weapon);
      } catch (e) {
        final lineNumber = lineNumberMapping[i];
        errors.add('[$modName] Row $lineNumber: $e');
      }
    }

    return ParseResult(weapons, errors);
  }

  // Helper function to remove comments starting with '#' outside of quotes
  String _removeCommentOutsideQuotes(String line) {
    bool inQuotes = false;
    String result = '';
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      }
      if (!inQuotes && char == '#') {
        break;
      }
      result += char;
    }
    return result.trimRight();
  }

  // Helper function to remove comments from JSON content
  String _removeCommentsFromJson(String jsonContent) {
    final lines = LineSplitter.split(jsonContent);
    final nonCommentLines = lines.map((line) {
      final index = line.indexOf('#');
      if (index >= 0) {
        return line.substring(0, index);
      } else {
        return line;
      }
    });
    return nonCommentLines.join('\n');
  }
}

// Helper class to hold parsing results
class ParseResult {
  final List<Weapon> weapons;
  final List<String> errors;

  ParseResult(this.weapons, this.errors);
}
