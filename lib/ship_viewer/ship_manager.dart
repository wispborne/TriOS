import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/models/ship_skin.dart';
import 'package:trios/ship_viewer/models/ship_variant.dart';
import 'package:trios/ship_viewer/models/ship_weapon_slot.dart';
import 'package:trios/ship_viewer/models/ships_cache_payload.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/utils/log_collapser.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/cached_stream_list_notifier.dart';
import 'package:trios/viewer_cache/cached_variant_store.dart';

final isLoadingShipsList = StateProvider<bool>((ref) => false);
final isShipsListDirty = StateProvider<bool>((ref) => false);

/// Variants that define station modules, keyed by variant ID.
/// Populated as a side-effect of ship list parsing.
final moduleVariantsProvider = StateProvider<Map<String, ShipVariant>>(
  (ref) => {},
);

/// Lightweight map of ALL variant IDs to their hull IDs.
/// Used to resolve module variant ID → hull ID lookups.
final variantHullIdMapProvider = StateProvider<Map<String, String>>((ref) => {});

/// The raw scan: one entry per source, holding that source's `ship_data.csv`
/// rows, `.ship` files and `.skin` files, unmerged. Read
/// [shipListNotifierProvider] for usable ships. Invalidate this to rescan.
final shipSourcesProvider =
    StreamNotifierProvider<ShipListNotifier, List<ShipsCachePayload>>(
      ShipListNotifier.new,
    );

/// Cached last merge result. Reused when payloads and source order are unchanged.
({List<ShipsCachePayload> payloads, String key, List<Ship> ships})? _lastMergedShips;

/// Ships built from the merged scan. Calls `mergeShips`, builds [Ship] objects,
/// and resolves skins.
final shipListNotifierProvider = Provider<AsyncValue<List<Ship>>>((ref) {
  final sources = ref.watch(shipSourcesProvider);
  final variants = ref
      .watch(AppState.mods)
      .map((mod) => mod.findFirstEnabledOrHighestVersion)
      .nonNulls;
  final orderedSrcs = orderedSources(variants);

  return sources.whenData((payloads) {
    final key = orderedSrcs.map((s) => s.key).join('\n');
    final memo = _lastMergedShips;
    if (memo != null && identical(memo.payloads, payloads) && memo.key == key) {
      return memo.ships;
    }
    final ships = _buildShips(payloads, orderedSrcs);
    _lastMergedShips = (payloads: payloads, key: key, ships: ships);
    return ships;
  });
});

/// `.ship`/`.skin` field names mapped to friendly area names for the
/// mod-attribution tooltip. Empty value = known but hidden.
const _shipAreaNames = <String, String>{
  'spriteName': 'sprite',
  'style': 'style',
  'hullName': 'name',
  'hullSize': 'hull size',
  'weaponSlots': 'weapon slots',
  'engineSlots': 'engines',
  'builtInMods': 'built-in hullmods',
  'builtInWeapons': 'built-in weapons',
  'builtInWings': 'built-in wings',
  'bounds': 'outline',
  'shieldCenter': 'shield',
  'shieldRadius': 'shield',
  'center': 'center point',
  'collisionRadius': 'collision size',
  'width': 'size',
  'height': 'size',
  'viewOffset': 'view offset',
  'moduleAnchor': 'module anchor',
  'hullId': '',
  'spriteFile': '',
  '_dataFile': '',
};

List<Ship> _buildShips(
  List<ShipsCachePayload> payloads,
  List<MergeSource> sources,
) {
  if (payloads.isEmpty) return const [];
  final bySourceKey = {for (final payload in payloads) payload.sourceKey: payload};

  final specs = mergeShips(
    rows: [
      for (final source in sources)
        if (bySourceKey[source.key] case final payload?)
          (source: source, items: payload.rows),
    ],
    sideFiles: [
      for (final source in sources)
        if (bySourceKey[source.key] case final payload?)
          (source: source, filesByPath: payload.shipFiles),
    ],
  );

  final ships = <Ship>[];
  final failures = LogCollapser();
  for (final spec in specs) {
    final ship = _buildHull(
      spec,
      bySourceKey[spec.rowSource.key]?.csvFilePath?.toFile(),
      failures,
    );
    if (ship != null) ships.add(ship);
  }

  ships.addAll(
    _resolveSkins(
      mergeShipSkins([
        for (final source in sources)
          if (bySourceKey[source.key] case final payload?)
            (source: source, filesByPath: payload.skinFiles),
      ]),
      ships,
      failures,
    ),
  );

  failures.flush('Building ships', noun: 'failure');
  return ships;
}

/// Turns one merged CSV row plus its merged `.ship` file into a [Ship].
///
/// A row with no `.ship` file is kept with no hull geometry (the game drops
/// such rows; TriOS keeps them so the problem is visible).
Ship? _buildHull(MergedSpec spec, File? csvFile, LogCollapser failures) {
  final data = <String, dynamic>{...spec.row};
  File? dataFile;

  final side = spec.sideFile;
  if (side != null) {
    final fields = <String, dynamic>{...side};
    dataFile = (fields.remove('_dataFile') as String?)?.toFile();

    final rawSlots = fields.remove('weaponSlots');
    if (rawSlots is List) {
      data['weaponSlots'] = rawSlots
          .map((e) => ShipWeaponSlotMapper.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    data.addAll(fields);
  }

  try {
    return ShipMapper.fromMap({
      for (final e in data.entries) e.key.toLowerCase(): e.value,
    })
      ..modVariant = spec.rowSource.variant
      ..spriteModVariant = spec.sideFileSource?.variant
      ..modSources = buildItemModSources(
        rowContributors: spec.rowContributors,
        sideFileContributors: spec.sideFileContributors,
        sideFileChangedKeys: spec.sideFileChangedKeys,
        areaNames: _shipAreaNames,
      )
      ..csvFile = csvFile
      ..dataFile = dataFile;
  } catch (e) {
    failures.add('[${spec.rowSource.name}] "${spec.id}": $e');
    return null;
  }
}

/// Resolves every merged `.skin` file against its base hull.
///
/// Skins can layer on other skins, so this loops until a pass resolves nothing
/// new.
List<Ship> _resolveSkins(
  Map<String, DeepMergeResult> mergedSkins,
  List<Ship> baseShips,
  LogCollapser failures,
) {
  final available = {for (final ship in baseShips) ship.id: ship};
  final resolved = <Ship>[];
  var pending = mergedSkins.entries.toList();

  while (pending.isNotEmpty) {
    final stillPending = <MapEntry<String, DeepMergeResult>>[];

    for (final entry in pending) {
      final fields = <String, dynamic>{...entry.value.merged};
      final spriteFile = fields.remove('_spriteFile') as String?;
      final dataFile = fields.remove('_dataFile') as String?;

      final ShipSkin skin;
      try {
        skin = ShipSkinMapper.fromMap(fields);
      } catch (e) {
        failures.add('skin "${entry.key}": $e');
        continue;
      }

      final baseHull = available[skin.baseHullId];
      if (baseHull == null) {
        stillPending.add(entry);
        continue;
      }

      final ship = _resolveSkin(
        skin,
        baseHull,
        spriteFile,
        entry.value.winningSource?.variant,
      )
        ..modSources = buildItemModSources(
          rowContributors: const [],
          sideFileContributors: entry.value.contributors,
          sideFileChangedKeys: entry.value.topLevelKeysBySource(),
          areaNames: _shipAreaNames,
          hasStatsRow: false,
        )
        ..csvFile = baseHull.csvFile
        ..dataFile = dataFile?.toFile();
      resolved.add(ship);
      // A resolved skin can itself be another skin's base hull.
      available[ship.id] = ship;
    }

    // Nothing moved this pass, so the rest have base hulls that don't exist.
    if (stillPending.length == pending.length) {
      for (final entry in stillPending) {
        failures.add(
          'skin "${entry.key}": base hull '
          '"${entry.value.merged['baseHullId']}" not found in any mod.',
        );
      }
      break;
    }
    pending = stillPending;
  }

  return resolved;
}

/// Renders the current ship list as CSV, for the export button.
String shipsAsCsv(List<Ship> ships) {
  final fields = ships.isNotEmpty ? ships.first.toMap().keys.toList() : [];
  final rows = <List<dynamic>>[
    fields,
    for (final ship in ships) ship.toMap().values.toList(),
  ];
  return const ListToCsvConverter(convertNullTo: "").convert(rows);
}

/// Scans every source for `ship_data.csv` rows, `.ship` files and `.skin`
/// files and keeps them raw, one payload per source.
/// [shipListNotifierProvider] merges them.
class ShipListNotifier
    extends CachedStreamListNotifier<ShipsCachePayload, ShipsCachePayload> {
  @override
  String get domain => 'ships';

  /// 2: the payload holds raw rows and side files instead of finished ships,
  /// so every cached file from before is unreadable.
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
  /// merging happens afterwards, in [shipListNotifierProvider].
  @override
  String itemId(ShipsCachePayload item) => item.sourceKey;

  @override
  List<ShipsCachePayload> itemsFromPayload(ShipsCachePayload payload) => [
    payload,
  ];

  /// `.variant` files are parsed in a distinct pass from `.ship`/`.skin`
  /// files; their errors get their own log group so they're easier to spot.
  final List<String> _pendingVariantErrors = [];

  @override
  Directory? get gameCorePath {
    final path = ref.watch(AppState.gameCoreFolder).value?.path;
    return (path == null || path.isEmpty) ? null : Directory(path);
  }

  @override
  String? get currentGameVersion => ref.watch(AppState.starsectorVersion).value;

  @override
  void onBuildStart() {
    ref.read(isLoadingShipsList.notifier).state = true;
    ref.listen(AppState.smolIds, (previous, next) {
      ref.read(isShipsListDirty.notifier).state = true;
    });
    _pendingVariantErrors.clear();
  }

  @override
  void onBuildComplete({required bool fullScanCompleted}) {
    ref.read(isLoadingShipsList.notifier).state = false;
    if (fullScanCompleted) {
      ref.read(isShipsListDirty.notifier).state = false;
    }
    super.onBuildComplete(fullScanCompleted: fullScanCompleted);
    if (_pendingVariantErrors.isNotEmpty) {
      Fimber.w(
        '[ships] .variant parsing errors:\n${_pendingVariantErrors.join('\n')}',
      );
    }
  }

  @override
  Future<bool> awaitReadiness() async {
    // Wait for modVariants to resolve on startup without watching it to avoid
    // re-triggering this entire stream on every mod version switch, which
    // caused cascading widget rebuilds in the pre-cache implementation.
    if (!ref.read(AppState.modVariants).hasValue) {
      final completer = Completer<void>();
      ref.listen(AppState.modVariants, (prev, next) {
        if (next.hasValue && !completer.isCompleted) completer.complete();
      });
      await completer.future;
    }
    return true;
  }

  @override
  void onCacheLoadComplete(Map<String, ShipsCachePayload> cachedPayloads) {
    _publishModuleData(cachedPayloads);
  }

  @override
  void onFullScanComplete(Map<String, ShipsCachePayload> allPayloads) {
    _publishModuleData(allPayloads);
  }

  void _publishModuleData(Map<String, ShipsCachePayload> payloads) {
    final allModuleVariants = <String, ShipVariant>{};
    final allHullIdMap = <String, String>{};
    for (final payload in payloads.values) {
      allModuleVariants.addAll(payload.moduleVariants);
      allHullIdMap.addAll(payload.hullIdMap);
    }
    ref.read(moduleVariantsProvider.notifier).state = allModuleVariants;
    ref.read(variantHullIdMapProvider.notifier).state = allHullIdMap;
  }

  @override
  Future<ShipsCachePayload?> parseVanilla(
    Directory gameCore,
    List<ShipsCachePayload> allItemsSoFar,
  ) async {
    return _parseOneFolder(gameCore, null);
  }

  @override
  Future<ShipsCachePayload?> parseVariant(
    ModVariant variant,
    List<ShipsCachePayload> allItemsSoFar,
  ) async {
    return _parseOneFolder(variant.modFolder, variant);
  }

  Future<ShipsCachePayload?> _parseOneFolder(
    Directory folder,
    ModVariant? modVariant,
  ) async {
    try {
      final scan = await _scanShipsFolder(folder, modVariant);
      scan.errors.forEach(addError);
      scan.infos.forEach(addInfo);

      final variantErrors = <String>[];
      final variantResult = await _parseVariants(
        folder,
        modVariant,
        variantErrors,
      );
      _pendingVariantErrors.addAll(variantErrors);

      if (scan.rows.isEmpty &&
          scan.shipFiles.isEmpty &&
          scan.skinFiles.isEmpty &&
          variantResult.moduleVariants.isEmpty &&
          variantResult.hullIdMap.isEmpty) {
        return null;
      }

      return ShipsCachePayload(
        sourceKey: modVariant?.smolId ?? kVanillaSourceKey,
        rows: scan.rows,
        shipFiles: scan.shipFiles,
        skinFiles: scan.skinFiles,
        csvFilePath: scan.csvFilePath,
        moduleVariants: variantResult.moduleVariants,
        hullIdMap: variantResult.hullIdMap,
      );
    } catch (e, st) {
      Fimber.w(
        'Ship parse failed for ${modVariant?.modInfo.nameOrId ?? kVanillaSourceName}: $e',
        ex: e,
        stacktrace: st,
      );
      return null;
    }
  }

  @override
  Uint8List encodePayload(ShipsCachePayload payload) {
    return msgpack.serialize(<String, dynamic>{
      'sourceKey': payload.sourceKey,
      'rows': payload.rows,
      'shipFiles': payload.shipFiles,
      'skinFiles': payload.skinFiles,
      'csvFilePath': payload.csvFilePath,
      'moduleVariants': payload.moduleVariants.map(
        (k, v) => MapEntry(k, v.toMap()),
      ),
      'hullIdMap': payload.hullIdMap,
    });
  }

  @override
  ShipsCachePayload decodePayload(Uint8List bytes) {
    final raw = CachedStreamListNotifier.normalizeForMapper(
      msgpack.deserialize(bytes),
    ) as Map<String, dynamic>;

    Map<String, Map<String, dynamic>> filesFrom(String key) => {
      for (final e in (raw[key] as Map).entries)
        e.key.toString(): (e.value as Map).cast<String, dynamic>(),
    };

    final moduleVariants = <String, ShipVariant>{};
    (raw['moduleVariants'] as Map<String, dynamic>).forEach((k, v) {
      moduleVariants[k] = ShipVariantMapper.fromMap(v as Map<String, dynamic>);
    });

    final hullIdMap = <String, String>{};
    (raw['hullIdMap'] as Map<String, dynamic>).forEach((k, v) {
      hullIdMap[k] = v.toString();
    });

    return ShipsCachePayload(
      sourceKey: raw['sourceKey'] as String,
      rows: (raw['rows'] as List).cast<Map<String, dynamic>>(),
      shipFiles: filesFrom('shipFiles'),
      skinFiles: filesFrom('skinFiles'),
      csvFilePath: raw['csvFilePath'] as String?,
      moduleVariants: moduleVariants,
      hullIdMap: hullIdMap,
    );
  }

  /// Parse `.variant` files from `data/variants/`.
  ///
  /// Returns [_VariantParseResult] containing:
  /// - module variants (those with a `modules` field), keyed by variant ID
  /// - a lightweight map of ALL variant IDs → hull IDs (for resolving
  ///   module variant → hull lookups)
  Future<_VariantParseResult> _parseVariants(
    Directory folder,
    ModVariant? modVariant,
    List<String> errors,
  ) async {
    final variantsDir = Directory(p.join(folder.path, 'data/variants'));
    final moduleVariants = <String, ShipVariant>{};
    final hullIdMap = <String, String>{};
    final modName = modVariant?.modInfo.nameOrId ?? kVanillaSourceName;

    if (!await variantsDir.exists()) {
      return _VariantParseResult(moduleVariants, hullIdMap);
    }

    final variantFiles = await variantsDir
        .list(recursive: true)
        .where((e) => e is File && e.path.endsWith('.variant'))
        .cast<File>()
        .toList();

    for (final file in variantFiles) {
      try {
        final raw = await file.readAsString(encoding: utf8);
        final cleaned = raw.removeJsonComments();
        final map = await cleaned.parseJsonToMapAsync();

        final variantId = map['variantId'] as String?;
        final hullId = map['hullId'] as String?;
        if (variantId == null || hullId == null) continue;

        // Always record the variantId → hullId mapping.
        hullIdMap[variantId] = hullId;

        // Only create full ShipVariant objects for variants with modules.
        // Modules in .variant files are a List<Map> of single-entry objects:
        //   [{"WS0017": "module_variant_id"}, {"WS0018": "other_variant"}]
        // Flatten into a single Map<String, String> for the model.
        final modulesRaw = map['modules'];
        if (modulesRaw == null || modulesRaw is! List || modulesRaw.isEmpty) {
          continue;
        }

        final flatModules = <String, String>{};
        for (final entry in modulesRaw) {
          if (entry is Map) {
            for (final kv in entry.entries) {
              flatModules[kv.key.toString()] = kv.value.toString();
            }
          }
        }
        if (flatModules.isEmpty) continue;

        map['modules'] = flatModules;

        final variant = ShipVariantMapper.fromMap(map);
        moduleVariants[variant.variantId] = variant;
      } catch (e) {
        errors.add('[$modName] Failed to parse .variant file ${file.path}: $e');
      }
    }

    return _VariantParseResult(moduleVariants, hullIdMap);
  }
}

/// One source's raw ships data, plus the diagnostics from reading it.
class _ShipScanResult {
  final List<Map<String, dynamic>> rows;
  final Map<String, Map<String, dynamic>> shipFiles;
  final Map<String, Map<String, dynamic>> skinFiles;
  final String? csvFilePath;
  final List<String> errors;
  final List<String> infos;

  const _ShipScanResult({
    required this.rows,
    required this.shipFiles,
    required this.skinFiles,
    required this.csvFilePath,
    required this.errors,
    required this.infos,
  });
}

/// Reads one folder's `ship_data.csv` rows, `.ship` files and `.skin` files.
/// Merging and pairing happen after the full scan completes.
Future<_ShipScanResult> _scanShipsFolder(
  Directory folder,
  ModVariant? modVariant,
) async {
  final errors = <String>[];
  final infos = <String>[];
  final modName = modVariant?.modInfo.nameOrId ?? kVanillaSourceName;

  final shipFiles = <String, Map<String, dynamic>>{};
  final hullsDir = Directory(p.join(folder.path, 'data/hulls'));
  if (await hullsDir.exists()) {
    for (final shipFile in hullsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.ship'))) {
      try {
        final raw = await shipFile.readAsString(encoding: utf8);
        final map = await raw.removeJsonComments().parseJsonToMapAsync();
        if (map['hullId'] == null) {
          errors.add('[$modName] .ship file ${shipFile.path} missing "hullId"');
          continue;
        }
        final spriteName = map['spriteName'] as String?;
        if (spriteName != null) {
          map['spriteFile'] = p
              .join(folder.path, spriteName)
              .toFile()
              .normalize
              .path;
        }
        // Underscored so it can't collide with a real field name from the
        // file; stripped again before the Ship is built.
        map['_dataFile'] = shipFile.path;
        map.removeWhere((_, value) => value == null);
        shipFiles[p.basename(shipFile.path)] = map;
      } catch (e) {
        errors.add('[$modName] Failed to parse .ship file ${shipFile.path}: $e');
      }
    }
  }

  final skinFiles = <String, Map<String, dynamic>>{};
  final skinsDir = Directory(p.join(folder.path, 'data/hulls/skins'));
  if (await skinsDir.exists()) {
    for (final skinFile in skinsDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.skin'))) {
      try {
        final raw = await skinFile.readAsString(encoding: utf8);
        final map = await raw.removeJsonComments().parseJsonToMapAsync();
        final spriteName = map['spriteName'] as String?;
        if (spriteName != null) {
          map['_spriteFile'] = p
              .join(folder.path, spriteName)
              .toFile()
              .normalize
              .path;
        }
        map['_dataFile'] = skinFile.path;
        map.removeWhere((_, value) => value == null);
        skinFiles[p
            .relative(skinFile.path, from: skinsDir.path)
            .replaceAll('\\', '/')] = map;
      } catch (e) {
        errors.add('[$modName] Failed to parse .skin file ${skinFile.path}: $e');
      }
    }
  }

  final rows = <Map<String, dynamic>>[];
  final shipsCsvFile = p
      .join(folder.path, 'data/hulls/ship_data.csv')
      .toFile()
      .normalize
      .toFile();
  final hasCsv = await shipsCsvFile.exists();

  if (!hasCsv) {
    infos.add('[$modName] Ship CSV file not found at $shipsCsvFile');
  } else {
    String content;
    try {
      content = await shipsCsvFile.readAsStringUtf8OrLatin1();
    } catch (e) {
      errors.add('[$modName] Failed to read ship_data.csv: $e');
      content = '';
    }

    if (content.isNotEmpty) {
      // Strip `#` comments (quote-aware, multi-line safe).
      final stripped = content.stripCsvCommentsAndTrackLines();

      List<List<dynamic>> csvRows;
      try {
        csvRows = const CsvToListConverter(
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(stripped.cleanContent);
      } catch (e) {
        errors.add('[$modName] Failed to parse CSV: $e');
        csvRows = const [];
      }

      if (csvRows.isEmpty) {
        errors.add('[$modName] Empty ship_data.csv');
      } else {
        final headers = csvRows.first
            .map((e) => e.toString().trim().toLowerCase())
            .toList();
        for (var i = 1; i < csvRows.length; i++) {
          final data = <String, dynamic>{};
          for (var j = 0; j < headers.length; j++) {
            dynamic value = csvRows[i].length > j ? csvRows[i][j] : null;

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
          rows.add(data);
        }
      }
    }
  }

  return _ShipScanResult(
    rows: rows,
    shipFiles: shipFiles,
    skinFiles: skinFiles,
    csvFilePath: hasCsv ? shipsCsvFile.path : null,
    errors: errors,
    infos: infos,
  );
}

/// Resolve a [ShipSkin] against its [baseHull] to produce a complete [Ship].
Ship _resolveSkin(
  ShipSkin skin,
  Ship baseHull,
  String? spriteFile,
  ModVariant? modVariant,
) {
  // Built-in mods: remove then add
  final builtInMods = List<String>.from(baseHull.builtInMods ?? []);
  if (skin.removeBuiltInMods != null) {
    builtInMods.removeWhere(skin.removeBuiltInMods!.contains);
  }
  if (skin.builtInMods != null) {
    builtInMods.addAll(skin.builtInMods!);
  }

  // Built-in weapons: remove then add
  final builtInWeapons = Map<String, String>.from(
    baseHull.builtInWeapons ?? {},
  );
  if (skin.removeBuiltInWeapons != null) {
    builtInWeapons.removeWhere((k, _) => skin.removeBuiltInWeapons!.contains(k));
  }
  if (skin.builtInWeapons != null) {
    builtInWeapons.addAll(skin.builtInWeapons!);
  }

  // Weapon slots: remove by ID
  var weaponSlots = baseHull.weaponSlots;
  if (skin.removeWeaponSlots != null &&
      skin.removeWeaponSlots!.isNotEmpty &&
      weaponSlots != null) {
    weaponSlots = weaponSlots
        .where((s) => !skin.removeWeaponSlots!.contains(s.id))
        .toList();
  }

  // Weapon slots: apply per-slot field overrides
  if (skin.weaponSlotChanges != null &&
      skin.weaponSlotChanges!.isNotEmpty &&
      weaponSlots != null) {
    weaponSlots = weaponSlots.map((slot) {
      final changes = skin.weaponSlotChanges![slot.id];
      if (changes == null || changes is! Map<String, dynamic>) return slot;
      return ShipWeaponSlot(
        id: slot.id,
        angle: (changes['angle'] as num?)?.toDouble() ?? slot.angle,
        arc: (changes['arc'] as num?)?.toDouble() ?? slot.arc,
        mount: changes['mount'] as String? ?? slot.mount,
        size: changes['size'] as String? ?? slot.size,
        type: changes['type'] as String? ?? slot.type,
        locations: slot.locations,
        position: slot.position,
        renderOrderMod: slot.renderOrderMod,
      );
    }).toList();
  }

  // Hints: remove then add
  final hints = List<String>.from(baseHull.hints ?? []);
  if (skin.removeHints != null) {
    hints.removeWhere(skin.removeHints!.contains);
  }
  if (skin.addHints != null) {
    hints.addAll(skin.addHints!);
  }

  // Tags: override if skin specifies, otherwise inherit
  final tags = skin.tags ?? baseHull.tags;

  // Base value: apply multiplier if specified
  double? baseValue = skin.baseValue?.toDouble() ?? baseHull.baseValue;
  if (skin.baseValueMult != null && baseValue != null) {
    baseValue = baseValue * skin.baseValueMult!;
  }

  // Engine slots: remove by index, then apply per-slot overrides
  var engineSlots = baseHull.engineSlots != null
      ? List<dynamic>.from(baseHull.engineSlots!)
      : null;
  if (skin.removeEngineSlots != null &&
      skin.removeEngineSlots!.isNotEmpty &&
      engineSlots != null) {
    final toRemove = skin.removeEngineSlots!
        .where((i) => i >= 0 && i < engineSlots.length)
        .map((i) => engineSlots[i])
        .toList();
    engineSlots.removeWhere(toRemove.contains);
  }
  if (skin.engineSlotChanges != null &&
      skin.engineSlotChanges!.isNotEmpty &&
      engineSlots != null) {
    for (final entry in skin.engineSlotChanges!.entries) {
      final index = int.tryParse(entry.key);
      if (index == null || index < 0 || index >= engineSlots.length) continue;
      final changes = entry.value;
      if (changes is! Map<String, dynamic>) continue;
      final original = engineSlots[index];
      if (original is Map<String, dynamic>) {
        engineSlots[index] = {...original, ...changes};
      }
    }
  }

  return Ship(
    id: skin.skinHullId,
    isSkin: true,
    baseHullId: skin.baseHullId,
    name: skin.hullName ?? baseHull.name,
    designation: skin.hullDesignation ?? baseHull.designation,
    techManufacturer:
        skin.manufacturer ?? skin.tech ?? baseHull.techManufacturer,
    systemId: skin.systemId ?? baseHull.systemId,
    fleetPts: _resolveFleetPts(baseHull.fleetPts, skin.fleetPoints, skin.fpMod),
    hitpoints: baseHull.hitpoints,
    armorRating: baseHull.armorRating,
    maxFlux: baseHull.maxFlux,
    fluxDissipation: baseHull.fluxDissipation,
    ordnancePoints: skin.ordnancePoints?.toDouble() ?? baseHull.ordnancePoints,
    fighterBays: skin.fighterBays?.toDouble() ?? baseHull.fighterBays,
    maxSpeed: baseHull.maxSpeed,
    acceleration: baseHull.acceleration,
    deceleration: baseHull.deceleration,
    maxTurnRate: baseHull.maxTurnRate,
    turnAcceleration: baseHull.turnAcceleration,
    mass: baseHull.mass,
    shieldType: baseHull.shieldType,
    defenseId: baseHull.defenseId,
    shieldArc: baseHull.shieldArc,
    shieldUpkeep: baseHull.shieldUpkeep,
    shieldEfficiency: baseHull.shieldEfficiency,
    phaseCost: baseHull.phaseCost,
    phaseUpkeep: baseHull.phaseUpkeep,
    minCrew: baseHull.minCrew,
    maxCrew: baseHull.maxCrew,
    cargo: baseHull.cargo,
    fuel: baseHull.fuel,
    fuelPerLY: baseHull.fuelPerLY,
    range: baseHull.range,
    maxBurn: baseHull.maxBurn,
    baseValue: baseValue,
    crPercentPerDay: baseHull.crPercentPerDay,
    crToDeploy: baseHull.crToDeploy,
    peakCrSec: baseHull.peakCrSec,
    crLossPerSec: baseHull.crLossPerSec,
    suppliesRec: skin.suppliesToRecover?.toDouble() ?? baseHull.suppliesRec,
    suppliesMo: baseHull.suppliesMo,
    hints: hints,
    tags: tags,
    rarity: baseHull.rarity,
    breakProb: baseHull.breakProb,
    minPieces: baseHull.minPieces,
    maxPieces: baseHull.maxPieces,
    travelDrive: baseHull.travelDrive,
    bounds: baseHull.bounds,
    center: baseHull.center,
    collisionRadius: baseHull.collisionRadius,
    height: baseHull.height,
    width: baseHull.width,
    hullSize: baseHull.hullSize,
    shieldCenter: baseHull.shieldCenter,
    shieldRadius: baseHull.shieldRadius,
    spriteName: skin.spriteName ?? baseHull.spriteName,
    spriteFile: spriteFile ?? baseHull.spriteFile,
    style: baseHull.style,
    viewOffset: baseHull.viewOffset,
    engineSlots: engineSlots,
    weaponSlots: weaponSlots,
    builtInWeapons: builtInWeapons,
    builtInMods: builtInMods,
    builtInWings: skin.builtInWings ?? baseHull.builtInWings,
    moduleAnchor: baseHull.moduleAnchor,
  )
    ..modVariant = modVariant ?? baseHull.modVariant
    ..spriteModVariant = modVariant ?? baseHull.spriteModVariant;
}

/// Resolves fleet points from skin overrides.
/// [fleetPoints] replaces the base value outright; [fpMod] is additive.
double? _resolveFleetPts(double? baseFp, num? fleetPoints, num? fpMod) {
  final fp = fleetPoints?.toDouble() ?? baseFp;
  if (fp == null) return null;
  return fpMod != null ? fp + fpMod.toDouble() : fp;
}

class _VariantParseResult {
  final Map<String, ShipVariant> moduleVariants;
  final Map<String, String> hullIdMap;

  _VariantParseResult(this.moduleVariants, this.hullIdMap);
}
