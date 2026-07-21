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
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/utils/log_collapser.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/cached_stream_list_notifier.dart';
import 'package:trios/viewer_cache/cached_variant_store.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/models/weapons_cache_payload.dart';

final isLoadingWeaponsList = StateProvider<bool>((ref) => false);
final isWeaponsListDirty = StateProvider<bool>((ref) => false);

/// The raw scan: one entry per source, holding that source's `weapon_data.csv`
/// rows and `.wpn` files, unmerged. Read [weaponListNotifierProvider] for
/// usable weapons. Invalidate this to force a rescan.
final weaponSourcesProvider =
    StreamNotifierProvider<WeaponListNotifier, List<WeaponsCachePayload>>(
      WeaponListNotifier.new,
    );

/// Cached last merge result. Reused when payloads and source order are unchanged.
({List<WeaponsCachePayload> payloads, String key, List<Weapon> weapons})?
_lastMergedWeapons;

/// Weapons built from the merged scan. Calls `mergeWeapons` and builds
/// [Weapon] objects.
final weaponListNotifierProvider = Provider<AsyncValue<List<Weapon>>>((ref) {
  final sources = ref.watch(weaponSourcesProvider);
  final variants = ref
      .watch(AppState.mods)
      .map((mod) => mod.findFirstEnabledOrHighestVersion)
      .nonNulls;
  final orderedSrcs = orderedSources(variants);

  return sources.whenData((payloads) {
    final key = orderedSrcs.map((s) => s.key).join('\n');
    final memo = _lastMergedWeapons;
    if (memo != null && identical(memo.payloads, payloads) && memo.key == key) {
      return memo.weapons;
    }
    final weapons = _buildWeapons(payloads, orderedSrcs);
    _lastMergedWeapons = (payloads: payloads, key: key, weapons: weapons);
    return weapons;
  });
});

/// Weapons keyed by id, rebuilt only when the weapons list changes. Prefer
/// this over building a map from [weaponListNotifierProvider] per widget.
final weaponsByIdProvider = Provider<Map<String, Weapon>>((ref) {
  final weapons =
      ref.watch(weaponListNotifierProvider).valueOrNull ?? const <Weapon>[];
  return {for (final w in weapons) w.id: w};
});

/// `.wpn` field names mapped to friendly area names for the mod-attribution
/// tooltip. Empty value = known but hidden.
const _weaponAreaNames = <String, String>{
  'turretSprite': 'sprites',
  'turretGunSprite': 'sprites',
  'turretUnderSprite': 'sprites',
  'hardpointSprite': 'sprites',
  'hardpointGunSprite': 'sprites',
  'hardpointUnderSprite': 'sprites',
  'turretGlowSprite': 'glow',
  'hardpointGlowSprite': 'glow',
  'glowColor': 'glow',
  'turretOffsets': 'mount positions',
  'hardpointOffsets': 'mount positions',
  'turretAngleOffsets': 'mount positions',
  'hardpointAngleOffsets': 'mount positions',
  'renderHints': 'render hints',
  'specClass': 'spec class',
  'type': 'mount type',
  'mountTypeOverride': 'mount type',
  'size': 'size',
  'damageType': 'damage type',
  'projectileSpecId': 'projectile',
  'id': '',
  'wpnFile': '',
  'loadedMissileSprite': '',
  'loadedMissileSize': '',
  'loadedMissileCenter': '',
};

List<Weapon> _buildWeapons(
  List<WeaponsCachePayload> payloads,
  List<MergeSource> sources,
) {
  if (payloads.isEmpty) return const [];
  final bySourceKey = {for (final payload in payloads) payload.sourceKey: payload};

  final specs = mergeWeapons(
    rows: [
      for (final source in sources)
        if (bySourceKey[source.key] case final payload?)
          (source: source, items: payload.rows),
    ],
    sideFiles: [
      for (final source in sources)
        if (bySourceKey[source.key] case final payload?)
          (source: source, filesByPath: payload.wpnFiles),
    ],
  );

  final weapons = <Weapon>[];
  final failures = LogCollapser();
  for (final spec in specs) {
    final data = <String, dynamic>{...spec.row};

    // Save CSV `type` (damage type) before `.wpn`'s `type` (mount type)
    // overwrites it.
    final csvDamageType = data['type'];

    final side = spec.sideFile;
    String? wpnFilePath;
    if (side != null) {
      final fields = <String, dynamic>{...side};
      wpnFilePath = fields.remove('wpnFile') as String?;
      data.addAll(fields);
      // .wpn files rarely have damageType; fall back to the CSV type column.
      data['damageType'] ??= csvDamageType;
    }

    try {
      weapons.add(
        WeaponMapper.fromMap({
          for (final e in data.entries) e.key.toLowerCase(): e.value,
        })
          ..modVariant = spec.rowSource.variant
          ..spriteModVariant = spec.sideFileSource?.variant
          ..modSources = buildItemModSources(
            rowContributors: spec.rowContributors,
            sideFileContributors: spec.sideFileContributors,
            sideFileChangedKeys: spec.sideFileChangedKeys,
            areaNames: _weaponAreaNames,
          )
          ..csvFile = bySourceKey[spec.rowSource.key]?.csvFilePath?.toFile()
          ..wpnFile = wpnFilePath?.toFile(),
      );
    } catch (e) {
      failures.add('[${spec.rowSource.name}] "${spec.id}": $e');
    }
  }
  failures.flush('Building weapons', noun: 'failure');
  return weapons;
}

/// Renders the current weapon list as CSV, for the export button.
String weaponsAsCsv(List<Weapon> weapons) {
  final fields = weapons.isNotEmpty ? weapons.first.toMap().keys.toList() : [];
  final rows = <List<dynamic>>[
    fields,
    for (final weapon in weapons) weapon.toMap().values.toList(),
  ];
  return const ListToCsvConverter(convertNullTo: "").convert(rows);
}

/// Scans every source for `weapon_data.csv` rows and `.wpn` files and keeps
/// them raw, one payload per source. [weaponListNotifierProvider] merges them.
class WeaponListNotifier
    extends CachedStreamListNotifier<WeaponsCachePayload, WeaponsCachePayload> {
  @override
  String get domain => 'weapons';

  /// 2: the payload holds raw rows and `.wpn` files instead of finished
  /// weapons, so every cached file from before is unreadable.
  @override
  int get schemaVersion => 2;

  @override
  late final CachedVariantStore store =
      CachedVariantStore(domain, Constants.viewerCacheDirPath);

  /// Longer interval because the downstream merge and model rebuild is
  /// expensive.
  @override
  Duration get progressiveYieldInterval => const Duration(seconds: 3);

  /// One payload per source, so nothing is thrown away during the scan. The
  /// merging happens afterwards, in [weaponListNotifierProvider].
  @override
  String itemId(WeaponsCachePayload item) => item.sourceKey;

  @override
  List<WeaponsCachePayload> itemsFromPayload(WeaponsCachePayload payload) => [
    payload,
  ];

  @override
  Directory? get gameCorePath {
    final path = ref.watch(AppState.gameCoreFolder).value?.path;
    return (path == null || path.isEmpty) ? null : Directory(path);
  }

  @override
  String? get currentGameVersion => ref.watch(AppState.starsectorVersion).value;

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
  Future<WeaponsCachePayload?> parseVanilla(
    Directory gameCore,
    List<WeaponsCachePayload> allItemsSoFar,
  ) {
    return _parseOneFolder(gameCore, null);
  }

  @override
  Future<WeaponsCachePayload?> parseVariant(
    ModVariant variant,
    List<WeaponsCachePayload> allItemsSoFar,
  ) {
    return _parseOneFolder(variant.modFolder, variant);
  }

  Future<WeaponsCachePayload?> _parseOneFolder(
    Directory folder,
    ModVariant? modVariant,
  ) async {
    try {
      final result = await _scanWeaponsFolder(folder, modVariant);
      result.errors.forEach(addError);
      result.infos.forEach(addInfo);
      return result.payload;
    } catch (e, st) {
      Fimber.w(
        'Weapon parse failed for ${modVariant?.modInfo.nameOrId ?? kVanillaSourceName}: $e',
        ex: e,
        stacktrace: st,
      );
      return null;
    }
  }

  @override
  Uint8List encodePayload(WeaponsCachePayload payload) {
    return msgpack.serialize(<String, dynamic>{
      'sourceKey': payload.sourceKey,
      'rows': payload.rows,
      'wpnFiles': payload.wpnFiles,
      'csvFilePath': payload.csvFilePath,
    });
  }

  @override
  WeaponsCachePayload decodePayload(Uint8List bytes) {
    final raw = CachedStreamListNotifier.normalizeForMapper(
      msgpack.deserialize(bytes),
    ) as Map<String, dynamic>;

    return WeaponsCachePayload(
      sourceKey: raw['sourceKey'] as String,
      rows: (raw['rows'] as List).cast<Map<String, dynamic>>(),
      wpnFiles: {
        for (final e in (raw['wpnFiles'] as Map).entries)
          e.key.toString(): (e.value as Map).cast<String, dynamic>(),
      },
      csvFilePath: raw['csvFilePath'] as String?,
    );
  }
}

/// One source's raw weapons data, plus the diagnostics from reading it.
class _WeaponScanResult {
  final WeaponsCachePayload? payload;
  final List<String> errors;
  final List<String> infos;

  const _WeaponScanResult(this.payload, this.errors, this.infos);
}

/// Reads one folder's `weapon_data.csv` rows and `.wpn` files. Merging
/// happens in `mergeWeapons` after the full scan completes.
Future<_WeaponScanResult> _scanWeaponsFolder(
  Directory folder,
  ModVariant? modVariant,
) async {
  final errors = <String>[];
  final infos = <String>[];
  final modName = modVariant?.modInfo.nameOrId ?? kVanillaSourceName;
  final sourceKey = modVariant?.smolId ?? kVanillaSourceKey;

  final weaponsCsvFile = p
      .join(folder.path, 'data/weapons/weapon_data.csv')
      .toFile()
      .normalize
      .toFile();

  final wpnFilesDir = Directory(p.join(folder.path, 'data/weapons'));
  if (!await wpnFilesDir.exists()) {
    infos.add('[$modName] No data/weapons folder at ${wpnFilesDir.path}');
    return _WeaponScanResult(null, errors, infos);
  }

  // Index missile projectile specs in this folder so launchers with the
  // RENDER_LOADED_MISSILES hint can show their loaded missiles. Resolved
  // within the weapon's own mod folder (cross-mod projectile references are
  // not handled; those launchers simply won't show missiles).
  final missileSpecs = await _indexMissileSpecs(folder);

  final wpnFiles = <String, Map<String, dynamic>>{};
  for (final wpnFile in wpnFilesDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.wpn'))) {
    try {
      final wpnContent = await wpnFile.readAsString(encoding: utf8);
      final jsonData = await wpnContent
          .removeJsonComments()
          .parseJsonToMapAsync();

      // Omit keys the mod didn't set, so a partial file doesn't blank out
      // fields from another mod during the merge.
      final fields = <String, dynamic>{};
      void put(String key, dynamic value) {
        if (value != null) fields[key] = value;
      }

      put('id', jsonData['id']);
      put('specClass', jsonData['specClass']);
      put('type', jsonData['type']);
      put('mountTypeOverride', jsonData['mountTypeOverride']);
      put('size', jsonData['size']);
      put('damageType', jsonData['damageType']);
      put('turretSprite', _resolveSpritePath(folder, jsonData['turretSprite']));
      put(
        'turretGunSprite',
        _resolveSpritePath(folder, jsonData['turretGunSprite']),
      );
      put(
        'hardpointSprite',
        _resolveSpritePath(folder, jsonData['hardpointSprite']),
      );
      put(
        'hardpointGunSprite',
        _resolveSpritePath(folder, jsonData['hardpointGunSprite']),
      );
      put(
        'turretUnderSprite',
        _resolveSpritePath(folder, jsonData['turretUnderSprite']),
      );
      put(
        'hardpointUnderSprite',
        _resolveSpritePath(folder, jsonData['hardpointUnderSprite']),
      );
      put(
        'turretGlowSprite',
        _resolveSpritePath(folder, jsonData['turretGlowSprite']),
      );
      put(
        'hardpointGlowSprite',
        _resolveSpritePath(folder, jsonData['hardpointGlowSprite']),
      );
      put('glowColor', _toDoubleList(jsonData['glowColor']));
      put('renderHints', _toStringList(jsonData['renderHints']));
      put('projectileSpecId', jsonData['projectileSpecId']);
      put('turretOffsets', _toDoubleList(jsonData['turretOffsets']));
      put('hardpointOffsets', _toDoubleList(jsonData['hardpointOffsets']));
      put('turretAngleOffsets', _toDoubleList(jsonData['turretAngleOffsets']));
      put(
        'hardpointAngleOffsets',
        _toDoubleList(jsonData['hardpointAngleOffsets']),
      );
      put('wpnFile', wpnFile.path);

      if (jsonData['id'] == null) {
        errors.add('[$modName] .wpn file ${wpnFile.path} missing "id" field');
        continue;
      }

      // Resolve loaded-missile render data for launchers.
      final hints = (fields['renderHints'] as List<String>?) ?? const [];
      final projId = jsonData['projectileSpecId'] as String?;
      if (projId != null &&
          hints.any((h) => h.toUpperCase().contains('RENDER_LOADED_MISSILES'))) {
        final missile = missileSpecs[projId];
        if (missile != null) {
          put('loadedMissileSprite', missile.sprite);
          put('loadedMissileSize', missile.size);
          put('loadedMissileCenter', missile.center);
        }
      }

      // Keyed on path relative to data/weapons (not on the id inside).
      wpnFiles[p.basename(wpnFile.path)] = fields;
    } catch (e) {
      errors.add('[$modName] Failed to parse .wpn file ${wpnFile.path}: $e');
    }
  }

  final rows = <Map<String, dynamic>>[];
  if (!await weaponsCsvFile.exists()) {
    infos.add('[$modName] Weapons CSV file not found at $weaponsCsvFile');
  } else {
    String content;
    try {
      content = await weaponsCsvFile.readAsStringUtf8OrLatin1();
    } catch (e) {
      errors.add('[$modName] Failed to read file at $weaponsCsvFile: $e');
      content = '';
    }

    if (content.isNotEmpty) {
      // Strip `#` comments (quote-aware, multi-line safe) and track lines.
      final stripped = content.stripCsvCommentsAndTrackLines();

      List<List<dynamic>> csvRows;
      try {
        csvRows = const CsvToListConverter(
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(stripped.cleanContent);
      } catch (e) {
        errors.add('[$modName] Failed to parse CSV in $weaponsCsvFile: $e');
        csvRows = const [];
      }

      if (csvRows.isEmpty) {
        errors.add('[$modName] Empty weapons CSV file at $weaponsCsvFile');
      } else {
        final headers = csvRows.first
            .map((e) => e.toString().trim().toLowerCase())
            .toList();
        for (var i = 1; i < csvRows.length; i++) {
          rows.add(_typedRow(csvRows[i], headers));
        }
      }
    }
  }

  if (rows.isEmpty && wpnFiles.isEmpty) {
    return _WeaponScanResult(null, errors, infos);
  }

  return _WeaponScanResult(
    WeaponsCachePayload(
      sourceKey: sourceKey,
      rows: rows,
      wpnFiles: wpnFiles,
      csvFilePath: await weaponsCsvFile.exists() ? weaponsCsvFile.path : null,
    ),
    errors,
    infos,
  );
}

/// Turns one CSV line into a map, coercing `TRUE`/`FALSE` and numbers the way
/// the viewers expect. Blank cells become null.
Map<String, dynamic> _typedRow(List<dynamic> row, List<String> headers) {
  final data = <String, dynamic>{};
  for (var j = 0; j < headers.length; j++) {
    dynamic value = row.length > j ? row[j] : null;

    if (value == null || (value is String && value.trim().isEmpty)) {
      data[headers[j]] = null;
      continue;
    }

    if (value.toString().toUpperCase() == 'TRUE') {
      value = true;
    } else if (value.toString().toUpperCase() == 'FALSE') {
      value = false;
    } else {
      value = num.tryParse(value.toString()) ?? value.toString();
    }

    data[headers[j]] = value;
  }
  return data;
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
