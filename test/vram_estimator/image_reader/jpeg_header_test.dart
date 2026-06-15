import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:trios/vram_estimator/image_reader/jpeg_header.dart';

import 'fixture_utils.dart';

Future<File> _writeJpeg(
  Directory dir,
  String name,
  img.Image image, {
  int quality = 85,
}) async {
  final bytes = img.encodeJpg(image, quality: quality);
  final f = File('${dir.path}/$name');
  await f.writeAsBytes(bytes);
  return f;
}

/// Builds a JPEG by hand whose payload is just an SOI + a giant APP1 segment
/// (filled with [appPayloadSize] bytes) followed by a minimal SOF0 + EOI. The
/// SOF lands well past the first KB but stays under 64 KB.
Uint8List _jpegWithGiantApp1({required int appPayloadSize}) {
  // Segment length includes the 2 length bytes themselves, but excludes the
  // marker.
  final segLen = appPayloadSize + 2;
  final out = BytesBuilder();
  // SOI
  out.add([0xFF, 0xD8]);
  // APP1 marker + length
  out.add([0xFF, 0xE1, (segLen >> 8) & 0xFF, segLen & 0xFF]);
  out.add(Uint8List(appPayloadSize));
  // Minimal SOF0: marker + length(8) + precision(8) + height + width +
  // components(1) + 3 component bytes.
  // Length = 2 + 6 + 3 = 11.
  // We omit components/sampling bytes because the header reader only needs
  // the first 6 payload bytes (precision, height, width, components).
  // But to be a structurally valid JPEG some readers want the full segment.
  // Pad to 11 bytes payload.
  out.add([0xFF, 0xC0]); // SOF0 marker
  out.add([0x00, 0x11]); // length = 17 bytes (2 + 8 + 9 components data)
  out.add([0x08]); // precision = 8
  out.add([0x00, 0x10]); // height = 16
  out.add([0x00, 0x20]); // width = 32
  out.add([0x03]); // components = 3
  // 3 component definitions: id(1) + sampling(1) + qtable(1).
  out.add([1, 0x22, 0]);
  out.add([2, 0x11, 1]);
  out.add([3, 0x11, 1]);
  // EOI
  out.add([0xFF, 0xD9]);
  return out.toBytes();
}

/// Builds a JPEG that fills space with non-SOF segments (APP1) until total
/// bytes consumed by markers exceeds 64 KB, with no SOF anywhere.
Uint8List _jpegMarkersExceedingCap() {
  final out = BytesBuilder();
  out.add([0xFF, 0xD8]); // SOI
  // Each APP1 segment: marker(2) + length(2) + payload. Use payload of
  // ~16 KB so we exceed 64 KB after 4-5 segments.
  const payload = 16000;
  final segLen = payload + 2;
  for (int i = 0; i < 6; i++) {
    out.add([0xFF, 0xE1, (segLen >> 8) & 0xFF, segLen & 0xFF]);
    out.add(Uint8List(payload));
  }
  // No SOF, no EOI either — purposefully malformed.
  return out.toBytes();
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('jpeg_header_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('readJpegFileHeaders parity (baseline / SOF0)', () {
    test('small RGB JPEG', () async {
      final src = img.Image(width: 24, height: 16, numChannels: 3);
      final f = await _writeJpeg(tmp, 'rgb.jpg', src);
      await expectParityWithImagePackage(f, readJpegFileHeaders);
    });

    test('larger RGB JPEG', () async {
      final src = img.Image(width: 320, height: 240, numChannels: 3);
      final f = await _writeJpeg(tmp, 'big.jpg', src);
      await expectParityWithImagePackage(f, readJpegFileHeaders);
    });
  });

  group('readJpegFileHeaders failure paths', () {
    test('truncated file throws', () async {
      final src = img.Image(width: 24, height: 16, numChannels: 3);
      final bytes = img.encodeJpg(src);
      final f = File('${tmp.path}/truncated.jpg');
      await f.writeAsBytes(bytes.sublist(0, 1));
      await expectThrows(() => readJpegFileHeaders(f.path));
    });

    test('corrupted SOI throws', () async {
      final src = img.Image(width: 24, height: 16, numChannels: 3);
      final bytes = Uint8List.fromList(img.encodeJpg(src));
      bytes[0] = 0x00;
      bytes[1] = 0x00;
      final f = File('${tmp.path}/bad_sig.jpg');
      await f.writeAsBytes(bytes);
      await expectThrows(() => readJpegFileHeaders(f.path));
    });

    test('markers chain past 64 KB without SOF throws within cap', () async {
      final f = File('${tmp.path}/never_sof.jpg');
      await f.writeAsBytes(_jpegMarkersExceedingCap());
      await expectThrows(() => readJpegFileHeaders(f.path));
    });
  });

  group('readJpegFileHeaders extras', () {
    test('giant APP1 pushing SOF past 1 KB still finds SOF', () async {
      // 8 KB payload — well past 1 KB initial buffer, well under 64 KB cap.
      final f = File('${tmp.path}/giant_app1.jpg');
      await f.writeAsBytes(_jpegWithGiantApp1(appPayloadSize: 8000));
      final h = await readJpegFileHeaders(f.path);
      expect(h, isNotNull);
      expect(h!.width, 32);
      expect(h.height, 16);
      expect(h.bitDepth, 8);
      expect(h.numChannels, 3);
    });
  });
}
