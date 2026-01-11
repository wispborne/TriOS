import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('trios_test');
    Constants.configDataFolderPath = tempDir;
    container = ProviderContainer();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
    container.dispose();
  });

  Portrait createMockPortrait(String name, String hash) {
    return Portrait(
      imageFile: File(p.join(tempDir.path, name)),
      relativePath: name,
      width: 100,
      height: 100,
      hash: hash,
    );
  }

  test(
    'removeReplacement fails if called multiple times in rapid succession',
    () async {
      final notifier = container.read(
        AppState.portraitReplacementsManager.notifier,
      );

      final p1 = createMockPortrait('p1.png', 'hash1');
      final p2 = createMockPortrait('p2.png', 'hash2');
      final p3 = createMockPortrait('p3.png', 'hash3');
      final r1 = createMockPortrait('r1.png', 'rhash1');

      // First, add some replacements
      await notifier.saveReplacement(p1, r1);
      await notifier.saveReplacement(p2, r1);
      await notifier.saveReplacement(p3, r1);

      // Verify they are there
      var state = await container.read(
        AppState.portraitReplacementsManager.future,
      );
      expect(state.containsKey('hash1'), isTrue);
      expect(state.containsKey('hash2'), isTrue);
      expect(state.containsKey('hash3'), isTrue);

      // Call removeReplacement multiple times in rapid succession
      // We don't await them individually to trigger the race condition
      final f1 = notifier.removeReplacement(p1);
      final f2 = notifier.removeReplacement(p2);
      final f3 = notifier.removeReplacement(p3);

      await Future.wait([f1, f2, f3]);

      // Check final state
      state = await container.read(AppState.portraitReplacementsManager.future);

      // If the race condition exists, some of these might still be present because they read stale state
      print('Final state keys: ${state.keys.toList()}');

      // We expect all to be removed
      expect(
        state.containsKey('hash1'),
        isFalse,
        reason: 'hash1 should be removed',
      );
      expect(
        state.containsKey('hash2'),
        isFalse,
        reason: 'hash2 should be removed',
      );
      expect(
        state.containsKey('hash3'),
        isFalse,
        reason: 'hash3 should be removed',
      );
    },
  );
}
