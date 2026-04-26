import 'dart:io';

import 'png_chatgpt.dart';

Future<ImageHeader?> readWebpFileHeaders(String path) async {
  RandomAccessFile? raf;
  try {
    raf = await File(path).open();
    final bytes = await raf.read(30);
    if (bytes.length < 30) {
      throw Exception('This file is not a WEBP.');
    }

    // RIFF + WEBP container check.
    final isRiff = bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46;
    final isWebp = bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
    if (!isRiff || !isWebp) {
      throw Exception('This file is not a WEBP.');
    }

    final fourcc = String.fromCharCodes(bytes.sublist(12, 16));

    switch (fourcc) {
      case 'VP8 ':
        {
          // VP8 bitstream starts at offset 20. Width/height live in the 14 LSBs
          // of 16-bit LE values at offsets 26 and 28 (after the 3-byte frame
          // tag and the 3-byte start code 0x9D 0x01 0x2A).
          final width = ((bytes[26] | (bytes[27] << 8))) & 0x3FFF;
          final height = ((bytes[28] | (bytes[29] << 8))) & 0x3FFF;
          return ImageHeader(width, height, 8, 3);
        }
      case 'VP8L':
        {
          // VP8L body at offset 20. Signature byte 0x2F, then 4 bytes packing
          // (width-1):14, (height-1):14, alpha:1, version:3 little-endian.
          if (bytes[20] != 0x2F) {
            throw Exception('Invalid VP8L signature.');
          }
          final b0 = bytes[21];
          final b1 = bytes[22];
          final b2 = bytes[23];
          final b3 = bytes[24];
          final packed = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
          final width = (packed & 0x3FFF) + 1;
          final height = ((packed >> 14) & 0x3FFF) + 1;
          final alpha = ((packed >> 28) & 0x1) == 1;
          return ImageHeader(width, height, 8, alpha ? 4 : 3);
        }
      case 'VP8X':
        {
          // VP8X body at offset 20. Bit 4 of bytes[20] is alpha; width-1 is the
          // 24-bit LE value at offset 24; height-1 is the 24-bit LE value at
          // offset 27.
          final alpha = (bytes[20] & 0x10) != 0;
          final widthMinus1 =
              bytes[24] | (bytes[25] << 8) | (bytes[26] << 16);
          final heightMinus1 =
              bytes[27] | (bytes[28] << 8) | (bytes[29] << 16);
          return ImageHeader(
            widthMinus1 + 1,
            heightMinus1 + 1,
            8,
            alpha ? 4 : 3,
          );
        }
      default:
        throw Exception('Unknown WEBP chunk: $fourcc');
    }
  } finally {
    await raf?.close();
  }
}
