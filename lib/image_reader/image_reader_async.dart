import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:squadron/squadron.dart';
import 'package:squadron/squadron_annotations.dart';

import 'image_reader_async.activator.g.dart';
import 'png_chatgpt.dart';

part 'image_reader_async.worker.g.dart';

@UseLogger(ConsoleSquadronLogger)
@SquadronService(web: false)
class ReadImageHeaders {
  @SquadronMethod()
  Future<ImageHeader?> readPng(String path) async {
    Squadron.debug("Reading $path using png");
    return readPngFileHeaders(path);
  }

  @SquadronMethod()
  Future<ImageHeader?> readGeneric(String path) async {
    Squadron.debug("Reading $path using generic");
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
