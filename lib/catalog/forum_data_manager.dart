import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/models/forum_data_bundle.dart';
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

