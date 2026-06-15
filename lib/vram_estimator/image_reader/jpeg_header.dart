import 'dart:io';
import 'dart:typed_data';

import 'png_chatgpt.dart';

const int _jpegMaxScan = 65536;
const int _jpegInitialRead = 4096;
const int _jpegChunkRead = 4096;

Future<ImageHeader?> readJpegFileHeaders(String path) async {
  RandomAccessFile? raf;
  try {
    raf = await File(path).open();
    final builder = BytesBuilder(copy: false);
    final initial = await raf.read(_jpegInitialRead);
    builder.add(initial);
    int totalRead = initial.length;

    Future<bool> ensureAvailable(int upTo) async {
      while (builder.length < upTo) {
        if (totalRead >= _jpegMaxScan) return false;
        final remaining = _jpegMaxScan - totalRead;
        final wanted = remaining < _jpegChunkRead ? remaining : _jpegChunkRead;
        final chunk = await raf!.read(wanted);
        if (chunk.isEmpty) return false;
        builder.add(chunk);
        totalRead += chunk.length;
      }
      return true;
    }

    Uint8List bytes() => builder.toBytes();

    if (!await ensureAvailable(2)) {
      throw Exception('This file is not a JPEG.');
    }
    final head = bytes();
    if (head[0] != 0xFF || head[1] != 0xD8) {
      throw Exception('This file is not a JPEG.');
    }

    int offset = 2;
    while (true) {
      if (!await ensureAvailable(offset + 2)) {
        throw Exception('JPEG SOF not found within first 64 KB.');
      }
      final buf = bytes();
      if (buf[offset] != 0xFF) {
        throw Exception('JPEG marker expected at offset $offset.');
      }
      // Skip any padding 0xFF bytes (JPEG fill bytes).
      int markerOffset = offset + 1;
      while (true) {
        if (!await ensureAvailable(markerOffset + 1)) {
          throw Exception('JPEG SOF not found within first 64 KB.');
        }
        if (bytes()[markerOffset] != 0xFF) break;
        markerOffset++;
      }
      final marker = bytes()[markerOffset];
      offset = markerOffset + 1;

      // SOI (D8) and EOI (D9) have no payload.
      if (marker == 0xD8 || marker == 0xD9) {
        continue;
      }

      // Standalone markers with no length: RSTn (D0..D7), TEM (01).
      if ((marker >= 0xD0 && marker <= 0xD7) || marker == 0x01) {
        continue;
      }

      // SOF markers: every defined Start-Of-Frame marker.
      // C0..C3, C5..C7, C9..CB, CD..CF.
      final isSof = (marker >= 0xC0 && marker <= 0xC3) ||
          (marker >= 0xC5 && marker <= 0xC7) ||
          (marker >= 0xC9 && marker <= 0xCB) ||
          (marker >= 0xCD && marker <= 0xCF);

      if (!await ensureAvailable(offset + 2)) {
        throw Exception('JPEG SOF not found within first 64 KB.');
      }
      final segBuf = bytes();
      final segLen = (segBuf[offset] << 8) | segBuf[offset + 1];
      if (segLen < 2) {
        throw Exception('Invalid JPEG segment length: $segLen.');
      }

      if (isSof) {
        // Segment payload: precision(1) height(2) width(2) components(1).
        if (!await ensureAvailable(offset + 2 + 6)) {
          throw Exception('JPEG SOF segment truncated.');
        }
        final sof = bytes();
        final precision = sof[offset + 2];
        final height = (sof[offset + 3] << 8) | sof[offset + 4];
        final width = (sof[offset + 5] << 8) | sof[offset + 6];
        final components = sof[offset + 7];
        return ImageHeader(width, height, precision, components);
      }

      // Non-SOF: skip the segment (length includes the 2 length bytes).
      offset += segLen;
    }
  } finally {
    await raf?.close();
  }
}
