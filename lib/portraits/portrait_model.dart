import 'dart:io';
import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:hashlib/hashlib.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:trios/utils/extensions.dart';

part 'portrait_model.mapper.dart';

/// Represents a portrait image found in a mod
@MappableClass()
class Portrait with PortraitMappable {
  final ModVariant? modVariant;
  @MappableField(hook: FileHook())
  final File imageFile;

  /// Relative to the mod folder or `starsector-core`.
  final String relativePath;
  final int width;
  final int height;
  String hash;

  Portrait({
    this.modVariant,
    required this.imageFile,
    required this.relativePath,
    required this.width,
    required this.height,
    required this.hash,
  });

  Portrait.fromBytes({
    this.modVariant,
    required this.imageFile,
    required this.relativePath,
    required this.width,
    required this.height,
    required Uint8List imageBytes,
  }) : hash = hashImagesBytes(imageBytes);

  static String hashImagesBytes(Uint8List imageBytes) =>
      crc64.convert(imageBytes).toString();

  @override
  String toString() {
    return 'Portrait{smolId: ${modVariant?.smolId}, path: ${imageFile.path}, size: ${width}x$height, hash: $hash}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Portrait &&
          runtimeType == other.runtimeType &&
          hash == other.hash;

  @override
  int get hashCode => hash.hashCode;

  SavedPortrait toSavedPortrait() =>
      SavedPortrait(relativePath: relativePath, lastKnownFullPath: imageFile.path, hash: hash);
}

@MappableClass()
class SavedPortrait with SavedPortraitMappable {
  /// Relative to the mod folder or `starsector-core`.
  final String relativePath;

  /// Note: DO NOT USE FOR ANYTHING EXCEPT BEST-GUESS DISPLAY.
  /// This allows displaying a replacement portrait without having to scan all portraits or images,
  /// but it is tied to the game install path and the mod folder name, both of which may change without changing hash+relative path!
  final String lastKnownFullPath;
  final String hash;

  SavedPortrait({
    required this.relativePath,
    required this.lastKnownFullPath,
    required this.hash,
  });

  Portrait? toPortrait(Map<String, Portrait> portraitsByHash) =>
      portraitsByHash[hash];

  File imageFile(ModVariant? variant, Directory gameCoreFolder) => relativePath
      .toFile()
      .relativeTo(variant?.modFolder ?? gameCoreFolder)
      .toFile();
}

@MappableClass()
class ReplacedSavedPortrait with ReplacedSavedPortraitMappable {
  SavedPortrait original;
  SavedPortrait replacement;

  ReplacedSavedPortrait({required this.original, required this.replacement});
}
