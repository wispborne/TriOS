import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart';
import 'package:trios/utils/logging.dart';

import '../models/mod_variant.dart';

const int minSizeInBytes = 15 * 1024; // 15 KB
const int minWidth = 128;
const int maxWidth = 256;

Future<Map<ModVariant, List<Portrait>>> scanModFoldersForSquareImages(
    List<ModVariant> modVariants) async {
  Map<ModVariant, List<Portrait>> modImagesMap = {};
  final timer = Stopwatch()..start();

  await Future.wait(modVariants.map((modVariant) async {
    List<Portrait> squareImages = [];
    Set<String> uniqueImageHashes = {};

    if (await modVariant.modsFolder.exists()) {
      await for (var entity in modVariant.modsFolder.list(recursive: true)) {
        if (entity is File && await _isImageFile(entity)) {
          try {
            Uint8List imageBytes = await entity.readAsBytes();
              final (imageWidth, imageHeight) = await getImageSize(imageBytes);

              if (imageWidth == imageHeight &&
                  imageWidth >= minWidth &&
                  imageWidth <= maxWidth) {
                String imageHash = hashImageBytes(imageBytes);

                if (!uniqueImageHashes.contains(imageHash)) {
                uniqueImageHashes.add(imageHash);
                squareImages.add(Portrait(
                    modVariant.smolId, entity, imageWidth, imageHeight, imageHash));
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
  }).toList());

  Fimber.i(
      'Scanned mod folders for square images in ${modVariants.length} mods in ${timer.elapsedMilliseconds} ms');
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

Future<bool> _isImageFile(File file) async {
  final List<String> allowedExtensions = ['jpg', 'jpeg', 'png'];
  final String extension = file.path.split('.').last.toLowerCase();

  if (!allowedExtensions.contains(extension)) {
    return false;
  }

  final int fileSize = await file.length();
  return fileSize >= minSizeInBytes;
}

Future<(int, int)> getImageSize(Uint8List data) async {
  final buffer = await ImmutableBuffer.fromUint8List(data);
  final descriptor = await ImageDescriptor.encoded(buffer);

  final imageWidth = descriptor.width;
  final imageHeight = descriptor.height;
  return (imageWidth, imageHeight);
}

String hashImageBytes(Uint8List imageBytes) {
  var digest = md5.convert(imageBytes);
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
