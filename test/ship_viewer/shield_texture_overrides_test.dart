import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/ship_viewer/hull_styles_manager.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/game_data_merge.dart';

/// A stand-in mod. These tests don't read any files, so a name is enough.
MergeSource _mod(String name) => MergeSource(key: name, name: name);

/// Parses one mod's `trios.json` text the way the provider does.
ShieldTextureOverridePaths _parseOne(String json) =>
    parseShieldTextureOverrides(json.parseJsonToMap());

/// Merges several mods' `trios.json` files, listed in load order, then parses.
ShieldTextureOverridePaths _parseMerged(List<(String, String)> modsAndJson) =>
    parseShieldTextureOverrides(
      mergeTriosModConfig([
        for (final (name, json) in modsAndJson)
          (source: _mod(name), json: json.parseJsonToMap()),
      ]).merged,
    );

void main() {
  group('parsing trios.json', () {
    test('reads hullmod and hull entries', () {
      final paths = _parseOne('''
{
  "shields": {
    "byHullmod": {
      "kol_shields": {"textureInner": "graphics/kol/fx/kol_shield_fx.png"}
    },
    "byHull": {
      "zea_edf_kiyohime": {
        "textureInner": "graphics/zea/fx/zea_shield_elysia_2.png"
      }
    }
  }
}
''');

      expect(
        paths.byHullmod['kol_shields'],
        'graphics/kol/fx/kol_shield_fx.png',
      );
      expect(
        paths.byHull['zea_edf_kiyohime'],
        'graphics/zea/fx/zea_shield_elysia_2.png',
      );
    });

    test('a file with no shields section is empty, not an error', () {
      expect(_parseOne('{}').isEmpty, isTrue);
      expect(_parseOne('{"somethingElse": {"a": 1}}').isEmpty, isTrue);
    });

    test('unknown keys are ignored so the format can grow', () {
      final paths = _parseOne('''
{
  "version": 3,
  "shields": {
    "byHullmod": {
      "kol_shields": {
        "textureInner": "a.png",
        "textureRing": "unused.png",
        "innerRotationRate": 6,
        "somethingNew": "whatever"
      }
    },
    "byWeather": {"rain": {"textureInner": "b.png"}}
  },
  "futureSection": {"x": 1}
}
''');

      expect(paths.byHullmod['kol_shields'], 'a.png');
      expect(paths.byHullmod.length, 1);
      expect(paths.byHull, isEmpty);
    });

    test('entries shaped wrong are skipped, the rest still load', () {
      final paths = _parseOne('''
{
  "shields": {
    "byHullmod": {
      "good": {"textureInner": "good.png"},
      "notAMap": "oops",
      "emptyPath": {"textureInner": ""},
      "namesNothing": {"unrelated": 1},
      "ringOnly": {"textureRing": "ring.png"}
    }
  }
}
''');

      expect(paths.byHullmod.keys, ['good']);
    });
  });

  group('merging across mods', () {
    test('the last mod in load order wins an entry', () {
      final paths = _parseMerged([
        ('Alpha', '{"shields": {"byHullmod": {"shared": '
            '{"textureInner": "alpha.png"}}}}'),
        ('Zeta', '{"shields": {"byHullmod": {"shared": '
            '{"textureInner": "zeta.png"}}}}'),
      ]);

      expect(paths.byHullmod['shared'], 'zeta.png');
    });

    test('entries from different mods all survive', () {
      final paths = _parseMerged([
        ('Alpha', '{"shields": {"byHullmod": {"a_mod": '
            '{"textureInner": "a.png"}}}}'),
        ('Zeta', '{"shields": {"byHull": {"z_hull": '
            '{"textureInner": "z.png"}}}}'),
      ]);

      expect(paths.byHullmod['a_mod'], 'a.png');
      expect(paths.byHull['z_hull'], 'z.png');
    });
  });

  group("TriOS's built-in list versus a mod's own file", () {
    // The provider puts the built-in list first, so every mod is applied over
    // it. These tests use the same ordering.
    ShieldTextureOverridePaths withBuiltIn(String builtIn, String modFile) =>
        _parseMerged([('TriOS', builtIn), ('Some Mod', modFile)]);

    test('a mod replaces what TriOS ships for the same hullmod', () {
      final paths = withBuiltIn(
        '{"shields": {"byHullmod": {"kol_shields": '
        '{"textureInner": "triOS_guess.png"}}}}',
        '{"shields": {"byHullmod": {"kol_shields": '
        '{"textureInner": "the_real_one.png"}}}}',
      );

      expect(paths.byHullmod['kol_shields'], 'the_real_one.png');
    });

    test('a mod adds entries without losing the built-in ones', () {
      final paths = withBuiltIn(
        '{"shields": {"byHullmod": {"kol_shields": {"textureInner": "a.png"}}}}',
        '{"shields": {"byHullmod": {"new_mod": {"textureInner": "b.png"}}}}',
      );

      expect(paths.byHullmod['kol_shields'], 'a.png');
      expect(paths.byHullmod['new_mod'], 'b.png');
    });

    test('an empty textureInner clears a built-in entry', () {
      final paths = withBuiltIn(
        '{"shields": {"byHullmod": {"kol_shields": {"textureInner": "a.png"}}}}',
        '{"shields": {"byHullmod": {"kol_shields": {"textureInner": ""}}}}',
      );

      // Gone entirely, so the ship goes back to the vanilla shield.
      expect(paths.byHullmod.containsKey('kol_shields'), isFalse);
      expect(paths.forShip('kol_lotus', ['kol_shields']), isNull);
    });

    test('the built-in list stands on its own when no mod ships a file', () {
      final paths = _parseMerged([
        ('TriOS', '{"shields": {"byHullmod": {"kol_shields": '
            '{"textureInner": "a.png"}}}}'),
      ]);

      expect(paths.forShip('kol_lotus', ['kol_shields']), 'a.png');
    });
  });

  group('picking an override for a ship', () {
    final paths = _parseOne('''
{
  "shields": {
    "byHullmod": {
      "zea_edf_shield_style": {"textureInner": "elysia.png"},
      "zea_dawn_shield_style": {"textureInner": "dawn.png"}
    },
    "byHull": {
      "zea_edf_kiyohime": {"textureInner": "elysia_2.png"}
    }
  }
}
''');

    test('a built-in hullmod picks the texture', () {
      expect(
        paths.forShip('zea_edf_mizuchi', [
          'automated',
          'zea_edf_shield_style',
        ]),
        'elysia.png',
      );
    });

    test('a hull entry beats the ship\'s hullmod', () {
      expect(
        paths.forShip('zea_edf_kiyohime', [
          'zea_edf_shield_style',
        ]),
        'elysia_2.png',
      );
    });

    test('the first listed hullmod with an entry wins', () {
      expect(
        paths.forShip('some_hull', [
          'zea_dawn_shield_style',
          'zea_edf_shield_style',
        ]),
        'dawn.png',
      );
    });

    test('no match means no override, so the vanilla shield is drawn', () {
      expect(paths.forShip('hound', ['civgrade']), isNull);
      expect(paths.forShip('hound', null), isNull);
      expect(paths.forShip('hound', const []), isNull);
    });
  });

  group('choosing the image to draw', () {
    test('an entry whose texture never loaded falls back to vanilla', () {
      final images = ShieldTextureImages(
        paths: _parseOne(
          '{"shields": {"byHullmod": {"kol_shields": '
          '{"textureInner": "missing.png"}}}}',
        ),
        // The provider drops textures it couldn't read, so the map is empty.
        fillsByPath: const {},
      );

      expect(images.fillFor('kol_lotus', ['kol_shields']), isNull);
    });

    test('a ship with no override asks for no image', () {
      expect(ShieldTextureImages.empty.fillFor('hound', ['civgrade']), isNull);
    });
  });

  group('the shield texture list TriOS ships', () {
    // Read straight off disk rather than through the asset bundle, which needs
    // a widget binding. Same file either way.
    final paths = parseShieldTextureOverrides(
      File(
        'assets/common/shield_textures.json',
      ).readAsStringSync().parseJsonToMap(),
    );

    test('parses, with entries in both maps', () {
      expect(paths.byHullmod, isNotEmpty);
      expect(paths.byHull, isNotEmpty);
    });

    test('every texture path looks like a game data path', () {
      for (final path in {...paths.byHullmod.values, ...paths.byHull.values}) {
        expect(path, startsWith('graphics/'), reason: path);
        expect(path, endsWith('.png'), reason: path);
        expect(path, isNot(contains('\\')), reason: 'use forward slashes');
      }
    });

    test('the Knights of Ludd entries are the ones we worked out', () {
      expect(
        paths.forShip('kol_lotus', ['kol_shields']),
        'graphics/kol/fx/kol_shield_fx.png',
      );
      expect(
        paths.forShip('zea_dawn_ao', ['zea_dawn_shield_style']),
        'graphics/zea/fx/zea_shield_dawn.png',
      );
      // Conformal shield hulls take the second Elysian texture.
      expect(
        paths.forShip('zea_edf_kiyohime', ['zea_edf_shield_style']),
        'graphics/zea/fx/zea_shield_elysia_2.png',
      );
      expect(
        paths.forShip('zea_edf_mizuchi', ['zea_edf_shield_style']),
        'graphics/zea/fx/zea_shield_elysia.png',
      );
    });

    test('VIC hulls get the texture matching their shield radius', () {
      // vic_dynamicshields picks by radius, so these are listed per hull.
      expect(
        paths.forShip('vic_apollyon', ['vic_dynamicshields']),
        'graphics/fx/shield/vic_shields256.png',
      );
      expect(
        paths.forShip('vic_kobal', ['vic_dynamicshields']),
        'graphics/fx/shield/vic_shields64.png',
      );
    });

    test('a vanilla ship is untouched by the list', () {
      expect(paths.forShip('hound', ['civgrade']), isNull);
      expect(paths.forShip('onslaught', null), isNull);
    });
  });
}
