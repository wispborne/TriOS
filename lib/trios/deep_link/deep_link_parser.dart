/// Parsing logic for `starsector-mod://` deep link URIs.
///
/// Format: `starsector-mod://install?mod=<entry>[&dep=<entry>...]`
/// - `mod`: the main mod (required).
/// - `dep`: a dependency (optional, repeatable).
///
/// Each `<entry>` value is one of two forms (auto-detected):
/// - a bare URL — `https://.../Mod.version` (or a direct archive URL); or
/// - a JSON object — `{"url":"https://.../Mod.version","id":"mod_id"}`, where
///   `url` is required, `id` is optional, and any extra keys are ignored. This
///   form is extensible: new optional keys can be added without breaking older
///   clients. Detected by a leading `{`.
///
/// A `.version` URL is fetched for metadata + download URL; anything else is
/// treated as a direct download.
library;

import 'dart:convert';

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

  /// Optional mod id (`mod_info.json` `id`) supplied by the link, used for
  /// reliable already-installed matching. Null when the link didn't include it.
  final String? modId;

  const DeepLinkModEntry({required this.url, required this.source, this.modId});

  @override
  String toString() =>
      'DeepLinkModEntry(${source.name}: $url${modId != null ? ', id: $modId' : ''})';
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

  // Parse the main mod (required).
  final mainMod = _parseEntry(uri.queryParameters['mod'] ?? '');
  if (mainMod == null) return null;

  // Parse dependencies (repeated `dep` params; skip any that don't parse).
  final dependencies = (uri.queryParametersAll['dep'] ?? [])
      .map(_parseEntry)
      .whereType<DeepLinkModEntry>()
      .toList();

  return DeepLinkRequest(
    action: action,
    mainMod: mainMod,
    dependencies: dependencies,
  );
}

/// Parses one `mod`/`dep` value into an entry, or null if invalid.
///
/// Accepts a bare URL (`https://.../X.version`) or a JSON object
/// (`{"url":"https://.../X.version","id":"mod_id"}`) — detected by a leading
/// `{`. `url` is required; `id` is optional; unknown keys are ignored.
DeepLinkModEntry? _parseEntry(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  String? urlString;
  String? modId;

  if (value.startsWith('{')) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;
      final url = decoded['url'];
      if (url is! String) return null;
      urlString = url;
      final id = decoded['id'];
      if (id is String && id.trim().isNotEmpty) modId = id.trim();
    } catch (_) {
      return null;
    }
  } else {
    urlString = value;
  }

  final url = validateHttpUrl(urlString);
  if (url == null) return null;
  return DeepLinkModEntry(url: url, source: _detectSource(url), modId: modId);
}

/// Only allow http/https URLs.
Uri? validateHttpUrl(String? urlString) {
  if (urlString == null) return null;
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
