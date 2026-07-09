import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/fighter_viewer/wings_manager.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/ship_manager.dart';
import 'package:trios/ship_viewer/ship_module_resolver.dart';

typedef CodexKey = (CodexEntryType, String);

/// Category sort rank for related links, in the game's order:
/// ship systems → hullmods → weapons → fighters → ships → factions.
int codexCategoryRank(CodexEntryType type) => switch (type) {
  CodexEntryType.shipSystem => 0,
  CodexEntryType.hullmod => 1,
  CodexEntryType.weapon => 2,
  CodexEntryType.wing => 3,
  CodexEntryType.ship => 4,
  CodexEntryType.station => 5,
  CodexEntryType.faction => 6,
};

/// Two-way "see also" links between entries, keyed by `(type, id)`. Computed
/// from the raw ship and wing lists; links are stored as keys and resolved to
/// entries at display time, so a key pointing at a disabled/filtered entry
/// simply resolves to nothing. Factions get no links in v1.
final codexLinksProvider = Provider<Map<CodexKey, List<CodexKey>>>((ref) {
  // Watch the ship and wing lists directly instead of the codex index: links
  // are derived only from ships and wings, so yields from the other five
  // index sources (weapons, hullmods, systems, factions, descriptions) don't
  // trigger a rebuild of this expensive map while everything loads.
  final ships = ref.watch(shipListNotifierProvider).valueOrNull ?? const [];
  final wings = ref.watch(wingListNotifierProvider).valueOrNull ?? const [];
  final moduleVariants = ref.watch(moduleVariantsProvider);
  final variantHullIdMap = ref.watch(variantHullIdMapProvider);
  // HashMap/HashSet: insertion order is maintained by the default map/set
  // types but never used here (lists are sorted below), and this is hot.
  final links = HashMap<CodexKey, Set<CodexKey>>();

  void addBoth(CodexKey a, CodexKey b) {
    if (a == b) return;
    links.putIfAbsent(a, HashSet.new).add(b);
    links.putIfAbsent(b, HashSet.new).add(a);
  }

  // Built once and shared across the ship loop below — resolveModules would
  // otherwise rebuild this map for every ship that has station slots.
  final shipById = <String, Ship>{for (final s in ships) s.id: s};

  // Stations live in their own category, so a hull's key type depends on whether
  // it's a station. Route every hull/ship key through this so links resolve to
  // the entry's real key.
  final stationIds = ships.where((s) => s.isStation).map((s) => s.id).toSet();
  CodexKey keyForHull(String id) => (
    stationIds.contains(id) ? CodexEntryType.station : CodexEntryType.ship,
    id,
  );

  for (final ship in ships) {
    final shipKey = keyForHull(ship.id);

    final systemId = ship.systemId;
    if (systemId != null && systemId.isNotEmpty) {
      addBoth(shipKey, (CodexEntryType.shipSystem, systemId));
    }

    // The ship's "Special" — a defensive system in place of a shield (Canister
    // Flak, Damper Field). Shown as a related entry, matching the in-game codex.
    // "NONE" means no special defense. The game skips this for real phase ships
    // (it doesn't list the phase cloak), so we skip 'phasecloak' too.
    final defenseId = ship.defenseId;
    if (defenseId != null &&
        defenseId.isNotEmpty &&
        defenseId.toUpperCase() != 'NONE' &&
        defenseId != 'phasecloak') {
      addBoth(shipKey, (CodexEntryType.shipSystem, defenseId));
    }
    for (final mod in ship.builtInMods ?? const <String>[]) {
      if (mod.isEmpty) continue;
      addBoth(shipKey, (CodexEntryType.hullmod, mod));
      // The game maps the hidden Vast Hangar hullmod to also show Converted
      // Hangar as a related entry (it boosts Converted Hangar). e.g. Invictus.
      if (mod == 'vast_hangar') {
        addBoth(shipKey, (CodexEntryType.hullmod, 'converted_hangar'));
      }
    }
    // Built-in weapons, but skip those in decorative or system slots — the
    // in-game codex leaves them off (e.g. the Invictus's lidar dishes).
    final slotTypeById = <String, String>{
      for (final slot in ship.weaponSlots ?? const []) slot.id: slot.typeUppercase,
    };
    for (final entry
        in (ship.builtInWeapons ?? const <String, String>{}).entries) {
      final slotType = slotTypeById[entry.key];
      if (slotType == 'DECORATIVE' || slotType == 'SYSTEM') continue;
      if (entry.value.isNotEmpty) {
        addBoth(shipKey, (CodexEntryType.weapon, entry.value));
      }
    }
    for (final wingId in ship.builtInWings ?? const <String>[]) {
      if (wingId.isNotEmpty) addBoth(shipKey, (CodexEntryType.wing, wingId));
    }

    // Station modules: the child ships that dock in this hull's STATION slots.
    // Matches the in-game codex, which lists a station's modules as related.
    for (final module in resolveModulesWithIndex(
      ship,
      shipById,
      moduleVariants,
      variantHullIdMap,
    )) {
      addBoth(shipKey, keyForHull(module.moduleShip.id));
    }
  }

  // Wing ↔ its ship (resolved hull id).
  for (final wing in wings) {
    final hullId = wing.hullId;
    if (hullId != null && hullId.isNotEmpty) {
      addBoth((CodexEntryType.wing, wing.id), keyForHull(hullId));
    }
  }

  // Skins: every ship sharing a baseHullId links to the others and to the base.
  final byBase = <String, List<Ship>>{};
  for (final ship in ships) {
    final base = ship.baseHullId;
    if (base != null && base.isNotEmpty) {
      byBase.putIfAbsent(base, () => []).add(ship);
    }
  }
  byBase.forEach((base, skins) {
    final baseKey = keyForHull(base);
    for (final skin in skins) {
      addBoth(keyForHull(skin.id), baseKey);
      for (final other in skins) {
        addBoth(keyForHull(skin.id), keyForHull(other.id));
      }
    }
  });

  // Manual "see also" pairs the game hard-codes in CodexDataV2, for links that
  // aren't derivable from the data. Ids that don't resolve to a visible entry
  // (missing, hidden, or spoiler-filtered) are simply dropped at display time.
  addBoth(
    (CodexEntryType.hullmod, 'neural_integrator'),
    (CodexEntryType.hullmod, 'automated'),
  );
  addBoth(
    (CodexEntryType.hullmod, 'design_compromises'),
    (CodexEntryType.hullmod, 'converted_hangar'),
  );
  addBoth(
    (CodexEntryType.hullmod, 'vast_hangar'),
    (CodexEntryType.hullmod, 'converted_hangar'),
  );
  addBoth(
    (CodexEntryType.shipSystem, 'displacer'),
    (CodexEntryType.shipSystem, 'displacer_degraded'),
  );
  addBoth(
    (CodexEntryType.wing, 'terminator_wing'),
    (CodexEntryType.shipSystem, 'drone_strike'),
  );
  addBoth(
    (CodexEntryType.weapon, 'vortex_launcher'),
    keyForHull('shrouded_vortex'),
  );

  // Freeze to deterministic lists (final display sort happens once names are
  // resolved; this just gives a stable order for anything that reads keys).
  return {
    for (final entry in links.entries)
      entry.key: (entry.value.toList()
        ..sort((a, b) {
          final byCat = codexCategoryRank(a.$1).compareTo(codexCategoryRank(b.$1));
          return byCat != 0 ? byCat : a.$2.compareTo(b.$2);
        })),
  };
});

/// Resolves the link keys for [entry] against the visible index and sorts them
/// by category order, then alphabetically by display name. Keys that resolve to
/// nothing (disabled mod, filtered out) are dropped.
List<CodexEntry> resolveCodexLinks(
  CodexKey entry,
  Map<CodexKey, List<CodexKey>> links,
  Map<CodexKey, CodexEntry> visibleByKey,
) {
  final keys = links[entry];
  if (keys == null) return const [];
  final resolved = <CodexEntry>[];
  for (final key in keys) {
    final target = visibleByKey[key];
    if (target != null) resolved.add(target);
  }
  resolved.sort((a, b) {
    final byCat = codexCategoryRank(a.type).compareTo(codexCategoryRank(b.type));
    if (byCat != 0) return byCat;
    return a.sortName.toLowerCase().compareTo(b.sortName.toLowerCase());
  });
  return resolved;
}
