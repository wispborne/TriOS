import 'dart:io';


class ModImage {
  static const vanillaBackgroundTextSizeInBytes = 12582912.0;
  String filePath;
  int textureHeight;
  int textureWidth;
  int bitsInAllChannelsSum;
  ImageType imageType;

  ModImage(this.filePath, this.textureHeight, this.textureWidth,
      this.bitsInAllChannelsSum, this.imageType);

  File get file => File(filePath);

  /// Textures are mipmapped and therefore use 125% memory. Backgrounds are not.
  late final double multiplier =
      (imageType == ImageType.background) ? 1.0 : 4.0 / 3.0;

  late int bytesUsed = ((textureHeight *
              textureWidth *
              (bitsInAllChannelsSum / 8) *
              multiplier) -
// Number of bytes in a vanilla background image
// Only count any excess toward the mod's VRAM hit
          ((imageType == ImageType.background)
              ? vanillaBackgroundTextSizeInBytes
              : 0.0))
      .ceil(); // Round up
}

enum ImageType { texture, background, unused }
