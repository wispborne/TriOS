import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/save_archiver/save_archive_selection.dart';

/// The "keep the newest N" arithmetic. It decides which ticks a dialog starts
/// with, so getting it wrong means somebody archives a save they are playing.
void main() {
  SaveFile save(String id, DateTime? saved) => SaveFile(
    id: id,
    folder: Directory('/saves/$id'),
    characterName: id,
    characterLevel: 1,
    saveDate: saved,
    mods: const [],
    compressed: false,
    isIronMode: false,
    difficulty: 'normal',
    gameTimestamp: 0,
    secondsPerDay: 10,
  );

  final newest = save('save_newest', DateTime.utc(2026, 9, 21));
  final middle = save('save_middle', DateTime.utc(2026, 9, 14));
  final oldest = save('save_oldest', DateTime.utc(2026, 1, 1));
  final unsorted = [middle, oldest, newest];

  group('sorting saves', () {
    test('newest first', () {
      expect(savesNewestFirst(unsorted).map((save) => save.id), [
        'save_newest',
        'save_middle',
        'save_oldest',
      ]);
    });

    test('saves with no date go last', () {
      final undated = save('save_undated', null);

      expect(savesNewestFirst([undated, ...unsorted]).last.id, 'save_undated');
    });

    test(
      'same date falls back to the folder name, so order never shuffles',
      () {
        final sameTime = DateTime.utc(2026, 5, 5);
        final b = save('save_b', sameTime);
        final a = save('save_a', sameTime);

        expect(savesNewestFirst([b, a]).map((save) => save.id), [
          'save_a',
          'save_b',
        ]);
        expect(savesNewestFirst([a, b]).map((save) => save.id), [
          'save_a',
          'save_b',
        ]);
      },
    );
  });

  group('keeping the newest saves', () {
    test('keeping one leaves the rest', () {
      expect(savesToArchiveKeepingNewest(unsorted, 1).map((save) => save.id), [
        'save_middle',
        'save_oldest',
      ]);
    });

    test('keeping none means all of them', () {
      expect(savesToArchiveKeepingNewest(unsorted, 0), hasLength(3));
    });

    test('keeping more than there are means none of them', () {
      expect(savesToArchiveKeepingNewest(unsorted, 10), isEmpty);
    });

    test('keeping exactly all of them means none of them', () {
      expect(savesToArchiveKeepingNewest(unsorted, 3), isEmpty);
    });

    test('a negative number is treated as zero, not as an error', () {
      expect(savesToArchiveKeepingNewest(unsorted, -5), hasLength(3));
    });

    test('never returns a save that was not passed in', () {
      final picked = savesToArchiveKeepingNewest(unsorted, 1);

      expect(picked.every((save) => unsorted.contains(save)), isTrue);
    });

    test('an empty list stays empty', () {
      expect(savesToArchiveKeepingNewest(const [], 3), isEmpty);
    });
  });

  group('taking the newest archives', () {
    test('takes them newest first', () {
      final archives = archivesToRestoreNewest(const [], 3);

      expect(archives, isEmpty);
    });
  });
}
