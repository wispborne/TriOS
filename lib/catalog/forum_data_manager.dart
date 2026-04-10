import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:trios/catalog/models/forum_data_bundle.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/logging.dart';

final isLoadingForumData = StateProvider<bool>((ref) => false);

final forumDataProvider = StreamProvider<ForumDataBundle>((ref) async* {
  final currentTime = DateTime.now();
  ref.watch(isLoadingForumData.notifier).state = true;
  String rawJson;

  try {
    rawJson = await _fetchForumDataWithCache();
  } catch (ex, st) {
    Fimber.w('Failed to fetch forum data bundle', ex: ex, stacktrace: st);
    ref.watch(isLoadingForumData.notifier).state = false;
    return;
  }

  try {
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    // Only parse updatedAt and index, skip details/assumedDownloads.
    final bundle = ForumDataBundleMapper.fromMap({
      'updatedAt': decoded['updatedAt'],
      'index': decoded['index'],
    });

    ref.watch(isLoadingForumData.notifier).state = false;
    Fimber.i(
      'Parsed ${bundle.index.length} forum mod entries in '
      '${DateTime.now().difference(currentTime).inMilliseconds}ms',
    );

    yield bundle;
  } catch (ex, st) {
    Fimber.w('Failed to parse forum data bundle', ex: ex, stacktrace: st);
    ref.watch(isLoadingForumData.notifier).state = false;
    return;
  }
});

/// O(1) lookup map from topicId to ForumModIndex, built from the latest
/// forum data bundle.
final forumDataByTopicId = Provider<Map<int, ForumModIndex>>((ref) {
  final bundle = ref.watch(forumDataProvider).valueOrNull;
  if (bundle == null) return {};
  return {for (final entry in bundle.index) entry.topicId: entry};
});

const _cacheMaxAge = Duration(hours: 24);

/// Cache file name for the forum data bundle.
const _cacheFileName = 'forum_data_bundle.json';
const _metaFileName = 'forum_data_bundle.meta';

Future<String> _fetchForumDataWithCache({bool bypassCache = false}) async {
  final cacheDir = Constants.cacheDirPath;
  final cacheFile = File(p.join(cacheDir.path, _cacheFileName));
  final metaFile = File(p.join(cacheDir.path, _metaFileName));

  // Try reading from cache.
  if (!bypassCache) {
    try {
      final meta = jsonDecode(metaFile.readAsStringSync());
      final cachedAt = DateTime.parse(meta['cachedAt'] as String);

      if (DateTime.now().difference(cachedAt) < _cacheMaxAge) {
        final body = cacheFile.readAsStringSync();
        Fimber.i(
          'Using cached forum data '
          '(cached ${DateTime.now().difference(cachedAt).inMinutes}m ago)',
        );
        return body;
      }
    } catch (_) {
      // Missing/corrupt cache — fall through to fetch.
    }
  }

  // Fetch fresh data.
  try {
    final response = await http.get(Uri.parse(Constants.forumDataBundleUrl));
    final body = response.body;

    // Write to cache. createSync is a no-op if the dir already exists.
    try {
      cacheDir.createSync(recursive: true);
      cacheFile.writeAsStringSync(body);
      metaFile.writeAsStringSync(
        jsonEncode({'cachedAt': DateTime.now().toIso8601String()}),
      );
    } catch (e) {
      Fimber.w('Failed to write forum data cache', ex: e);
    }

    return body;
  } catch (ex) {
    // Fallback to stale cache if available.
    try {
      final body = cacheFile.readAsStringSync();
      Fimber.w(
        'Forum data fetch failed, falling back to stale cache',
        ex: ex,
      );
      return body;
    } catch (_) {
      rethrow;
    }
  }
}

/// Forces a re-fetch of the forum data, bypassing the cache TTL.
Future<String> forceRefreshForumData() => _fetchForumDataWithCache(bypassCache: true);

/// Clears the cached forum data files from disk.
void clearForumDataCache() {
  final cacheDir = Constants.cacheDirPath;
  for (final name in [_cacheFileName, _metaFileName]) {
    try {
      File(p.join(cacheDir.path, name)).deleteSync();
    } catch (_) {
      // Already gone or inaccessible — nothing to do.
    }
  }
}

/// Returns the cache metadata (cachedAt timestamp), or null if no cache exists.
DateTime? getForumDataCacheTimestamp() {
  try {
    final metaFile = File(
      p.join(Constants.cacheDirPath.path, _metaFileName),
    );
    final meta = jsonDecode(metaFile.readAsStringSync());
    return DateTime.parse(meta['cachedAt'] as String);
  } catch (_) {
    return null;
  }
}
