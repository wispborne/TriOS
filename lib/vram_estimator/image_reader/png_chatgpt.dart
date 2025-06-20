import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class ImageHeader {
  int width;
  int height;
  int bitDepth;
  int numChannels;

  ImageHeader(this.width, this.height, this.bitDepth, this.numChannels);

  @override
  String toString() {
    return 'ImageHeader{width: $width, height: $height, bitDepth: $bitDepth, numChannels: $numChannels}';
  }
}

Future<ImageHeader?> readPngFileHeaders(String path) async {
  final file = File(path);
  RandomAccessFile? fileStream;
  try {
    fileStream = file.openSync();
    var bytes = fileStream.readSync(8 + 8 + 13).toList();
    return readPngHeadersFromBytes(bytes);
  } finally {
    await fileStream?.close();
  }
}

ImageHeader? readPngHeadersFromBytes(List<int> bytes) {
  // Need at least PNG signature (8 bytes) + IHDR chunk length (4) + type (4) + content (13) = 29 bytes minimum
  if (bytes.length < 29) {
    throw Exception(
      'Insufficient bytes to read PNG header. Need at least 29 bytes.',
    );
  }

  // Verify PNG signature
  var pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
  for (int i = 0; i < pngSignature.length; i++) {
    if (bytes[i] != pngSignature[i]) {
      throw Exception('This file is not a PNG.');
    }
  }

  // Assuming the file is a PNG, proceed to read the IHDR chunk
  // IHDR starts at byte 8, after the PNG signature
  var ihdrStart = 8 + 4; // Skip the length field of the IHDR chunk
  var type = utf8.decode(bytes.sublist(ihdrStart, ihdrStart + 4));
  if (type != 'IHDR') {
    throw Exception('IHDR chunk not found.');
  }

  // Read IHDR content
  var ihdrContentStart = ihdrStart + 4;
  var width = _bytesToUint32(
    bytes.sublist(ihdrContentStart, ihdrContentStart + 4),
  );
  var height = _bytesToUint32(
    bytes.sublist(ihdrContentStart + 4, ihdrContentStart + 8),
  );
  var bitDepth = bytes[ihdrContentStart + 8];
  var colorType = bytes[ihdrContentStart + 9];

  final numChannels = switch (colorType) {
    0 => 1,
    3 => 1,
    2 => 3,
    4 => 2,
    6 => 4,
    _ => throw Exception('Invalid color type: $colorType'),
  };

  return ImageHeader(width, height, bitDepth, numChannels);
}

// Utility function to convert 4 bytes into a uint32
int _bytesToUint32(List<int> bytes) {
  return ByteData.sublistView(
    Uint8List.fromList(bytes),
  ).getUint32(0, Endian.big);
}
