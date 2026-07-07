import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/codex/codex_index.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/ship_viewer/models/ship.dart';

typedef CodexKey = (CodexEntryType, String);

/// Category sort rank for related links, in the game's order:
/// ship systems → hullmods → weapons → fighters → ships → factions.
int codexCategoryRank(CodexEntryType type) => switch (type) {
  CodexEntryType.shipSystem => 0,
  CodexEntryType.hullmod => 1,
  CodexEntryType.weapon => 2,
  CodexEntryType.wing => 3,
  CodexEntryType.ship => 4,
  CodexEntryType.faction => 5,
};

/// Two-way "see also" links between entries, keyed by `(type, id)`. Computed
/// from the raw index; links are stored as keys and resolved to entries at
/// display time, so a key pointing at a disabled/filtered entry simply resolves
/// to nothing. Factions get no links in v1.
final codexLinksProvider = Provider<Map<CodexKey, List<CodexKey>>>((ref) {
  final index = ref.watch(codexIndexProvider);
  final links = <CodexKey, Set<CodexKey>>{};

  void addBoth(CodexKey a, CodexKey b) {
    if (a == b) return;
    links.putIfAbsent(a, () => {}).add(b);
    links.putIfAbsent(b, () => {}).add(a);
  }

  final ships = index.whereType<ShipCodexEntry>().map((e) => e.ship).toList();

  for (final ship in ships) {
    final shipKey = (CodexEntryType.ship, ship.id);

    final systemId = ship.systemId;
    if (systemId != null && systemId.isNotEmpty) {
      addBoth(shipKey, (CodexEntryType.shipSystem, systemId));
    }
    for (final mod in ship.builtInMods ?? const <String>[]) {
      if (mod.isNotEmpty) addBoth(shipKey, (CodexEntryType.hullmod, mod));
    }
    for (final weaponId
        in (ship.builtInWeapons ?? const <String, String>{}).values) {
      if (weaponId.isNotEmpty) {
        addBoth(shipKey, (CodexEntryType.weapon, weaponId));
      }
    }
    for (final wingId in ship.builtInWings ?? const <String>[]) {
      if (wingId.isNotEmpty) addBoth(shipKey, (CodexEntryType.wing, wingId));
    }
  }

  // Wing ↔ its ship (resolved hull id).
  for (final entry in index.whereType<WingCodexEntry>()) {
    final hullId = entry.wing.hullId;
    if (hullId != null && hullId.isNotEmpty) {
      addBoth(
        (CodexEntryType.wing, entry.wing.id),
        (CodexEntryType.ship, hullId),
      );
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
    final baseKey = (CodexEntryType.ship, base);
    for (final skin in skins) {
      addBoth((CodexEntryType.ship, skin.id), baseKey);
      for (final other in skins) {
        addBoth(
          (CodexEntryType.ship, skin.id),
          (CodexEntryType.ship, other.id),
        );
      }
    }
  });

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
