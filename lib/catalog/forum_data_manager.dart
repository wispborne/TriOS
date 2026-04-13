import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/models/forum_data_bundle.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/cached_json_fetcher.dart';
import 'package:trios/utils/logging.dart';

final isLoadingForumData = StateProvider<bool>((ref) => false);

/// Shared fetcher for QB's forum data bundle.
final forumDataFetcher = CachedJsonFetcher(
  cacheFileName: 'forum_data_bundle.json',
  metaFileName: 'forum_data_bundle.meta',
  url: Constants.forumDataBundleUrl,
  maxAge: Duration(hours: 24),
  logTag: 'forum data',
);

final forumDataProvider = StreamProvider<ForumDataBundle>((ref) async* {
  final currentTime = DateTime.now();
  ref.watch(isLoadingForumData.notifier).state = true;
  String rawJson;

  try {
    rawJson = await forumDataFetcher.fetch();
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

/// Top-level function used with `compute()` to parse the `details` section of
/// the cached forum bundle off the UI isolate. Input is the raw JSON body,
/// output is a map from `topicId` (int) to `ForumModDetails`.
Map<int, ForumModDetails> _parseForumDetails(String rawJson) {
  final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
  final detailsRaw = decoded['details'];
  if (detailsRaw is! Map) return {};

  final result = <int, ForumModDetails>{};
  detailsRaw.forEach((key, value) {
    if (value is! Map) return;
    final topicId = int.tryParse(key.toString());
    if (topicId == null) return;
    try {
      final details = ForumModDetailsMapper.fromMap(
        Map<String, dynamic>.from(value),
      );
      result[topicId] = details;
    } catch (_) {
      // Skip malformed detail entries without failing the whole parse.
    }
  });
  return result;
}

/// On-demand provider for the rich `details` section of the forum data
/// bundle. Parsing is deferred until the first read (the catalog hot path
/// via [forumDataProvider] intentionally skips `details`). The raw JSON is
/// re-read from the shared cache via [forumDataFetcher]; the heavy
/// `jsonDecode` + mapping runs in a background isolate via [compute].
///
/// The resulting map is cached for the app lifetime, keyed by `topicId`.
final forumDetailsByTopicId = FutureProvider<Map<int, ForumModDetails>>((
  ref,
) async {
  final started = DateTime.now();
  final String rawJson;
  try {
    rawJson = await forumDataFetcher.fetch();
  } catch (ex, st) {
    Fimber.w('Failed to fetch forum data bundle for details', ex: ex, stacktrace: st);
    return const {};
  }

  try {
    final map = await compute(_parseForumDetails, rawJson);
    Fimber.i(
      'Parsed ${map.length} forum detail entries in '
      '${DateTime.now().difference(started).inMilliseconds}ms',
    );
    return map;
  } catch (ex, st) {
    Fimber.w('Failed to parse forum data bundle details', ex: ex, stacktrace: st);
    return const {};
  }
});

/// Thin per-topic lookup. Returns null while the details are still parsing,
/// or when the topic is not present in the bundle.
final forumDetailsForTopic = Provider.family<ForumModDetails?, int>((
  ref,
  topicId,
) {
  final map = ref.watch(forumDetailsByTopicId).valueOrNull;
  return map?[topicId];
});

