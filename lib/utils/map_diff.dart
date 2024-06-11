/// Utility class to compare two maps and return the differences between them.
/// The differences are returned as a [MapDiff] object containing the added,
/// removed, and modified entries.
///
/// Written by ChatGPT.
class MapDiff<K, V> {
  final Map<K, V> added;
  final Map<K, V> removed;
  final Map<K, MapEntry<V, V>> modified;

  MapDiff({
    required this.added,
    required this.removed,
    required this.modified,
  });

  bool get hasChanged =>
      added.isNotEmpty || removed.isNotEmpty || modified.isNotEmpty;

  @override
  String toString() {
    return 'Added: $added\nRemoved: $removed\nModified: $modified';
  }
}

class MapComparer<K, V> {
  MapDiff<K, V> compare(Map<K, V> oldMap, Map<K, V> newMap) {
    final added = <K, V>{};
    final removed = <K, V>{};
    final modified = <K, MapEntry<V, V>>{};

    // Check for added or modified entries
    newMap.forEach((key, newValue) {
      if (!oldMap.containsKey(key)) {
        added[key] = newValue;
      } else if (oldMap[key] != newValue) {
        modified[key] = MapEntry(oldMap[key] as V, newValue);
      }
    });

    // Check for removed entries
    oldMap.forEach((key, oldValue) {
      if (!newMap.containsKey(key)) {
        removed[key] = oldValue;
      }
    });

    return MapDiff(
      added: added,
      removed: removed,
      modified: modified,
    );
  }
}

extension MapComparison<K, V> on Map<K, V> {
  MapDiff<K, V> compareWith(Map<K, V> other) {
    final added = <K, V>{};
    final removed = <K, V>{};
    final modified = <K, MapEntry<V, V>>{};

    // Check for added or modified entries
    other.forEach((key, newValue) {
      if (!containsKey(key)) {
        added[key] = newValue;
      } else if (this[key] != newValue) {
        modified[key] = MapEntry(this[key] as V, newValue);
      }
    });

    // Check for removed entries
    forEach((key, oldValue) {
      if (!other.containsKey(key)) {
        removed[key] = oldValue;
      }
    });

    return MapDiff(
      added: added,
      removed: removed,
      modified: modified,
    );
  }
}
