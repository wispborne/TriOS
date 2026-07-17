import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/extensions.dart';

void main() {
  group('parseJsonToMap', () {
    test('valid JSON passes through unchanged', () {
      const input = '{"key": "value", "num": 42}';
      final result = input.parseJsonToMap();
      expect(result['key'], 'value');
      expect(result['num'], 42);
    });

    test('replaces semicolons used as value separators', () {
      const input = '''
{
  "id": "test_wpn",
  "type": "BALLISTIC";
  "size": "LARGE"
}''';
      final result = input.parseJsonToMap();
      expect(result['id'], 'test_wpn');
      expect(result['type'], 'BALLISTIC');
      expect(result['size'], 'LARGE');
    });

    test('preserves semicolons inside string values', () {
      const input = '''
{
  "desc": "hello; world",
  "type": "BALLISTIC"
}''';
      final result = input.parseJsonToMap();
      expect(result['desc'], 'hello; world');
    });

    test('removes trailing commas', () {
      const input = '{"key": "value"},';
      final result = input.parseJsonToMap();
      expect(result['key'], 'value');
    });

    test('replaces tabs with spaces', () {
      const input = '{\t"key":\t"value"}';
      final result = input.parseJsonToMap();
      expect(result['key'], 'value');
    });

    test('removes // comment lines', () {
      const input = '''
{
  // this is a comment
  "key": "value"
}''';
      final result = input.parseJsonToMap();
      expect(result['key'], 'value');
    });

    test('replaces escaped hashes', () {
      const input = r'{"key": "color\#ff0000"}';
      final result = input.parseJsonToMap();
      expect(result['key'], 'color#ff0000');
    });

    test('handles combination of issues', () {
      const input = '''
{
  // weapon config
  "id": "ork_rightarm_wpn",
  "type": "BALLISTIC";
  "size": "LARGE";
  "turretOffsets": [10, 0]
}''';
      final result = input.parseJsonToMap();
      expect(result['id'], 'ork_rightarm_wpn');
      expect(result['type'], 'BALLISTIC');
      expect(result['size'], 'LARGE');
      expect(result['turretOffsets'], [10, 0]);
    });

    test('handles unquoted map keys without space after colon', () {
      const input = '''
{
  "hullId": "ms_kobold",
  "builtInWeapons": {
    WS0001:"ms_splinterKol",
    WS0002:"ms_pdburstCustom"
  },
  "builtInMods": [
    "ms_enjector",
    "no_weapon_flux"
  ]
}''';
      final result = input.parseJsonToMap();
      expect(result['hullId'], 'ms_kobold');
      expect(result['builtInWeapons'], {
        'WS0001': 'ms_splinterKol',
        'WS0002': 'ms_pdburstCustom',
      });
      expect(result['builtInMods'], ['ms_enjector', 'no_weapon_flux']);
    });

    test('preserves empty strings in lists', () {
      const input = '''
{
  "tags": [""],
  "removeBuiltInMods": [""],
  "emptyList": []
}''';
      final result = input.parseJsonToMap();
      expect(result['tags'], ['']);
      expect(result['removeBuiltInMods'], ['']);
      expect(result['emptyList'], []);
    });

    // Java-style literals like `1f` or `3d` are ambiguous: fleet weights mean
    // the number, but `.version` files use `"patch": 3d` to mean the string
    // "3d". The parser must not guess — it keeps them as strings, and readers
    // that expect a number use toDoubleOrNullAllowingJavaSuffix().
    test('keeps Java float suffix as a string, does not strip it', () {
      const input = '{"a":1f}';
      final result = input.parseJsonToMap();
      expect(result['a'], '1f');
    });

    test('leaves a quoted "1f" alone', () {
      const input = '{"a":"1f", "b":1f}';
      final result = input.parseJsonToMap();
      expect(result['a'], '1f');
      expect(result['b'], '1f');
    });

    test('keeps suffixed values inside arrays as strings', () {
      const input = '{"a":[1f, 2.5f]}';
      final result = input.parseJsonToMap();
      expect(result['a'], ['1f', '2.5f']);
    });

    test('keeps version-file patch values like 3d as strings', () {
      const input = '{"modVersion":{"major":1, "minor":1, "patch":3d}}';
      final result = input.parseJsonToMap();
      expect(result['modVersion']['patch'], '3d');
    });

    test('handles the real-world weapon file from bug report', () {
      const input = '''
{
  "id":"ork_rightarm_wpn",
  "specClass":"projectile",
  "type":"BALLISTIC",
  "size":"LARGE",
  "displayArcRadius":400,
  "everyFrameEffect":"data.scripts.weapons.bt_arm_everyframe";
  "turretSprite":"graphics/ships/despot/ork_despot_punch_r.png",
  "hardpointSprite":"graphics/ships/despot/ork_despot_punch_r.png",
  "turretOffsets":[10, 0],
  "turretAngleOffsets":[0],
  "hardpointOffsets":[15, 0],
  "hardpointAngleOffsets":[0],
  "barrelMode":"ALTERNATING",
  "animationType":"NONE",
  "muzzleFlashSpec":{"length":25.0,
             "spread":16.0,
             "particleSizeMin":12.0,
             "particleSizeRange":15.0,
             "particleDuration":0.4,
             "particleCount":12,
             "particleColor":[255,125,105,255]},
  "projectileSpecId":"bt_invis",
  "fireSoundTwo":"bt_mech_punch"
}''';
      final result = input.parseJsonToMap();
      expect(result['id'], 'ork_rightarm_wpn');
      expect(result['everyFrameEffect'],
          'data.scripts.weapons.bt_arm_everyframe');
      expect(result['turretOffsets'], [10, 0]);
      expect(result['muzzleFlashSpec']['particleCount'], 12);
    });
  });

  group('toDoubleOrNullAllowingJavaSuffix', () {
    test('parses plain numbers', () {
      expect('1'.toDoubleOrNullAllowingJavaSuffix(), 1.0);
      expect('2.5'.toDoubleOrNullAllowingJavaSuffix(), 2.5);
      expect('-3'.toDoubleOrNullAllowingJavaSuffix(), -3.0);
    });

    test('parses Java-style suffixed literals', () {
      expect('1f'.toDoubleOrNullAllowingJavaSuffix(), 1.0);
      expect('1F'.toDoubleOrNullAllowingJavaSuffix(), 1.0);
      expect('-2.5d'.toDoubleOrNullAllowingJavaSuffix(), -2.5);
      expect('3D'.toDoubleOrNullAllowingJavaSuffix(), 3.0);
    });

    test('rejects non-numbers', () {
      expect('d'.toDoubleOrNullAllowingJavaSuffix(), null);
      expect('1x'.toDoubleOrNullAllowingJavaSuffix(), null);
      expect('1fd'.toDoubleOrNullAllowingJavaSuffix(), null);
      expect(''.toDoubleOrNullAllowingJavaSuffix(), null);
    });
  });
}
