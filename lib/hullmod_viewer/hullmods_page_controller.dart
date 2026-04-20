import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/hullmod_viewer/hullmods_manager.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';

part 'hullmods_page_controller.mapper.dart';

/// Stable page identifier for persistence keying.
const String kHullmodsPageId = 'hullmods';

@MappableClass()
class HullmodsPageStatePersisted with HullmodsPageStatePersistedMappable {
  final bool splitPane;
  final bool useContainFit;
  final bool showFilters;

  const HullmodsPageStatePersisted({
    this.splitPane = false,
    this.useContainFit = false,
    this.showFilters = false,
  });
}

@MappableClass()
class HullmodsPageState with HullmodsPageStateMappable {
  final HullmodsPageStatePersisted persisted;
  final List<Hullmod> allHullmods;
  final List<Hullmod> filteredHullmods;
  final List<Hullmod> hullmodsBeforeGridFilter;
  final Map<String, List<String>> hullmodSearchIndices;
  final String currentSearchQuery;
  final bool isLoading;

  bool get splitPane => persisted.splitPane;
  bool get useContainFit => persisted.useContainFit;
  bool get showFilters => persisted.showFilters;

  const HullmodsPageState({
    this.persisted = const HullmodsPageStatePersisted(),
    this.allHullmods = const [],
    this.filteredHullmods = const [],
    this.hullmodsBeforeGridFilter = const [],
    this.hullmodSearchIndices = const {},
    this.currentSearchQuery = '',
    this.isLoading = false,
  });
}

@MappableEnum()
enum HullmodSpoilerLevel { noSpoilers, showAllSpoilers }

final hullmodsPageControllerProvider =
    NotifierProvider<HullmodsPageController, HullmodsPageState>(
      () => HullmodsPageController(),
    );

class HullmodsPageController extends Notifier<HullmodsPageState> {
  static final _scope = const FilterScope(kHullmodsPageId);

  late final FilterScopeController<Hullmod> _filters;

  final vanillaName = 'Vanilla';

  FilterScope get scope => _scope;

  List<FilterGroup<Hullmod>> get filterGroups => _filters.groups;

  CompositeFilterGroup<Hullmod> get _general =>
      _filters.findGroup('general') as CompositeFilterGroup<Hullmod>;

  BoolField<Hullmod> get _showEnabledField =>
      _general.fieldById('showEnabled') as BoolField<Hullmod>;

  BoolField<Hullmod> get _showHiddenField =>
      _general.fieldById('showHidden') as BoolField<Hullmod>;

  EnumField<Hullmod, HullmodSpoilerLevel> get _spoilerField =>
      _general.fieldById('spoiler') as EnumField<Hullmod, HullmodSpoilerLevel>;

  bool get showEnabled => _showEnabledField.value;

  bool get showHidden => _showHiddenField.value;

  HullmodSpoilerLevel get hullmodSpoilerLevel => _spoilerField.selected;

  @override
  HullmodsPageState build() {
    if (stateOrNull == null) {
      _filters = _buildFilters();
      final persistence = ref.read(filterGroupPersistenceProvider);
      _filters.loadPersisted(persistence);
    }

    final saved = ref.read(appSettings).hullmodsPageState;

    ref.watch(descriptionsNotifierProvider);
    final hullmodsAsync = ref.watch(hullmodListNotifierProvider);
    final mods = ref.watch(AppState.mods);
    final isLoadingHullmods = ref.watch(isLoadingHullmodsList);

    final allHullmods = hullmodsAsync.value ?? [];

    _filters.applyPendingChipMerge(allHullmods);

    Map<String, List<String>> hullmodValuesByHullmodId = _updateSearchIndices(
      allHullmods,
    );

    var initialState =
        (stateOrNull ??
                HullmodsPageState(
                  persisted: HullmodsPageStatePersisted(
                    splitPane: saved?.splitPane ?? false,
                    useContainFit: saved?.useContainFit ?? false,
                    showFilters: saved?.showFilters ?? false,
                  ),
                ))
            .copyWith(
              allHullmods: allHullmods,
              hullmodSearchIndices: hullmodValuesByHullmodId,
              isLoading: isLoadingHullmods,
            );

    return _processAllFilters(initialState, mods);
  }

  FilterScopeController<Hullmod> _buildFilters() {
    final groups = <FilterGroup<Hullmod>>[
      CompositeFilterGroup<Hullmod>(
        id: 'general',
        name: 'General',
        fields: [
          BoolField<Hullmod>(
            id: 'showEnabled',
            label: 'Only Enabled Mods',
            tooltip: 'Only hullmods from enabled mods.',
            predicate: (hullmod) {
              final mods = ref.read(AppState.mods);
              return hullmod.modVariant == null ||
                  hullmod.modVariant?.mod(mods)?.hasEnabledVariant == true;
            },
          ),
          BoolField<Hullmod>(
            id: 'showHidden',
            label: 'Show Hidden Hullmods',
            tooltip: 'Show hidden hullmods (built-in, internal).',
            predicate: (_) => true, // manual application (inverted default).
          ),
          EnumField<Hullmod, HullmodSpoilerLevel>(
            id: 'spoiler',
            label: 'Spoilers',
            defaultValue: HullmodSpoilerLevel.noSpoilers,
            options: HullmodSpoilerLevel.values,
            predicate: _spoilerMatches,
            optionLabel: _spoilerLabel,
            optionTooltip: _spoilerTooltip,
            optionIcon: (e) => switch (e) {
              HullmodSpoilerLevel.noSpoilers => Icons.visibility_off,
              HullmodSpoilerLevel.showAllSpoilers => Icons.visibility_outlined,
            },
          ),
        ],
      ),
      ChipFilterGroup<Hullmod>(
        id: 'mod',
        name: 'Mod',
        valueGetter: (hullmod) =>
            hullmod.modVariant?.modInfo.nameOrId ?? vanillaName,
        sortComparator: (a, b) => a == vanillaName
            ? -1
            : b == vanillaName
            ? 1
            : a.compareTo(b),
      ),
      ChipFilterGroup<Hullmod>(
        id: 'techManufacturer',
        name: 'Tech/Manufacturer',
        valueGetter: (hullmod) => hullmod.techManufacturer ?? '',
      ),
      ChipFilterGroup<Hullmod>(
        id: 'uiTags',
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
    return FilterScopeController<Hullmod>(scope: _scope, groups: groups);
  }

  bool _spoilerMatches(Hullmod hullmod, HullmodSpoilerLevel level) {
    if (level == HullmodSpoilerLevel.showAllSpoilers) return true;
    final isCodexUnlockable = hullmod.tagsAsSet.contains('codex_unlockable');
    final isCodexRequireRelated =
        hullmod.tagsAsSet.contains('codex_require_related');
    return !isCodexUnlockable && !isCodexRequireRelated;
  }

  String _spoilerLabel(HullmodSpoilerLevel e) => switch (e) {
    HullmodSpoilerLevel.noSpoilers => 'No spoilers',
    HullmodSpoilerLevel.showAllSpoilers => 'Show all spoilers',
  };

  String _spoilerTooltip(HullmodSpoilerLevel e) => switch (e) {
    HullmodSpoilerLevel.noSpoilers =>
      'Hides hullmods tagged CODEX_UNLOCKABLE or CODEX_REQUIRE_RELATED.',
    HullmodSpoilerLevel.showAllSpoilers =>
      'Shows hullmods tagged CODEX_UNLOCKABLE or CODEX_REQUIRE_RELATED.',
  };

  void _persistState(HullmodsPageState newState) {
    try {
      ref.read(appSettings.notifier).update((s) {
        final current =
            s.hullmodsPageState ?? const HullmodsPageStatePersisted();
        return s.copyWith(
          hullmodsPageState: current.copyWith(
            splitPane: newState.splitPane,
            useContainFit: newState.useContainFit,
            showFilters: newState.showFilters,
          ),
        );
      });
    } catch (_) {}
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
    var hullmods = _applyEnabledAndHidden(currentState.allHullmods.toList());
    hullmods = _applySpoilers(hullmods);

    final hullmodsBeforeGridFilter = hullmods.toList();

    hullmods = _filters.applyChipFilters(hullmods);

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

  List<Hullmod> _applyEnabledAndHidden(List<Hullmod> hullmods) {
    if (showEnabled) {
      final mods = ref.read(AppState.mods);
      hullmods = hullmods.where((h) {
        return h.modVariant == null ||
            h.modVariant?.mod(mods)?.hasEnabledVariant == true;
      }).toList();
    }
    if (!showHidden) {
      hullmods = hullmods
          .where((h) => h.hidden != true && h.hiddenEverywhere != true)
          .toList();
    }
    return hullmods;
  }

  List<Hullmod> _applySpoilers(List<Hullmod> hullmods) {
    final level = hullmodSpoilerLevel;
    if (level == HullmodSpoilerLevel.showAllSpoilers) return hullmods;
    return hullmods.where((h) => _spoilerMatches(h, level)).toList();
  }

  void updateSearchQuery(String query) {
    final mods = ref.read(AppState.mods);
    final updatedState = state.copyWith(currentSearchQuery: query);
    state = _processAllFilters(updatedState, mods);
  }

  void toggleShowEnabled() {
    _showEnabledField.value = !_showEnabledField.value;
    _emitAfterFilterMutation();
    _filters.maybePersist('general', ref.read(filterGroupPersistenceProvider));
  }

  void toggleShowHidden() {
    _showHiddenField.value = !_showHiddenField.value;
    _emitAfterFilterMutation();
    _filters.maybePersist('general', ref.read(filterGroupPersistenceProvider));
  }

  void setHullmodSpoilerLevel(HullmodSpoilerLevel level) {
    _spoilerField.setSelected(level);
    _emitAfterFilterMutation();
    _filters.maybePersist('general', ref.read(filterGroupPersistenceProvider));
  }

  void toggleSplitPane() {
    final updatedState = state.copyWith(
      persisted: state.persisted.copyWith(splitPane: !state.splitPane),
    );
    state = updatedState;
    _persistState(state);
  }

  void toggleShowFilters() {
    final updatedState = state.copyWith(
      persisted: state.persisted.copyWith(showFilters: !state.showFilters),
    );
    state = updatedState;
    _persistState(state);
  }

  void toggleUseContainFit() {
    final updatedState = state.copyWith(
      persisted: state.persisted.copyWith(
        useContainFit: !state.useContainFit,
      ),
    );
    state = updatedState;
    _persistState(state);
  }

  int get activeFilterCount => _filters.activeCount;

  Directory getGameCoreDir() {
    return Directory(ref.read(AppState.gameCoreFolder).value?.path ?? '');
  }

  void clearAllFilters() {
    _filters.clearAll();
    _emitAfterFilterMutation();
  }

  void onGroupChanged(String groupId) {
    _emitAfterFilterMutation();
    _filters.maybePersist(groupId, ref.read(filterGroupPersistenceProvider));
  }

  void setChipSelections(String groupId, Map<String, bool?> selections) {
    _filters.setChipSelections(groupId, selections);
    _emitAfterFilterMutation();
  }

  void _emitAfterFilterMutation() {
    final mods = ref.read(AppState.mods);
    state = _processAllFilters(state, mods);
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
