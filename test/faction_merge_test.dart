import 'package:flutter_test/flutter_test.dart';
import 'package:trios/faction_viewer/faction_merge.dart';
import 'package:trios/faction_viewer/models/faction.dart';

void main() {
  group('mergeFactionJson', () {
    test('arrays are additive', () {
      final base = {
        'knownShips': {
          'hulls': ['cerberus', 'crig'],
        },
      };
      final overlay = {
        'knownShips': {
          'hulls': ['custom_ship'],
        },
      };

      final result = mergeFactionJson(
        base: base,
        overlay: overlay,
        sourceName: 'TestMod',
        existingAttributions: {},
        existingItemAttributions: {},
      );

      final hulls =
          (result.merged['knownShips'] as Map)['hulls'] as List;
      expect(hulls, ['cerberus', 'crig', 'custom_ship']);
    });

    test('scalars are last-write-wins', () {
      final base = {
        'displayName': 'Hegemony',
        'factionDoctrine': {'aggression': 3},
      };
      final overlay = {
        'displayName': 'New Hegemony',
        'factionDoctrine': {'aggression': 5},
      };

      final result = mergeFactionJson(
        base: base,
        overlay: overlay,
        sourceName: 'TestMod',
        existingAttributions: {},
        existingItemAttributions: {},
      );

      expect(result.merged['displayName'], 'New Hegemony');
      expect(
        (result.merged['factionDoctrine'] as Map)['aggression'],
        5,
      );
    });

    test('core_clearArray clears base array before adding', () {
      final base = {
        'knownShips': {
          'hulls': ['cerberus', 'crig', 'ox'],
        },
      };
      final overlay = {
        'knownShips': {
          'hulls': ['core_clearArray', 'custom_ship'],
        },
      };

      final result = mergeFactionJson(
        base: base,
        overlay: overlay,
        sourceName: 'TestMod',
        existingAttributions: {},
        existingItemAttributions: {},
      );

      final hulls =
          (result.merged['knownShips'] as Map)['hulls'] as List;
      expect(hulls, ['custom_ship']);
    });

    test('nested objects are recursively merged', () {
      final base = {
        'factionDoctrine': {
          'warships': 4,
          'carriers': 1,
          'aggression': 3,
        },
      };
      final overlay = {
        'factionDoctrine': {
          'aggression': 5,
        },
      };

      final result = mergeFactionJson(
        base: base,
        overlay: overlay,
        sourceName: 'TestMod',
        existingAttributions: {},
        existingItemAttributions: {},
      );

      final doctrine = result.merged['factionDoctrine'] as Map;
      expect(doctrine['warships'], 4);
      expect(doctrine['carriers'], 1);
      expect(doctrine['aggression'], 5);
    });

    test('color arrays are replaced entirely', () {
      final base = {'color': [200, 200, 200, 255]};
      final overlay = {'color': [100, 50, 50, 255]};

      final result = mergeFactionJson(
        base: base,
        overlay: overlay,
        sourceName: 'TestMod',
        existingAttributions: {},
        existingItemAttributions: {},
      );

      expect(result.merged['color'], [100, 50, 50, 255]);
    });

    test('music is replaced entirely', () {
      final base = {
        'music': {'theme': 'vanilla_theme', 'encounter_hostile': 'vanilla_battle'},
      };
      final overlay = {
        'music': {'theme': 'mod_theme'},
      };

      final result = mergeFactionJson(
        base: base,
        overlay: overlay,
        sourceName: 'TestMod',
        existingAttributions: {},
        existingItemAttributions: {},
      );

      final music = result.merged['music'] as Map;
      expect(music['theme'], 'mod_theme');
      expect(music.containsKey('encounter_hostile'), false);
    });

    test('per-section attribution tracks counts', () {
      final base = {
        'knownShips': {
          'hulls': ['a', 'b', 'c'],
        },
      };
      final overlay = {
        'knownShips': {
          'hulls': ['d', 'e'],
        },
      };

      final existingAttributions = {
        'knownShips.hulls': [
          const SourceContribution(source: 'Vanilla', count: 3),
        ],
      };

      final result = mergeFactionJson(
        base: base,
        overlay: overlay,
        sourceName: 'TestMod',
        existingAttributions: existingAttributions,
        existingItemAttributions: {},
      );

      final attr = result.attributions['knownShips.hulls']!;
      expect(attr.length, 2);
      expect(attr[0].source, 'Vanilla');
      expect(attr[0].count, 3);
      expect(attr[1].source, 'TestMod');
      expect(attr[1].count, 2);
    });

    test('scalar attribution names the last mod to write the value', () {
      final base = {
        'shipRoles': {
          'combatSmall': {'lasher_Assault': 10, 'vigilance_Standard': 5},
        },
      };
      final overlay = {
        'shipRoles': {
          'combatSmall': {'lasher_Assault': 2, 'mod_frigate_Standard': 8},
        },
      };

      final result = mergeFactionJson(
        base: base,
        overlay: overlay,
        sourceName: 'TestMod',
        existingAttributions: {},
        existingItemAttributions: {
          'shipRoles.combatSmall': {
            'lasher_Assault': 'Vanilla',
            'vigilance_Standard': 'Vanilla',
          },
        },
      );

      final weights =
          ((result.merged['shipRoles'] as Map)['combatSmall'] as Map);
      expect(weights['lasher_Assault'], 2);
      expect(weights['vigilance_Standard'], 5);
      expect(weights['mod_frigate_Standard'], 8);

      final attrs = result.itemAttributions['shipRoles.combatSmall']!;
      expect(attrs['lasher_Assault'], 'TestMod');
      expect(attrs['vigilance_Standard'], 'Vanilla');
      expect(attrs['mod_frigate_Standard'], 'TestMod');
    });

    test('a brand-new nested section still gets scalar attribution', () {
      final result = mergeFactionJson(
        base: {},
        overlay: {
          'hullFrequency': {
            'hulls': {'onslaught': 10},
          },
        },
        sourceName: 'TestMod',
        existingAttributions: {},
        existingItemAttributions: {},
      );

      expect(
        (result.merged['hullFrequency'] as Map)['hulls'],
        {'onslaught': 10},
      );
      expect(
        result.itemAttributions['hullFrequency.hulls']!['onslaught'],
        'TestMod',
      );
    });

    test('core_clearArray resets attribution for that source', () {
      final base = {
        'knownWeapons': {
          'weapons': ['w1', 'w2', 'w3'],
        },
      };
      final overlay = {
        'knownWeapons': {
          'weapons': ['core_clearArray', 'mod_w1'],
        },
      };

      final existingAttributions = {
        'knownWeapons.weapons': [
          const SourceContribution(source: 'Vanilla', count: 3),
        ],
      };

      final result = mergeFactionJson(
        base: base,
        overlay: overlay,
        sourceName: 'TestMod',
        existingAttributions: existingAttributions,
        existingItemAttributions: {},
      );

      final weapons =
          (result.merged['knownWeapons'] as Map)['weapons'] as List;
      expect(weapons, ['mod_w1']);

      final attr = result.attributions['knownWeapons.weapons']!;
      expect(attr.any((c) => c.source == 'TestMod' && c.count == 1), true);
    });
  });
}
