import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:ktx/collections.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/models/graphics_lib_info.dart';

import '../../models/version.dart';

part 'vram_checker_models.mapper.dart';

/// Represents the type of an image asset.
@MappableEnum()
enum ImageType { texture, background, unused }

/// A columnar data structure for image metadata. Instead of creating an object per image,
/// this class uses parallel lists to store fields (file paths, dimensions, etc.) which reduces
/// per-object overhead.
class ModImageTable {
  static const double vanillaBackgroundTextSizeInBytes = 12582912.0;

  final List<String> filePaths;
  final List<int> textureHeights;
  final List<int> textureWidths;
  final List<int> bitsInAllChannelsSums;
  final List<ImageType> imageTypes;
  final List<MapType?> graphicsLibTypes;

  ModImageTable._(
    this.filePaths,
    this.textureHeights,
    this.textureWidths,
    this.bitsInAllChannelsSums,
    this.imageTypes,
    this.graphicsLibTypes,
  );

  /// Constructs a [ModImageTable] from a list of maps (typically parsed from JSON).
  factory ModImageTable.fromRows(List<Map<String, dynamic>> rows) {
    final length = rows.length;
    final filePaths = List<String>.filled(length, '', growable: false);
    final heights = List<int>.filled(length, 0, growable: false);
    final widths = List<int>.filled(length, 0, growable: false);
    final bits = List<int>.filled(length, 0, growable: false);
    final types = List<ImageType>.filled(
      length,
      ImageType.texture,
      growable: false,
    );
    final gfxTypes = List<MapType?>.filled(length, null, growable: false);

    for (int i = 0; i < length; i++) {
      final row = rows[i];
      filePaths[i] = row['filePath'] as String;
      heights[i] = row['textureHeight'] as int;
      widths[i] = row['textureWidth'] as int;
      bits[i] = row['bitsInAllChannelsSum'] as int;

      // Convert string to ImageType enum; default to texture if unrecognized.
      final imageTypeStr = row['imageType'] as String?;
      if (imageTypeStr != null) {
        types[i] = ImageType.values.firstWhere(
          (e) => e.name == imageTypeStr,
          orElse: () => ImageType.texture,
        );
      }

      // Optional graphics library type conversion.
      final gfxTypeStr = row['graphicsLibType'] as String?;
      if (gfxTypeStr != null) {
        gfxTypes[i] = MapType.values.firstWhereOrNull(
          (m) => m.name == gfxTypeStr,
        );
      }
    }

    return ModImageTable._(filePaths, heights, widths, bits, types, gfxTypes);
  }

  /// Converts the columnar data back into a list of maps for JSON serialization.
  List<Map<String, dynamic>> toRows() {
    final rows = <Map<String, dynamic>>[];
    for (int i = 0; i < filePaths.length; i++) {
      rows.add({
        'filePath': filePaths[i],
        'textureHeight': textureHeights[i],
        'textureWidth': textureWidths[i],
        'bitsInAllChannelsSum': bitsInAllChannelsSums[i],
        'imageType': imageTypes[i].name,
        'graphicsLibType': graphicsLibTypes[i]?.name,
      });
    }
    return rows;
  }

  List<ModImageView> toImageViews() =>
      List.generate(filePaths.length, (i) => ModImageView(i, this));

  int get length => filePaths.length;
}

/// A lightweight view into a single row of [ModImageTable]. This class provides the
/// same functionality as the original [ModImage] but without storing per-image objects.
class ModImageView {
  final int index;
  final ModImageTable table;

  ModImageView(this.index, this.table);

  String get filePath => table.filePaths[index];

  int get textureHeight => table.textureHeights[index];

  int get textureWidth => table.textureWidths[index];

  int get bitsInAllChannelsSum => table.bitsInAllChannelsSums[index];

  ImageType get imageType => table.imageTypes[index];

  MapType? get graphicsLibType => table.graphicsLibTypes[index];

  File get file => File(filePath);

  /// Returns the memory multiplier (125% for mipmaps; 100% for backgrounds).
  double get multiplier =>
      (imageType == ImageType.background) ? 1.0 : (4.0 / 3.0);

  /// Computes the memory usage (in bytes) of the image.
  int get bytesUsed {
    const vanillaBackgroundTextSizeInBytes = 12582912.0;
    final rawSize =
        (textureHeight *
            textureWidth *
            (bitsInAllChannelsSum / 8) *
            multiplier) -
        ((imageType == ImageType.background)
            ? vanillaBackgroundTextSizeInBytes
            : 0.0);
    return rawSize.ceil();
  }

  /// Determines if the image is used based on the provided graphics library configuration.
  bool isUsedBasedOnGraphicsLibConfig() {
    return graphicsLibType == null;
  }

  @override
  String toString() {
    return 'ModImageView{index: $index, filePath: $filePath, textureHeight: $textureHeight, textureWidth: $textureWidth, bitsInAllChannelsSum: $bitsInAllChannelsSum, imageType: $imageType, graphicsLibType: $graphicsLibType}';
  }
}

/// A custom mapping hook for converting between a [ModImageTable] and its JSON representation.
class ModImageTableHook extends MappingHook {
  const ModImageTableHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value is List) {
      return ModImageTable.fromRows(value.cast<Map<String, dynamic>>());
    }
    throw Exception('ModImageTableHook: Invalid JSON structure: $value');
  }

  @override
  dynamic beforeEncode(dynamic value) {
    if (value is ModImageTable) {
      return value.toRows();
    }
    throw Exception('ModImageTableHook: Invalid type: $value');
  }
}

/// Contains basic mod metadata.
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

/// Represents a mod with VRAM usage information.
@MappableClass()
class VramMod with VramModMappable {
  final VramCheckerMod info;
  final bool isEnabled;
  final List<GraphicsLibInfo>? graphicsLibEntries;

  @MappableField(hook: ModImageTableHook())
  final ModImageTable images;

  VramMod(this.info, this.isEnabled, this.images, this.graphicsLibEntries);

  /// Computes the total bytes used by all images in the table.
  late final int _maxPossibleBytesForMod = Iterable<int>.generate(
    images.length,
  ).map((i) => ModImageView(i, images).bytesUsed).sum;

  ModImageView getModViewForIndex(int index) => ModImageView(index, images);

  List<int>? _cache;

  /// Each value is the usage by one of the images.GraphicsLib() {
  List<int> imagesNotIncludingGraphicsLib() {
    if (_cache != null) {
      return _cache!;
    }

    _cache = images
        .toImageViews()
        .where((view) => view.graphicsLibType == null)
        .map((view) => view.bytesUsed)
        .toList();

    return _cache!;
  }

  int bytesNotIncludingGraphicsLib() => imagesNotIncludingGraphicsLib().sum;
}
