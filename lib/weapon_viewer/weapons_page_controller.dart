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
import 'package:trios/widgets/smart_search/search_dsl_field.dart';
import 'package:trios/widgets/smart_search/search_dsl_parser.dart';

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
  late final List<SearchField<Weapon>> _searchFields;
  late final Map<String, SearchField<Weapon>> _fieldsByKey;

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
      SearchField<Weapon>(
        key: 'tracking',
        description: 'Tracking quality (excellent, good, poor, none)',
        valueSuggestions: (weapons) => weapons
            .map((w) => w.trackingStr?.toLowerCase())
            .whereType<String>()
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort(),
        matches: (weapon, op, value) {
          if (op != DslOperator.equals) return false;
          return weapon.trackingStr?.toLowerCase() == value.toLowerCase();
        },
      ),
      SearchField<Weapon>(
        key: 'ammo',
        description: 'Ammo count (none = unlimited); supports numeric operators',
        supportsNumeric: true,
        valueSuggestions: (weapons) => ['none'],
        matches: (weapon, op, value) {
          if (value.toLowerCase() == 'none') {
            if (op != DslOperator.equals) return false;
            return weapon.ammo == null || weapon.ammo == 0;
          }
          final numVal = double.tryParse(value);
          if (numVal == null) return false;
          return _compareNumeric(weapon.ammo ?? 0, numVal, op);
        },
      ),
      SearchField<Weapon>(
        key: 'type',
        description: 'Weapon type (missile, energy, ballistic, hybrid)',
        valueSuggestions: (weapons) => weapons
            .map((w) => w.weaponType?.toLowerCase())
            .whereType<String>()
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort(),
        matches: (weapon, op, value) {
          if (op != DslOperator.equals) return false;
          return weapon.weaponType?.toLowerCase() == value.toLowerCase();
        },
      ),
      SearchField<Weapon>(
        key: 'size',
        description: 'Mount size (small, medium, large)',
        valueSuggestions: (weapons) => weapons
            .map((w) => w.size?.toLowerCase())
            .whereType<String>()
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort(),
        matches: (weapon, op, value) {
          if (op != DslOperator.equals) return false;
          return weapon.size?.toLowerCase() == value.toLowerCase();
        },
      ),
      SearchField<Weapon>(
        key: 'damage',
        description: 'Damage type (kinetic, he, energy, fragmentation)',
        valueSuggestions: (weapons) => weapons
            .map((w) => w.damageType?.toLowerCase())
            .whereType<String>()
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort(),
        matches: (weapon, op, value) {
          if (op != DslOperator.equals) return false;
          return weapon.damageType?.toLowerCase() == value.toLowerCase();
        },
      ),
      SearchField<Weapon>(
        key: 'range',
        description: 'Weapon range; supports numeric operators (>800)',
        supportsNumeric: true,
        valueSuggestions: (_) => [],
        matches: (weapon, op, value) {
          final numVal = double.tryParse(value);
          if (numVal == null) return false;
          final range = weapon.range;
          if (range == null) return false;
          return _compareNumeric(range, numVal, op);
        },
      ),
      SearchField<Weapon>(
        key: 'op',
        description: 'Ordnance points cost; supports numeric operators',
        supportsNumeric: true,
        valueSuggestions: (_) => [],
        matches: (weapon, op, value) {
          final numVal = double.tryParse(value);
          if (numVal == null) return false;
          final ops = weapon.ops?.toDouble();
          if (ops == null) return false;
          return _compareNumeric(ops, numVal, op);
        },
      ),
      SearchField<Weapon>(
        key: 'dps',
        description: 'Damage per second; supports numeric operators',
        supportsNumeric: true,
        valueSuggestions: (_) => [],
        matches: (weapon, op, value) {
          final numVal = double.tryParse(value);
          if (numVal == null) return false;
          final dps = weapon.damagePerSecond;
          if (dps == null) return false;
          return _compareNumeric(dps, numVal, op);
        },
      ),
      SearchField<Weapon>(
        key: 'hint',
        description: 'Weapon hint tag; matches any hint in a multi-value set',
        valueSuggestions: (weapons) => weapons
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
        valueSuggestions: (weapons) => weapons
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
        valueSuggestions: (weapons) => weapons
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
    ];
  }

  List<Weapon> _applyParsedQuery(
    List<Weapon> weapons,
    String query,
    Map<String, List<String>> weaponValuesByWeaponId,
  ) {
    if (query.trim().isEmpty) return weapons;

    final parsed = SearchDslParser.parse(query);
    if (parsed.isEmpty) return weapons;

    final preparedTokens = [
      for (final token in parsed.tokens)
        if (token is TextToken)
          (token: token, lowered: token.text.toLowerCase())
        else if (token is FieldToken)
          (
            token: token,
            lowered: _fieldsByKey.containsKey(token.key)
                ? ''
                : token.toQueryString().toLowerCase(),
          ),
    ];

    return weapons
        .where(
          (w) => _weaponMatchesQuery(w, preparedTokens, weaponValuesByWeaponId),
        )
        .toList();
  }

  bool _weaponMatchesQuery(
    Weapon weapon,
    List<({Object token, String lowered})> tokens,
    Map<String, List<String>> weaponValuesByWeaponId,
  ) {
    final values = weaponValuesByWeaponId[weapon.id];
    for (final entry in tokens) {
      final token = entry.token;
      if (token is TextToken) {
        if (!(values?.any((v) => v.contains(entry.lowered)) ?? false)) {
          return false;
        }
      } else if (token is FieldToken) {
        final field = _fieldsByKey[token.key];
        final bool result;
        if (field == null) {
          // Unknown field key — fall back to substring match on the raw token
          result = values?.any((v) => v.contains(entry.lowered)) ?? false;
        } else {
          result = field.matches(weapon, token.operator, token.value);
        }
        if (token.negated ? result : !result) return false;
      }
    }
    return true;
  }

  bool _compareNumeric(num actual, double target, DslOperator op) => switch (op) {
    DslOperator.equals => actual == target,
    DslOperator.greaterThan => actual > target,
    DslOperator.lessThan => actual < target,
    DslOperator.greaterThanOrEqual => actual >= target,
    DslOperator.lessThanOrEqual => actual <= target,
  };

  void submitSearchQuery() {
    final query = state.currentSearchQuery.trim();
    if (query.isEmpty) return;
    ref.read(appSettings.notifier).update((s) {
      final deduped = [query, ...s.weaponsSearchHistory.where((h) => h != query)];
      return s.copyWith(weaponsSearchHistory: deduped.take(10).toList());
    });
  }
}
