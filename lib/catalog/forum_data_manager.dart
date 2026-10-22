import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:trios/catalog/models/forum_data_bundle.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/cached_json_fetcher.dart';
import 'package:trios/utils/log_collapser.dart';
import 'package:trios/utils/logging.dart';

final isLoadingForumData = StateProvider<bool>((ref) => false);

/// Shared fetcher for the forum data bundle (`mod-catalog-details.json`).
final forumDataFetcher = CachedJsonFetcher(
  cacheFileName: 'mod_catalog_details.json',
  metaFileName: 'mod_catalog_details.meta',
  url: Constants.modCatalogDetailsUrl,
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
    }).copyWith(discordThreads: _parseDiscordThreads(decoded['discordThreads']));
    ForumLlmDataHook.flushDroppedBlocks();

    ref.watch(isLoadingForumData.notifier).state = false;
    Fimber.i(
      'Parsed ${bundle.index.length} forum mod entries and '
      '${bundle.discordThreads.length} Discord threads in '
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
  final bundle = ref.watch(forumDataProvider).value;
  if (bundle == null) return {};
  return {for (final entry in bundle.index) entry.topicId: entry};
});

/// Lookup map from Discord thread id to the AI's answer for that thread.
final discordThreadsById = Provider<Map<String, DiscordThreadAnswer>>((ref) {
  final bundle = ref.watch(forumDataProvider).value;
  if (bundle == null) return {};
  return {for (final thread in bundle.discordThreads) thread.threadId: thread};
});

/// Parses the bundle's `discordThreads` one thread at a time, so one bad
/// thread costs only that thread's AI answer instead of the whole bundle.
List<DiscordThreadAnswer> _parseDiscordThreads(dynamic raw) {
  if (raw is! List) return const [];
  final threads = <DiscordThreadAnswer>[];
  final dropped = LogCollapser();
  for (final item in raw) {
    try {
      threads.add(
        DiscordThreadAnswerMapper.fromMap(Map<String, dynamic>.from(item as Map)),
      );
    } catch (ex) {
      dropped.add('$ex');
    }
  }
  dropped.flush('Discord thread answers', noun: 'dropped thread', asInfo: true);
  return threads;
}

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
/// The map is keyed by `topicId` and dropped a few minutes after the last
/// forum post closes. It holds the full post text of every mod on the forum —
/// around 16 MB of JSON — which is far too much to keep for the whole session
/// just because the user read one post. Re-parsing takes a moment in the
/// background, and the few-minute delay means reading several posts in a row
/// only parses once.
final forumDetailsByTopicId =
    FutureProvider.autoDispose<Map<int, ForumModDetails>>((ref) async {
      _holdBriefly(ref);
      final started = DateTime.now();
      final String rawJson;
      try {
        rawJson = await forumDataFetcher.fetch();
      } catch (ex, st) {
        Fimber.w(
          'Failed to fetch forum data bundle for details',
          ex: ex,
          stacktrace: st,
        );
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
        Fimber.w(
          'Failed to parse forum data bundle details',
          ex: ex,
          stacktrace: st,
        );
        return const {};
      }
    });

/// Thin per-topic lookup. Returns null while the details are still parsing,
/// or when the topic is not present in the bundle.
///
/// Auto-disposing, so that closing the last forum post also lets go of
/// [forumDetailsByTopicId].
final forumDetailsForTopic = Provider.autoDispose.family<ForumModDetails?, int>(
  (ref, topicId) {
    final map = ref.watch(forumDetailsByTopicId).value;
    return map?[topicId];
  },
);

/// Keeps a provider's value for [_detailsHoldTime] after its last listener
/// goes away, then lets it be thrown out.
void _holdBriefly(Ref ref) {
  final link = ref.keepAlive();
  Timer? dropTimer;
  ref.onCancel(() {
    dropTimer = Timer(_detailsHoldTime, link.close);
  });
  ref.onResume(() {
    dropTimer?.cancel();
    dropTimer = null;
  });
  ref.onDispose(() => dropTimer?.cancel());
}

/// How long the parsed forum posts stick around after the last one closes.
const _detailsHoldTime = Duration(minutes: 2);
