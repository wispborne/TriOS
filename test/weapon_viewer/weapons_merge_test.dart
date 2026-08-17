import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/app_state.dart';
import 'package:path/path.dart' as p;
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/utils/game_file_resolver.dart';
import 'package:trios/viewer_cache/graphics_index_manager.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/models/weapons_cache_payload.dart';
import 'package:trios/weapon_viewer/weapons_manager.dart';

import '../riverpod_test_helpers.dart';

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

Mod _mod(ModVariant variant, {bool enabled = true}) =>
    Mod(id: variant.modInfo.id, isEnabledInGame: enabled, modVariants: [variant]);

/// A source that ships the given images, spelled as they are on disk.
GameFileSource _source(String folder, List<String> imageFiles) =>
    GameFileSource(
      folderPath: folder,
      imageFiles: {for (final file in imageFiles) file.toLowerCase(): file},
    );

/// The path the resolver builds for an image in [folder]. The resolver hands
/// back absolute paths, and these test folders are relative.
String _imageIn(String folder, String relativePath) =>
    p.normalize(File(p.join(folder, relativePath)).absolute.path);

Future<List<Weapon>> _build({
  required List<WeaponsCachePayload> payloads,
  required List<Mod> mods,
  List<GameFileSource> imageSources = const [],
  bool onlyEnabledMods = false,
}) async {
  final container = createTestContainer(
    overrides: [
      weaponSourcesProvider.overrideWith(
        () => _FakeWeaponListNotifier(payloads),
      ),
      AppState.mods.overrideWithValue(mods),
      gameFileResolverProvider.overrideWith(
        (ref, _) => GameFileResolver(imageSources),
      ),
    ],
  );

  await awaitFirstValue(container, weaponSourcesProvider);
  return container
          .read(weaponListNotifierProvider(onlyEnabledMods))
          .value ??
      const [];
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
              'lightmg.wpn': {
                'id': 'lightmg',
                'turretSprite': 'graphics/weapons/lightmg.png',
              },
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
        imageSources: [
          _source('mods/Rebalance', const []),
          _source('core', const ['graphics/weapons/lightmg.png']),
        ],
      );

      final mg = weapons.single;
      expect(mg.damagePerShot, 99, reason: 'the mod wins the stats, not vanilla');
      expect(
        mg.turretSprite,
        _imageIn('core', 'graphics/weapons/lightmg.png'),
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
                'turretSprite': 'graphics/brdy/homing_laser.png',
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
        imageSources: [
          _source('mods/Blackrock 0.97 Unofficial Add-on', const []),
          _source('mods/Blackrock Drive Yards', const [
            'graphics/brdy/homing_laser.png',
          ]),
          _source('core', const []),
        ],
      );

      final laser = weapons.single;
      expect(laser.damagePerShot, 300);
      expect(
        laser.turretSprite,
        _imageIn('mods/Blackrock Drive Yards', 'graphics/brdy/homing_laser.png'),
      );
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
                'turretSprite': 'graphics/weapons/base.png',
                'specClass': 'beam',
              },
            },
          ),
          WeaponsCachePayload(
            sourceKey: tweak.smolId,
            rows: const [],
            wpnFiles: {
              'laser.wpn': {
                'id': 'laser',
                'turretSprite': 'graphics/weapons/tweaked.png',
              },
            },
          ),
        ],
        mods: [_mod(tweak)],
        imageSources: [
          _source('mods/Z-tweak', const ['graphics/weapons/tweaked.png']),
          _source('core', const ['graphics/weapons/base.png']),
        ],
      );

      final laser = weapons.single;
      expect(
        laser.turretSprite,
        _imageIn('mods/Z-tweak', 'graphics/weapons/tweaked.png'),
      );
      expect(laser.specClass, 'beam');
      expect(laser.spriteModVariant?.modInfo.name, 'Z-tweak');
    });

    test('barrelMode rides along from the .wpn into the stats', () async {
      // The Solis Cannon case: a LINKED twin-barrel weapon fires both barrels
      // per shot, so its DPS doubles. A mod rebalancing only the CSV row must
      // not lose the vanilla .wpn's barrel wiring.
      final rebalance = _variant('Rebalance');

      final weapons = await _build(
        payloads: [
          WeaponsCachePayload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {
                'id': 'twin',
                'name': 'Twin Cannon',
                'damage/shot': 100,
                'chargedown': 1,
              },
            ],
            wpnFiles: {
              'twin.wpn': {
                'id': 'twin',
                'specClass': 'projectile',
                'barrelMode': 'LINKED',
                'turretOffsets': [10.0, 2.0, 10.0, -2.0],
              },
            },
          ),
          WeaponsCachePayload(
            sourceKey: rebalance.smolId,
            rows: [
              {
                'id': 'twin',
                'name': 'Twin Cannon',
                'damage/shot': 150,
                'chargedown': 1,
              },
            ],
            wpnFiles: const {},
          ),
        ],
        mods: [_mod(rebalance)],
      );

      final twin = weapons.single;
      expect(twin.barrelMode, 'LINKED');
      expect(twin.damagePerShot, 150, reason: 'the rebalanced row wins');
      expect(
        twin.effectiveDps,
        closeTo(300, 0.001),
        reason: 'both barrels count: 150x2 damage per 1s cycle',
      );
    });

    test('the mount type and the damage type stay apart', () async {
      // Both files call their field "type", but they mean different things:
      // in the .wpn it is the mount, in weapon_data.csv it is the damage.
      // The game keeps them apart, so TriOS has to as well.
      final weapons = await _build(
        payloads: [
          WeaponsCachePayload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {'id': 'lightmg', 'name': 'Light MG', 'type': 'KINETIC'},
            ],
            wpnFiles: {
              'weapons/lightmg.wpn': {
                'id': 'lightmg',
                'mountType': 'BALLISTIC',
                'size': 'SMALL',
              },
            },
          ),
        ],
        mods: const [],
      );

      final mg = weapons.single;
      expect(mg.weaponType, 'BALLISTIC');
      expect(mg.effectiveMountType, 'BALLISTIC');
      expect(mg.type, 'KINETIC');
      expect(mg.damageType, 'KINETIC');
    });

    test('mountTypeOverride wins over the .wpn mount type', () async {
      final weapons = await _build(
        payloads: [
          WeaponsCachePayload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {'id': 'hybrid', 'name': 'Hybrid', 'type': 'ENERGY'},
            ],
            wpnFiles: {
              'weapons/hybrid.wpn': {
                'id': 'hybrid',
                'mountType': 'BALLISTIC',
                'mountTypeOverride': 'HYBRID',
              },
            },
          ),
        ],
        mods: const [],
      );

      expect(weapons.single.effectiveMountType, 'HYBRID');
      expect(weapons.single.weaponType, 'BALLISTIC');
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

    test(
      'the Autopulse case: a mod wins the .wpn but only vanilla has the image',
      () async {
        // Emergent Threats copies autopulse.wpn just to change a sound. The
        // copy still names the vanilla images, and the mod ships no art.
        final threats = _variant('Emergent Threats');

        final weapons = await _build(
          payloads: [
            WeaponsCachePayload(
              sourceKey: kVanillaSourceKey,
              rows: [
                {'id': 'autopulse', 'name': 'Autopulse Laser'},
              ],
              wpnFiles: {
                'autopulse.wpn': {
                  'id': 'autopulse',
                  'turretSprite': 'graphics/weapons/autopulse_turret_base.png',
                  'specClass': 'projectile',
                },
              },
            ),
            WeaponsCachePayload(
              sourceKey: threats.smolId,
              rows: const [],
              wpnFiles: {
                'autopulse.wpn': {
                  'id': 'autopulse',
                  'turretSprite': 'graphics/weapons/autopulse_turret_base.png',
                },
              },
            ),
          ],
          mods: [_mod(threats)],
          imageSources: [
            _source('mods/Emergent Threats', const []),
            _source('core', const [
              'graphics/weapons/autopulse_turret_base.png',
            ]),
          ],
        );

        expect(
          weapons.single.turretSprite,
          _imageIn('core', 'graphics/weapons/autopulse_turret_base.png'),
          reason: 'the mod named the image, but only vanilla has it',
        );
      },
    );

    test('a launcher finds a missile another mod defines', () async {
      final launchers = _variant('A-launchers');
      final missiles = _variant('B-missiles');

      final weapons = await _build(
        payloads: [
          WeaponsCachePayload(
            sourceKey: launchers.smolId,
            rows: [
              {'id': 'pod', 'name': 'Missile Pod'},
            ],
            wpnFiles: {
              'pod.wpn': {
                'id': 'pod',
                'projectileSpecId': 'shared_missile',
                'renderHints': ['RENDER_LOADED_MISSILES'],
              },
            },
          ),
          WeaponsCachePayload(
            sourceKey: missiles.smolId,
            rows: const [],
            wpnFiles: const {},
            missileSpecs: const {
              'shared_missile': {
                'sprite': 'graphics/missiles/shared.png',
                'size': [8.0, 16.0],
                'center': [4.0, 8.0],
              },
            },
          ),
        ],
        mods: [_mod(launchers), _mod(missiles)],
        imageSources: [
          _source('mods/A-launchers', const []),
          _source('mods/B-missiles', const ['graphics/missiles/shared.png']),
          _source('core', const []),
        ],
      );

      expect(
        weapons.single.loadedMissileSprite,
        _imageIn('mods/B-missiles', 'graphics/missiles/shared.png'),
      );
    });

    test('every mod that changes a weapon offers its own files', () async {
      final threats = _variant('Emergent Threats');

      final weapons = await _build(
        payloads: [
          WeaponsCachePayload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {'id': 'autopulse', 'name': 'Autopulse Laser', 'damage/shot': 100},
            ],
            wpnFiles: {
              'weapons/autopulse.wpn': {
                'id': 'autopulse',
                'wpnFile': 'core/data/weapons/autopulse.wpn',
                'turretSprite': 'graphics/weapons/autopulse.png',
              },
            },
            csvFilePath: 'core/data/weapons/weapon_data.csv',
          ),
          WeaponsCachePayload(
            sourceKey: threats.smolId,
            rows: [
              {'id': 'autopulse', 'name': 'Autopulse Laser', 'damage/shot': 120},
            ],
            wpnFiles: {
              'weapons/autopulse.wpn': {
                'id': 'autopulse',
                'wpnFile': 'mods/Emergent Threats/data/weapons/autopulse.wpn',
                'turretGlowSprite': 'graphics/weapons/autopulse_glow.png',
              },
            },
            csvFilePath: 'mods/Emergent Threats/data/weapons/weapon_data.csv',
          ),
        ],
        mods: [_mod(threats)],
        imageSources: [
          _source('mods/Emergent Threats', const []),
          _source('core', const ['graphics/weapons/autopulse.png']),
        ],
      );

      final autopulse = weapons.single;
      expect(
        autopulse.wpnFiles.map((f) => f.modName).toList(),
        ['Emergent Threats', 'Vanilla'],
        reason: 'the mod applies last, so its .wpn wins the shared values',
      );
      expect(autopulse.wpnFiles.first.isEffective, isTrue);
      expect(
        autopulse.wpnFiles.last.file.path,
        'core/data/weapons/autopulse.wpn',
        reason: "vanilla's own file is still offered, not the mod's",
      );
      expect(
        autopulse.csvFiles.map((f) => f.modName).toList(),
        ['Emergent Threats', 'Vanilla'],
        reason: 'the mod row wins, but vanilla still has a row to look at',
      );
      expect(
        autopulse.csvFiles.first.file.path,
        'mods/Emergent Threats/data/weapons/weapon_data.csv',
      );
    });

    test('a weapon only one mod touches lists just that one file', () async {
      final weapons = await _build(
        payloads: [
          WeaponsCachePayload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {'id': 'lightmg', 'name': 'Light MG'},
            ],
            wpnFiles: {
              'weapons/lightmg.wpn': {
                'id': 'lightmg',
                'wpnFile': 'core/data/weapons/lightmg.wpn',
              },
            },
            csvFilePath: 'core/data/weapons/weapon_data.csv',
          ),
        ],
        mods: const [],
        imageSources: [_source('core', const [])],
      );

      expect(weapons.single.wpnFiles.length, 1);
      expect(weapons.single.csvFiles.length, 1);
      expect(weapons.single.wpnFiles.single.isVanilla, isTrue);
    });
  });
}
