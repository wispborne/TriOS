import 'package:flutter_test/flutter_test.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';

/// The stats TriOS derives from a weapon's raw CSV + .wpn data, checked
/// against numbers the game itself shows in its tooltips. The game multiplies
/// a shot by the number of barrels when `barrelMode` is LINKED (all barrels
/// fire together), and by 2 for DUAL — see `WeaponSpreadsheetLoader` and the
/// weapon tooltip in `CargoTooltipFactory`.
///
/// Expected values come from in-game tooltips (screenshots), not from
/// re-running TriOS's own formulas.
void main() {
  Weapon weapon(Map<String, dynamic> overrides) => WeaponMapper.fromMap({
    'id': 'test_weapon',
    'name': 'Test Weapon',
    ...overrides,
  });

  /// The Solis Cannon (Interstellar Imperium): a twin-barreled LINKED cannon.
  /// Its CSV says damage 325, burst size 1 — but both barrels fire each shot,
  /// so the game shows 325x2 and DPS 271.
  Weapon solis() => weapon({
    'id': 'ii_solis',
    'damage/shot': 325,
    'energy/shot': 330,
    'chargeup': 0.2,
    'chargedown': 2.2,
    'burst size': 1,
    'specclass': 'projectile',
    'barrelmode': 'LINKED',
    'turretoffsets': [20.0, 4.0, 20.0, -4.0],
  });

  group('LINKED barrels (Solis Cannon)', () {
    test('damage / second counts both barrels', () {
      // Game tooltip: 271. (650 damage per pull, one pull per 2.4s.)
      expect(solis().effectiveDps, closeTo(270.8, 0.1));
    });

    test('flux / second counts both barrels', () {
      // Game tooltip: 275. (660 flux per pull, one pull per 2.4s.)
      expect(solis().fluxPerSecond, closeTo(275, 0.5));
    });

    test('flux / damage is unchanged — the barrels cancel out', () {
      // Game tooltip: 1.02, same as a single barrel (330/325 = 660/650).
      expect(solis().fluxPerDamage, closeTo(1.015, 0.005));
    });

    test('refire delay is per trigger pull, not per barrel', () {
      // Game tooltip: 2.4 (chargeup 0.2 + chargedown 2.2).
      expect(solis().refireDelay, closeTo(2.4, 0.001));
    });

    test('flux from a chargeup drain is spread over every barrel\'s damage', () {
      // WeaponSpreadsheetLoader: totalFlux = chargeup * energy/second
      //                                    + energy/shot * burst * barrels.
      // Worked example: (1*20 + 50*1*2) / (100*2*1) = 120/200 = 0.6.
      final w = weapon({
        'damage/shot': 100,
        'energy/shot': 50,
        'energy/second': 20,
        'chargeup': 1,
        'chargedown': 1,
        'burst size': 1,
        'specclass': 'projectile',
        'barrelmode': 'LINKED',
        'turretoffsets': [10.0, 2.0, 10.0, -2.0],
      });
      expect(w.fluxPerDamage, closeTo(0.6, 0.001));
    });

    test('the shown burst size counts the barrels', () {
      // Game tooltip: "Damage 325x2" and "Burst size 2", from a CSV burst
      // size of 1 — CargoTooltipFactory multiplies by barrels for display.
      expect(solis().displayBurstSize, 2);
    });

    test('a real burst multiplies with the barrels', () {
      // A 3-round burst through 2 linked barrels shows as 6.
      final w = weapon({
        'damage/shot': 100,
        'burst size': 3,
        'chargedown': 1,
        'specclass': 'projectile',
        'barrelmode': 'LINKED',
        'turretoffsets': [10.0, 2.0, 10.0, -2.0],
      });
      expect(w.displayBurstSize, 6);
    });
  });

  group('DUAL barrels', () {
    test('a DUAL weapon doubles, whatever its offsets say', () {
      // The game hardcodes 2 for DUAL; the offsets are not consulted.
      final w = weapon({
        'damage/shot': 100,
        'chargedown': 1,
        'specclass': 'projectile',
        'barrelmode': 'DUAL',
        'turretoffsets': [10.0, 0.0],
      });
      expect(w.effectiveDps, closeTo(200, 0.001));
      expect(w.displayBurstSize, 2);
    });
  });

  group('weapons the multiplier must not touch', () {
    test('ALTERNATING barrels fire one at a time', () {
      // The common case — a twin-barrel autocannon alternates, so two
      // offsets do not mean two shots.
      final w = weapon({
        'damage/shot': 100,
        'chargedown': 1,
        'specclass': 'projectile',
        'barrelmode': 'ALTERNATING',
        'turretoffsets': [10.0, 2.0, 10.0, -2.0],
      });
      expect(w.effectiveDps, closeTo(100, 0.001));
      expect(w.displayBurstSize, 1);
    });

    test('no barrelMode at all means one shot per pull', () {
      final w = weapon({
        'damage/shot': 100,
        'chargedown': 1,
        'specclass': 'projectile',
        'turretoffsets': [10.0, 2.0, 10.0, -2.0],
      });
      expect(w.effectiveDps, closeTo(100, 0.001));
      expect(w.displayBurstSize, 1);
    });

    test('LINKED with a single barrel changes nothing', () {
      // Vanilla\'s LINKED weapons (Typhoon, Annihilator) are all one-barrel.
      final w = weapon({
        'damage/shot': 4000,
        'chargedown': 15,
        'specclass': 'projectile',
        'barrelmode': 'LINKED',
        'turretoffsets': [20.0, 0.0],
      });
      expect(w.effectiveDps, closeTo(4000 / 15, 0.01));
      expect(w.displayBurstSize, 1);
    });

    test('a LINKED beam keeps its plain beam DPS', () {
      // Vanilla\'s devouring_swarm is a LINKED beam; beam DPS comes straight
      // from damage/second and must ignore barrels.
      final w = weapon({
        'damage/second': 300,
        'energy/second': 150,
        'specclass': 'beamweapon',
        'barrelmode': 'LINKED',
        'turretoffsets': [10.0, 2.0, 10.0, -2.0],
      });
      expect(w.effectiveDps, closeTo(300, 0.001));
      expect(w.fluxPerDamage, closeTo(0.5, 0.001));
    });

    test('sustained DPS is ammo-bound, so the barrels cancel out', () {
      // WeaponSpreadsheetLoader: sustained = shot damage * barrels
      //                                    / (barrels / ammo per second)
      // — the barrel count cancels. Firing 650 per pull does not refill the
      // magazine any faster.
      final w = weapon({
        'damage/shot': 100,
        'chargedown': 1,
        'ammo': 20,
        'ammo/sec': 0.5,
        'reload size': 1,
        'specclass': 'projectile',
        'barrelmode': 'LINKED',
        'turretoffsets': [10.0, 2.0, 10.0, -2.0],
      });
      expect(w.effectiveDps, closeTo(200, 0.001), reason: 'burst DPS doubles');
      expect(
        w.sustainedDps,
        closeTo(50, 0.001),
        reason: 'sustained DPS must not double',
      );
    });
  });
}
