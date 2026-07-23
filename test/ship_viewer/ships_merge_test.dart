import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/models/ships_cache_payload.dart';
import 'package:trios/ship_viewer/ship_manager.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/utils/game_file_resolver.dart';
import 'package:trios/viewer_cache/graphics_index_manager.dart';

/// Stands in for the real scanner so tests can hand it fixed raw data.
class _FakeShipListNotifier extends ShipListNotifier {
  _FakeShipListNotifier(this.payloads);

  final List<ShipsCachePayload> payloads;

  @override
  Stream<List<ShipsCachePayload>> build() => Stream.value(payloads);
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

ShipsCachePayload _payload({
  required String sourceKey,
  List<Map<String, dynamic>> rows = const [],
  Map<String, Map<String, dynamic>> shipFiles = const {},
  Map<String, Map<String, dynamic>> skinFiles = const {},
}) => ShipsCachePayload(
  sourceKey: sourceKey,
  rows: rows,
  shipFiles: shipFiles,
  skinFiles: skinFiles,
  moduleVariants: const {},
  hullIdMap: const {},
);

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

Future<List<Ship>> _build({
  required List<ShipsCachePayload> payloads,
  required List<Mod> mods,
  List<GameFileSource> imageSources = const [],
  bool onlyEnabledMods = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      shipSourcesProvider.overrideWith(() => _FakeShipListNotifier(payloads)),
      AppState.mods.overrideWithValue(mods),
      gameFileResolverProvider.overrideWith(
        (ref, _) => GameFileResolver(imageSources),
      ),
    ],
  );
  addTearDown(container.dispose);

  await container.read(shipSourcesProvider.future);
  return container.read(shipListNotifierProvider(onlyEnabledMods)).valueOrNull ??
      const [];
}

Ship? _byId(List<Ship> ships, String id) =>
    ships.where((s) => s.id == id).firstOrNull;

void main() {
  group('shipListNotifierProvider', () {
    test('two mods listing the same built-in hullmod only show it once', () async {
      final resprite = _variant('Resprite');
      final ships = await _build(
        payloads: [
          _payload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {'id': 'paragon', 'name': 'Paragon', 'hitpoints': 18000},
            ],
            shipFiles: {
              'paragon.ship': {
                'hullId': 'paragon',
                'spriteName': 'graphics/ships/paragon.png',
                'builtInMods': ['advancedshieldstabilizer'],
                'builtInWings': ['talon_wing', 'talon_wing'],
              },
            },
          ),
          _payload(
            sourceKey: resprite.smolId,
            shipFiles: {
              'paragon.ship': {
                'hullId': 'paragon',
                'spriteName': 'graphics/ships/paragon_resprite.png',
                'builtInMods': ['advancedshieldstabilizer', 'targetingunit'],
              },
            },
          ),
        ],
        mods: [_mod(resprite)],
      );

      final paragon = _byId(ships, 'paragon')!;
      expect(paragon.builtInMods, [
        'advancedshieldstabilizer',
        'targetingunit',
      ]);
      expect(
        paragon.builtInWings,
        ['talon_wing', 'talon_wing'],
        reason: 'a repeated wing is a second bay, so it is left alone',
      );
    });

    test('a disabled mod does not override a vanilla ship when the toggle is '
        'on', () async {
      final rebalance = _variant('Rebalance');
      final payloads = [
        _payload(
          sourceKey: kVanillaSourceKey,
          rows: [
            {'id': 'onslaught', 'name': 'Onslaught', 'hitpoints': 20000},
          ],
          shipFiles: {
            'onslaught.ship': {
              'hullId': 'onslaught',
              'spriteName': 'graphics/ships/onslaught.png',
            },
          },
        ),
        _payload(
          sourceKey: rebalance.smolId,
          rows: [
            {'id': 'onslaught', 'name': 'Onslaught', 'hitpoints': 99000},
          ],
          shipFiles: {
            'onslaught.ship': {
              'hullId': 'onslaught',
              'spriteName': 'graphics/ships/onslaught_redrawn.png',
            },
          },
        ),
      ];
      final mods = [_mod(rebalance, enabled: false)];

      final withToggleOff = await _build(payloads: payloads, mods: mods);
      final withToggleOn = await _build(
        payloads: payloads,
        mods: mods,
        onlyEnabledMods: true,
      );

      expect(
        _byId(withToggleOff, 'onslaught')!.hitpoints,
        99000,
        reason: 'the toggle is off, so every installed mod still counts',
      );
      final onslaught = _byId(withToggleOn, 'onslaught')!;
      expect(onslaught.hitpoints, 20000);
      expect(onslaught.spriteName, 'graphics/ships/onslaught.png');
      expect(onslaught.modVariant, isNull, reason: 'vanilla supplies the row');
    });

    test('a ship only a disabled mod adds disappears when the toggle is on', () async {
      final adder = _variant('Adder');
      final ships = await _build(
        payloads: [
          _payload(
            sourceKey: adder.smolId,
            rows: [
              {'id': 'newship', 'name': 'New Ship', 'hitpoints': 500},
            ],
            shipFiles: {
              'newship.ship': {
                'hullId': 'newship',
                'spriteName': 'graphics/ships/newship.png',
              },
            },
          ),
        ],
        mods: [_mod(adder, enabled: false)],
        onlyEnabledMods: true,
      );

      expect(_byId(ships, 'newship'), isNull);
    });

    test('a mod\'s rebalanced row beats vanilla\'s', () async {
      final rebalance = _variant('Rebalance');

      final ships = await _build(
        payloads: [
          _payload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {'id': 'onslaught', 'name': 'Onslaught', 'hitpoints': 20000},
            ],
            shipFiles: {
              'onslaught.ship': {
                'hullId': 'onslaught',
                'spriteName': 'graphics/ships/onslaught.png',
              },
            },
          ),
          _payload(
            sourceKey: rebalance.smolId,
            rows: [
              {'id': 'onslaught', 'name': 'Onslaught', 'hitpoints': 99000},
            ],
          ),
        ],
        mods: [_mod(rebalance)],
        imageSources: [
          _source('mods/Rebalance', const []),
          _source('core', const ['graphics/ships/onslaught.png']),
        ],
      );

      final onslaught = _byId(ships, 'onslaught')!;
      expect(onslaught.hitpoints, 99000);
      expect(
        onslaught.spriteFile,
        _imageIn('core', 'graphics/ships/onslaught.png'),
        reason: 'the hull shape is still paired in from vanilla',
      );
      expect(onslaught.modVariant?.modInfo.name, 'Rebalance');
    });

    test('a row with no .ship file is kept, not dropped', () async {
      final ships = await _build(
        payloads: [
          _payload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {'id': 'bar', 'name': 'Bar', 'hitpoints': 1000},
            ],
          ),
        ],
        mods: const [],
      );

      final bar = _byId(ships, 'bar');
      expect(bar, isNotNull, reason: 'the game drops this row; a viewer shows it');
      expect(bar!.hitpoints, 1000);
      expect(bar.spriteFile, isNull);
    });

    test('a skin resolves against a base hull from another mod', () async {
      final skinner = _variant('Z-skinner');

      final ships = await _build(
        payloads: [
          _payload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {'id': 'lasher', 'name': 'Lasher', 'hitpoints': 3000},
            ],
            shipFiles: {
              'lasher.ship': {
                'hullId': 'lasher',
                'spriteName': 'graphics/ships/lasher.png',
              },
            },
          ),
          _payload(
            sourceKey: skinner.smolId,
            skinFiles: {
              'lasher_pirate.skin': {
                'baseHullId': 'lasher',
                'skinHullId': 'lasher_pirate',
                'hullName': 'Lasher (Pirate)',
                'spriteName': 'graphics/ships/lasher_pirate.png',
              },
            },
          ),
        ],
        mods: [_mod(skinner)],
        imageSources: [
          _source('mods/Z-skinner', const [
            'graphics/ships/lasher_pirate.png',
          ]),
          _source('core', const ['graphics/ships/lasher.png']),
        ],
      );

      final skin = _byId(ships, 'lasher_pirate');
      expect(skin, isNotNull);
      expect(skin!.name, 'Lasher (Pirate)');
      expect(skin.isSkin, isTrue);
      expect(skin.hitpoints, 3000, reason: 'inherited from the base hull');
      expect(
        skin.spriteFile,
        _imageIn('mods/Z-skinner', 'graphics/ships/lasher_pirate.png'),
      );
      expect(skin.modVariant?.modInfo.name, 'Z-skinner');
    });

    test('a skin of a skin resolves whatever order the files arrive in', () async {
      final skinner = _variant('Skinner');

      final ships = await _build(
        payloads: [
          _payload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {'id': 'lasher', 'name': 'Lasher', 'hitpoints': 3000},
            ],
            shipFiles: {
              'lasher.ship': {'hullId': 'lasher'},
            },
          ),
          _payload(
            sourceKey: skinner.smolId,
            skinFiles: {
              // Listed before the skin it depends on.
              'z_second.skin': {
                'baseHullId': 'lasher_pirate',
                'skinHullId': 'lasher_pirate_elite',
                'hullName': 'Elite Pirate Lasher',
              },
              'a_first.skin': {
                'baseHullId': 'lasher',
                'skinHullId': 'lasher_pirate',
                'hullName': 'Pirate Lasher',
              },
            },
          ),
        ],
        mods: [_mod(skinner)],
      );

      expect(_byId(ships, 'lasher_pirate'), isNotNull);
      expect(_byId(ships, 'lasher_pirate_elite')?.name, 'Elite Pirate Lasher');
    });

    test('a mod that ships only art wins the image for a vanilla ship', () async {
      // No rows, no .ship files — just a replacement picture. It has no ships
      // payload at all, only an entry in the image index.
      final artPack = _variant('Art Pack');

      final ships = await _build(
        payloads: [
          _payload(
            sourceKey: kVanillaSourceKey,
            rows: [
              {'id': 'lasher', 'name': 'Lasher', 'hitpoints': 3000},
            ],
            shipFiles: {
              'lasher.ship': {
                'hullId': 'lasher',
                'spriteName': 'graphics/ships/lasher.png',
              },
            },
          ),
        ],
        mods: [_mod(artPack)],
        imageSources: [
          _source('mods/Art Pack', const ['graphics/ships/lasher.png']),
          _source('core', const ['graphics/ships/lasher.png']),
        ],
      );

      expect(
        _byId(ships, 'lasher')?.spriteFile,
        _imageIn('mods/Art Pack', 'graphics/ships/lasher.png'),
        reason: 'the art pack has the file, so its copy is the one shown',
      );
    });
  });
}
