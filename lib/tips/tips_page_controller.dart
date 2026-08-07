import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/tips/tip.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/notify_on_new_state.dart';

part 'tips_page_controller.mapper.dart';

/// How the tips list is grouped.
@MappableEnum()
enum TipsGrouping { none, mod }

/// The parts of the tips page that are remembered between sessions.
@MappableClass()
class TipsPageStatePersisted with TipsPageStatePersistedMappable {
  final bool onlyEnabledMods;
  final bool showHidden;
  final TipsGrouping grouping;

  const TipsPageStatePersisted({
    this.onlyEnabledMods = false,
    this.showHidden = false,
    this.grouping = TipsGrouping.none,
  });
}

@MappableClass()
class TipsPageState with TipsPageStateMappable {
  final TipsPageStatePersisted persisted;

  /// Every tip that was loaded, before any filtering.
  final List<ModTip> allTips;

  /// The tips left after the toolbar's filters and search, sorted longest first.
  final List<ModTip> visibleTips;

  /// Tips the user has hidden from the game's loading screens.
  final List<ModTip> hiddenTips;

  final Set<ModTip> selectedTips;
  final String searchQuery;
  final bool isLoading;

  /// Set when loading tips failed, so the page can show it instead of the grid.
  final String? errorMessage;

  bool get onlyEnabledMods => persisted.onlyEnabledMods;

  bool get showHidden => persisted.showHidden;

  TipsGrouping get grouping => persisted.grouping;

  const TipsPageState({
    this.persisted = const TipsPageStatePersisted(),
    this.allTips = const [],
    this.visibleTips = const [],
    this.hiddenTips = const [],
    this.selectedTips = const {},
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });
}

final tipsPageControllerProvider =
    NotifierProvider<TipsPageController, TipsPageState>(
      () => TipsPageController(),
    );

class TipsPageController extends Notifier<TipsPageState>
    with NotifyOnNewState {
  @override
  TipsPageState build() {
    final tipsAsync = ref.watch(AppState.tipsProvider);
    final mods = ref.watch(AppState.mods);
    final allTips = tipsAsync.value ?? const <ModTip>[];
    final hiddenTips = ref
        .read(AppState.tipsProvider.notifier)
        .getHidden(allTips);

    final error = tipsAsync.error;
    if (error != null) {
      Fimber.e(
        'Error loading tips: $error',
        ex: error,
        stacktrace: tipsAsync.stackTrace,
      );
    }

    final saved = ref.read(appSettings).tipsPageState;
    final previous =
        stateOrNull ??
        TipsPageState(persisted: saved ?? const TipsPageStatePersisted());

    return _withVisibleTips(
      previous.copyWith(
        allTips: allTips,
        hiddenTips: hiddenTips,
        // Drop tips that no longer exist from the selection.
        selectedTips: previous.selectedTips.where(allTips.contains).toSet(),
        isLoading: tipsAsync.isLoading,
        errorMessage: error?.toString(),
      ),
      mods,
    );
  }

  /// Applies the toolbar's filters and search to [TipsPageState.allTips] and
  /// sorts what's left by tip length, longest first.
  TipsPageState _withVisibleTips(TipsPageState newState, List<Mod> mods) {
    var tips = newState.allTips;

    if (newState.onlyEnabledMods) {
      tips = tips
          .where(
            (tip) =>
                tip.variants.any((variant) => variant.isEnabled(mods) == true),
          )
          .toList();
    }

    if (!newState.showHidden) {
      final hidden = newState.hiddenTips.toSet();
      tips = tips.where((tip) => !hidden.contains(tip)).toList();
    }

    final searchQuery = newState.searchQuery.toLowerCase();
    if (searchQuery.isNotEmpty) {
      tips = tips
          .where(
            (tip) => tip.toMap().values.any(
              (value) => value.toString().toLowerCase().contains(searchQuery),
            ),
          )
          .toList();
    }

    final sorted = tips.toList()
      ..sort((a, b) => (b.tipObj.tip?.length ?? 0) - (a.tipObj.tip?.length ?? 0));

    return newState.copyWith(visibleTips: sorted);
  }

  void _update(TipsPageState newState) {
    state = _withVisibleTips(newState, ref.read(AppState.mods));
  }

  void _updatePersisted(TipsPageStatePersisted newPersisted) {
    _update(state.copyWith(persisted: newPersisted));
    ref.read(appSettings.notifier).update(
      (s) => s.copyWith(tipsPageState: newPersisted),
    );
  }

  void setSearchQuery(String query) =>
      _update(state.copyWith(searchQuery: query));

  void toggleOnlyEnabledMods() => _updatePersisted(
    state.persisted.copyWith(onlyEnabledMods: !state.onlyEnabledMods),
  );

  void toggleShowHidden() => _updatePersisted(
    state.persisted.copyWith(showHidden: !state.showHidden),
  );

  void setGrouping(TipsGrouping grouping) =>
      _updatePersisted(state.persisted.copyWith(grouping: grouping));

  void refresh() => ref.invalidate(AppState.tipsProvider);

  /// The visible tips grouped by the mod that added them, sorted by mod.
  Map<Mod, List<ModTip>> groupVisibleTipsByMod() {
    final mods = ref.read(AppState.mods);
    final grouped = <Mod, List<ModTip>>{};

    for (final tip in state.visibleTips) {
      final mod = tip.variants.firstOrNull?.mod(mods);
      if (mod == null) continue;
      grouped.putIfAbsent(mod, () => []).add(tip);
    }

    final sortedMods = grouped.keys.sorted((a, b) => a.compareTo(b));
    return {for (final mod in sortedMods) mod: grouped[mod]!};
  }

  bool isSelected(ModTip tip) => state.selectedTips.contains(tip);

  void setSelected(ModTip tip, bool isSelected) {
    final selected = state.selectedTips.toSet();
    if (isSelected) {
      selected.add(tip);
    } else {
      selected.remove(tip);
    }
    state = state.copyWith(selectedTips: selected);
  }

  /// Selects every tip in [tips], or deselects them all if they're already
  /// selected.
  void toggleSelectAll(List<ModTip> tips) {
    final selected = state.selectedTips.toSet();
    if (tips.every(selected.contains)) {
      selected.removeAll(tips);
    } else {
      selected.addAll(tips);
    }
    state = state.copyWith(selectedTips: selected);
  }

  /// How many of the selected tips are already hidden. The Hide/Unhide button
  /// uses this to decide which action to offer.
  int get selectedHiddenCount {
    final hidden = state.hiddenTips.toSet();
    return state.selectedTips.where(hidden.contains).length;
  }

  void hideTips(Iterable<ModTip> tips) {
    if (tips.isEmpty) return;
    ref.read(AppState.tipsProvider.notifier).hideTips(tips, dryRun: false);
    _clearSelection(tips);
  }

  void unhideTips(Iterable<ModTip> tips) {
    if (tips.isEmpty) return;
    ref.read(AppState.tipsProvider.notifier).unhideTips(tips);
    _clearSelection(tips);
  }

  void _clearSelection(Iterable<ModTip> tips) {
    final selected = state.selectedTips.toSet()..removeAll(tips);
    state = state.copyWith(selectedTips: selected);
  }
}
