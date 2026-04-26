import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/vram_check_scan_params.dart';
import 'package:trios/vram_estimator/vram_scan_one_mod.dart';

VramCheckScanParams _params(VramCheckerMod mod) => VramCheckScanParams(
  modInfo: mod,
  enabledModIds: const [],
  selectorId: 'folder-scan',
  selectorConfig: null,
  graphicsLibConfig: GraphicsLibConfig.disabled,
  showGfxLibDebugOutput: false,
  showPerformance: false,
  showSkippedFiles: false,
  showCountedFiles: false,
  maxFileHandles: 32,
);

void main() {
  group('scanOneMod', () {
    test('non-existent mod path yields a failed outcome, not a throw', () async {
      final mod = VramCheckerMod(
        ModInfo(id: 'ghost', name: 'Ghost'),
        '${Directory.systemTemp.path}/this_path_definitely_does_not_exist_${DateTime.now().microsecondsSinceEpoch}',
      );
      final outcome = await scanOneMod(_params(mod));
      expect(outcome.isFailure, isTrue);
      expect(outcome.errorMessage, isNotEmpty);
    });

    test('empty mod folder yields a success outcome with no images', () async {
      final dir = Directory.systemTemp.createTempSync('scan_one_mod_test_');
      try {
        final mod = VramCheckerMod(
          ModInfo(id: 'empty', name: 'Empty'),
          dir.path,
        );
        final outcome = await scanOneMod(_params(mod));
        expect(outcome.isSuccess, isTrue);
        expect(outcome.mod!.images.length, equals(0));
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('cancelled outcome surfaces when local cancel predicate flips', () async {
      final dir = Directory.systemTemp.createTempSync('scan_one_mod_cancel_');
      try {
        final mod = VramCheckerMod(
          ModInfo(id: 'cancel', name: 'Cancel'),
          dir.path,
        );
        final outcome = await scanOneMod(
          _params(mod),
          isCancelledLocal: () => true,
        );
        expect(outcome.cancelled, isTrue);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
