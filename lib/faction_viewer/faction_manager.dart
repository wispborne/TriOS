import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:path/path.dart' as p;
import 'package:trios/faction_viewer/faction_merge.dart';
import 'package:trios/faction_viewer/factions_csv.dart';
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/faction_viewer/models/factions_cache_payload.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/cached_stream_list_notifier.dart';
import 'package:trios/viewer_cache/cached_variant_store.dart';

final isLoadingFactionsList = StateProvider<bool>((ref) => false);
final isFactionsListDirty = StateProvider<bool>((ref) => false);

/// The raw `.faction` files from vanilla and every installed mod. Read
/// [mergedFactionListProvider] for usable factions.
final factionListNotifierProvider =
    StreamNotifierProvider<FactionListNotifier, List<FactionFileData>>(
      FactionListNotifier.new,
    );

/// Name used for game-core data, matching `ship_roles_manager.dart` so
/// attributions from both can be compared by name.
const String _vanillaSourceName = 'Vanilla';

/// Key standing in for vanilla when grouping files by their source mod.
const String _vanillaSourceKey = '__vanilla__';

/// Scans every installed mod for `.faction` files and keeps them raw, one
/// entry per file per mod. [mergedFactionListProvider] does the merging.
class FactionListNotifier
    extends CachedStreamListNotifier<FactionFileData, FactionsCachePayload> {
  @override
  String get domain => 'factions';

  @override
  int get schemaVersion => 6;

  @override
  late final CachedVariantStore store =
      CachedVariantStore(domain, Constants.viewerCacheDirPath);

  /// Two mods can both ship `hegemony.faction`, and we need to keep both, so
  /// the id covers the source as well as the file.
  @override
  String itemId(FactionFileData item) =>
      '${item.sourceSmolId ?? _vanillaSourceKey}|${item.mergeKey}';

  @override
  List<FactionFileData> itemsFromPayload(FactionsCachePayload payload) =>
      payload.files;

  @override
  Directory? get gameCorePath {
    final path = ref.watch(AppState.gameCoreFolder).value?.path;
    return (path == null || path.isEmpty) ? null : Directory(path);
  }

  @override
  String? get currentGameVersion => ref.watch(AppState.starsectorVersion).value;

  @override
  Future<bool> awaitReadiness() async {
    return ref.watch(AppState.modVariants).hasValue;
  }

  @override
  void onBuildStart() {
    ref.read(isLoadingFactionsList.notifier).state = true;
    ref.listen(AppState.smolIds, (previous, next) {
      ref.read(isFactionsListDirty.notifier).state = true;
    });
  }

  @override
  void onBuildComplete({required bool fullScanCompleted}) {
    ref.read(isLoadingFactionsList.notifier).state = false;
    if (fullScanCompleted) {
      ref.read(isFactionsListDirty.notifier).state = false;
    }
    super.onBuildComplete(fullScanCompleted: fullScanCompleted);
  }

  @override
  Future<FactionsCachePayload?> parseVanilla(
    Directory gameCore,
    List<FactionFileData> allItemsSoFar,
  ) async {
    return _parseFactionFolder(gameCore, null);
  }

  @override
  Future<FactionsCachePayload?> parseVariant(
    ModVariant variant,
    List<FactionFileData> allItemsSoFar,
  ) async {
    return _parseFactionFolder(variant.modFolder, variant);
  }

  Future<FactionsCachePayload?> _parseFactionFolder(
    Directory folder,
    ModVariant? modVariant,
  ) async {
    final factionsDir = Directory(
      p.join(folder.path, 'data', 'world', 'factions'),
    );
    if (!await factionsDir.exists()) return null;

    final modName = modVariant?.modInfo.nameOrId ?? _vanillaSourceName;
    final sourceName = modName;
    final files = <FactionFileData>[];

    // A faction only exists in-game if some source lists its file path in
    // factions.csv (merged across vanilla + mods). Sources with a matching
    // row *add* the faction; sources without one only patch it.
    var registeredKeys = const <String>{};
    final csvFile = File(p.join(factionsDir.path, 'factions.csv'));
    if (await csvFile.exists()) {
      try {
        final csvContent = await csvFile.readAsStringUtf8OrLatin1();
        registeredKeys = parseFactionsCsvKeys(csvContent);
      } catch (e) {
        Fimber.w('[$modName] Error reading factions.csv: $e');
      }
    }

    try {
      await for (final entity in factionsDir.list(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.faction')) continue;

        try {
          final content = await entity.readAsStringUtf8OrLatin1();
          final jsonContent = content.removeJsonComments();
          final factionData = await jsonContent.parseJsonToMapAsync();

          // Starsector associates overlay faction files by relative path, not
          // by the `id` field (vanilla persean_league.faction declares id
          // "persean" but mods omit the id and rely on the path). Merge on
          // the path under data/world/factions (subfolders count, e.g. AoTD's
          // submarkets/researchfacil); the `id` field is kept only for
          // display.
          final mergeKey = p
              .withoutExtension(p.relative(entity.path, from: factionsDir.path))
              .replaceAll('\\', '/');

          files.add(
            FactionFileData(
              mergeKey: mergeKey,
              sourceName: sourceName,
              sourceSmolId: modVariant?.smolId,
              registersFaction: registeredKeys.contains(mergeKey.toLowerCase()),
              json: factionData,
            ),
          );
        } catch (e, st) {
          Fimber.w(
            '[$modName] Error parsing faction file ${entity.path}: $e',
            ex: e,
            stacktrace: st,
          );
        }
      }
    } catch (e) {
      Fimber.w('Error scanning factions in ${folder.path}: $e');
    }

    if (files.isEmpty) return null;
    return FactionsCachePayload(files: files);
  }

  @override
  Uint8List encodePayload(FactionsCachePayload payload) {
    final map = <String, dynamic>{
      'files': payload.files.map((f) => f.toMap()).toList(),
    };
    return msgpack.serialize(map);
  }

  @override
  FactionsCachePayload decodePayload(Uint8List bytes) {
    final raw = CachedStreamListNotifier.normalizeForMapper(
      msgpack.deserialize(bytes),
    ) as Map<String, dynamic>;
    final fileMaps = (raw['files'] as List).cast<Map<String, dynamic>>();
    final files = <FactionFileData>[];
    for (final map in fileMaps) {
      try {
        files.add(FactionFileDataMapper.fromMap(map));
      } catch (e) {
        Fimber.w('Error decoding cached faction file: $e');
      }
    }
    return FactionsCachePayload(files: files);
  }
}

/// Factions built by merging the raw files, in the game's load order.
///
/// With [onlyEnabledMods] on, files from mods that aren't enabled are left
/// out, so ship lists, doctrine numbers, and spawn weights match what the game
/// would actually do with the current setup. Vanilla is always included.
///
/// Merging here rather than during the scan means flipping the toggle is
/// instant: the scan and its cache hold every installed mod either way.
final mergedFactionListProvider = Provider.family<List<Faction>, bool>((
  ref,
  onlyEnabledMods,
) {
  final files = ref.watch(factionListNotifierProvider).valueOrNull ?? const [];
  if (files.isEmpty) return const [];
  final mods = ref.watch(AppState.mods);

  final filesBySource = <String, List<FactionFileData>>{};
  for (final file in files) {
    filesBySource
        .putIfAbsent(file.sourceSmolId ?? _vanillaSourceKey, () => [])
        .add(file);
  }

  // Later files overwrite earlier ones, so walk the sources the way the game
  // loads them: vanilla, then mods in load order.
  final orderedSources =
      <({List<FactionFileData> files, ModVariant? variant, bool enabled})>[
        (
          files: filesBySource[_vanillaSourceKey] ?? const [],
          variant: null,
          enabled: true,
        ),
        for (final variant in mods
            .map((mod) => mod.findFirstEnabledOrHighestVersion)
            .nonNulls
            .sortedByGameLoadOrder())
          if (filesBySource[variant.smolId] case final variantFiles?)
            (
              files: variantFiles,
              variant: variant,
              enabled: variant.mod(mods)?.hasEnabledVariant == true,
            ),
      ];

  // Which factions any installed mod claims to add, enabled or not. Used below
  // to tell "nobody owns this file" apart from "a disabled mod owns it".
  final registeredByAnySource = <String>{
    for (final file in files)
      if (file.registersFaction) file.mergeKey,
  };

  final merging = <String, _MergingFaction>{};
  for (final source in orderedSources) {
    if (onlyEnabledMods && !source.enabled) continue;

    for (final file in source.files) {
      final factionSource = FactionSource(
        name: file.sourceName,
        modVariant: source.variant,
        registersFaction: file.registersFaction,
      );

      final existing = merging[file.mergeKey];
      if (existing == null) {
        final attributions = <String, List<SourceContribution>>{};
        final itemAttributions = <String, Map<String, String>>{};
        _initAttributions(
          file.json,
          file.sourceName,
          attributions,
          itemAttributions,
          '',
        );
        merging[file.mergeKey] = _MergingFaction(
          json: file.json,
          attributions: attributions,
          itemAttributions: itemAttributions,
          sources: [factionSource],
        );
      } else {
        final result = mergeFactionJson(
          base: existing.json,
          overlay: file.json,
          sourceName: file.sourceName,
          existingAttributions: existing.attributions,
          existingItemAttributions: existing.itemAttributions,
        );
        existing.json = result.merged;
        existing.attributions = result.attributions;
        existing.itemAttributions = result.itemAttributions;
        existing.sources.add(factionSource);
      }
    }
  }

  final factions = <Faction>[];
  for (final entry in merging.entries) {
    final merged = entry.value;

    // A faction is only in the game if some source lists it in factions.csv.
    // If the only sources that did are mods we left out, the faction isn't
    // there either. Files nobody claims are kept — the owner is unknown, not
    // known-to-be-disabled.
    if (registeredByAnySource.contains(entry.key) &&
        !merged.sources.any((s) => s.registersFaction)) {
      continue;
    }

    factions.add(
      _buildFactionFromJson(
        entry.key,
        merged.json,
        merged.sources,
        merged.attributions,
        merged.itemAttributions,
      ),
    );
  }
  return factions;
});

/// One faction's data part-way through the merge.
class _MergingFaction {
  Map<String, dynamic> json;
  Map<String, List<SourceContribution>> attributions;
  Map<String, Map<String, String>> itemAttributions;
  final List<FactionSource> sources;

  _MergingFaction({
    required this.json,
    required this.attributions,
    required this.itemAttributions,
    required this.sources,
  });
}

Faction _buildFactionFromJson(
  String mergeKey,
  Map<String, dynamic> data,
  List<FactionSource> sources,
  Map<String, List<SourceContribution>> attributions,
  Map<String, Map<String, String>> itemAttributions,
) {
  final doctrine = data['factionDoctrine'] as Map<String, dynamic>?;
  final custom = data['custom'] as Map<String, dynamic>? ?? {};
  final portraits = data['portraits'] as Map<String, dynamic>?;
  final knownShips = data['knownShips'] as Map<String, dynamic>?;
  final knownWeapons = data['knownWeapons'] as Map<String, dynamic>?;
  final knownFighters = data['knownFighters'] as Map<String, dynamic>?;
  final knownHullMods = data['knownHullMods'] as Map<String, dynamic>?;
  final musicRaw = data['music'] as Map<String, dynamic>?;

  // The `id` field is display-only; fall back to the filename when none of
  // the merged files declared one.
  final id = (data['id'] as String?)?.ifBlank(mergeKey) ?? mergeKey;

  return Faction(
    mergeKey: mergeKey,
    id: id,
    displayName: data['displayName'] as String? ?? id,
    displayNameWithArticle: data['displayNameWithArticle'] as String?,
    displayNameLong: data['displayNameLong'] as String?,
    displayNameLongWithArticle: data['displayNameLongWithArticle'] as String?,
    color: _toIntList(data['color']) ?? const [255, 255, 255, 255],
    baseUIColor: _toIntList(data['baseUIColor']),
    darkUIColor: _toIntList(data['darkUIColor']),
    gridUIColor: _toIntList(data['gridUIColor']),
    brightUIColor: _toIntList(data['brightUIColor']),
    logo: data['logo'] as String?,
    crest: data['crest'] as String?,
    showInIntelTab: data['showInIntelTab'] as bool? ?? true,
    shipNamePrefix: data['shipNamePrefix']?.toString(),
    shipNameSources: data['shipNameSources'] as Map<String, dynamic>?,
    doctrine: doctrine != null
        ? FactionDoctrine(
            warships: _toInt(doctrine['warships']),
            carriers: _toInt(doctrine['carriers']),
            phaseShips: _toInt(doctrine['phaseShips']),
            officerQuality: _toInt(doctrine['officerQuality']),
            shipQuality: _toInt(doctrine['shipQuality']),
            numShips: _toInt(doctrine['numShips']),
            shipSize: _toInt(doctrine['shipSize']),
            aggression: _toInt(doctrine['aggression']),
            combatFreighterProbability:
                _toDouble(doctrine['combatFreighterProbability']),
            autofitRandomizeProbability:
                _toDouble(doctrine['autofitRandomizeProbability']),
          )
        : null,
    knownShipIds: _stringList(knownShips?['hulls']),
    priorityShipIds: _stringList(
      (data['priorityShips'] as Map<String, dynamic>?)?['hulls'],
    ),
    knownWeaponIds: _stringList(knownWeapons?['weapons']),
    priorityWeaponIds: _stringList(
      (data['priorityWeapons'] as Map<String, dynamic>?)?['weapons'],
    ),
    knownFighterIds: _stringList(knownFighters?['fighters']),
    priorityFighterIds: _stringList(
      (data['priorityFighters'] as Map<String, dynamic>?)?['fighters'],
    ),
    knownHullModIds: _stringList(knownHullMods?['hullMods']),
    knownShipTags: _stringList(knownShips?['tags']),
    priorityShipTags: _stringList(
      (data['priorityShips'] as Map<String, dynamic>?)?['tags'],
    ),
    knownWeaponTags: _stringList(knownWeapons?['tags']),
    knownFighterTags: _stringList(knownFighters?['tags']),
    knownHullModTags: _stringList(knownHullMods?['tags']),
    malePortraits: _stringList(portraits?['standard_male']),
    femalePortraits: _stringList(portraits?['standard_female']),
    illegalCommodities: _stringList(data['illegalCommodities']),
    customFlags: custom,
    music: musicRaw?.map((k, v) => MapEntry(k, v.toString())),
    shipRoles: data['shipRoles'] as Map<String, dynamic>?,
    hullFrequency: data['hullFrequency'] as Map<String, dynamic>?,
    variantOverrides: data['variantOverrides'] as Map<String, dynamic>?,
    sources: sources,
    sectionAttributions: attributions,
    itemAttributions: itemAttributions,
  );
}

void _initAttributions(
  Map<String, dynamic> data,
  String sourceName,
  Map<String, List<SourceContribution>> attributions,
  Map<String, Map<String, String>> itemAttributions,
  String prefix,
) {
  for (final entry in data.entries) {
    final fullKey = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;
    if (value is List && !_isColorKey(entry.key)) {
      final items = value.where((e) => e != 'core_clearArray');
      final count = items.length;
      if (count > 0) {
        attributions[fullKey] = [
          SourceContribution(source: sourceName, count: count),
        ];
        final perItem = <String, String>{};
        for (final item in items) {
          if (item is String) {
            perItem[item] = sourceName;
          }
        }
        if (perItem.isNotEmpty) {
          itemAttributions[fullKey] = perItem;
        }
      }
    } else if (value is Map<String, dynamic> &&
        entry.key.toLowerCase() != 'music') {
      _initAttributions(
        value, sourceName, attributions, itemAttributions, fullKey,
      );
    } else if (value is! Map && value is! List) {
      // Scalars are attributed to whoever wrote them last; for the first file
      // that's this source. Recorded under the parent section, matching
      // faction_merge.dart.
      itemAttributions.putIfAbsent(prefix, () => {})[entry.key] = sourceName;
    }
  }
}

bool _isColorKey(String key) {
  final lower = key.toLowerCase();
  return lower == 'color' ||
      lower == 'baseuicolor' ||
      lower == 'darkuicolor' ||
      lower == 'griduicolor' ||
      lower == 'brightuicolor';
}

List<String> _stringList(dynamic value) {
  if (value is List) return value.whereType<String>().toList();
  return const [];
}

List<int>? _toIntList(dynamic value) {
  if (value is List) {
    return value.map((e) => _toInt(e)).toList();
  }
  return null;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) {
    return value.toDoubleOrNullAllowingJavaSuffix()?.round() ?? 0;
  }
  return 0;
}

double? _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return value.toDoubleOrNullAllowingJavaSuffix();
  return null;
}
