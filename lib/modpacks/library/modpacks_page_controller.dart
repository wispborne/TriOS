import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/modpacks/library/modpack_card_data.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/modpacks/modpack_install_progress.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/notify_on_new_state.dart';
import 'package:trios/utils/search_index.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';
import 'package:trios/widgets/smart_search/search_dsl_field.dart';

part 'modpacks_page_controller.mapper.dart';

const String kModpacksPageId = 'modpacks';

@MappableEnum()
enum ModpackSortField {
  name('Name'),
  author('Author'),
  packVersion('Pack version'),
  gameVersion('Game version'),
  installedCount('Installed count');

  final String label;

  const ModpackSortField(this.label);
}

/// The parts of the Modpacks page remembered between sessions. The current
/// search, the open pack, and the editor are not.
@MappableClass()
class ModpacksPageStatePersisted with ModpacksPageStatePersistedMappable {
  final ModpackSortField sortField;
  final bool sortAscending;
  final bool showFilters;

  const ModpacksPageStatePersisted({
    this.sortField = ModpackSortField.name,
    this.sortAscending = true,
    this.showFilters = false,
  });
}

@MappableClass()
class ModpacksPageState with ModpacksPageStateMappable {
  final ModpacksPageStatePersisted persisted;

  /// One card per pack in the library, in no particular order.
  final List<ModpackCardData> allCards;

  /// The cards left after filters and search, in display order.
  final List<ModpackCardData> visibleCards;

  final String searchQuery;

  /// True until the library has been read from disk.
  final bool isLoading;

  /// The pack whose full page or editor is open. Null while the card
  /// library is showing.
  final String? openPackId;

  /// Whether [openPackId] is open in the editor rather than the full page.
  final bool isEditing;

  ModpackSortField get sortField => persisted.sortField;

  bool get sortAscending => persisted.sortAscending;

  bool get showFilters => persisted.showFilters;

  const ModpacksPageState({
    this.persisted = const ModpacksPageStatePersisted(),
    this.allCards = const [],
    this.visibleCards = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.openPackId,
    this.isEditing = false,
  });
}

/// What happened when a `.trios-modpack` file was imported.
enum ModpackImportOutcome {
  /// The pack was new and is now in the library.
  added,

  /// The library already had this exact pack.
  alreadyInLibrary,

  /// The library has a pack or draft with this ID but different contents.
  /// Nothing was changed.
  conflictsWithLibrary,

  /// The file could not be read as a modpack.
  unreadable,
}

class ModpackImportResult {
  final ModpackImportOutcome outcome;

  /// The pack the file describes, when it could be read.
  final String? packId;

  /// Why the file could not be read, for [ModpackImportOutcome.unreadable].
  final String? error;

  const ModpackImportResult(this.outcome, {this.packId, this.error});
}

final modpacksPageControllerProvider =
    NotifierProvider<ModpacksPageController, ModpacksPageState>(
      ModpacksPageController.new,
    );

class ModpacksPageController extends Notifier<ModpacksPageState>
    with NotifyOnNewState {
  static const _scope = FilterScope(kModpacksPageId);

  late final FilterScopeController<ModpackCardData> _filters;
  late final List<SearchField<ModpackCardData>> _searchFields =
      _buildSearchFields();
  late final Map<String, SearchField<ModpackCardData>> _fieldsByKey = {
    for (final field in _searchFields) field.key: field,
  };
  String _searchQuery = '';
  SearchIndex _searchIndex = {};
  List<ModpackCardData> _searchIndexCards = const [];

  FilterScope get scope => _scope;

  List<FilterGroup<ModpackCardData>> get filterGroups => _filters.groups;

  int get activeFilterCount => _filters.activeCount;

  List<SearchFieldMeta> get searchFieldsMeta =>
      _searchFields.map((field) => field.toMeta(state.allCards)).toList();

  @override
  ModpacksPageState build() {
    final persisted =
        ref.watch(appSettings.select((s) => s.modpacksPageState)) ??
        const ModpacksPageStatePersisted();

    if (stateOrNull == null) {
      _filters = _buildFilters();
      _filters.loadPersisted(ref.read(filterGroupPersistenceProvider));
    }

    final library = ref.watch(modpackStoreProvider);
    final mods = ref.watch(AppState.mods);
    final installations = ref.watch(runningModpackInstallationsProvider);

    final data = library.value ?? const ModpacksData();
    final cards = buildModpackCardData(
      data,
      installedModIds: {for (final mod in mods) mod.id},
      installations: installations,
    );

    // A pack that was deleted while open sends the page back to the library.
    final previous = stateOrNull;
    final openPackId = previous?.openPackId;
    final stillOpen =
        openPackId != null && data.allPackIds.contains(openPackId);

    return ModpacksPageState(
      persisted: persisted,
      allCards: cards,
      visibleCards: _visibleCards(cards, persisted),
      searchQuery: _searchQuery,
      isLoading: library.isLoading,
      openPackId: stillOpen ? openPackId : null,
      isEditing: stillOpen && (previous?.isEditing ?? false),
    );
  }

  FilterScopeController<ModpackCardData> _buildFilters() {
    return FilterScopeController<ModpackCardData>(
      scope: _scope,
      groups: [
        CompositeFilterGroup<ModpackCardData>(
          id: 'state',
          name: 'Show only',
          fields: [
            BoolField<ModpackCardData>(
              id: 'draft',
              label: 'Draft',
              tooltip: 'Packs that have never been saved.',
              predicate: (card) => card.isDraftOnly,
            ),
            BoolField<ModpackCardData>(
              id: 'unsaved',
              label: 'Unsaved changes',
              tooltip: 'Packs with edits that have not been saved.',
              predicate: (card) => card.hasUnsavedChanges,
            ),
            BoolField<ModpackCardData>(
              id: 'installing',
              label: 'Installing',
              tooltip: 'Packs being installed right now.',
              predicate: (card) => card.isInstalling,
            ),
            BoolField<ModpackCardData>(
              id: 'updateAvailable',
              label: 'Update available',
              tooltip: 'Packs whose update address has a newer version.',
              predicate: (card) => card.updateAvailable,
            ),
            BoolField<ModpackCardData>(
              id: 'missingMods',
              label: 'Missing mods',
              tooltip: 'Packs with at least one mod that is not installed.',
              predicate: (card) => card.missingCount > 0,
            ),
            BoolField<ModpackCardData>(
              id: 'needsSources',
              label: 'Needs sources',
              tooltip:
                  'Packs with a mod that has no download address yet, so '
                  'they cannot be shared.',
              predicate: (card) => card.needsSources,
            ),
          ],
        ),
      ],
    );
  }

  // --- Search -----------------------------------------------------------

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _refilter();
  }

  /// Adds the current search to the page's history.
  void submitSearchQuery() {
    final query = _searchQuery.trim();
    if (query.isEmpty) return;
    ref.read(appSettings.notifier).update((s) {
      final deduped = [
        query,
        ...s.modpacksSearchHistory.where((h) => h != query),
      ];
      return s.copyWith(modpacksSearchHistory: deduped.take(10).toList());
    });
  }

  void clearSearch() => updateSearchQuery('');

  // --- Filters and sorting ----------------------------------------------

  void toggleShowFilters() {
    _updatePersisted(state.persisted.copyWith(showFilters: !state.showFilters));
  }

  void setSortField(ModpackSortField field) {
    _updatePersisted(state.persisted.copyWith(sortField: field));
  }

  void toggleSortDirection() {
    _updatePersisted(
      state.persisted.copyWith(sortAscending: !state.sortAscending),
    );
  }

  void onGroupChanged(String groupId) {
    _filters.maybePersist(groupId, ref.read(filterGroupPersistenceProvider));
    _refilter();
  }

  void clearAllFilters() {
    _filters.clearAll();
    _refilter();
  }

  /// Rebuilds every card from the library and the current mod list. The
  /// online update check (phase 9) will run from here as well.
  void refresh() {
    final data = ref.read(modpackStoreProvider).value ?? const ModpacksData();
    final cards = buildModpackCardData(
      data,
      installedModIds: {for (final mod in ref.read(AppState.mods)) mod.id},
      installations: ref.read(runningModpackInstallationsProvider),
    );
    state = state.copyWith(
      allCards: cards,
      visibleCards: _visibleCards(cards, state.persisted),
    );
  }

  // --- Opening packs ------------------------------------------------------

  /// A saved pack opens on its full page; a pack that was never saved has
  /// nothing to view, so it opens in the editor.
  void openCard(ModpackCardData card) {
    if (card.isDraftOnly) {
      editPack(card.packId);
    } else {
      viewPack(card.packId);
    }
  }

  void viewPack(String packId) {
    state = state.copyWith(openPackId: packId, isEditing: false);
  }

  void editPack(String packId) {
    state = state.copyWith(openPackId: packId, isEditing: true);
  }

  /// Back to the card library. Any draft stays as it is.
  void closePack() {
    state = state.copyWith(openPackId: null, isEditing: false);
  }

  // --- Library actions ---------------------------------------------------

  /// Starts a new pack and opens it in the editor. The draft exists from
  /// this moment, so nothing typed into it is lost.
  Future<String> createNewPack() async {
    final gameVersion = ref.read(appSettings).lastStarsectorVersion;
    final draft = await ref
        .read(modpackStoreProvider.notifier)
        .createDraft(gameVersion: gameVersion);
    editPack(draft.id);
    return draft.id;
  }

  /// Removes the pack and its draft. No mods are disabled or uninstalled.
  Future<void> deletePack(String packId) async {
    await ref.read(modpackStoreProvider.notifier).deletePack(packId);
  }

  /// Copies a saved pack. The copy gets its own ID and starts at version 1.
  Future<void> duplicatePack(String packId) async {
    await ref.read(modpackStoreProvider.notifier).duplicatePack(packId);
  }

  /// Reads a `.trios-modpack` file and adds it to the library when it's new.
  ///
  /// A pack the library already has is left alone. Choosing between the two
  /// versions belongs to the incoming-pack dialog (phase 7).
  Future<ModpackImportResult> importFile(File file) async {
    try {
      final text = await file.readAsString();
      final definition = decodeModpackDefinition(text.parseJsonToMap());
      final data = ref.read(modpackStoreProvider).value ?? const ModpacksData();

      final existing = data.packs[definition.id];
      if (existing != null) {
        final identical = modpackDefinitionsAreIdentical(
          existing.definition,
          definition,
        );
        return ModpackImportResult(
          identical
              ? ModpackImportOutcome.alreadyInLibrary
              : ModpackImportOutcome.conflictsWithLibrary,
          packId: definition.id,
        );
      }
      if (data.drafts.containsKey(definition.id)) {
        return ModpackImportResult(
          ModpackImportOutcome.conflictsWithLibrary,
          packId: definition.id,
        );
      }

      await ref
          .read(modpackStoreProvider.notifier)
          .saveIncomingDefinition(definition);
      return ModpackImportResult(
        ModpackImportOutcome.added,
        packId: definition.id,
      );
    } on ModpackFormatException catch (e) {
      return ModpackImportResult(
        ModpackImportOutcome.unreadable,
        error: e.message,
      );
    } catch (e, stacktrace) {
      Fimber.w(
        "Could not import modpack file ${file.path}",
        ex: e,
        stacktrace: stacktrace,
      );
      return ModpackImportResult(
        ModpackImportOutcome.unreadable,
        error: e.toString(),
      );
    }
  }

  // --- Internals ----------------------------------------------------------

  void _refilter() {
    state = state.copyWith(
      visibleCards: _visibleCards(state.allCards, state.persisted),
      searchQuery: _searchQuery,
    );
  }

  void _updatePersisted(ModpacksPageStatePersisted persisted) {
    ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(modpacksPageState: persisted));
  }

  List<ModpackCardData> _visibleCards(
    List<ModpackCardData> cards,
    ModpacksPageStatePersisted persisted,
  ) {
    var visible = _filters.applyChipFilters(cards);
    visible = _filters.applyNonChipFilters(visible);
    visible = _applySearch(visible);
    return sortCards(visible, persisted.sortField, persisted.sortAscending);
  }

  List<ModpackCardData> _applySearch(List<ModpackCardData> cards) {
    if (_searchQuery.trim().isEmpty) return cards;
    return SearchField.applyQuery(
      cards,
      _searchQuery,
      _fieldsByKey,
      _searchIndexFor(cards),
      (card) => card.packId,
    );
  }

  SearchIndex _searchIndexFor(List<ModpackCardData> cards) {
    if (!identical(cards, _searchIndexCards)) {
      _searchIndexCards = cards;
      _searchIndex = {
        for (final card in cards)
          card.packId: [
            card.name.toLowerCase(),
            if (card.author != null) card.author!.toLowerCase(),
            if (card.description != null) card.description!.toLowerCase(),
            if (card.gameVersion != null) card.gameVersion!.toLowerCase(),
          ].join(searchIndexSeparator),
      };
    }
    return _searchIndex;
  }

  /// Sorts cards by [field]. A pack being installed always comes first so
  /// its progress stays in view; the rest are ordered by [field], with
  /// blanks last and ties broken by name.
  static List<ModpackCardData> sortCards(
    List<ModpackCardData> cards,
    ModpackSortField field,
    bool ascending,
  ) {
    int compareValues(ModpackCardData a, ModpackCardData b) {
      final va = _sortValue(a, field);
      final vb = _sortValue(b, field);
      if (va == null && vb == null) return 0;
      if (va == null) return 1;
      if (vb == null) return -1;
      final result = va.compareTo(vb);
      return ascending ? result : -result;
    }

    return [...cards]..sort((a, b) {
      if (a.isInstalling != b.isInstalling) return a.isInstalling ? -1 : 1;
      final byField = compareValues(a, b);
      if (byField != 0) return byField;
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) return byName;
      return a.packId.compareTo(b.packId);
    });
  }

  static Comparable? _sortValue(ModpackCardData card, ModpackSortField field) {
    return switch (field) {
      ModpackSortField.name => card.name.toLowerCase(),
      ModpackSortField.author => card.author?.toLowerCase(),
      ModpackSortField.packVersion => card.packVersion,
      ModpackSortField.gameVersion => card.gameVersion?.toLowerCase(),
      ModpackSortField.installedCount => card.installedCount,
    };
  }

  static List<SearchField<ModpackCardData>> _buildSearchFields() {
    SearchField<ModpackCardData> flag(
      String key,
      String description,
      bool Function(ModpackCardData card) getter,
    ) => SearchField<ModpackCardData>(
      key: key,
      description: '$description (true/false)',
      valueSuggestions: (_) => ['true', 'false'],
      matches: (card, op, value) {
        if (op != DslOperator.equals) return false;
        final wanted = value.toLowerCase() == 'true';
        return getter(card) == wanted;
      },
    );

    return [
      SearchField.string('name', 'Pack name', (card) => card.name),
      SearchField.string('author', 'Pack author', (card) => card.author),
      SearchField.numeric(
        'version',
        'Saved pack version',
        (card) => card.packVersion,
      ),
      SearchField.string(
        'gameversion',
        'Starsector version label',
        (card) => card.gameVersion,
      ),
      SearchField.numeric(
        'installed',
        'Number of installed mods',
        (card) => card.installedCount,
      ),
      SearchField.numeric(
        'missing',
        'Number of missing mods',
        (card) => card.missingCount,
      ),
      SearchField.numeric(
        'mods',
        'Number of mods in the pack',
        (card) => card.totalCount,
      ),
      flag('draft', 'Never saved', (card) => card.isDraftOnly),
      flag('unsaved', 'Has unsaved changes', (card) => card.hasUnsavedChanges),
      flag('update', 'Has an update available', (card) => card.updateAvailable),
      flag('failed', 'Has a failed install', (card) => card.hasFailures),
      flag('installing', 'Is installing', (card) => card.isInstalling),
    ];
  }
}
