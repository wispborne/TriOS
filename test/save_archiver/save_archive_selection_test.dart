import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/save_archiver/save_archive_selection.dart';

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

    test('equal dates are sorted by save ID', () {
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
    });
  });

  group('saves ticked for archiving by default', () {
    final now = DateTime.utc(2026, 9, 30);
    List<String> picked(Iterable<SaveFile> saves) => savesToArchiveByDefault(
      saves,
      now: now,
    ).map((save) => save.id).toList();

    // Old enough to be archived, newest first.
    final old = [
      for (var month = 6; month >= 1; month--)
        save('save_month$month', DateTime.utc(2026, month)),
    ];

    test('saves from the last 30 days are left alone', () {
      expect(picked([...unsorted, ...old]), [
        'save_month5',
        'save_month4',
        'save_month3',
        'save_month2',
        'save_month1',
        'save_oldest',
      ]);
    });

    test('a save from exactly 30 days ago is archived', () {
      expect(
        picked([
          for (var day = 25; day <= 27; day++)
            save('save_day$day', DateTime.utc(2026, 9, day)),
          save('save_edge', DateTime.utc(2026, 8, 31)),
        ]),
        ['save_edge'],
      );
    });

    test('only the newest 5 recent saves are left alone', () {
      final recent = [
        for (var day = 1; day <= 7; day++)
          save('save_day$day', DateTime.utc(2026, 9, 20 + day)),
      ];

      expect(picked([...recent, oldest]), [
        'save_day2',
        'save_day1',
        'save_oldest',
      ]);
    });

    test('the newest 3 saves are left alone even when old', () {
      expect(picked(old), ['save_month3', 'save_month2', 'save_month1']);
    });

    test('3 or fewer saves are all left alone', () {
      expect(picked(old.take(3)), isEmpty);
    });

    test('saves with no date are left alone', () {
      expect(picked([save('save_undated', null), ...old]), [
        'save_month3',
        'save_month2',
        'save_month1',
      ]);
    });

    test('an empty list stays empty', () {
      expect(picked(const []), isEmpty);
    });
  });
}
