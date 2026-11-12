import 'package:flutter_test/flutter_test.dart';
import 'package:trios/faction_viewer/faction_knowledge.dart';
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';

class _Item implements WispGridItem {
  @override
  final String key;
  final List<String> tags;

  _Item(this.key, [this.tags = const []]);
}

Faction _faction(
  String key,
  String name, {
  List<String> ids = const [],
  List<String> tags = const [],
  bool shown = true,
}) => Faction(
  mergeKey: key,
  id: key,
  displayName: name,
  knownShipIds: ids,
  knownShipTags: tags,
  showInIntelTab: shown,
);

FactionKnowledge _knowledge(List<Faction> factions, List<_Item> items) =>
    buildFactionKnowledge<_Item>(
      factions: factions,
      items: items,
      idOf: (item) => item.key,
      tagsOf: (item) => item.tags,
      knownIdsOf: (faction) => faction.knownShipIds,
      knownTagsOf: (faction) => faction.knownShipTags,
    );

void main() {
  test('matches by id and by tag, ignoring tag case, in name order', () {
    final knowledge = _knowledge(
      [
        _faction('tt', 'Tri-Tachyon', ids: ['wolf']),
        _faction('heg', 'Hegemony', tags: ['BASE_bp']),
      ],
      [
        _Item('wolf', ['base_bp']),
        _Item('lasher', ['base_bp']),
        _Item('hidden'),
      ],
    );

    expect(knowledge.factionKeysOf('wolf'), ['heg', 'tt']);
    expect(knowledge.factionNamesOf('wolf'), 'Hegemony, Tri-Tachyon');
    expect(knowledge.factionKeysOf('lasher'), ['heg']);
    expect(knowledge.factionKeysOf('hidden'), isEmpty);
  });

  test('a faction listing a ship by id and by tag only counts once', () {
    final knowledge = _knowledge(
      [
        _faction('heg', 'Hegemony', ids: ['wolf'], tags: ['base_bp']),
      ],
      [
        _Item('wolf', ['base_bp']),
      ],
    );

    expect(knowledge.factionKeysOf('wolf'), ['heg']);
  });

  test('leaves out factions the game hides from the intel tab', () {
    final knowledge = _knowledge(
      [
        _faction('remnants', 'Remnant', ids: ['radiant'], shown: false),
      ],
      [_Item('radiant')],
    );

    expect(knowledge.factionKeysOf('radiant'), isEmpty);
    expect(knowledge.nameOf('remnants'), 'remnants');
  });

  test('grid group lists a row under each faction, and no faction last', () {
    final wolf = _Item('wolf');
    final orphan = _Item('orphan');
    final group = FactionGridGroup<_Item>(
      _knowledge(
        [
          _faction('tt', 'Tri-Tachyon', ids: ['wolf']),
          _faction('heg', 'Hegemony', ids: ['wolf']),
        ],
        [wolf, orphan],
      ),
    );

    expect(group.getAllGroupSortValues(wolf), [0, 1]);
    expect(group.getGroupName(wolf, groupSortValue: 1), 'Tri-Tachyon');
    expect(group.getAllGroupSortValues(orphan), [
      FactionGridGroup.noFactionSortValue,
    ]);
    expect(group.getGroupName(orphan), 'No Faction');
  });
}
