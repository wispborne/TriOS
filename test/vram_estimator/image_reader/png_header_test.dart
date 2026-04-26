import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:trios/vram_estimator/image_reader/png_chatgpt.dart';

import 'fixture_utils.dart';

Future<File> _writePng(Directory dir, String name, img.Image image) async {
  final bytes = img.encodePng(image);
  final f = File('${dir.path}/$name');
  await f.writeAsBytes(bytes);
  return f;
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('png_header_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('readPngFileHeaders parity', () {
    test('24-bit truecolor (color type 2)', () async {
      final src = img.Image(width: 17, height: 9, numChannels: 3);
      final f = await _writePng(tmp, 'rgb.png', src);
      await expectParityWithImagePackage(f, readPngFileHeaders);
    });

    test('32-bit truecolor + alpha (color type 6)', () async {
      final src = img.Image(width: 33, height: 21, numChannels: 4);
      final f = await _writePng(tmp, 'rgba.png', src);
      await expectParityWithImagePackage(f, readPngFileHeaders);
    });

    test('grayscale (color type 0)', () async {
      final src = img.Image(width: 19, height: 7, numChannels: 1);
      final f = await _writePng(tmp, 'gray.png', src);
      await expectParityWithImagePackage(f, readPngFileHeaders);
    });

    test('grayscale + alpha (color type 4)', () async {
      // Two-channel gray+alpha PNGs are produced by package:image when
      // numChannels=2.
      final src = img.Image(width: 11, height: 13, numChannels: 2);
      final f = await _writePng(tmp, 'graya.png', src);
      await expectParityWithImagePackage(f, readPngFileHeaders);
    });

    test('palette (color type 3)', () async {
      // Documented deviation from strict tuple parity (task 7.3). The PNG
      // header reader maps IHDR color type 3 → numChannels=1, matching the
      // pre-change behavior of `readPngFileHeaders` itself (PNG was always
      // routed through the IHDR-driven reader, not through `package:image`'s
      // generic decode path). Current package:image versions expand the
      // palette during decode and report numChannels=3, which is what an
      // RGB-uploaded surface would look like — but that does NOT match the
      // pre-change VRAM total this change must preserve, because PNGs were
      // never sent through `package:image` before. Reference: PNG spec
      // section 11.2.2 (IHDR) — color type 3 stores indices, not RGB
      // samples; channel count is a decode-time interpretation.
      final palette = img.PaletteUint8(4, 3);
      palette.setRgb(0, 0, 0, 0);
      palette.setRgb(1, 255, 0, 0);
      palette.setRgb(2, 0, 255, 0);
      palette.setRgb(3, 0, 0, 255);
      final src = img.Image(
        width: 8,
        height: 8,
        numChannels: 1,
        palette: palette,
      );
      final f = await _writePng(tmp, 'palette.png', src);
      final h = await readPngFileHeaders(f.path);
      expect(h, isNotNull);
      expect(h!.width, 8);
      expect(h.height, 8);
      expect(h.bitDepth, 8);
      expect(h.numChannels, 1, reason: 'preserves pre-change PNG behavior');
    });
  });

  group('readPngFileHeaders failure paths', () {
    test('truncated file throws', () async {
      final src = img.Image(width: 10, height: 10, numChannels: 4);
      final bytes = img.encodePng(src);
      // Truncate to 16 bytes — far less than the 29 byte minimum.
      final f = File('${tmp.path}/truncated.png');
      await f.writeAsBytes(bytes.sublist(0, 16));
      await expectThrows(() => readPngFileHeaders(f.path));
    });

    test('corrupted signature throws', () async {
      final src = img.Image(width: 10, height: 10, numChannels: 4);
      final bytes = Uint8List.fromList(img.encodePng(src));
      bytes[0] = 0x00;
      bytes[1] = 0x00;
      final f = File('${tmp.path}/bad_sig.png');
      await f.writeAsBytes(bytes);
      await expectThrows(() => readPngFileHeaders(f.path));
    });
  });
}
