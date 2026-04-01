import 'dart:io';
import 'dart:ui' as ui;

/// Load the pixel dimensions of an image file without fully decoding it.
///
/// Returns `null` if the file doesn't exist or can't be decoded.
/// The result is delivered asynchronously via [ui.instantiateImageCodec].
Future<ui.Size?> loadImageSize(String? path) async {
  if (path == null) return null;
  final file = File(path);
  if (!file.existsSync()) return null;

  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return ui.Size(
    frame.image.width.toDouble(),
    frame.image.height.toDouble(),
  );
}
