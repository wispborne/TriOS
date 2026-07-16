import 'package:flutter_test/flutter_test.dart';
import 'package:trios/faction_viewer/factions_csv.dart';
import 'package:trios/faction_viewer/models/faction.dart';

void main() {
  group('parseFactionsCsvKeys', () {
    test('parses vanilla-style rows and skips the header', () {
      const csv = '''
faction
data/world/factions/neutral.faction
data/world/factions/hegemony.faction
''';
      expect(parseFactionsCsvKeys(csv), {'neutral', 'hegemony'});
    });

    test('keeps subfolder paths as part of the key', () {
      const csv = '''
faction
data/world/factions/submarkets/researchfacil.faction
''';
      expect(parseFactionsCsvKeys(csv), {'submarkets/researchfacil'});
    });

    test('handles comments, blank lines, and whitespace', () {
      const csv = '''
faction
# a comment line
data/world/factions/adversary.faction  # trailing comment

  data/world/factions/other.faction
''';
      expect(parseFactionsCsvKeys(csv), {'adversary', 'other'});
    });

    test('normalizes backslashes and uppercase', () {
      const csv = r'''
faction
data\world\factions\MyFaction.faction
''';
      expect(parseFactionsCsvKeys(csv), {'myfaction'});
    });

    test('unquotes quoted cells and ignores extra columns', () {
      const csv = '''
faction,notes
"data/world/factions/quoted.faction",some note
''';
      expect(parseFactionsCsvKeys(csv), {'quoted'});
    });

    test('keeps full path for rows outside data/world/factions', () {
      const csv = '''
faction
data/factions/elsewhere.faction
''';
      expect(parseFactionsCsvKeys(csv), {'data/factions/elsewhere'});
    });

    test('returns empty set for empty or header-only content', () {
      expect(parseFactionsCsvKeys(''), isEmpty);
      expect(parseFactionsCsvKeys('faction\n'), isEmpty);
    });
  });

  group('Faction.addedBy / modifiedBy', () {
    Faction factionWith(List<FactionSource> sources) => Faction(
      mergeKey: 'test',
      id: 'test',
      displayName: 'Test',
      sources: sources,
    );

    test('the registering source wins even when a patch loads first', () {
      const patcher = FactionSource(name: 'Patch Mod');
      const owner = FactionSource(name: 'Owner Mod', registersFaction: true);
      final faction = factionWith(const [patcher, owner]);

      expect(faction.addedBy, same(owner));
      expect(faction.modifiedBy, [patcher]);
    });

    test('no registrant means addedBy is null and all sources are modifiers',
        () {
      const a = FactionSource(name: 'A');
      const b = FactionSource(name: 'B');
      final faction = factionWith(const [a, b]);

      expect(faction.addedBy, isNull);
      expect(faction.modifiedBy, [a, b]);
    });

    test('first registrant wins when multiple sources register', () {
      const first = FactionSource(name: 'First', registersFaction: true);
      const second = FactionSource(name: 'Second', registersFaction: true);
      final faction = factionWith(const [first, second]);

      expect(faction.addedBy, same(first));
      expect(faction.modifiedBy, [second]);
    });

    test('tooltip covers added, modified, and patch-only cases', () {
      const owner = FactionSource(name: 'Owner', registersFaction: true);
      const patcher = FactionSource(name: 'Patcher');

      expect(
        factionWith(const [owner]).attributionTooltip,
        'Added by: Owner',
      );
      expect(
        factionWith(const [owner, patcher]).attributionTooltip,
        'Added by: Owner\nModified by: Patcher',
      );
      expect(
        factionWith(const [patcher]).attributionTooltip,
        'Not added by any enabled mod — it may belong to a disabled mod.\n'
        'Modified by: Patcher',
      );
      expect(factionWith(const []).attributionTooltip, '');
    });
  });
}
