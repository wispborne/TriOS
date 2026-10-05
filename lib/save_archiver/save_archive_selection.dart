import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/save_archiver/archived_save_store.dart';

/// Sorts [items] newest first.
///
/// Anything without a date goes last, and ties fall back to [tieBreakerOf], so
/// the same list always comes out in the same order. A checkbox list that
/// reshuffles itself between openings is a good way to archive the wrong save.
List<T> sortedNewestFirst<T>(
  Iterable<T> items, {
  required DateTime? Function(T item) dateOf,
  required String Function(T item) tieBreakerOf,
}) {
  final sorted = items.toList();
  sorted.sort((a, b) {
    final dateA = dateOf(a);
    final dateB = dateOf(b);
    if (dateA == null && dateB == null) {
      return tieBreakerOf(a).compareTo(tieBreakerOf(b));
    }
    if (dateA == null) return 1;
    if (dateB == null) return -1;
    final byDate = dateB.compareTo(dateA);
    if (byDate != 0) return byDate;
    return tieBreakerOf(a).compareTo(tieBreakerOf(b));
  });
  return sorted;
}

/// Saves ordered newest first.
List<SaveFile> savesNewestFirst(Iterable<SaveFile> saves) =>
    sortedNewestFirst<SaveFile>(
      saves,
      dateOf: (save) => save.saveDate,
      tieBreakerOf: (save) => save.id,
    );

/// The saves that would be archived when keeping the [keepCount] newest.
///
/// A [keepCount] of 0 means every save, and anything larger than the number of
/// saves means none. Never returns saves the caller didn't pass in.
List<SaveFile> savesToArchiveKeepingNewest(
  Iterable<SaveFile> saves,
  int keepCount,
) {
  final keep = keepCount < 0 ? 0 : keepCount;
  return savesNewestFirst(saves).skip(keep).toList();
}

/// Archives ordered newest save first.
List<ArchivedSaveEntry> archivesNewestFirst(
  Iterable<ArchivedSaveEntry> archives,
) => sortedNewestFirst<ArchivedSaveEntry>(
  archives,
  dateOf: (archive) => archive.sortDate,
  tieBreakerOf: (archive) => archive.sortTieBreaker,
);

/// The [count] newest archives, which is what "restore the most recent ones"
/// starts from. A [count] of 0 means none.
List<ArchivedSaveEntry> archivesToRestoreNewest(
  Iterable<ArchivedSaveEntry> archives,
  int count,
) {
  final take = count < 0 ? 0 : count;
  return archivesNewestFirst(archives).take(take).toList();
}
