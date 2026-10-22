import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';

part 'forum_data_bundle.mapper.dart';

/// Top-level wrapper for the forum data bundle (`mod-catalog-details.json`).
/// Only parses `updatedAt`, `index` and `discordThreads`; `details` and
/// `assumedDownloads` are ignored to avoid loading ~13MB of HTML content.
@MappableClass()
class ForumDataBundle with ForumDataBundleMappable {
  final DateTime updatedAt;
  final List<ForumModIndex> index;
  final List<DiscordThreadAnswer> discordThreads;

  ForumDataBundle({
    required this.updatedAt,
    required this.index,
    this.discordThreads = const [],
  });
}

/// The AI's answer for one Discord announcement thread. Holds no message text.
@MappableClass()
class DiscordThreadAnswer with DiscordThreadAnswerMappable {
  final String threadId;
  final String url;

  /// The thread's title.
  final String name;
  final List<ForumLlmMod> mods;

  DiscordThreadAnswer({
    required this.threadId,
    required this.url,
    required this.name,
    this.mods = const [],
  });
}
