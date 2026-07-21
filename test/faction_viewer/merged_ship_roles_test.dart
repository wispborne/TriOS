import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/faction_viewer/spawn_weights/ship_roles_manager.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/app_state.dart';

void main() {
  group('mergedShipRolesProvider', () {
    late Directory tempDir;
    late Directory gameCore;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ship_roles_test_');
      gameCore = Directory(p.join(tempDir.path, 'core'))..createSync();
      _writeRoles(gameCore, '{"combatSmall":{"lasher_Standard":10}}');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    /// Creates a mod folder with its own `default_ship_roles.json`.
    ModVariant addMod(String id, String rolesJson) {
      final folder = Directory(p.join(tempDir.path, id))..createSync();
      _writeRoles(folder, rolesJson);
      return ModVariant(
        modInfo: ModInfo(id: id, name: id, version: Version.parse('1.0.0')),
        versionCheckerInfo: null,
        modFolder: folder,
        hasNonBrickedModInfo: true,
        gameCoreFolder: gameCore,
      );
    }

    /// Reads the merged roles once the game folder has resolved and the file
    /// reads have finished. Awaiting `.future` doesn't work here: the first
    /// build is superseded when the game folder arrives, and that future never
    /// completes.
    Future<MergedShipRoles> read(
      List<Mod> mods, {
      required bool onlyEnabledMods,
    }) async {
      final container = ProviderContainer(
        overrides: [
          AppState.gameCoreFolder.overrideWith((ref) async => gameCore),
          AppState.mods.overrideWithValue(mods),
        ],
      );
      addTearDown(container.dispose);

      final provider = mergedShipRolesProvider(onlyEnabledMods);
      container.listen(provider, (_, _) {}, fireImmediately: true);
      await container.read(AppState.gameCoreFolder.future);

      for (var attempt = 0; attempt < 200; attempt++) {
        final value = container.read(provider).value;
        // Vanilla always contributes a role, so anything non-empty means the
        // rebuild finished.
        if (value != null && value.roles.isNotEmpty) return value;
        await Future.delayed(const Duration(milliseconds: 10));
      }
      fail('Merged ship roles never loaded.');
    }

    test('a disabled mod adds no weights when the toggle is on', () async {
      final variant = addMod(
        'weight_mod',
        '{"combatSmall":{"modded_ship_Standard":5}}',
      );
      final mods = [
        Mod(
          id: 'weight_mod',
          isEnabledInGame: false,
          modVariants: [variant],
        ),
      ];

      final all = await read(mods, onlyEnabledMods: false);
      expect(all.roles['combatSmall']!.weights, {
        'lasher_Standard': 10.0,
        'modded_ship_Standard': 5.0,
      });

      final enabledOnly = await read(mods, onlyEnabledMods: true);
      expect(enabledOnly.roles['combatSmall']!.weights, {
        'lasher_Standard': 10.0,
      });
    });

    test('an enabled mod still adds its weights', () async {
      final variant = addMod(
        'weight_mod',
        '{"combatSmall":{"modded_ship_Standard":5}}',
      );
      final mods = [
        Mod(id: 'weight_mod', isEnabledInGame: true, modVariants: [variant]),
      ];

      final enabledOnly = await read(mods, onlyEnabledMods: true);
      expect(
        enabledOnly.roles['combatSmall']!.weights['modded_ship_Standard'],
        5.0,
      );
    });

    test('a disabled mod cannot overwrite a vanilla weight', () async {
      final variant = addMod(
        'weight_mod',
        '{"combatSmall":{"lasher_Standard":99}}',
      );
      final mods = [
        Mod(id: 'weight_mod', isEnabledInGame: false, modVariants: [variant]),
      ];

      final all = await read(mods, onlyEnabledMods: false);
      expect(all.roles['combatSmall']!.weights['lasher_Standard'], 99.0);

      final enabledOnly = await read(mods, onlyEnabledMods: true);
      expect(enabledOnly.roles['combatSmall']!.weights['lasher_Standard'], 10.0);
      expect(
        enabledOnly.roles['combatSmall']!.sources['lasher_Standard'],
        kVanillaSourceName,
      );
    });
  });
}

void _writeRoles(Directory folder, String json) {
  final file = File(
    p.join(folder.path, 'data', 'world', 'factions', 'default_ship_roles.json'),
  );
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(json);
}
