import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/faction_viewer/faction_manager.dart';
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';
import 'package:trios/widgets/smart_search/search_dsl_field.dart';

part 'faction_viewer_controller.mapper.dart';

const String kFactionViewerPageId = 'factions';

@MappableEnum()
enum FactionViewMode { gallery, grid }

@MappableEnum()
enum FactionGallerySortField {
  name('Name'),
  ships('Ships'),
  weapons('Weapons'),
  aggression('Aggression'),
  shipQuality('Ship Quality'),
  officerQuality('Officer Quality'),
  source('Source');

  final String label;
  const FactionGallerySortField(this.label);
}

@MappableClass()
class FactionViewerStatePersisted with FactionViewerStatePersistedMappable {
  final FactionViewMode viewMode;
  final bool showFilters;
  final FactionGallerySortField gallerySortField;
  final bool gallerySortAscending;

  const FactionViewerStatePersisted({
    this.viewMode = FactionViewMode.gallery,
    this.showFilters = false,
    this.gallerySortField = FactionGallerySortField.ships,
    this.gallerySortAscending = false,
  });
}

@MappableClass()
class FactionViewerState with FactionViewerStateMappable {
  final FactionViewerStatePersisted persisted;
  final List<Faction> allFactions;
  final List<Faction> filteredFactions;
  final String searchQuery;
  final bool isLoading;

  bool get showFilters => persisted.showFilters;
  FactionViewMode get viewMode => persisted.viewMode;
  FactionGallerySortField get gallerySortField => persisted.gallerySortField;
  bool get gallerySortAscending => persisted.gallerySortAscending;

  const FactionViewerState({
    this.persisted = const FactionViewerStatePersisted(),
    this.allFactions = const [],
    this.filteredFactions = const [],
    this.searchQuery = '',
    this.isLoading = false,
  });
}

final factionViewerControllerProvider =
    NotifierProvider<FactionViewerController, FactionViewerState>(
      () => FactionViewerController(),
    );

class FactionViewerController extends Notifier<FactionViewerState> {
  static final _scope = const FilterScope(kFactionViewerPageId);

  late final FilterScopeController<Faction> _filters;
  late final List<SearchField<Faction>> _searchFields = _buildSearchFields();
  late final Map<String, SearchField<Faction>> _fieldsByKey = {
    for (final f in _searchFields) f.key: f,
  };
  String _searchQuery = '';
  Map<String, List<String>> _cachedSearchIndices = {};
  List<Faction> _cachedSearchIndicesFactions = const [];

  FilterScope get scope => _scope;
  List<FilterGroup<Faction>> get filterGroups => _filters.groups;
  int get activeFilterCount => _filters.activeCount;

  List<SearchFieldMeta> get searchFieldsMeta =>
      _searchFields.map((f) => f.toMeta(state.allFactions)).toList();

  @override
  FactionViewerState build() {
    final persisted = ref.watch(
      appSettings.select((s) => s.factionViewerState),
    ) ?? const FactionViewerStatePersisted();

    if (stateOrNull == null) {
      _filters = _buildFilters();
      _filters.loadPersisted(ref.read(filterGroupPersistenceProvider));
    }

    final factions = ref.watch(factionListNotifierProvider);
    final isLoading = ref.watch(isLoadingFactionsList);
    final allFactions = factions.valueOrNull ?? [];

    var filtered = _filters.applyChipFilters(allFactions);
    filtered = _filters.applyNonChipFilters(filtered);
    filtered = _applySearch(filtered, _searchQuery);

    return FactionViewerState(
      persisted: persisted,
      allFactions: allFactions,
      filteredFactions: filtered,
      searchQuery: _searchQuery,
      isLoading: isLoading,
    );
  }

  FilterScopeController<Faction> _buildFilters() {
    return FilterScopeController<Faction>(
      scope: _scope,
      groups: [
        CompositeFilterGroup<Faction>(
          id: 'visibility',
          name: 'Visibility',
          fields: [
            BoolField<Faction>(
              id: 'hideHidden',
              label: 'Hide hidden factions',
              tooltip: 'Hide factions with showInIntelTab: false (Remnants, Omega, etc.)',
              predicate: (f) => f.showInIntelTab,
              initialValue: true,
            ),
            BoolField<Faction>(
              id: 'hideModOnly',
              label: 'Hide mod-only factions',
              predicate: (f) => !f.isModOnly,
            ),
          ],
        ),
        ChipFilterGroup<Faction>(
          id: 'source',
          name: 'Source',
          valueGetter: (f) => f.sources.firstOrNull?.name ?? 'Unknown',
          valuesGetter: (f) => f.sources.map((s) => s.name).toList(),
        ),
      ],
    );
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _refilter();
  }

  void submitSearchQuery() {
    final query = _searchQuery.trim();
    if (query.isEmpty) return;
    ref.read(appSettings.notifier).update((s) {
      final deduped = [
        query,
        ...s.factionSearchHistory.where((h) => h != query),
      ];
      return s.copyWith(factionSearchHistory: deduped.take(10).toList());
    });
  }

  void toggleShowFilters() {
    _updatePersisted(
      state.persisted.copyWith(showFilters: !state.showFilters),
    );
  }

  void setViewMode(FactionViewMode mode) {
    _updatePersisted(state.persisted.copyWith(viewMode: mode));
  }

  void setGallerySortField(FactionGallerySortField field) {
    _updatePersisted(state.persisted.copyWith(gallerySortField: field));
  }

  void toggleGallerySortDirection() {
    _updatePersisted(
      state.persisted.copyWith(
        gallerySortAscending: !state.gallerySortAscending,
      ),
    );
  }

  void setChipSelections(String groupId, Map<String, bool?> selections) {
    _filters.setChipSelections(groupId, selections);
    _refilter();
  }

  void onGroupChanged(String groupId) {
    _filters.maybePersist(groupId, ref.read(filterGroupPersistenceProvider));
    _refilter();
  }

  void clearAllFilters() {
    _filters.clearAll();
    _refilter();
  }

  void _refilter() {
    var filtered = _filters.applyChipFilters(state.allFactions);
    filtered = _filters.applyNonChipFilters(filtered);
    filtered = _applySearch(filtered, _searchQuery);
    state = state.copyWith(
      filteredFactions: filtered,
      searchQuery: _searchQuery,
    );
  }

  void _updatePersisted(FactionViewerStatePersisted persisted) {
    ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(factionViewerState: persisted));
  }

  List<Faction> _applySearch(List<Faction> factions, String query) {
    if (query.trim().isEmpty) return factions;
    return SearchField.applyQuery(
      factions,
      query,
      _fieldsByKey,
      _getSearchIndices(factions),
      (f) => f.id,
    );
  }

  Map<String, List<String>> _getSearchIndices(List<Faction> factions) {
    if (!identical(factions, _cachedSearchIndicesFactions)) {
      _cachedSearchIndicesFactions = factions;
      _cachedSearchIndices = {
        for (final f in factions)
          f.id: [
            f.id.toLowerCase(),
            f.displayName.toLowerCase(),
            if (f.displayNameLong != null) f.displayNameLong!.toLowerCase(),
            if (f.displayNameWithArticle != null)
              f.displayNameWithArticle!.toLowerCase(),
            f.sourceNames.toLowerCase(),
          ],
      };
    }
    return _cachedSearchIndices;
  }

  static Comparable _gallerySortValue(Faction f, FactionGallerySortField field) {
    return switch (field) {
      FactionGallerySortField.name => f.displayName.toLowerCase(),
      FactionGallerySortField.ships => f.knownShipIds.length,
      FactionGallerySortField.weapons => f.knownWeaponIds.length,
      FactionGallerySortField.aggression => f.doctrine?.aggression ?? 0,
      FactionGallerySortField.shipQuality => f.doctrine?.shipQuality ?? 0,
      FactionGallerySortField.officerQuality => f.doctrine?.officerQuality ?? 0,
      FactionGallerySortField.source => f.sourceNames.toLowerCase(),
    };
  }

  static List<Faction> sortForGallery(
    List<Faction> factions,
    FactionGallerySortField field,
    bool ascending,
  ) {
    final sorted = [...factions]..sort((a, b) {
      final va = _gallerySortValue(a, field);
      final vb = _gallerySortValue(b, field);
      return ascending ? va.compareTo(vb) : vb.compareTo(va);
    });
    return sorted;
  }

  static List<SearchField<Faction>> _buildSearchFields() {
    return [
      SearchField.string('id', 'Faction ID', (f) => f.id),
      SearchField<Faction>(
        key: 'name',
        description: 'Faction display name',
        valueSuggestions: (factions) =>
            factions.map((f) => f.displayName).toSet().toList()..sort(),
        matches: (f, op, value) {
          if (op != DslOperator.equals) return false;
          final lower = value.toLowerCase();
          return f.displayName.toLowerCase().contains(lower) ||
              (f.displayNameLong?.toLowerCase().contains(lower) ?? false);
        },
      ),
      SearchField<Faction>(
        key: 'source',
        description: 'Source mod or vanilla',
        valueSuggestions: (factions) =>
            factions.expand((f) => f.sources.map((s) => s.name)).toSet().toList()
              ..sort(),
        matches: (f, op, value) {
          if (op != DslOperator.equals) return false;
          return f.sources.any(
            (s) => s.name.toLowerCase() == value.toLowerCase(),
          );
        },
      ),
      SearchField.numeric(
        'ships',
        'Number of known ships',
        (f) => f.knownShipIds.length,
      ),
      SearchField.numeric(
        'weapons',
        'Number of known weapons',
        (f) => f.knownWeaponIds.length,
      ),
      SearchField.numeric(
        'fighters',
        'Number of known fighters',
        (f) => f.knownFighterIds.length,
      ),
      SearchField<Faction>(
        key: 'hidden',
        description: 'Whether faction is hidden from intel tab (true/false)',
        valueSuggestions: (_) => ['true', 'false'],
        matches: (f, op, value) {
          if (op != DslOperator.equals) return false;
          final isHidden = !f.showInIntelTab;
          return value.toLowerCase() == 'true' ? isHidden : !isHidden;
        },
      ),
      SearchField.numeric(
        'aggression',
        'Doctrine aggression level',
        (f) => f.doctrine?.aggression,
      ),
    ];
  }
}
