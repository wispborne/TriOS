import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hashlib/hashlib.dart';
import 'package:image/image.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/image_reader/png_chatgpt.dart';

import '../models/mod_variant.dart';

final isLoadingPortraits = StateProvider<bool>((ref) => false);

final portraitsProvider = StreamProvider<Map<ModVariant, List<Portrait>>>((
  ref,
) async* {
  final currentTime = DateTime.now();
  ref.watch(isLoadingPortraits.notifier).state = true;

  final variants = ref
      .watch(AppState.mods)
      .map((mod) => mod.findFirstEnabledOrHighestVersion)
      .nonNulls
      .toList();

  Fimber.i(
    'Scanning mod folders for square images in ${variants.length} mod versions',
  );

  final portraitsManager = _PortraitsManager();
  Map<ModVariant, List<Portrait>> allPortraits = {};

  // Process each mod variant
  for (final variant in variants) {
    final modResult = await portraitsManager._scanModVariantForSquareImages(
      variant,
    );
    if (modResult.isNotEmpty) {
      allPortraits[variant] = modResult;
    }

    // Yield intermediate results for progressive loading
    yield Map.from(allPortraits);
  }

  ref.watch(isLoadingPortraits.notifier).state = false;
  Fimber.i(
    'Scanned mod folders for square images in ${variants.length} mods in ${DateTime.now().difference(currentTime).inMilliseconds}ms',
  );
});

class _PortraitsManager {
  static const int minSizeInBytes = 15 * 1024; // 15 KB
  static const int minWidth = 128;
  static const int maxWidth = 256;
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', '.webp'];

  /// Scans the provided mod variants for square portrait images
  /// Returns a map of ModVariant to List of Portrait objects
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
        final portraits = await _scanModVariantForSquareImages(modVariant);
        if (portraits.isNotEmpty) {
          modImagesMap[modVariant] = portraits;
        }
      }).toList(),
    );

    Fimber.i(
      'Scanned mod folders for square images in ${modVariants.length} mods in ${timer.elapsedMilliseconds} ms',
    );
    return modImagesMap;
  }



  /// Scans a single mod variant for square portrait images
  Future<List<Portrait>> _scanModVariantForSquareImages(
      ModVariant modVariant,
      ) async {
    List<Portrait> squareImages = [];
    Set<String> uniqueImageHashes = {};

    if (await modVariant.modFolder.exists()) {
      await for (var entity in modVariant.modFolder.list(recursive: true)) {
        // Skip files from GraphicsLib (it has that /cache folder with generated normal maps,
        // and also it doesn't have any portraits)
        if (entity is File &&
            !(modVariant.modInfo.id == Constants.graphicsLibId) &&
            await _isImageFile(entity)) {
          try {
            Uint8List imageBytes = await entity.readAsBytes();
            final (imageWidth, imageHeight) = await _getImageSize(
              entity.path,
              imageBytes,
            );

            if (_isSquarePortraitSize(imageWidth, imageHeight)) {
              String imageHash = _hashImageBytes(imageBytes);

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
            Fimber.w('Error processing image: ${entity.path}, $e');
          }
        }
      }
    }

    return squareImages;
  }

  /// Checks if the given dimensions represent a valid square portrait
  bool _isSquarePortraitSize(int width, int height) {
    return width == height && width >= minWidth && width <= maxWidth;
  }

  /// Validates if a file is a supported image format and meets size requirements
  Future<bool> _isImageFile(File file) async {
    final String extension = file.path.toLowerCase();

    if (!allowedExtensions.any((ext) => extension.endsWith(ext))) {
      return false;
    }

    final int fileSize = await file.length();
    return fileSize >= minSizeInBytes;
  }

  /// Gets the dimensions of an image from its file path and byte data
  Future<(int, int)> _getImageSize(String path, Uint8List data) async {
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

  /// Generates a hash for image bytes to detect duplicates
  String _hashImageBytes(Uint8List imageBytes) {
    var digest = crc64.convert(imageBytes);
    return digest.toString();
  }

  /// Decodes an image based on its file extension
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
}

/// Represents a portrait image found in a mod
class Portrait {
  final String smolId;
  final File imageFile;
  final int width;
  final int height;
  final String hash;

  Portrait(this.smolId, this.imageFile, this.width, this.height, this.hash);

  @override
  String toString() {
    return 'Portrait{smolId: $smolId, path: ${imageFile.path}, size: ${width}x$height, hash: $hash}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Portrait &&
          runtimeType == other.runtimeType &&
          hash == other.hash;

  @override
  int get hashCode => hash.hashCode;
}
