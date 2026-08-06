import 'package:flutter_test/flutter_test.dart';
import 'package:trios/starsector_json/starsector_json.dart';
import 'package:trios/utils/extensions.dart';

void main() {
  group('parseJsonToMap', () {
    test('valid JSON passes through unchanged', () {
      const input = '{"key": "value", "num": 42}';
      final result = input.parseJsonToMap();
      expect(result['key'], 'value');
      expect(result['num'], 42);
    });

    test('accepts semicolons used as value separators', () {
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

    test('ignores anything after the closing brace', () {
      const input = '{"key": "value"},';
      final result = input.parseJsonToMap();
      expect(result['key'], 'value');
    });

    test('treats tabs as whitespace', () {
      const input = '{\t"key":\t"value"}';
      final result = input.parseJsonToMap();
      expect(result['key'], 'value');
    });

    test('handles combination of issues', () {
      const input = '''
{
  # weapon config
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

    // A Java-style suffix is only accepted on the path that has a `.`, `e` or
    // `E` in it, because that's the path that hands the text to Java's
    // Double.valueOf. So `2.5f` is the number 2.5, but `1f` and `3d` fail the
    // whole-number parse and stay text. That's the game's own behaviour, and it
    // is what makes `"patch": 3d` in a .version file mean the string "3d".
    // Readers that want a number regardless use
    // toDoubleOrNullAllowingJavaSuffix().
    test('a suffixed literal with no decimal point stays a string', () {
      const input = '{"a":1f}';
      final result = input.parseJsonToMap();
      expect(result['a'], '1f');
    });

    test('a suffixed literal with a decimal point becomes a number', () {
      const input = '{"a":2.5f}';
      final result = input.parseJsonToMap();
      expect(result['a'], 2.5);
    });

    test('leaves a quoted "1f" alone', () {
      const input = '{"a":"1f", "b":1f}';
      final result = input.parseJsonToMap();
      expect(result['a'], '1f');
      expect(result['b'], '1f');
    });

    test('applies the same suffix rule inside arrays', () {
      const input = '{"a":[1f, 2.5f]}';
      final result = input.parseJsonToMap();
      expect(result['a'], ['1f', 2.5]);
    });

    test('keeps version-file patch values like 3d as strings', () {
      const input = '{"modVersion":{"major":1, "minor":1, "patch":3d}}';
      final result = input.parseJsonToMap();
      expect(result['modVersion']['patch'], '3d');
    });

    test('accepts trailing commas before a closing brace or bracket', () {
      const input = '''
{
  "a": [1, 2, 3,],
  "b": { "c": 1, },
}''';
      final result = input.parseJsonToMap();
      expect(result['a'], [1, 2, 3]);
      expect(result['b'], {'c': 1});
    });

    test('removes # comments, whole-line and trailing', () {
      const input = '''
{
  # a whole line
  "a": 1, # and a trailing one
  "b": 2
}''';
      final result = input.parseJsonToMap();
      expect(result, {'a': 1, 'b': 2});
    });

    test('reads unquoted values as strings', () {
      const input = '''
{
  "textureType": ROUGH,
  "barrelMode": LINKED
}''';
      final result = input.parseJsonToMap();
      expect(result['textureType'], 'ROUGH');
      expect(result['barrelMode'], 'LINKED');
    });

    test('reads True/TRUE and Null the way the game files write them', () {
      const input = '''
{
  "a": True,
  "b": FALSE,
  "c": Null,
  "d": 1
}''';
      final result = input.parseJsonToMap();
      expect(result['a'], true);
      expect(result['b'], false);
      expect(result['c'], null);
    });

    test('reads numbers with leading zeroes and plus signs', () {
      const input = '''
{
  "engineGlowColor": [205,095,100,155],
  "renderOrderMod": +100,
  "mult": .8
}''';
      final result = input.parseJsonToMap();
      expect(result['engineGlowColor'], [205, 95, 100, 155]);
      expect(result['renderOrderMod'], 100);
      expect(result['mult'], 0.8);
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
      expect(
        result['everyFrameEffect'],
        'data.scripts.weapons.bt_arm_everyframe',
      );
      expect(result['turretOffsets'], [10, 0]);
      expect(result['muzzleFlashSpec']['particleCount'], 12);
    });
  });

  // The parser is the game's parser, so it refuses what the game refuses. A
  // file in here would fail to load in Starsector too. See
  // lib/starsector_json/README.md.
  group('parseJsonToMap refuses what the game refuses', () {
    test('a // comment', () {
      const input = '''
{
  // this is a comment
  "key": "value"
}''';
      expect(
        () => input.parseJsonToMap(),
        _throwsJsonError(startsWith('Missing value')),
      );
    });

    test(r'an escaped hash, because \# is not a real escape', () {
      const input = r'{"key": "color\#ff0000"}';
      expect(
        () => input.parseJsonToMap(),
        _throwsJsonError(startsWith('Illegal escape.')),
      );
    });

    // A `#` starts a comment whether or not a space comes before it, so the
    // value is cut down to `red` and the next line has no separator in front
    // of it.
    test('a # inside an unquoted value', () {
      const input = '''
{
  "a": red#ff0000,
  "b": 1
}''';
      expect(
        () => input.parseJsonToMap(),
        _throwsJsonError(startsWith("Expected a ',' or '}'")),
      );
    });

    test('a duplicate key', () {
      expect(
        () => '{"a": 1, "a": 2}'.parseJsonToMap(),
        _throwsJsonError('Duplicate key "a"'),
      );
    });

    test('a string that spans lines', () {
      expect(
        () => '{"a": "one\ntwo"}'.parseJsonToMap(),
        _throwsJsonError(startsWith('Unterminated string')),
      );
    });

    test('valid JSON that is not an object', () {
      expect(
        () => '[1, 2, 3]'.parseJsonToMap(),
        _throwsJsonError(startsWith("A JSONObject text must begin with '{'")),
      );
    });
  });

  // These used to be wrong and are covered so they stay fixed. The old parser
  // repaired near-JSON with string substitutions and a YAML fallback, and both
  // changed values they shouldn't have.
  group('parseJsonToMap no longer mangles values', () {
    test('does not insert a space inside string values', () {
      // The old `(\w):"` substitution also matched inside a string, so any
      // value ending in `:` got a space added to it.
      const input = '''
{
  "text": "Losses this round:",
  "x": 1,
}''';
      final result = input.parseJsonToMap();
      expect(result['text'], 'Losses this round:');
    });

    test('leaves quoted values as strings', () {
      // The old YAML fallback re-read quoted values, so `"false"` came back as
      // a boolean and `'3'` as a number — but only for files that needed the
      // fallback, so the same text could parse two different ways.
      const input = '''
{
  # a comment, which used to force the fallback
  "version": { "major": '3' },
  "utility": "false"
}''';
      final result = input.parseJsonToMap();
      expect(result['version'], {'major': '3'});
      expect(result['utility'], 'false');
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

/// Expects a [StarsectorJsonException] whose message matches [message].
Matcher _throwsJsonError(Object message) => throwsA(
  isA<StarsectorJsonException>().having((e) => e.message, 'message', message),
);
