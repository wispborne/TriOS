import 'dart:math' show Random;

import 'package:material_ui/material_ui.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/utils/notify_on_new_state.dart';
import 'package:trios/catalog/catalog_links.dart';
import 'package:trios/catalog/catalog_manager.dart';
import 'package:trios/catalog/catalog_requires.dart';
import 'package:trios/catalog/catalog_text_search.dart';
import 'package:trios/catalog/models/ai_summary_mode.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/widgets/ai_use_filter_controls.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/mod_metadata.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/smart_search/search_dsl_field.dart';

part 'catalog_page_controller.mapper.dart';

const String kCatalogPageId = 'catalog';

/// Chip-value keys for the Catalog "Attributes" filter group.
const String kAttrDownload = 'download';
const String kAttrDiscord = 'discord';
const String kAttrIndex = 'index';
const String kAttrForum = 'forum';
const String kAttrWip = 'wip';
const String kAttrArchived = 'archived';
const String kAttrSourceCode = 'sourceCode';
const String kAttrSafeToAdd = 'safeToAdd';
const String kAttrTool = 'tool';

const List<String> _kAttributeOrder = [
  kAttrDownload,
  kAttrSourceCode,
  kAttrSafeToAdd,
  kAttrTool,
  kAttrDiscord,
  kAttrIndex,
  kAttrForum,
  kAttrWip,
  kAttrArchived,
];

const Map<String, String> _kAttributeLabels = {
  kAttrDownload: 'Has Download Link',
  kAttrSourceCode: 'Has Source Code',
  kAttrSafeToAdd: 'Safe to add mid-game',
  kAttrTool: 'Tool',
  kAttrDiscord: 'Discord',
  kAttrIndex: 'Index',
  kAttrForum: 'Forum',
  kAttrWip: 'WIP',
  kAttrArchived: 'Archived',
};

@MappableClass()
class CatalogPageStatePersisted with CatalogPageStatePersistedMappable {
  final bool showFilters;

  /// The [CatalogSortKey] name the user last picked. Never Best match.
  final String? sortKey;
  final bool? sortAscending;

  const CatalogPageStatePersisted({
    this.showFilters = false,
    this.sortKey,
    this.sortAscending,
  });
}

/// A sort and its direction.
typedef CatalogSavedSort = ({CatalogSortKey key, bool ascending});

/// The saved sort in [saved]. A missing or unknown name, or Best match, gives
/// the default: Popular, most first. A saved sort with no direction uses its
/// own default direction.
CatalogSavedSort savedSort(CatalogPageStatePersisted? saved) {
  final key = CatalogSortKey.values.asNameMap()[saved?.sortKey];
  if (key == null || key == CatalogSortKey.bestMatch) {
    const fallback = CatalogPageState();
    return (key: fallback.selectedSort, ascending: fallback.sortAscending);
  }
  return (key: key, ascending: saved?.sortAscending ?? key.defaultAscending);
}

/// [state]'s saved form with its sort written in. While Best match is
/// showing, the sort it will go back to is saved instead.
CatalogPageStatePersisted withSortSaved(CatalogPageState state) {
  final isBestMatch = state.selectedSort == CatalogSortKey.bestMatch;
  final sort = isBestMatch ? state.sortBeforeSearch : state.selectedSort;
  if (sort == null) return state.persisted;
  return state.persisted.copyWith(
    sortKey: sort.name,
    sortAscending: isBestMatch
        ? state.sortAscendingBeforeSearch
        : state.sortAscending,
  );
}

@MappableClass()
class CatalogPageState with CatalogPageStateMappable {
  final CatalogPageStatePersisted persisted;
  @MappableField(hook: SkipSerializationHook())
  final List<CatalogMod> allMods;
  @MappableField(hook: SkipSerializationHook())
  final List<CatalogMod> displayedMods;
  final String currentSearchQuery;
  final CatalogSortKey selectedSort;
  final bool sortAscending;

  /// The sort in use before Best match took over, put back when the search
  /// is cleared.
  final CatalogSortKey? sortBeforeSearch;
  final bool sortAscendingBeforeSearch;

  /// True once the user picks a sort by hand while there is search text. Their
  /// pick outranks the switch to Best match.
  final bool sortChosenWhileSearching;
  final bool isLoading;

  /// For each chip group that shows counts, the searched mods that pass every
  /// other group. A chip's count is how many of these have its value.
  @MappableField(hook: SkipSerializationHook())
  final Map<String, List<CatalogMod>> countItemsByGroup;

  bool get showFilters => persisted.showFilters;

  const CatalogPageState({
    this.persisted = const CatalogPageStatePersisted(),
    this.allMods = const [],
    this.displayedMods = const [],
    this.currentSearchQuery = '',
    this.selectedSort = CatalogSortKey.mostViewed,
    this.sortAscending = false,
    this.sortBeforeSearch,
    this.sortAscendingBeforeSearch = false,
    this.sortChosenWhileSearching = false,
    this.isLoading = false,
    this.countItemsByGroup = const {},
  });
}

/// Whether the Catalog should present [mod] as having an update.
///
/// True when there's a newer version and the user hasn't muted it — either by
/// muting the mod outright or by muting this one version. Muted mods are left
/// out of both the "Has Update" filter and the count on its badge, the same
/// way the Mods page leaves them out of its Updates section.
bool hasUpdateToShowInCatalog(
  Mod mod,
  VersionCheckerState? versionCheckState,
  ModsMetadata? modsMetadata,
) {
  final comparison = mod.updateCheck(versionCheckState);
  if (comparison?.hasUpdate != true) return false;

  final isMuted =
      modsMetadata
          ?.getMergedModMetadata(mod.id)
          ?.isUpdateHidden(comparison?.remoteVersionString) ==
      true;
  return !isMuted;
}

/// [state] with the search text set to [query], and the sort switched the way
/// typing switches it.
///
/// - Going from no text to some text picks Best match, unless the user already
///   picked a sort by hand during this search. The sort before is kept aside.
/// - Clearing the text puts a Best match sort back to the kept sort, with its
///   direction. A sort picked by hand stays.
CatalogPageState withSearchQuery(CatalogPageState state, String query) {
  final wasSearching = state.currentSearchQuery.trim().isNotEmpty;
  final searchingNow = query.trim().isNotEmpty;
  var next = state.copyWith(currentSearchQuery: query);

  if (searchingNow && !wasSearching && !state.sortChosenWhileSearching) {
    next = next.copyWith(
      sortBeforeSearch: state.selectedSort,
      sortAscendingBeforeSearch: state.sortAscending,
      selectedSort: CatalogSortKey.bestMatch,
      sortAscending: CatalogSortKey.bestMatch.defaultAscending,
    );
  } else if (!searchingNow && wasSearching) {
    if (state.selectedSort == CatalogSortKey.bestMatch) {
      const fallback = CatalogPageState();
      final kept = state.sortBeforeSearch;
      next = next.copyWith(
        selectedSort: kept ?? fallback.selectedSort,
        sortAscending: kept != null
            ? state.sortAscendingBeforeSearch
            : fallback.sortAscending,
      );
    }
    next = next.copyWith(sortBeforeSearch: null, sortChosenWhileSearching: false);
  }
  return next;
}

/// [state] with [sort] picked by the user. A pick made while there is search
/// text is kept for the rest of that search.
CatalogPageState withSortChosen(CatalogPageState state, CatalogSortKey sort) {
  return state.copyWith(
    selectedSort: sort,
    sortAscending: sort.defaultAscending,
    sortChosenWhileSearching: state.currentSearchQuery.trim().isNotEmpty,
  );
}

class CatalogEntryStatus {
  final Mod mod;
  final VersionCheckComparison? versionCheck;

  const CatalogEntryStatus({required this.mod, this.versionCheck});
}

class CatalogPageController extends Notifier<CatalogPageState>
    with NotifyOnNewState {
  static const FilterScope _scope = FilterScope(kCatalogPageId);

  late final FilterScopeController<CatalogMod> _filters;

  CatalogLinks _links = CatalogLinks(const []);
  VersionCheckerState? _versionCheckState;
  ModsMetadata? _modsMetadata;
  Map<String, Set<String>> _versionGroupOptions = const {};
  bool _hasSeededVersionDefault = false;

  /// Whether the AI sentence is searched. Off while AI summaries can't be
  /// shown, so a match never comes from text the user has turned off.
  bool _searchAiText = false;
  List<String> _authorOptions = const [];
  List<String> _categoryOptions = const [];

  /// Each mod's Dependencies chip values, and the chips' labels and counts.
  RequiresChipInfo _requiresInfo = const RequiresChipInfo();

  /// The mod list the options, Dependencies data and slider ranges were last
  /// worked out from. They only depend on the mods, so other changes that
  /// rebuild the controller skip them.
  List<CatalogMod>? _derivedFrom;

  /// Sets the Random sort's order. Picked once per app run, so the order
  /// holds across tab switches.
  int _shuffleSeed = Random().nextInt(1 << 32);

  /// The fields the search box suggests. The plural and old spellings
  /// (`authors`, `gameversion`, ...) work when typed but are left out to keep
  /// the list short.
  late final List<SearchFieldMeta> searchFieldsMeta = [
    SearchFieldMeta(
      key: 'name',
      description: 'Mod name',
      valueSuggestions: () => const [],
    ),
    SearchFieldMeta(
      key: 'author',
      description: 'Author, including their other names',
      valueSuggestions: () => _authorOptions,
    ),
    SearchFieldMeta(
      key: 'category',
      description: 'Category',
      valueSuggestions: () => _categoryOptions,
    ),
    SearchFieldMeta(
      key: 'version',
      description: 'Game version, e.g. 0.98',
      valueSuggestions: () => _versionGroupOptions.keys.toList(),
    ),
    SearchFieldMeta(
      key: 'modversion',
      description: 'Mod version',
      valueSuggestions: () => const [],
    ),
    SearchFieldMeta(
      key: 'from',
      description: 'Where the mod was posted',
      valueSuggestions: () => const ['forum', 'index', 'discord', 'nexus'],
    ),
    SearchFieldMeta(
      key: 'url',
      description: 'Any of the mod\'s links',
      valueSuggestions: () => const [],
    ),
    SearchFieldMeta(
      key: 'summary',
      description: 'The mod\'s short summary',
      valueSuggestions: () => const [],
    ),
    SearchFieldMeta(
      key: 'has',
      description: 'Has a source code link, a download link, or AI use',
      valueSuggestions: () => const ['source', 'download', 'ai'],
    ),
    SearchFieldMeta(
      key: 'is',
      description: 'Is a work in progress, a tool, safe to add to a save, '
          'or made without AI',
      valueSuggestions: () => const ['wip', 'tool', 'addable', 'noai'],
    ),
  ];

  FilterScope get scope => _scope;

  List<FilterGroup<CatalogMod>> get filterGroups => _filters.groups;

  int get activeFilterCount => _filters.activeCount;

  int get updatesCount => _links.all
      .where((l) => _hasUpdateToShow(l.mod))
      .map((l) => l.mod.id)
      .toSet()
      .length;

  /// How many installed mods have an update the user has muted. Shown beside
  /// the "Has Update" count so a muted mod isn't simply missing with no
  /// explanation, the same as the Dashboard's updates header.
  int get mutedUpdatesCount => _links.all
      .where(
        (l) =>
            l.mod.updateCheck(_versionCheckState)?.hasUpdate == true &&
            !_hasUpdateToShow(l.mod),
      )
      .map((l) => l.mod.id)
      .toSet()
      .length;

  bool _hasUpdateToShow(Mod mod) =>
      hasUpdateToShowInCatalog(mod, _versionCheckState, _modsMetadata);

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

    final allMods = ref.watch(catalogModsProvider);
    _links = ref.watch(catalogLinksProvider);
    _versionCheckState = ref
        .watch(AppState.versionCheckResults)
        .value;
    // Watched so the update count and the "Has Update" filter recompute as
    // soon as a mute is toggled.
    _modsMetadata = ref.watch(AppState.modsMetadata).value;
    _searchAiText =
        ref.watch(effectiveCatalogAiSummaryModeProvider) != AiSummaryMode.never;
    final modsChanged = !identical(_derivedFrom, allMods);
    if (modsChanged) {
      _derivedFrom = allMods;
      _versionGroupOptions = extractVersionGroups(allMods);
      _categoryOptions = extractCategories(allMods);
      _authorOptions = _extractAuthors(allMods);
      _requiresInfo = RequiresChipInfo.from(allMods);
    }

    if (stateOrNull == null) {
      _filters = _buildFilters();
      final persistence = ref.read(filterGroupPersistenceProvider);
      _filters.loadPersisted(persistence);
    }

    _filters.applyPendingChipMerge(allMods);
    // With no extras file, no mod has a release date, so the Last release
    // slider has no data and hides itself.
    if (modsChanged) _filters.updateRanges(allMods);

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

    if (!_hasSeededVersionDefault && _versionGroupOptions.isNotEmpty) {
      if (versionField != null && versionField.selected == null) {
        versionField.setSelected(_versionGroupOptions.keys.first);
      }
      _hasSeededVersionDefault = true;
    }

    final saved = ref.read(appSettings).catalogPageState;
    final savedSortChoice = savedSort(saved);
    final initialState =
        (stateOrNull ??
                CatalogPageState(
                  persisted: saved ?? const CatalogPageStatePersisted(),
                  selectedSort: savedSortChoice.key,
                  sortAscending: savedSortChoice.ascending,
                ))
            .copyWith(allMods: allMods, isLoading: isLoading);

    return _processAllFilters(initialState);
  }

  FilterScopeController<CatalogMod> _buildFilters() {
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
              final isInstalled = mod.installedMod != null;
              return selected == 'installed' ? isInstalled : !isInstalled;
            },
          ),
          BoolField<CatalogMod>(
            id: 'hasUpdate',
            label: 'Has Update',
            badgeCount: () => updatesCount,
            labelSuffix: (context) {
              final muted = mutedUpdatesCount;
              return muted > 0 ? _MutedUpdatesCount(count: muted) : null;
            },
            predicate: (mod) {
              final installedMod = mod.installedMod;
              return installedMod != null && _hasUpdateToShow(installedMod);
            },
          ),
        ],
      ),
      ChipFilterGroup<CatalogMod>(
        id: 'attributes',
        name: 'Attributes',
        valueGetter: (_) => '',
        valuesGetter: (mod) => mod.attributeKeys,
        displayNameGetter: (v) => _kAttributeLabels[v] ?? v,
        sortComparator: (a, b) =>
            declaredAttrIndex(a).compareTo(declaredAttrIndex(b)),
        explicitNoChecks: {
          kAttrSafeToAdd: (mod) =>
              mod.canAddToSaveAnswer == CatalogSaveAnswer.no,
        },
        chipTooltipGetter: (value, state) => switch (value) {
          kAttrSafeToAdd when state == false =>
            'Only mods the author says are not safe to add mid-game.',
          kAttrSafeToAdd =>
            'Only mods the author says are safe to add mid-game.',
          kAttrTool =>
            'Programs that run outside the game, like editors and mod '
                'managers.',
          _ => null,
        },
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
              final ver = mod.entry.gameVersionReq;
              return ver != null && bucket.contains(ver);
            },
          ),
        ],
      ),
      ChipFilterGroup<CatalogMod>(
        id: 'category',
        name: 'Category',
        collapsedByDefault: false,
        valueGetter: (_) => '',
        valuesGetter: (m) => m.categories,
      ),
      ChipFilterGroup<CatalogMod>(
        id: 'requires',
        name: 'Dependencies',
        collapsedByDefault: true,
        valueGetter: (_) => '',
        valuesGetter: (m) => _requiresInfo.keysFor(m),
        displayNameGetter: (v) => _requiresInfo.labelFor(v),
        sortComparator: (a, b) => _requiresInfo.compare(a, b),
        chipTooltipGetter: (value, state) => value == kRequiresStandalone
            ? 'Mods that need no other mods.'
            : null,
      ),
      AiUseFilterGroup(id: 'aiUse', name: 'AI use'),
      RangeFilterGroup<CatalogMod>(
        id: 'posted',
        name: 'Posted',
        valueGetter: (m) => m.postedDay,
        valueLabel: _formatDay,
      ),
      RangeFilterGroup<CatalogMod>(
        id: 'edited',
        name: 'Last edited',
        valueGetter: (m) => m.editedDay,
        valueLabel: _formatDay,
        tooltip: "The post's last edit time (or, if not edited, the post "
            'time).',
      ),
      RangeFilterGroup<CatalogMod>(
        id: 'released',
        name: 'Last release',
        valueGetter: (m) => m.lastReleaseDay,
        valueLabel: _formatDay,
        tooltip: 'Note: Release tracking can be unreliable.',
      ),
    ];
    return FilterScopeController<CatalogMod>(
      scope: _scope,
      groups: groups,
    );
  }

  static final DateFormat _dayFormat = DateFormat('d MMM y');

  /// A day number from the date sliders, as e.g. "14 Mar 2024".
  static String _formatDay(num day) =>
      _dayFormat.format(dateFromCatalogDayNumber(day));

  /// Every author, once each regardless of case, sorted.
  static List<String> _extractAuthors(List<CatalogMod> mods) {
    final byLowercase = <String, String>{};
    for (final mod in mods) {
      for (final author in mod.entry.getAuthors()) {
        final trimmed = author.trim();
        if (trimmed.isEmpty) continue;
        byLowercase.putIfAbsent(trimmed.toLowerCase(), () => trimmed);
      }
    }
    return byLowercase.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  StringChoiceField<CatalogMod>? _versionChoiceField() {
    final group = _filters.findGroup('version')
        as CompositeFilterGroup<CatalogMod>?;
    return group?.fieldById('versionBucket')
        as StringChoiceField<CatalogMod>?;
  }

  CatalogPageState _processAllFilters(CatalogPageState current) {
    final search = searchCatalogMods(
      current.allMods,
      current.currentSearchQuery,
      searchAiText: _searchAiText,
    );
    final filtered = _filters.applyWithCountItems(search.mods);

    final sorted = sortCatalogMods(
      filtered.matching,
      current.selectedSort,
      ascending: current.sortAscending,
      scores: search.scores,
      shuffleSeed: _shuffleSeed,
    );

    return current.copyWith(
      displayedMods: sorted,
      countItemsByGroup: filtered.countItemsByGroup,
    );
  }

  // ===== Public mutators =====

  void updateSearchQuery(String query) {
    state = _processAllFilters(withSearchQuery(state, query));
  }

  void setSort(CatalogSortKey sort) {
    _setStateAndSaveSort(withSortChosen(state, sort));
  }

  void toggleSortDirection() {
    _setStateAndSaveSort(state.copyWith(sortAscending: !state.sortAscending));
  }

  /// Picks a new Random order.
  void shuffle() {
    _shuffleSeed = Random().nextInt(1 << 32);
    state = _processAllFilters(state);
  }

  void _setStateAndSaveSort(CatalogPageState next) {
    final saved = next.copyWith(persisted: withSortSaved(next));
    state = _processAllFilters(saved);
    _persistUiState(saved);
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
            (curr) => curr.copyWith(catalogPageState: s.persisted),
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

/// "+ 3 🔕" shown after the "Has Update" count, saying how many mods with an
/// update were left out because the user muted them. Draws nothing when none
/// are muted. Worded and shaped like the Dashboard's updates header.
class _MutedUpdatesCount extends StatelessWidget {
  final int count;

  const _MutedUpdatesCount({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MovingTooltipWidget.text(
      message: "$count muted update${count == 1 ? '' : 's'}",
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Text("+ $count", style: theme.textTheme.labelMedium),
          Icon(
            Icons.notifications_off,
            size: 14,
            color: theme.iconTheme.color,
          ),
        ],
      ),
    );
  }
}
