import 'dart:io';

import 'png_chatgpt.dart';

Future<ImageHeader?> readGifFileHeaders(String path) async {
  RandomAccessFile? raf;
  try {
    raf = await File(path).open();
    final bytes = await raf.read(13);
    if (bytes.length < 13) {
      throw Exception('This file is not a GIF.');
    }

    // Signature: 'GIF87a' or 'GIF89a'.
    final isGif87a = bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38 &&
        bytes[4] == 0x37 &&
        bytes[5] == 0x61;
    final isGif89a = bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38 &&
        bytes[4] == 0x39 &&
        bytes[5] == 0x61;
    if (!isGif87a && !isGif89a) {
      throw Exception('This file is not a GIF.');
    }

    final width = bytes[6] | (bytes[7] << 8);
    final height = bytes[8] | (bytes[9] << 8);

    // Hard-code bitDepth=8, numChannels=4 to match what package:image returned
    // for GIFs after palette expansion. The LSD packed field's "color
    // resolution" bits encode palette bit depth, not channel count, so we
    // intentionally ignore them here.
    return ImageHeader(width, height, 8, 4);
  } finally {
    await raf?.close();
  }
}
