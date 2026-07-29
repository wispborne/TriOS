import 'dart:io';

import 'package:trios/utils/extensions.dart';

sealed class ModImageSource {
  const ModImageSource();

  static ModImageSource? web(String? url) =>
      (url == null || url.isEmpty) ? null : WebModImage(url);

  static ModImageSource? file(String? path) {
    if (path == null || path.isEmpty) return null;
    return FileModImage(path.toFile());
  }
}

class WebModImage extends ModImageSource {
  final String url;
  const WebModImage(this.url);
}

class FileModImage extends ModImageSource {
  final File file;
  const FileModImage(this.file);
}
