import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:hashlib/hashlib.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/image_reader/png_chatgpt.dart';

import '../models/mod_variant.dart';

/// Handles scanning mod folders for portrait images
class PortraitScanner {
  static const int minSizeInBytes = 15 * 1024; // 15 KB
  static const int minWidth = 128;
  static const int maxWidth = 256;
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', '.webp'];

  /// Scans multiple mod variants and returns results as a stream
  Stream<Map<ModVariant, List<Portrait>>> scanVariantsStream(
    List<ModVariant> variants,
  ) async* {
    final timer = Stopwatch()..start();
    Map<ModVariant, List<Portrait>> allPortraits = {};

    Fimber.i('Scanning ${variants.length} mod variants for portraits');

    for (final variant in variants) {
      final portraits = await _scanSingleVariant(variant);
      if (portraits.isNotEmpty) {
        allPortraits[variant] = portraits;
      }
      yield Map.from(allPortraits);
    }

    Fimber.i('Portrait scan completed in ${timer.elapsedMilliseconds}ms');
  }

  /// Scans multiple mod variants (non-streaming)
  Future<Map<ModVariant, List<Portrait>>> scanVariants(
    List<ModVariant> variants,
  ) async {
    final timer = Stopwatch()..start();
    Map<ModVariant, List<Portrait>> results = {};

    await Future.wait(
      variants.map((variant) async {
        final portraits = await _scanSingleVariant(variant);
        if (portraits.isNotEmpty) {
          results[variant] = portraits;
        }
      }),
    );

    Fimber.i(
      'Scanned ${variants.length} variants in ${timer.elapsedMilliseconds}ms',
    );
    return results;
  }

  /// Scans a single mod variant for portrait images
  Future<List<Portrait>> _scanSingleVariant(ModVariant variant) async {
    if (!await variant.modFolder.exists()) return [];

    final portraits = <Portrait>[];
    final uniqueHashes = <String>{};

    await for (final entity in variant.modFolder.list(recursive: true)) {
      if (entity is File &&
          !_isGraphicsLib(variant) &&
          await _isValidImageFile(entity)) {
        final portrait = await _processImageFile(entity, variant.smolId);
        if (portrait != null && uniqueHashes.add(portrait.hash)) {
          portraits.add(portrait);
        }
      }
    }

    return portraits;
  }

  /// Processes a single image file into a Portrait object
  Future<Portrait?> _processImageFile(File file, String smolId) async {
    try {
      final imageBytes = await file.readAsBytes();
      final (width, height) = await _getImageSize(file.path, imageBytes);

      if (_isValidPortraitSize(width, height)) {
        final hash = _hashImageBytes(imageBytes);
        return Portrait(smolId, file, width, height, hash);
      }
    } catch (e) {
      Fimber.w('Error processing ${file.path}: $e');
    }
    return null;
  }

  bool _isGraphicsLib(ModVariant variant) =>
      variant.modInfo.id == Constants.graphicsLibId;

  bool _isValidPortraitSize(int width, int height) {
    return width == height && width >= minWidth && width <= maxWidth;
  }

  Future<bool> _isValidImageFile(File file) async {
    final extension = file.path.toLowerCase();
    if (!allowedExtensions.any((ext) => extension.endsWith(ext))) return false;

    final fileSize = await file.length();
    return fileSize >= minSizeInBytes;
  }

  Future<(int, int)> _getImageSize(String path, Uint8List data) async {
    if (path.toLowerCase().endsWith('.png')) {
      final image = readPngHeadersFromBytes(data);
      return (image!.width, image.height);
    } else {
      final buffer = await ImmutableBuffer.fromUint8List(data);
      final descriptor = await ImageDescriptor.encoded(buffer);
      return (descriptor.width, descriptor.height);
    }
  }

  String _hashImageBytes(Uint8List bytes) => crc64.convert(bytes).toString();
}
