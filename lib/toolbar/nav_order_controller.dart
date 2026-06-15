import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/toolbar/nav_order_entry.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/logging.dart';

/// In-memory state for the nav-order feature.
///
/// Only [entries] is persisted (via `Settings.navIconOrder`). [isInDragMode]
/// is transient — it resets to false on every app launch.
class NavOrderState {
  final List<NavOrderEntry> entries;
  final bool isInDragMode;

  const NavOrderState({required this.entries, required this.isInDragMode});

  NavOrderState copyWith({List<NavOrderEntry>? entries, bool? isInDragMode}) {
    return NavOrderState(
      entries: entries ?? this.entries,
      isInDragMode: isInDragMode ?? this.isInDragMode,
    );
  }
}

/// Riverpod notifier that owns the user's navigation order and the transient
/// drag-mode flag.
///
/// Design (see `openspec/changes/reorderable-nav-icons/design.md`):
/// - Persists only the order, never the drag-mode flag.
/// - Reconciles stored orders on load: appends new tools, drops unknown
///   entries, and deduplicates.
/// - Exposes a toolkit API — primitive ops that the sidebar and top-bar
///   compose into their own UI.
class NavOrderController extends Notifier<NavOrderState> {
  @override
  NavOrderState build() {
    // Read settings once at build time — we intentionally do NOT watch,
    // because this controller is the ONLY writer of `navIconOrder`. Watching
    // would cause our own writes (reorder / resetToDefault) to re-trigger
    // build() and reset transient state like `isInDragMode` mid-drag.
    final stored = ref.read(appSettings).navIconOrder;
    final reconciled = _reconcile(stored);
    return NavOrderState(entries: reconciled, isInDragMode: false);
  }

  // ---- mutators ----

  void toggleDragMode() {
    state = state.copyWith(isInDragMode: !state.isInDragMode);
  }

  void exitDragMode() {
    if (state.isInDragMode) {
      state = state.copyWith(isInDragMode: false);
    }
  }

  /// Move the entry at [oldIndex] to [newIndex]. Uses the `ReorderableListView`
  /// convention where [newIndex] is the target index *before* the item is
  /// removed (so we adjust internally).
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.entries.length) return;
    final adjustedNew = newIndex > oldIndex ? newIndex - 1 : newIndex;
    if (adjustedNew < 0 || adjustedNew >= state.entries.length) return;
    if (oldIndex == adjustedNew) return;

    final newList = List<NavOrderEntry>.of(state.entries);
    final moved = newList.removeAt(oldIndex);
    newList.insert(adjustedNew, moved);

    state = state.copyWith(entries: newList);
    _persist(newList);
  }

  /// Clear the stored custom order and restore [defaultNavOrder] in state.
  Future<void> resetToDefault() async {
    state = state.copyWith(entries: List<NavOrderEntry>.of(defaultNavOrder));
    await ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(navIconOrder: null));
  }

  // ---- helpers ----

  /// Whether the current order differs from [defaultNavOrder]. Used by the
  /// "Reset to default order" menu entry to decide whether to confirm.
  bool get isCustomized => !_listsEqual(state.entries, defaultNavOrder);

  /// Returns the tools in [section], where core = above the divider and
  /// viewers = below. If no divider exists, all tools go to core.
  List<TriOSTools> toolsInSection(NavSection section) {
    final dividerIndex = state.entries.indexWhere(
      (e) => e is NavDividerEntry,
    );
    final split = dividerIndex == -1 ? state.entries.length : dividerIndex;

    final slice = section == NavSection.core
        ? state.entries.sublist(0, split)
        : (dividerIndex == -1
              ? const <NavOrderEntry>[]
              : state.entries.sublist(dividerIndex + 1));
    return slice
        .whereType<NavToolEntry>()
        .map((e) => e.tool)
        .toList(growable: false);
  }

  void _persist(List<NavOrderEntry> entries) {
    ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(navIconOrder: entries));
  }

  /// Normalize a (possibly null or stale) stored order against the current
  /// [TriOSTools] enum:
  /// - null  → use [defaultNavOrder] verbatim.
  /// - drop unknown enum values (e.g. SafeDecodeHook left null) and anything
  ///   that isn't in [reorderableTools].
  /// - dedupe tool entries (keep first occurrence) and divider entries
  ///   (keep first).
  /// - append any missing reorderable tools at the end (after the divider
  ///   if one exists, else at the very end).
  @visibleForTesting
  static List<NavOrderEntry> reconcileForTesting(List<NavOrderEntry>? stored) =>
      _reconcile(stored);

  static List<NavOrderEntry> _reconcile(List<NavOrderEntry>? stored) {
    if (stored == null || stored.isEmpty) {
      return List<NavOrderEntry>.of(defaultNavOrder);
    }

    final seen = <TriOSTools>{};
    var sawDivider = false;
    final cleaned = <NavOrderEntry>[];

    for (final entry in stored) {
      switch (entry) {
        case NavToolEntry(:final tool):
          if (!reorderableTools.contains(tool)) {
            Fimber.i("Dropping non-reorderable tool from stored nav order: $tool");
            continue;
          }
          if (seen.add(tool)) {
            cleaned.add(entry);
          } else {
            Fimber.i("Dropping duplicate nav entry: $tool");
          }
        case NavDividerEntry():
          if (!sawDivider) {
            sawDivider = true;
            cleaned.add(entry);
          } else {
            Fimber.i("Dropping duplicate nav divider entry");
          }
      }
    }

    // Append any missing reorderable tools.
    final missing = reorderableTools
        .where((t) => !seen.contains(t))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      Fimber.i(
        "Appending ${missing.length} missing tool(s) to nav order: $missing",
      );
      final insertIndex = sawDivider
          ? cleaned.length
          : cleaned.length; // with or without a divider, append at end
      for (final tool in missing) {
        cleaned.insert(insertIndex, NavToolEntry(tool));
      }
    }

    // If no divider was present at all, synthesize one at the end so the
    // layout still has a section boundary the user can move.
    if (!sawDivider) {
      cleaned.add(const NavDividerEntry());
    }

    return cleaned;
  }

  static bool _listsEqual(List<NavOrderEntry> a, List<NavOrderEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x is NavToolEntry && y is NavToolEntry) {
        if (x.tool != y.tool) return false;
      } else if (x is NavDividerEntry && y is NavDividerEntry) {
        continue;
      } else {
        return false;
      }
    }
    return true;
  }
}

/// Global provider for the nav-order controller.
final navOrderProvider =
    NotifierProvider<NavOrderController, NavOrderState>(NavOrderController.new);
