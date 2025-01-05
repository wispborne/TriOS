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
  MapDiff<K, V> diff(Map<K, V> other) => compareWith(other);

  MapDiff<K, V> compareWith(Map<K, V> other) {
    final added = <K, V>{};
    final removed = <K, V>{};
    final modified = <K, MapEntry<V, V>>{};

    other.forEach((key, newValue) {
      // If this map doesn't have [key], it's added.
      if (!containsKey(key)) {
        added[key] = newValue;
      } else {
        final oldValue = this[key];
        // If the values are not deeply equal, mark modified.
        if (!_deepEquals(oldValue, newValue)) {
          modified[key] = MapEntry(oldValue as V, newValue);
        }
      }
    });

    // Anything in 'this' that is not in 'other' is removed.
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

/// A helper function to compare values deeply:
/// - If both values are Maps, compare their contents recursively.
/// - If both values are null or identical, they're equal.
/// - Otherwise, default to `==` comparison.
bool _deepEquals(dynamic a, dynamic b) {
  // Quick check for identical() or both null
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;

  // Handle nested maps
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }

  // Optionally handle lists, sets, etc. if needed:
  // if (a is List && b is List) { ... }
  // if (a is Set && b is Set) { ... }

  // Fallback to standard equality
  return a == b;
}
