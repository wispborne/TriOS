import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/selectors/references/_json_utils.dart';

void main() {
  group('stripJsonComments default mode (legacy)', () {
    test('input with # passes through unchanged', () {
      const src = '{ "key": "value" # trailing\n}';
      expect(stripJsonComments(src), equals(src));
    });

    test('strips // line comments', () {
      const src = '{ "k": "v" // trailing\n}';
      expect(stripJsonComments(src), equals('{ "k": "v" \n}'));
    });

    test('strips /* */ block comments', () {
      const src = '{ /* block */ "k": "v" }';
      expect(stripJsonComments(src), equals('{  "k": "v" }'));
    });

    test('// inside a string literal is preserved', () {
      const src = '{ "k": "http://example.com" }';
      expect(stripJsonComments(src), equals(src));
    });

    test('# inside a string literal is preserved', () {
      const src = '{ "k": "prefix#suffix" }';
      expect(stripJsonComments(src), equals(src));
    });
  });

  group('stripJsonComments with stripHashLineComments: true', () {
    test('strips # through the next newline outside a string', () {
      const src = '{ "k": "v" # trailing comment\n}';
      expect(
        stripJsonComments(src, stripHashLineComments: true),
        equals('{ "k": "v" \n}'),
      );
    });

    test('strips # at end-of-file with no trailing newline', () {
      const src = '{ "k": "v" } # tail';
      expect(
        stripJsonComments(src, stripHashLineComments: true),
        equals('{ "k": "v" } '),
      );
    });

    test('# inside a string literal is preserved', () {
      const src = '{ "k": "prefix#suffix" }';
      expect(
        stripJsonComments(src, stripHashLineComments: true),
        equals(src),
      );
    });

    test('// and /* */ handling is still intact', () {
      const src = '{ /* b */ "k": "v" // tail\n, "x": 1 # tail2\n}';
      expect(
        stripJsonComments(src, stripHashLineComments: true),
        equals('{  "k": "v" \n, "x": 1 \n}'),
      );
    });

    test('multiple # comments on different lines', () {
      const src = '{\n  # comment 1\n  "k": 1 # comment 2\n}';
      expect(
        stripJsonComments(src, stripHashLineComments: true),
        equals('{\n  \n  "k": 1 \n}'),
      );
    });
  });
}
