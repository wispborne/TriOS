import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:trios/utils/extensions.dart';

part 'faction.mapper.dart';

@MappableClass()
class Faction with FactionMappable implements WispGridItem {
  @override
  String get key => mergeKey;

  /// The `.faction` file path relative to `data/world/factions`, without the
  /// extension — e.g. `hegemony` or `submarkets/researchfacil`. Forward
  /// slashes on all platforms. This is how Starsector associates overlay
  /// files across mods.
  final String mergeKey;

  final String id;
  final String displayName;
  final String? displayNameWithArticle;
  final String? displayNameLong;
  final String? displayNameLongWithArticle;
  final List<int> color;
  final List<int>? baseUIColor;
  final List<int>? darkUIColor;
  final List<int>? gridUIColor;
  final List<int>? brightUIColor;
  final String? logo;
  final String? crest;
  final bool showInIntelTab;

  final String? shipNamePrefix;
  final Map<String, dynamic>? shipNameSources;

  final FactionDoctrine? doctrine;

  final List<String> knownShipIds;
  final List<String> priorityShipIds;
  final List<String> knownWeaponIds;
  final List<String> priorityWeaponIds;
  final List<String> knownFighterIds;
  final List<String> priorityFighterIds;
  final List<String> knownHullModIds;

  final List<String> knownShipTags;
  final List<String> knownWeaponTags;
  final List<String> knownFighterTags;
  final List<String> knownHullModTags;

  /// Hulls/tags the faction *favors*. The game picks from these far more often
  /// than their raw weight implies, so a ship being here matters. From the
  /// `.faction` `priorityShips` block.
  final List<String> priorityShipTags;

  final List<String> malePortraits;
  final List<String> femalePortraits;

  final List<String> illegalCommodities;

  final Map<String, dynamic> customFlags;

  final Map<String, String>? music;

  /// Role name → `{ includeDefault: bool, <loadoutId>: weight, ... }`. Kept raw;
  /// the shape varies and it's small.
  final Map<String, dynamic>? shipRoles;

  /// `{ hulls: { <hullId>: multiplier }, tags: { <tag>: multiplier } }`.
  final Map<String, dynamic>? hullFrequency;

  /// `<loadoutId>` → weight. Naming any loadout of a hull hides that hull's
  /// other loadouts from the faction.
  final Map<String, dynamic>? variantOverrides;

  @MappableField(hook: SkipSerializationHook())
  final List<FactionSource> sources;
  @MappableField(hook: SkipSerializationHook())
  final Map<String, List<SourceContribution>> sectionAttributions;
  @MappableField(hook: SkipSerializationHook())
  final Map<String, Map<String, String>> itemAttributions;

  Faction({
    required this.mergeKey,
    required this.id,
    required this.displayName,
    this.displayNameWithArticle,
    this.displayNameLong,
    this.displayNameLongWithArticle,
    this.color = const [255, 255, 255, 255],
    this.baseUIColor,
    this.darkUIColor,
    this.gridUIColor,
    this.brightUIColor,
    this.logo,
    this.crest,
    this.showInIntelTab = true,
    this.shipNamePrefix,
    this.shipNameSources,
    this.doctrine,
    this.knownShipIds = const [],
    this.priorityShipIds = const [],
    this.knownWeaponIds = const [],
    this.priorityWeaponIds = const [],
    this.knownFighterIds = const [],
    this.priorityFighterIds = const [],
    this.knownHullModIds = const [],
    this.knownShipTags = const [],
    this.knownWeaponTags = const [],
    this.knownFighterTags = const [],
    this.knownHullModTags = const [],
    this.priorityShipTags = const [],
    this.malePortraits = const [],
    this.femalePortraits = const [],
    this.illegalCommodities = const [],
    this.customFlags = const {},
    this.music,
    this.shipRoles,
    this.hullFrequency,
    this.variantOverrides,
    this.sources = const [],
    this.sectionAttributions = const {},
    this.itemAttributions = const {},
  });

  String get displayNameBest =>
      displayNameLong ?? displayNameWithArticle?.toTitleCase() ?? displayName;

  late final Color factionColor = color.length >= 3
      ? Color.fromARGB(
          color.length >= 4 ? color[3] : 255,
          color[0],
          color[1],
          color[2],
        )
      : Colors.grey;

  bool get isVanilla => sources.any((s) => s.modVariant == null);

  bool get isModOnly => sources.every((s) => s.modVariant != null);

  String get sourceNames => sources.map((s) => s.name).join(', ');

  /// The source that registered this faction in its `factions.csv` — the mod
  /// (or vanilla) that actually added the faction to the game. Null when no
  /// enabled source registers it: every source is then just patching a
  /// faction owned by something else (possibly a disabled mod).
  FactionSource? get addedBy {
    for (final source in sources) {
      if (source.registersFaction) return source;
    }
    return null;
  }

  /// Every source except [addedBy]: mods that merge changes into the faction
  /// without being the one that added it.
  List<FactionSource> get modifiedBy {
    final adder = addedBy;
    if (adder == null) return sources;
    return sources.where((s) => !identical(s, adder)).toList();
  }

  /// Multi-line "who added it, who changes it" text for tooltips.
  /// Empty when sources are unknown (e.g. cache-loaded, pre-scan).
  String get attributionTooltip {
    if (sources.isEmpty) return '';
    final adder = addedBy;
    final modifiers = modifiedBy.map((s) => s.name).join(', ');
    return [
      if (adder != null)
        'Added by: ${adder.name}'
      else
        'Not added by any enabled mod — it may belong to a disabled mod.',
      if (modifiers.isNotEmpty) 'Modified by: $modifiers',
    ].join('\n');
  }

  /// Resolves an image path (e.g. logo, crest) by searching source directories
  /// in reverse order (last source wins).
  File? resolveImageFile(String? relativePath, Directory? gameCoreDir) {
    if (relativePath == null || gameCoreDir == null) return null;
    for (final source in sources.reversed) {
      final baseDir = source.modVariant != null
          ? source.modVariant.modFolder as Directory
          : gameCoreDir;
      final file = File(p.join(baseDir.path, relativePath));
      if (file.existsSync()) return file;
    }
    return null;
  }
}

@MappableClass()
class FactionDoctrine with FactionDoctrineMappable {
  final int warships;
  final int carriers;
  final int phaseShips;
  final int officerQuality;
  final int shipQuality;
  final int numShips;
  final int shipSize;
  final int aggression;
  final double? combatFreighterProbability;
  final double? autofitRandomizeProbability;

  const FactionDoctrine({
    this.warships = 0,
    this.carriers = 0,
    this.phaseShips = 0,
    this.officerQuality = 0,
    this.shipQuality = 0,
    this.numShips = 0,
    this.shipSize = 0,
    this.aggression = 0,
    this.combatFreighterProbability,
    this.autofitRandomizeProbability,
  });
}

@MappableClass()
class FactionSource with FactionSourceMappable {
  final String name;
  @MappableField(hook: SkipSerializationHook())
  final dynamic modVariant;

  /// True if this source lists the faction's file in its `factions.csv`,
  /// meaning it adds the faction to the game rather than just patching it.
  final bool registersFaction;

  const FactionSource({
    required this.name,
    this.modVariant,
    this.registersFaction = false,
  });
}

@MappableClass()
class SourceContribution with SourceContributionMappable {
  final String source;
  final int count;

  const SourceContribution({required this.source, required this.count});
}
