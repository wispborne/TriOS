import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/descriptions/description_entry.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/faction_viewer/faction_manager.dart';
import 'package:trios/fighter_viewer/wings_manager.dart';
import 'package:trios/hullmod_viewer/hullmods_manager.dart';
import 'package:trios/hullmod_viewer/hullmods_page_controller.dart';
import 'package:trios/ship_systems_manager/ship_systems_manager.dart';
import 'package:trios/ship_viewer/ship_manager.dart';
import 'package:trios/ship_viewer/ships_page_controller.dart';
import 'package:trios/weapon_viewer/weapons_manager.dart';
import 'package:trios/weapon_viewer/weapons_page_controller.dart';

/// Sentinel mod-filter value meaning "vanilla only" (entries with no mod).
const String codexVanillaModId = '__vanilla__';

/// Page-wide settings that filter the whole index. Shared across categories and
/// never captured in history snapshots (design 6b): going back should never
/// silently re-show hidden content.
class CodexStandingFilters {
  /// Uses the ships' three-level enum; the two-level weapon/hullmod checks map
  /// onto it (none = hide, slight/all = show).
  final SpoilerLevel spoilerLevel;

  /// Selected mod id, [codexVanillaModId] for vanilla-only, or null for all.
  final String? modId;

  /// When false, hidden weapons (system/decorative) are not listed. They stay
  /// in the index as link targets regardless.
  final bool showHidden;

  const CodexStandingFilters({
    this.spoilerLevel = SpoilerLevel.showNone,
    this.modId,
    this.showHidden = false,
  });

  CodexStandingFilters copyWith({
    SpoilerLevel? spoilerLevel,
    String? modId,
    bool clearModId = false,
    bool? showHidden,
  }) {
    return CodexStandingFilters(
      spoilerLevel: spoilerLevel ?? this.spoilerLevel,
      modId: clearModId ? null : (modId ?? this.modId),
      showHidden: showHidden ?? this.showHidden,
    );
  }
}

class CodexStandingFiltersNotifier extends Notifier<CodexStandingFilters> {
  @override
  CodexStandingFilters build() => const CodexStandingFilters();

  void setSpoilerLevel(SpoilerLevel level) =>
      state = state.copyWith(spoilerLevel: level);

  void setModId(String? modId) => modId == null
      ? state = state.copyWith(clearModId: true)
      : state = state.copyWith(modId: modId);

  void setShowHidden(bool show) => state = state.copyWith(showHidden: show);
}

final codexStandingFiltersProvider =
    NotifierProvider<CodexStandingFiltersNotifier, CodexStandingFilters>(
      CodexStandingFiltersNotifier.new,
    );

/// The raw combined index: every entry of all six categories, deduped within
/// each category by the loaders themselves. `(type, id)` is the key, so the
/// same id in two categories never collides.
final codexIndexProvider = Provider<List<CodexEntry>>((ref) {
  final ships = ref.watch(shipListNotifierProvider).valueOrNull ?? const [];
  final weapons = ref.watch(weaponListNotifierProvider).valueOrNull ?? const [];
  final hullmods =
      ref.watch(hullmodListNotifierProvider).valueOrNull ?? const [];
  final factions =
      ref.watch(factionListNotifierProvider).valueOrNull ?? const [];
  final systems =
      ref.watch(shipSystemsStreamProvider).valueOrNull ?? const [];
  final wings = ref.watch(wingListNotifierProvider).valueOrNull ?? const [];
  // Watch the descriptions map once and look up directly — one family watch
  // per ship system is far too slow (each watch walks the element ancestors).
  final descriptions =
      ref.watch(descriptionsNotifierProvider).valueOrNull ?? const {};

  // Ship name by hull id, so a wing can show the name of the ship behind it
  // (wing rows have no name column of their own).
  final shipNamesByHull = <String, String>{
    for (final s in ships)
      if (s.name != null) s.id: s.name!,
  };

  return <CodexEntry>[
    for (final s in ships) ShipCodexEntry(s),
    for (final w in weapons) WeaponCodexEntry(w),
    for (final h in hullmods) HullmodCodexEntry(h),
    for (final sys in systems)
      ShipSystemCodexEntry(
        sys,
        shortType: descriptions[(
          sys.id,
          DescriptionEntry.typeShipSystem,
        )]?.text2,
      ),
    for (final wing in wings)
      WingCodexEntry(
        wing,
        shipName: wing.hullId == null ? null : shipNamesByHull[wing.hullId],
      ),
    for (final f in factions) FactionCodexEntry(f),
  ];
});

/// Whether the manager backing [type] is still loading its entities. Used to
/// show a spinner next to categories whose data isn't ready yet.
final codexCategoryLoadingProvider = Provider.family<bool, CodexEntryType>((
  ref,
  type,
) {
  return switch (type) {
    CodexEntryType.ship => ref.watch(shipListNotifierProvider).isLoading,
    CodexEntryType.weapon => ref.watch(weaponListNotifierProvider).isLoading,
    CodexEntryType.hullmod => ref.watch(hullmodListNotifierProvider).isLoading,
    CodexEntryType.shipSystem => ref.watch(shipSystemsStreamProvider).isLoading,
    CodexEntryType.wing => ref.watch(wingListNotifierProvider).isLoading,
    CodexEntryType.faction => ref.watch(factionListNotifierProvider).isLoading,
  };
});

/// The index after the standing spoiler and mod filters. This is the universe
/// that links resolve against, so a spoiler- or mod-hidden entry can't leak in
/// through a related link or a random roll.
final codexVisibleIndexProvider = Provider<List<CodexEntry>>((ref) {
  final index = ref.watch(codexIndexProvider);
  final filters = ref.watch(codexStandingFiltersProvider);

  // Ships by id, so a wing can borrow its ship's spoiler result.
  final shipsById = <String, ShipCodexEntry>{
    for (final e in index)
      if (e is ShipCodexEntry) e.ship.id: e,
  };

  return index
      .where((e) => _matchesSpoiler(e, filters.spoilerLevel, shipsById))
      .where((e) => _matchesMod(e, filters.modId))
      .toList();
});

/// The subset of the visible index that is actually listed in the drill-down
/// list, search, and random: fighter hulls are never listed, and hidden
/// weapons only when the toggle is on.
final codexListedIndexProvider = Provider<List<CodexEntry>>((ref) {
  final visible = ref.watch(codexVisibleIndexProvider);
  final showHidden = ref.watch(codexStandingFiltersProvider).showHidden;
  return visible.where((e) => isCodexEntryListed(e, showHidden)).toList();
});

/// Whether [entry] appears in the list/search/random (as opposed to being only
/// a link target).
bool isCodexEntryListed(CodexEntry entry, bool showHidden) {
  return switch (entry) {
    ShipCodexEntry(:final ship) => ship.hullSize?.toLowerCase() != 'fighter',
    WeaponCodexEntry(:final weapon) => showHidden || !weapon.isHidden(),
    _ => true,
  };
}

bool _matchesMod(CodexEntry entry, String? modId) {
  if (modId == null) return true;
  if (modId == codexVanillaModId) return entry.modIds.isEmpty;
  return entry.modIds.contains(modId);
}

bool _matchesSpoiler(
  CodexEntry entry,
  SpoilerLevel level,
  Map<String, ShipCodexEntry> shipsById,
) {
  // Weapons and hullmods have a single spoiler tier: "none" hides it, both
  // "slight" and "all" show it.
  final showTwoTier = level != SpoilerLevel.showNone;

  switch (entry) {
    case ShipCodexEntry(:final ship):
      return shipMatchesSpoilerLevel(ship, level);
    case WeaponCodexEntry(:final weapon):
      return weaponMatchesSpoilerLevel(
        weapon,
        showTwoTier
            ? WeaponSpoilerLevel.showAllSpoilers
            : WeaponSpoilerLevel.noSpoilers,
      );
    case HullmodCodexEntry(:final hullmod):
      return hullmodMatchesSpoilerLevel(
        hullmod,
        showTwoTier
            ? HullmodSpoilerLevel.showAllSpoilers
            : HullmodSpoilerLevel.noSpoilers,
      );
    case WingCodexEntry(:final wing):
      final ship = wing.hullId == null ? null : shipsById[wing.hullId!];
      if (ship != null) return shipMatchesSpoilerLevel(ship.ship, level);
      return tagsMatchShipSpoilerLevel(_splitTags(wing.tags), level);
    case ShipSystemCodexEntry(:final system):
      return tagsMatchShipSpoilerLevel(_splitTags(system.tags), level);
    case FactionCodexEntry():
      return true;
  }
}

Iterable<String> _splitTags(String? tags) {
  if (tags == null || tags.isEmpty) return const [];
  return tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty);
}
