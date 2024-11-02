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
  @override
  FutureOr<List<Weapon>> build() async {
    final currentTime = DateTime.now();
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
        'Parsed ${weapons.length} weapons from ${variants.length + 1} mods in ${DateTime.now().difference(currentTime).inMilliseconds}ms');
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
    final file = p
        .join(folder.path, 'data/weapons/weapon_data.csv')
        .toFile()
        .normalize
        .toFile();

    final weapons = <Weapon>[];
    final errors = <String>[];
    final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

    if (!await file.exists()) {
      errors.add('[$modName] Weapons CSV file not found at $file');
      return ParseResult(weapons, errors);
    }

    String content;
    try {
      // Try reading the file with UTF-8 encoding
      content = await file.readAsString(encoding: utf8);
    } on FileSystemException catch (e) {
      // Handle file system exceptions (e.g., encoding issues)
      errors.add('[$modName] Failed to read file at $file: $e');
      return ParseResult(weapons, errors);
    } catch (e) {
      // Handle any other exceptions
      errors.add('[$modName] Unexpected error reading file at $file: $e');
      return ParseResult(weapons, errors);
    }

    // Preprocess the content to handle comments
    // We'll process each line to remove comments starting with '#' outside of quotes
    final lines = content.split('\n');
    final processedLines = <String>[];
    final lineNumberMapping = <int>[];

    for (int index = 0; index < lines.length; index++) {
      String line = lines[index];
      String processedLine = _removeCommentOutsideQuotes(line);

      if (processedLine.trim().isEmpty) {
        // Skip empty lines
        continue;
      }

      processedLines.add(processedLine);
      lineNumberMapping.add(index + 1); // Original line number in the file
    }

    // Rejoin the processed lines
    final processedContent = processedLines.join('\n');

    List<List<dynamic>> rows;
    try {
      rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(processedContent);
    } catch (e) {
      errors.add('[$modName] Failed to parse CSV content in file $file: $e');
      return ParseResult(weapons, errors);
    }

    if (rows.isEmpty) {
      errors.add('[$modName] Empty weapons CSV file at $file');
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

        // Handle null or empty values
        if (value == null || (value is String && value.trim().isEmpty)) {
          weaponData[key] = null;
          continue;
        }

        // Convert 'TRUE'/'FALSE' to boolean
        if (value.toString().toUpperCase() == 'TRUE') {
          value = true;
        } else if (value.toString().toUpperCase() == 'FALSE') {
          value = false;
        } else {
          // Attempt to parse numbers
          final numValue = num.tryParse(value.toString());
          value = numValue ?? value.toString();
        }

        weaponData[key] = value;
      }

      try {
        final weapon = WeaponMapper.fromMap(weaponData)
          ..modVariant = modVariant;
        weapons.add(weapon);
      } catch (e) {
        // Use the original line number from the file for accurate error reporting
        final lineNumber = lineNumberMapping[i];
        errors.add('[$modName] Row $lineNumber: $e');
        // Continue parsing the next row
      }
    }

    return ParseResult(weapons, errors);
  }

// Helper function to remove comments starting with '#' outside of quotes
  String _removeCommentOutsideQuotes(String line) {
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        // Toggle inQuotes status
        inQuotes = !inQuotes;
      } else if (char == '#' && !inQuotes) {
        // Found '#' outside quotes, remove rest of the line
        return line.substring(0, i).trimRight();
      }
    }
    // No comment found outside quotes
    return line;
  }
}

// Helper class to hold parsing results
class ParseResult {
  final List<Weapon> weapons;
  final List<String> errors;

  ParseResult(this.weapons, this.errors);
}
