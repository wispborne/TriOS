import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:hashlib/hashlib.dart';
import 'package:image/image.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/image_reader/png_chatgpt.dart';

import '../models/mod_variant.dart';

const int minSizeInBytes = 15 * 1024; // 15 KB
const int minWidth = 128;
const int maxWidth = 256;

Future<Map<ModVariant, List<Portrait>>> scanModFoldersForSquareImages(
  List<ModVariant> modVariants,
) async {
  Map<ModVariant, List<Portrait>> modImagesMap = {};
  final timer = Stopwatch()..start();
  Fimber.i(
    'Scanning mod folders for square images in ${modVariants.length} mod versions',
  );

  await Future.wait(
    modVariants.map((modVariant) async {
      List<Portrait> squareImages = [];
      Set<String> uniqueImageHashes = {};

      if (await modVariant.modFolder.exists()) {
        await for (var entity in modVariant.modFolder.list(recursive: true)) {
          // Skip files GraphicsLib (it has that /cache folder with generated normal maps,
          // and also it doesn't have any portraits
          if (entity is File &&
              !(modVariant.modInfo.id == Constants.graphicsLibId) &&
              await _isImageFile(entity)) {
            try {
              Uint8List imageBytes = await entity.readAsBytes();
              final (imageWidth, imageHeight) = await getImageSize(
                entity.path,
                imageBytes,
              );

              if (imageWidth == imageHeight &&
                  imageWidth >= minWidth &&
                  imageWidth <= maxWidth) {
                String imageHash = hashImageBytes(imageBytes);

                if (!uniqueImageHashes.contains(imageHash)) {
                  uniqueImageHashes.add(imageHash);
                  squareImages.add(
                    Portrait(
                      modVariant.smolId,
                      entity,
                      imageWidth,
                      imageHeight,
                      imageHash,
                    ),
                  );
                }
              }
            } catch (e) {
              // Handle error (optional)
              Fimber.w('Error decoding image: ${entity.path}, $e');
            }
          }
        }
      }
      modImagesMap[modVariant] = squareImages;
    }).toList(),
  );

  Fimber.i(
    'Scanned mod folders for square images in ${modVariants.length} mods in ${timer.elapsedMilliseconds} ms',
  );
  return modImagesMap;
}

Image? _decodeImage(String filePath, Uint8List data) {
  final String extension = filePath.split('.').last.toLowerCase();
  switch (extension) {
    case 'jpg':
    case 'jpeg':
      return decodeJpg(data);
    case 'png':
      return decodePng(data);
    // Add other specific decoders if needed
    default:
      return null;
  }
}

final List<String> allowedExtensions = ['jpg', 'jpeg', 'png', '.webp'];

Future<bool> _isImageFile(File file) async {
  final String extension = file.path.toLowerCase();

  if (!allowedExtensions.any((ext) => extension.endsWith(ext))) {
    return false;
  }

  final int fileSize = await file.length();
  return fileSize >= minSizeInBytes;
}

Future<(int, int)> getImageSize(String path, Uint8List data) async {
  if (path.toLowerCase().endsWith(".png")) {
    final image = readPngHeadersFromBytes(data);
    return (image!.width, image.height);
  } else {
    final buffer = await ImmutableBuffer.fromUint8List(data);
    final descriptor = await ImageDescriptor.encoded(buffer);

    final imageWidth = descriptor.width;
    final imageHeight = descriptor.height;
    return (imageWidth, imageHeight);
  }
}

// Future<(int, int)> getImageSize(String path) async {
//   final image = await _imageSizeReader.readImageDeterminingBest(path);
//   return (image!.width, image.height);
// }

String hashImageBytes(Uint8List imageBytes) {
  var digest = crc64.convert(imageBytes);
  return digest.toString();
}

class Portrait {
  final String smolId;
  final File imageFile;
  final int width;
  final int height;
  final String hash;

  Portrait(this.smolId, this.imageFile, this.width, this.height, this.hash);
}
