import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/models/weapons_cache_payload.dart';
import 'package:trios/weapon_viewer/weapons_manager.dart';

/// Stands in for the real scanner so tests can hand it fixed raw data.
class _FakeWeaponListNotifier extends WeaponListNotifier {
  _FakeWeaponListNotifier(this.payloads);

  final List<WeaponsCachePayload> payloads;

  @override
  Stream<List<WeaponsCachePayload>> build() => Stream.value(payloads);
}

ModVariant _variant(String name) => ModVariant(
  modInfo: ModInfo(
    id: name.toLowerCase().replaceAll(' ', '_'),
    name: name,
    version: Version.parse('1.0.0'),
  ),
  versionCheckerInfo: null,
  modFolder: Directory('mods/$name'),
  hasNonBrickedModInfo: true,
  gameCoreFolder: Directory('core'),
);

Mod _mod(ModVariant variant) =>
    Mod(id: variant.modInfo.id, isEnabledInGame: true, modVariants: [variant]);

Future<List<Weapon>> _build({
  required List<WeaponsCachePayload> payloads,
  required List<Mod> mods,
}) async {
  final container = ProviderContainer(
    overrides: [
      weaponSourcesProvider.overrideWith(
        () => _FakeWeaponListNotifier(payloads),
      ),
      AppState.mods.overrideWithValue(mods),
    ],
  );
  addTearDown(container.dispose);

  await container.read(weaponSourcesProvider.future);
  return container.read(weaponListNotifierProvider).valueOrNull ?? const [];
}

void main() {
  group('weaponListNotifierProvider', () {
    test('a mod\'s rebalanced row beats vanilla\'s', () async {
      final rebalance = _variant('Rebalance');

      final weapons = await _build(
        payloads: [
          WeaponsCachePayload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {'id': 'lightmg', 'name': 'Light MG', 'damage/shot': 10},
            ],
            wpnFiles: {
              'lightmg.wpn': {'id': 'lightmg', 'turretSprite': 'vanilla.png'},
            },
          ),
          WeaponsCachePayload(
            sourceKey: rebalance.smolId,
            rows: [
              {'id': 'lightmg', 'name': 'Light MG', 'damage/shot': 99},
            ],
            wpnFiles: const {},
          ),
        ],
        mods: [_mod(rebalance)],
      );

      final mg = weapons.single;
      expect(mg.damagePerShot, 99, reason: 'the mod wins the stats, not vanilla');
      expect(
        mg.turretSprite,
        'vanilla.png',
        reason: 'and vanilla\'s sprite is still paired in',
      );
      expect(mg.modVariant?.modInfo.name, 'Rebalance');
      expect(
        mg.spriteModVariant,
        isNull,
        reason: 'the sprite came from vanilla, which has no mod variant',
      );
    });

    test('the Blackrock case: add-on stats, parent mod sprite', () async {
      final addon = _variant('Blackrock 0.97 Unofficial Add-on');
      final parent = _variant('Blackrock Drive Yards');

      final weapons = await _build(
        payloads: [
          WeaponsCachePayload(
            sourceKey: parent.smolId,
            rows: [
              {'id': 'homing_laser', 'name': 'Homing Laser', 'damage/shot': 250},
            ],
            wpnFiles: {
              'homing_laser.wpn': {
                'id': 'homing_laser',
                'turretSprite': 'brdy/homing_laser.png',
              },
            },
          ),
          // The add-on ships a full weapon_data.csv and no .wpn files at all.
          WeaponsCachePayload(
            sourceKey: addon.smolId,
            rows: [
              {'id': 'homing_laser', 'name': 'Homing Laser', 'damage/shot': 300},
            ],
            wpnFiles: const {},
          ),
        ],
        mods: [_mod(addon), _mod(parent)],
      );

      final laser = weapons.single;
      expect(laser.damagePerShot, 300);
      expect(laser.turretSprite, 'brdy/homing_laser.png');
      expect(laser.modVariant?.modInfo.name, 'Blackrock 0.97 Unofficial Add-on');
      expect(laser.spriteModVariant?.modInfo.name, 'Blackrock Drive Yards');
    });

    test('a partial .wpn keeps the fields it does not mention', () async {
      final tweak = _variant('Z-tweak');

      final weapons = await _build(
        payloads: [
          WeaponsCachePayload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {'id': 'laser', 'name': 'Laser'},
            ],
            wpnFiles: {
              'laser.wpn': {
                'id': 'laser',
                'turretSprite': 'base.png',
                'specClass': 'beam',
              },
            },
          ),
          WeaponsCachePayload(
            sourceKey: tweak.smolId,
            rows: const [],
            wpnFiles: {
              'laser.wpn': {'id': 'laser', 'turretSprite': 'tweaked.png'},
            },
          ),
        ],
        mods: [_mod(tweak)],
      );

      final laser = weapons.single;
      expect(laser.turretSprite, 'tweaked.png');
      expect(laser.specClass, 'beam');
      expect(laser.spriteModVariant?.modInfo.name, 'Z-tweak');
    });

    test('a row with no .wpn anywhere still appears, without a sprite', () async {
      final weapons = await _build(
        payloads: [
          WeaponsCachePayload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {'id': 'orphan', 'name': 'Orphan'},
            ],
            wpnFiles: const {},
          ),
        ],
        mods: const [],
      );

      expect(weapons.single.id, 'orphan');
      expect(weapons.single.turretSprite, isNull);
    });
  });
}
