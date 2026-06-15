import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:path/path.dart' as p;
import 'package:trios/faction_viewer/faction_merge.dart';
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

final factionListNotifierProvider =
    StreamNotifierProvider<FactionListNotifier, List<Faction>>(
      FactionListNotifier.new,
    );

/// Holds the raw parsed JSON for each faction ID, used for mod merging.
/// Key: faction ID, Value: {json, attributions, sources}.
final _vanillaFactionJsonCache = <String, _ParsedFactionJson>{};

/// Maps faction ID → the payload list that first introduced it, so merges
/// update in-place and the base class's first-occurrence-wins dedup picks
/// up the latest merged version.
final _factionListOwnership = <String, List<Faction>>{};

class _ParsedFactionJson {
  Map<String, dynamic> json;
  Map<String, List<SourceContribution>> attributions;
  Map<String, Map<String, String>> itemAttributions;
  List<FactionSource> sources;

  _ParsedFactionJson({
    required this.json,
    required this.attributions,
    required this.itemAttributions,
    required this.sources,
  });
}

class FactionListNotifier
    extends CachedStreamListNotifier<Faction, FactionsCachePayload> {
  @override
  String get domain => 'factions';

  @override
  int get schemaVersion => 1;

  @override
  late final CachedVariantStore store =
      CachedVariantStore(domain, Constants.viewerCacheDirPath);

  @override
  String itemId(Faction item) => item.id;

  @override
  List<Faction> itemsFromPayload(FactionsCachePayload payload) =>
      payload.factions;

  @override
  bool get providesItemContext => true;

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
    return ref.watch(AppState.modVariants).hasValue;
  }

  @override
  void onBuildStart() {
    _vanillaFactionJsonCache.clear();
    _factionListOwnership.clear();
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
  void rehydratePayload(
    FactionsCachePayload payload,
    ModVariant? sourceVariant,
  ) {
    // Factions don't store modVariant on the model directly since they
    // can have multiple sources. Nothing to rehydrate.
  }

  @override
  Future<FactionsCachePayload?> parseVanilla(
    Directory gameCore,
    List<Faction> allItemsSoFar,
  ) async {
    return _parseFactionFolder(gameCore, null, allItemsSoFar);
  }

  @override
  Future<FactionsCachePayload?> parseVariant(
    ModVariant variant,
    List<Faction> allItemsSoFar,
  ) async {
    return _parseFactionFolder(variant.modFolder, variant, allItemsSoFar);
  }

  Future<FactionsCachePayload?> _parseFactionFolder(
    Directory folder,
    ModVariant? modVariant,
    List<Faction> allItemsSoFar,
  ) async {
    final factionsDir = Directory(
      p.join(folder.path, 'data', 'world', 'factions'),
    );
    if (!await factionsDir.exists()) return null;

    final modName = modVariant?.modInfo.nameOrId ?? 'Vanilla';
    final sourceName = modName;
    final factions = <Faction>[];

    try {
      await for (final entity in factionsDir.list()) {
        if (entity is! File || !entity.path.endsWith('.faction')) continue;

        try {
          final content = await entity.readAsStringUtf8OrLatin1();
          final jsonContent = content.removeJsonComments();
          final factionData = await jsonContent.parseJsonToMapAsync();

          var factionId = factionData['id'] as String?;
          if (factionId == null || factionId.isEmpty) {
            // Many mod faction files omit the id field — the game
            // identifies factions by filename instead.
            factionId = p.basenameWithoutExtension(entity.path);
            factionData['id'] = factionId;
          }

          final source = FactionSource(
            name: sourceName,
            modVariant: modVariant,
          );

          // Check if this faction already exists (needs merging).
          final existingCached = _vanillaFactionJsonCache[factionId];
          if (existingCached != null) {
            final mergeResult = mergeFactionJson(
              base: existingCached.json,
              overlay: factionData,
              sourceName: sourceName,
              existingAttributions: existingCached.attributions,
              existingItemAttributions: existingCached.itemAttributions,
            );

            existingCached.json = mergeResult.merged;
            existingCached.attributions = mergeResult.attributions;
            existingCached.itemAttributions = mergeResult.itemAttributions;
            existingCached.sources = [...existingCached.sources, source];

            final merged = _buildFactionFromJson(
              mergeResult.merged,
              existingCached.sources,
              mergeResult.attributions,
              mergeResult.itemAttributions,
            );

            // Update the faction in the payload that first introduced it,
            // so the base class's first-occurrence-wins dedup sees the
            // latest merged version.
            final ownerList = _factionListOwnership[factionId];
            if (ownerList != null) {
              final idx = ownerList.indexWhere((f) => f.id == factionId);
              if (idx >= 0) {
                ownerList[idx] = merged;
              } else {
                factions.add(merged);
              }
            } else {
              factions.add(merged);
            }
          } else {
            // New faction — build initial attributions from array lengths.
            final attributions = <String, List<SourceContribution>>{};
            final itemAttrs = <String, Map<String, String>>{};
            _initAttributions(
              factionData, sourceName, attributions, itemAttrs, '',
            );

            _vanillaFactionJsonCache[factionId] = _ParsedFactionJson(
              json: factionData,
              attributions: attributions,
              itemAttributions: itemAttrs,
              sources: [source],
            );

            final faction = _buildFactionFromJson(
              factionData,
              [source],
              attributions,
              itemAttrs,
            );
            factions.add(faction);
            _factionListOwnership[factionId] = factions;
          }
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

    if (factions.isEmpty) return null;
    return FactionsCachePayload(factions: factions);
  }

  @override
  Uint8List encodePayload(FactionsCachePayload payload) {
    final map = <String, dynamic>{
      'factions': payload.factions.map((f) => f.toMap()).toList(),
    };
    return msgpack.serialize(map);
  }

  @override
  FactionsCachePayload decodePayload(Uint8List bytes) {
    final raw = CachedStreamListNotifier.normalizeForMapper(
      msgpack.deserialize(bytes),
    ) as Map<String, dynamic>;
    final factionMaps =
        (raw['factions'] as List).cast<Map<String, dynamic>>();
    final factions = <Faction>[];
    for (final map in factionMaps) {
      try {
        factions.add(FactionMapper.fromMap(map));
      } catch (e) {
        Fimber.w('Error decoding cached faction: $e');
      }
    }
    return FactionsCachePayload(factions: factions);
  }
}

Faction _buildFactionFromJson(
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

  return Faction(
    id: data['id'] as String,
    displayName: data['displayName'] as String? ?? data['id'] as String,
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
    knownWeaponTags: _stringList(knownWeapons?['tags']),
    knownFighterTags: _stringList(knownFighters?['tags']),
    knownHullModTags: _stringList(knownHullMods?['tags']),
    malePortraits: _stringList(portraits?['standard_male']),
    femalePortraits: _stringList(portraits?['standard_female']),
    illegalCommodities: _stringList(data['illegalCommodities']),
    customFlags: custom,
    music: musicRaw?.map((k, v) => MapEntry(k, v.toString())),
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
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double? _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
