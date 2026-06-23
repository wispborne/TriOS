import 'package:flutter_test/flutter_test.dart';
import 'package:trios/sector_map/finder/finder_criteria.dart';
import 'package:trios/sector_map/finder/finder_engine.dart';
import 'package:trios/sector_map/finder/hazard.dart';
import 'package:trios/sector_map/models/sector.dart';

SectorPlanet _planet(String type, List<String> conditions, {String name = ''}) =>
    SectorPlanet(
      name: name,
      type: type,
      conditionIds: conditions,
      hazardRating: computeHazardRating(conditions),
    );

SectorSystem _system(
  String id, {
  double x = 0,
  double y = 0,
  List<SectorPlanet> planets = const [],
  int stableLocs = 0,
  int marketSize = 0,
}) => SectorSystem(
  id: id,
  name: id,
  baseName: id,
  type: 'SINGLE',
  x: x,
  y: y,
  planets: planets,
  stableLocationCount: stableLocs,
  markets: marketSize > 0
      ? [SectorMarket(factionId: 'player', size: marketSize, name: id)]
      : const [],
);

void main() {
  group('FinderEngine', () {
    test('resource floor is best-of across planets', () {
      final sector = Sector(
        systems: [
          // System A: two planets, best ore is rich (tier 4).
          _system(
            'A',
            planets: [
              _planet('barren', ['ore_sparse']),
              _planet('rocky_metallic', ['ore_rich']),
            ],
          ),
          // System B: only sparse ore (tier 1).
          _system('B', planets: [_planet('barren', ['ore_sparse'])]),
        ],
      );
      final engine = FinderEngine(sector);

      // Floor of tier 4 keeps only A.
      final floor4 = const FinderCriteria(
        resources: {'ore': ResourceCriterion(minTier: 4)},
      );
      expect(engine.matchCount(floor4), 1);
      expect(engine.filter(floor4).single.system.id, 'A');

      // Floor of tier 1 keeps both.
      expect(
        engine.matchCount(
          const FinderCriteria(
            resources: {'ore': ResourceCriterion(minTier: 1)},
          ),
        ),
        2,
      );
    });

    test('hard toggles: habitable, gas giant, stable locations', () {
      final sector = Sector(
        systems: [
          _system('hab', planets: [_planet('terran', ['habitable'])]),
          _system('gas', planets: [_planet('gas_giant', ['volatiles_abundant'])]),
          _system('stable', stableLocs: 3, planets: [_planet('barren', [])]),
        ],
      );
      final engine = FinderEngine(sector);

      expect(
        engine.filter(const FinderCriteria(mustBeHabitable: true)).single.system.id,
        'hab',
      );
      expect(
        engine
            .filter(const FinderCriteria(mustHaveGasGiant: true))
            .single
            .system
            .id,
        'gas',
      );
      expect(
        engine
            .filter(const FinderCriteria(minStableLocations: 2))
            .single
            .system
            .id,
        'stable',
      );
    });

    test('excludeColonized drops systems with a faction colony', () {
      final sector = Sector(
        systems: [
          // Colonized: a faction market (non-neutral).
          _system(
            'colony',
            marketSize: 5,
            planets: [_planet('terran', ['habitable', 'ore_rich'])],
          ),
          // Pristine: only a neutral uninhabited-planet market.
          SectorSystem(
            id: 'pristine',
            name: 'pristine',
            baseName: 'pristine',
            type: 'SINGLE',
            x: 0,
            y: 0,
            markets: const [
              SectorMarket(factionId: 'neutral', size: 0, name: 'rock'),
            ],
            planets: [_planet('terran', ['habitable', 'ore_rich'])],
          ),
        ],
      );
      final engine = FinderEngine(sector);

      // Without the toggle, both habitable systems match.
      expect(
        engine.matchCount(const FinderCriteria(mustBeHabitable: true)),
        2,
      );
      // With it, only the pristine one survives.
      final ids = engine
          .filter(
            const FinderCriteria(mustBeHabitable: true, excludeColonized: true),
          )
          .map((s) => s.system.id)
          .toSet();
      expect(ids, {'pristine'});
    });

    test('landmark proximity uses system-to-system distance in LY', () {
      // Cryosleeper sits in system "cryo" at origin. "near" is 5 LY away
      // (5*2000=10000 units), "far" is 20 LY away.
      final sector = Sector(
        systems: [
          _system('cryo', x: 0, y: 0, planets: [_planet('barren', [])]),
          _system('near', x: 10000, y: 0, planets: [_planet('terran', ['habitable'])]),
          _system('far', x: 40000, y: 0, planets: [_planet('terran', ['habitable'])]),
        ],
        landmarks: const [
          SectorLandmark(
            typeId: 'derelict_cryosleeper',
            name: 'Test',
            systemId: 'cryo',
          ),
        ],
      );
      final engine = FinderEngine(sector);

      final near10 = const FinderCriteria(
        landmarkNearby: {'derelict_cryosleeper': true},
        nearbyRangeLy: 10,
      );
      final ids = engine.filter(near10).map((s) => s.system.id).toSet();
      // cryo (0 LY) and near (5 LY) are within 10 LY; far (20 LY) is not.
      expect(ids, containsAll(['cryo', 'near']));
      expect(ids, isNot(contains('far')));
    });

    test('scoring orders by weighted resource tier, best first', () {
      final sector = Sector(
        systems: [
          _system('poor', planets: [_planet('barren', ['ore_sparse'])]),
          _system('rich', planets: [_planet('barren', ['ore_ultrarich'])]),
        ],
      );
      final engine = FinderEngine(sector);
      final scored = engine.filter(
        const FinderCriteria(resources: {'ore': ResourceCriterion(weight: 1.0)}),
      );
      expect(scored.first.system.id, 'rich');
      expect(scored.last.system.id, 'poor');
      expect(scored.first.score, greaterThan(scored.last.score));
    });

    test('bottleneck reports the constraint that unlocks matches', () {
      final sector = Sector(
        systems: [
          // No habitable planet anywhere, but ore_rich exists.
          _system('A', planets: [_planet('barren', ['ore_rich'])]),
          _system('B', planets: [_planet('barren', ['ore_sparse'])]),
        ],
      );
      final engine = FinderEngine(sector);

      // Require habitable -> zero matches.
      final crit = const FinderCriteria(mustBeHabitable: true);
      expect(engine.matchCount(crit), 0);

      final hints = engine.bottleneck(crit);
      expect(hints, isNotEmpty);
      expect(hints.first.constraint, 'Habitable');
      expect(hints.first.countIfRemoved, 2);
    });

    test('hazard worked examples match the reference', () {
      expect(computeHazardRating(['habitable']), closeTo(0.75, 1e-9));
      expect(
        computeHazardRating(['very_hot', 'toxic_atmosphere', 'extreme_tectonic_activity']),
        closeTo(2.5, 1e-9),
      );
      expect(computeHazardRating([]), closeTo(1.0, 1e-9));
    });
  });
}
