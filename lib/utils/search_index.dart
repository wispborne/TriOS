/// Incrementally update a search index cache. Removes entries for items no
/// longer present and adds entries for new items by lowercasing all values
/// from [toMap].
Map<String, List<String>> updateSearchIndices<T>(
  List<T> items,
  Map<String, List<String>> currentIndices,
  String Function(T) idOf,
  Map<String, dynamic> Function(T) toMap,
) {
  final currentIds = items.map(idOf).toSet();
  final cachedIds = currentIndices.keys.toSet();

  final result = Map<String, List<String>>.from(currentIndices);
  for (final id in cachedIds.difference(currentIds)) {
    result.remove(id);
  }

  final newItems = items.where((item) => !cachedIds.contains(idOf(item)));
  for (final item in newItems) {
    result[idOf(item)] =
        toMap(item).values.map((v) => v.toString().toLowerCase()).toList();
  }
  return result;
}
