import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';

/// The game reads every number in `weapon_data.csv` with `optDouble`/`optInt`,
/// which quietly fall back to a default when the cell holds something that
/// isn't a number. These cover the same rows that used to make TriOS throw the
/// whole weapon away. The bad values are real ones, taken from installed mods.
void main() {
  Map<String, dynamic> row(Map<String, dynamic> overrides) => {
    'id': 'test_weapon',
    'name': 'Test Weapon',
    ...overrides,
  };

  CleanedNumbers clean(Map<String, dynamic> data) =>
      blankUnusableNumbers(WeaponMapper.ensureInitialized(), data);

  group('unusable numbers in weapon_data.csv', () {
    test('a word where a number belongs is blanked, not thrown', () {
      // Arma Armatura's header is missing two columns, so its rows sit one
      // over and "DS" lands in energy/second.
      final cleaned = clean(row({'energy/second': 'DS', 'range': 500}));
      final weapon = WeaponMapper.fromMap(cleaned.data);

      expect(weapon.id, 'test_weapon');
      expect(weapon.energyPerSecond, isNull);
      expect(weapon.range, 500);
    });

    test('the message names the column and what was in it', () {
      final cleaned = clean(row({'energy/second': 'DS'}));

      expect(cleaned.errors.keys, ['energyPerSecond']);
      expect(
        cleaned.errors['energyPerSecond'],
        '"energy/second" is "DS", which is not a number.',
      );
    });

    test('a typo with two dots is blanked', () {
      // Gensoukyou Manufacture writes burst delay as "0.0.05".
      final cleaned = clean(row({'burst delay': '0.0.05'}));

      expect(WeaponMapper.fromMap(cleaned.data).burstDelay, isNull);
      expect(cleaned.errors.keys, ['burstDelay']);
    });

    test('a repeated header row is read instead of dropped', () {
      // Crown Constellation repeats its header partway down the file, so the
      // int column "tier" holds the word "tier".
      final cleaned = clean({'id': 'id', 'name': 'name', 'tier': 'tier'});
      final weapon = WeaponMapper.fromMap(cleaned.data);

      expect(weapon.tier, isNull);
      expect(cleaned.errors.keys, ['tier']);
    });

    test('several bad cells in one row are all reported', () {
      final cleaned = clean(
        row({'chargedown': 'AA', 'autofireaccbonus': 'SYSTEM'}),
      );

      expect(
        cleaned.errors.keys,
        unorderedEquals(['chargedown', 'autofireAccBonus']),
      );
    });

    test('good rows are handed back untouched', () {
      final data = row({'range': 500, 'chargedown': '0.4', 'tier': 2});
      final cleaned = clean(data);

      expect(cleaned.errors, isEmpty);
      expect(identical(cleaned.data, data), isTrue);
    });

    test('text columns keep their text', () {
      final cleaned = clean(row({'hints': 'PD', 'type': 'KINETIC'}));
      final weapon = WeaponMapper.fromMap(cleaned.data);

      expect(cleaned.errors, isEmpty);
      expect(weapon.hints, 'PD');
      expect(weapon.type, 'KINETIC');
    });

    test('extraArcForAI reads as a number, the way the game reads it', () {
      // voltaic_discharge in vanilla.
      final weapon = WeaponMapper.fromMap(row({'extraarcforai': 360}));

      expect(weapon.extraArcForAI, 360);
    });
  });
}
