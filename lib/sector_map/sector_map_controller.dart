import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/sector_map/finder/finder_criteria.dart';
import 'package:trios/sector_map/sector_map_manager.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/debouncer.dart';
import 'package:trios/utils/logging.dart';

part 'sector_map_controller.mapper.dart';

/// Which face of the sector map tool is showing.
///
/// - [finder] is the default: knob panel + live count + escalating hint ladder,
///   built so locations stay hidden until the player asks for them.
/// - [atlas] is the original show-everything overview (opt-in spoiler).
@MappableEnum()
enum SectorMapMode { finder, atlas }

/// The slice of finder state that survives across sessions, persisted in the
/// app settings (see [Settings.sectorMapPageState]).
@MappableClass()
class SectorMapPageStatePersisted with SectorMapPageStatePersistedMappable {
  final SectorMapMode mode;
  final FinderCriteria criteria;

  const SectorMapPageStatePersisted({
    this.mode = SectorMapMode.finder,
    this.criteria = const FinderCriteria(),
  });
}

/// Persistent-ish view state for the sector map page. Pan/zoom and hover are
/// intentionally kept as local widget state in the canvas for performance.
class SectorMapState {
  /// The save currently being viewed.
  final SectorSource? source;

  /// The system selected (clicked), shown in the detail panel.
  final String? selectedSystemId;

  /// Bumped whenever the user asks to recenter on [selectedSystemId] (e.g. via
  /// search). The canvas watches this to animate to the system.
  final int focusRequest;

  final String searchQuery;

  /// Faction ids toggled OFF. Empty = all factions shown normally. Systems with
  /// no visible faction are dimmed.
  final Set<String> hiddenFactionIds;

  // --- Finder ---

  /// Finder vs atlas view.
  final SectorMapMode mode;

  /// The finder's knob state.
  final FinderCriteria criteria;

  /// Hint reveal step for the current match. 0 = nothing revealed.
  final int revealLevel;

  /// Index into the scored-match list of the match currently being revealed.
  final int matchIndex;

  const SectorMapState({
    this.source,
    this.selectedSystemId,
    this.focusRequest = 0,
    this.searchQuery = '',
    this.hiddenFactionIds = const {},
    this.mode = SectorMapMode.finder,
    this.criteria = const FinderCriteria(),
    this.revealLevel = 0,
    this.matchIndex = 0,
  });

  SectorMapState copyWith({
    SectorSource? source,
    Object? selectedSystemId = _unset,
    int? focusRequest,
    String? searchQuery,
    Set<String>? hiddenFactionIds,
    SectorMapMode? mode,
    FinderCriteria? criteria,
    int? revealLevel,
    int? matchIndex,
  }) {
    return SectorMapState(
      source: source ?? this.source,
      selectedSystemId: selectedSystemId == _unset
          ? this.selectedSystemId
          : selectedSystemId as String?,
      focusRequest: focusRequest ?? this.focusRequest,
      searchQuery: searchQuery ?? this.searchQuery,
      hiddenFactionIds: hiddenFactionIds ?? this.hiddenFactionIds,
      mode: mode ?? this.mode,
      criteria: criteria ?? this.criteria,
      revealLevel: revealLevel ?? this.revealLevel,
      matchIndex: matchIndex ?? this.matchIndex,
    );
  }
}

const _unset = Object();

final sectorMapControllerProvider =
    NotifierProvider<SectorMapController, SectorMapState>(
      SectorMapController.new,
    );

class SectorMapController extends Notifier<SectorMapState> {
  /// Coalesces rapid criteria changes (slider drags) into one settings write.
  final _persistDebouncer = Debouncer(
    duration: const Duration(milliseconds: 600),
  );

  @override
  SectorMapState build() {
    final saved = ref.read(appSettings).sectorMapPageState;
    return SectorMapState(
      mode: saved?.mode ?? SectorMapMode.finder,
      criteria: saved?.criteria ?? const FinderCriteria(),
    );
  }

  void selectSave(SectorSource source) {
    state = state.copyWith(source: source, selectedSystemId: null);
  }

  void selectSystem(String? id) {
    state = state.copyWith(selectedSystemId: id);
  }

  /// Select a system and request the canvas recenter on it.
  void focusSystem(String id) {
    state = state.copyWith(
      selectedSystemId: id,
      focusRequest: state.focusRequest + 1,
    );
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleFaction(String factionId) {
    final next = Set<String>.from(state.hiddenFactionIds);
    if (!next.remove(factionId)) next.add(factionId);
    state = state.copyWith(hiddenFactionIds: next);
  }

  void clearFactionFilter() {
    state = state.copyWith(hiddenFactionIds: const {});
  }

  // --- Finder ---

  void setMode(SectorMapMode mode) {
    state = state.copyWith(mode: mode);
    _persist();
  }

  /// Replace the criteria (knob change or preset). Resets the reveal ladder
  /// since the best match may have changed.
  void setCriteria(FinderCriteria criteria) {
    state = state.copyWith(criteria: criteria, revealLevel: 0, matchIndex: 0);
    _persist();
  }

  /// Advance the hint ladder by one step (clamped by the caller's max).
  void bumpReveal(int max) {
    state = state.copyWith(
      revealLevel: (state.revealLevel + 1).clamp(0, max),
    );
  }

  /// Step to the next-best match and reset the reveal ladder.
  void nextMatch(int matchCount) {
    if (matchCount <= 0) return;
    state = state.copyWith(
      matchIndex: (state.matchIndex + 1) % matchCount,
      revealLevel: 0,
    );
  }

  void resetReveal() {
    state = state.copyWith(revealLevel: 0, matchIndex: 0);
  }

  void _persist() {
    _persistDebouncer.debounce(() async {
      try {
        ref
            .read(appSettings.notifier)
            .update(
              (curr) => curr.copyWith(
                sectorMapPageState: SectorMapPageStatePersisted(
                  mode: state.mode,
                  criteria: state.criteria,
                ),
              ),
            );
      } catch (e, st) {
        Fimber.w('Failed to persist sector map state', ex: e, stacktrace: st);
      }
      return null;
    });
  }
}
