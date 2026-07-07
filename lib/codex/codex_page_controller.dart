import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/trios/app_state.dart';

/// The [Highlightable] key for a Codex entry, used when landing in another
/// category so the target row glows and scrolls into view.
String codexHighlightKey((CodexEntryType, String) key) =>
    'codex_${key.$1.name}_${key.$2}';

/// A saved point in the browse history: enough to restore the list, the shown
/// entry, the search text, and the category's facet selections. Standing
/// settings (spoiler, mod filter, show hidden) are deliberately excluded — see
/// design 6b.
class CodexSnapshot {
  final CodexEntryType? category;
  final (CodexEntryType, String)? selected;
  final String searchQuery;

  /// Per-group serialized facet selections for the snapshot's category.
  final Map<String, Map<String, Object?>> facetSelections;

  const CodexSnapshot({
    required this.category,
    required this.selected,
    required this.searchQuery,
    required this.facetSelections,
  });
}

class CodexPageState {
  /// null = the root category list.
  final CodexEntryType? category;

  /// The entry shown in the detail panel.
  final (CodexEntryType, String)? selected;

  /// '' = not searching.
  final String searchQuery;

  final List<CodexSnapshot> history;
  final int historyIndex;

  /// The key of a row that should be highlighted+scrolled-to once (landing in
  /// another category). Cleared after it is consumed by the list.
  final (CodexEntryType, String)? highlightTarget;

  const CodexPageState({
    this.category,
    this.selected,
    this.searchQuery = '',
    this.history = const [],
    this.historyIndex = -1,
    this.highlightTarget,
  });

  bool get isSearching => searchQuery.trim().isNotEmpty;

  bool get canGoBack => historyIndex > 0;
  bool get canGoForward => historyIndex >= 0 && historyIndex < history.length - 1;

  CodexPageState copyWith({
    CodexEntryType? category,
    bool clearCategory = false,
    (CodexEntryType, String)? selected,
    bool clearSelected = false,
    String? searchQuery,
    List<CodexSnapshot>? history,
    int? historyIndex,
    (CodexEntryType, String)? highlightTarget,
    bool clearHighlight = false,
  }) {
    return CodexPageState(
      category: clearCategory ? null : (category ?? this.category),
      selected: clearSelected ? null : (selected ?? this.selected),
      searchQuery: searchQuery ?? this.searchQuery,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
      highlightTarget: clearHighlight
          ? null
          : (highlightTarget ?? this.highlightTarget),
    );
  }
}

/// How the controller reads and writes the per-category facet selections. The
/// page supplies this (backed by the `FilterScopeController`s) so the controller
/// can capture/restore facets in history without knowing about the filter
/// engine.
class CodexFacetBridge {
  final Map<String, Map<String, Object?>> Function(CodexEntryType category)
  capture;
  final void Function(
    CodexEntryType category,
    Map<String, Map<String, Object?>> selections,
  )
  restore;
  final void Function(CodexEntryType category) reset;

  const CodexFacetBridge({
    required this.capture,
    required this.restore,
    required this.reset,
  });
}

class CodexPageController extends Notifier<CodexPageState> {
  static const int _historyCap = 100;

  /// Set by the page after it builds its facet controllers.
  CodexFacetBridge? facets;

  @override
  CodexPageState build() => const CodexPageState();

  Map<String, Map<String, Object?>> _captureFacets(CodexEntryType? category) {
    if (category == null || facets == null) return const {};
    return facets!.capture(category);
  }

  /// Push a snapshot of the current state, dropping any forward history.
  void _snapshot() {
    final snap = CodexSnapshot(
      category: state.category,
      selected: state.selected,
      searchQuery: state.searchQuery,
      facetSelections: _captureFacets(state.category),
    );
    final kept = state.history.take(state.historyIndex + 1).toList()..add(snap);
    final capped = kept.length > _historyCap
        ? kept.sublist(kept.length - _historyCap)
        : kept;
    state = state.copyWith(
      history: capped,
      historyIndex: capped.length - 1,
    );
  }

  void openCategory(CodexEntryType type) {
    facets?.reset(type);
    state = state.copyWith(
      category: type,
      searchQuery: '',
      clearSelected: true,
    );
    _snapshot();
  }

  void goUp() {
    if (state.isSearching) {
      state = state.copyWith(searchQuery: '');
      _snapshot();
      return;
    }
    state = state.copyWith(clearCategory: true, searchQuery: '');
    _snapshot();
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Show [key] in the detail panel; switch category first if needed (landing
  /// in another category → highlight the row).
  void select((CodexEntryType, String) key) {
    final needsSwitch = state.category != key.$1;
    // A "jump" is any selection that lands the row in a list it wasn't already
    // visible in: a different category, or a search result (the list flips from
    // results back to the category). Those get a glow + scroll-into-view; a
    // plain click on an already-visible list row does not.
    final isJump = needsSwitch || state.isSearching;
    if (needsSwitch) {
      facets?.reset(key.$1);
    }
    state = state.copyWith(
      category: key.$1,
      selected: key,
      searchQuery: '',
      highlightTarget: isJump ? key : null,
      clearHighlight: !isJump,
    );
    if (isJump) {
      ref.read(AppState.activeHighlightKey.notifier).state =
          codexHighlightKey(key);
    }
    _snapshot();
  }

  void consumeHighlight() {
    if (state.highlightTarget != null) {
      state = state.copyWith(clearHighlight: true);
    }
  }

  void back() {
    if (!state.canGoBack) return;
    _restore(state.historyIndex - 1);
  }

  void forward() {
    if (!state.canGoForward) return;
    _restore(state.historyIndex + 1);
  }

  void _restore(int index) {
    final snap = state.history[index];
    if (snap.category != null) {
      facets?.restore(snap.category!, snap.facetSelections);
    }
    state = state.copyWith(
      category: snap.category,
      clearCategory: snap.category == null,
      selected: snap.selected,
      clearSelected: snap.selected == null,
      searchQuery: snap.searchQuery,
      historyIndex: index,
      highlightTarget: snap.selected,
      clearHighlight: snap.selected == null,
    );
  }
}

final codexPageControllerProvider =
    NotifierProvider<CodexPageController, CodexPageState>(
      CodexPageController.new,
    );
