/// Canonical path normalization for VRAM reference matching.
///
/// Starsector's resource loader is case-insensitive on Windows and mod
/// authors frequently mismatch path case or separator style. References
/// extracted from JSON/CSV/JAR strings are compared against on-disk file
/// paths by normalizing both sides through the same pipeline.
class PathNormalizer {
  static const _imageExtensions = <String>[
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
  ];

  /// Lowercase, forward-slash, strip leading slashes. Empty strings pass
  /// through unchanged (and stay empty — they won't match anything).
  static String normalize(String path) {
    var s = path.replaceAll('\\', '/').toLowerCase().trim();
    while (s.startsWith('/')) {
      s = s.substring(1);
    }
    return s;
  }

  /// Expand a single reference path into the set of normalized forms that
  /// could match an on-disk file:
  /// - the path itself (normalized)
  /// - the path with each image extension appended, if it has no extension
  ///
  /// This lets reference parsers emit paths as written in source (often
  /// with the extension omitted) while still matching `.png` (or similar)
  /// files on disk.
  static Set<String> expand(String path) {
    final base = normalize(path);
    if (base.isEmpty) return const <String>{};
    final hasExt = _imageExtensions.any((e) => base.endsWith(e));
    if (hasExt) return {base};
    return {base, for (final ext in _imageExtensions) '$base$ext'};
  }

  /// True if the given (already normalized) path ends in a known image
  /// extension.
  static bool hasImageExtension(String normalizedPath) =>
      _imageExtensions.any((e) => normalizedPath.endsWith(e));
}
