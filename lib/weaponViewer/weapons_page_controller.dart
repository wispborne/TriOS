import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/shipViewer/filter_widget.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weaponViewer/models/weapon.dart';
import 'package:trios/weaponViewer/weapons_manager.dart';

part 'weapons_page_controller.mapper.dart';

@MappableClass()
class WeaponsPageState with WeaponsPageStateMappable {
  final List<GridFilter<Weapon>> filterCategories;
  final List<Weapon> allWeapons;
  final List<Weapon> filteredWeapons;
  final List<Weapon> weaponsBeforeGridFilter;
  final Map<String, List<String>> weaponSearchIndices;
  final String currentSearchQuery;
  final bool showEnabled;
  final bool showHidden;
  final bool splitPane;
  final bool showFilters;
  final bool isLoading;
  final WeaponSpoilerLevel weaponSpoilerLevel;

  const WeaponsPageState({
    this.filterCategories = const [],
    this.allWeapons = const [],
    this.filteredWeapons = const [],
    this.weaponsBeforeGridFilter = const [],
    this.weaponSearchIndices = const {},
    this.currentSearchQuery = '',
    this.showEnabled = false,
    this.showHidden = false,
    this.splitPane = false,
    this.showFilters = false,
    this.isLoading = false,
    this.weaponSpoilerLevel = WeaponSpoilerLevel.noSpoilers,
  });
}

@MappableEnum()
enum WeaponSpoilerLevel { noSpoilers, showAllSpoilers }

// Provider for the weapons page controller
final weaponsPageControllerProvider =
    AutoDisposeNotifierProvider<WeaponsPageController, WeaponsPageState>(
      () => WeaponsPageController(),
    );

class WeaponsPageController extends AutoDisposeNotifier<WeaponsPageState> {
  @override
  WeaponsPageState build() {
    // Initialize filter categories
    final filterCategories = [
      GridFilter<Weapon>(
        name: 'Weapon Type',
        valueGetter: (weapon) => weapon.weaponType ?? '',
        displayNameGetter: (name) => name.toTitleCase(),
      ),
      GridFilter<Weapon>(
        name: 'Mod',
        valueGetter: (weapon) =>
            weapon.modVariant?.modInfo.nameOrId ?? 'Vanilla',
      ),
      GridFilter<Weapon>(
        name: 'Size',
        valueGetter: (weapon) => weapon.size ?? '',
        displayNameGetter: (name) => name.toTitleCase(),
      ),
      GridFilter<Weapon>(
        name: 'Tech/Manufacturer',
        valueGetter: (weapon) => weapon.techManufacturer ?? '',
      ),
    ];

    // Watch weapon data
    final weaponsAsync = ref.watch(weaponListNotifierProvider);
    final mods = ref.watch(AppState.mods);
    final isLoadingWeapons = ref.watch(isLoadingWeaponsList);

    final allWeapons = weaponsAsync.valueOrNull ?? [];

    // Build search index from current weapons (incremental update)
    Map<String, List<String>> weaponValuesByWeaponId = _updateSearchIndices(
      allWeapons,
    );

    // Build initial state
    var initialState = (stateOrNull ?? WeaponsPageState()).copyWith(
      filterCategories: filterCategories,
      allWeapons: allWeapons,
      // filteredWeapons: [],
      // weaponsBeforeGridFilter: [],
      weaponSearchIndices: weaponValuesByWeaponId,
      isLoading: isLoadingWeapons,
    );

    // Process filters to get final weapon lists
    final processedState = _processAllFilters(initialState, mods);

    return processedState;
  }

  Map<String, List<String>> _updateSearchIndices(List<Weapon> allWeapons) {
    // Build search index from current weapons (incremental update)
    final currentIndices = stateOrNull?.weaponSearchIndices ?? {};
    final currentWeaponIds = allWeapons.map((weapon) => weapon.id).toSet();
    final cachedWeaponIds = currentIndices.keys.toSet();

    // Remove indices for weapons that are no longer present
    final indicesToRemove = cachedWeaponIds.difference(currentWeaponIds);
    final weaponValuesByWeaponId = Map<String, List<String>>.from(
      currentIndices,
    );
    for (final weaponId in indicesToRemove) {
      weaponValuesByWeaponId.remove(weaponId);
    }

    // Add indices only for new weapons that don't already have them
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

  /// Process all filters and return updated state
  WeaponsPageState _processAllFilters(
    WeaponsPageState currentState,
    List<Mod> mods,
  ) {
    var weapons = currentState.allWeapons.toList();

    weapons = _filterByEnabled(weapons, mods, currentState.showEnabled);

    weapons = _filterByHidden(weapons, currentState.showHidden);

    weapons = _filterByWeaponSpoilers(weapons, currentState.weaponSpoilerLevel);

    // Store weapons before grid filters for filter panel
    final weaponsBeforeGridFilter = weapons.toList();

    // Apply grid filters
    weapons = _applyFilters(weapons, currentState.filterCategories);

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

  /// Update search query and reprocess filters
  void updateSearchQuery(String query) {
    final mods = ref.read(AppState.mods);
    final updatedState = state.copyWith(currentSearchQuery: query);
    final processedState = _processAllFilters(updatedState, mods);

    state = processedState;
  }

  /// Toggle show enabled filter
  void toggleShowEnabled() {
    final mods = ref.read(AppState.mods);
    final updatedState = state.copyWith(showEnabled: !state.showEnabled);
    final processedState = _processAllFilters(updatedState, mods);

    state = processedState;
  }

  /// Toggle show hidden weapons filter
  void toggleShowHidden() {
    final mods = ref.read(AppState.mods);
    final updatedState = state.copyWith(showHidden: !state.showHidden);
    final processedState = _processAllFilters(updatedState, mods);

    state = processedState;
  }

  /// Set spoiler level for weapons
  void setWeaponSpoilerLevel(WeaponSpoilerLevel level) {
    final mods = ref.read(AppState.mods);
    final updatedState = state.copyWith(weaponSpoilerLevel: level);
    final processedState = _processAllFilters(updatedState, mods);

    state = processedState;
  }

  /// Toggle split pane view
  void toggleSplitPane() {
    final updatedState = state.copyWith(splitPane: !state.splitPane);
    state = updatedState;
  }

  /// Toggle filters panel visibility
  void toggleShowFilters() {
    final updatedState = state.copyWith(showFilters: !state.showFilters);
    state = updatedState;
  }

  /// Get game core directory
  Directory getGameCoreDir() {
    return Directory(
      ref.read(appSettings.select((s) => s.gameCoreDir))?.path ?? '',
    );
  }

  /// Clear all active filters
  void clearAllFilters() {
    final mods = ref.read(AppState.mods);

    // Clear all filter states
    for (final filter in state.filterCategories) {
      filter.filterStates.clear();
    }

    // Create new state with cleared filters
    final updatedState = state.copyWith(
      filterCategories: List.from(state.filterCategories),
    );
    final processedState = _processAllFilters(updatedState, mods);

    state = processedState;
  }

  /// Update filter states for a specific filter
  void updateFilterStates(GridFilter filter, Map<String, bool?> states) {
    final mods = ref.read(AppState.mods);

    filter.filterStates.clear();
    filter.filterStates.addAll(states);

    // Create new state with updated filters
    final updatedState = state.copyWith(
      filterCategories: List.from(state.filterCategories),
    );
    final processedState = _processAllFilters(updatedState, mods);

    state = processedState;
  }

  /// Filter weapons based on enabled status
  List<Weapon> _filterByEnabled(
    List<Weapon> weapons,
    List<Mod> mods,
    bool showEnabled,
  ) {
    if (!showEnabled) return weapons;

    return weapons.where((weapon) {
      return weapon.modVariant == null ||
          weapon.modVariant?.mod(mods)?.hasEnabledVariant == true;
    }).toList();
  }

  /// Filter weapons based on hidden status
  List<Weapon> _filterByHidden(List<Weapon> weapons, bool showHidden) {
    if (showHidden) return weapons;

    return weapons
        .where((weapon) => weapon.weaponType?.toLowerCase() != "decorative")
        .where(
          (weapon) =>
              // If weapon has SYSTEM hint, hide unless SHOW_IN_CODEX tag is present
              !weapon.hintsAsSet.contains("system") ||
              weapon.tagsAsSet.contains("show_in_codex"),
        )
        .toList();
  }

  /// Filter weapons by spoiler level (hide codex_unlockable when No spoilers)
  List<Weapon> _filterByWeaponSpoilers(
    List<Weapon> weapons,
    WeaponSpoilerLevel level,
  ) {
    if (level == WeaponSpoilerLevel.showAllSpoilers) return weapons;

    return weapons.where((weapon) {
      final tags =
          weapon.tags?.split(',').map((t) => t.trim().toLowerCase()) ?? [];
      final isCodexUnlockable = tags.contains('codex_unlockable');
      return !isCodexUnlockable;
    }).toList();
  }

  /// Apply grid filters to weapons
  List<Weapon> _applyFilters(
    List<Weapon> weapons,
    List<GridFilter<Weapon>> filterCategories,
  ) {
    for (final filter in filterCategories) {
      if (filter.hasActiveFilters) {
        weapons = weapons.where((weapon) {
          final value = filter.valueGetter(weapon);
          final filterState = filter.filterStates[value];

          // If this value is explicitly excluded
          if (filterState == false) {
            return false;
          }

          // If there are any explicitly included values
          final hasIncludedValues = filter.filterStates.values.contains(true);
          if (hasIncludedValues) {
            // Must be explicitly included to pass the filter
            return filterState == true;
          }

          // If we have only exclusions, allow anything not explicitly excluded
          return true;
        }).toList();
      }
    }
    return weapons;
  }

  /// Filter weapons by search query
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
