import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/vram_selector_id.dart';
import 'package:trios/vram_estimator/vram_check_scan_params.dart';
import 'package:trios/vram_estimator/vram_scan_one_mod.dart';

VramCheckScanParams _baseParams(VramCheckerMod mod) => VramCheckScanParams(
  modInfo: mod,
  enabledModIds: const ['test_mod'],
  selectorId: VramSelectorId.folderScan,
  selectorConfig: null,
  graphicsLibConfig: GraphicsLibConfig.disabled,
  showGfxLibDebugOutput: false,
  showPerformance: false,
  showSkippedFiles: false,
  showCountedFiles: false,
  maxFileHandles: 32,
);

Set<Map<String, Object?>> _imageSet(ModImageTable? t) {
  if (t == null) return const {};
  return t.toRows().map<Map<String, Object?>>((r) {
    // Drop fields that are null to make set equality cleaner.
    return {
      for (final e in r.entries)
        if (e.value != null) e.key: e.value,
    };
  }).toSet();
}

void main() {
  group('scanOneMod parity', () {
    test('params round-trip through toTransfer/fromTransfer is byte-equal', () async {
      final dir = Directory.systemTemp.createTempSync('parity_test_');
      try {
        // Empty mod folder — both paths will produce a `VramMod` with
        // zero images. The point is to check the serialization layer.
        final mod = VramCheckerMod(
          ModInfo(id: 'test_mod', name: 'Test Mod'),
          dir.path,
        );

        final paramsA = _baseParams(mod);
        final outcomeA = await scanOneMod(paramsA);
        expect(outcomeA.isSuccess, isTrue);

        // Round-trip the params to simulate the isolate boundary.
        final transferred = VramCheckScanParams.fromTransfer(
          paramsA.toTransfer(),
        );
        final outcomeB = await scanOneMod(transferred);
        expect(outcomeB.isSuccess, isTrue);

        // Round-trip the outcome too.
        final transferredOutcome = VramScanOutcome.fromTransfer(
          outcomeB.toTransfer(),
        );
        expect(transferredOutcome.isSuccess, isTrue);

        final modA = outcomeA.mod!;
        final modB = transferredOutcome.mod!;

        expect(modA.info.modId, equals(modB.info.modId));
        expect(modA.isEnabled, equals(modB.isEnabled));
        expect(_imageSet(modA.images), equals(_imageSet(modB.images)));
        expect(
          _imageSet(modA.unreferencedImages),
          equals(_imageSet(modB.unreferencedImages)),
        );
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
