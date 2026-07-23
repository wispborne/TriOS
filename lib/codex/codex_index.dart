import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/descriptions/description_entry.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/faction_viewer/faction_manager.dart';
import 'package:trios/fighter_viewer/wings_manager.dart';
import 'package:trios/hullmod_viewer/hullmods_manager.dart';
import 'package:trios/hullmod_viewer/hullmods_page_controller.dart';
import 'package:trios/ship_systems_manager/ship_systems_manager.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/ship_manager.dart';
import 'package:trios/ship_viewer/ship_module_resolver.dart';
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

  /// When false, hullmods flagged hidden or hiddenEverywhere are not listed.
  final bool showHiddenHullmods;

  /// When false, ship systems tagged `hide_in_codex` are not listed.
  final bool showHiddenShipSystems;

  /// When false, station modules (the child hulls docked in a station's module
  /// slots) are not listed as their own ship entries. They stay in the index as
  /// link targets regardless, so a station still shows them as related.
  final bool showModulesAsShips;

  const CodexStandingFilters({
    this.spoilerLevel = SpoilerLevel.showNone,
    this.modId,
    this.showHidden = false,
    this.showHiddenHullmods = false,
    this.showHiddenShipSystems = false,
    this.showModulesAsShips = false,
  });

  CodexStandingFilters copyWith({
    SpoilerLevel? spoilerLevel,
    String? modId,
    bool clearModId = false,
    bool? showHidden,
    bool? showHiddenHullmods,
    bool? showHiddenShipSystems,
    bool? showModulesAsShips,
  }) {
    return CodexStandingFilters(
      spoilerLevel: spoilerLevel ?? this.spoilerLevel,
      modId: clearModId ? null : (modId ?? this.modId),
      showHidden: showHidden ?? this.showHidden,
      showHiddenHullmods: showHiddenHullmods ?? this.showHiddenHullmods,
      showHiddenShipSystems:
          showHiddenShipSystems ?? this.showHiddenShipSystems,
      showModulesAsShips: showModulesAsShips ?? this.showModulesAsShips,
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

  void setShowHiddenHullmods(bool show) =>
      state = state.copyWith(showHiddenHullmods: show);

  void setShowHiddenShipSystems(bool show) =>
      state = state.copyWith(showHiddenShipSystems: show);

  void setShowModulesAsShips(bool show) =>
      state = state.copyWith(showModulesAsShips: show);
}

final codexStandingFiltersProvider =
    NotifierProvider<CodexStandingFiltersNotifier, CodexStandingFilters>(
      CodexStandingFiltersNotifier.new,
    );

/// The raw combined index: every entry of all six categories, deduped within
/// each category by the loaders themselves. `(type, id)` is the key, so the
/// same id in two categories never collides.
final codexIndexProvider = Provider<List<CodexEntry>>((ref) {
  // Ships, weapons and factions are merged from mod files, so "only enabled
  // mods" has to be applied while merging rather than by dropping entries
  // afterwards — otherwise a disabled mod still overrides stats and sprites.
  final enabledModsOnly = ref.watch(
    appSettings.select((s) => s.codexEnabledModsOnly),
  );
  final ships =
      ref.watch(shipListNotifierProvider(enabledModsOnly)).valueOrNull ??
      const [];
  final weapons =
      ref.watch(weaponListNotifierProvider(enabledModsOnly)).valueOrNull ??
      const [];
  final hullmods =
      ref.watch(hullmodListNotifierProvider).valueOrNull ?? const [];
  final factions = ref.watch(mergedFactionListProvider(enabledModsOnly));
  final systems =
      ref.watch(shipSystemListNotifierProvider).valueOrNull ?? const [];
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
        shortType:
            descriptions[(sys.id, DescriptionEntry.typeShipSystem)]?.text2,
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
  // Same toggle the index itself uses, so this doesn't merge a second list
  // just to read a loading flag.
  final enabledModsOnly = ref.watch(
    appSettings.select((s) => s.codexEnabledModsOnly),
  );
  return switch (type) {
    CodexEntryType.ship =>
      ref.watch(shipListNotifierProvider(enabledModsOnly)).isLoading,
    CodexEntryType.station =>
      ref.watch(shipListNotifierProvider(enabledModsOnly)).isLoading,
    CodexEntryType.weapon =>
      ref.watch(weaponListNotifierProvider(enabledModsOnly)).isLoading,
    CodexEntryType.hullmod => ref.watch(hullmodListNotifierProvider).isLoading,
    CodexEntryType.shipSystem =>
      ref.watch(shipSystemListNotifierProvider).isLoading,
    CodexEntryType.wing => ref.watch(wingListNotifierProvider).isLoading,
    CodexEntryType.faction => ref.watch(factionListNotifierProvider).isLoading,
  };
});

/// Hull ids that are station modules — the child hulls docked in some station's
/// module slots. Kept in its own provider so it only recomputes when the ships
/// or module data change, not on every spoiler/mod-filter tweak.
final _codexModuleShipIdsProvider = Provider<Set<String>>((ref) {
  // Same toggle the index uses, so the codex only ever merges one ship list.
  final ships =
      ref
          .watch(
            shipListNotifierProvider(
              ref.watch(appSettings.select((s) => s.codexEnabledModsOnly)),
            ),
          )
          .valueOrNull ??
      const [];
  final moduleVariants = ref.watch(moduleVariantsProvider);
  final variantHullIdMap = ref.watch(variantHullIdMapProvider);
  if (ships.isEmpty || moduleVariants.isEmpty) return const {};

  final shipById = <String, Ship>{for (final s in ships) s.id: s};
  final moduleIds = <String>{};
  for (final ship in ships) {
    for (final module in resolveModulesWithIndex(
      ship,
      shipById,
      moduleVariants,
      variantHullIdMap,
    )) {
      moduleIds.add(module.moduleShip.id);
    }
  }
  return moduleIds;
});

/// One pass over the raw index producing the visible, listed, and
/// spoiler-locked lists together. The three lists share all their filter work
/// (the spoiler check is the expensive one), and this runs on every data
/// refresh while mods load, so doing it in a single pass instead of three
/// separate provider passes matters.
final _codexFilteredIndexProvider =
    Provider<
      ({
        List<CodexEntry> visible,
        List<CodexEntry> listed,
        List<CodexEntry> locked,
      })
    >((ref) {
      final index = ref.watch(codexIndexProvider);
      final filters = ref.watch(codexStandingFiltersProvider);

      // When "only enabled mods" is on, keep vanilla plus entries from a mod
      // that is currently enabled. Off by default, so this collapses to a
      // no-op filter.
      final onlyEnabledMods = ref.watch(
        appSettings.select((s) => s.codexEnabledModsOnly),
      );
      final enabledModIds = onlyEnabledMods
          ? ref
                .watch(AppState.mods)
                .where((mod) => mod.isEnabledOnUi)
                .map((mod) => mod.id)
                .toSet()
          : const <String>{};

      final moduleShipIds = ref.watch(_codexModuleShipIdsProvider);

      // Ships by id, so a wing can borrow its ship's spoiler result. HashMap:
      // built fresh on every data refresh, and insertion order is never used.
      final shipsById = HashMap<String, ShipCodexEntry>();
      for (final e in index) {
        if (e is ShipCodexEntry) shipsById[e.ship.id] = e;
      }

      final visible = <CodexEntry>[];
      final listed = <CodexEntry>[];
      final locked = <CodexEntry>[];
      for (final e in index) {
        // Cheap filters first; the spoiler check walks tag lists.
        if (!_matchesMod(e, filters.modId)) continue;
        if (!_matchesEnabledMods(e, onlyEnabledMods, enabledModIds)) continue;

        // Station modules always stay in the visible index so a station's
        // related panel can resolve them, but they're only listed when "Show
        // modules as ships" is on, and never appear as locked placeholders.
        if (e is ShipCodexEntry && moduleShipIds.contains(e.ship.id)) {
          visible.add(e);
          if (filters.showModulesAsShips) listed.add(e);
          continue;
        }

        if (_matchesSpoiler(e, filters.spoilerLevel, shipsById)) {
          visible.add(e);
          if (isCodexEntryListed(e, filters)) listed.add(e);
        } else if (isCodexEntryListed(e, filters)) {
          // Hidden by spoiler, but otherwise fully listable.
          locked.add(e);
        }
      }
      return (visible: visible, listed: listed, locked: locked);
    });

/// The index after the standing spoiler and mod filters. This is the universe
/// that links resolve against, so a spoiler- or mod-hidden entry can't leak in
/// through a related link or a random roll.
final codexVisibleIndexProvider = Provider<List<CodexEntry>>(
  (ref) => ref.watch(_codexFilteredIndexProvider).visible,
);

/// The subset of the visible index that is actually listed in the drill-down
/// list, search, and random: fighter hulls are never listed, and hidden
/// weapons, hullmods, and ship systems only when their toggle is on.
final codexListedIndexProvider = Provider<List<CodexEntry>>(
  (ref) => ref.watch(_codexFilteredIndexProvider).listed,
);

/// Entries hidden only by the current spoiler level: they pass the mod,
/// enabled-mods, and listed filters and would show if the spoiler level allowed
/// them. The in-game Codex still lists these as "Locked entry" placeholders at
/// the bottom of their category, revealing nothing about them.
final codexSpoilerLockedIndexProvider = Provider<List<CodexEntry>>(
  (ref) => ref.watch(_codexFilteredIndexProvider).locked,
);

/// Whether [entry] appears in the list/search/random (as opposed to being only
/// a link target).
bool isCodexEntryListed(CodexEntry entry, CodexStandingFilters filters) {
  return switch (entry) {
    ShipCodexEntry(:final ship) => ship.hullSize?.toLowerCase() != 'fighter',
    WeaponCodexEntry(:final weapon) => filters.showHidden || !weapon.isHidden(),
    HullmodCodexEntry(:final hullmod) =>
      filters.showHiddenHullmods ||
          (hullmod.hidden != true && hullmod.hiddenEverywhere != true),
    ShipSystemCodexEntry(:final system) =>
      filters.showHiddenShipSystems ||
          !_splitTags(system.tags).contains('hide_in_codex'),
    _ => true,
  };
}

bool _matchesMod(CodexEntry entry, String? modId) {
  if (modId == null) return true;
  if (modId == codexVanillaModId) return entry.modIds.isEmpty;
  return entry.modIds.contains(modId);
}

/// When [onlyEnabledMods] is on, keep vanilla entries (no mod) and any entry
/// from at least one enabled mod. A faction sourced from several mods stays as
/// long as one of those mods is enabled.
bool _matchesEnabledMods(
  CodexEntry entry,
  bool onlyEnabledMods,
  Set<String> enabledModIds,
) {
  if (!onlyEnabledMods) return true;
  if (entry.modIds.isEmpty) return true;
  return entry.modIds.any(enabledModIds.contains);
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
      // Treat the `hide_in_codex` hint as a spoiler, the same as the Ship
      // Viewer and the wing case below: "Show all spoilers" reveals these
      // ships, and lower levels leave them as anonymous "Locked entry"
      // placeholders. Station modules use the tag instead of the hint, so
      // they keep passing here and stay in the visible index as link targets.
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
