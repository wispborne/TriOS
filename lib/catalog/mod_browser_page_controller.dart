import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/forum_data_manager.dart';
import 'package:trios/catalog/mod_browser_manager.dart';
import 'package:trios/catalog/models/scraped_mod.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_records_store.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/search.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';

part 'mod_browser_page_controller.mapper.dart';

const String kCatalogPageId = 'catalog';

/// Chip-value keys for the Catalog "Attributes" filter group.
const String kAttrDownload = 'download';
const String kAttrDiscord = 'discord';
const String kAttrIndex = 'index';
const String kAttrForum = 'forum';
const String kAttrInstalled = 'installed';
const String kAttrUpdate = 'update';
const String kAttrWip = 'wip';
const String kAttrArchived = 'archived';

const List<String> _kAttributeOrder = [
  kAttrDownload,
  kAttrDiscord,
  kAttrIndex,
  kAttrForum,
  kAttrInstalled,
  kAttrUpdate,
  kAttrWip,
  kAttrArchived,
];

const Map<String, String> _kAttributeLabels = {
  kAttrDownload: 'Has Download Link',
  kAttrDiscord: 'Discord',
  kAttrIndex: 'Index',
  kAttrForum: 'Forum',
  kAttrInstalled: 'Installed',
  kAttrUpdate: 'Has Update',
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
  final List<ScrapedMod> allMods;
  final List<ScrapedMod> displayedMods;
  final String currentSearchQuery;
  final CatalogSortKey selectedSort;
  final bool isLoading;

  bool get showFilters => persisted.showFilters;

  const CatalogPageState({
    this.persisted = const CatalogPageStatePersisted(),
    this.allMods = const [],
    this.displayedMods = const [],
    this.currentSearchQuery = '',
    this.selectedSort = CatalogSortKey.mostViewed,
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

  late final FilterScopeController<ScrapedMod> _filters;

  Map<String, CatalogEntryStatus> _catalogStatusMap = const {};
  Map<String, Set<String>> _versionGroupOptions = const {};
  bool _hasSeededVersionDefault = false;

  FilterScope get scope => _scope;

  List<FilterGroup<ScrapedMod>> get filterGroups => _filters.groups;

  int get activeFilterCount => _filters.activeCount;

  /// Lookup of catalog-mod installation/update status keyed by
  /// `mod.name.toLowerCase().trim()`. Used by card UIs to decorate installed
  /// mods; null when the mod is not installed.
  CatalogEntryStatus? statusForModName(String modName) =>
      _catalogStatusMap[modName.toLowerCase().trim()];

  @override
  CatalogPageState build() {
    final repo = ref.watch(browseModsNotifierProvider).value;
    final allMods = repo?.items ?? const <ScrapedMod>[];
    final isLoading = ref.watch(isLoadingCatalog);

    final modRecords = ref.watch(modRecordsStore).valueOrNull;
    final installedMods = ref.watch(AppState.mods);
    final versionCheckState = ref
        .watch(AppState.versionCheckResults)
        .valueOrNull;
    _catalogStatusMap = _buildCatalogStatusMap(
      modRecords,
      installedMods,
      versionCheckState,
    );
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

  FilterScopeController<ScrapedMod> _buildFilters() {
    // Category order is declared and stable; the chip renderer respects
    // sortComparator when useDefaultSort is false.
    int declaredAttrIndex(String v) {
      final i = _kAttributeOrder.indexOf(v);
      return i < 0 ? _kAttributeOrder.length : i;
    }

    final groups = <FilterGroup<ScrapedMod>>[
      ChipFilterGroup<ScrapedMod>(
        id: 'attributes',
        name: 'Attributes',
        valueGetter: (_) => '',
        valuesGetter: _attributeValuesFor,
        displayNameGetter: (v) => _kAttributeLabels[v] ?? v,
        sortComparator: (a, b) =>
            declaredAttrIndex(a).compareTo(declaredAttrIndex(b)),
      ),
      CompositeFilterGroup<ScrapedMod>(
        id: 'version',
        name: 'Game Version',
        fields: [
          StringChoiceField<ScrapedMod>(
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
      ChipFilterGroup<ScrapedMod>(
        id: 'category',
        name: 'Category',
        collapsedByDefault: true,
        valueGetter: (_) => '',
        valuesGetter: (m) => m.categories ?? const <String>[],
      ),
    ];
    return FilterScopeController<ScrapedMod>(scope: _scope, groups: groups);
  }

  /// Returns the set of Attribute chip-value keys that apply to [mod].
  List<String> _attributeValuesFor(ScrapedMod mod) {
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
    final statusKey = mod.name.toLowerCase().trim();
    final status = _catalogStatusMap[statusKey];
    if (status != null) {
      result.add(kAttrInstalled);
      if (status.versionCheck?.hasUpdate == true) result.add(kAttrUpdate);
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

  StringChoiceField<ScrapedMod>? _versionChoiceField() {
    final group =
        _filters.findGroup('version') as CompositeFilterGroup<ScrapedMod>?;
    return group?.fieldById('versionBucket') as StringChoiceField<ScrapedMod>?;
  }

  CatalogPageState _processAllFilters(CatalogPageState current) {
    Iterable<ScrapedMod> items = current.allMods;

    // 1. Search
    final q = current.currentSearchQuery;
    if (q.isNotEmpty) {
      items = searchScrapedMods(items.toList(), q);
    }

    // 2. Chip groups (Attributes, Category)
    items = _filters.applyChipFilters(items);

    // 3. Non-chip groups (Version composite)
    items = _filters.applyNonChipFilters(items);

    // 4. Sort
    final sorted = sortScrapedMods(
      items.toList(),
      current.selectedSort,
      forumLookup: ref.read(forumDataByTopicId),
    );

    return current.copyWith(displayedMods: sorted);
  }

  Map<String, CatalogEntryStatus> _buildCatalogStatusMap(
    ModRecords? records,
    List<Mod> installedMods,
    VersionCheckerState? versionCheckState,
  ) {
    if (records == null) return const {};
    final modsByModId = {for (final mod in installedMods) mod.id: mod};
    final map = <String, CatalogEntryStatus>{};
    for (final record in records.records.values) {
      final catalogName = record.catalog?.name;
      if (catalogName == null) continue;
      if (record.installed == null) continue;
      final modId = record.modId;
      if (modId == null) continue;
      final mod = modsByModId[modId];
      if (mod == null) continue;
      final versionCheck = mod.updateCheck(versionCheckState);
      map[catalogName.toLowerCase().trim()] = CatalogEntryStatus(
        mod: mod,
        versionCheck: versionCheck,
      );
    }
    return map;
  }

  // ===== Public mutators =====

  void updateSearchQuery(String query) {
    state = _processAllFilters(state.copyWith(currentSearchQuery: query));
  }

  void setSort(CatalogSortKey sort) {
    state = _processAllFilters(state.copyWith(selectedSort: sort));
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
