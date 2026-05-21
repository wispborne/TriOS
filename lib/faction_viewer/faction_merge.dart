import 'package:trios/faction_viewer/models/faction.dart';

const _colorKeys = {'color', 'baseuicolor', 'darkuicolor', 'griduicolor', 'brightuicolor'};
const _musicKey = 'music';
const _coreClearArray = 'core_clearArray';

class FactionMergeResult {
  final Map<String, dynamic> merged;
  final Map<String, List<SourceContribution>> attributions;
  final Map<String, Map<String, String>> itemAttributions;

  const FactionMergeResult({
    required this.merged,
    required this.attributions,
    required this.itemAttributions,
  });
}

FactionMergeResult mergeFactionJson({
  required Map<String, dynamic> base,
  required Map<String, dynamic> overlay,
  required String sourceName,
  required Map<String, List<SourceContribution>> existingAttributions,
  required Map<String, Map<String, String>> existingItemAttributions,
}) {
  final merged = _deepCopyMap(base);
  final attributions = {
    for (final e in existingAttributions.entries)
      e.key: List<SourceContribution>.from(e.value),
  };
  final itemAttributions = {
    for (final e in existingItemAttributions.entries)
      e.key: Map<String, String>.from(e.value),
  };

  _mergeRecursive(
    merged,
    overlay,
    sourceName,
    attributions,
    itemAttributions,
    prefix: '',
  );

  return FactionMergeResult(
    merged: merged,
    attributions: attributions,
    itemAttributions: itemAttributions,
  );
}

void _mergeRecursive(
  Map<String, dynamic> target,
  Map<String, dynamic> overlay,
  String sourceName,
  Map<String, List<SourceContribution>> attributions,
  Map<String, Map<String, String>> itemAttributions, {
  required String prefix,
}) {
  for (final entry in overlay.entries) {
    final key = entry.key;
    final overlayValue = entry.value;
    final fullKey = prefix.isEmpty ? key : '$prefix.$key';
    final keyLower = key.toLowerCase();

    if (overlayValue is List) {
      if (_colorKeys.contains(keyLower)) {
        // Color arrays are replaced entirely.
        target[key] = overlayValue;
      } else {
        final existing = target[key];
        if (existing is List) {
          final hasClear = overlayValue.contains(_coreClearArray);
          if (hasClear) {
            itemAttributions.remove(fullKey);
          }
          final newItems = _handleArrayMerge(
            existing,
            overlayValue,
            attributions,
            fullKey,
          );
          target[key] = newItems;
          final addedCount = overlayValue
              .where((e) => e != _coreClearArray)
              .length;
          if (addedCount > 0) {
            _addAttribution(attributions, fullKey, sourceName, addedCount);
          }
          _tagItems(itemAttributions, fullKey, overlayValue, sourceName);
        } else {
          target[key] = overlayValue;
          if (overlayValue.isNotEmpty) {
            final countExcludingClear = overlayValue
                .where((e) => e != _coreClearArray)
                .length;
            if (countExcludingClear > 0) {
              _addAttribution(
                attributions,
                fullKey,
                sourceName,
                countExcludingClear,
              );
            }
            _tagItems(itemAttributions, fullKey, overlayValue, sourceName);
          }
        }
      }
    } else if (overlayValue is Map<String, dynamic>) {
      if (keyLower == _musicKey) {
        // Music is replaced entirely.
        target[key] = overlayValue;
      } else {
        final existing = target[key];
        if (existing is Map<String, dynamic>) {
          _mergeRecursive(
            existing,
            overlayValue,
            sourceName,
            attributions,
            itemAttributions,
            prefix: fullKey,
          );
        } else {
          target[key] = Map<String, dynamic>.from(overlayValue);
        }
      }
    } else {
      // Scalar: last-write-wins.
      target[key] = overlayValue;
    }
  }
}

List<dynamic> _handleArrayMerge(
  List<dynamic> base,
  List<dynamic> overlay,
  Map<String, List<SourceContribution>> attributions,
  String fullKey,
) {
  final hasClear = overlay.contains(_coreClearArray);
  final items = overlay.where((e) => e != _coreClearArray).toList();

  if (hasClear) {
    attributions.remove(fullKey);
    return items;
  }
  return [...base, ...items];
}

Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) {
  return source.map((key, value) {
    if (value is Map<String, dynamic>) {
      return MapEntry(key, _deepCopyMap(value));
    } else if (value is List) {
      return MapEntry(key, List.from(value));
    }
    return MapEntry(key, value);
  });
}

void _tagItems(
  Map<String, Map<String, String>> itemAttributions,
  String key,
  List<dynamic> items,
  String source,
) {
  for (final item in items) {
    if (item != _coreClearArray && item is String) {
      itemAttributions.putIfAbsent(key, () => {});
      itemAttributions[key]![item] = source;
    }
  }
}

void _addAttribution(
  Map<String, List<SourceContribution>> attributions,
  String key,
  String sourceName,
  int count,
) {
  attributions.putIfAbsent(key, () => []);
  final list = attributions[key]!;
  final existingIndex = list.indexWhere((c) => c.source == sourceName);
  if (existingIndex >= 0) {
    list[existingIndex] = SourceContribution(
      source: sourceName,
      count: list[existingIndex].count + count,
    );
  } else {
    list.add(SourceContribution(source: sourceName, count: count));
  }
}
