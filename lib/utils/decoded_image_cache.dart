import 'dart:io';
import 'dart:ui' as ui;

/// Decoded images for CustomPaint, with one app-wide memory budget.
///
/// This exists alongside Flutter's own ImageCache because these images feed
/// `canvas.drawImage` in painters (ship blueprints, weapon composites,
/// engine flames), which needs raw [ui.Image] handles. Flutter's cache works
/// in widget-layer image streams and can't hand those out. Widgets showing
/// plain pictures should use `Image.file` with `cacheWidth`, not this.
///
/// The app-wide instance is behind [loadDecodedImage].

/// Read and decode an image file's first frame.
///
/// Returns `null` if the file is missing or can't be decoded. Not cached —
/// use [loadDecodedImage] unless the image is one-off.
Future<ui.Image?> decodeImageFile(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    return (await codec.getNextFrame()).image;
  } catch (_) {
    return null;
  }
}

/// The pixel dimensions of an image file, or `null` if it can't be read.
///
/// Reads only the image header — no pixels are decoded, so this is cheap and
/// doesn't belong in (or pollute) the decoded-image cache.
Future<ui.Size?> loadImageSize(String? path) async {
  if (path == null) return null;
  try {
    final buffer = await ui.ImmutableBuffer.fromFilePath(path);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final size = ui.Size(
      descriptor.width.toDouble(),
      descriptor.height.toDouble(),
    );
    descriptor.dispose();
    buffer.dispose();
    return size;
  } catch (_) {
    return null;
  }
}

/// The one shared cache. One budget, shared across features, so a sprite
/// used both as a weapon-grid image and as a ship's built-in weapon overlay
/// is decoded and held once.
final _sharedCache = DecodedImageCache(
  budgetBytes: 64 * 1024 * 1024,
  decode: decodeImageFile,
);

/// The decoded image for [path], from the shared cache.
///
/// Returns `null` (inside the future) if the file is missing or can't be
/// decoded.
Future<ui.Image?> loadDecodedImage(String path) => _sharedCache.load(path);

/// Decoded bytes currently held by the shared cache, for debug display.
int get decodedImageCacheBytes => _sharedCache.totalBytes;

/// Images currently held by the shared cache, for debug display.
int get decodedImageCacheCount => _sharedCache.entryCount;

/// A decoded-image cache with a byte budget.
///
/// Keeps the most recently used images; when the total decoded pixel bytes go
/// over [budgetBytes], the least recently used entries are dropped. Without a
/// budget, a cache like this grows by every sprite ever shown and never gives
/// the memory back — scrolling the weapons grid once cost ~80 MB for the rest
/// of the session.
///
/// Dropped images are NOT disposed, only released: a widget may still be
/// painting one (e.g. a visible grid row holds the image in its state). The
/// garbage collector frees the pixel memory once nothing holds the image.
class DecodedImageCache {
  DecodedImageCache({required this.budgetBytes, required this.decode});

  /// Rough ceiling on total decoded pixel bytes (width × height × 4 each).
  final int budgetBytes;

  /// How to load and decode a path when it isn't cached.
  final Future<ui.Image?> Function(String path) decode;

  /// Insertion-ordered; the first key is the least recently used.
  final _entries = <String, Future<ui.Image?>>{};
  final _bytesByPath = <String, int>{};
  int _totalBytes = 0;

  int get totalBytes => _totalBytes;

  int get entryCount => _entries.length;

  /// The image for [path], decoding it if needed. Returns null (inside the
  /// future) if the file is missing or can't be decoded.
  Future<ui.Image?> load(String path) {
    final existing = _entries.remove(path);
    if (existing != null) {
      // Re-insert so this entry becomes the most recently used.
      _entries[path] = existing;
      return existing;
    }

    final pending = decode(path);
    _entries[path] = pending;
    pending.then(
      (image) {
        // Skip if this entry was already evicted while decoding.
        if (image == null || !_entries.containsKey(path)) return;
        _bytesByPath[path] = image.width * image.height * 4;
        _totalBytes += _bytesByPath[path]!;
        _evictOverBudget();
      },
      onError: (_) {
        _entries.remove(path);
      },
    );
    return pending;
  }

  void _evictOverBudget() {
    // Keep at least the newest entry, even if it alone is over budget.
    while (_totalBytes > budgetBytes && _entries.length > 1) {
      final oldest = _entries.keys.first;
      _entries.remove(oldest);
      _totalBytes -= _bytesByPath.remove(oldest) ?? 0;
    }
  }
}
