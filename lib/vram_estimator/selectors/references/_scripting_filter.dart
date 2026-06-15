import 'package:trios/vram_estimator/selectors/path_normalizer.dart';

/// Shared filtering logic for asset-path-like strings extracted from
/// scripting sources (JAR class constant pools, loose `.java` sources).
///
/// Retains a string if it contains `/` AND either ends in a known image
/// extension or starts with one of the known Starsector resource roots.
///
/// Directory-prefix literals (strings starting with a resource root and
/// ending with `/`) are returned as-is for the caller to expand against
/// on-disk images.
class ScriptingStringFilter {
  static const _resourceRoots = <String>['graphics/', 'data/', 'sounds/'];

  /// Returns true if [s] should be retained as a reference candidate.
  /// Input is expected to be already normalized via [PathNormalizer.normalize].
  static bool shouldRetain(String s) {
    if (s.isEmpty) return false;
    if (!s.contains('/')) return false;
    if (PathNormalizer.hasImageExtension(s)) return true;
    return _resourceRoots.any((root) => s.startsWith(root));
  }

  /// True if [s] is a directory prefix — starts with a known resource root
  /// and ends with a trailing slash.
  static bool isDirectoryPrefix(String s) {
    if (!s.endsWith('/')) return false;
    return _resourceRoots.any((root) => s.startsWith(root));
  }
}
