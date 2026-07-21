import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/ship_viewer/engine_styles_manager.dart';
import 'package:trios/ship_viewer/models/ship_engine_style_spec.dart';
import 'package:trios/trios/app_state.dart';

void main() {
  group('engineStylesProvider', () {
    late Directory tempDir;
    late Directory gameCore;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('engine_styles_test_');
      gameCore = Directory(p.join(tempDir.path, 'core'))..createSync();
      _writeStyles(gameCore, '''
{
  "HIGH_TECH": {
    "engineColor": [100, 100, 255, 255],
    "glowSizeMult": 1.5
  }
}
''');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    Mod addMod(String id, String stylesJson) {
      final folder = Directory(p.join(tempDir.path, id))..createSync();
      _writeStyles(folder, stylesJson);
      final variant = ModVariant(
        modInfo: ModInfo(id: id, name: id, version: Version.parse('1.0.0')),
        versionCheckerInfo: null,
        modFolder: folder,
        hasNonBrickedModInfo: true,
        gameCoreFolder: gameCore,
      );
      return Mod(id: id, isEnabledInGame: true, modVariants: [variant]);
    }

    Future<Map<String, EngineStyleSpec>> read(List<Mod> mods) async {
      final container = ProviderContainer(
        overrides: [
          AppState.gameCoreFolder.overrideWith((ref) async => gameCore),
          AppState.mods.overrideWithValue(mods),
        ],
      );
      addTearDown(container.dispose);
      await container.read(AppState.gameCoreFolder.future);
      return container.read(engineStylesProvider.future);
    }

    test('a mod setting one field keeps the style\'s other fields', () async {
      final styles = await read([
        addMod('tweaker', '{"HIGH_TECH":{"glowSizeMult":9.0}}'),
      ]);

      final highTech = styles['HIGH_TECH'];
      expect(highTech, isNotNull);
      expect(highTech!.glowSizeMult, 9.0);
      expect(
        highTech.engineColor,
        const Color.fromARGB(255, 100, 100, 255),
        reason: 'vanilla\'s colour survives instead of being wiped',
      );
    });

    test('a 4-entry colour list is replaced, not appended to', () async {
      final styles = await read([
        addMod('recolour', '{"HIGH_TECH":{"engineColor":[255,0,0,255]}}'),
      ]);

      expect(
        styles['HIGH_TECH']!.engineColor,
        const Color.fromARGB(255, 255, 0, 0),
      );
    });
  });
}

void _writeStyles(Directory folder, String json) {
  final file = File(p.join(folder.path, 'data', 'config', 'engine_styles.json'));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(json);
}
