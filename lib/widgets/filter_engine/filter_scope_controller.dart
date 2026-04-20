import 'package:flutter/foundation.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';
import 'filter_group.dart';
import 'filter_scope.dart';

/// Toolkit-style helper that owns a [FilterScope]'s groups and exposes
/// functions for the hosting [Notifier] to compose into its own pipeline.
///
/// Not a framework: pages still own `build()` and control pipeline order.
class FilterScopeController<T> {
  final FilterScope scope;
  final List<FilterGroup<T>> groups;

  /// When false, [loadPersisted] and [maybePersist] become no-ops.
  /// Used by portraits `left`/`right` scopes.
  final bool persistenceEnabled;

  /// Chip-group staging: pending selections loaded from settings waiting for
  /// their values to appear in the currently-loaded data set.
  final Map<String, Map<String, bool?>> _pendingChipSelections = {};

  bool _persistedLoadedOnce = false;

  bool get hasPendingChipSelections => _pendingChipSelections.isNotEmpty;

  FilterScopeController({
    required this.scope,
    required this.groups,
    this.persistenceEnabled = true,
  });

  /// Apply all chip groups to [items] in declaration order.
  List<T> applyChipFilters(Iterable<T> items) {
    Iterable<T> out = items;
    for (final g in groups) {
      if (g is ChipFilterGroup<T> && g.isActive) {
        out = out.where(g.matches);
      }
    }
    return out.toList();
  }

  /// Apply all non-chip groups (bool / enum / composite) to [items] in
  /// declaration order.
  List<T> applyNonChipFilters(Iterable<T> items) {
    Iterable<T> out = items;
    for (final g in groups) {
      if (g is ChipFilterGroup<T>) continue;
      if (!g.isActive) continue;
      out = out.where(g.matches);
    }
    return out.toList();
  }

  int get activeCount {
    var total = 0;
    for (final g in groups) {
      total += g.activeCount;
    }
    return total;
  }

  void clearAll() {
    for (final g in groups) {
      g.clear();
    }
  }

  /// Replace a chip group's selections wholesale and persist if locked.
  /// Used by context-menu navigation to "jump to this mod".
  void setChipSelections(String groupId, Map<String, bool?> selections) {
    final g = _findChipGroup(groupId);
    if (g == null) return;
    g.setSelections(selections);
  }

  ChipFilterGroup<T>? _findChipGroup(String groupId) {
    for (final g in groups) {
      if (g is ChipFilterGroup<T> && g.id == groupId) return g;
    }
    return null;
  }

  FilterGroup<T>? findGroup(String groupId) {
    for (final g in groups) {
      if (g.id == groupId) return g;
    }
    return null;
  }

  /// Load persisted state from settings.
  ///
  /// For composite/bool/enum groups, restore is immediate and intrinsic.
  /// For chip groups we stage selections and apply only those values that
  /// exist in the current data (unknowns remain inert).
  ///
  /// Safe to call every build — reads settings only once.
  void loadPersisted(FilterGroupPersistence persistence) {
    if (!persistenceEnabled) return;
    if (_persistedLoadedOnce) return;
    final entries = persistence.allForScope(scope);
    for (final entry in entries.entries) {
      final group = findGroup(entry.key);
      if (group == null) continue;
      final selections = entry.value.selections;
      if (group is ChipFilterGroup<T>) {
        // Stage raw chip selections; apply-merge later when data is present.
        _pendingChipSelections[entry.key] = {
          for (final e in selections.entries)
            if (e.value == null || e.value is bool)
              e.key: e.value as bool?,
        };
      } else {
        group.restore(selections);
      }
    }
    _persistedLoadedOnce = true;
  }

  /// Merge staged chip selections into live state for values that appear in
  /// [items]. Applied entries are removed from staging; unknowns remain for a
  /// future call.
  ///
  /// Does not overwrite existing live entries so user edits after the initial
  /// apply are preserved.
  void applyPendingChipMerge(Iterable<T> items) {
    if (_pendingChipSelections.isEmpty) return;
    final pendingKeys = _pendingChipSelections.keys.toList();
    for (final groupId in pendingKeys) {
      final group = _findChipGroup(groupId);
      if (group == null) continue;
      final pending = _pendingChipSelections[groupId]!;
      final validValues = <String>{};
      for (final item in items) {
        if (group.valuesGetter != null) {
          validValues.addAll(
            group.valuesGetter!(item).where((v) => v.isNotEmpty),
          );
        } else {
          final v = group.valueGetter(item);
          if (v.isNotEmpty) validValues.add(v);
        }
      }
      final applied = <String>[];
      for (final e in pending.entries) {
        if (validValues.contains(e.key)) {
          group.filterStates.putIfAbsent(e.key, () => e.value);
          applied.add(e.key);
        }
      }
      for (final k in applied) {
        pending.remove(k);
      }
      if (pending.isEmpty) _pendingChipSelections.remove(groupId);
    }
  }

  /// If the group is locked (persistence entry exists), mirror its serialized
  /// state to settings. No-op when [persistenceEnabled] is false.
  void maybePersist(String groupId, FilterGroupPersistence persistence) {
    if (!persistenceEnabled) return;
    final existing = persistence.read(scope, groupId);
    if (existing == null) return;
    final group = findGroup(groupId);
    if (group == null) return;
    final serialized = group.serialize();
    if (mapEquals(existing.selections, serialized)) return;
    try {
      persistence.write(scope, groupId, serialized);
    } catch (e, st) {
      Fimber.w('Failed to persist filter group $groupId', ex: e, stacktrace: st);
    }
  }
}
