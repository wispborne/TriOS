import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/ship_systems_manager/ship_systems_manager.dart';
import 'package:trios/ship_viewer/models/ship_gpt.dart';
import 'package:trios/ship_viewer/models/ship_variant.dart';
import 'package:trios/ship_viewer/ship_manager.dart';
import 'package:trios/ship_viewer/ship_module_resolver.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/hullmod_viewer/hullmods_manager.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/weapons_manager.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';

part 'ships_page_controller.mapper.dart';

/// Stable page identifier for persistence keying.
const String kShipsPageId = 'ships';

/// State class for the ships page controller
@MappableClass()
class ShipsPageState with ShipsPageStateMappable {
  final ShipsPageStatePersisted persisted;

  /// Ship properties, lowercase, by ship id.
  final Map<String, List<String>> shipSearchIndices;
  final Map<String, ShipSystem> shipSystemsMap;
  final Map<String, Weapon> weaponsMap;
  final Map<String, Hullmod> hullmodsMap;
  final Set<String> shipsWithModuleIds;
  final List<Ship> allShips;
  final List<Ship> filteredShips;
  final List<Ship> shipsBeforeGridFilter;
  final String currentSearchQuery;
  final bool isLoading;

  bool get splitPane => persisted.splitPane;

  bool get showFilters => persisted.showFilters;

  bool get useContainFit => persisted.useContainFit;

  const ShipsPageState({
    this.persisted = const ShipsPageStatePersisted(),
    this.shipSearchIndices = const {},
    this.shipSystemsMap = const {},
    this.weaponsMap = const {},
    this.hullmodsMap = const {},
    this.shipsWithModuleIds = const {},
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
  final bool splitPane;
  final bool showFilters;
  final bool useContainFit;

  const ShipsPageStatePersisted({
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

  static final _scope = const FilterScope(kShipsPageId);

  late final FilterScopeController<Ship> _filters;

  // Memoization for shipsWithModuleIds, keyed by input identity so we skip
  // the O(N²) recompute on rebuilds where ship/variant references haven't
  // actually changed (e.g. an unrelated watched provider ticked).
  List<Ship>? _lastShips;
  Map<String, ShipVariant>? _lastModuleVariants;
  Map<String, String>? _lastVariantHullIdMap;
  Set<String>? _cachedShipsWithModuleIds;

  FilterScope get scope => _scope;

  List<FilterGroup<Ship>> get filterGroups => _filters.groups;

  /// Find the composite general group (showEnabled + spoiler).
  CompositeFilterGroup<Ship> get _general =>
      _filters.findGroup('general') as CompositeFilterGroup<Ship>;

  BoolField<Ship> get _showEnabledField =>
      _general.fieldById('showEnabled') as BoolField<Ship>;

  EnumField<Ship, SpoilerLevel> get _spoilerField =>
      _general.fieldById('spoiler') as EnumField<Ship, SpoilerLevel>;

  bool get showEnabled => _showEnabledField.value;

  SpoilerLevel get spoilerLevelToShow => _spoilerField.selected;

  /// Returns `shipsWithModuleIds`, recomputing only if any of the three
  /// inputs has a different identity than the last call. Riverpod's
  /// providers return the same list/map instance until the underlying data
  /// actually changes, so `identical` is the right equality here.
  Set<String> _computeShipsWithModuleIdsMemo(
    List<Ship> allShips,
    Map<String, ShipVariant> moduleVariants,
    Map<String, String> variantHullIdMap,
  ) {
    final cached = _cachedShipsWithModuleIds;
    if (cached != null &&
        identical(_lastShips, allShips) &&
        identical(_lastModuleVariants, moduleVariants) &&
        identical(_lastVariantHullIdMap, variantHullIdMap)) {
      return cached;
    }

    final result = computeShipsWithModuleIds(
      allShips,
      moduleVariants,
      variantHullIdMap,
    );
    _lastShips = allShips;
    _lastModuleVariants = moduleVariants;
    _lastVariantHullIdMap = variantHullIdMap;
    _cachedShipsWithModuleIds = result;
    return result;
  }

  @override
  ShipsPageState build() {
    // Watch ship data, ship systems, weapons, and descriptions.
    ref.watch(descriptionsNotifierProvider);
    final shipsAsync = ref.watch(shipListNotifierProvider);
    final shipSystemsAsync = ref.watch(shipSystemsStreamProvider);
    final mods = ref.watch(AppState.mods);
    final isLoadingShips = ref.watch(isLoadingShipsList);

    final hullmodsAsync = ref.watch(hullmodListNotifierProvider);

    final allShips = shipsAsync.value ?? [];
    final moduleVariants = ref.watch(moduleVariantsProvider);
    final variantHullIdMap = ref.watch(variantHullIdMapProvider);
    final shipSystems = shipSystemsAsync.value ?? [];
    final shipSystemsMap = shipSystems.associateBy((e) => e.id);
    final hullmodsMap = (hullmodsAsync.value ?? []).associateBy((e) => e.id);

    final weaponsAsync = ref.watch(weaponListNotifierProvider);
    final weapons = weaponsAsync.value ?? [];
    final weaponsMap = weapons.associateBy((e) => e.id);

    final shipsWithModuleIds = _computeShipsWithModuleIdsMemo(
      allShips,
      moduleVariants,
      variantHullIdMap,
    );

    // Build filter scope controller only once; reuse the same groups across
    // rebuilds so live filter state persists across them.
    if (stateOrNull == null) {
      _filters = _buildFilters();
      final persistence = ref.read(filterGroupPersistenceProvider);
      _filters.loadPersisted(persistence);
    }

    // Apply staged chip selections against the current data.
    _filters.applyPendingChipMerge(allShips);

    // Initialize saved settings (non-filter UI).
    final saved = ref.read(appSettings).shipsPageState;

    Map<String, List<String>> shipSearchIndices = _updateSearchIndices(
      allShips,
    );

    final initialState =
        (stateOrNull ??
                ShipsPageState(
                  persisted: ShipsPageStatePersisted(
                    splitPane: saved?.splitPane ?? false,
                    showFilters: saved?.showFilters ?? false,
                    useContainFit: saved?.useContainFit ?? false,
                  ),
                ))
            .copyWith(
              shipSystemsMap: shipSystemsMap,
              weaponsMap: weaponsMap,
              hullmodsMap: hullmodsMap,
              shipsWithModuleIds: shipsWithModuleIds,
              allShips: allShips,
              shipSearchIndices: shipSearchIndices,
              isLoading: isLoadingShips,
            );

    return _processAllFilters(initialState, mods);
  }

  FilterScopeController<Ship> _buildFilters() {
    final groups = <FilterGroup<Ship>>[
      CompositeFilterGroup<Ship>(
        id: 'general',
        name: 'General',
        fields: [
          BoolField<Ship>(
            id: 'showEnabled',
            label: 'Only Enabled Mods',
            tooltip: 'Only show ships from enabled mods.',
            predicate: (ship) {
              final mods = ref.read(AppState.mods);
              return ship.modVariant == null ||
                  ship.modVariant?.mod(mods)?.hasEnabledVariant == true;
            },
          ),
          EnumField<Ship, SpoilerLevel>(
            id: 'spoiler',
            label: 'Spoilers',
            defaultValue: SpoilerLevel.showNone,
            options: SpoilerLevel.values,
            predicate: _spoilerMatches,
            optionLabel: _spoilerLabel,
            optionTooltip: _spoilerTooltip,
            optionIcon: (e) => switch (e) {
              SpoilerLevel.showNone => Icons.visibility_off,
              SpoilerLevel.showSlightSpoilers => Icons.visibility,
              SpoilerLevel.showAllSpoilers => Icons.visibility_outlined,
            },
          ),
        ],
      ),
      ChipFilterGroup<Ship>(
        id: 'type',
        name: 'Type',
        valueGetter: (ship) => ship.isSkin ? 'Skin' : 'Base Hull',
        valuesGetter: (ship) => [
          ship.isSkin ? 'Skin' : 'Base Hull',
          if (stateOrNull?.shipsWithModuleIds.contains(ship.id) ?? false)
            'Has Modules',
        ],
      ),
      ChipFilterGroup<Ship>(
        id: 'hullSize',
        name: 'Hull Size',
        valueGetter: (ship) =>
            ship.isStation ? 'Station' : ship.hullSizeForDisplay(),
        useDefaultSort: true,
      ),
      ChipFilterGroup<Ship>(
        id: 'weaponSlotType',
        name: 'Weapon Slot Type',
        valueGetter: (ship) => '',
        valuesGetter: (ship) =>
            ship.weaponSlots
                ?.where((s) => s.isMountable)
                .map((s) => s.typeUppercase)
                .toSet()
                .toList() ??
            [],
        displayNameGetter: (value) => value.toTitleCase(),
      ),
      ChipFilterGroup<Ship>(
        id: 'weaponSize',
        name: 'Weapon Size',
        valueGetter: (ship) => '',
        valuesGetter: (ship) =>
            ship.weaponSlots
                ?.where((s) => s.isMountable)
                .map((s) => s.sizeUppercase)
                .toSet()
                .toList() ??
            [],
        displayNameGetter: (value) => value.toTitleCase(),
        sortComparator: (a, b) {
          const order = ['SMALL', 'MEDIUM', 'LARGE'];
          return order.indexOf(a).compareTo(order.indexOf(b));
        },
      ),
      ChipFilterGroup<Ship>(
        id: 'mountType',
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
      ChipFilterGroup<Ship>(
        id: 'shieldType',
        name: 'Shield Type',
        valueGetter: (ship) => ship.shieldType ?? '',
        displayNameGetter: (value) => value.toTitleCase(),
      ),
      ChipFilterGroup<Ship>(
        id: 'mod',
        name: 'Mod',
        collapsedByDefault: true,
        valueGetter: (ship) => ship.modVariant?.modInfo.nameOrId ?? vanillaName,
        sortComparator: (a, b) => a == vanillaName
            ? -1
            : b == vanillaName
            ? 1
            : a.compareTo(b),
      ),
      ChipFilterGroup<Ship>(
        id: 'system',
        name: 'System',
        collapsedByDefault: true,
        valueGetter: (ship) => ship.systemId ?? '',
        displayNameGetter: (value) =>
            stateOrNull?.shipSystemsMap[value]?.name ?? value,
      ),
      ChipFilterGroup<Ship>(
        id: 'defenseId',
        name: 'Defense Id',
        collapsedByDefault: true,
        valueGetter: (ship) => ship.defenseId ?? '',
        displayNameGetter: (value) =>
            stateOrNull?.shipSystemsMap[value]?.name ?? value,
      ),
      ChipFilterGroup<Ship>(
        id: 'techManufacturer',
        name: 'Tech/Manufacturer',
        collapsedByDefault: true,
        valueGetter: (ship) => ship.techManufacturer ?? '',
      ),
      ChipFilterGroup<Ship>(
        id: 'designation',
        name: 'Designation',
        collapsedByDefault: true,
        valueGetter: (ship) => ship.designation ?? '',
      ),
    ];
    return FilterScopeController<Ship>(scope: _scope, groups: groups);
  }

  bool _spoilerMatches(Ship ship, SpoilerLevel level) {
    if (level == SpoilerLevel.showAllSpoilers) return true;
    final hints = ship.hints.orEmpty().map((h) => h.toLowerCase());
    final tags = ship.tags.orEmpty().map((t) => t.toLowerCase());
    final hidden = hints.contains('hide_in_codex');
    final isSlightSpoiler = tags.any(slightSpoilerTags.contains);
    final isSpoiler = tags.any(spoilerTags.contains);
    if (level == SpoilerLevel.showSlightSpoilers) {
      return !hidden && !isSpoiler;
    }
    return !hidden && !isSlightSpoiler && !isSpoiler;
  }

  String _spoilerLabel(SpoilerLevel e) => switch (e) {
    SpoilerLevel.showNone => 'No Spoilers',
    SpoilerLevel.showSlightSpoilers => 'Show slight spoilers',
    SpoilerLevel.showAllSpoilers => 'Show all spoilers',
  };

  String _spoilerTooltip(SpoilerLevel e) => switch (e) {
    SpoilerLevel.showNone => 'No spoilers shown at all.',
    SpoilerLevel.showSlightSpoilers => 'Shows CODEX_UNLOCKABLE ships.',
    SpoilerLevel.showAllSpoilers =>
      'Show all spoilers, including HIDE_IN_CODEX and certain ultra-redacted vanilla tagged ships',
  };

  void _persistState(ShipsPageState newState) {
    try {
      ref
          .read(appSettings.notifier)
          .update(
            (s) => s.copyWith(
              shipsPageState: (s.shipsPageState ?? ShipsPageStatePersisted())
                  .copyWith(
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
    final currentIndices = stateOrNull?.shipSearchIndices ?? {};
    final currentShipIds = allShips.map((ship) => ship.id).toSet();
    final cachedShipIds = currentIndices.keys.toSet();

    final indicesToRemove = cachedShipIds.difference(currentShipIds);
    final shipValuesByShipId = Map<String, List<String>>.from(currentIndices);
    for (final shipId in indicesToRemove) {
      shipValuesByShipId.remove(shipId);
    }

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

  ShipsPageState _processAllFilters(
    ShipsPageState currentState,
    List<Mod> mods,
  ) {
    var ships = _filters.applyNonChipFilters(currentState.allShips);

    final shipsBeforeGridFilter = ships.toList();

    ships = _filters.applyChipFilters(ships);

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

  void setShowSpoilers(SpoilerLevel spoilerLevelToShow) {
    _spoilerField.setSelected(spoilerLevelToShow);
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

  /// Called after a user mutates a filter group's state via the renderer.
  void onGroupChanged(String groupId) {
    _emitAfterFilterMutation();
    _filters.maybePersist(groupId, ref.read(filterGroupPersistenceProvider));
  }

  /// Replace chip selections on a named group (context-menu navigation).
  void setChipSelections(String groupId, Map<String, bool?> selections) {
    _filters.setChipSelections(groupId, selections);
    _emitAfterFilterMutation();
  }

  void _emitAfterFilterMutation() {
    final mods = ref.read(AppState.mods);
    state = _processAllFilters(state, mods);
  }

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

final shipsPageControllerProvider =
    NotifierProvider<ShipsPageController, ShipsPageState>(() {
      return ShipsPageController();
    });
