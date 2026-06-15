import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/logging.dart';

/// Small reusable HTTP-JSON fetcher with a TTL'd on-disk cache and a stale
/// fallback when the network fetch fails. Both [mod_browser_manager] and
/// [forum_data_manager] use one of these to avoid re-implementing the same
/// cache/TTL/stale-fallback dance.
class CachedJsonFetcher {
  final String cacheFileName;
  final String metaFileName;
  final String url;
  final Duration maxAge;

  /// Short name used in log messages, e.g. `"mod repo"`.
  final String logTag;

  const CachedJsonFetcher({
    required this.cacheFileName,
    required this.metaFileName,
    required this.url,
    required this.maxAge,
    required this.logTag,
  });

  File get _cacheFile =>
      File(p.join(Constants.cacheDirPath.path, cacheFileName));

  File get _metaFile => File(p.join(Constants.cacheDirPath.path, metaFileName));

  /// Returns the cached body if it's still fresh, otherwise fetches from
  /// [url] and updates the cache. On fetch failure, falls back to the stale
  /// cache if one exists.
  Future<String> fetch({bool bypassCache = false}) async {
    if (!bypassCache) {
      try {
        final meta = jsonDecode(_metaFile.readAsStringSync());
        final cachedAt = DateTime.parse(meta['cachedAt'] as String);
        final age = DateTime.now().difference(cachedAt);
        if (age < maxAge) {
          final body = _cacheFile.readAsStringSync();
          Fimber.i('Using cached $logTag (cached ${age.inMinutes}m ago)');
          return body;
        }
      } catch (_) {
        // Missing/corrupt cache — fall through to fetch.
      }
    }

    try {
      final response = await http.get(Uri.parse(url));
      final body = response.body;

      try {
        Constants.cacheDirPath.createSync(recursive: true);
        _cacheFile.writeAsStringSync(body);
        _metaFile.writeAsStringSync(
          jsonEncode({'cachedAt': DateTime.now().toIso8601String()}),
        );
      } catch (e) {
        Fimber.w('Failed to write $logTag cache', ex: e);
      }

      return body;
    } catch (ex) {
      try {
        final body = _cacheFile.readAsStringSync();
        Fimber.w('$logTag fetch failed, falling back to stale cache', ex: ex);
        return body;
      } catch (_) {
        rethrow;
      }
    }
  }

  /// Deletes both the cached body file and the metadata file from disk.
  void clearCache() {
    for (final file in [_cacheFile, _metaFile]) {
      try {
        file.deleteSync();
      } catch (_) {
        // Already gone or inaccessible — nothing to do.
      }
    }
  }

  /// Returns the `cachedAt` timestamp from the metadata file, or `null` if
  /// no cache exists or the metadata is unreadable.
  DateTime? getCacheTimestamp() {
    try {
      final meta = jsonDecode(_metaFile.readAsStringSync());
      return DateTime.parse(meta['cachedAt'] as String);
    } catch (_) {
      return null;
    }
  }

  /// Absolute path of the on-disk cache file (for display in UI).
  String get cacheFilePath => _cacheFile.path;
}
