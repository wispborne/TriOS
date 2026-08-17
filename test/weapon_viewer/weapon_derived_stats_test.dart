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

    test(
      'flux from a chargeup drain is spread over every barrel\'s damage',
      () {
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
      },
    );

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

  group('DUAL_LINKED barrels', () {
    test('a DUAL_LINKED weapon doubles, whatever its offsets say', () {
      // The game hardcodes 2 for DUAL_LINKED; the offsets are not consulted.
      final w = weapon({
        'damage/shot': 100,
        'chargedown': 1,
        'specclass': 'projectile',
        'barrelmode': 'DUAL_LINKED',
        'turretoffsets': [10.0, 0.0],
      });
      expect(w.effectiveDps, closeTo(200, 0.001));
      expect(w.displayBurstSize, 2);
    });

    test('plain DUAL is not a real mode and must not multiply', () {
      // The game's enum parse rejects "DUAL" outright (it crashes the load),
      // so a .wpn carrying it gets no multiplier anywhere.
      final w = weapon({
        'damage/shot': 100,
        'chargedown': 1,
        'specclass': 'projectile',
        'barrelmode': 'DUAL',
        'turretoffsets': [10.0, 0.0],
      });
      expect(w.effectiveDps, closeTo(100, 0.001));
      expect(w.displayBurstSize, 1);
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

    test('regen without an ammo cap is ignored, like the game', () {
      // BaseWeaponSpec.usesAmmo() requires the CSV `ammo` column; a weapon
      // with only `ammo/sec` keeps a single DPS number.
      final w = weapon({
        'damage/shot': 100,
        'chargedown': 1,
        'ammo/sec': 0.5,
        'specclass': 'projectile',
      });
      expect(w.sustainedDps, isNull);
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

  group('burst beams', () {
    /// Vanilla Tachyon Lance. Its `beamFireOnlyOnFullCharge` is commented
    /// out, so the full chargeup feeds the damage ramp: the game shows
    /// Damage 2249, DPS 346, refire 6.5.
    Weapon tachyon({Map<String, dynamic> overrides = const {}}) => weapon({
      'id': 'tachyonlance',
      'damage/second': 1500,
      'energy/second': 2000,
      'emp': 1000,
      'chargeup': 0.5,
      'chargedown': 1,
      'burst size': 1,
      'burst delay': 4,
      'specclass': 'beam',
      ...overrides,
    });

    test('Tachyon Lance matches its in-game numbers', () {
      final w = tachyon();
      expect(w.burstDamage, closeTo(2249.25, 0.01));
      expect(w.effectiveDps, closeTo(346.04, 0.01));
      expect(w.refireDelay, closeTo(6.5, 0.001));
      // EMP per burst: emp × the same ramp. 1000 × 1.4995.
      expect(w.empPerActivation, closeTo(1499.5, 0.01));
    });

    test('beamFireOnlyOnFullCharge drops the chargeup from the ramp only', () {
      // DME's Tactical Beamer: chargeup 0.1, chargedown 1.2, burst 0.6,
      // delay 0.5, 240 damage/second, flag on. Game: Damage 240, DPS 100.
      final w = weapon({
        'damage/second': 240,
        'chargeup': 0.1,
        'chargedown': 1.2,
        'burst size': 0.6,
        'burst delay': 0.5,
        'specclass': 'beam',
        'beamfireonlyonfullcharge': true,
      });
      expect(w.burstDamage, closeTo(239.90, 0.01));
      expect(w.effectiveDps, closeTo(99.96, 0.01));
      // The refire cycle keeps the real chargeup.
      expect(w.refireDelay, closeTo(2.4, 0.001));
    });

    test('skipIdleFrameIfZeroBurstDelay displays as a continuous beam', () {
      // Vanilla IR Autolance: a 0.1s burst beam with the flag — the game
      // shows no per-burst Damage row, and DPS 500 (100).
      final w = weapon({
        'damage/second': 500,
        'energy/second': 150,
        'chargeup': 0,
        'chargedown': 0,
        'burst size': 0.1,
        'ammo': 40,
        'ammo/sec': 2,
        'reload size': 10,
        'specclass': 'beam',
        'skipidleframeifzeroburstdelay': true,
      });
      expect(w.tooltipDisplay.displayAsBurstBeam, isFalse);
      expect(w.effectiveDps, closeTo(500, 0.001));
      expect(w.sustainedDps, closeTo(100, 0.001));
    });
  });

  group('interruptible and giant bursts', () {
    /// SEEKER's Minigun: burst 99999, delay 0.10, chargeup 0.25,
    /// chargedown 1, interruptible. The game shows Refire delay 1, no burst
    /// size row, and "600 (600)".
    Weapon minigun() => weapon({
      'damage/shot': 60,
      'chargeup': 0.25,
      'chargedown': 1,
      'burst size': 99999,
      'burst delay': 0.10,
      'ammo': 200,
      'ammo/sec': 10,
      'specclass': 'projectile',
      'interruptibleburst': true,
    });

    test(
      'an interruptible burst shows bare chargedown as the refire delay',
      () {
        expect(minigun().refireDelay, closeTo(1, 0.001));
      },
    );

    test('an interruptible burst hides the burst rows', () {
      expect(minigun().displayBurstSize, 1);
      expect(minigun().tooltipDisplay.showBurstRow, isFalse);
      expect(minigun().tooltipDisplay.showDamageTimesBurst, isFalse);
    });

    test('DPS still counts the whole burst cycle', () {
      // 60 × 99999 / (0.25 + 1 + 0.1 × 99998) ≈ 599.93.
      expect(minigun().effectiveDps, closeTo(599.93, 0.01));
    });

    test('sustained DPS shows whenever the floats differ at all', () {
      // The game compares with plain != and prints "600 (600)" here; the old
      // 1% threshold would have hidden it.
      expect(minigun().sustainedDps, closeTo(600, 0.001));
    });

    test(
      'a 100+ round burst drops the in-burst delays from the refire delay',
      () {
        final w = weapon({
          'damage/shot': 60,
          'chargeup': 0.25,
          'chargedown': 1,
          'burst size': 200,
          'burst delay': 0.10,
          'specclass': 'projectile',
        });
        expect(w.refireDelay, closeTo(1.25, 0.001));
      },
    );
  });

  group('MIRV missiles', () {
    /// Vanilla Sabot SRM: CSV damage 100, but the missile splits into five
    /// 200-damage submunitions. Game: Damage 200x5, EMP 200x5, DPS 1000.
    Weapon sabot() => weapon({
      'id': 'sabot',
      'damage/shot': 100,
      'chargeup': 0,
      'chargedown': 1,
      'burst size': 1,
      'ammo': 3,
      'proj hitpoints': 300,
      'specclass': 'projectile',
      'missiletype': 'MIRV',
      'mirvdamage': 200.0,
      'mirvemp': 200.0,
      'mirvnumshots': 5,
      'mirvhitpoints': 500.0,
    });

    test('per-shot damage is the submunitions\' total', () {
      expect(sabot().mirvTotalDamage, closeTo(1000, 0.001));
      expect(sabot().effectiveDps, closeTo(1000, 0.001));
    });

    test('a missile without MIRV data keeps its CSV damage', () {
      final w = weapon({
        'damage/shot': 100,
        'chargedown': 1,
        'specclass': 'projectile',
        'missiletype': 'MISSILE',
      });
      expect(w.mirvTotalDamage, isNull);
      expect(w.effectiveDps, closeTo(100, 0.001));
    });

    test('missiles always get the xN suffix when bursting', () {
      // The game's magazine check only applies to gun projectiles: a missile
      // whose ammo equals its burst size still shows "xN".
      final missile = weapon({
        'damage/shot': 100,
        'chargedown': 1,
        'burst size': 4,
        'ammo': 4,
        'specclass': 'projectile',
        'missiletype': 'MISSILE',
      });
      expect(missile.tooltipDisplay.showDamageTimesBurst, isTrue);

      final gun = weapon({
        'damage/shot': 100,
        'chargedown': 1,
        'burst size': 4,
        'ammo': 4,
        'specclass': 'projectile',
      });
      expect(gun.tooltipDisplay.showDamageTimesBurst, isFalse);
    });
  });
}
