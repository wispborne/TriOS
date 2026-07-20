import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_links.dart';
import 'package:trios/catalog/forum_data_manager.dart';
import 'package:trios/catalog/mod_browser_manager.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/mod_search.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';

part 'mod_browser_page_controller.mapper.dart';

const String kCatalogPageId = 'catalog';

/// Chip-value keys for the Catalog "Attributes" filter group.
const String kAttrDownload = 'download';
const String kAttrDiscord = 'discord';
const String kAttrIndex = 'index';
const String kAttrForum = 'forum';
const String kAttrWip = 'wip';
const String kAttrArchived = 'archived';

const List<String> _kAttributeOrder = [
  kAttrDownload,
  kAttrDiscord,
  kAttrIndex,
  kAttrForum,
  kAttrWip,
  kAttrArchived,
];

const Map<String, String> _kAttributeLabels = {
  kAttrDownload: 'Has Download Link',
  kAttrDiscord: 'Discord',
  kAttrIndex: 'Index',
  kAttrForum: 'Forum',
  kAttrWip: 'WIP',
  kAttrArchived: 'Archived',
};

@MappableClass()
class CatalogPageStatePersisted with CatalogPageStatePersistedMappable {
  final bool showFilters;

  const CatalogPageStatePersisted({this.showFilters = false});
}

@MappableClass()
class CatalogPageState with CatalogPageStateMappable {
  final CatalogPageStatePersisted persisted;
  final List<CatalogMod> allMods;
  final List<CatalogMod> displayedMods;
  final String currentSearchQuery;
  final CatalogSortKey selectedSort;
  final bool sortAscending;
  final bool isLoading;

  bool get showFilters => persisted.showFilters;

  const CatalogPageState({
    this.persisted = const CatalogPageStatePersisted(),
    this.allMods = const [],
    this.displayedMods = const [],
    this.currentSearchQuery = '',
    this.selectedSort = CatalogSortKey.mostViewed,
    this.sortAscending = false,
    this.isLoading = false,
  });
}

class CatalogEntryStatus {
  final Mod mod;
  final VersionCheckComparison? versionCheck;

  const CatalogEntryStatus({required this.mod, this.versionCheck});
}

class CatalogPageController extends Notifier<CatalogPageState> {
  static const FilterScope _scope = FilterScope(kCatalogPageId);

  late final FilterScopeController<CatalogMod> _filters;

  /// Resolved catalog↔installed links from the shared [catalogLinksProvider].
  CatalogLinks _links = CatalogLinks(const []);
  VersionCheckerState? _versionCheckState;
  Map<String, Set<String>> _versionGroupOptions = const {};
  bool _hasSeededVersionDefault = false;

  FilterScope get scope => _scope;

  List<FilterGroup<CatalogMod>> get filterGroups => _filters.groups;

  int get activeFilterCount => _filters.activeCount;

  /// Number of installed mods with an available update. Backs the toolbar
  /// "N updates" pill. Counts distinct mods, since one installed mod can be
  /// linked from several catalog entries (name, id, add-on).
  int get updatesCount => _links.all
      .where((l) => l.mod.updateCheck(_versionCheckState)?.hasUpdate == true)
      .map((l) => l.mod.id)
      .toSet()
      .length;

  /// The installed-mod + update status for a catalog entry name, or null when
  /// it isn't installed. Backed by the shared [catalogLinksProvider], so cards,
  /// dialogs, and filters all read the same links.
  CatalogEntryStatus? statusForModName(String modName) {
    final link = _links.linkForName(modName);
    if (link == null) return null;
    return CatalogEntryStatus(
      mod: link.mod,
      versionCheck: link.mod.updateCheck(_versionCheckState),
    );
  }

  @override
  CatalogPageState build() {
    final isLoading = ref.watch(isLoadingCatalog);

    // The full catalog list (real entries + made-up add-on cards) and the
    // resolved catalog↔installed links both come from shared providers, so the
    // page, dialogs, and records store can never disagree about install state.
    final allMods = ref.watch(catalogEntriesProvider);
    _links = ref.watch(catalogLinksProvider);
    _versionCheckState = ref
        .watch(AppState.versionCheckResults)
        .valueOrNull;
    _versionGroupOptions = extractVersionGroups(allMods);

    if (stateOrNull == null) {
      _filters = _buildFilters();
      final persistence = ref.read(filterGroupPersistenceProvider);
      _filters.loadPersisted(persistence);
    }

    _filters.applyPendingChipMerge(allMods);

    // Keep the version field's option list in sync with the current data.
    final versionField = _versionChoiceField();
    if (versionField != null) {
      versionField.options
        ..clear()
        ..addAll(_versionGroupOptions.keys);
      if (versionField.selected != null &&
          !versionField.options.contains(versionField.selected)) {
        versionField.selected = null;
      }
    }

    // Seed version default once data is present and nothing has been
    // restored/selected for it yet.
    if (!_hasSeededVersionDefault && _versionGroupOptions.isNotEmpty) {
      if (versionField != null && versionField.selected == null) {
        versionField.setSelected(_versionGroupOptions.keys.first);
      }
      _hasSeededVersionDefault = true;
    }

    final saved = ref.read(appSettings).catalogPageState;
    final initialState =
        (stateOrNull ??
                CatalogPageState(
                  persisted: CatalogPageStatePersisted(
                    showFilters: saved?.showFilters ?? false,
                  ),
                ))
            .copyWith(allMods: allMods, isLoading: isLoading);

    return _processAllFilters(initialState);
  }

  FilterScopeController<CatalogMod> _buildFilters() {
    // Category order is declared and stable; the chip renderer respects
    // sortComparator when useDefaultSort is false.
    int declaredAttrIndex(String v) {
      final i = _kAttributeOrder.indexOf(v);
      return i < 0 ? _kAttributeOrder.length : i;
    }

    final groups = <FilterGroup<CatalogMod>>[
      CompositeFilterGroup<CatalogMod>(
        id: 'status',
        name: 'Status',
        fields: [
          StringChoiceField<CatalogMod>(
            id: 'installed',
            label: 'Installed',
            allLabel: 'Both Installed & Available',
            options: const ['installed', 'available'],
            optionLabel: (v) =>
                v == 'installed' ? 'Only Installed' : 'Not Installed',
            predicate: (mod, selected) {
              if (selected == null) return true;
              final isInstalled = _links.linkForName(mod.name) != null;
              return selected == 'installed' ? isInstalled : !isInstalled;
            },
          ),
          BoolField<CatalogMod>(
            id: 'hasUpdate',
            label: 'Has Update',
            badgeCount: () => updatesCount,
            predicate: (mod) =>
                statusForModName(mod.name)?.versionCheck?.hasUpdate == true,
          ),
        ],
      ),
      ChipFilterGroup<CatalogMod>(
        id: 'attributes',
        name: 'Attributes',
        valueGetter: (_) => '',
        valuesGetter: _attributeValuesFor,
        displayNameGetter: (v) => _kAttributeLabels[v] ?? v,
        sortComparator: (a, b) =>
            declaredAttrIndex(a).compareTo(declaredAttrIndex(b)),
      ),
      CompositeFilterGroup<CatalogMod>(
        id: 'version',
        name: 'Game Version',
        fields: [
          StringChoiceField<CatalogMod>(
            id: 'versionBucket',
            label: 'Game Version',
            options: _versionGroupOptions.keys.toList(),
            allLabel: 'All Versions',
            predicate: (mod, selected) {
              if (selected == null) return true;
              final bucket = _versionGroupOptions[selected];
              if (bucket == null) return false;
              return mod.gameVersionReq != null &&
                  bucket.contains(mod.gameVersionReq);
            },
          ),
        ],
      ),
      ChipFilterGroup<CatalogMod>(
        id: 'category',
        name: 'Category',
        collapsedByDefault: false,
        valueGetter: (_) => '',
        valuesGetter: (m) => m.categories ?? const <String>[],
      ),
    ];
    return FilterScopeController<CatalogMod>(scope: _scope, groups: groups);
  }

  /// Returns the set of Attribute chip-value keys that apply to [mod].
  List<String> _attributeValuesFor(CatalogMod mod) {
    final result = <String>[];
    final urls = mod.urls;
    if (urls?.containsKey(ModUrlType.DirectDownload) == true) {
      result.add(kAttrDownload);
    }
    final sources = mod.sources;
    if (sources?.contains(ModSource.Discord) == true) result.add(kAttrDiscord);
    if (sources?.contains(ModSource.Index) == true) result.add(kAttrIndex);
    if (sources?.contains(ModSource.ModdingSubforum) == true) {
      result.add(kAttrForum);
    }
    final topicId = extractForumTopicId(mod.urls?[ModUrlType.Forum]);
    if (topicId != null) {
      final forum = ref.read(forumDataByTopicId)[topicId];
      if (forum != null) {
        if (forum.isWip) result.add(kAttrWip);
        if (forum.isArchivedModIndex) result.add(kAttrArchived);
      }
    }
    return result;
  }

  StringChoiceField<CatalogMod>? _versionChoiceField() {
    final group =
        _filters.findGroup('version') as CompositeFilterGroup<CatalogMod>?;
    return group?.fieldById('versionBucket') as StringChoiceField<CatalogMod>?;
  }

  CatalogPageState _processAllFilters(CatalogPageState current) {
    Iterable<CatalogMod> items = current.allMods;

    // 1. Search
    final q = current.currentSearchQuery;
    if (q.isNotEmpty) {
      items = searchCatalogMods(items.toList(), q);
    }

    // 2. Chip groups (Attributes, Category)
    items = _filters.applyChipFilters(items);

    // 3. Non-chip groups (Version composite)
    items = _filters.applyNonChipFilters(items);

    // 4. Sort
    final sorted = sortCatalogMods(
      items.toList(),
      current.selectedSort,
      ascending: current.sortAscending,
      forumLookup: ref.read(forumDataByTopicId),
    );

    return current.copyWith(displayedMods: sorted);
  }

  // ===== Public mutators =====

  void updateSearchQuery(String query) {
    state = _processAllFilters(state.copyWith(currentSearchQuery: query));
  }

  void setSort(CatalogSortKey sort) {
    state = _processAllFilters(
      state.copyWith(
        selectedSort: sort,
        sortAscending: sort.defaultAscending,
      ),
    );
  }

  void toggleSortDirection() {
    state = _processAllFilters(
      state.copyWith(sortAscending: !state.sortAscending),
    );
  }

  void toggleShowFilters() {
    final next = state.copyWith(
      persisted: state.persisted.copyWith(showFilters: !state.showFilters),
    );
    state = next;
    _persistUiState(next);
  }

  void clearAllFilters() {
    _filters.clearAll();
    _hasSeededVersionDefault = false; // allow re-seed to newest on next build
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
    state = _processAllFilters(state);
  }

  void _persistUiState(CatalogPageState s) {
    try {
      ref
          .read(appSettings.notifier)
          .update(
            (curr) => curr.copyWith(
              catalogPageState:
                  (curr.catalogPageState ?? const CatalogPageStatePersisted())
                      .copyWith(showFilters: s.showFilters),
            ),
          );
    } catch (e, st) {
      Fimber.w('Failed to persist catalog page state', ex: e, stacktrace: st);
    }
  }
}

final catalogPageControllerProvider =
    NotifierProvider<CatalogPageController, CatalogPageState>(
      CatalogPageController.new,
    );
