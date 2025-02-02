import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/models/graphics_lib_info.dart';

import '../../models/version.dart';

part 'vram_checker_models.mapper.dart';

@MappableClass()
class VramMod with VramModMappable {
  VramCheckerMod info;
  bool isEnabled;
  List<ModImage> images;

  VramMod(this.info, this.isEnabled, this.images);

  late final maxPossibleBytesForMod = images.map((e) => e.bytesUsed).sum;

  // Cache for storing results of bytesUsingGraphicsLibConfig
  final Map<GraphicsLibConfig?, int> _cache = {};

  int bytesUsingGraphicsLibConfig(GraphicsLibConfig? graphicsLibConfig) {
    // Check if the result is already cached
    if (_cache.containsKey(graphicsLibConfig)) {
      return _cache[graphicsLibConfig]!;
    }

    // Compute the result and store it in the cache
    final result = images
        .where((element) => graphicsLibConfig == null
            ? true
            : element.isUsedBasedOnGraphicsLibConfig(graphicsLibConfig))
        .map((e) => e.bytesUsed)
        .sum;

    _cache[graphicsLibConfig] = result;
    return result;
  }
}

@MappableClass()
class VramCheckerMod with VramCheckerModMappable {
  final ModInfo modInfo;
  final String modFolder;

  VramCheckerMod(this.modInfo, this.modFolder);

  String get smolId => createSmolId(modInfo.id, modInfo.version);

  String get modId => modInfo.id;

  String? get name => modInfo.name;

  Version? get version => modInfo.version;

  String get formattedName => "$name $version (${modInfo.id})";
}

@MappableClass()
class ModImage with ModImageMappable {
  static const vanillaBackgroundTextSizeInBytes = 12582912.0;
  String filePath;
  int textureHeight;
  int textureWidth;
  int bitsInAllChannelsSum;
  ImageType imageType;
  MapType? graphicsLibType;

  ModImage(this.filePath, this.textureHeight, this.textureWidth,
      this.bitsInAllChannelsSum, this.imageType, this.graphicsLibType);

  File get file => File(filePath);

  /// Textures are mipmapped and therefore use 125% memory. Backgrounds are not.
  late final double multiplier =
      (imageType == ImageType.background) ? 1.0 : 4.0 / 3.0;

  late int bytesUsed = ((textureHeight *
              textureWidth *
              (bitsInAllChannelsSum / 8) *
              multiplier) -
          ((imageType == ImageType.background)
              ? vanillaBackgroundTextSizeInBytes
              : 0.0))
      .ceil();

  bool isUsedBasedOnGraphicsLibConfig(GraphicsLibConfig? graphicsLibConfig) {
    if (graphicsLibConfig == null) {
      return graphicsLibType == null;
    }

    return switch (graphicsLibType) {
      null => true,
      MapType.Normal => graphicsLibConfig.areGfxLibNormalMapsEnabled,
      MapType.Material => graphicsLibConfig.areGfxLibMaterialMapsEnabled,
      MapType.Surface => graphicsLibConfig.areGfxLibSurfaceMapsEnabled,
    };
  }
}

@MappableEnum()
enum ImageType { texture, background, unused }
