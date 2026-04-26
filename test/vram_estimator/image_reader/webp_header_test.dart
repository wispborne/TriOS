import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/image_reader/webp_header.dart';

import 'fixture_utils.dart';

/// Wraps a chunk body in the RIFF/WEBP container for the given chunk
/// FourCC. Pads the body so the total file is at least 30 bytes — the new
/// reader's fixed initial read size.
Uint8List _wrapWebp(String fourcc, List<int> body) {
  assert(fourcc.length == 4);
  final paddedBody = List<int>.from(body);
  while (12 + 4 + 4 + paddedBody.length < 30) {
    paddedBody.add(0);
  }
  final size = paddedBody.length;
  final out = BytesBuilder();
  out.add('RIFF'.codeUnits);
  out.add([0, 0, 0, 0]); // RIFF size, irrelevant for header reader
  out.add('WEBP'.codeUnits);
  out.add(fourcc.codeUnits);
  out.add([
    size & 0xFF,
    (size >> 8) & 0xFF,
    (size >> 16) & 0xFF,
    (size >> 24) & 0xFF,
  ]);
  out.add(paddedBody);
  return out.toBytes();
}

/// Builds a `VP8 ` chunk body with the supplied 14-bit width and height.
/// Layout (relative to chunk body start, which is offset 20 in the file):
/// - 3-byte frame tag (we leave 0)
/// - 3-byte start code 0x9D 0x01 0x2A
/// - 2-byte LE width (with optional scale in the top 2 bits)
/// - 2-byte LE height (with optional scale in the top 2 bits)
List<int> _vp8Body({required int width, required int height}) {
  final body = <int>[
    0x00, 0x00, 0x00, // frame tag
    0x9D, 0x01, 0x2A, // VP8 start code
    width & 0xFF, (width >> 8) & 0xFF,
    height & 0xFF, (height >> 8) & 0xFF,
  ];
  return body;
}

/// Builds a `VP8L` chunk body with the supplied dimensions and alpha flag.
/// Layout (relative to chunk body start):
/// - 1 byte signature 0x2F
/// - 4 bytes packed: (width-1):14, (height-1):14, alpha:1, version:3 LE
List<int> _vp8lBody({
  required int width,
  required int height,
  required bool alpha,
}) {
  final w = (width - 1) & 0x3FFF;
  final h = (height - 1) & 0x3FFF;
  final packed =
      w | (h << 14) | ((alpha ? 1 : 0) << 28) | (0 << 29); // version 0
  return <int>[
    0x2F,
    packed & 0xFF,
    (packed >> 8) & 0xFF,
    (packed >> 16) & 0xFF,
    (packed >> 24) & 0xFF,
  ];
}

/// Builds a `VP8X` chunk body with the supplied dimensions and alpha flag.
/// Layout (relative to chunk body start):
/// - 1 byte flags (bit 4 = alpha)
/// - 3 bytes reserved
/// - 3 bytes (width-1) LE
/// - 3 bytes (height-1) LE
List<int> _vp8xBody({
  required int width,
  required int height,
  required bool alpha,
}) {
  final flags = alpha ? 0x10 : 0x00;
  final w = width - 1;
  final h = height - 1;
  return <int>[
    flags, 0, 0, 0,
    w & 0xFF, (w >> 8) & 0xFF, (w >> 16) & 0xFF,
    h & 0xFF, (h >> 8) & 0xFF, (h >> 16) & 0xFF,
  ];
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('webp_header_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('readWebpFileHeaders parse paths', () {
    test('VP8 (lossy) returns 14-bit width/height, no alpha', () async {
      final bytes = _wrapWebp('VP8 ', _vp8Body(width: 640, height: 480));
      final f = File('${tmp.path}/lossy.webp');
      await f.writeAsBytes(bytes);
      final h = await readWebpFileHeaders(f.path);
      expect(h, isNotNull);
      expect(h!.width, 640);
      expect(h.height, 480);
      expect(h.bitDepth, 8);
      expect(h.numChannels, 3);
    });

    test('VP8L (lossless) without alpha', () async {
      final bytes = _wrapWebp(
        'VP8L',
        _vp8lBody(width: 800, height: 600, alpha: false),
      );
      final f = File('${tmp.path}/lossless_noalpha.webp');
      await f.writeAsBytes(bytes);
      final h = await readWebpFileHeaders(f.path);
      expect(h, isNotNull);
      expect(h!.width, 800);
      expect(h.height, 600);
      expect(h.bitDepth, 8);
      expect(h.numChannels, 3);
    });

    test('VP8L (lossless) with alpha', () async {
      final bytes = _wrapWebp(
        'VP8L',
        _vp8lBody(width: 256, height: 128, alpha: true),
      );
      final f = File('${tmp.path}/lossless_alpha.webp');
      await f.writeAsBytes(bytes);
      final h = await readWebpFileHeaders(f.path);
      expect(h, isNotNull);
      expect(h!.width, 256);
      expect(h.height, 128);
      expect(h.bitDepth, 8);
      expect(h.numChannels, 4);
    });

    test('VP8X (extended) with alpha', () async {
      final bytes = _wrapWebp(
        'VP8X',
        _vp8xBody(width: 1234, height: 567, alpha: true),
      );
      final f = File('${tmp.path}/ext_alpha.webp');
      await f.writeAsBytes(bytes);
      final h = await readWebpFileHeaders(f.path);
      expect(h, isNotNull);
      expect(h!.width, 1234);
      expect(h.height, 567);
      expect(h.bitDepth, 8);
      expect(h.numChannels, 4);
    });

    test('VP8X (extended) without alpha', () async {
      final bytes = _wrapWebp(
        'VP8X',
        _vp8xBody(width: 4096, height: 2160, alpha: false),
      );
      final f = File('${tmp.path}/ext_noalpha.webp');
      await f.writeAsBytes(bytes);
      final h = await readWebpFileHeaders(f.path);
      expect(h, isNotNull);
      expect(h!.width, 4096);
      expect(h.height, 2160);
      expect(h.bitDepth, 8);
      expect(h.numChannels, 3);
    });
  });

  group('readWebpFileHeaders failure paths', () {
    test('truncated file throws', () async {
      final f = File('${tmp.path}/truncated.webp');
      await f.writeAsBytes(Uint8List.fromList('RIFF'.codeUnits));
      await expectThrows(() => readWebpFileHeaders(f.path));
    });

    test('bad RIFF signature throws', () async {
      final bytes = _wrapWebp('VP8 ', _vp8Body(width: 10, height: 10));
      bytes[0] = 0x00;
      final f = File('${tmp.path}/bad_riff.webp');
      await f.writeAsBytes(bytes);
      await expectThrows(() => readWebpFileHeaders(f.path));
    });

    test('bad WEBP fourcc throws', () async {
      final bytes = _wrapWebp('VP8 ', _vp8Body(width: 10, height: 10));
      bytes[8] = 0x00;
      final f = File('${tmp.path}/bad_webp.webp');
      await f.writeAsBytes(bytes);
      await expectThrows(() => readWebpFileHeaders(f.path));
    });

    test('unknown chunk fourcc throws', () async {
      final bytes = _wrapWebp('XXXX', List.filled(20, 0));
      final f = File('${tmp.path}/unknown.webp');
      await f.writeAsBytes(bytes);
      await expectThrows(() => readWebpFileHeaders(f.path));
    });

    test('VP8L with bad signature byte throws', () async {
      final body = _vp8lBody(width: 10, height: 10, alpha: false);
      body[0] = 0x00; // corrupt the 0x2F signature
      final bytes = _wrapWebp('VP8L', body);
      final f = File('${tmp.path}/bad_vp8l.webp');
      await f.writeAsBytes(bytes);
      await expectThrows(() => readWebpFileHeaders(f.path));
    });
  });
}
