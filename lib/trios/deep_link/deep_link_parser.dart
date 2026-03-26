/// Parsing logic for `starsector-mod://` deep link URIs.
///
/// Format: `starsector-mod://install?mod=<url>[&dep=<url>...]`
/// - `mod`: main mod URL (required). Auto-detected as .version file or direct download.
/// - `dep`: dependency URL (optional, repeatable). Same auto-detection.
library;

const deepLinkScheme = 'starsector-mod';

/// Parsed result of a `starsector-mod://` URI.
class DeepLinkRequest {
  final DeepLinkAction action;
  final DeepLinkModEntry mainMod;
  final List<DeepLinkModEntry> dependencies;

  const DeepLinkRequest({
    required this.action,
    required this.mainMod,
    this.dependencies = const [],
  });

  @override
  String toString() =>
      'DeepLinkRequest(action: $action, mainMod: $mainMod, deps: ${dependencies.length})';
}

/// A single mod entry (either the main mod or a dependency).
class DeepLinkModEntry {
  final Uri url;
  final DeepLinkModSource source;

  const DeepLinkModEntry({required this.url, required this.source});

  @override
  String toString() => 'DeepLinkModEntry(${source.name}: $url)';
}

enum DeepLinkAction { install }

/// How to interpret the URL.
enum DeepLinkModSource {
  /// URL points to a `.version` JSON file — fetch it to get metadata + download URL.
  versionFile,

  /// URL points directly to a mod archive (zip, 7z, etc.).
  directDownload,
}

/// Parses a raw URI string into a [DeepLinkRequest], or returns null if invalid.
DeepLinkRequest? parseDeepLink(String rawUri) {
  final uri = Uri.tryParse(rawUri);
  if (uri == null) return null;
  if (uri.scheme != deepLinkScheme) return null;

  // The "host" in `starsector-mod://install?...` is "install".
  final action = switch (uri.host.toLowerCase()) {
    'install' => DeepLinkAction.install,
    _ => null,
  };
  if (action == null) return null;

  // Parse main mod URL.
  final modUrlString = uri.queryParameters['mod'];
  if (modUrlString == null || modUrlString.isEmpty) return null;

  final modUrl = _validateUrl(modUrlString);
  if (modUrl == null) return null;

  final mainMod = DeepLinkModEntry(
    url: modUrl,
    source: _detectSource(modUrl),
  );

  // Parse dependency URLs (repeated `dep` params).
  final depStrings = uri.queryParametersAll['dep'] ?? [];
  final dependencies = <DeepLinkModEntry>[];
  for (final depString in depStrings) {
    final depUrl = _validateUrl(depString);
    if (depUrl != null) {
      dependencies.add(
        DeepLinkModEntry(url: depUrl, source: _detectSource(depUrl)),
      );
    }
  }

  return DeepLinkRequest(
    action: action,
    mainMod: mainMod,
    dependencies: dependencies,
  );
}

/// Only allow http/https URLs.
Uri? _validateUrl(String urlString) {
  final url = Uri.tryParse(urlString);
  if (url == null) return null;
  if (url.scheme != 'http' && url.scheme != 'https') return null;
  if (url.host.isEmpty) return null;
  return url;
}

/// Auto-detect: if the URL path ends in `.version`, treat as a version file.
DeepLinkModSource _detectSource(Uri url) {
  final path = url.path.toLowerCase();
  if (path.endsWith('.version')) {
    return DeepLinkModSource.versionFile;
  }
  return DeepLinkModSource.directDownload;
}
