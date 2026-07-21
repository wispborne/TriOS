import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/game_data_merge.dart';

/// A stand-in source. Tests that don't go through [orderedSources] don't need a
/// real mod folder behind them.
MergeSource _mod(String name) => MergeSource(key: name, name: name);

const _vanilla = MergeSource.vanilla;

ModVariant _variant(String name, {String? sortString}) => ModVariant(
  modInfo: ModInfo(
    id: name.toLowerCase().replaceAll(' ', '_'),
    name: name,
    version: Version.parse('1.0.0'),
    sortString: sortString,
  ),
  versionCheckerInfo: null,
  modFolder: Directory(name),
  hasNonBrickedModInfo: true,
  gameCoreFolder: Directory('core'),
);

/// Shorthand for a plain deep merge of whole files, in [orderedSources] order.
DeepMergeResult _deep(List<SourceJson> sources) => mergeShipRoles(sources);

void main() {
  group('orderedSources (R1)', () {
    test('mods come first in load order and vanilla comes last', () {
      final sources = orderedSources([_variant('Zeta'), _variant('Alpha')]);

      expect(sources.map((s) => s.name), ['Alpha', 'Zeta', 'Vanilla']);
      expect(sources.last.isVanilla, isTrue);
    });

    test('two mods with no sortString order by display name', () {
      final sources = orderedSources([
        _variant('Blackrock Drive Yards'),
        _variant('Blackrock 0.97 Unofficial Add-on'),
      ]);

      expect(sources.first.name, 'Blackrock 0.97 Unofficial Add-on');
      expect(sources[1].name, 'Blackrock Drive Yards');
    });

    test('sortString is used instead of the display name', () {
      final sources = orderedSources([
        _variant('Aardvark'),
        _variant('Zeta', sortString: 'A'),
      ]);

      expect(sources.first.name, 'Zeta');
      expect(sources[1].name, 'Aardvark');
    });

    test('an empty sortString counts as absent, same as null', () {
      final sources = orderedSources([
        _variant('Zeta', sortString: ''),
        _variant('Alpha'),
      ]);

      expect(sources.map((s) => s.name).take(2), ['Alpha', 'Zeta']);
    });
  });

  group('mergeById (R2)', () {
    test('the first source to claim an id wins, vanilla included', () {
      final merged = mergeById<Map<String, dynamic>>([
        (
          source: _mod('A-mod'),
          items: [
            {'id': 'lightmg', 'damage': 50},
          ],
        ),
        (
          source: _mod('Z-mod'),
          items: [
            {'id': 'lightmg', 'damage': 99},
          ],
        ),
        (
          source: _vanilla,
          items: [
            {'id': 'lightmg', 'damage': 10},
          ],
        ),
      ], (row) => row['id'] as String);

      expect(merged.single['damage'], 50);
    });

    test('a mod beats vanilla', () {
      final merged = mergeById<Map<String, dynamic>>([
        (
          source: _mod('Rebalance'),
          items: [
            {'id': 'lightmg', 'damage': 99},
          ],
        ),
        (
          source: _vanilla,
          items: [
            {'id': 'lightmg', 'damage': 10},
          ],
        ),
      ], (row) => row['id'] as String);

      expect(merged.single['damage'], 99);
    });
  });

  group('mergeDescriptions (R2)', () {
    test('keys on id and type together', () {
      final merged = mergeDescriptions([
        (
          source: _mod('A-mod'),
          items: [
            {'id': 'onslaught', 'type': 'SHIP', 'text1': 'from A'},
          ],
        ),
        (
          source: _vanilla,
          items: [
            {'id': 'onslaught', 'type': 'SHIP', 'text1': 'vanilla ship'},
            {'id': 'onslaught', 'type': 'CUSTOM', 'text1': 'vanilla custom'},
          ],
        ),
      ]);

      expect(merged.length, 2);
      final ship = merged.firstWhere((m) => m.row['type'] == 'SHIP');
      final custom = merged.firstWhere((m) => m.row['type'] == 'CUSTOM');
      expect(ship.row['text1'], 'from A');
      expect(ship.source.name, 'A-mod');
      expect(custom.row['text1'], 'vanilla custom');
    });

    test('the alphabetically first mod wins', () {
      final merged = mergeDescriptions([
        (
          source: _mod('A-mod'),
          items: [
            {'id': 'x', 'type': 'SHIP', 'text1': 'A'},
          ],
        ),
        (
          source: _mod('Z-mod'),
          items: [
            {'id': 'x', 'type': 'SHIP', 'text1': 'Z'},
          ],
        ),
      ]);

      expect(merged.single.row['text1'], 'A');
    });

    test('rows with every key column blank are skipped, not collapsed', () {
      final merged = mergeDescriptions([
        (
          source: _vanilla,
          items: [
            {'id': '', 'type': '', 'text1': 'spacer one'},
            {'id': '', 'type': '', 'text1': 'spacer two'},
            {'id': 'real', 'type': 'SHIP', 'text1': 'kept'},
          ],
        ),
      ]);

      expect(merged.length, 1);
      expect(merged.single.row['id'], 'real');
    });

    test('a duplicate key inside one source keeps the first row', () {
      final merged = mergeDescriptions([
        (
          source: _vanilla,
          items: [
            {'id': 'x', 'type': 'SHIP', 'text1': 'first'},
            {'id': 'x', 'type': 'SHIP', 'text1': 'second'},
          ],
        ),
      ]);

      expect(merged.single.row['text1'], 'first');
    });
  });

  group('deep merge (R3)', () {
    test('vanilla is the base and the last mod applied wins a value', () {
      final result = _deep([
        (
          source: _mod('A-mod'),
          json: {'fireSoundTwo': 'a_sound'},
        ),
        (
          source: _mod('Z-mod'),
          json: {'fireSoundTwo': 'z_sound'},
        ),
        (
          source: _vanilla,
          json: {'fireSoundTwo': 'vanilla_sound'},
        ),
      ]);

      // The opposite of the spreadsheet rule right above: there A-mod wins.
      expect(result.merged['fireSoundTwo'], 'z_sound');
      expect(result.winningSource?.name, 'Z-mod');
    });

    test('a partial file keeps the fields it does not mention', () {
      final result = _deep([
        (
          source: _mod('B-mod'),
          json: {'fireSoundTwo': 'b_sound'},
        ),
        (
          source: _vanilla,
          json: {
            'fireSoundTwo': 'vanilla_sound',
            'specClass': 'projectile',
            'size': 'MEDIUM',
          },
        ),
      ]);

      expect(result.merged['fireSoundTwo'], 'b_sound');
      expect(result.merged['specClass'], 'projectile');
      expect(result.merged['size'], 'MEDIUM');
    });

    test('nested objects merge field by field', () {
      final result = _deep([
        (
          source: _mod('A-mod'),
          json: {
            'factionDoctrine': {'aggression': 5},
          },
        ),
        (
          source: _vanilla,
          json: {
            'factionDoctrine': {'warships': 4, 'carriers': 1, 'aggression': 3},
          },
        ),
      ]);

      final doctrine = result.merged['factionDoctrine'] as Map;
      expect(doctrine['warships'], 4);
      expect(doctrine['carriers'], 1);
      expect(doctrine['aggression'], 5);
    });

    test('plain lists append', () {
      final result = _deep([
        (
          source: _mod('A-mod'),
          json: {
            'knownShips': {
              'hulls': ['custom_ship'],
            },
          },
        ),
        (
          source: _vanilla,
          json: {
            'knownShips': {
              'hulls': ['cerberus', 'crig'],
            },
          },
        ),
      ]);

      expect((result.merged['knownShips'] as Map)['hulls'], [
        'cerberus',
        'crig',
        'custom_ship',
      ]);
    });

    test('core_clearArray wipes the base list and does not survive', () {
      final result = _deep([
        (
          source: _mod('A-mod'),
          json: {
            'knownShips': {
              'hulls': ['core_clearArray', 'custom_ship'],
            },
          },
        ),
        (
          source: _vanilla,
          json: {
            'knownShips': {
              'hulls': ['cerberus', 'crig', 'ox'],
            },
          },
        ),
      ]);

      expect((result.merged['knownShips'] as Map)['hulls'], ['custom_ship']);
    });

    test('core_clearArray only counts at index 0', () {
      final result = _deep([
        (
          source: _mod('A-mod'),
          json: {
            'knownShips': {
              'hulls': ['custom_ship', 'core_clearArray'],
            },
          },
        ),
        (
          source: _vanilla,
          json: {
            'knownShips': {
              'hulls': ['cerberus'],
            },
          },
        ),
      ]);

      expect((result.merged['knownShips'] as Map)['hulls'], [
        'cerberus',
        'custom_ship',
      ]);
    });

    test('a 4-entry colour list replaces whole', () {
      final result = _deep([
        (
          source: _mod('A-mod'),
          json: {
            'color': [100, 50, 50, 255],
          },
        ),
        (
          source: _vanilla,
          json: {
            'color': [200, 200, 200, 255],
          },
        ),
      ]);

      expect(result.merged['color'], [100, 50, 50, 255]);
    });

    test('a 4-entry "button" list replaces whole too', () {
      final result = _deep([
        (
          source: _mod('A-mod'),
          json: {
            'buttonBg': [1, 2, 3, 4],
          },
        ),
        (
          source: _vanilla,
          json: {
            'buttonBg': [9, 9, 9, 9],
          },
        ),
      ]);

      expect(result.merged['buttonBg'], [1, 2, 3, 4]);
    });

    test('a 3-entry colour list still appends — the count gates the rule', () {
      final result = _deep([
        (
          source: _mod('A-mod'),
          json: {
            'color': [1, 2, 3],
          },
        ),
        (
          source: _vanilla,
          json: {
            'color': [9, 9, 9],
          },
        ),
      ]);

      expect(result.merged['color'], [9, 9, 9, 1, 2, 3]);
    });

    test('a music_ list replaces whole at any length', () {
      final result = _deep([
        (
          source: _mod('A-mod'),
          json: {
            'music_custom': ['mod_track'],
          },
        ),
        (
          source: _vanilla,
          json: {
            'music_custom': ['t1', 't2'],
          },
        ),
      ]);

      expect(result.merged['music_custom'], ['mod_track']);
    });

    test('a plain "music" object deep merges like any other object', () {
      final result = _deep([
        (
          source: _mod('A-mod'),
          json: {
            'music': {'theme': 'mod_theme'},
          },
        ),
        (
          source: _vanilla,
          json: {
            'music': {
              'theme': 'vanilla_theme',
              'encounter_hostile': 'vanilla_battle',
            },
          },
        ),
      ]);

      final music = result.merged['music'] as Map;
      expect(music['theme'], 'mod_theme');
      expect(music['encounter_hostile'], 'vanilla_battle');
    });

    test('a wrong value shape is skipped and the base value kept', () {
      final result = _deep([
        (
          source: _mod('A-mod'),
          json: {
            'hulls': {'oops': 1},
          },
        ),
        (
          source: _vanilla,
          json: {
            'hulls': ['cerberus'],
          },
        ),
      ]);

      expect(result.merged['hulls'], ['cerberus']);
    });

    test('per-section attribution counts what each source added', () {
      final result = _deep([
        (
          source: _mod('TestMod'),
          json: {
            'knownShips': {
              'hulls': ['d', 'e'],
            },
          },
        ),
        (
          source: _vanilla,
          json: {
            'knownShips': {
              'hulls': ['a', 'b', 'c'],
            },
          },
        ),
      ]);

      final attribution = result.sectionAttributions['knownShips.hulls']!;
      expect(attribution.length, 2);
      expect(attribution[0], (source: 'Vanilla', count: 3));
      expect(attribution[1], (source: 'TestMod', count: 2));
    });

    test('scalar attribution names the last source to write the value', () {
      final result = _deep([
        (
          source: _mod('TestMod'),
          json: {
            'shipRoles': {
              'combatSmall': {'lasher_Assault': 2, 'mod_frigate_Standard': 8},
            },
          },
        ),
        (
          source: _vanilla,
          json: {
            'shipRoles': {
              'combatSmall': {'lasher_Assault': 10, 'vigilance_Standard': 5},
            },
          },
        ),
      ]);

      final weights =
          (result.merged['shipRoles'] as Map)['combatSmall'] as Map;
      expect(weights['lasher_Assault'], 2);
      expect(weights['vigilance_Standard'], 5);
      expect(weights['mod_frigate_Standard'], 8);

      final attributions = result.itemAttributions['shipRoles.combatSmall']!;
      expect(attributions['lasher_Assault'], 'TestMod');
      expect(attributions['vigilance_Standard'], 'Vanilla');
      expect(attributions['mod_frigate_Standard'], 'TestMod');
    });

    test('core_clearArray resets the attribution for that list', () {
      final result = _deep([
        (
          source: _mod('TestMod'),
          json: {
            'knownWeapons': {
              'weapons': ['core_clearArray', 'mod_w1'],
            },
          },
        ),
        (
          source: _vanilla,
          json: {
            'knownWeapons': {
              'weapons': ['w1', 'w2', 'w3'],
            },
          },
        ),
      ]);

      expect((result.merged['knownWeapons'] as Map)['weapons'], ['mod_w1']);
      expect(result.sectionAttributions['knownWeapons.weapons'], [
        (source: 'TestMod', count: 1),
      ]);
    });
  });

  group('mergeFactions (R3)', () {
    test('files pair up by path, not by the id inside them', () {
      final merged = mergeFactions([
        (
          source: _mod('A-mod'),
          filesByPath: {
            'persean_league': {'displayName': 'Modded League'},
          },
        ),
        (
          source: _vanilla,
          filesByPath: {
            'persean_league': {'id': 'persean', 'displayName': 'Persean League'},
          },
        ),
      ]);

      expect(merged.keys, ['persean_league']);
      expect(merged['persean_league']!.merged['id'], 'persean');
      expect(merged['persean_league']!.merged['displayName'], 'Modded League');
    });

    test('contributors are listed in the order they were applied', () {
      final merged = mergeFactions([
        (
          source: _mod('Z-mod'),
          filesByPath: {
            'hegemony': {'displayName': 'Z'},
          },
        ),
        (
          source: _mod('A-mod'),
          filesByPath: {
            'hegemony': {'displayName': 'A'},
          },
        ),
        (
          source: _vanilla,
          filesByPath: {
            'hegemony': {'displayName': 'Hegemony'},
          },
        ),
      ]);

      expect(merged['hegemony']!.contributors.map((s) => s.name), [
        'Vanilla',
        'Z-mod',
        'A-mod',
      ]);
    });
  });

  group('mergeWeapons (R4)', () {
    test('a CSV-only add-on keeps the parent mod\'s sprite', () {
      final specs = mergeWeapons(
        rows: [
          (
            source: _mod('B-addon'),
            items: [
              {'id': 'foo', 'damage': 999},
            ],
          ),
          (
            source: _mod('A-parent'),
            items: [
              {'id': 'foo', 'damage': 100},
            ],
          ),
        ],
        sideFiles: [
          (source: _mod('B-addon'), filesByPath: {}),
          (
            source: _mod('A-parent'),
            filesByPath: {
              'foo.wpn': {'id': 'foo', 'turretSprite': 'foo.png'},
            },
          ),
        ],
      );

      final foo = specs.single;
      expect(foo.row['damage'], 999);
      expect(foo.rowSource.name, 'B-addon');
      expect(foo.sideFile!['turretSprite'], 'foo.png');
      expect(foo.sideFileSource!.name, 'A-parent');
    });

    test('the CSV winner and the side-file winner run opposite ways', () {
      final specs = mergeWeapons(
        rows: [
          (
            source: _mod('A-mod'),
            items: [
              {'id': 'laser', 'damage': 1},
            ],
          ),
          (
            source: _mod('Z-mod'),
            items: [
              {'id': 'laser', 'damage': 2},
            ],
          ),
        ],
        sideFiles: [
          (
            source: _mod('A-mod'),
            filesByPath: {
              'laser.wpn': {'id': 'laser', 'fireSoundTwo': 'a'},
            },
          ),
          (
            source: _mod('Z-mod'),
            filesByPath: {
              'laser.wpn': {'id': 'laser', 'fireSoundTwo': 'z'},
            },
          ),
        ],
      );

      // Same two mods, different winner, depending only on which file the
      // value came from.
      expect(specs.single.row['damage'], 1, reason: 'CSV: first mod wins');
      expect(
        specs.single.sideFile!['fireSoundTwo'],
        'z',
        reason: 'side file: last mod wins',
      );
    });

    test('a CSV row with no side file anywhere still produces an item', () {
      final specs = mergeWeapons(
        rows: [
          (
            source: _mod('A-mod'),
            items: [
              {'id': 'orphan', 'damage': 5},
            ],
          ),
        ],
        sideFiles: [(source: _mod('A-mod'), filesByPath: {})],
      );

      expect(specs.single.id, 'orphan');
      expect(specs.single.sideFile, isNull);
    });

    test('a side file whose id has no CSV row produces nothing', () {
      final specs = mergeWeapons(
        rows: [(source: _mod('A-mod'), items: [])],
        sideFiles: [
          (
            source: _mod('A-mod'),
            filesByPath: {
              'ghost.wpn': {'id': 'ghost'},
            },
          ),
        ],
      );

      expect(specs, isEmpty);
    });

    test('across mods, the higher-priority source\'s file wins a clashing id', () {
      final specs = mergeWeapons(
        rows: [
          (
            source: _vanilla,
            items: [
              {'id': 'laser'},
            ],
          ),
        ],
        sideFiles: [
          (
            source: _mod('A-mod'),
            filesByPath: {
              'z_laser.wpn': {'id': 'laser', 'from': 'A'},
            },
          ),
          (
            source: _mod('Z-mod'),
            filesByPath: {
              'a_laser.wpn': {'id': 'laser', 'from': 'Z'},
            },
          ),
        ],
      );

      // Path names don't enter into it — A-mod is consulted first.
      expect(specs.single.sideFilePath, 'z_laser.wpn');
      expect(specs.single.sideFile!['from'], 'A');
    });

    test('inside one mod, the alphabetically first path wins', () {
      final specs = mergeWeapons(
        rows: [
          (
            source: _vanilla,
            items: [
              {'id': 'laser'},
            ],
          ),
        ],
        sideFiles: [
          (
            source: _mod('A-mod'),
            filesByPath: {
              'b_laser.wpn': {'id': 'laser', 'from': 'b'},
              'a_laser.wpn': {'id': 'laser', 'from': 'a'},
            },
          ),
        ],
      );

      expect(specs.single.sideFilePath, 'a_laser.wpn');
    });

    test('the Blackrock case end to end', () {
      final addon = _mod('Blackrock 0.97 Unofficial Add-on');
      final parent = _mod('Blackrock Drive Yards');

      final specs = mergeWeapons(
        rows: [
          (
            source: addon,
            items: [
              {'id': 'homing_laser', 'damage': 300},
            ],
          ),
          (
            source: parent,
            items: [
              {'id': 'homing_laser', 'damage': 250},
            ],
          ),
          (
            source: _vanilla,
            items: [
              {'id': 'lightmg', 'damage': 10},
            ],
          ),
        ],
        sideFiles: [
          // The add-on ships a CSV and no .wpn files at all.
          (source: addon, filesByPath: {}),
          (
            source: parent,
            filesByPath: {
              'homing_laser.wpn': {
                'id': 'homing_laser',
                'turretSprite': 'brdy/homing_laser.png',
              },
            },
          ),
          (source: _vanilla, filesByPath: {}),
        ],
      );

      final laser = specs.firstWhere((s) => s.id == 'homing_laser');
      expect(laser.row['damage'], 300, reason: 'the add-on wins the stats');
      expect(
        laser.sideFile!['turretSprite'],
        'brdy/homing_laser.png',
        reason: 'and the parent mod\'s sprite survives',
      );
    });
  });

  group('mergeShips (R4)', () {
    test('a CSV row with no .ship file is kept, not dropped', () {
      final specs = mergeShips(
        rows: [
          (
            source: _mod('A-mod'),
            items: [
              {'id': 'bar', 'hitpoints': 1000},
            ],
          ),
        ],
        sideFiles: [(source: _mod('A-mod'), filesByPath: {})],
      );

      expect(specs.single.id, 'bar');
      expect(specs.single.row['hitpoints'], 1000);
      expect(specs.single.sideFile, isNull);
    });
  });

  group('which mods changed this (mod sources)', () {
    test('every source with a row is a contributor, winner first', () {
      final specs = mergeWeapons(
        rows: [
          (
            source: _mod('A-mod'),
            items: [
              {'id': 'laser', 'damage': 1},
            ],
          ),
          (
            source: _mod('Z-mod'),
            items: [
              {'id': 'laser', 'damage': 2},
            ],
          ),
          (
            source: _vanilla,
            items: [
              {'id': 'laser', 'damage': 3},
            ],
          ),
        ],
        sideFiles: const [],
      );

      // First-wins order: the winner leads, the overridden rows follow.
      expect(specs.single.rowContributors.map((s) => s.name), [
        'A-mod',
        'Z-mod',
        'Vanilla',
      ]);
    });

    test('side-file contributors and the keys each source changed', () {
      final result = _deep([
        (source: _vanilla, json: {'spriteName': 'v.png', 'style': 'LOW_TECH'}),
        (
          source: _mod('Missing Ships'),
          json: {
            'spriteName': 'ms.png',
            'weaponSlots': [
              {'id': 'WS1'},
            ],
          },
        ),
      ]);

      final bySource = result.topLevelKeysBySource();
      // The mod is applied last, so it wins the sprite and adds a slot.
      expect(bySource['Missing Ships'], containsAll(['spriteName', 'weaponSlots']));
      // Vanilla only still owns the field the mod never touched.
      expect(bySource['Vanilla'], contains('style'));
      expect(bySource['Vanilla'], isNot(contains('spriteName')));
    });

    test('buildItemModSources splits stats winner and friendly areas', () {
      final nexerelin = _mod('Nexerelin');
      final missingShips = _mod('Missing Ships');

      final sources = buildItemModSources(
        rowContributors: [nexerelin, _vanilla],
        // Applied order: vanilla base, then the mod — so the mod wins.
        sideFileContributors: [_vanilla, missingShips],
        sideFileChangedKeys: {
          'Missing Ships': {'spriteName', 'weaponSlots', 'hullId'},
        },
        areaNames: const {
          'spriteName': 'sprite',
          'weaponSlots': 'weapon slots',
          'hullId': '',
        },
      );

      expect(sources.statsWinner, 'Nexerelin');
      expect(sources.statsIgnored, ['Vanilla']);

      // Winner leads; the game core is listed last as the base with no areas.
      expect(sources.fileWinner, 'Missing Ships');
      final winner = sources.fileSources.first;
      expect(winner.isWinner, isTrue);
      expect(winner.areas, ['sprite', 'weapon slots']); // hullId is hidden
      final base = sources.fileSources.last;
      expect(base.isVanilla, isTrue);
      expect(base.areas, isEmpty);
    });
  });
}
