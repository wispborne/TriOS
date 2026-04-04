import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/hullmod_viewer/hullmods_manager.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/filter_widget.dart';

part 'hullmods_page_controller.mapper.dart';

@MappableClass()
class HullmodsPageStatePersisted with HullmodsPageStatePersistedMappable {
  final bool showEnabled;
  final bool splitPane;
  final bool useContainFit;

  const HullmodsPageStatePersisted({
    this.showEnabled = false,
    this.splitPane = false,
    this.useContainFit = false,
  });
}

@MappableClass()
class HullmodsPageState with HullmodsPageStateMappable {
  final HullmodsPageStatePersisted persisted;
  final List<GridFilter<Hullmod>> filterCategories;
  final List<Hullmod> allHullmods;
  final List<Hullmod> filteredHullmods;
  final List<Hullmod> hullmodsBeforeGridFilter;
  final Map<String, List<String>> hullmodSearchIndices;
  final String currentSearchQuery;
  final bool showFilters;
  final bool isLoading;
  final bool showHidden;
  final HullmodSpoilerLevel hullmodSpoilerLevel;

  bool get showEnabled => persisted.showEnabled;
  bool get splitPane => persisted.splitPane;
  bool get useContainFit => persisted.useContainFit;

  const HullmodsPageState({
    this.persisted = const HullmodsPageStatePersisted(),
    this.filterCategories = const [],
    this.allHullmods = const [],
    this.filteredHullmods = const [],
    this.hullmodsBeforeGridFilter = const [],
    this.hullmodSearchIndices = const {},
    this.currentSearchQuery = '',
    this.showFilters = false,
    this.isLoading = false,
    this.showHidden = false,
    this.hullmodSpoilerLevel = HullmodSpoilerLevel.noSpoilers,
  });
}

@MappableEnum()
enum HullmodSpoilerLevel { noSpoilers, showAllSpoilers }

final hullmodsPageControllerProvider =
    NotifierProvider<HullmodsPageController, HullmodsPageState>(
      () => HullmodsPageController(),
    );

class HullmodsPageController extends Notifier<HullmodsPageState> {
  @override
  HullmodsPageState build() {
    final vanillaName = 'Vanilla';

    final filterCategories = [
      GridFilter<Hullmod>(
        name: 'Mod',
        valueGetter: (hullmod) =>
            hullmod.modVariant?.modInfo.nameOrId ?? vanillaName,
        sortComparator: (a, b) => a == vanillaName
            ? -1
            : b == vanillaName
            ? 1
            : a.compareTo(b),
      ),
      GridFilter<Hullmod>(
        name: 'Tech/Manufacturer',
        valueGetter: (hullmod) => hullmod.techManufacturer ?? '',
      ),
      GridFilter<Hullmod>(
        name: 'UI Tags',
        valueGetter: (hullmod) => hullmod.uiTags ?? '',
        valuesGetter: (hullmod) => hullmod.uiTags
                ?.split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList() ??
            [],
      ),
    ];

    final saved = ref.read(appSettings).hullmodsPageState;

    final hullmodsAsync = ref.watch(hullmodListNotifierProvider);
    final mods = ref.watch(AppState.mods);
    final isLoadingHullmods = ref.watch(isLoadingHullmodsList);

    final allHullmods = hullmodsAsync.value ?? [];

    Map<String, List<String>> hullmodValuesByHullmodId = _updateSearchIndices(
      allHullmods,
    );

    var initialState =
        (stateOrNull ??
                HullmodsPageState(
                  persisted: HullmodsPageStatePersisted(
                    showEnabled: saved?.showEnabled ?? false,
                    splitPane: saved?.splitPane ?? false,
                    useContainFit: saved?.useContainFit ?? false,
                  ),
                ))
            .copyWith(
              filterCategories:
                  stateOrNull?.filterCategories ?? filterCategories,
              allHullmods: allHullmods,
              hullmodSearchIndices: hullmodValuesByHullmodId,
              isLoading: isLoadingHullmods,
            );

    final processedState = _processAllFilters(initialState, mods);

    return processedState;
  }

  void _persistState(HullmodsPageState newState) {
    try {
      ref.read(appSettings.notifier).update((s) {
        final current =
            s.hullmodsPageState ?? const HullmodsPageStatePersisted();
        return s.copyWith(
          hullmodsPageState: current.copyWith(
            showEnabled: newState.showEnabled,
            splitPane: newState.splitPane,
            useContainFit: newState.useContainFit,
          ),
        );
      });
    } catch (_) {
      // swallow; persistence failures shouldn't break UX
    }
  }

  Map<String, List<String>> _updateSearchIndices(List<Hullmod> allHullmods) {
    final currentIndices = stateOrNull?.hullmodSearchIndices ?? {};
    final currentHullmodIds = allHullmods.map((hullmod) => hullmod.id).toSet();
    final cachedHullmodIds = currentIndices.keys.toSet();

    final indicesToRemove = cachedHullmodIds.difference(currentHullmodIds);
    final hullmodValuesByHullmodId = Map<String, List<String>>.from(
      currentIndices,
    );
    for (final hullmodId in indicesToRemove) {
      hullmodValuesByHullmodId.remove(hullmodId);
    }

    final newHullmods = allHullmods.where(
      (hullmod) => !cachedHullmodIds.contains(hullmod.id),
    );
    for (final hullmod in newHullmods) {
      final searchValues = hullmod
          .toMap()
          .values
          .map((hullmodField) => hullmodField.toString().toLowerCase())
          .toList();
      hullmodValuesByHullmodId[hullmod.id] = searchValues;
    }
    return hullmodValuesByHullmodId;
  }

  HullmodsPageState _processAllFilters(
    HullmodsPageState currentState,
    List<Mod> mods,
  ) {
    var hullmods = currentState.allHullmods.toList();

    hullmods = _filterByEnabled(hullmods, mods, currentState.showEnabled);
    hullmods = _filterByHidden(hullmods, currentState.showHidden);
    hullmods = _filterByHullmodSpoilers(
      hullmods,
      currentState.hullmodSpoilerLevel,
    );

    final hullmodsBeforeGridFilter = hullmods.toList();

    hullmods = _applyFilters(hullmods, currentState.filterCategories);

    hullmods = _filterBySearch(
      hullmods,
      currentState.currentSearchQuery,
      currentState.hullmodSearchIndices,
    );

    return currentState.copyWith(
      filteredHullmods: hullmods,
      hullmodsBeforeGridFilter: hullmodsBeforeGridFilter,
    );
  }

  void updateSearchQuery(String query) {
    final mods = ref.read(AppState.mods);
    final updatedState = state.copyWith(currentSearchQuery: query);
    final processedState = _processAllFilters(updatedState, mods);

    state = processedState;
  }

  void toggleShowEnabled() {
    final mods = ref.read(AppState.mods);
    final updatedState = state.copyWith(
      persisted: state.persisted.copyWith(showEnabled: !state.showEnabled),
    );
    final processedState = _processAllFilters(updatedState, mods);

    state = processedState;
    _persistState(state);
  }

  void toggleShowHidden() {
    final mods = ref.read(AppState.mods);
    final updatedState = state.copyWith(showHidden: !state.showHidden);
    final processedState = _processAllFilters(updatedState, mods);

    state = processedState;
  }

  void setHullmodSpoilerLevel(HullmodSpoilerLevel level) {
    final mods = ref.read(AppState.mods);
    final updatedState = state.copyWith(hullmodSpoilerLevel: level);
    final processedState = _processAllFilters(updatedState, mods);

    state = processedState;
  }

  void toggleSplitPane() {
    final updatedState = state.copyWith(
      persisted: state.persisted.copyWith(splitPane: !state.splitPane),
    );
    state = updatedState;
    _persistState(state);
  }

  void toggleShowFilters() {
    final updatedState = state.copyWith(showFilters: !state.showFilters);
    state = updatedState;
  }

  /// Toggle image fit between scaleDown and contain
  void toggleUseContainFit() {
    final updatedState = state.copyWith(
      persisted: state.persisted.copyWith(
        useContainFit: !state.useContainFit,
      ),
    );
    state = updatedState;
    _persistState(state);
  }

  int get activeFilterCount =>
      state.filterCategories.fold(
        0,
        (sum, f) => sum + f.filterStates.length,
      ) +
      (state.showEnabled ? 1 : 0) +
      (state.showHidden ? 1 : 0) +
      (state.hullmodSpoilerLevel != HullmodSpoilerLevel.showAllSpoilers
          ? 1
          : 0);

  Directory getGameCoreDir() {
    return Directory(ref.read(AppState.gameCoreFolder).value?.path ?? '');
  }

  void clearAllFilters() {
    final mods = ref.read(AppState.mods);

    for (final filter in state.filterCategories) {
      filter.filterStates.clear();
    }

    final updatedState = state.copyWith(
      filterCategories: List.from(state.filterCategories),
    );
    final processedState = _processAllFilters(updatedState, mods);

    state = processedState;
  }

  void updateFilterStates(GridFilter filter, Map<String, bool?> states) {
    final mods = ref.read(AppState.mods);

    filter.filterStates.clear();
    filter.filterStates.addAll(states);

    final updatedState = state.copyWith(
      filterCategories: List.from(state.filterCategories),
    );
    final processedState = _processAllFilters(updatedState, mods);

    state = processedState;
  }

  List<Hullmod> _filterByEnabled(
    List<Hullmod> hullmods,
    List<Mod> mods,
    bool showEnabled,
  ) {
    if (!showEnabled) return hullmods;

    return hullmods.where((hullmod) {
      return hullmod.modVariant == null ||
          hullmod.modVariant?.mod(mods)?.hasEnabledVariant == true;
    }).toList();
  }

  List<Hullmod> _filterByHidden(List<Hullmod> hullmods, bool showHidden) {
    if (showHidden) return hullmods;

    return hullmods
        .where(
          (hullmod) =>
              hullmod.hidden != true && hullmod.hiddenEverywhere != true,
        )
        .toList();
  }

  List<Hullmod> _filterByHullmodSpoilers(
    List<Hullmod> hullmods,
    HullmodSpoilerLevel level,
  ) {
    if (level == HullmodSpoilerLevel.showAllSpoilers) return hullmods;

    return hullmods.where((hullmod) {
      final isCodexUnlockable = hullmod.tagsAsSet.contains('codex_unlockable');
      final isCodexRequireRelated =
          hullmod.tagsAsSet.contains('codex_require_related');
      return !isCodexUnlockable && !isCodexRequireRelated;
    }).toList();
  }

  List<Hullmod> _applyFilters(
    List<Hullmod> hullmods,
    List<GridFilter<Hullmod>> filterCategories,
  ) {
    for (final filter in filterCategories) {
      if (filter.hasActiveFilters) {
        hullmods = hullmods.where((hullmod) {
          // Multi-value filter (e.g. UI Tags split by comma).
          if (filter.valuesGetter != null) {
            final values = filter.valuesGetter!(hullmod);
            final hasIncludedValues =
                filter.filterStates.values.contains(true);

            // Exclude if any of the item's values are explicitly excluded.
            if (values.any((v) => filter.filterStates[v] == false)) {
              return false;
            }

            // If there are included values, at least one must match.
            if (hasIncludedValues) {
              return values.any((v) => filter.filterStates[v] == true);
            }

            return true;
          }

          // Single-value filter.
          final value = filter.valueGetter(hullmod);
          final filterState = filter.filterStates[value];

          if (filterState == false) {
            return false;
          }

          final hasIncludedValues = filter.filterStates.values.contains(true);
          if (hasIncludedValues) {
            return filterState == true;
          }

          return true;
        }).toList();
      }
    }
    return hullmods;
  }

  List<Hullmod> _filterBySearch(
    List<Hullmod> hullmods,
    String query,
    Map<String, List<String>> hullmodValuesByHullmodId,
  ) {
    if (query.isEmpty) return hullmods;

    query = query.toLowerCase();

    return hullmods.where((hullmod) {
      return hullmodValuesByHullmodId[hullmod.id]?.any(
            (value) => value.contains(query),
          ) ??
          false;
    }).toList();
  }
}
