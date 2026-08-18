import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/utils/notify_on_new_state.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/ship_systems_manager/ship_systems_manager.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/models/ship_variant.dart';
import 'package:trios/ship_viewer/ship_manager.dart';
import 'package:trios/ship_viewer/ship_module_resolver.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/search_index.dart';
import 'package:trios/widgets/smart_search/search_dsl_field.dart';
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

  /// Ships that are used as a module on some other ship.
  final Set<String> moduleShipIds;
  final List<Ship> allShips;
  final List<Ship> filteredShips;
  final List<Ship> shipsBeforeGridFilter;
  final String currentSearchQuery;
  final bool isLoading;

  bool get splitPane => persisted.splitPane;

  bool get showFilters => persisted.showFilters;

  bool get useContainFit => persisted.useContainFit;

  bool get alwaysShowEngineGlow => persisted.alwaysShowEngineGlow;

  bool get advancedFilters => persisted.advancedFilters;

  const ShipsPageState({
    this.persisted = const ShipsPageStatePersisted(),
    this.shipSearchIndices = const {},
    this.shipSystemsMap = const {},
    this.weaponsMap = const {},
    this.hullmodsMap = const {},
    this.shipsWithModuleIds = const {},
    this.moduleShipIds = const {},
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
  final bool alwaysShowEngineGlow;

  /// Advanced filters: number sliders, and an "any" / "all" choice per group.
  final bool advancedFilters;

  const ShipsPageStatePersisted({
    this.splitPane = false,
    this.showFilters = false,
    this.useContainFit = false,
    this.alwaysShowEngineGlow = false,
    this.advancedFilters = false,
  });
}

@MappableEnum()
enum SpoilerLevel { showNone, showSlightSpoilers, showAllSpoilers }

const _slightSpoilerTags = ["codex_unlockable"];
const _spoilerTags = ["threat", "dweller"];

/// Whether [ship] should be shown at the given spoiler [level].
/// Shared by the ships page and the faction profile dialog.
bool shipMatchesSpoilerLevel(Ship ship, SpoilerLevel level) {
  if (level == SpoilerLevel.showAllSpoilers) return true;
  return tagsMatchShipSpoilerLevel(
    ship.tags.orEmpty(),
    level,
    hidden: ship.hints.orEmpty().any((h) => h.toLowerCase() == 'hide_in_codex'),
  );
}

/// The tag-list core of [shipMatchesSpoilerLevel], so entries without a full
/// [Ship] (a wing with no resolved ship, a ship system) can apply the same
/// spoiler rules to their own tags column. [hidden] forces hiding regardless
/// of level (the ship version passes `hide_in_codex`).
///
/// Single pass over the tags: the codex runs this for every entry on every
/// data refresh while mods load, so it should not allocate iterable chains.
bool tagsMatchShipSpoilerLevel(
  Iterable<String> tags,
  SpoilerLevel level, {
  bool hidden = false,
}) {
  if (level == SpoilerLevel.showAllSpoilers) return true;
  if (hidden) return false;
  var isSlightSpoiler = false;
  for (final tag in tags) {
    final lower = tag.toLowerCase();
    // A full spoiler hides the entry at both remaining levels.
    if (_spoilerTags.contains(lower)) return false;
    if (_slightSpoilerTags.contains(lower)) isSlightSpoiler = true;
  }
  return level == SpoilerLevel.showSlightSpoilers || !isSlightSpoiler;
}

/// Controller for the ships page using Notifier (synchronous)
class ShipsPageController extends Notifier<ShipsPageState>
    with NotifyOnNewState {
  final vanillaName = 'Vanilla';

  static final _scope = const FilterScope(kShipsPageId);

  late final FilterScopeController<Ship> _filters;
  late final List<SearchField<Ship>> _searchFields;
  late final Map<String, SearchField<Ship>> _fieldsByKey;

  List<SearchFieldMeta> get searchFieldsMeta =>
      _searchFields.map((f) => f.toMeta(state.allShips)).toList();

  List<Ship>? _searchIndexItems;

  /// Hullmods by id, so the `hullmod:` search field can match built-in
  /// hullmods by their display name. Kept here rather than read from `state`
  /// because searching also runs during `build()`, before state is set.
  Map<String, Hullmod> _hullmodsById = const {};

  // Memoization for shipsWithModuleIds, keyed by input identity so we skip
  // the O(N²) recompute on rebuilds where ship/variant references haven't
  // actually changed (e.g. an unrelated watched provider ticked).
  List<Ship>? _lastShips;
  Map<String, ShipVariant>? _lastModuleVariants;
  Map<String, String>? _lastVariantHullIdMap;
  Set<String>? _cachedShipsWithModuleIds;

  // Maps an upper-cased tech/manufacturer to the most common original spelling,
  // used to label the case-insensitive Tech/Manufacturer filter chips. Cached
  // by ship-list identity so it only rebuilds when the ship list changes.
  List<Ship>? _techLabelShips;
  Map<String, String> _techLabelsByUpper = const {};

  FilterScope get scope => _scope;

  List<FilterGroup<Ship>> get filterGroups => _filters.groups;

  /// Find the composite general group (showEnabled + spoiler).
  CompositeFilterGroup<Ship> get _general =>
      _filters.findGroup('general') as CompositeFilterGroup<Ship>;

  BoolField<Ship> get _showEnabledField =>
      _general.fieldById('showEnabled') as BoolField<Ship>;

  EnumField<Ship, SpoilerLevel> get _spoilerField =>
      _general.fieldById('spoiler') as EnumField<Ship, SpoilerLevel>;

  BoolField<Ship> get _showModuleShipsField =>
      _general.fieldById('showModuleShips') as BoolField<Ship>;

  bool get showEnabled => ref.read(appSettings).onlyEnabledMods;

  bool get showModuleShips => _showModuleShipsField.value;

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
    // Build filter scope controller only once; reuse the same groups across
    // rebuilds so live filter state persists across them. Done first because
    // the "Only Enabled Mods" field decides which ship list to read.
    if (stateOrNull == null) {
      _filters = _buildFilters();
      _searchFields = _buildSearchFields();
      _fieldsByKey = {for (final f in _searchFields) f.key: f};
      final persistence = ref.read(filterGroupPersistenceProvider);
      _filters.loadPersisted(persistence);
    }

    // Watch ship data, ship systems, weapons, and descriptions.
    ref.watch(descriptionsNotifierProvider);
    // One app-wide switch, so flipping it anywhere rebuilds this page too.
    final onlyEnabledMods = ref.watch(onlyEnabledModsProvider);
    _showEnabledField.value = onlyEnabledMods;
    final shipsAsync = ref.watch(shipListNotifierProvider(onlyEnabledMods));
    final shipSystemsAsync = ref.watch(shipSystemListNotifierProvider);
    final mods = ref.watch(AppState.mods);
    final isLoadingShips = ref.watch(isLoadingShipsList);

    final hullmodsAsync = ref.watch(hullmodListNotifierProvider);

    final allShips = shipsAsync.value ?? [];
    final moduleVariants = ref.watch(moduleVariantsProvider);
    final variantHullIdMap = ref.watch(variantHullIdMapProvider);
    final shipSystems = shipSystemsAsync.value ?? [];
    final shipSystemsMap = shipSystems.associateBy((e) => e.id);
    final hullmodsMap = (hullmodsAsync.value ?? []).associateBy((e) => e.id);
    _hullmodsById = hullmodsMap;

    final weaponsAsync = ref.watch(weaponListNotifierProvider(onlyEnabledMods));
    final weapons = weaponsAsync.value ?? [];
    final weaponsMap = weapons.associateBy((e) => e.id);

    final shipsWithModuleIds = _computeShipsWithModuleIdsMemo(
      allShips,
      moduleVariants,
      variantHullIdMap,
    );

    // Apply staged chip selections against the current data.
    _filters.applyPendingChipMerge(allShips);

    // Initialize saved settings (non-filter UI).
    final saved = ref.read(appSettings).shipsPageState;

    final itemsChanged = !identical(allShips, _searchIndexItems);
    _searchIndexItems = allShips;
    // Module data is published after the ship list, so this often changes on a
    // later build than the ships do. The filter depends on it, so track it too.
    final moduleShipIds = computeModuleShipIds(
      moduleVariants,
      variantHullIdMap,
    );
    final moduleShipsChanged =
        stateOrNull == null ||
        !setEquals(stateOrNull!.moduleShipIds, moduleShipIds);
    // Sliders cover the whole ship list, not the filtered subset, so their
    // ends don't move as you filter.
    if (itemsChanged) _filters.updateRanges(allShips);
    final shipSearchIndices = itemsChanged
        ? _updateSearchIndices(allShips)
        : stateOrNull?.shipSearchIndices ?? _updateSearchIndices(allShips);

    final initialState =
        (stateOrNull ??
                ShipsPageState(
                  persisted: ShipsPageStatePersisted(
                    splitPane: saved?.splitPane ?? false,
                    showFilters: saved?.showFilters ?? false,
                    useContainFit: saved?.useContainFit ?? false,
                    alwaysShowEngineGlow: saved?.alwaysShowEngineGlow ?? false,
                    advancedFilters: saved?.advancedFilters ?? false,
                  ),
                ))
            .copyWith(
              shipSystemsMap: shipSystemsMap,
              weaponsMap: weaponsMap,
              hullmodsMap: hullmodsMap,
              shipsWithModuleIds: shipsWithModuleIds,
              moduleShipIds: moduleShipIds,
              allShips: allShips,
              shipSearchIndices: shipSearchIndices,
              isLoading: isLoadingShips,
            );

    if (!itemsChanged &&
        !moduleShipsChanged &&
        !showEnabled &&
        stateOrNull != null) {
      return initialState.copyWith(
        filteredShips: stateOrNull!.filteredShips,
        shipsBeforeGridFilter: stateOrNull!.shipsBeforeGridFilter,
      );
    }

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
            tooltip:
                'Only show ships from enabled mods.'
                '\nShared with the weapons, factions and codex pages.',
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
            inactiveValue: SpoilerLevel.showAllSpoilers,
          ),
          BoolField<Ship>(
            id: 'hasModules',
            label: 'Has Modules',
            tooltip: 'Only show ships that have modules.',
            predicate: (ship) =>
                stateOrNull?.shipsWithModuleIds.contains(ship.id) ?? false,
          ),
          BoolField<Ship>(
            id: 'hasBuiltInWeapons',
            label: 'Has Built-in Weapons',
            tooltip: 'Only show ships that have built-in weapons.',
            predicate: (ship) =>
                ship.builtInWeapons != null && ship.builtInWeapons!.isNotEmpty,
          ),
          BoolField<Ship>(
            id: 'showModuleShips',
            label: 'Show Ships That Are Modules',
            tooltip: 'Show ships that are used as modules on other ships.',
            // Starts off, and being off is what hides ships. The engine only
            // runs a predicate when a field is on, so the real work is in
            // [_applyShowModuleShips] — same trick as "Show Hidden Weapons".
            predicate: (_) => true,
            // A field counts as active when it differs from its default, so
            // the default is the *unfiltered* state (ticked). Off then reads as
            // an active filter, which is what it is, and clearing the filters
            // brings the module ships back.
            defaultValue: true,
            initialValue: false,
          ),
        ],
      ),
      ChipFilterGroup<Ship>(
        id: 'type',
        name: 'Type',
        valueGetter: (ship) => ship.isSkin ? 'Skin' : 'Base Hull',
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
        // Group ignoring capitalization so a mod that wrote "High tech" lands
        // in the same category as vanilla's "High Tech". The chip label uses
        // the most common original spelling (see _techManufacturerLabel).
        valueGetter: (ship) => (ship.techManufacturer ?? '').toUpperCase(),
        displayNameGetter: _techManufacturerLabel,
      ),
      ChipFilterGroup<Ship>(
        id: 'designation',
        name: 'Designation',
        collapsedByDefault: true,
        valueGetter: (ship) => ship.designation ?? '',
      ),
      // Number sliders (advanced mode only).
      RangeFilterGroup<Ship>(
        id: 'rangeDeploymentPoints',
        name: 'Deployment Points',
        valueGetter: (ship) => ship.deploymentPoints,
      ),
      RangeFilterGroup<Ship>(
        id: 'rangeSpeed',
        name: 'Max Speed',
        valueGetter: (ship) => ship.maxSpeed,
      ),
      RangeFilterGroup<Ship>(
        id: 'rangeOrdnancePoints',
        name: 'Ordnance Points',
        valueGetter: (ship) => ship.ordnancePoints,
      ),
      RangeFilterGroup<Ship>(
        id: 'rangeArmor',
        name: 'Armor',
        valueGetter: (ship) => ship.armorRating,
      ),
      RangeFilterGroup<Ship>(
        id: 'rangeHull',
        name: 'Hull',
        valueGetter: (ship) => ship.hitpoints,
      ),
      RangeFilterGroup<Ship>(
        id: 'rangeFluxDissipation',
        name: 'Flux Dissipation',
        valueGetter: (ship) => ship.fluxDissipation,
      ),
      RangeFilterGroup<Ship>(
        id: 'rangeFluxCapacity',
        name: 'Flux Capacity',
        valueGetter: (ship) => ship.maxFlux,
      ),
      RangeFilterGroup<Ship>(
        id: 'rangeMaxBurn',
        name: 'Max Burn',
        valueGetter: (ship) => ship.maxBurn,
      ),
      RangeFilterGroup<Ship>(
        id: 'rangeFuel',
        name: 'Fuel Capacity',
        valueGetter: (ship) => ship.fuel,
      ),
      RangeFilterGroup<Ship>(
        id: 'rangeCargo',
        name: 'Cargo Capacity',
        valueGetter: (ship) => ship.cargo,
      ),
      RangeFilterGroup<Ship>(
        id: 'rangeCrew',
        name: 'Crew Capacity',
        valueGetter: (ship) => ship.maxCrew,
      ),
    ];
    return FilterScopeController<Ship>(scope: _scope, groups: groups);
  }

  /// Label for a case-folded tech/manufacturer chip. Returns the most common
  /// original spelling among ships so, e.g., vanilla's "High Tech" wins over a
  /// mod's "High tech", while names like "MandalMotors" keep their own casing.
  String _techManufacturerLabel(String upper) {
    final ships = stateOrNull?.allShips ?? const <Ship>[];
    if (!identical(_techLabelShips, ships)) {
      _techLabelShips = ships;
      final counts = <String, Map<String, int>>{};
      for (final ship in ships) {
        final raw = ship.techManufacturer;
        if (raw == null || raw.isEmpty) continue;
        final bySpelling = counts[raw.toUpperCase()] ??= <String, int>{};
        bySpelling[raw] = (bySpelling[raw] ?? 0) + 1;
      }
      _techLabelsByUpper = {
        for (final entry in counts.entries)
          entry.key: entry.value.entries
              .reduce((a, b) => b.value > a.value ? b : a)
              .key,
      };
    }
    return _techLabelsByUpper[upper] ?? upper;
  }

  bool _spoilerMatches(Ship ship, SpoilerLevel level) =>
      shipMatchesSpoilerLevel(ship, level);

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
                    alwaysShowEngineGlow: newState.alwaysShowEngineGlow,
                    advancedFilters: newState.advancedFilters,
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
    return updateSearchIndices(
      allShips,
      stateOrNull?.shipSearchIndices ?? {},
      (s) => s.id,
      (s) => s.toSearchMap(),
    );
  }

  ShipsPageState _processAllFilters(
    ShipsPageState currentState,
    List<Mod> mods,
  ) {
    var ships = _filters.applyNonChipFilters(currentState.allShips);
    ships = _applyShowModuleShips(ships, currentState.moduleShipIds);

    final shipsBeforeGridFilter = ships.toList();

    ships = _filters.applyChipFilters(ships);

    ships = _applyParsedQuery(
      ships,
      currentState.currentSearchQuery,
      currentState.shipSearchIndices,
    );

    return currentState.copyWith(
      filteredShips: ships,
      shipsBeforeGridFilter: shipsBeforeGridFilter,
    );
  }

  /// Drops ships that are used as modules unless the box is ticked. The
  /// *unticked* state is the one that filters, which the composite group's
  /// plain AND can't express, so it runs here instead.
  List<Ship> _applyShowModuleShips(
    List<Ship> ships,
    Set<String> moduleShipIds,
  ) {
    if (showModuleShips || moduleShipIds.isEmpty) return ships;
    return ships.where((ship) => !moduleShipIds.contains(ship.id)).toList();
  }

  void updateSearchQuery(String query) {
    final mods = ref.read(AppState.mods);
    final updatedState = state.copyWith(currentSearchQuery: query);
    state = _processAllFilters(updatedState, mods);
  }

  void toggleShowEnabled() {
    // Writing the shared setting rebuilds this controller, and every other
    // page showing merged data, through [onlyEnabledModsProvider].
    ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(onlyEnabledMods: !s.onlyEnabledMods));
  }

  void setShowSpoilers(SpoilerLevel spoilerLevelToShow) {
    _spoilerField.setSelected(spoilerLevelToShow);
    _filters.maybePersist('general', ref.read(filterGroupPersistenceProvider));
    _emitAfterFilterMutation();
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

  /// Turn advanced filters on or off. This only decides whether the per-group
  /// "any" / "all" buttons are on show, so no re-filtering is needed.
  void setAdvancedMode(bool advanced) {
    if (advanced == state.advancedFilters) return;
    state = state.copyWith(
      persisted: state.persisted.copyWith(advancedFilters: advanced),
    );
    _persistState(state);
  }

  void toggleUseContainFit() {
    final updatedState = state.copyWith(
      persisted: state.persisted.copyWith(useContainFit: !state.useContainFit),
    );
    state = updatedState;
    _persistState(state);
  }

  void toggleAlwaysShowEngineGlow() {
    final updatedState = state.copyWith(
      persisted: state.persisted.copyWith(
        alwaysShowEngineGlow: !state.alwaysShowEngineGlow,
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

  /// Called after a user mutates a filter group's state via the renderer.
  void onGroupChanged(String groupId) {
    // "Only Enabled Mods" in the panel writes the shared setting, which is
    // what every page reads. The rebuild that follows syncs the field back.
    if (_showEnabledField.value != showEnabled) {
      ref
          .read(appSettings.notifier)
          .update((s) => s.copyWith(onlyEnabledMods: _showEnabledField.value));
      return;
    }
    _filters.maybePersist(groupId, ref.read(filterGroupPersistenceProvider));
    _emitAfterFilterMutation();
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

  List<Ship> _applyParsedQuery(
    List<Ship> ships,
    String query,
    Map<String, List<String>> shipValuesByShipId,
  ) {
    return SearchField.applyQuery(
      ships,
      query,
      _fieldsByKey,
      shipValuesByShipId,
      (s) => s.id,
    );
  }

  void submitSearchQuery() {
    final query = state.currentSearchQuery.trim();
    if (query.isEmpty) return;
    ref.read(appSettings.notifier).update((s) {
      final deduped = [query, ...s.shipsSearchHistory.where((h) => h != query)];
      return s.copyWith(shipsSearchHistory: deduped.take(10).toList());
    });
  }

  List<SearchField<Ship>> _buildSearchFields() {
    return [
      // String fields
      SearchField.string(
        'size',
        'Hull size (frigate, destroyer, cruiser, capital_ship)',
        (s) => s.hullSize,
      ),
      SearchField.string(
        'shield',
        'Shield type (FRONT, OMNI, PHASE, NONE)',
        (s) => s.shieldType,
      ),
      SearchField.string('system', 'Ship system ID', (s) => s.systemId),
      SearchField.string('defense', 'Defense system ID', (s) => s.defenseId),
      SearchField.string(
        'manufacturer',
        'Tech/manufacturer',
        (s) => s.techManufacturer,
      ),
      SearchField.string(
        'designation',
        'Ship designation',
        (s) => s.designation,
      ),
      SearchField.string('style', 'Visual style', (s) => s.style),
      SearchField<Ship>(
        key: 'mod',
        description: 'Mod name substring match',
        valueSuggestions: (ships) =>
            ships
                .map((s) => s.modVariant?.modInfo.nameOrId)
                .whereType<String>()
                .toSet()
                .toList()
              ..sort(),
        matches: (ship, op, value) {
          if (op != DslOperator.equals) return false;
          final modName = ship.modVariant?.modInfo.nameOrId.toLowerCase() ?? '';
          return modName.contains(value.toLowerCase());
        },
      ),
      SearchField<Ship>(
        key: 'hullmod',
        description: 'Built-in hullmod, by name or ID',
        valueSuggestions: (ships) =>
            ships
                .expand((s) => s.builtInMods ?? const <String>[])
                .map((id) => _hullmodsById[id]?.name ?? id)
                .where((name) => name.isNotEmpty)
                .toSet()
                .toList()
              ..sort(),
        matches: (ship, op, value) {
          if (op != DslOperator.equals) return false;
          final search = value.toLowerCase();
          return (ship.builtInMods ?? const <String>[]).any((id) {
            if (id.toLowerCase().contains(search)) return true;
            final name = _hullmodsById[id]?.name?.toLowerCase();
            return name != null && name.contains(search);
          });
        },
      ),
      SearchField.multiValue(
        'hint',
        'Ship hint; matches any hint in a multi-value set',
        (s) => s.hints,
      ),
      SearchField.multiValue(
        'tag',
        'Ship CSV tag; matches any tag in a multi-value set',
        (s) => s.tags,
      ),
      // Numeric fields
      SearchField.numeric('hp', 'Hull hitpoints', (s) => s.hitpoints),
      SearchField.numeric('armor', 'Armor rating', (s) => s.armorRating),
      SearchField.numeric('flux', 'Max flux capacity', (s) => s.maxFlux),
      SearchField.numeric(
        'dissipation',
        'Flux dissipation',
        (s) => s.fluxDissipation,
      ),
      SearchField.numeric('op', 'Ordnance points', (s) => s.ordnancePoints),
      SearchField.numeric('speed', 'Max speed', (s) => s.maxSpeed),
      SearchField.numeric('accel', 'Acceleration', (s) => s.acceleration),
      SearchField.numeric('decel', 'Deceleration', (s) => s.deceleration),
      SearchField.numeric('turnrate', 'Max turn rate', (s) => s.maxTurnRate),
      SearchField.numeric(
        'turnaccel',
        'Turn acceleration',
        (s) => s.turnAcceleration,
      ),
      SearchField.numeric('bays', 'Fighter bays', (s) => s.fighterBays),
      SearchField.numeric('shieldarc', 'Shield arc', (s) => s.shieldArc),
      SearchField.numeric(
        'shieldeff',
        'Shield efficiency',
        (s) => s.shieldEfficiency,
      ),
      SearchField.numeric(
        'shieldupkeep',
        'Shield upkeep',
        (s) => s.shieldUpkeep,
      ),
      SearchField.numeric('phasecost', 'Phase cost', (s) => s.phaseCost),
      SearchField.numeric('phaseupkeep', 'Phase upkeep', (s) => s.phaseUpkeep),
      SearchField.numeric('mincrew', 'Minimum crew', (s) => s.minCrew),
      SearchField.numeric('maxcrew', 'Maximum crew', (s) => s.maxCrew),
      SearchField.numeric('cargo', 'Cargo capacity', (s) => s.cargo),
      SearchField.numeric('fuel', 'Fuel capacity', (s) => s.fuel),
      SearchField.numeric(
        'fuelperly',
        'Fuel used per light year',
        (s) => s.fuelPerLY,
      ),
      SearchField.numeric('range', 'Range', (s) => s.range),
      SearchField.numeric('burn', 'Max burn', (s) => s.maxBurn),
      SearchField.numeric('mass', 'Ship mass', (s) => s.mass),
      SearchField.numeric('dp', 'Deployment points', (s) => s.deploymentPoints),
      SearchField.numeric('fleetpts', 'Fleet points', (s) => s.fleetPts),
      SearchField.numeric('cost', 'Base credit value', (s) => s.baseValue),
      SearchField.numeric(
        'slots',
        'Weapon slots',
        (s) => s.mountableWeaponSlotCount,
      ),
      SearchField.numeric('peak', 'Peak CR seconds', (s) => s.peakCrSec),
      SearchField.numeric(
        'crday',
        'CR recovered per day',
        (s) => s.crPercentPerDay,
      ),
      SearchField.numeric('crdeploy', 'CR cost to deploy', (s) => s.crToDeploy),
      SearchField.numeric(
        'crloss',
        'CR lost per second past peak',
        (s) => s.crLossPerSec,
      ),
      SearchField.numeric(
        'supplies',
        'Supplies per month',
        (s) => s.suppliesMo,
      ),
      SearchField.numeric(
        'sensorprofile',
        'Sensor profile',
        (s) => s.sensorProfile,
      ),
      SearchField.numeric(
        'sensorstrength',
        'Sensor strength',
        (s) => s.sensorStrength,
      ),
      SearchField.numeric(
        'minpieces',
        'Minimum debris pieces',
        (s) => s.minPieces,
      ),
      SearchField.numeric(
        'maxpieces',
        'Maximum debris pieces',
        (s) => s.maxPieces,
      ),
      SearchField.numeric(
        'builtinweapons',
        'Number of built-in weapons',
        (s) => s.builtInWeapons?.length ?? 0,
      ),
      SearchField.numeric(
        'builtinmods',
        'Number of built-in hullmods',
        (s) => s.builtInMods?.length ?? 0,
      ),
      SearchField.numeric(
        'builtinwings',
        'Number of built-in fighter wings',
        (s) => s.builtInWings?.length ?? 0,
      ),
      // Weapon slot fields by size, type, and size+type combination
      for (final size in const ['SMALL', 'MEDIUM', 'LARGE'])
        SearchField.numeric<Ship>(
          '${size.toLowerCase()}Slots',
          '${size.toLowerCase().toTitleCase()} slots',
          (s) => s.countMountableSlots(size: size),
        ),
      for (final type in const [
        'BALLISTIC',
        'ENERGY',
        'MISSILE',
        'COMPOSITE',
        'HYBRID',
        'SYNERGY',
        'UNIVERSAL',
      ])
        SearchField.numeric<Ship>(
          '${type.toLowerCase()}Slots',
          '${type.toLowerCase().toTitleCase()} mountable slots',
          (s) => s.countMountableSlots(type: type),
        ),
      for (final size in const ['SMALL', 'MEDIUM', 'LARGE'])
        for (final type in const [
          'BALLISTIC',
          'ENERGY',
          'MISSILE',
          'COMPOSITE',
          'HYBRID',
          'SYNERGY',
          'UNIVERSAL',
        ])
          SearchField.numeric<Ship>(
            '${size.toLowerCase()}${type.toLowerCase().toTitleCase()}',
            '${size.toLowerCase().toTitleCase()} ${type.toLowerCase()} slots',
            (s) => s.countMountableSlots(type: type, size: size),
          ),
    ];
  }
}

final shipsPageControllerProvider =
    NotifierProvider<ShipsPageController, ShipsPageState>(() {
      return ShipsPageController();
    });
