import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/search_index.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/weapons_manager.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';
import 'package:trios/widgets/smart_search/search_dsl_field.dart';

part 'weapons_page_controller.mapper.dart';

/// Stable page identifier for persistence keying.
const String kWeaponsPageId = 'weapons';

@MappableClass()
class WeaponsPageStatePersisted with WeaponsPageStatePersistedMappable {
  final bool splitPane;
  final bool useContainFit;
  final bool showFilters;
  final bool alwaysShowGlow;

  const WeaponsPageStatePersisted({
    this.splitPane = false,
    this.useContainFit = false,
    this.showFilters = false,
    this.alwaysShowGlow = false,
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

  bool get alwaysShowGlow => persisted.alwaysShowGlow;

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

/// Whether [weapon] should be shown at the given spoiler [level].
/// Shared by the weapons page and the faction profile dialog.
bool weaponMatchesSpoilerLevel(Weapon weapon, WeaponSpoilerLevel level) {
  if (level == WeaponSpoilerLevel.showAllSpoilers) return true;
  // tagsAsSet is cached on the weapon; re-splitting the tags string here was
  // a hot spot when the codex filters every weapon on each data refresh.
  return !weapon.tagsAsSet.contains('codex_unlockable');
}

final weaponsPageControllerProvider =
    NotifierProvider<WeaponsPageController, WeaponsPageState>(
      () => WeaponsPageController(),
    );

class WeaponsPageController extends Notifier<WeaponsPageState> {
  static final _scope = const FilterScope(kWeaponsPageId);

  late final FilterScopeController<Weapon> _filters;
  late final List<SearchField<Weapon>> _searchFields;
  late final Map<String, SearchField<Weapon>> _fieldsByKey;
  List<Weapon>? _searchIndexItems;

  final vanillaName = 'Vanilla';

  FilterScope get scope => _scope;

  List<FilterGroup<Weapon>> get filterGroups => _filters.groups;

  List<SearchFieldMeta> get searchFieldsMeta =>
      _searchFields.map((f) => f.toMeta(state.allWeapons)).toList();

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
      _searchFields = _buildSearchFields();
      _fieldsByKey = {for (final f in _searchFields) f.key: f};
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

    final itemsChanged = !identical(allWeapons, _searchIndexItems);
    _searchIndexItems = allWeapons;
    final weaponValuesByWeaponId = itemsChanged
        ? _updateSearchIndices(allWeapons)
        : stateOrNull?.weaponSearchIndices ?? _updateSearchIndices(allWeapons);

    final initialState =
        (stateOrNull ??
                WeaponsPageState(
                  persisted: WeaponsPageStatePersisted(
                    splitPane: saved?.splitPane ?? false,
                    useContainFit: saved?.useContainFit ?? false,
                    showFilters: saved?.showFilters ?? false,
                    alwaysShowGlow: saved?.alwaysShowGlow ?? false,
                  ),
                ))
            .copyWith(
              allWeapons: allWeapons,
              weaponSearchIndices: weaponValuesByWeaponId,
              isLoading: isLoadingWeapons,
            );

    if (!itemsChanged && !showEnabled && stateOrNull != null) {
      return initialState.copyWith(
        filteredWeapons: stateOrNull!.filteredWeapons,
        weaponsBeforeGridFilter: stateOrNull!.weaponsBeforeGridFilter,
      );
    }

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
            inactiveValue: WeaponSpoilerLevel.showAllSpoilers,
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

  bool _spoilerMatches(Weapon weapon, WeaponSpoilerLevel level) =>
      weaponMatchesSpoilerLevel(weapon, level);

  String _spoilerLabel(WeaponSpoilerLevel e) => switch (e) {
    WeaponSpoilerLevel.noSpoilers => 'No spoilers',
    WeaponSpoilerLevel.showAllSpoilers => 'Show all spoilers',
  };

  String _spoilerTooltip(WeaponSpoilerLevel e) => switch (e) {
    WeaponSpoilerLevel.noSpoilers => 'Hides weapons tagged CODEX_UNLOCKABLE.',
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
            alwaysShowGlow: newState.alwaysShowGlow,
          ),
        );
      });
    } catch (_) {}
  }

  Map<String, List<String>> _updateSearchIndices(List<Weapon> allWeapons) {
    return updateSearchIndices(
      allWeapons,
      stateOrNull?.weaponSearchIndices ?? {},
      (w) => w.id,
      (w) => w.toMap(),
    );
  }

  WeaponsPageState _processAllFilters(
    WeaponsPageState currentState,
    List<Mod> mods,
  ) {
    var weapons = _applyEnabledAndHidden(currentState.allWeapons.toList());
    weapons = _applySpoilers(weapons);

    final weaponsBeforeGridFilter = weapons.toList();

    weapons = _filters.applyChipFilters(weapons);

    weapons = _applyParsedQuery(
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
    if (query == state.currentSearchQuery) return;
    final mods = ref.read(AppState.mods);
    state = _processAllFilters(state.copyWith(currentSearchQuery: query), mods);
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

  void toggleAlwaysShowGlow() {
    final updatedState = state.copyWith(
      persisted: state.persisted.copyWith(
        alwaysShowGlow: !state.alwaysShowGlow,
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

  List<SearchField<Weapon>> _buildSearchFields() {
    return [
      SearchField.string(
        'tracking',
        'Tracking quality (excellent, good, poor, none)',
        (w) => w.trackingStr,
      ),
      SearchField<Weapon>(
        key: 'ammo',
        description:
            'Ammo count (none = unlimited); supports numeric operators',
        supportsNumeric: true,
        valueSuggestions: (weapons) => ['none'],
        matches: (weapon, op, value) {
          if (value.toLowerCase() == 'none') {
            if (op != DslOperator.equals) return false;
            return weapon.ammo == null || weapon.ammo == 0;
          }
          final numVal = double.tryParse(value);
          if (numVal == null) return false;
          final ammo = weapon.ammo ?? 0;
          return switch (op) {
            DslOperator.equals => ammo == numVal,
            DslOperator.greaterThan => ammo > numVal,
            DslOperator.lessThan => ammo < numVal,
            DslOperator.greaterThanOrEqual => ammo >= numVal,
            DslOperator.lessThanOrEqual => ammo <= numVal,
          };
        },
      ),
      SearchField.string(
        'type',
        'Weapon type (missile, energy, ballistic, hybrid)',
        (w) => w.weaponType,
      ),
      SearchField.string(
        'size',
        'Mount size (small, medium, large)',
        (w) => w.size,
      ),
      SearchField.string(
        'damage',
        'Damage type (kinetic, he, energy, fragmentation)',
        (w) => w.damageType,
      ),
      SearchField.numeric('range', 'Weapon range', (w) => w.range),
      SearchField.numeric('op', 'Ordnance points cost', (w) => w.ops),
      SearchField.numeric('dps', 'Damage per second', (w) => w.damagePerSecond),
      SearchField<Weapon>(
        key: 'hint',
        description: 'Weapon hint tag; matches any hint in a multi-value set',
        valueSuggestions: (weapons) =>
            weapons
                .expand((w) => w.hintsAsSet)
                .where((v) => v.isNotEmpty)
                .toSet()
                .toList()
              ..sort(),
        matches: (weapon, op, value) {
          if (op != DslOperator.equals) return false;
          return weapon.hintsAsSet.contains(value.toLowerCase());
        },
      ),
      SearchField<Weapon>(
        key: 'tag',
        description: 'Weapon CSV tag; matches any tag in a multi-value set',
        valueSuggestions: (weapons) =>
            weapons
                .expand((w) => w.tagsAsSet)
                .where((v) => v.isNotEmpty)
                .toSet()
                .toList()
              ..sort(),
        matches: (weapon, op, value) {
          if (op != DslOperator.equals) return false;
          return weapon.tagsAsSet.contains(value.toLowerCase());
        },
      ),
      SearchField<Weapon>(
        key: 'mod',
        description: 'Mod name substring match',
        valueSuggestions: (weapons) =>
            weapons
                .map((w) => w.modVariant?.modInfo.nameOrId)
                .whereType<String>()
                .toSet()
                .toList()
              ..sort(),
        matches: (weapon, op, value) {
          if (op != DslOperator.equals) return false;
          final modName =
              weapon.modVariant?.modInfo.nameOrId.toLowerCase() ?? '';
          return modName.contains(value.toLowerCase());
        },
      ),
      // Combat stats (numeric)
      SearchField.numeric('dpshot', 'Damage per shot', (w) => w.damagePerShot),
      SearchField.numeric('emp', 'EMP damage', (w) => w.emp),
      SearchField.numeric('energy', 'Flux per shot', (w) => w.energyPerShot),
      SearchField.numeric('eps', 'Flux per second', (w) => w.energyPerSecond),
      SearchField.numeric(
        'chargeup',
        'Charge-up time in seconds',
        (w) => w.chargeup,
      ),
      SearchField.numeric(
        'chargedown',
        'Charge-down time in seconds',
        (w) => w.chargedown,
      ),
      SearchField.numeric(
        'burst',
        'Burst size (number of shots)',
        (w) => w.burstSize,
      ),
      SearchField.numeric(
        'burstdelay',
        'Delay between burst shots',
        (w) => w.burstDelay,
      ),
      SearchField.numeric(
        'turnrate',
        'Projectile/beam turn rate',
        (w) => w.turnRate,
      ),
      SearchField.numeric('speed', 'Projectile speed', (w) => w.projSpeed),
      SearchField.numeric('beamspeed', 'Beam speed', (w) => w.beamSpeed),
      SearchField.numeric(
        'launchspeed',
        'Missile launch speed',
        (w) => w.launchSpeed,
      ),
      SearchField.numeric(
        'flighttime',
        'Projectile flight time',
        (w) => w.flightTime,
      ),
      SearchField.numeric(
        'projhp',
        'Projectile hitpoints',
        (w) => w.projHitpoints,
      ),
      SearchField.numeric(
        'ammosec',
        'Ammo regeneration per second',
        (w) => w.ammoPerSec,
      ),
      SearchField.numeric('reload', 'Reload size', (w) => w.reloadSize),
      SearchField.numeric('impact', 'Impact/force value', (w) => w.impact),
      SearchField.numeric(
        'autofire',
        'Autofire accuracy bonus',
        (w) => w.autofireAccBonus,
      ),
      // Spread/accuracy (numeric)
      SearchField.numeric('spread', 'Maximum spread', (w) => w.maxSpread),
      SearchField.numeric('minspread', 'Minimum spread', (w) => w.minSpread),
      SearchField.numeric(
        'spreadshot',
        'Spread added per shot',
        (w) => w.spreadPerShot,
      ),
      SearchField.numeric(
        'spreaddecay',
        'Spread decay per second',
        (w) => w.spreadDecayPerSec,
      ),
      // Weapon identity (string, with value suggestions)
      SearchField.string(
        'specclass',
        'Weapon spec class (beam, projectile, missile, etc.)',
        (w) => w.specClass,
      ),
      SearchField.string(
        'mount',
        'Effective mount type (TURRET, HARDPOINT, HIDDEN)',
        (w) => w.effectiveMountType,
      ),
      SearchField.string(
        'manufacturer',
        'Tech/manufacturer',
        (w) => w.techManufacturer,
      ),
      SearchField.string(
        'role',
        'Primary role description',
        (w) => w.primaryRoleStr,
      ),
      SearchField.string('group', 'Weapon group tag', (w) => w.groupTag),
      // Metadata (numeric)
      SearchField.numeric('tier', 'Weapon tier', (w) => w.tier),
      SearchField.numeric('rarity', 'Rarity value', (w) => w.rarity),
      SearchField.numeric('cost', 'Base credit value', (w) => w.baseValue),
    ];
  }

  List<Weapon> _applyParsedQuery(
    List<Weapon> weapons,
    String query,
    Map<String, List<String>> weaponValuesByWeaponId,
  ) {
    return SearchField.applyQuery(
      weapons,
      query,
      _fieldsByKey,
      weaponValuesByWeaponId,
      (w) => w.id,
    );
  }

  void submitSearchQuery() {
    final query = state.currentSearchQuery.trim();
    if (query.isEmpty) return;
    ref.read(appSettings.notifier).update((s) {
      final deduped = [
        query,
        ...s.weaponsSearchHistory.where((h) => h != query),
      ];
      return s.copyWith(weaponsSearchHistory: deduped.take(10).toList());
    });
  }
}
