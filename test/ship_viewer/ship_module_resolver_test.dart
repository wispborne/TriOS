import 'package:flutter_test/flutter_test.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/models/ship_variant.dart';
import 'package:trios/ship_viewer/models/ship_weapon_slot.dart';
import 'package:trios/ship_viewer/ship_module_resolver.dart';

ShipWeaponSlot _stationSlot(String id) =>
    ShipWeaponSlot(id: id, type: 'STATION_MODULE');

ShipWeaponSlot _gunSlot(String id) =>
    ShipWeaponSlot(id: id, type: 'BALLISTIC', size: 'MEDIUM');

Ship _ship(String id, {List<ShipWeaponSlot>? slots}) =>
    Ship(id: id, name: id, weaponSlots: slots);

void main() {
  // A station with two docking points, and the two hulls that dock there.
  final station = _ship(
    'station',
    slots: [_stationSlot('WS0001'), _stationSlot('WS0002'), _gunSlot('WS0003')],
  );
  final gunModule = _ship('gun_module');
  final hangarModule = _ship('hangar_module');

  final stationVariant = ShipVariant(
    variantId: 'station_variant',
    hullId: 'station',
    modules: {'WS0001': 'gun_variant', 'WS0002': 'hangar_variant'},
  );

  const hullIds = {
    'station_variant': 'station',
    'gun_variant': 'gun_module',
    'hangar_variant': 'hangar_module',
  };

  group('resolveModules', () {
    test('pairs each station slot with the ship that docks there', () {
      final resolved = resolveModules(
        station,
        [station, gunModule, hangarModule],
        {'station_variant': stationVariant},
        hullIds,
      );

      expect(resolved, hasLength(2));
      expect(resolved[0].parentSlot.id, 'WS0001');
      expect(resolved[0].moduleShip.id, 'gun_module');
      expect(resolved[1].parentSlot.id, 'WS0002');
      expect(resolved[1].moduleShip.id, 'hangar_module');
    });

    test('a normal weapon slot is not a module slot', () {
      final resolved = resolveModules(
        station,
        [station, gunModule, hangarModule],
        {'station_variant': stationVariant},
        hullIds,
      );

      expect(resolved.map((r) => r.parentSlot.id), isNot(contains('WS0003')));
    });

    test('a ship with no station slots has no modules', () {
      final frigate = _ship('frigate', slots: [_gunSlot('WS0001')]);

      expect(
        resolveModules(
          frigate,
          [frigate],
          {'station_variant': stationVariant},
          hullIds,
        ),
        isEmpty,
      );
    });

    test('a ship with no slots at all has no modules', () {
      expect(
        resolveModules(gunModule, [gunModule], const {}, const {}),
        isEmpty,
      );
    });

    test('no variant for this hull means no modules', () {
      final otherHullVariant = ShipVariant(
        variantId: 'other_variant',
        hullId: 'some_other_station',
        modules: {'WS0001': 'gun_variant'},
      );

      expect(
        resolveModules(station, [station, gunModule], {
          'other_variant': otherHullVariant,
        }, hullIds),
        isEmpty,
      );
    });

    test('a slot the variant says nothing about is skipped', () {
      final onlyFirst = ShipVariant(
        variantId: 'station_variant',
        hullId: 'station',
        modules: {'WS0001': 'gun_variant'},
      );

      final resolved = resolveModules(
        station,
        [station, gunModule, hangarModule],
        {'station_variant': onlyFirst},
        hullIds,
      );

      expect(resolved, hasLength(1));
      expect(resolved.single.parentSlot.id, 'WS0001');
    });

    test('a module whose variant is unknown is skipped', () {
      final resolved = resolveModules(
        station,
        [station, gunModule, hangarModule],
        {'station_variant': stationVariant},
        // 'hangar_variant' is missing, e.g. the mod that added it is gone.
        const {'station_variant': 'station', 'gun_variant': 'gun_module'},
      );

      expect(resolved.map((r) => r.moduleShip.id), ['gun_module']);
    });

    test('a module hull that no mod actually ships is skipped', () {
      final resolved = resolveModules(
        station,
        // hangar_module is named by the variant but is not in the ship list.
        [station, gunModule],
        {'station_variant': stationVariant},
        hullIds,
      );

      expect(resolved.map((r) => r.moduleShip.id), ['gun_module']);
    });
  });

  group('computeModuleShipIds', () {
    test("lists the hulls used as another ship's module", () {
      expect(
        computeModuleShipIds({'station_variant': stationVariant}, hullIds),
        {'gun_module', 'hangar_module'},
      );
    });

    test('the parent station itself is not a module', () {
      expect(
        computeModuleShipIds({'station_variant': stationVariant}, hullIds),
        isNot(contains('station')),
      );
    });

    test('a hull docked by two different stations is listed once', () {
      final secondStation = ShipVariant(
        variantId: 'station2_variant',
        hullId: 'station2',
        modules: {'WS0001': 'gun_variant'},
      );

      expect(
        computeModuleShipIds({
          'station_variant': stationVariant,
          'station2_variant': secondStation,
        }, {...hullIds, 'station2_variant': 'station2'}),
        {'gun_module', 'hangar_module'},
      );
    });

    test('a variant with no modules adds nothing', () {
      final plain = ShipVariant(variantId: 'plain', hullId: 'frigate');
      expect(computeModuleShipIds({'plain': plain}, hullIds), isEmpty);
    });

    test('a module variant with no known hull is left out', () {
      expect(
        computeModuleShipIds({'station_variant': stationVariant}, const {}),
        isEmpty,
      );
    });

    test('no variants means no module ships', () {
      expect(computeModuleShipIds(const {}, const {}), isEmpty);
    });
  });

  group('computeShipsWithModuleIds', () {
    test('lists only the ships that actually dock something', () {
      expect(
        computeShipsWithModuleIds(
          [station, gunModule, hangarModule],
          {'station_variant': stationVariant},
          hullIds,
        ),
        {'station'},
      );
    });

    test('a station whose modules cannot be found is left out', () {
      expect(
        computeShipsWithModuleIds(
          [station],
          {'station_variant': stationVariant},
          hullIds,
        ),
        isEmpty,
      );
    });
  });

  group('the two sets answer different questions', () {
    test('"is a module" and "has modules" do not overlap here', () {
      final areModules = computeModuleShipIds({
        'station_variant': stationVariant,
      }, hullIds);
      final haveModules = computeShipsWithModuleIds(
        [station, gunModule, hangarModule],
        {'station_variant': stationVariant},
        hullIds,
      );

      expect(areModules.intersection(haveModules), isEmpty);
    });
  });
}
