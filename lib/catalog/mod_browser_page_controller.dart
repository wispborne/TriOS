import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/forum_data_manager.dart';
import 'package:trios/catalog/mod_browser_manager.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
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
import 'package:trios/utils/extensions.dart';
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
  final List<ScrapedMod> allMods;
  final List<ScrapedMod> displayedMods;
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

  late final FilterScopeController<ScrapedMod> _filters;

  Map<String, CatalogEntryStatus> _catalogStatusMap = const {};
  Map<String, Set<String>> _versionGroupOptions = const {};
  bool _hasSeededVersionDefault = false;

  FilterScope get scope => _scope;

  List<FilterGroup<ScrapedMod>> get filterGroups => _filters.groups;

  int get activeFilterCount => _filters.activeCount;

  /// Number of installed mods with an available update. Backs the toolbar
  /// "N updates" pill. Counts distinct mods, since one installed mod can be
  /// keyed under several catalog entries (name, id, synthesized add-on).
  int get updatesCount => _catalogStatusMap.values
      .where((s) => s.versionCheck?.hasUpdate == true)
      .map((s) => s.mod.id)
      .toSet()
      .length;

  /// Lookup of catalog-mod installation/update status keyed by
  /// `mod.name.toLowerCase().trim()`. Used by card UIs to decorate installed
  /// mods; null when the mod is not installed.
  CatalogEntryStatus? statusForModName(String modName) =>
      _catalogStatusMap[modName.toLowerCase().trim()];

  @override
  CatalogPageState build() {
    final repo = ref.watch(browseModsNotifierProvider).value;
    final realMods = repo?.items ?? const <ScrapedMod>[];
    final isLoading = ref.watch(isLoadingCatalog);

    // Mods bundled inside another mod's forum thread (add-ons, separate mods)
    // become their own searchable cards. Watched so they appear once the forum
    // data loads.
    final forumLookup = ref.watch(forumDataByTopicId);
    final allMods = _withSynthesizedAddonEntries(realMods, forumLookup);

    final modRecords = ref.watch(modRecordsStore).valueOrNull;
    final installedMods = ref.watch(AppState.mods);
    final versionCheckState = ref
        .watch(AppState.versionCheckResults)
        .valueOrNull;
    _catalogStatusMap = _buildCatalogStatusMap(
      allMods,
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
      CompositeFilterGroup<ScrapedMod>(
        id: 'status',
        name: 'Status',
        fields: [
          StringChoiceField<ScrapedMod>(
            id: 'installed',
            label: 'Installed',
            allLabel: 'Both Installed & Available',
            options: const ['installed', 'available'],
            optionLabel: (v) =>
                v == 'installed' ? 'Only Installed' : 'Not Installed',
            predicate: (mod, selected) {
              if (selected == null) return true;
              final isInstalled = _catalogStatusMap
                  .containsKey(mod.name.toLowerCase().trim());
              return selected == 'installed' ? isInstalled : !isInstalled;
            },
          ),
          BoolField<ScrapedMod>(
            id: 'hasUpdate',
            label: 'Has Update',
            badgeCount: () => updatesCount,
            predicate: (mod) {
              final status =
                  _catalogStatusMap[mod.name.toLowerCase().trim()];
              return status?.versionCheck?.hasUpdate == true;
            },
          ),
        ],
      ),
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
        collapsedByDefault: false,
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
      ascending: current.sortAscending,
      forumLookup: ref.read(forumDataByTopicId),
    );

    return current.copyWith(displayedMods: sorted);
  }

  /// Maps a catalog entry (keyed by `mod.name.toLowerCase().trim()`) to its
  /// installed mod + update status.
  ///
  /// Matches scraped mods to installed mods directly — by forum thread id,
  /// then exact name, then fuzzy alphanumeric name — so a freshly installed
  /// mod flips to "Installed" immediately, without waiting for the mod-records
  /// store to attach a catalog source (which can miss when the installed mod's
  /// name differs from the catalog's). Record-based catalog matches (including
  /// the user's manual source overrides) fill any remaining gaps.
  Map<String, CatalogEntryStatus> _buildCatalogStatusMap(
    List<ScrapedMod> scrapedMods,
    ModRecords? records,
    List<Mod> installedMods,
    VersionCheckerState? versionCheckState,
  ) {
    final map = <String, CatalogEntryStatus>{};

    CatalogEntryStatus statusFor(Mod mod) => CatalogEntryStatus(
      mod: mod,
      versionCheck: mod.updateCheck(versionCheckState),
    );

    // Index installed mods by the signals a catalog entry can match on.
    final byThreadId = <String, Mod>{};
    final byName = <String, Mod>{};
    final byFuzzy = <String, Mod>{};
    for (final mod in installedMods) {
      final variant = mod.findHighestVersion;
      final name = variant?.modInfo.name;
      if (name != null && name.trim().isNotEmpty) {
        byName.putIfAbsent(name.toLowerCase().trim(), () => mod);
        byFuzzy.putIfAbsent(name.alphanumericLower(), () => mod);
      }
      byFuzzy.putIfAbsent(mod.id.alphanumericLower(), () => mod);
      final threadId = variant?.versionCheckerInfo?.modThreadId;
      if (threadId != null) byThreadId.putIfAbsent(threadId, () => mod);
    }

    for (final scraped in scrapedMods) {
      final key = scraped.name.toLowerCase().trim();
      if (key.isEmpty) continue;
      final threadId = extractForumThreadId(scraped.urls?[ModUrlType.Forum]);
      final mod =
          (threadId != null ? byThreadId[threadId] : null) ??
          byName[key] ??
          byFuzzy[scraped.name.alphanumericLower()];
      if (mod != null) map[key] = statusFor(mod);
    }

    // Record-based catalog matches (with user overrides) fill any gaps.
    if (records != null) {
      final modsByModId = {for (final mod in installedMods) mod.id: mod};
      for (final record in records.records.values) {
        final catalogName = record.catalog?.name;
        if (catalogName == null) continue;
        if (record.installed == null) continue;
        final modId = record.modId;
        if (modId == null) continue;
        final mod = modsByModId[modId];
        if (mod == null) continue;
        map.putIfAbsent(catalogName.toLowerCase().trim(), () => statusFor(mod));
      }
    }

    return map;
  }

  /// Adds synthesized cards for mods that only live inside another mod's forum
  /// thread. For each thread that lists more than one mod, every mod that
  /// doesn't already have its own catalog entry becomes a synthesized card,
  /// marked with the thread title so the card can show `part of <thread>`.
  ///
  /// A thread's "main" mod isn't special-cased: the scraped catalog entry that
  /// points at the thread often has a different name (e.g. it's a different mod
  /// in the same thread), so relying on the name match below is what keeps the
  /// real main mod from being both listed and synthesized — and stops a main
  /// mod with no catalog entry of its own from going missing.
  ///
  /// Dedupes synthesized names across threads (first thread wins), so a mod
  /// that appears in several threads isn't duplicated.
  List<ScrapedMod> _withSynthesizedAddonEntries(
    List<ScrapedMod> realMods,
    Map<int, ForumModIndex> forumLookup,
  ) {
    if (realMods.isEmpty || forumLookup.isEmpty) return realMods;

    final existingNames = {
      for (final mod in realMods)
        if (mod.name.trim().isNotEmpty) mod.name.toLowerCase().trim(),
    };
    final synthesizedNames = <String>{};
    final synthesized = <ScrapedMod>[];

    for (final mod in realMods) {
      final forumUrl = mod.urls?[ModUrlType.Forum];
      final topicId = extractForumTopicId(forumUrl);
      if (topicId == null) continue;
      final index = forumLookup[topicId];
      final llm = index?.llm;
      if (index == null || llm == null || llm.mods.length < 2) continue;

      for (final llmMod in llm.mods) {
        final key = llmMod.name.toLowerCase().trim();
        if (key.isEmpty) continue;
        if (existingNames.contains(key)) continue;
        if (!synthesizedNames.add(key)) continue;

        synthesized.add(
          ScrapedMod(
            name: llmMod.name,
            summary: llmMod.extras?.summary?.sentence,
            description: llmMod.extras?.summary?.paragraph,
            // Prefer the thread's game version; fall back to the parent mod's
            // so add-ons stay visible under the default Game Version filter
            // even when the thread itself lists no version.
            gameVersionReq: index.gameVersion ?? mod.gameVersionReq,
            authorsList: mod.authorsList,
            urls: {ModUrlType.Forum: ?forumUrl},
            partOfThreadTitle: index.title,
          ),
        );
      }
    }

    if (synthesized.isEmpty) return realMods;
    return [...realMods, ...synthesized];
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
