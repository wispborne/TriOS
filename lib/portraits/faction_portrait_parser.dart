import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/portraits/portrait_metadata.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

/// Parses faction and settings files to extract portrait metadata.
///
/// Faction files (*.faction) are JSON-ish files with comments that define
/// which portraits a faction uses, grouped by gender:
/// ```json
/// "portraits": {
///   "standard_male": ["graphics/portraits/male1.png"],
///   "standard_female": ["graphics/portraits/female1.png"]
/// }
/// ```
///
/// Settings files (settings.json) define character portraits with IDs:
/// ```json
/// "graphics": {
///   "characters": {
///     "portrait_id": "graphics/portraits/portrait.png"
///   }
/// }
/// ```
class FactionPortraitParser {
  /// Scans all faction and settings files in a mod and extracts portrait metadata.
  ///
  /// Returns a map of relative portrait path -> PortraitMetadata.
  static Future<Map<String, PortraitMetadata>> parseModFactions(
    ModVariant? modVariant,
    Directory gameCoreFolder,
  ) async {
    final folder = modVariant?.modFolder ?? gameCoreFolder;
    final Map<String, PortraitMetadata> allMetadata = {};

    // Parse faction files
    final factionsDir = Directory(p.join(folder.path, 'data/world/factions'));
    if (await factionsDir.exists()) {
      try {
        await for (final entity in factionsDir.list()) {
          if (entity is File && entity.path.endsWith('.faction')) {
            final factionMetadata = await _parseFactionFile(entity, modVariant);
            _mergeMetadata(allMetadata, factionMetadata);
          }
        }
      } catch (e) {
        Fimber.w('Error scanning factions in ${folder.path}: $e');
      }
    }

    // Parse settings.json for character portraits
    final settingsFile = File(p.join(folder.path, 'data/config/settings.json'));
    if (await settingsFile.exists()) {
      try {
        final settingsMetadata = await _parseSettingsFile(settingsFile);
        _mergeMetadata(allMetadata, settingsMetadata);
      } catch (e) {
        Fimber.w('Error parsing settings.json in ${folder.path}: $e');
      }
    }

    return allMetadata;
  }

  /// Merges source metadata into target, combining overlapping entries.
  static void _mergeMetadata(
    Map<String, PortraitMetadata> target,
    Map<String, PortraitMetadata> source,
  ) {
    for (final entry in source.entries) {
      if (target.containsKey(entry.key)) {
        target[entry.key] = target[entry.key]!.mergeWith(entry.value);
      } else {
        target[entry.key] = entry.value;
      }
    }
  }

  /// Parses settings.json to extract character portrait metadata.
  ///
  /// Uses text extraction instead of JSON parsing because settings.json
  /// has inconsistent formatting (mixed semicolons/commas, comments, etc).
  /// Looks for the `"characters":{...}` block and extracts key-value pairs.
  static Future<Map<String, PortraitMetadata>> _parseSettingsFile(
    File settingsFile,
  ) async {
    final Map<String, PortraitMetadata> metadata = {};

    try {
      final content = await settingsFile.readAsString();

      // Find the "characters" block using regex
      // Match "characters": { or "characters":{ (with optional whitespace)
      final charactersBlockRegex = RegExp(
        r'"characters"\s*:\s*\{([^}]*)\}',
        multiLine: true,
        dotAll: true,
      );

      final match = charactersBlockRegex.firstMatch(content);
      if (match == null) return {};

      final charactersBlock = match.group(1) ?? '';

      // Extract key-value pairs: "key":"value" or "key": "value"
      // Values are paths like "graphics/portraits/foo.png"
      final entryRegex = RegExp(
        r'"([^"]+)"\s*:\s*"([^"]+\.(?:png|jpg|jpeg))"',
        caseSensitive: false,
      );

      for (final entryMatch in entryRegex.allMatches(charactersBlock)) {
        final portraitId = entryMatch.group(1);
        final path = entryMatch.group(2);

        if (portraitId == null || path == null) continue;

        final normalizedPath = _normalizePath(path);
        metadata[normalizedPath] = PortraitMetadata(
          relativePath: normalizedPath,
          gender: null, // settings.json doesn't specify gender
          factions: {},
          portraitId: portraitId,
        );

        // :]
        if (portraitId == Constants.gargoyleCharId) {
          metadata[normalizedPath] = metadata[normalizedPath]!.copyWith(
            gender: PortraitGender.any,
          );
        }
      }
    } catch (e) {
      Fimber.w('Error parsing settings file ${settingsFile.path}: $e');
    }

    return metadata;
  }

  /// Parses a single faction file and returns portrait metadata.
  static Future<Map<String, PortraitMetadata>> _parseFactionFile(
    File factionFile,
    ModVariant? modVariant,
  ) async {
    final Map<String, PortraitMetadata> metadata = {};

    try {
      final content = await factionFile.readAsString();
      final jsonContent = content.removeJsonComments();
      final factionData = jsonContent.parseJsonToMap();

      final factionId = factionData['id'] as String?;
      if (factionId == null) return {};

      // Get the display name, preferring displayNameLong over displayName
      final displayName =
          factionData['displayNameLong'] as String? ??
          factionData['displayName'] as String? ??
          factionId;

      final factionInfo = FactionInfo(id: factionId, displayName: displayName);

      final portraits = factionData['portraits'] as Map<String, dynamic>?;
      if (portraits == null) return {};

      // Parse male portraits
      final malePortraits = _parsePortraitList(portraits['standard_male']);
      for (final path in malePortraits) {
        final normalizedPath = _normalizePath(path);
        metadata[normalizedPath] = PortraitMetadata(
          relativePath: normalizedPath,
          gender: PortraitGender.male,
          factions: {factionInfo},
        );
      }

      // Parse female portraits
      final femalePortraits = _parsePortraitList(portraits['standard_female']);
      for (final path in femalePortraits) {
        final normalizedPath = _normalizePath(path);
        final existing = metadata[normalizedPath];
        if (existing != null) {
          // Portrait already exists (possibly listed in both male and female?)
          // Merge factions, keep first gender found
          metadata[normalizedPath] = existing.mergeWith(
            PortraitMetadata(
              relativePath: normalizedPath,
              gender: PortraitGender.female,
              factions: {factionInfo},
            ),
          );
        } else {
          metadata[normalizedPath] = PortraitMetadata(
            relativePath: normalizedPath,
            gender: PortraitGender.female,
            factions: {factionInfo},
          );
        }
      }
    } catch (e) {
      Fimber.w('Error parsing faction file ${factionFile.path}: $e');
    }

    return metadata;
  }

  /// Parses a portrait list which can be a list or null.
  static List<String> _parsePortraitList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  /// Normalizes a portrait path for consistent matching.
  ///
  /// Ensures forward slashes and removes leading slashes.
  static String _normalizePath(String path) {
    var normalized = path.replaceAll('\\', '/');
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }
}
