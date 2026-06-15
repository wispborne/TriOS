import 'gif_header.dart';
import 'jpeg_header.dart';
import 'png_chatgpt.dart';
import 'webp_header.dart';

class ReadImageHeaders {
  Future<ImageHeader?> readImageDeterminingBest(String path) async {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return readPngFileHeaders(path);
    } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return readJpegFileHeaders(path);
    } else if (lower.endsWith('.gif')) {
      return readGifFileHeaders(path);
    } else if (lower.endsWith('.webp')) {
      return readWebpFileHeaders(path);
    } else {
      throw Exception('Not an image.');
    }
  }
}
