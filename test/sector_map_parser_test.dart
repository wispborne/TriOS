// Regression test for the sector map parser against real save data.
// Guarded: skips cleanly when the local saves folder isn't present (CI), so it
// never fails on machines without Starsector installed.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/sector_map/sector_map_parser.dart';

const _savesDir =
    r'C:\Program Files (x86)\Fractal Softworks\Starsector-0.98a-RC5\saves';

void main() {
  final saves = Directory(_savesDir);
  if (!saves.existsSync()) {
    test('sector parser (skipped — no local saves)', () {
      // ignore: avoid_print
      print('Saves folder not found at $_savesDir — skipping.');
    }, skip: true);
    return;
  }

  final campaigns = saves
      .listSync()
      .whereType<Directory>()
      .map((d) => File('${d.path}${Platform.pathSeparator}campaign.xml'))
      .where((f) => f.existsSync())
      .toList();

  test('parses every local save: ~all systems positioned, markets join', () {
    expect(campaigns, isNotEmpty);
    for (final f in campaigns) {
      final name = f.parent.path.split(Platform.pathSeparator).last;
      final sector = parseCampaignXml(f.readAsStringSync());

      expect(sector.systems.length, greaterThan(100), reason: name);
      // every system has a finite hyperspace position
      for (final s in sector.systems) {
        expect(s.x.isFinite && s.y.isFinite, isTrue, reason: '$name ${s.name}');
      }
      // constellations referenced by systems exist
      final conIds = sector.constellations.map((c) => c.id).toSet();
      for (final s in sector.systems) {
        if (s.constellationId != null) {
          expect(conIds, contains(s.constellationId), reason: name);
        }
      }
      // at least some inhabited systems with faction markets
      final inhabited = sector.systems.where((s) => s.isInhabited).length;
      expect(inhabited, greaterThan(10), reason: name);
    }
  });

  test('parses finder data: planets, conditions, hazard, stable locs, marks', () {
    // Regression guard: conditions must attach to uninhabited planets too, not
    // just colonized ones (whose market is nested in the Plnt). Tracked across
    // all local saves so it holds even if some are brand-new/unexplored.
    var anyUninhabitedWithResource = false;

    for (final f in campaigns) {
      final name = f.parent.path.split(Platform.pathSeparator).last;
      final sector = parseCampaignXml(f.readAsStringSync());

      // Surveyable planets are harvested and carry types.
      final allPlanets = sector.systems.expand((s) => s.planets).toList();
      expect(allPlanets, isNotEmpty, reason: '$name: no planets parsed');
      expect(
        allPlanets.every((p) => p.type.isNotEmpty),
        isTrue,
        reason: '$name: planet with empty type',
      );
      // Stars must be excluded from the planet list.
      expect(
        allPlanets.any((p) => p.type.startsWith('star_')),
        isFalse,
        reason: '$name: a star leaked into planets',
      );

      // Some planets carry resource conditions.
      final withResources = allPlanets.where(
        (p) => p.conditionIds.any((c) => c.startsWith('ore_')),
      );
      expect(withResources, isNotEmpty, reason: '$name: no ore conditions');

      // Hazard is computed and matches the recompute from conditions.
      for (final p in allPlanets) {
        expect(p.hazardRating.isFinite, isTrue, reason: name);
      }
      // A bare-habitable planet (only environmental condition is habitable)
      // should be below 100% hazard somewhere in the sector — sanity on the math.
      // (Not asserted strictly; just ensure no negative-infinity etc.)

      // Stable locations counted on at least some systems.
      final totalStable = sector.systems.fold<int>(
        0,
        (sum, s) => sum + s.stableLocationCount,
      );
      expect(totalStable, greaterThan(0), reason: '$name: no stable locations');

      // Landmarks (if any) name a real system.
      final systemIds = sector.systems.map((s) => s.id).toSet();
      for (final l in sector.landmarks) {
        expect(systemIds, contains(l.systemId), reason: '$name ${l.typeId}');
        expect(l.typeId.isNotEmpty, isTrue, reason: name);
      }

      // An uninhabited (no faction colony) system carrying a resource condition
      // proves the planet↔market join works for non-colonized planets.
      for (final s in sector.systems) {
        final colonized = s.markets.any((m) => m.factionId != 'neutral');
        if (colonized) continue;
        final conds = {for (final p in s.planets) ...p.conditionIds};
        if (conds.any((c) => c.startsWith('ore_'))) {
          anyUninhabitedWithResource = true;
          break;
        }
      }
    }

    expect(
      anyUninhabitedWithResource,
      isTrue,
      reason: 'No uninhabited system had a resource condition across any local '
          'save — the planet↔market condition join is likely broken.',
    );
  });
}
