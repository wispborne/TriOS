import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/faction_viewer/faction_manager.dart';
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/fighter_viewer/wings_manager.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/ship_viewer/ship_manager.dart';
import 'package:trios/weapon_viewer/weapons_manager.dart';

/// Which factions know each ship, weapon or fighter wing.
///
/// Only factions shown on the game's intel tab are included. The game's own
/// Codex uses the same rule, which also keeps spoiler factions such as the
/// Remnants out of these lists.
class FactionKnowledge {
  static const empty = FactionKnowledge._([], {}, {});

  /// Sorted by name. An index into this list is a faction's sort position.
  final List<Faction> _factions;
  final Map<String, List<int>> _positionsByItemId;
  final Map<String, String> _namesByKey;

  const FactionKnowledge._(
    this._factions,
    this._positionsByItemId,
    this._namesByKey,
  );

  /// Sort positions of the factions that know [itemId], in name order.
  List<int> sortPositionsOf(String itemId) =>
      _positionsByItemId[itemId] ?? const [];

  /// The `mergeKey`s of the factions that know [itemId], in name order.
  List<String> factionKeysOf(String itemId) => [
    for (final position in sortPositionsOf(itemId))
      _factions[position].mergeKey,
  ];

  /// A comma-separated list of the factions that know [itemId].
  String factionNamesOf(String itemId) => [
    for (final position in sortPositionsOf(itemId))
      _factions[position].displayName,
  ].join(', ');

  /// The display name for a faction's `mergeKey`, or the key if it's unknown.
  String nameOf(String factionKey) => _namesByKey[factionKey] ?? factionKey;

  /// The display name at [sortPosition], or null if there is no such faction.
  String? nameAtSortPosition(int sortPosition) =>
      sortPosition >= 0 && sortPosition < _factions.length
      ? _factions[sortPosition].displayName
      : null;
}

/// Works out which factions know each of [items]. A faction knows an item if
/// it lists the item's id, or lists any of the item's tags.
FactionKnowledge buildFactionKnowledge<T>({
  required List<Faction> factions,
  required List<T> items,
  required String Function(T item) idOf,
  required Iterable<String> Function(T item) tagsOf,
  required List<String> Function(Faction faction) knownIdsOf,
  required List<String> Function(Faction faction) knownTagsOf,
}) {
  final shown = factions.where((f) => f.showInIntelTab).toList()
    ..sort((a, b) {
      final byName = a.displayName.toLowerCase().compareTo(
        b.displayName.toLowerCase(),
      );
      return byName != 0 ? byName : a.mergeKey.compareTo(b.mergeKey);
    });

  final positionsById = <String, List<int>>{};
  final positionsByTag = <String, List<int>>{};
  for (var position = 0; position < shown.length; position++) {
    final faction = shown[position];
    for (final id in knownIdsOf(faction)) {
      (positionsById[id] ??= []).add(position);
    }
    for (final tag in knownTagsOf(faction)) {
      (positionsByTag[tag.toLowerCase()] ??= []).add(position);
    }
  }

  final positionsByItemId = <String, List<int>>{};
  for (final item in items) {
    final id = idOf(item);
    final positions = <int>{...?positionsById[id]};
    for (final tag in tagsOf(item)) {
      positions.addAll(positionsByTag[tag.toLowerCase()] ?? const []);
    }
    if (positions.isNotEmpty) {
      positionsByItemId[id] = positions.toList()..sort();
    }
  }

  return FactionKnowledge._(shown, positionsByItemId, {
    for (final faction in shown) faction.mergeKey: faction.displayName,
  });
}

final shipFactionKnowledgeProvider = Provider.family<FactionKnowledge, bool>((
  ref,
  onlyEnabledMods,
) {
  return buildFactionKnowledge(
    factions: ref.watch(mergedFactionListProvider(onlyEnabledMods)),
    items: ref.watch(shipListNotifierProvider(onlyEnabledMods)).value ?? [],
    idOf: (ship) => ship.id,
    tagsOf: (ship) => ship.tags ?? const [],
    knownIdsOf: (faction) => faction.knownShipIds,
    knownTagsOf: (faction) => faction.knownShipTags,
  );
});

final weaponFactionKnowledgeProvider = Provider.family<FactionKnowledge, bool>((
  ref,
  onlyEnabledMods,
) {
  return buildFactionKnowledge(
    factions: ref.watch(mergedFactionListProvider(onlyEnabledMods)),
    items: ref.watch(weaponListNotifierProvider(onlyEnabledMods)).value ?? [],
    idOf: (weapon) => weapon.id,
    tagsOf: (weapon) => weapon.tagsAsSet,
    knownIdsOf: (faction) => faction.knownWeaponIds,
    knownTagsOf: (faction) => faction.knownWeaponTags,
  );
});

final wingFactionKnowledgeProvider = Provider.family<FactionKnowledge, bool>((
  ref,
  onlyEnabledMods,
) {
  return buildFactionKnowledge(
    factions: ref.watch(mergedFactionListProvider(onlyEnabledMods)),
    items: ref.watch(wingListNotifierProvider).value ?? [],
    idOf: (wing) => wing.id,
    tagsOf: (wing) =>
        wing.tags?.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty) ??
        const [],
    knownIdsOf: (faction) => faction.knownFighterIds,
    knownTagsOf: (faction) => faction.knownFighterTags,
  );
});

/// Groups grid rows by faction. A row known by several factions appears under
/// each of them.
class FactionGridGroup<T extends WispGridItem> extends WispGridGroup<T> {
  /// Sorts "No Faction" after every real faction.
  static const int noFactionSortValue = 1 << 30;

  final FactionKnowledge knowledge;

  FactionGridGroup(this.knowledge) : super('faction', 'Faction');

  @override
  String getGroupName(T item, {Comparable? groupSortValue}) {
    final sortValue = groupSortValue ?? getGroupSortValue(item);
    return knowledge.nameAtSortPosition(sortValue as int) ?? 'No Faction';
  }

  @override
  Comparable getGroupSortValue(T item) =>
      knowledge.sortPositionsOf(item.key).firstOrNull ?? noFactionSortValue;

  @override
  List<Comparable?> getAllGroupSortValues(T item) {
    final positions = knowledge.sortPositionsOf(item.key);
    return positions.isEmpty ? [noFactionSortValue] : positions;
  }
}
