import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/catalog_search.dart';

void main() {
  group('compareGameVersionOrder', () {
    test('sorts Starsector releases in the order they came out', () {
      const releases = [
        '0.35a',
        '0.5a',
        '0.54a',
        '0.6a',
        '0.6.1a',
        '0.6.2a',
        '0.62a',
        '0.65a',
        '0.65.1a',
        '0.65.2a',
        '0.7a',
        '0.7.2a',
        '0.8a',
        '0.8.1a',
        '0.9a',
        '0.9.1a',
        '0.95a',
        '0.95.1a',
        '0.96a',
        '0.97a',
        '0.98a',
      ];
      final shuffled = [...releases]..shuffle(Random(1));
      expect(shuffled..sort(compareGameVersionOrder), releases);
    });

    test('0.9.5a is the same release as 0.95a', () {
      expect(compareGameVersionOrder('0.9.5a', '0.95a'), lessThanOrEqualTo(0));
      expect(compareGameVersionOrder('0.9.5a', '0.96a'), lessThan(0));
    });

    test('release candidates of one version sort by RC number', () {
      expect(compareGameVersionOrder('0.97a-RC2', '0.97a-RC11'), lessThan(0));
      expect(compareGameVersionOrder('0.97a-RC11', '0.98a'), lessThan(0));
    });

    test('a version with no numbers sorts first', () {
      expect(compareGameVersionOrder('', '0.5a'), lessThan(0));
      expect(compareGameVersionOrder('0.5a', null), greaterThan(0));
    });
  });

  group('GameVersionSortKey', () {
    test('sorts like compareGameVersionOrder', () {
      final keys = ['0.9a', '0.65a', '0.98a', '0.7a'].map(GameVersionSortKey.new);
      expect(keys.toList()..sort(), [
        GameVersionSortKey('0.65a'),
        GameVersionSortKey('0.7a'),
        GameVersionSortKey('0.9a'),
        GameVersionSortKey('0.98a'),
      ]);
    });

    test('ignores case', () {
      expect(GameVersionSortKey('0.98a-RC8'), GameVersionSortKey('0.98A-rc8'));
      expect(
        GameVersionSortKey('0.98a-RC8')
            .compareTo(GameVersionSortKey('0.98A-rc8')),
        0,
      );
    });

    test('different text only compares as equal when it is the same key', () {
      final a = GameVersionSortKey('0.9.5a');
      final b = GameVersionSortKey('0.95a');
      expect(a == b, isFalse);
      expect(a.compareTo(b), isNot(0));
      expect(a.compareTo(b), -b.compareTo(a));
    });
  });
}
