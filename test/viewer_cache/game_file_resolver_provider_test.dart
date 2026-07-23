import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/viewer_cache/graphics_index_manager.dart';

/// Stands in for the real folder walk so tests can hand it a fixed index.
class _FakeGraphicsIndexNotifier extends GraphicsIndexNotifier {
  _FakeGraphicsIndexNotifier(this.payloads);

  final List<GraphicsIndexPayload> payloads;

  @override
  Stream<List<GraphicsIndexPayload>> build() => Stream.value(payloads);
}

ModVariant _variant(String name) => ModVariant(
  modInfo: ModInfo(
    id: name.toLowerCase(),
    name: name,
    version: Version.parse('1.0.0'),
  ),
  versionCheckerInfo: null,
  modFolder: Directory('mods/$name'),
  hasNonBrickedModInfo: true,
  gameCoreFolder: Directory('core'),
);

/// The absolute path the resolver builds for an image in [folder].
String _imageIn(String folder, String relativePath) =>
    p.normalize(File(p.join(folder, relativePath)).absolute.path);

void main() {
  group('gameFileResolverProvider', () {
    const spritePath = 'graphics/ships/hound.png';
    final repaint = _variant('Repaint');

    final payloads = [
      GraphicsIndexPayload(
        sourceKey: kVanillaSourceKey,
        folderPath: 'core',
        imageFiles: const [spritePath],
      ),
      GraphicsIndexPayload(
        sourceKey: repaint.smolId,
        folderPath: 'mods/Repaint',
        imageFiles: const [spritePath],
      ),
    ];

    Future<String?> resolve({
      required bool modEnabled,
      required bool onlyEnabledMods,
    }) async {
      final container = ProviderContainer(
        overrides: [
          graphicsIndexProvider.overrideWith(
            () => _FakeGraphicsIndexNotifier(payloads),
          ),
          AppState.mods.overrideWithValue([
            Mod(
              id: repaint.modInfo.id,
              isEnabledInGame: modEnabled,
              modVariants: [repaint],
            ),
          ]),
        ],
      );
      addTearDown(container.dispose);

      await container.read(graphicsIndexProvider.future);
      return container
          .read(gameFileResolverProvider(onlyEnabledMods))
          .resolve(spritePath);
    }

    test('a mod replacing a vanilla sprite wins while it is enabled', () async {
      expect(
        await resolve(modEnabled: true, onlyEnabledMods: true),
        _imageIn('mods/Repaint', spritePath),
      );
    });

    test('a disabled mod cannot replace a vanilla sprite', () async {
      expect(
        await resolve(modEnabled: false, onlyEnabledMods: true),
        _imageIn('core', spritePath),
      );
    });

    test('with the toggle off, a disabled mod still wins', () async {
      expect(
        await resolve(modEnabled: false, onlyEnabledMods: false),
        _imageIn('mods/Repaint', spritePath),
        reason: 'the toggle is off, so every installed mod counts',
      );
    });
  });
}
