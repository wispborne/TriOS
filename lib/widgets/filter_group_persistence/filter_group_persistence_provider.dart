import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/filter_engine/filter_scope.dart';
import 'package:trios/widgets/filter_group_persistence/persisted_filter_group.dart';

/// Thin wrapper around [appSettings] that reads/writes [PersistedFilterGroup]
/// entries keyed by `(FilterScope, filterGroupId)`.
///
/// The key format is `"<pageId>::<scopeId>::<filterGroupId>"` — stable across
/// display-name changes and translations.
class FilterGroupPersistence {
  final Ref _ref;

  FilterGroupPersistence(this._ref);

  static String keyFor(FilterScope scope, String filterGroupId) =>
      scope.keyFor(filterGroupId);

  PersistedFilterGroup? read(FilterScope scope, String filterGroupId) {
    final map = _ref.read(appSettings).persistedFilterGroups;
    return map[keyFor(scope, filterGroupId)];
  }

  /// Writes the persisted entry. Skips write if the stored selections equal
  /// [selections] to avoid flooding settings with identical updates.
  Future<void> write(
    FilterScope scope,
    String filterGroupId,
    Map<String, Object?> selections,
  ) async {
    final key = keyFor(scope, filterGroupId);
    final existing = _ref.read(appSettings).persistedFilterGroups[key];
    if (existing != null && mapEquals(existing.selections, selections)) return;
    await _ref.read(appSettings.notifier).update((s) {
      final next = Map<String, PersistedFilterGroup>.from(
        s.persistedFilterGroups,
      );
      next[key] = PersistedFilterGroup(
        selections: Map<String, Object?>.from(selections),
      );
      return s.copyWith(persistedFilterGroups: next);
    });
  }

  Future<void> clear(FilterScope scope, String filterGroupId) async {
    final key = keyFor(scope, filterGroupId);
    await _ref.read(appSettings.notifier).update((s) {
      if (!s.persistedFilterGroups.containsKey(key)) return s;
      final next = Map<String, PersistedFilterGroup>.from(
        s.persistedFilterGroups,
      );
      next.remove(key);
      return s.copyWith(persistedFilterGroups: next);
    });
  }

  /// Returns all persisted entries under [scope] keyed by `filterGroupId`.
  Map<String, PersistedFilterGroup> allForScope(FilterScope scope) {
    final prefix = '${scope.pageId}::${scope.scopeId}::';
    final map = _ref.read(appSettings).persistedFilterGroups;
    final out = <String, PersistedFilterGroup>{};
    for (final entry in map.entries) {
      if (entry.key.startsWith(prefix)) {
        out[entry.key.substring(prefix.length)] = entry.value;
      }
    }
    return out;
  }
}

/// Riverpod provider exposing the [FilterGroupPersistence] helper.
final filterGroupPersistenceProvider = Provider<FilterGroupPersistence>(
  (ref) => FilterGroupPersistence(ref),
);
