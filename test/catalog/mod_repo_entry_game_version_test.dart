import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';

ModRepoEntry parseWithVersion(dynamic gameVersionReq) =>
    ModRepoEntryMapper.fromMap({
      'name': 'Test Mod',
      'gameVersionReq': gameVersionReq,
    });

void main() {
  group('game version fixup on catalog entries', () {
    test('adds the leading 0. when the author left it off', () {
      expect(parseWithVersion('97a-RC11').gameVersionReq, '0.97a-RC11');
      expect(parseWithVersion('98a').gameVersionReq, '0.98a');
    });

    test('adds the leading 0 when the version starts with a dot', () {
      expect(parseWithVersion('.98a').gameVersionReq, '0.98a');
    });

    test('leaves well-formed versions alone', () {
      expect(parseWithVersion('0.98a-RC8').gameVersionReq, '0.98a-RC8');
      expect(parseWithVersion('0.95.1a').gameVersionReq, '0.95.1a');
      expect(parseWithVersion('0.9x').gameVersionReq, '0.9x');
    });

    test('leaves a single leading digit alone', () {
      // Starsector has never shipped a 1.x, but don't mangle it if it does.
      expect(parseWithVersion('1.0a').gameVersionReq, '1.0a');
    });

    test('leaves empty and missing values alone', () {
      expect(parseWithVersion('').gameVersionReq, '');
      expect(parseWithVersion(null).gameVersionReq, isNull);
    });
  });
}
