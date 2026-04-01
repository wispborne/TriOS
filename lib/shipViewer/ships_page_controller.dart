import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/shipSystemsManager/ship_system.dart';
import 'package:trios/shipSystemsManager/ship_systems_manager.dart';
import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/shipViewer/ship_manager.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/weaponViewer/models/weapon.dart';
import 'package:trios/weaponViewer/weapons_manager.dart';
import 'package:trios/widgets/filter_widget.dart';

part 'ships_page_controller.mapper.dart';

/// State class for the ships page controller
@MappableClass()
class ShipsPageState with ShipsPageStateMappable {
  final ShipsPageStatePersisted persisted;

  final List<GridFilter<Ship>> filterCategories;

  /// Ship properties, lowercase, by ship id.
  final Map<String, List<String>> shipSearchIndices;
  final Map<String, ShipSystem> shipSystemsMap;
  final Map<String, Weapon> weaponsMap;
  final List<Ship> allShips;
  final List<Ship> filteredShips;
  final List<Ship> shipsBeforeGridFilter;
  final String currentSearchQuery;
  final bool isLoading;

  // Backward-compatible passthroughs (API unchanged)
  bool get showEnabled => persisted.showEnabled;

  SpoilerLevel get spoilerLevelToShow => persisted.spoilerLevelToShow;

  bool get splitPane => persisted.splitPane;

  bool get showFilters => persisted.showFilters;

  bool get useContainFit => persisted.useContainFit;

  const ShipsPageState({
    this.persisted = const ShipsPageStatePersisted(),
    this.filterCategories = const [],
    this.shipSearchIndices = const {},
    this.shipSystemsMap = const {},
    this.weaponsMap = const {},
    this.allShips = const [],
    this.filteredShips = const [],
    this.shipsBeforeGridFilter = const [],
    this.currentSearchQuery = '',
    this.isLoading = false,
  });

  /// Returns the display name for a ship by its ID, or the ID itself if not found.
  String hullNameById(String id) =>
      allShips.where((s) => s.id == id).firstOrNull?.hullNameForDisplay() ?? id;
}

@MappableClass()
class ShipsPageStatePersisted with ShipsPageStatePersistedMappable {
  final bool showEnabled;
  final SpoilerLevel spoilerLevelToShow;
  final bool splitPane;
  final bool showFilters;
  final bool useContainFit;

  const ShipsPageStatePersisted({
    this.showEnabled = false,
    this.spoilerLevelToShow = SpoilerLevel.showNone,
    this.splitPane = false,
    this.showFilters = false,
    this.useContainFit = false,
  });
}

@MappableEnum()
enum SpoilerLevel { showNone, showSlightSpoilers, showAllSpoilers }

/// Controller for the ships page using Notifier (synchronous)
class ShipsPageController extends Notifier<ShipsPageState> {
  final slightSpoilerTags = ["codex_unlockable"];
  final spoilerTags = ["threat", "dweller"];
  final vanillaName = 'Vanilla';

  @override
  ShipsPageState build() {
    // Try restore saved state from Settings
    final saved = ref.read(appSettings).shipsPageState;

    // Initialize filter categories
    final filterCategories = [
      GridFilter<Ship>(
        name: 'Type',
        valueGetter: (ship) => ship.isSkin ? 'Skin' : 'Base Hull',
        valuesGetter: (ship) => [
          ship.isSkin ? 'Skin' : 'Base Hull',
          if (ship.hasStationSlots) 'Has Modules',
        ],
      ),
      GridFilter<Ship>(
        name: 'Hull Size',
        valueGetter: (ship) => ship.hullSizeForDisplay(),
        useDefaultSort: true, // Sorts by hull size by default
      ),
      GridFilter<Ship>(
        name: 'Weapon Slot Type',
        valueGetter: (ship) => '',
        valuesGetter: (ship) =>
            ship.weaponSlots
                ?.where((s) => s.isMountable)
                .map((s) => s.type.toUpperCase())
                .toSet()
                .toList() ??
            [],
        displayNameGetter: (value) => value.toTitleCase(),
      ),
      GridFilter<Ship>(
        name: 'Weapon Size',
        valueGetter: (ship) => '',
        valuesGetter: (ship) =>
            ship.weaponSlots
                ?.where((s) => s.isMountable)
                .map((s) => s.size.toUpperCase())
                .toSet()
                .toList() ??
            [],
        displayNameGetter: (value) => value.toTitleCase(),
        sortComparator: (a, b) {
          const order = ['SMALL', 'MEDIUM', 'LARGE'];
          return order.indexOf(a).compareTo(order.indexOf(b));
        },
      ),
      GridFilter<Ship>(
        name: 'Mount Type',
        valueGetter: (ship) => '',
        valuesGetter: (ship) =>
            ship.weaponSlots
                ?.where((s) => s.isMountable)
                .map((s) => s.mount.toUpperCase())
                .toSet()
                .toList() ??
            [],
        displayNameGetter: (value) => value.toTitleCase(),
      ),
      GridFilter<Ship>(
        name: 'Shield Type',
        valueGetter: (ship) => ship.shieldType ?? '',
        displayNameGetter: (value) => value.toTitleCase(),
      ),
      GridFilter<Ship>(
        name: 'Mod',
        collapsedByDefault: true,
        valueGetter: (ship) {
          return ship.modVariant?.modInfo.nameOrId ?? vanillaName;
        },
        sortComparator: (a, b) => a == vanillaName
            ? -1
            : b == vanillaName
            ? 1
            : a.compareTo(b),
      ),
      GridFilter<Ship>(
        name: 'System',
        collapsedByDefault: true,
        valueGetter: (ship) => ship.systemId ?? '',
        displayNameGetter: (value) =>
        state.shipSystemsMap[value ?? ""]?.name ?? value,
      ),
      GridFilter<Ship>(
        name: 'Defense Id',
        collapsedByDefault: true,
        valueGetter: (ship) => ship.defenseId ?? '',
        displayNameGetter: (value) =>
        state.shipSystemsMap[value ?? ""]?.name ?? value,
      ),
      GridFilter<Ship>(
        name: 'Tech/Manufacturer',
        collapsedByDefault: true,
        valueGetter: (ship) => ship.techManufacturer ?? '',
      ),
      GridFilter<Ship>(
        name: 'Designation',
        collapsedByDefault: true,
        valueGetter: (ship) => ship.designation ?? '',
      ),
    ];

    // Watch ship data, ship systems, and weapons
    final shipsAsync = ref.watch(shipListNotifierProvider);
    final shipSystemsAsync = ref.watch(shipSystemsStreamProvider);
    final mods = ref.watch(AppState.mods);
    final isLoadingShips = ref.watch(isLoadingShipsList);

    final allShips = shipsAsync.value ?? [];
    final shipSystems = shipSystemsAsync.value ?? [];
    final shipSystemsMap = shipSystems.associateBy((e) => e.id);

    // TODO for 1.3.x
    if (false) {
      final weaponsAsync = ref.watch(weaponListNotifierProvider);
      final weapons = weaponsAsync.value ?? [];
      final weaponsMap = weapons.associateBy((e) => e.id);
    }

    // Build search index from current ships (incremental update)
    Map<String, List<String>> shipSearchIndices = _updateSearchIndices(
      allShips,
    );

    // Build initial state (prefer saved state when available)
    final initialState =
        (stateOrNull ??
                ShipsPageState(
                  persisted: ShipsPageStatePersisted(
                    showEnabled: saved?.showEnabled ?? false,
                    spoilerLevelToShow:
                        saved?.spoilerLevelToShow ?? SpoilerLevel.showNone,
                    splitPane: saved?.splitPane ?? false,
                    showFilters: saved?.showFilters ?? false,
                    useContainFit: saved?.useContainFit ?? false,
                  ),
                ))
            .copyWith(
              filterCategories:
                  stateOrNull?.filterCategories ?? filterCategories,
              shipSystemsMap: shipSystemsMap,
              // weaponsMap: weaponsMap,
              weaponsMap: {},
              allShips: allShips,
              shipSearchIndices: shipSearchIndices,
              isLoading: isLoadingShips,
            );

    // Process filters to get final ship lists
    final processedState = _processAllFilters(initialState, mods);

    return processedState;
  }

  void _persistState(ShipsPageState newState) {
    try {
      ref
          .read(appSettings.notifier)
          .update(
            (s) => s.copyWith(
              shipsPageState: (s.shipsPageState ?? ShipsPageStatePersisted())
                  .copyWith(
                    showEnabled: newState.showEnabled,
                    spoilerLevelToShow: newState.spoilerLevelToShow,
                    splitPane: newState.splitPane,
                    showFilters: newState.showFilters,
                    useContainFit: newState.useContainFit,
                  ),
            ),
          );
    } catch (e, stackTrace) {
      Fimber.w(
        "Failed to persist ships page state",
        ex: e,
        stacktrace: stackTrace,
      );
    }
  }

  Map<String, List<String>> _updateSearchIndices(List<Ship> allShips) {
    // Build search index from current ships (incremental update)
    final currentIndices = stateOrNull?.shipSearchIndices ?? {};
    final currentShipIds = allShips.map((ship) => ship.id).toSet();
    final cachedShipIds = currentIndices.keys.toSet();

    // Remove indices for ships that are no longer present
    final indicesToRemove = cachedShipIds.difference(currentShipIds);
    final shipValuesByShipId = Map<String, List<String>>.from(currentIndices);
    for (final shipId in indicesToRemove) {
      shipValuesByShipId.remove(shipId);
    }

    // Add indices only for new ships that don't already have them
    final newShips = allShips.where((ship) => !cachedShipIds.contains(ship.id));
    for (final ship in newShips) {
      final searchValues = ship
          .toMap()
          .values
          .map((shipField) => shipField.toString().toLowerCase())
          .toList();
      shipValuesByShipId[ship.id] = searchValues;
    }
    return shipValuesByShipId;
  }

  /// Process all filters and return updated state
  ShipsPageState _processAllFilters(
    ShipsPageState currentState,
    List<Mod> mods,
  ) {
    var ships = currentState.allShips.toList();

    // Apply enabled filter
    ships = _filterByEnabled(ships, mods, currentState.showEnabled);

    // Apply spoiler filter
    ships = _filterBySpoilers(ships, currentState.spoilerLevelToShow);

    // Store ships before grid filters for filter panel
    final shipsBeforeGridFilter = ships.toList();

    // Apply grid filters
    ships = _applyFilters(ships, currentState.filterCategories);

    // Apply search filter
    ships = _filterBySearch(
      ships,
      currentState.currentSearchQuery,
      currentState.shipSearchIndices,
    );

    return currentState.copyWith(
      filteredShips: ships,
      shipsBeforeGridFilter: shipsBeforeGridFilter,
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
    final updatedState = state.copyWith(
      persisted: state.persisted.copyWith(showEnabled: !state.showEnabled),
    );
    final processedState = _processAllFilters(updatedState, mods);

    _persistState(processedState);
    state = processedState;
  }

  /// Toggle show spoilers filter
  void setShowSpoilers(SpoilerLevel spoilerLevelToShow) {
    final mods = ref.read(AppState.mods);
    final updatedState = state.copyWith(
      persisted: state.persisted.copyWith(
        spoilerLevelToShow: spoilerLevelToShow,
      ),
    );
    final processedState = _processAllFilters(updatedState, mods);

    state = processedState;
    _persistState(state);
  }

  /// Toggle split pane view
  void toggleSplitPane() {
    final updatedState = state.copyWith(
      persisted: state.persisted.copyWith(splitPane: !state.splitPane),
    );
    state = updatedState;
    _persistState(state);
  }

  /// Toggle filters panel visibility
  void toggleShowFilters() {
    final updatedState = state.copyWith(
      persisted: state.persisted.copyWith(showFilters: !state.showFilters),
    );
    state = updatedState;
    _persistState(state);
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
      (state.spoilerLevelToShow != SpoilerLevel.showAllSpoilers ? 1 : 0);

  /// Get game core directory
  Directory getGameCoreDir() {
    return Directory(ref.read(AppState.gameCoreFolder).value?.path ?? '');
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

  /// Filter ships based on enabled status
  List<Ship> _filterByEnabled(
    List<Ship> ships,
    List<Mod> mods,
    bool showEnabled,
  ) {
    if (!showEnabled) return ships;

    return ships.where((ship) {
      return ship.modVariant == null ||
          ship.modVariant?.mod(mods)?.hasEnabledVariant == true;
    }).toList();
  }

  /// Filter ships based on spoiler settings
  List<Ship> _filterBySpoilers(
    List<Ship> ships,
    SpoilerLevel spoilerLevelToShow,
  ) {
    if (spoilerLevelToShow == SpoilerLevel.showAllSpoilers) return ships;

    return ships.where((ship) {
      final hints = ship.hints.orEmpty().map((h) => h.toLowerCase());
      final tags = ship.tags.orEmpty().map((t) => t.toLowerCase());

      final hidden = hints.contains('hide_in_codex');
      final isSlightSpoiler = tags.any(slightSpoilerTags.contains);
      final isSpoiler = tags.any(spoilerTags.contains);

      if (spoilerLevelToShow == SpoilerLevel.showSlightSpoilers) {
        return !hidden && !isSpoiler;
      }

      // Show no spoilers
      return !hidden && !isSlightSpoiler && !isSpoiler;
    }).toList();
  }

  /// Apply grid filters to ships
  List<Ship> _applyFilters(
    List<Ship> ships,
    List<GridFilter<Ship>> filterCategories,
  ) {
    for (final filter in filterCategories) {
      if (filter.hasActiveFilters) {
        ships = ships.where((ship) {
          final values = filter.valuesGetter != null
              ? filter.valuesGetter!(ship)
              : [filter.valueGetter(ship)];

          // If any value is explicitly excluded, exclude the item
          if (values.any((v) => filter.filterStates[v] == false)) {
            return false;
          }

          // If there are any explicitly included values
          final hasIncludedValues = filter.filterStates.values.contains(true);
          if (hasIncludedValues) {
            // Must have at least one included value
            return values.any((v) => filter.filterStates[v] == true);
          }

          // Only exclusions active — allow anything not excluded
          return true;
        }).toList();
      }
    }
    return ships;
  }

  /// Filter ships by search query
  List<Ship> _filterBySearch(
    List<Ship> ships,
    String query,
    Map<String, List<String>> shipValuesByShipId,
  ) {
    if (query.isEmpty) return ships;

    query = query.toLowerCase();

    return ships.where((ship) {
      return shipValuesByShipId[ship.id]?.any(
            (value) => value.contains(query),
          ) ??
          false;
    }).toList();
  }
}

/// Provider for the ships page controller
final shipsPageControllerProvider =
    NotifierProvider<ShipsPageController, ShipsPageState>(() {
      return ShipsPageController();
    });
