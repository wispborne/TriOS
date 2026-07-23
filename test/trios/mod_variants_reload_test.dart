import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';

/// Covers partial reloads (`reloadModVariantsFromFolders` with `onlyFolders`),
/// especially that a variant whose folder was deleted on disk is removed from
/// state instead of lingering as a ghost entry. See Sentry TRIOS-21S.
void main() {
  group('reloadModVariantsFromFolders', () {
    late Directory gameDir;
    late Directory coreDir;
    late Directory modsDir;
    late ProviderContainer container;

    Directory makeModFolder(String folderName, String modId) {
      final folder = modsDir.resolve(folderName).toDirectory()
        ..createSync(recursive: true);
      folder
          .resolve('mod_info.json')
          .toFile()
          .writeAsStringSync('{"id": "$modId", "name": "$modId", "version": "1.0.0"}');
      return folder;
    }

    ProviderContainer makeContainer() => ProviderContainer(
      overrides: [
        AppState.gameFolder.overrideWith((ref) => Future.value(gameDir)),
        AppState.modsFolder.overrideWith((ref) => Future.value(modsDir)),
        AppState.gameCoreFolder.overrideWith((ref) => Future.value(coreDir)),
      ],
    );

    List<String> currentModIds() =>
        (container.read(AppState.modVariants).value ?? [])
            .map((v) => v.modInfo.id)
            .toList()
          ..sort();

    setUp(() {
      gameDir = Directory.systemTemp.createTempSync('mod_reload_test');
      coreDir = gameDir.resolve('starsector-core').toDirectory()..createSync();
      modsDir = gameDir.resolve('mods').toDirectory()..createSync();
    });

    tearDown(() async {
      // Let the mods-folder watcher's debounce (250 ms) fire while the
      // container is still alive, so it doesn't run against a disposed one.
      await Future.delayed(const Duration(milliseconds: 400));
      container.dispose();
      if (gameDir.existsSync()) {
        gameDir.deleteSync(recursive: true);
      }
    });

    test('removes the variant of a deleted folder', () async {
      final folderA = makeModFolder('ModA', 'mod_a');
      final folderB = makeModFolder('ModB', 'mod_b');

      container = makeContainer();
      final notifier = container.read(AppState.modVariants.notifier);

      // Wait for the first full scan. Don't await `.future` — it can hang if
      // the first build is superseded; poll instead.
      await _waitFor(
        () => currentModIds().length == 2,
        'initial scan to find both mods',
      );

      folderB.deleteSync(recursive: true);
      await notifier.reloadModVariantsFromFolders(
        onlyFolders: [folderA, folderB],
      );

      expect(
        currentModIds(),
        ['mod_a'],
        reason: 'The deleted folder should drop out; the other should stay.',
      );
    });

    test(
      'reloading only the deleted folder removes it and leaves others alone',
      () async {
        makeModFolder('ModA', 'mod_a');
        final folderB = makeModFolder('ModB', 'mod_b');

        container = makeContainer();
        final notifier = container.read(AppState.modVariants.notifier);

        await _waitFor(
          () => currentModIds().length == 2,
          'initial scan to find both mods',
        );

        folderB.deleteSync(recursive: true);
        await notifier.reloadModVariantsFromFolders(onlyFolders: [folderB]);

        expect(
          currentModIds(),
          ['mod_a'],
          reason: 'Only the deleted folder should be removed from state.',
        );
      },
    );
  });
}

Future<void> _waitFor(bool Function() condition, String description) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for $description');
    }
    await Future.delayed(const Duration(milliseconds: 25));
  }
}
