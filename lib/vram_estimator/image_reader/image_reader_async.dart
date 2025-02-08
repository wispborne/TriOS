import 'dart:io';

import 'package:image/image.dart' as img;

import 'png_chatgpt.dart';

class ReadImageHeaders {
  Future<ImageHeader?> readPng(String path) async {
    // Squadron.debug("Reading $path using png");
    return readPngFileHeaders(path);
  }

  Future<ImageHeader?> readGeneric(String path) async {
    // Squadron.debug("Reading $path using generic");
    final file = File(path);

    if (img.findDecoderForNamedImage(file.path) == null) {
      throw Exception("Not an image.");
    }
    // withContext(Dispatchers.IO) {
    final image = (await (img.Command()
              ..decodeNamedImage(file.path, file.readAsBytesSync()))
            .executeThread())
        .outputImage;

    if (image == null) {
      throw Exception("Failed to read image.");
    }

    return ImageHeader(
        image.width, image.height, image.bitsPerChannel, image.numChannels);
  }
}
