import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/utils/mod_file_utils.dart';

void main() {
  group('parseVersionCheckerJson', () {
    // `.version` files aren't a game format, so the game's own parser never
    // sees them and modders do write `//` comments in them. Refusing the file
    // would mean no update check for that mod.
    test('reads a file with // comments', () {
      const text = '''
{
    "masterVersionFile": "https://example.com/VOpt.version",
    // "directDownloadURL": "https://example.com/CPG.zip",
    "modName": "~Vram Optimizer",
    "modThreadId": 18011,
    "modVersion": {
        "major": 1,
        "minor": 0,
        "patch": 0
    }
}
''';
      final map = parseVersionCheckerJson(text);
      expect(map['modName'], '~Vram Optimizer');
      expect(map['directDownloadURL'], isNull);
      expect(map['modVersion'], {'major': 1, 'minor': 0, 'patch': 0});
    });

    test('reads a file with /* */ comments', () {
      const text = '{"modName": /* the mod */ "X", "modThreadId": 1}';
      expect(parseVersionCheckerJson(text)['modName'], 'X');
    });

    // Everything the game itself accepts still works, since this runs the same
    // parser underneath.
    test('still accepts # comments, unquoted keys and trailing commas', () {
      const text = '''
{
  # which mod this is
  modName: "X",
  "modVersion":{ "major":1, "minor":0, "patch":3, },
}
''';
      final map = parseVersionCheckerJson(text);
      expect(map['modName'], 'X');
      expect(map['modVersion'], {'major': 1, 'minor': 0, 'patch': 3});
    });

    test('keeps a // that is inside a string', () {
      const text = '{"masterVersionFile": "https://example.com/a.version"}';
      expect(
        parseVersionCheckerJson(text)['masterVersionFile'],
        'https://example.com/a.version',
      );
    });
  });
}
