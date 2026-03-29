import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/extensions.dart';

void main() {
  group('fixJson', () {
    test('valid JSON passes through unchanged', () {
      const input = '{"key": "value", "num": 42}';
      final result = jsonDecode(input.fixJson()) as Map<String, dynamic>;
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
      final result = jsonDecode(input.fixJson()) as Map<String, dynamic>;
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
      final result = jsonDecode(input.fixJson()) as Map<String, dynamic>;
      expect(result['desc'], 'hello; world');
    });

    test('removes trailing commas', () {
      const input = '{"key": "value"},';
      final result = jsonDecode(input.fixJson()) as Map<String, dynamic>;
      expect(result['key'], 'value');
    });

    test('replaces tabs with spaces', () {
      const input = '{\t"key":\t"value"}';
      final result = jsonDecode(input.fixJson()) as Map<String, dynamic>;
      expect(result['key'], 'value');
    });

    test('removes // comment lines', () {
      const input = '''
{
  // this is a comment
  "key": "value"
}''';
      final result = jsonDecode(input.fixJson()) as Map<String, dynamic>;
      expect(result['key'], 'value');
    });

    test('replaces escaped hashes', () {
      const input = r'{"key": "color\#ff0000"}';
      final result = jsonDecode(input.fixJson()) as Map<String, dynamic>;
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
      final result = jsonDecode(input.fixJson()) as Map<String, dynamic>;
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
      final result = jsonDecode(input.fixJson()) as Map<String, dynamic>;
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
      final result = jsonDecode(input.fixJson()) as Map<String, dynamic>;
      expect(result['tags'], ['']);
      expect(result['removeBuiltInMods'], ['']);
      expect(result['emptyList'], []);
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
      final result = jsonDecode(input.fixJson()) as Map<String, dynamic>;
      expect(result['id'], 'ork_rightarm_wpn');
      expect(result['everyFrameEffect'],
          'data.scripts.weapons.bt_arm_everyframe');
      expect(result['turretOffsets'], [10, 0]);
      expect(result['muzzleFlashSpec']['particleCount'], 12);
    });
  });
}
