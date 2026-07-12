import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/cached_stream_list_notifier.dart';
import 'package:trios/viewer_cache/cached_variant_store.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/models/weapons_cache_payload.dart';

final isLoadingWeaponsList = StateProvider<bool>((ref) => false);
final isWeaponsListDirty = StateProvider<bool>((ref) => false);

final weaponListNotifierProvider =
    StreamNotifierProvider<WeaponListNotifier, List<Weapon>>(
      WeaponListNotifier.new,
    );

/// Weapons keyed by id, rebuilt only when the weapons list changes. Prefer
/// this over building a map from [weaponListNotifierProvider] per widget.
final weaponsByIdProvider = Provider<Map<String, Weapon>>((ref) {
  final weapons =
      ref.watch(weaponListNotifierProvider).valueOrNull ?? const <Weapon>[];
  return {for (final w in weapons) w.id: w};
});

class WeaponListNotifier
    extends CachedStreamListNotifier<Weapon, WeaponsCachePayload> {
  @override
  String get domain => 'weapons';

  @override
  int get schemaVersion => 1;

  @override
  late final CachedVariantStore store =
      CachedVariantStore(domain, Constants.viewerCacheDirPath);

  @override
  String itemId(Weapon item) => item.id;

  @override
  List<Weapon> itemsFromPayload(WeaponsCachePayload payload) => payload.weapons;

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
    // Watch modVariants so this rebuilds once the initial scan resolves.
    return ref.watch(AppState.modVariants).hasValue;
  }

  @override
  void onBuildStart() {
    ref.read(isLoadingWeaponsList.notifier).state = true;
    ref.listen(AppState.smolIds, (previous, next) {
      ref.read(isWeaponsListDirty.notifier).state = true;
    });
  }

  @override
  void onBuildComplete({required bool fullScanCompleted}) {
    ref.read(isLoadingWeaponsList.notifier).state = false;
    if (fullScanCompleted) {
      ref.read(isWeaponsListDirty.notifier).state = false;
    }
    super.onBuildComplete(fullScanCompleted: fullScanCompleted);
  }

  @override
  void rehydratePayload(
    WeaponsCachePayload payload,
    ModVariant? sourceVariant,
  ) {
    for (final weapon in payload.weapons) {
      weapon.modVariant = sourceVariant;
    }
  }

  @override
  Future<WeaponsCachePayload?> parseVanilla(
    Directory gameCore,
    List<Weapon> allItemsSoFar,
  ) {
    return _parseOneFolder(gameCore, null);
  }

  @override
  Future<WeaponsCachePayload?> parseVariant(
    ModVariant variant,
    List<Weapon> allItemsSoFar,
  ) {
    return _parseOneFolder(variant.modFolder, variant);
  }

  Future<WeaponsCachePayload?> _parseOneFolder(
    Directory folder,
    ModVariant? modVariant,
  ) async {
    try {
      final result = await _parseWeaponsCsv(folder, modVariant);
      result.errors.forEach(addError);
      result.infos.forEach(addInfo);
      return WeaponsCachePayload(weapons: result.weapons);
    } catch (e, st) {
      Fimber.w(
        'Weapon parse failed for ${modVariant?.modInfo.nameOrId ?? 'Vanilla'}: $e',
        ex: e,
        stacktrace: st,
      );
      return null;
    }
  }

  @override
  Uint8List encodePayload(WeaponsCachePayload payload) {
    final map = <String, dynamic>{
      'weapons': payload.weapons.map((w) => w.toMap()).toList(),
    };
    return msgpack.serialize(map);
  }

  @override
  WeaponsCachePayload decodePayload(Uint8List bytes) {
    final raw = CachedStreamListNotifier.normalizeForMapper(
      msgpack.deserialize(bytes),
    ) as Map<String, dynamic>;
    final weaponMaps = (raw['weapons'] as List).cast<Map<String, dynamic>>();
    final weapons = <Weapon>[];
    for (final map in weaponMaps) {
      final weapon = WeaponMapper.fromMap(map);
      final csvPath = map['csvfile'];
      if (csvPath is String) weapon.csvFile = File(csvPath);
      final wpnPath = map['wpnFile'];
      if (wpnPath is String) weapon.wpnFile = File(wpnPath);
      weapon.modVariant = null;
      weapons.add(weapon);
    }
    return WeaponsCachePayload(weapons: weapons);
  }

  String allWeaponsAsCsv() {
    final allWeapons = state.value ?? [];

    final weaponFields = allWeapons.isNotEmpty
        ? allWeapons.first.toMap().keys.toList()
        : [];
    List<List<dynamic>> rows = [weaponFields];

    if (allWeapons.isNotEmpty) {
      rows.addAll(
        allWeapons.map((weapon) => weapon.toMap().values.toList()).toList(),
      );
    }

    final csvContent = const ListToCsvConverter(
      convertNullTo: "",
    ).convert(rows);

    return csvContent;
  }
}

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
  final infos = <String>[];
  final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

  if (!await weaponsCsvFile.exists()) {
    infos.add('[$modName] Weapons CSV file not found at $weaponsCsvFile');
    return ParseResult(weapons, errors, infos, filesProcessed);
  }

  // Read and parse the .wpn files
  final wpnFilesDir = p.join(folder.path, 'data/weapons');
  final wpnFiles = Directory(wpnFilesDir)
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.wpn'))
      .toList();

  // Index missile projectile specs in this folder so launchers with the
  // RENDER_LOADED_MISSILES hint can show their loaded missiles. Resolved
  // within the weapon's own mod folder (cross-mod projectile references are
  // not handled — those launchers simply won't show missiles).
  final missileSpecs = await _indexMissileSpecs(folder);

  final wpnDataMap = <String, Map<String, dynamic>>{};

  for (final wpnFile in wpnFiles) {
    filesProcessed++;
    try {
      final wpnContent = await wpnFile.readAsString(encoding: utf8);
      final cleanedContent = wpnContent.removeJsonComments();
      final jsonData = await cleanedContent.parseJsonToMapAsync();
      final weaponId = jsonData['id'] as String?;
      if (weaponId != null) {
        // Extract only the specified fields
        final Map<String, dynamic> wpnFields = {
          'specClass': jsonData['specClass'],
          'type': jsonData['type'],
          'mountTypeOverride': jsonData['mountTypeOverride'],
          'size': jsonData['size'],
          'damageType': jsonData['damageType'],
          'turretSprite': _resolveSpritePath(folder, jsonData['turretSprite']),
          'turretGunSprite': _resolveSpritePath(
            folder,
            jsonData['turretGunSprite'],
          ),
          'hardpointSprite': _resolveSpritePath(
            folder,
            jsonData['hardpointSprite'],
          ),
          'hardpointGunSprite': _resolveSpritePath(
            folder,
            jsonData['hardpointGunSprite'],
          ),
          'turretUnderSprite': _resolveSpritePath(
            folder,
            jsonData['turretUnderSprite'],
          ),
          'hardpointUnderSprite': _resolveSpritePath(
            folder,
            jsonData['hardpointUnderSprite'],
          ),
          'turretGlowSprite': _resolveSpritePath(
            folder,
            jsonData['turretGlowSprite'],
          ),
          'hardpointGlowSprite': _resolveSpritePath(
            folder,
            jsonData['hardpointGlowSprite'],
          ),
          'glowColor': _toDoubleList(jsonData['glowColor']),
          'renderHints': _toStringList(jsonData['renderHints']),
          'projectileSpecId': jsonData['projectileSpecId'],
          'turretOffsets': _toDoubleList(jsonData['turretOffsets']),
          'hardpointOffsets': _toDoubleList(jsonData['hardpointOffsets']),
          'turretAngleOffsets': _toDoubleList(jsonData['turretAngleOffsets']),
          'hardpointAngleOffsets': _toDoubleList(
            jsonData['hardpointAngleOffsets'],
          ),
          'wpnFile': wpnFile,
        };

        // Resolve loaded-missile render data for launchers.
        final hints = (wpnFields['renderHints'] as List<String>?) ?? const [];
        final projId = jsonData['projectileSpecId'] as String?;
        if (projId != null &&
            hints.any(
              (h) => h.toUpperCase().contains('RENDER_LOADED_MISSILES'),
            )) {
          final missile = missileSpecs[projId];
          if (missile != null) {
            wpnFields['loadedMissileSprite'] = missile.sprite;
            wpnFields['loadedMissileSize'] = missile.size;
            wpnFields['loadedMissileCenter'] = missile.center;
          }
        }

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
    content = await weaponsCsvFile.readAsStringUtf8OrLatin1();
  } on FileSystemException catch (e) {
    errors.add('[$modName] Failed to read file at $weaponsCsvFile: $e');
    return ParseResult(weapons, errors, infos, filesProcessed);
  } catch (e) {
    errors.add(
      '[$modName] Unexpected error reading file at $weaponsCsvFile: $e',
    );
    return ParseResult(weapons, errors, infos, filesProcessed);
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
      '[$modName] Failed to parse CSV content in file $weaponsCsvFile: $e',
    );
    return ParseResult(weapons, errors, infos, filesProcessed);
  }

  if (rows.isEmpty) {
    errors.add('[$modName] Empty weapons CSV file at $weaponsCsvFile');
    return ParseResult(weapons, errors, infos, filesProcessed);
  }

  // Extract headers from the first row
  final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();

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

      // Preserve CSV damage type before .wpn overwrites 'type' with mount type.
      final csvDamageType = weaponData['type'];

      // Merge the .wpn data into weaponData
      final wpnData = wpnDataMap[weaponId];
      if (wpnData != null) {
        weaponData.addAll(wpnData);
        // .wpn files rarely have damageType; fall back to the CSV type column.
        weaponData['damageType'] ??= csvDamageType;
      } else {
        errors.add(
          '[$modName] No .wpn data found for weapon id "$weaponId" (addon mods sometimes tweak weapons in their parent mod or vanilla)',
        );
      }

      // Create Weapon instance
      final weapon = WeaponMapper.fromMap(
        {for (final e in weaponData.entries) e.key.toLowerCase(): e.value},
      )
        ..modVariant = modVariant
        ..csvFile = weaponsCsvFile
        ..wpnFile = weaponData['wpnFile'];
      weapons.add(weapon);
    } catch (e) {
      final lineNumber = lineNumberMapping[i];
      errors.add('[$modName] Row $lineNumber: $e');
    }
  }

  return ParseResult(weapons, errors, infos, filesProcessed);
}

/// Joins a mod-relative sprite path to an absolute, normalized path.
/// Returns null when the source value is missing, so absent layers stay null
/// (joining a null would otherwise yield the mod folder path).
String? _resolveSpritePath(Directory folder, dynamic relativePath) {
  if (relativePath is! String || relativePath.trim().isEmpty) return null;
  return p.join(folder.path, relativePath).toFile().normalize.path;
}

List<double>? _toDoubleList(dynamic value) {
  if (value is! List) return null;
  final result = <double>[];
  for (final e in value) {
    if (e is num) {
      result.add(e.toDouble());
    } else {
      final parsed = num.tryParse(e.toString());
      if (parsed != null) result.add(parsed.toDouble());
    }
  }
  return result.isEmpty ? null : result;
}

List<String>? _toStringList(dynamic value) {
  if (value is! List) return null;
  return value.map((e) => e.toString()).toList();
}

/// Resolved render data for a loaded missile, from a `.proj` spec.
class _MissileSpec {
  final String sprite;
  final List<double>? size;
  final List<double>? center;

  _MissileSpec(this.sprite, this.size, this.center);
}

/// Scans `data/weapons` (recursively, to catch the `proj/` subfolder) and
/// builds a `projectileSpecId -> _MissileSpec` index for missile-type
/// projectiles defined in this folder.
Future<Map<String, _MissileSpec>> _indexMissileSpecs(Directory folder) async {
  final result = <String, _MissileSpec>{};
  final projDir = p.join(folder.path, 'data/weapons').toDirectory();
  if (!await projDir.exists()) return result;

  final projFiles = projDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.proj'));

  for (final projFile in projFiles) {
    try {
      final content = await projFile.readAsString(encoding: utf8);
      final json = await content.removeJsonComments().parseJsonToMapAsync();
      final id = json['id'] as String?;
      final specClass = (json['specClass'] as String?)?.toLowerCase();
      if (id == null || specClass != 'missile') continue;
      final sprite = _resolveSpritePath(folder, json['sprite']);
      if (sprite == null) continue;
      result[id] = _MissileSpec(
        sprite,
        _toDoubleList(json['size']),
        _toDoubleList(json['center']),
      );
    } catch (_) {
      // Ignore unparseable .proj files; missiles are best-effort decoration.
    }
  }
  return result;
}

// Helper class to hold parsing results
class ParseResult {
  final List<Weapon> weapons;
  final List<String> errors;
  final List<String> infos;
  final int filesProcessed;

  ParseResult(this.weapons, this.errors, this.infos, this.filesProcessed);
}
