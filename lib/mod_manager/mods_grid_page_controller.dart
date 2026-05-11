import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stringr/stringr.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/mod_search.dart';
import 'package:trios/widgets/smart_search/search_dsl_field.dart';

class ModsGridSearchController extends Notifier<ModsGridSearchState> {
  late final List<SearchField<Mod>> _searchFields;
  late final Map<String, SearchField<Mod>> _fieldsByKey;

  List<SearchFieldMeta> get searchFieldsMeta =>
      _searchFields.map((f) => f.toMeta(state.allMods)).toList();

  @override
  ModsGridSearchState build() {
    final allMods = ref.watch(AppState.mods);

    if (stateOrNull == null) {
      _searchFields = _buildSearchFields();
      _fieldsByKey = {for (final f in _searchFields) f.key: f};
    }

    final searchIndices = _updateSearchIndices(allMods);

    final initial = (stateOrNull ?? const ModsGridSearchState()).copyWith(
      allMods: allMods,
      modSearchIndices: searchIndices,
    );

    return _applySearch(initial);
  }

  void updateSearchQuery(String query) {
    state = _applySearch(state.copyWith(currentSearchQuery: query));
  }

  void submitSearchQuery() {
    final query = state.currentSearchQuery.trim();
    if (query.isEmpty) return;
    ref.read(appSettings.notifier).update((s) {
      final deduped = [query, ...s.modsSearchHistory.where((h) => h != query)];
      return s.copyWith(modsSearchHistory: deduped.take(10).toList());
    });
  }

  ModsGridSearchState _applySearch(ModsGridSearchState current) {
    final filtered = SearchField.applyQuery(
      current.allMods,
      current.currentSearchQuery,
      _fieldsByKey,
      current.modSearchIndices,
      (m) => m.id,
    );
    return current.copyWith(filteredMods: filtered);
  }

  Map<String, List<String>> _updateSearchIndices(List<Mod> allMods) {
    final currentIndices = stateOrNull?.modSearchIndices ?? {};
    final currentIds = allMods.map((m) => m.id).toSet();
    final cachedIds = currentIndices.keys.toSet();

    final result = Map<String, List<String>>.from(currentIndices);
    for (final id in cachedIds.difference(currentIds)) {
      result.remove(id);
    }

    final newMods = allMods.where((m) => !cachedIds.contains(m.id));
    for (final mod in newMods) {
      result[mod.id] = _buildModSearchIndex(mod);
    }
    return result;
  }

  /// Builds a search index for a mod that includes fuzzy-matching terms
  /// (slugified name, name parts, acronym, author aliases).
  List<String> _buildModSearchIndex(Mod mod) {
    final variant = mod.findFirstEnabledOrHighestVersion;
    if (variant == null) return [];
    final info = variant.modInfo;
    final values = <String>[];

    void add(String? v) {
      if (v != null && v.isNotEmpty) values.add(v.toLowerCase());
    }

    add(info.name);
    add(info.id);
    add(info.author);
    add(info.version?.toString());
    add(info.gameVersion);
    add(info.originalGameVersion);
    add(info.description);
    add(mod.hasEnabledVariant ? 'true' : 'false');

    final alphaName = info.name?.slugify();
    if (alphaName != null && alphaName.isNotEmpty) {
      add(alphaName);
      final parts = alphaName.split('-').where((p) => p.isNotEmpty).toList();
      for (final part in parts) {
        add(part);
      }
      if (parts.length > 1) {
        add(parts.map((p) => p.substring(0, 1)).join());
      }
    }

    if (info.author != null) {
      for (final alias in getModAuthorAliases(info.author!)) {
        add(alias);
      }
    }

    return values;
  }

  List<SearchField<Mod>> _buildSearchFields() {
    return [
      SearchField<Mod>(
        key: 'name',
        description: 'Mod name',
        valueSuggestions: (mods) => mods
            .map((m) =>
                m.findFirstEnabledOrHighestVersion?.modInfo.name?.toLowerCase())
            .whereType<String>()
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort(),
        matches: (mod, op, value) {
          if (op != DslOperator.equals) return false;
          final name =
              mod.findFirstEnabledOrHighestVersion?.modInfo.name?.toLowerCase();
          return name?.contains(value.toLowerCase()) ?? false;
        },
      ),
      SearchField.string(
        'id',
        'Mod ID',
        (m) => m.id,
      ),
      SearchField<Mod>(
        key: 'author',
        description: 'Author name (includes aliases)',
        valueSuggestions: (mods) => mods
            .map((m) => m.findFirstEnabledOrHighestVersion?.modInfo.author
                ?.toLowerCase())
            .whereType<String>()
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort(),
        matches: (mod, op, value) {
          if (op != DslOperator.equals) return false;
          final author =
              mod.findFirstEnabledOrHighestVersion?.modInfo.author;
          if (author == null) return false;
          final lowerValue = value.toLowerCase();
          if (author.toLowerCase().contains(lowerValue)) return true;
          return getModAuthorAliases(author)
              .any((alias) => alias.toLowerCase().contains(lowerValue));
        },
      ),
      SearchField.string(
        'version',
        'Mod version',
        (m) => m.findFirstEnabledOrHighestVersion?.modInfo.version?.toString(),
      ),
      SearchField.string(
        'gameversion',
        'Game version compatibility',
        (m) => m.findFirstEnabledOrHighestVersion?.modInfo.gameVersion,
      ),
      SearchField<Mod>(
        key: 'enabled',
        description: 'Whether the mod is enabled (true/false)',
        valueSuggestions: (_) => ['true', 'false'],
        matches: (mod, op, value) {
          if (op != DslOperator.equals) return false;
          final isEnabled = mod.hasEnabledVariant;
          return value.toLowerCase() == isEnabled.toString();
        },
      ),
    ];
  }
}

class ModsGridSearchState {
  final List<Mod> allMods;
  final List<Mod> filteredMods;
  final Map<String, List<String>> modSearchIndices;
  final String currentSearchQuery;

  const ModsGridSearchState({
    this.allMods = const [],
    this.filteredMods = const [],
    this.modSearchIndices = const {},
    this.currentSearchQuery = '',
  });

  ModsGridSearchState copyWith({
    List<Mod>? allMods,
    List<Mod>? filteredMods,
    Map<String, List<String>>? modSearchIndices,
    String? currentSearchQuery,
  }) {
    return ModsGridSearchState(
      allMods: allMods ?? this.allMods,
      filteredMods: filteredMods ?? this.filteredMods,
      modSearchIndices: modSearchIndices ?? this.modSearchIndices,
      currentSearchQuery: currentSearchQuery ?? this.currentSearchQuery,
    );
  }
}

final modsGridSearchControllerProvider =
    NotifierProvider<ModsGridSearchController, ModsGridSearchState>(() {
  return ModsGridSearchController();
});
