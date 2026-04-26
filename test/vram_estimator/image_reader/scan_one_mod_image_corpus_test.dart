import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:trios/models/mod_info.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/vram_selector_id.dart';
import 'package:trios/vram_estimator/vram_check_scan_params.dart';
import 'package:trios/vram_estimator/vram_scan_one_mod.dart';

VramCheckScanParams _params(VramCheckerMod mod) => VramCheckScanParams(
  modInfo: mod,
  enabledModIds: const [],
  selectorId: VramSelectorId.folderScan,
  selectorConfig: null,
  graphicsLibConfig: GraphicsLibConfig.disabled,
  showGfxLibDebugOutput: false,
  showPerformance: false,
  showSkippedFiles: false,
  showCountedFiles: false,
  maxFileHandles: 32,
);

Uint8List _wrapWebpVp8x({
  required int width,
  required int height,
  required bool alpha,
}) {
  final flags = alpha ? 0x10 : 0x00;
  final w = width - 1;
  final h = height - 1;
  final body = <int>[
    flags, 0, 0, 0,
    w & 0xFF, (w >> 8) & 0xFF, (w >> 16) & 0xFF,
    h & 0xFF, (h >> 8) & 0xFF, (h >> 16) & 0xFF,
  ];
  while (12 + 4 + 4 + body.length < 30) {
    body.add(0);
  }
  final size = body.length;
  final out = BytesBuilder();
  out.add('RIFF'.codeUnits);
  out.add([0, 0, 0, 0]);
  out.add('WEBP'.codeUnits);
  out.add('VP8X'.codeUnits);
  out.add([
    size & 0xFF,
    (size >> 8) & 0xFF,
    (size >> 16) & 0xFF,
    (size >> 24) & 0xFF,
  ]);
  out.add(body);
  return out.toBytes();
}

void main() {
  test('scanOneMod processes a mixed PNG/JPG/GIF/WEBP corpus end-to-end',
      () async {
    final root = Directory.systemTemp.createTempSync('scan_corpus_test_');
    try {
      // Mixed corpus under graphics/ so the folder scan picks them up.
      final gfx = Directory('${root.path}/graphics')..createSync();

      // PNG sprite (RGBA): 64x64.
      File('${gfx.path}/sprite.png').writeAsBytesSync(
        img.encodePng(img.Image(width: 64, height: 64, numChannels: 4)),
      );

      // JPG background: 320x240, RGB.
      File('${gfx.path}/bg.jpg').writeAsBytesSync(
        img.encodeJpg(img.Image(width: 320, height: 240, numChannels: 3)),
      );

      // GIF: 32x32, palette-backed.
      final gifSrc = img.Image(width: 32, height: 32, numChannels: 4);
      File('${gfx.path}/icon.gif').writeAsBytesSync(
        img.encodeGif(img.quantize(gifSrc, numberOfColors: 16)),
      );

      // WEBP VP8X with alpha: 100x80.
      File('${gfx.path}/banner.webp').writeAsBytesSync(
        _wrapWebpVp8x(width: 100, height: 80, alpha: true),
      );

      final mod = VramCheckerMod(
        ModInfo(id: 'corpus', name: 'Corpus'),
        root.path,
      );
      final outcome = await scanOneMod(_params(mod));
      expect(outcome.isSuccess, isTrue,
          reason: outcome.errorMessage ?? 'no error message');
      expect(outcome.mod, isNotNull);

      final scanned = outcome.mod!;
      // 4 input files; the folder scan should pick all of them up.
      expect(scanned.images.length, 4);

      // Texture dimensions are rounded up to the next power of two before
      // the byte calculation; multiplier = 4/3 for non-background images.
      // None of these go in graphics/backgrounds/, so they are all textures.
      int nextPow2(int n) {
        if (n <= 1) return 1;
        var v = 1;
        while (v < n) {
          v <<= 1;
        }
        return v;
      }

      int bytesFor(int w, int h, int channels) {
        final tw = nextPow2(w);
        final th = nextPow2(h);
        final raw = th * tw * channels * (4.0 / 3.0);
        return raw.ceil();
      }

      // PNG 64x64 RGBA   → 64x64,   32 bits/pixel
      // JPG 320x240 RGB  → 512x256, 24 bits/pixel
      // GIF 32x32        → 32x32,   32 bits/pixel (hardcoded RGBA)
      // WEBP VP8X 100x80 → 128x128, 32 bits/pixel
      final expected = bytesFor(64, 64, 4) +
          bytesFor(320, 240, 3) +
          bytesFor(32, 32, 4) +
          bytesFor(100, 80, 4);
      expect(scanned.bytesNotIncludingGraphicsLib(), expected);
    } finally {
      root.deleteSync(recursive: true);
    }
  });
}
