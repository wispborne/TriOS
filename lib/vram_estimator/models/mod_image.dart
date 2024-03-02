import 'dart:io';


class ModImage {
  static const VANILLA_BACKGROUND_TEXTURE_SIZE_IN_BYTES = 12582912.0;
  File file;
  int textureHeight;
  int textureWidth;
  int bitsInAllChannelsSum;
  ImageType imageType;

  ModImage(this.file, this.textureHeight, this.textureWidth,
      this.bitsInAllChannelsSum, this.imageType);

  /// Textures are mipmapped and therefore use 125% memory. Backgrounds are not.
  late final double multiplier =
      (imageType == ImageType.Background) ? 1.0 : 4.0 / 3.0;

  late int bytesUsed = ((textureHeight *
              textureWidth *
              (bitsInAllChannelsSum / 8) *
              multiplier) -
// Number of bytes in a vanilla background image
// Only count any excess toward the mod's VRAM hit
          ((imageType == ImageType.Background)
              ? VANILLA_BACKGROUND_TEXTURE_SIZE_IN_BYTES
              : 0.0))
      .ceil(); // Round up
}

enum ImageType { Texture, Background, Unused }
