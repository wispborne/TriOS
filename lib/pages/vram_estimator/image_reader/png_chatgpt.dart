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
  // Open the file
  var file = File(path);
  RandomAccessFile? fileStream;
  try {
    fileStream = file.openSync();

    // Read the PNG signature plus the first chunk (IHDR)
    var bytes = fileStream.readSync(8 + 8 + 13).toList();

    // Flatten the list of lists into a single list of bytes
    var flatList = bytes; //.expand((byteList) => byteList).toList();

    // Verify PNG signature
    var pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
    for (int i = 0; i < pngSignature.length; i++) {
      if (flatList[i] != pngSignature[i]) {
        throw Exception('This file is not a PNG.');
      }
    }

    // Assuming the file is a PNG, proceed to read the IHDR chunk
    // IHDR starts at byte 8, after the PNG signature
    var ihdrStart = 8 + 4; // Skip the length field of the IHDR chunk
    var type = utf8.decode(flatList.sublist(ihdrStart, ihdrStart + 4));
    if (type != 'IHDR') {
      throw Exception('IHDR chunk not found.');
    }

    // Read IHDR content
    var ihdrContentStart = ihdrStart + 4;
    var width = _bytesToUint32(
        flatList.sublist(ihdrContentStart, ihdrContentStart + 4));
    var height = _bytesToUint32(
        flatList.sublist(ihdrContentStart + 4, ihdrContentStart + 8));
    var bitDepth = flatList[ihdrContentStart + 8];
    var colorType = flatList[ihdrContentStart + 9];

    final numChannels = switch (colorType) {
      0 => 1,
      3 => 1,
      2 => 3,
      4 => 2,
      6 => 4,
      _ => throw Exception('Invalid color type: $colorType')
    };

    return ImageHeader(width, height, bitDepth, numChannels);
  } finally {
    fileStream?.close();
  }
}

// Utility function to convert 4 bytes into a uint32
int _bytesToUint32(List<int> bytes) {
  return ByteData.sublistView(Uint8List.fromList(bytes))
      .getUint32(0, Endian.big);
}
