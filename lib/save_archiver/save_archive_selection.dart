import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/save_archiver/archived_save_store.dart';

/// Sorts [items] newest first.
///
/// Undated items go last. [tieBreakerOf] keeps equal dates in a consistent order.
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

List<SaveFile> savesNewestFirst(Iterable<SaveFile> saves) =>
    sortedNewestFirst<SaveFile>(
      saves,
      dateOf: (save) => save.saveDate,
      tieBreakerOf: (save) => save.id,
    );

/// Selects the saves the bulk archive dialog starts with ticked: every save
/// not saved in the last 30 days, plus any recent saves beyond the newest 5.
/// The newest 3 saves are never selected, however old they are. Undated saves
/// are never selected.
List<SaveFile> savesToArchiveByDefault(
  Iterable<SaveFile> saves, {
  required DateTime now,
}) {
  final cutoff = now.subtract(const Duration(days: 30));
  final dated = savesNewestFirst(saves)
      .where((save) => save.saveDate != null)
      .toList();
  // Newest first, so recent saves always come before older ones.
  return [
    for (final (index, save) in dated.indexed)
      if (index >= 3 && (index >= 5 || !save.saveDate!.isAfter(cutoff))) save,
  ];
}

List<ArchivedSaveEntry> archivesNewestFirst(
  Iterable<ArchivedSaveEntry> archives,
) => sortedNewestFirst<ArchivedSaveEntry>(
  archives,
  dateOf: (archive) => archive.sortDate,
  tieBreakerOf: (archive) => archive.sortTieBreaker,
);
