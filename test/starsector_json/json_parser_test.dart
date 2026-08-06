import 'package:flutter_test/flutter_test.dart';
import 'package:trios/starsector_json/starsector_json.dart';

void main() {
  group('plain JSON', () {
    test('reads objects, arrays and every scalar type', () {
      expect(
        parseJsonObject(
          '{"s": "hi", "i": 5, "d": 1.5, "t": true, "f": false, '
          '"n": null, "a": [1, 2], "o": {"k": "v"}}',
        ),
        {
          's': 'hi',
          'i': 5,
          'd': 1.5,
          't': true,
          'f': false,
          'n': null,
          'a': [1, 2],
          'o': {'k': 'v'},
        },
      );
    });

    test('keeps a key whose value is null', () {
      final result = parseJsonObject('{"a": null}');
      expect(result.containsKey('a'), isTrue);
      expect(result['a'], isNull);
    });

    test('reads escapes', () {
      expect(
        parseJsonObject(r'{"a": "t\tn\nq\"b\\s\/uA"}'),
        {'a': 't\tn\nq"b\\s/uA'},
      );
    });
  });

  group('things the game accepts that strict JSON does not', () {
    test('unquoted keys', () {
      expect(parseJsonObject('{hullId: "wolf", cost: 5}'), {
        'hullId': 'wolf',
        'cost': 5,
      });
    });

    test('unquoted string values', () {
      expect(parseJsonObject('{a: wolf}'), {'a': 'wolf'});
    });

    test('an unquoted token can contain spaces', () {
      expect(parseJsonObject('{a: two words}'), {'a': 'two words'});
    });

    test('single-quoted strings', () {
      expect(parseJsonObject("{'a': 'b'}"), {'a': 'b'});
    });

    test('trailing comma in an object and an array', () {
      expect(parseJsonObject('{"a": [1, 2,],}'), {
        'a': [1, 2],
      });
    });

    test('semicolon instead of comma', () {
      expect(parseJsonObject('{"a": 1; "b": 2}'), {'a': 1, 'b': 2});
    });

    test('= and => instead of colon', () {
      expect(parseJsonObject('{"a" = 1, "b" => 2}'), {'a': 1, 'b': 2});
    });

    test('a missing array element becomes null', () {
      expect(parseJsonObject('{"a": [1,,2]}'), {
        'a': [1, null, 2],
      });
    });

    test('true/false/null are case insensitive', () {
      expect(parseJsonObject('{a: TRUE, b: False, c: NULL}'), {
        'a': true,
        'b': false,
        'c': null,
      });
    });
  });

  group('numbers', () {
    test('whole numbers come back as int, decimals as double', () {
      final result = parseJsonObject('{a: 5, b: 5.0, c: -3, d: +4}');
      expect(result['a'], isA<int>());
      expect(result['b'], isA<double>());
      expect(result['c'], -3);
      expect(result['d'], 4);
    });

    test('exponents', () {
      expect(parseJsonObject('{a: 1e3, b: 1E-2}'), {'a': 1000.0, 'b': 0.01});
    });

    test('hex integers', () {
      expect(parseJsonObject('{a: 0xFF, b: 0X10}'), {'a': 255, 'b': 16});
    });

    test('a hex value too big for a 32-bit int stays a string', () {
      expect(parseJsonObject('{a: 0xFFFFFFFF}'), {'a': '0xFFFFFFFF'});
    });

    test('a number too big for 64 bits stays a string', () {
      expect(parseJsonObject('{a: 99999999999999999999}'), {
        'a': '99999999999999999999',
      });
    });

    // These show up in mod files copied from Java source.
    test('a Java float suffix is kept only when there is a decimal point', () {
      // 1.5f parses as a double, because it contains a '.' and Java's
      // Double.valueOf accepts the suffix.
      expect(parseJsonObject('{a: 1.5f}'), {'a': 1.5});
      // 1f has no '.', so it is tried as a whole number, fails, and stays text.
      expect(parseJsonObject('{a: 1f}'), {'a': '1f'});
    });
  });

  group('errors', () {
    test('a duplicate key is rejected', () {
      expect(
        () => parseJsonObject('{"a": 1, "a": 2}'),
        throwsA(
          isA<StarsectorJsonException>().having(
            (e) => e.message,
            'message',
            'Duplicate key "a"',
          ),
        ),
      );
    });

    test('an object value of infinity is rejected', () {
      expect(
        () => parseJsonObject('{a: 1e999}'),
        throwsA(
          isA<StarsectorJsonException>().having(
            (e) => e.message,
            'message',
            'JSON does not allow non-finite numbers.',
          ),
        ),
      );
    });

    test('but an array element of infinity is not', () {
      expect(parseJsonObject('{a: [1e999]}'), {
        'a': [double.infinity],
      });
    });

    // The game's parser has no idea what // means, and the comment stripper
    // only handles #, so a // comment breaks the file in game too.
    test('a // comment is a syntax error, same as in game', () {
      expect(
        () => parseStarsectorJson('{\n// a note\n"a": 1\n}'),
        throwsA(isA<StarsectorJsonException>()),
      );
    });

    test('a string cannot span lines', () {
      expect(
        () => parseJsonObject('{"a": "one\ntwo"}'),
        throwsA(
          isA<StarsectorJsonException>().having(
            (e) => e.message,
            'message',
            startsWith('Unterminated string'),
          ),
        ),
      );
    });

    test('an unknown escape is rejected', () {
      expect(
        () => parseJsonObject(r'{"a": "\q"}'),
        throwsA(
          isA<StarsectorJsonException>().having(
            (e) => e.message,
            'message',
            startsWith('Illegal escape.'),
          ),
        ),
      );
    });

    test('the text has to be an object', () {
      expect(
        () => parseJsonObject('[1, 2]'),
        throwsA(
          isA<StarsectorJsonException>().having(
            (e) => e.message,
            'message',
            startsWith("A JSONObject text must begin with '{'"),
          ),
        ),
      );
    });

    // The line number is 3, not 2, and that is correct. Java steps back over
    // the newline after reading the `1`, and stepping back rolls back the
    // character but not the line, so re-reading that newline counts it twice.
    test('error messages carry the position, character and line', () {
      expect(
        () => parseJsonObject('{"a": 1\n "b" 2}'),
        throwsA(
          isA<StarsectorJsonException>().having(
            (e) => e.message,
            'message',
            "Expected a ',' or '}' at 10 [character 2 line 3]",
          ),
        ),
      );
    });
  });

  group('the whole pipeline', () {
    test('strips comments then parses', () {
      expect(
        parseStarsectorJson(
          '{\r\n'
          '  # what this file is\r\n'
          '  hullId: "wolf",   # the ship\r\n'
          '  "name": "Wolf #1",\r\n'
          '}\r\n',
        ),
        {'hullId': 'wolf', 'name': 'Wolf #1'},
      );
    });
  });
}
