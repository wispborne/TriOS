import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/ship_viewer/models/ship_gpt.dart';
import 'package:trios/ship_viewer/models/ship_skin.dart';
import 'package:trios/ship_viewer/models/ship_variant.dart';
import 'package:trios/ship_viewer/models/ship_weapon_slot.dart';
import 'package:trios/ship_viewer/models/ships_cache_payload.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/cached_stream_list_notifier.dart';
import 'package:trios/viewer_cache/cached_variant_store.dart';

final isLoadingShipsList = StateProvider<bool>((ref) => false);
final isShipsListDirty = StateProvider<bool>((ref) => false);

/// Variants that define station modules, keyed by variant ID.
/// Populated as a side-effect of ship list parsing.
final moduleVariantsProvider =
    StateProvider<Map<String, ShipVariant>>((ref) => {});

/// Lightweight map of ALL variant IDs to their hull IDs.
/// Used to resolve module variant ID → hull ID lookups.
final variantHullIdMapProvider =
    StateProvider<Map<String, String>>((ref) => {});

final shipListNotifierProvider =
    StreamNotifierProvider<ShipListNotifier, List<Ship>>(ShipListNotifier.new);

class ShipListNotifier
    extends CachedStreamListNotifier<Ship, ShipsCachePayload> {
  @override
  String get domain => 'ships';

  @override
  int get schemaVersion => 1;

  @override
  late final CachedVariantStore store =
      CachedVariantStore(domain, Constants.viewerCacheDirPath);

  @override
  String itemId(Ship item) => item.id;

  @override
  List<Ship> itemsFromPayload(ShipsCachePayload payload) => payload.ships;

  @override
  bool get providesItemContext => true;

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
  List<ModVariant> resolveEnabledVariants() {
    return ref
        .read(AppState.mods)
        .map((mod) => mod.findFirstEnabledOrHighestVersion)
        .nonNulls
        .toList();
  }

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
  void rehydratePayload(
    ShipsCachePayload payload,
    ModVariant? sourceVariant,
  ) {
    for (final ship in payload.ships) {
      ship.modVariant = sourceVariant;
    }
  }

  @override
  void onFullScanComplete(Map<String, ShipsCachePayload> allPayloads) {
    final allModuleVariants = <String, ShipVariant>{};
    final allHullIdMap = <String, String>{};
    for (final payload in allPayloads.values) {
      allModuleVariants.addAll(payload.moduleVariants);
      allHullIdMap.addAll(payload.hullIdMap);
    }
    ref.read(moduleVariantsProvider.notifier).state = allModuleVariants;
    ref.read(variantHullIdMapProvider.notifier).state = allHullIdMap;
  }

  @override
  Future<ShipsCachePayload?> parseVanilla(
    Directory gameCore,
    List<Ship> allItemsSoFar,
  ) async {
    return _parseOneFolder(gameCore, null, allItemsSoFar);
  }

  @override
  Future<ShipsCachePayload?> parseVariant(
    ModVariant variant,
    List<Ship> allItemsSoFar,
  ) async {
    return _parseOneFolder(variant.modFolder, variant, allItemsSoFar);
  }

  Future<ShipsCachePayload?> _parseOneFolder(
    Directory folder,
    ModVariant? modVariant,
    List<Ship> allItemsSoFar,
  ) async {
    try {
      final shipResult = await _parseShips(folder, modVariant, allItemsSoFar);
      shipResult.errors.forEach(addError);
      shipResult.infos.forEach(addInfo);

      final variantErrors = <String>[];
      final variantResult = await _parseVariants(
        folder,
        modVariant,
        variantErrors,
      );
      _pendingVariantErrors.addAll(variantErrors);

      return ShipsCachePayload(
        ships: shipResult.ships,
        moduleVariants: variantResult.moduleVariants,
        hullIdMap: variantResult.hullIdMap,
      );
    } catch (e, st) {
      Fimber.w(
        'Ship parse failed for ${modVariant?.modInfo.nameOrId ?? 'Vanilla'}: $e',
        ex: e,
        stacktrace: st,
      );
      return null;
    }
  }

  @override
  Uint8List encodePayload(ShipsCachePayload payload) {
    final map = <String, dynamic>{
      'ships': payload.ships.map((s) => s.toMap()).toList(),
      'moduleVariants': payload.moduleVariants.map(
        (k, v) => MapEntry(k, v.toMap()),
      ),
      'hullIdMap': payload.hullIdMap,
    };
    return msgpack.serialize(map);
  }

  @override
  ShipsCachePayload decodePayload(Uint8List bytes) {
    final raw = CachedStreamListNotifier.normalizeForMapper(
      msgpack.deserialize(bytes),
    ) as Map<String, dynamic>;

    final shipMaps = (raw['ships'] as List).cast<Map<String, dynamic>>();
    final ships = <Ship>[];
    for (final map in shipMaps) {
      final ship = ShipMapper.fromMap(map);
      final csvPath = map['csvFile'];
      if (csvPath is String) ship.csvFile = File(csvPath);
      final dataPath = map['dataFile'];
      if (dataPath is String) ship.dataFile = File(dataPath);
      ship.modVariant = null; // reattached by rehydratePayload.
      ships.add(ship);
    }

    final moduleVariants = <String, ShipVariant>{};
    final moduleVariantsRaw = raw['moduleVariants'] as Map<String, dynamic>;
    moduleVariantsRaw.forEach((k, v) {
      moduleVariants[k] = ShipVariantMapper.fromMap(
        v as Map<String, dynamic>,
      );
    });

    final hullIdMap = <String, String>{};
    final hullIdMapRaw = raw['hullIdMap'] as Map<String, dynamic>;
    hullIdMapRaw.forEach((k, v) {
      hullIdMap[k] = v.toString();
    });

    return ShipsCachePayload(
      ships: ships,
      moduleVariants: moduleVariants,
      hullIdMap: hullIdMap,
    );
  }

  String allShipsAsCsv() {
    final allShips = state.value ?? [];

    final shipFields = allShips.isNotEmpty
        ? allShips.first.toMap().keys.toList()
        : [];
    List<List<dynamic>> rows = [shipFields];

    if (allShips.isNotEmpty) {
      rows.addAll(
        allShips.map((ship) => ship.toMap().values.toList()).toList(),
      );
    }

    final csvContent = const ListToCsvConverter(
      convertNullTo: "",
    ).convert(rows);

    return csvContent;
  }

  Future<ShipParseResult> _parseShips(
    Directory folder,
    ModVariant? modVariant,
    List<Ship> allShipsSoFar,
  ) async {
    int filesProcessed = 0;
    final shipsCsvFile = p
        .join(folder.path, 'data/hulls/ship_data.csv')
        .toFile()
        .normalize
        .toFile();
    final ships = <Ship>[];
    final errors = <String>[];
    final infos = <String>[];
    final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

    if (!await shipsCsvFile.exists()) {
      infos.add('[$modName] Ship CSV file not found at $shipsCsvFile');
      // Still check for skins even if no CSV exists (mod may only add skins).
      final skinShips = await _parseSkins(
        folder,
        modVariant,
        allShipsSoFar,
        [],
      );
      ships.addAll(skinShips.ships);
      errors.addAll(skinShips.errors);
      infos.addAll(skinShips.infos);
      return ShipParseResult(
        ships,
        errors,
        infos,
        filesProcessed + skinShips.filesProcessed,
      );
    }

    // Load and index .ship files
    final shipDir = Directory(p.join(folder.path, 'data/hulls'));
    final shipFiles = shipDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.ship'))
        .toList();

    final shipJsonData = <String, Map<String, dynamic>>{};
    final shipFilesByHullId = <String, File>{};
    for (final shipFile in shipFiles) {
      filesProcessed++;
      try {
        final raw = await shipFile.readAsString(encoding: utf8);
        final cleaned = raw.removeJsonComments();
        final map = await cleaned.parseJsonToMapAsync();
        final id = map['hullId'] as String?;
        if (id != null) {
          final spriteName = map['spriteName'] as String?;
          if (spriteName != null) {
            map['spriteFile'] =
                p.join(folder.path, spriteName).toFile().normalize.path;
          }
          shipJsonData[id] = map;
          shipFilesByHullId[id] = shipFile;
        } else {
          errors.add('[$modName] .ship file ${shipFile.path} missing "hullId"');
        }
      } catch (e) {
        errors.add(
          '[$modName] Failed to parse .ship file ${shipFile.path}: $e',
        );
      }
    }

    String content;
    try {
      filesProcessed++;
      content = await shipsCsvFile.readAsStringUtf8OrLatin1();
    } catch (e) {
      errors.add('[$modName] Failed to read ship_data.csv: $e');
      return ShipParseResult(ships, errors, infos, filesProcessed);
    }

    // Strip `#` comments (quote-aware, multi-line safe) and track source lines.
    final stripped = content.stripCsvCommentsAndTrackLines();
    final lineNumberMap = stripped.lineNumberMap;

    List<List<dynamic>> rows;
    try {
      rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(stripped.cleanContent);
    } catch (e) {
      errors.add('[$modName] Failed to parse CSV: $e');
      return ShipParseResult(ships, errors, infos, filesProcessed);
    }

    if (rows.isEmpty) {
      errors.add('[$modName] Empty ship_data.csv');
      return ShipParseResult(ships, errors, infos, filesProcessed);
    }

    final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();

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
        final ship = ShipMapper.fromMap(data)
          ..modVariant = modVariant
          ..csvFile = shipsCsvFile
          ..dataFile = shipFilesByHullId[shipId];
        ships.add(ship);
      } catch (e) {
        errors.add('[$modName] Failed to create ship for id "$shipId": $e');
      }
    }

    // Parse .skin files and resolve against base hulls
    final skinResult = await _parseSkins(
      folder,
      modVariant,
      allShipsSoFar,
      ships,
    );
    ships.addAll(skinResult.ships);
    errors.addAll(skinResult.errors);
    infos.addAll(skinResult.infos);
    filesProcessed += skinResult.filesProcessed;

    return ShipParseResult(ships, errors, infos, filesProcessed);
  }

  /// Parse `.skin` files from `data/hulls/skins/` and resolve each against
  /// its base hull to produce fully-populated [Ship] objects.
  Future<ShipParseResult> _parseSkins(
    Directory folder,
    ModVariant? modVariant,
    List<Ship> allShipsSoFar,
    List<Ship> currentModShips,
  ) async {
    final skinsDir = Directory(p.join(folder.path, 'data/hulls/skins'));
    final ships = <Ship>[];
    final errors = <String>[];
    final infos = <String>[];
    int filesProcessed = 0;
    final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

    if (!await skinsDir.exists()) {
      return ShipParseResult(ships, errors, infos, filesProcessed);
    }

    final skinFiles = skinsDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.skin'))
        .toList();

    // Build a lookup combining all previously loaded ships + this mod's ships
    final allAvailable = <String, Ship>{};
    for (final s in allShipsSoFar) {
      allAvailable[s.id] = s;
    }
    for (final s in currentModShips) {
      allAvailable[s.id] = s;
    }

    for (final skinFile in skinFiles) {
      filesProcessed++;
      try {
        final raw = await skinFile.readAsString(encoding: utf8);
        final cleaned = raw.removeJsonComments();
        final map = await cleaned.parseJsonToMapAsync();
        final skin = ShipSkinMapper.fromMap(map);

        final baseHull = allAvailable[skin.baseHullId];
        if (baseHull == null) {
          errors.add(
            '[$modName] Skin ${skin.skinHullId}: base hull "${skin.baseHullId}" not found',
          );
          continue;
        }

        final ship = _resolveSkin(skin, baseHull, folder, modVariant)
          ..csvFile = baseHull.csvFile
          ..dataFile = skinFile;
        ships.add(ship);
        // Also make resolved skins available as base hulls for other skins
        allAvailable[ship.id] = ship;
      } catch (e) {
        errors.add(
          '[$modName] Failed to parse .skin file ${skinFile.path}: $e',
        );
      }
    }

    return ShipParseResult(ships, errors, infos, filesProcessed);
  }

  /// Resolve a [ShipSkin] against its [baseHull] to produce a complete [Ship].
  Ship _resolveSkin(
    ShipSkin skin,
    Ship baseHull,
    Directory folder,
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
      builtInWeapons.removeWhere(
        (k, _) => skin.removeBuiltInWeapons!.contains(k),
      );
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

    // Sprite: resolve from skin or keep base
    final spriteName = skin.spriteName ?? baseHull.spriteName;
    final spriteFile = skin.spriteName != null
        ? p.join(folder.path, skin.spriteName!).toFile().normalize.path
        : baseHull.spriteFile;

    return Ship(
      id: skin.skinHullId,
      isSkin: true,
      baseHullId: skin.baseHullId,
      name: skin.hullName ?? baseHull.name,
      designation: skin.hullDesignation ?? baseHull.designation,
      techManufacturer: skin.manufacturer ?? skin.tech ?? baseHull.techManufacturer,
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
      number: baseHull.number,
      bounds: baseHull.bounds,
      center: baseHull.center,
      collisionRadius: baseHull.collisionRadius,
      height: baseHull.height,
      width: baseHull.width,
      hullSize: baseHull.hullSize,
      shieldCenter: baseHull.shieldCenter,
      shieldRadius: baseHull.shieldRadius,
      spriteName: spriteName,
      spriteFile: spriteFile,
      style: baseHull.style,
      viewOffset: baseHull.viewOffset,
      engineSlots: baseHull.engineSlots,
      weaponSlots: weaponSlots,
      builtInWeapons: builtInWeapons,
      builtInMods: builtInMods,
      builtInWings: skin.builtInWings ?? baseHull.builtInWings,
      moduleAnchor: baseHull.moduleAnchor,
    )..modVariant = modVariant ?? baseHull.modVariant;
  }

  /// Resolves fleet points from skin overrides.
  /// [fleetPoints] replaces the base value outright; [fpMod] is additive.
  static double? _resolveFleetPts(
    double? baseFp,
    num? fleetPoints,
    num? fpMod,
  ) {
    final fp = fleetPoints?.toDouble() ?? baseFp;
    if (fp == null) return null;
    return fpMod != null ? fp + fpMod.toDouble() : fp;
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
    final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

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
        errors.add(
          '[$modName] Failed to parse .variant file ${file.path}: $e',
        );
      }
    }

    return _VariantParseResult(moduleVariants, hullIdMap);
  }
}

class ShipParseResult {
  final List<Ship> ships;
  final List<String> errors;
  final List<String> infos;
  final int filesProcessed;

  ShipParseResult(this.ships, this.errors, this.infos, this.filesProcessed);
}

class _VariantParseResult {
  final Map<String, ShipVariant> moduleVariants;
  final Map<String, String> hullIdMap;

  _VariantParseResult(this.moduleVariants, this.hullIdMap);
}
