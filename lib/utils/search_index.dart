/// Text to match a plain-text search against, one entry per item.
///
/// All of an item's field values, lowercased and joined with newlines. Search
/// asks "does this contain the typed text", so one string per item works the
/// same as a list of one string per field: a newline can never appear in a
/// search token, so nothing can match across two fields by accident.
///
/// One string rather than a list because there are a lot of these. A big mod
/// list has thousands of ships with about sixty fields each; keeping every
/// field as its own string cost a list, a backing array and sixty string
/// headers per ship, which came to tens of megabytes of bookkeeping around a
/// much smaller amount of actual text.
typedef SearchIndex = Map<String, String>;

/// Separates one field's text from the next. Cannot appear in a search token,
/// because the search box splits what you type on whitespace.
const searchIndexSeparator = '\n';

/// Incrementally update a search index cache. Removes entries for items no
/// longer present and adds entries for new items by lowercasing all values
/// from [toMap].
///
/// Fields with no value are skipped. They used to be written out as the word
/// "null", which wasted space and meant that searching for `null` matched
/// nearly everything.
SearchIndex updateSearchIndices<T>(
  List<T> items,
  SearchIndex currentIndices,
  String Function(T) idOf,
  Map<String, dynamic> Function(T) toMap,
) {
  final currentIds = items.map(idOf).toSet();
  final cachedIds = currentIndices.keys.toSet();

  final result = SearchIndex.from(currentIndices);
  for (final id in cachedIds.difference(currentIds)) {
    result.remove(id);
  }

  final newItems = items.where((item) => !cachedIds.contains(idOf(item)));
  for (final item in newItems) {
    result[idOf(item)] = toMap(item).values
        .where((value) => value != null)
        .map((value) => value.toString().toLowerCase())
        .join(searchIndexSeparator);
  }
  return result;
}
