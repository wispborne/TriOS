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
import 'package:trios/shipViewer/models/shipSkin.dart';
import 'package:trios/shipViewer/models/ship_weapon_slot.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

final isLoadingShipsList = StateProvider<bool>((ref) => false);
final isShipsListDirty = StateProvider<bool>((ref) => false);

final shipListNotifierProvider =
    StreamNotifierProvider<ShipListNotifier, List<Ship>>(ShipListNotifier.new);

class ShipListNotifier extends StreamNotifier<List<Ship>> {
  /// Incremented each time build() starts. Stale builds compare against this
  /// and return early, preventing cascading widget rebuilds.
  var _buildToken = 0;

  @override
  Stream<List<Ship>> build() async* {
    final myToken = ++_buildToken;
    int filesProcessed = 0;

    final currentTime = DateTime.now();
    ref.read(isLoadingShipsList.notifier).state = true;
    filesProcessed = 0;
    final gameCorePath = ref.watch(AppState.gameCoreFolder).value?.path;

    if (gameCorePath == null || gameCorePath.isEmpty) {
      ref.read(isLoadingShipsList.notifier).state = false;
      return;
    }

    // Wait for modVariants to resolve on startup without watching it.
    // Using ref.read + ref.listen instead of ref.watch avoids re-triggering
    // this entire stream on every mod version switch, which was causing
    // cascading widget rebuilds.
    if (!ref.read(AppState.modVariants).hasValue) {
      final completer = Completer<void>();
      ref.listen(AppState.modVariants, (prev, next) {
        if (next.hasValue && !completer.isCompleted) completer.complete();
      });
      await completer.future;
      if (_buildToken != myToken) return;
    }

    ref.listen(AppState.smolIds, (previous, next) {
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
    // Throttle UI rebuilds during loading: yield at most once per 500ms.
    const yieldInterval = Duration(milliseconds: 500);
    var lastYieldTime = DateTime.fromMillisecondsSinceEpoch(0);

    final coreResult = await _parseShips(
      Directory(gameCorePath),
      null,
      allShips,
    );
    if (_buildToken != myToken) return;
    filesProcessed += coreResult.filesProcessed;
    allShips.addAll(coreResult.ships);
    allShips = allShips.distinctBy((e) => e.id).toList();

    if (coreResult.errors.isNotEmpty) {
      allErrors.addAll(coreResult.errors);
    }

    for (final variant in variants) {
      if (_buildToken != myToken) return;
      final modResult = await _parseShips(variant.modFolder, variant, allShips);
      if (_buildToken != myToken) return;
      filesProcessed += modResult.filesProcessed;
      allShips.addAll(modResult.ships);
      allShips = allShips.distinctBy((e) => e.id).toList();

      if (modResult.errors.isNotEmpty) {
        allErrors.addAll(modResult.errors);
      }

      final now = DateTime.now();
      if (now.difference(lastYieldTime) >= yieldInterval) {
        yield allShips;
        lastYieldTime = now;
      }
    }

    // Always yield the final complete list.
    yield allShips;

    if (allErrors.isNotEmpty) {
      Fimber.w('Ship parsing errors:\n${allErrors.join('\n')}');
    }

    ref.read(isLoadingShipsList.notifier).state = false;
    ref.read(isShipsListDirty.notifier).state = false;
    Fimber.i(
      'Parsed ${allShips.length} ships from ${variants.length + 1} mods and $filesProcessed files in ${DateTime.now().difference(currentTime).inMilliseconds}ms',
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
    final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

    if (!await shipsCsvFile.exists()) {
      // Still check for skins even if no CSV exists (mod may only add skins).
      final skinShips = await _parseSkins(
        folder,
        modVariant,
        allShipsSoFar,
        [],
      );
      ships.addAll(skinShips.ships);
      errors.addAll(skinShips.errors);
      return ShipParseResult(ships, errors, filesProcessed + skinShips.filesProcessed);
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
        final map = await cleaned.parseJsonToMapAsync();
        final id = map['hullId'] as String?;
        if (id != null) {
          final spriteName = map['spriteName'] as String?;
          if (spriteName != null) {
            map['spriteFile'] =
                p.join(folder.path, spriteName).toFile().normalize.path;
          }
          shipJsonData[id] = map;
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

    final headers = rows.first.map((e) => e.toString().trim()).toList();

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

    // Parse .skin files and resolve against base hulls
    final skinResult = await _parseSkins(
      folder,
      modVariant,
      allShipsSoFar,
      ships,
    );
    ships.addAll(skinResult.ships);
    errors.addAll(skinResult.errors);
    filesProcessed += skinResult.filesProcessed;

    return ShipParseResult(ships, errors, filesProcessed);
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
    int filesProcessed = 0;
    final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';

    if (!await skinsDir.exists()) {
      return ShipParseResult(ships, errors, filesProcessed);
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

        final ship = _resolveSkin(skin, baseHull, folder, modVariant);
        ships.add(ship);
        // Also make resolved skins available as base hulls for other skins
        allAvailable[ship.id] = ship;
      } catch (e) {
        errors.add(
          '[$modName] Failed to parse .skin file ${skinFile.path}: $e',
        );
      }
    }

    return ShipParseResult(ships, errors, filesProcessed);
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
      fleetPts: skin.fleetPoints?.toDouble() ?? baseHull.fleetPts,
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
      suppliesRec: baseHull.suppliesRec,
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
}

class ShipParseResult {
  final List<Ship> ships;
  final List<String> errors;
  final int filesProcessed;

  ShipParseResult(this.ships, this.errors, this.filesProcessed);
}
