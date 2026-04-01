import 'package:flutter_test/flutter_test.dart';
import 'package:trios/trios/mod_metadata.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ModVariantMetadata
  // ---------------------------------------------------------------------------
  group('ModVariantMetadata', () {
    test('empty() sets firstSeen close to now', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final metadata = ModVariantMetadata.empty();
      final after = DateTime.now().millisecondsSinceEpoch;

      expect(metadata.firstSeen, greaterThanOrEqualTo(before));
      expect(metadata.firstSeen, lessThanOrEqualTo(after));
    });

    test('backfillWith() keeps user firstSeen, ignores base firstSeen', () {
      final userTimestamp = 1_000_000;
      final baseTimestamp = 2_000_000;

      final user = ModVariantMetadata(firstSeen: userTimestamp);
      final base = ModVariantMetadata(firstSeen: baseTimestamp);

      final merged = user.backfillWith(base);

      expect(merged.firstSeen, userTimestamp);
    });
  });

  // ---------------------------------------------------------------------------
  // ModMetadata
  // ---------------------------------------------------------------------------
  group('ModMetadata', () {
    test('empty() has correct defaults', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final metadata = ModMetadata.empty();
      final after = DateTime.now().millisecondsSinceEpoch;

      expect(metadata.isFavorited, isFalse);
      expect(metadata.areUpdatesMuted, isFalse);
      expect(metadata.lastEnabled, isNull);
      expect(metadata.variantsMetadata, isEmpty);
      expect(metadata.firstSeen, greaterThanOrEqualTo(before));
      expect(metadata.firstSeen, lessThanOrEqualTo(after));
    });

    test('backfillWith() uses user scalar fields over base', () {
      final user = ModMetadata(
        firstSeen: 100,
        isFavorited: true,
        areUpdatesMuted: true,
        lastEnabled: 999,
      );
      final base = ModMetadata(
        firstSeen: 200,
        isFavorited: false,
        areUpdatesMuted: false,
        lastEnabled: 111,
      );

      final merged = user.backfillWith(base);

      expect(merged.firstSeen, 100);
      expect(merged.isFavorited, isTrue);
      expect(merged.areUpdatesMuted, isTrue);
      expect(merged.lastEnabled, 999);
    });

    test('backfillWith() falls back to base lastEnabled when user has null', () {
      final user = ModMetadata(firstSeen: 100, lastEnabled: null);
      final base = ModMetadata(firstSeen: 200, lastEnabled: 555);

      final merged = user.backfillWith(base);

      expect(merged.lastEnabled, 555);
    });

    test('backfillWith() uses user lastEnabled when set', () {
      final user = ModMetadata(firstSeen: 100, lastEnabled: 777);
      final base = ModMetadata(firstSeen: 200, lastEnabled: 555);

      final merged = user.backfillWith(base);

      expect(merged.lastEnabled, 777);
    });

    test('backfillWith() includes base-only variants in result', () {
      final baseVariant = ModVariantMetadata(firstSeen: 50);
      final user = ModMetadata(firstSeen: 100);
      final base = ModMetadata(
        firstSeen: 200,
        variantsMetadata: {'baseOnly': baseVariant},
      );

      final merged = user.backfillWith(base);

      expect(merged.variantsMetadata, contains('baseOnly'));
      expect(merged.variantsMetadata['baseOnly']!.firstSeen, 50);
    });

    test('backfillWith() includes user-only variants in result', () {
      final userVariant = ModVariantMetadata(firstSeen: 77);
      final user = ModMetadata(
        firstSeen: 100,
        variantsMetadata: {'userOnly': userVariant},
      );
      final base = ModMetadata(firstSeen: 200);

      final merged = user.backfillWith(base);

      expect(merged.variantsMetadata, contains('userOnly'));
      expect(merged.variantsMetadata['userOnly']!.firstSeen, 77);
    });

    test('backfillWith() merges overlapping variants via backfillWith', () {
      // user variant wins on firstSeen per ModVariantMetadata.backfillWith
      final userVariant = ModVariantMetadata(firstSeen: 10);
      final baseVariant = ModVariantMetadata(firstSeen: 20);

      final user = ModMetadata(
        firstSeen: 100,
        variantsMetadata: {'shared': userVariant},
      );
      final base = ModMetadata(
        firstSeen: 200,
        variantsMetadata: {'shared': baseVariant},
      );

      final merged = user.backfillWith(base);

      expect(merged.variantsMetadata, contains('shared'));
      // ModVariantMetadata.backfillWith keeps user's firstSeen
      expect(merged.variantsMetadata['shared']!.firstSeen, 10);
    });

    test('backfillWith() result contains all three variant categories', () {
      final user = ModMetadata(
        firstSeen: 1,
        variantsMetadata: {
          'userOnly': ModVariantMetadata(firstSeen: 11),
          'shared': ModVariantMetadata(firstSeen: 22),
        },
      );
      final base = ModMetadata(
        firstSeen: 2,
        variantsMetadata: {
          'baseOnly': ModVariantMetadata(firstSeen: 33),
          'shared': ModVariantMetadata(firstSeen: 44),
        },
      );

      final merged = user.backfillWith(base);

      expect(merged.variantsMetadata.keys, containsAll(['userOnly', 'baseOnly', 'shared']));
      expect(merged.variantsMetadata.length, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // ModsMetadata
  // ---------------------------------------------------------------------------
  group('ModsMetadata', () {
    group('getMergedModMetadata()', () {
      test('returns null when modId absent from both maps', () {
        final store = ModsMetadata(baseMetadata: {}, userMetadata: {});
        expect(store.getMergedModMetadata('unknown'), isNull);
      });

      test('returns base metadata when only base has the modId', () {
        final base = ModMetadata(firstSeen: 100, isFavorited: true);
        final store = ModsMetadata(
          baseMetadata: {'modA': base},
          userMetadata: {},
        );

        final result = store.getMergedModMetadata('modA');

        expect(result, isNotNull);
        expect(result!.firstSeen, 100);
        expect(result.isFavorited, isTrue);
      });

      test('returns user metadata when only user has the modId', () {
        final user = ModMetadata(firstSeen: 200, isFavorited: true);
        final store = ModsMetadata(
          baseMetadata: {},
          userMetadata: {'modA': user},
        );

        final result = store.getMergedModMetadata('modA');

        expect(result, isNotNull);
        expect(result!.firstSeen, 200);
        expect(result.isFavorited, isTrue);
      });

      test('merges when both user and base have the modId', () {
        final user = ModMetadata(firstSeen: 10, isFavorited: true, lastEnabled: null);
        final base = ModMetadata(firstSeen: 20, isFavorited: false, lastEnabled: 999);
        final store = ModsMetadata(
          baseMetadata: {'modA': base},
          userMetadata: {'modA': user},
        );

        final result = store.getMergedModMetadata('modA');

        expect(result, isNotNull);
        // user fields win
        expect(result!.firstSeen, 10);
        expect(result.isFavorited, isTrue);
        // lastEnabled falls back to base when user has null
        expect(result.lastEnabled, 999);
      });
    });

    group('getMergedModVariantMetadata()', () {
      test('returns null when variant absent from both maps', () {
        final store = ModsMetadata(baseMetadata: {}, userMetadata: {});
        expect(store.getMergedModVariantMetadata('modA', 'smol-1'), isNull);
      });

      test('returns null when mod exists in base but variant is absent', () {
        final store = ModsMetadata(
          baseMetadata: {'modA': ModMetadata(firstSeen: 1)},
          userMetadata: {},
        );
        expect(store.getMergedModVariantMetadata('modA', 'smol-missing'), isNull);
      });

      test('returns base variant when only base has it', () {
        final baseVariant = ModVariantMetadata(firstSeen: 50);
        final base = ModMetadata(
          firstSeen: 1,
          variantsMetadata: {'smol-1': baseVariant},
        );
        final store = ModsMetadata(
          baseMetadata: {'modA': base},
          userMetadata: {},
        );

        final result = store.getMergedModVariantMetadata('modA', 'smol-1');

        expect(result, isNotNull);
        expect(result!.firstSeen, 50);
      });

      test('returns user variant when only user has it', () {
        final userVariant = ModVariantMetadata(firstSeen: 77);
        final user = ModMetadata(
          firstSeen: 1,
          variantsMetadata: {'smol-1': userVariant},
        );
        final store = ModsMetadata(
          baseMetadata: {},
          userMetadata: {'modA': user},
        );

        final result = store.getMergedModVariantMetadata('modA', 'smol-1');

        expect(result, isNotNull);
        expect(result!.firstSeen, 77);
      });

      test('merges variant when both user and base have it', () {
        final userVariant = ModVariantMetadata(firstSeen: 11);
        final baseVariant = ModVariantMetadata(firstSeen: 22);

        final user = ModMetadata(
          firstSeen: 1,
          variantsMetadata: {'smol-1': userVariant},
        );
        final base = ModMetadata(
          firstSeen: 2,
          variantsMetadata: {'smol-1': baseVariant},
        );
        final store = ModsMetadata(
          baseMetadata: {'modA': base},
          userMetadata: {'modA': user},
        );

        final result = store.getMergedModVariantMetadata('modA', 'smol-1');

        expect(result, isNotNull);
        // ModVariantMetadata.backfillWith keeps user's firstSeen
        expect(result!.firstSeen, 11);
      });
    });
  });
}
