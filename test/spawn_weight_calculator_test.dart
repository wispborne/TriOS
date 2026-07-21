import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/faction_viewer/spawn_weights/ship_roles_manager.dart';
import 'package:trios/faction_viewer/spawn_weights/spawn_weight_calculator.dart';
import 'package:trios/ship_viewer/models/ship.dart';

/// The shared default `combatSmall` list used by most tests: two loadouts of
/// `lasher` (a hull the test faction knows) and one of `hound` (which it
/// doesn't), plus one loadout of a ship that isn't installed.
MergedShipRoles _defaults({Map<String, double>? combatSmall}) {
  final weights =
      combatSmall ??
      const {
        'lasher_Assault': 10.0,
        'lasher_CS': 5.0,
        'hound_Standard': 8.0,
      };
  return MergedShipRoles(
    roles: {
      'combatSmall': DefaultShipRole(
        name: 'combatSmall',
        weights: weights,
        sources: {for (final id in weights.keys) id: kVanillaSourceName},
        fallbackRole: 'combatMedium',
      ),
    },
    sourceFiles: const {},
  );
}

SpawnWeightContext _context({
  MergedShipRoles? defaults,
  Map<String, String>? variantHullIds,
  List<Ship>? ships,
}) {
  final shipList =
      ships ??
      [
        Ship(id: 'lasher', name: 'Lasher', hullSize: 'FRIGATE', tags: ['heg']),
        Ship(id: 'hound', name: 'Hound', hullSize: 'FRIGATE', tags: ['pirate']),
      ];
  return SpawnWeightContext(
    defaults: defaults ?? _defaults(),
    variantHullIds:
        variantHullIds ??
        const {
          'lasher_Assault': 'lasher',
          'lasher_CS': 'lasher',
          'hound_Standard': 'hound',
        },
    shipsByHullId: {for (final ship in shipList) ship.id: ship},
  );
}

Faction _faction({
  List<String> knownShipIds = const ['lasher'],
  List<String> knownShipTags = const [],
  List<String> priorityShipIds = const [],
  List<String> priorityShipTags = const [],
  Map<String, dynamic>? shipRoles,
  Map<String, dynamic>? hullFrequency,
  Map<String, dynamic>? variantOverrides,
  Map<String, Map<String, String>> itemAttributions = const {},
}) => Faction(
  mergeKey: 'test',
  id: 'test',
  displayName: 'Test',
  knownShipIds: knownShipIds,
  knownShipTags: knownShipTags,
  priorityShipIds: priorityShipIds,
  priorityShipTags: priorityShipTags,
  shipRoles: shipRoles,
  hullFrequency: hullFrequency,
  variantOverrides: variantOverrides,
  itemAttributions: itemAttributions,
);

Map<String, double> _weightsOf(RoleWeightResult result) => {
  for (final entry in result.entries) entry.loadoutId: entry.weight,
};

RoleWeightResult _run(Faction faction, {SpawnWeightContext? context}) =>
    computeRoleWeights(
      faction: faction,
      roleName: 'combatSmall',
      context: context ?? _context(),
    );

void main() {
  group('computeRoleWeights', () {
    test('uses the shared default list and drops unknown hulls', () {
      final result = _run(_faction());

      expect(_weightsOf(result), {'lasher_Assault': 10.0, 'lasher_CS': 5.0});
      expect(result.entries.first.source, kVanillaSourceName);
      expect(result.entries.first.shipName, 'Lasher');
      expect(result.skippedEntries, 0);
    });

    test('a hull is known if one of its tags is known', () {
      final result = _run(
        _faction(knownShipIds: const [], knownShipTags: const ['pirate']),
      );

      expect(_weightsOf(result), {'hound_Standard': 8.0});
    });

    test('the faction list replaces the default list unless it opts in', () {
      final result = _run(
        _faction(
          shipRoles: {
            'combatSmall': {'lasher_Assault': 3},
          },
        ),
      );

      expect(_weightsOf(result), {'lasher_Assault': 3.0});
    });

    test('includeDefault keeps the shared list and overrides on top', () {
      final result = _run(
        _faction(
          shipRoles: {
            'combatSmall': {'includeDefault': true, 'lasher_Assault': 3},
          },
          itemAttributions: const {
            'shipRoles.combatSmall': {'lasher_Assault': 'TestMod'},
          },
        ),
      );

      expect(_weightsOf(result), {'lasher_Assault': 3.0, 'lasher_CS': 5.0});
      final assault = result.entries.firstWhere(
        (e) => e.loadoutId == 'lasher_Assault',
      );
      expect(assault.source, 'TestMod');
      expect(assault.origin, WeightOrigin.factionFile);
    });

    test('naming one loadout of a hull hides that hull\'s other loadouts', () {
      final result = _run(
        _faction(
          variantOverrides: {'lasher_CS': 7},
          itemAttributions: const {
            'variantOverrides': {'lasher_CS': 'TestMod'},
          },
        ),
      );

      expect(_weightsOf(result), {'lasher_CS': 7.0});
      expect(result.entries.single.source, 'TestMod');
    });

    test('hull and tag multipliers compound, on top of an override', () {
      final ships = [
        Ship(
          id: 'lasher',
          name: 'Lasher',
          hullSize: 'FRIGATE',
          tags: ['heg', 'xiv'],
        ),
      ];
      final result = _run(
        _faction(
          variantOverrides: {'lasher_Assault': 10},
          hullFrequency: {
            'hulls': {'lasher': 2},
            'tags': {'heg': 3, 'xiv': 0.5},
          },
        ),
        context: _context(
          ships: ships,
          variantHullIds: const {'lasher_Assault': 'lasher'},
          defaults: _defaults(combatSmall: const {'lasher_Assault': 1.0}),
        ),
      );

      // 10 (override) × 2 (hull) × 3 (heg) × 0.5 (xiv)
      expect(result.entries.single.weight, 30.0);
    });

    test('marks priority ships by hull id and by tag', () {
      final byHull = _run(_faction(priorityShipIds: const ['lasher']));
      expect(byHull.entries.every((e) => e.isPriority), isTrue);

      final byTag = _run(_faction(priorityShipTags: const ['heg']));
      expect(byTag.entries.every((e) => e.isPriority), isTrue);

      final none = _run(_faction());
      expect(none.entries.any((e) => e.isPriority), isFalse);
    });

    test('a zero weight never spawns, so it is left out', () {
      final result = _run(
        _faction(
          hullFrequency: {
            'hulls': {'lasher': 0},
          },
        ),
      );

      expect(result.entries, isEmpty);
    });

    test('loadouts with no installed ship are counted, not shown', () {
      final result = _run(
        _faction(),
        context: _context(
          defaults: _defaults(
            combatSmall: const {'lasher_Assault': 10.0, 'ghost_Standard': 5.0},
          ),
        ),
      );

      expect(_weightsOf(result), {'lasher_Assault': 10.0});
      expect(result.skippedEntries, 1);
    });
  });

  group('FactionSpawnSummary', () {
    test('vanilla share is the vanilla slice of total weight', () {
      const summary = FactionSpawnSummary(
        totalWeight: 100,
        unknownWeight: 0,
        weightBySource: {kVanillaSourceName: 20, 'BigMod': 80},
        skippedEntries: 0,
      );

      expect(summary.vanillaShare, 0.2);
      expect(summary.modWeight, 80);
      expect(summary.topMods.first.key, 'BigMod');
    });

    test('share is unknown when nothing is attributed yet', () {
      const summary = FactionSpawnSummary(
        totalWeight: 100,
        unknownWeight: 100,
        weightBySource: {},
        skippedEntries: 0,
      );

      expect(summary.vanillaShare, isNull);
    });

    test('share is unknown when the faction spawns no warships', () {
      expect(FactionSpawnSummary.empty.vanillaShare, isNull);
    });
  });
}
