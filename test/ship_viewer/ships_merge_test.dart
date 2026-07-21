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
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/game_data_merge.dart';

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

Mod _mod(ModVariant variant) =>
    Mod(id: variant.modInfo.id, isEnabledInGame: true, modVariants: [variant]);

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

Future<List<Ship>> _build({
  required List<ShipsCachePayload> payloads,
  required List<Mod> mods,
}) async {
  final container = ProviderContainer(
    overrides: [
      shipSourcesProvider.overrideWith(() => _FakeShipListNotifier(payloads)),
      AppState.mods.overrideWithValue(mods),
    ],
  );
  addTearDown(container.dispose);

  await container.read(shipSourcesProvider.future);
  return container.read(shipListNotifierProvider).valueOrNull ?? const [];
}

Ship? _byId(List<Ship> ships, String id) =>
    ships.where((s) => s.id == id).firstOrNull;

void main() {
  group('shipListNotifierProvider', () {
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
                'spriteFile': 'vanilla/onslaught.png',
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
      );

      final onslaught = _byId(ships, 'onslaught')!;
      expect(onslaught.hitpoints, 99000);
      expect(
        onslaught.spriteFile,
        'vanilla/onslaught.png',
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
                'spriteFile': 'vanilla/lasher.png',
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
                '_spriteFile': 'mods/pirate_lasher.png',
              },
            },
          ),
        ],
        mods: [_mod(skinner)],
      );

      final skin = _byId(ships, 'lasher_pirate');
      expect(skin, isNotNull);
      expect(skin!.name, 'Lasher (Pirate)');
      expect(skin.isSkin, isTrue);
      expect(skin.hitpoints, 3000, reason: 'inherited from the base hull');
      expect(skin.spriteFile, 'mods/pirate_lasher.png');
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
  });
}
