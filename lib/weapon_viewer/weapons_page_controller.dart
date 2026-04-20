import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/weapons_manager.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';

part 'weapons_page_controller.mapper.dart';

/// Stable page identifier for persistence keying.
const String kWeaponsPageId = 'weapons';

@MappableClass()
class WeaponsPageStatePersisted with WeaponsPageStatePersistedMappable {
  final bool splitPane;
  final bool useContainFit;
  final bool showFilters;

  const WeaponsPageStatePersisted({
    this.splitPane = false,
    this.useContainFit = false,
    this.showFilters = false,
  });
}

@MappableClass()
class WeaponsPageState with WeaponsPageStateMappable {
  final WeaponsPageStatePersisted persisted;
  final List<Weapon> allWeapons;
  final List<Weapon> filteredWeapons;
  final List<Weapon> weaponsBeforeGridFilter;
  final Map<String, List<String>> weaponSearchIndices;
  final String currentSearchQuery;
  final bool isLoading;

  bool get splitPane => persisted.splitPane;

  bool get useContainFit => persisted.useContainFit;

  bool get showFilters => persisted.showFilters;

  const WeaponsPageState({
    this.persisted = const WeaponsPageStatePersisted(),
    this.allWeapons = const [],
    this.filteredWeapons = const [],
    this.weaponsBeforeGridFilter = const [],
    this.weaponSearchIndices = const {},
    this.currentSearchQuery = '',
    this.isLoading = false,
  });
}

@MappableEnum()
enum WeaponSpoilerLevel { noSpoilers, showAllSpoilers }

final weaponsPageControllerProvider =
    NotifierProvider<WeaponsPageController, WeaponsPageState>(
      () => WeaponsPageController(),
    );

class WeaponsPageController extends Notifier<WeaponsPageState> {
  static final _scope = const FilterScope(kWeaponsPageId);

  late final FilterScopeController<Weapon> _filters;

  final vanillaName = 'Vanilla';

  FilterScope get scope => _scope;

  List<FilterGroup<Weapon>> get filterGroups => _filters.groups;

  CompositeFilterGroup<Weapon> get _general =>
      _filters.findGroup('general') as CompositeFilterGroup<Weapon>;

  BoolField<Weapon> get _showEnabledField =>
      _general.fieldById('showEnabled') as BoolField<Weapon>;

  BoolField<Weapon> get _showHiddenField =>
      _general.fieldById('showHidden') as BoolField<Weapon>;

  EnumField<Weapon, WeaponSpoilerLevel> get _spoilerField =>
      _general.fieldById('spoiler') as EnumField<Weapon, WeaponSpoilerLevel>;

  bool get showEnabled => _showEnabledField.value;

  bool get showHidden => _showHiddenField.value;

  WeaponSpoilerLevel get weaponSpoilerLevel => _spoilerField.selected;

  @override
  WeaponsPageState build() {
    if (stateOrNull == null) {
      _filters = _buildFilters();
      final persistence = ref.read(filterGroupPersistenceProvider);
      _filters.loadPersisted(persistence);
    }

    final saved = ref.read(appSettings).weaponsPageState;

    ref.watch(descriptionsNotifierProvider);
    final weaponsAsync = ref.watch(weaponListNotifierProvider);
    final mods = ref.watch(AppState.mods);
    final isLoadingWeapons = ref.watch(isLoadingWeaponsList);

    final allWeapons = weaponsAsync.value ?? [];

    _filters.applyPendingChipMerge(allWeapons);

    Map<String, List<String>> weaponValuesByWeaponId = _updateSearchIndices(
      allWeapons,
    );

    final initialState =
        (stateOrNull ??
                WeaponsPageState(
                  persisted: WeaponsPageStatePersisted(
                    splitPane: saved?.splitPane ?? false,
                    useContainFit: saved?.useContainFit ?? false,
                    showFilters: saved?.showFilters ?? false,
                  ),
                ))
            .copyWith(
              allWeapons: allWeapons,
              weaponSearchIndices: weaponValuesByWeaponId,
              isLoading: isLoadingWeapons,
            );

    return _processAllFilters(initialState, mods);
  }

  FilterScopeController<Weapon> _buildFilters() {
    final groups = <FilterGroup<Weapon>>[
      CompositeFilterGroup<Weapon>(
        id: 'general',
        name: 'General',
        fields: [
          BoolField<Weapon>(
            id: 'showEnabled',
            label: 'Only Enabled Mods',
            tooltip: 'Only show weapons from enabled mods.',
            predicate: (weapon) {
              final mods = ref.read(AppState.mods);
              return weapon.modVariant == null ||
                  weapon.modVariant?.mod(mods)?.hasEnabledVariant == true;
            },
          ),
          BoolField<Weapon>(
            id: 'showHidden',
            label: 'Show Hidden Weapons',
            tooltip: 'Show hidden weapons (built-in, internal).',
            // When showHidden=true, include all → predicate always true.
            // When false, exclude hidden → matches only non-hidden.
            // We implement this with an inverted semantic: the field becomes
            // "inactive" at its default (false), so when false it filters to
            // non-hidden. When true it's active but passes everything.
            predicate: (_) => true,
          ),
          EnumField<Weapon, WeaponSpoilerLevel>(
            id: 'spoiler',
            label: 'Spoilers',
            defaultValue: WeaponSpoilerLevel.noSpoilers,
            options: WeaponSpoilerLevel.values,
            predicate: _spoilerMatches,
            optionLabel: _spoilerLabel,
            optionTooltip: _spoilerTooltip,
            optionIcon: (e) => switch (e) {
              WeaponSpoilerLevel.noSpoilers => Icons.visibility_off,
              WeaponSpoilerLevel.showAllSpoilers => Icons.visibility_outlined,
            },
          ),
        ],
      ),
      ChipFilterGroup<Weapon>(
        id: 'weaponType',
        name: 'Weapon Type',
        valueGetter: (weapon) => weapon.weaponType ?? '',
        displayNameGetter: (name) => name.toTitleCase(),
      ),
      ChipFilterGroup<Weapon>(
        id: 'size',
        name: 'Size',
        valueGetter: (weapon) => weapon.size ?? '',
        displayNameGetter: (name) => name.toTitleCase(),
      ),
      ChipFilterGroup<Weapon>(
        id: 'hint',
        name: 'Hint',
        valueGetter: (weapon) => weapon.hints ?? "",
        valuesGetter: (weapon) => weapon.hintsAsSet.toList(),
        displayNameGetter: (hint) => hint.toTitleCase(),
      ),
      ChipFilterGroup<Weapon>(
        id: 'mod',
        name: 'Mod',
        collapsedByDefault: true,
        valueGetter: (weapon) =>
            weapon.modVariant?.modInfo.nameOrId ?? vanillaName,
        sortComparator: (a, b) => a == vanillaName
            ? -1
            : b == vanillaName
            ? 1
            : a.compareTo(b),
      ),
      ChipFilterGroup<Weapon>(
        id: 'techManufacturer',
        name: 'Tech/Manufacturer',
        collapsedByDefault: true,
        valueGetter: (weapon) => weapon.techManufacturer ?? '',
      ),
    ];
    return FilterScopeController<Weapon>(scope: _scope, groups: groups);
  }

  bool _spoilerMatches(Weapon weapon, WeaponSpoilerLevel level) {
    if (level == WeaponSpoilerLevel.showAllSpoilers) return true;
    final tags =
        weapon.tags?.split(',').map((t) => t.trim().toLowerCase()) ?? const [];
    return !tags.contains('codex_unlockable');
  }

  String _spoilerLabel(WeaponSpoilerLevel e) => switch (e) {
    WeaponSpoilerLevel.noSpoilers => 'No spoilers',
    WeaponSpoilerLevel.showAllSpoilers => 'Show all spoilers',
  };

  String _spoilerTooltip(WeaponSpoilerLevel e) => switch (e) {
    WeaponSpoilerLevel.noSpoilers =>
      'Hides weapons tagged CODEX_UNLOCKABLE.',
    WeaponSpoilerLevel.showAllSpoilers =>
      'Shows weapons tagged CODEX_UNLOCKABLE.',
  };

  void _persistState(WeaponsPageState newState) {
    try {
      ref.read(appSettings.notifier).update((s) {
        final current = s.weaponsPageState ?? const WeaponsPageStatePersisted();
        return s.copyWith(
          weaponsPageState: current.copyWith(
            splitPane: newState.splitPane,
            useContainFit: newState.useContainFit,
            showFilters: newState.showFilters,
          ),
        );
      });
    } catch (_) {}
  }

  Map<String, List<String>> _updateSearchIndices(List<Weapon> allWeapons) {
    final currentIndices = stateOrNull?.weaponSearchIndices ?? {};
    final currentWeaponIds = allWeapons.map((weapon) => weapon.id).toSet();
    final cachedWeaponIds = currentIndices.keys.toSet();

    final indicesToRemove = cachedWeaponIds.difference(currentWeaponIds);
    final weaponValuesByWeaponId = Map<String, List<String>>.from(
      currentIndices,
    );
    for (final weaponId in indicesToRemove) {
      weaponValuesByWeaponId.remove(weaponId);
    }

    final newWeapons = allWeapons.where(
      (weapon) => !cachedWeaponIds.contains(weapon.id),
    );
    for (final weapon in newWeapons) {
      final searchValues = weapon
          .toMap()
          .values
          .map((weaponField) => weaponField.toString().toLowerCase())
          .toList();
      weaponValuesByWeaponId[weapon.id] = searchValues;
    }
    return weaponValuesByWeaponId;
  }

  WeaponsPageState _processAllFilters(
    WeaponsPageState currentState,
    List<Mod> mods,
  ) {
    var weapons = _applyEnabledAndHidden(currentState.allWeapons.toList());
    weapons = _applySpoilers(weapons);

    final weaponsBeforeGridFilter = weapons.toList();

    weapons = _filters.applyChipFilters(weapons);

    weapons = _filterBySearch(
      weapons,
      currentState.currentSearchQuery,
      currentState.weaponSearchIndices,
    );

    return currentState.copyWith(
      filteredWeapons: weapons,
      weaponsBeforeGridFilter: weaponsBeforeGridFilter,
    );
  }

  /// Composite fields don't map cleanly to "show X unless flag" semantics for
  /// showHidden (the *inactive* state is the one that filters). Apply these
  /// rules directly here instead of via the composite's AND.
  List<Weapon> _applyEnabledAndHidden(List<Weapon> weapons) {
    if (showEnabled) {
      final mods = ref.read(AppState.mods);
      weapons = weapons.where((weapon) {
        return weapon.modVariant == null ||
            weapon.modVariant?.mod(mods)?.hasEnabledVariant == true;
      }).toList();
    }
    if (!showHidden) {
      weapons = weapons.where((weapon) => !weapon.isHidden()).toList();
    }
    return weapons;
  }

  List<Weapon> _applySpoilers(List<Weapon> weapons) {
    final level = weaponSpoilerLevel;
    if (level == WeaponSpoilerLevel.showAllSpoilers) return weapons;
    return weapons.where((w) => _spoilerMatches(w, level)).toList();
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

  void setWeaponSpoilerLevel(WeaponSpoilerLevel level) {
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
      persisted: state.persisted.copyWith(useContainFit: !state.useContainFit),
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

  List<Weapon> _filterBySearch(
    List<Weapon> weapons,
    String query,
    Map<String, List<String>> weaponValuesByWeaponId,
  ) {
    if (query.isEmpty) return weapons;

    query = query.toLowerCase();

    return weapons.where((weapon) {
      return weaponValuesByWeaponId[weapon.id]?.any(
            (value) => value.contains(query),
          ) ??
          false;
    }).toList();
  }
}
