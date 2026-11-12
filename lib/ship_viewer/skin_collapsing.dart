import 'dart:collection';

import 'package:trios/ship_viewer/models/ship.dart';

/// The result of [collapseSimilarSkins].
class CollapsedSkins<T> {
  /// The items that remain, in their original order.
  final List<T> items;

  /// The number of skins each remaining row stands for, by ship id. Only has
  /// entries for rows that stand for two or more skins.
  final Map<String, int> groupSizes;

  const CollapsedSkins(this.items, this.groupSizes);
}

/// Keeps one row for each set of skins with the same base hull and displayed
/// name. The kept row is the skin whose id sorts first.
///
/// Items that are not skins are never removed. [shipOf] returns null for items
/// that are not ships.
CollapsedSkins<T> collapseSimilarSkins<T>(
  List<T> items,
  Ship? Function(T item) shipOf,
) {
  final firstIdByKey = HashMap<String, String>();
  final sizeByKey = HashMap<String, int>();
  for (final item in items) {
    final ship = shipOf(item);
    final key = ship == null ? null : _collapseKey(ship);
    if (key == null) continue;
    sizeByKey[key] = (sizeByKey[key] ?? 0) + 1;
    final firstId = firstIdByKey[key];
    if (firstId == null || ship!.id.compareTo(firstId) < 0) {
      firstIdByKey[key] = ship!.id;
    }
  }

  final kept = <T>[];
  final groupSizes = <String, int>{};
  for (final item in items) {
    final ship = shipOf(item);
    final key = ship == null ? null : _collapseKey(ship);
    if (key == null) {
      kept.add(item);
    } else if (firstIdByKey[key] == ship!.id) {
      kept.add(item);
      if (sizeByKey[key]! > 1) groupSizes[ship.id] = sizeByKey[key]!;
    }
  }
  return CollapsedSkins(kept, groupSizes);
}

String? _collapseKey(Ship ship) {
  final baseHullId = ship.baseHullId;
  if (!ship.isSkin || baseHullId == null) return null;
  return '$baseHullId|${ship.hullNameForDisplay()}';
}
