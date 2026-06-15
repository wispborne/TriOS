import 'package:dart_mappable/dart_mappable.dart';
import 'package:intl/intl.dart';

part 'forum_mod_index.mapper.dart';

/// Hook to parse forum date strings like "November 17, 2022, 07:14:08 AM".
class ForumDateHook extends MappingHook {
  const ForumDateHook();

  static final _format = DateFormat("MMMM d, yyyy, hh:mm:ss a", 'en_US');

  @override
  dynamic beforeDecode(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return _format.parse(value);
      } catch (_) {
        return null;
      }
    }
    return value;
  }

  @override
  dynamic beforeEncode(dynamic value) {
    if (value is DateTime) return _format.format(value);
    return value;
  }
}

/// A single entry from the forum data bundle's `index` array.
@MappableClass()
class ForumModIndex with ForumModIndexMappable {
  final int topicId;
  final String title;
  final String? category;
  final bool inModIndex;
  final bool isArchivedModIndex;
  final String? gameVersion;
  final String author;
  final int replies;
  final int views;
  @MappableField(hook: ForumDateHook())
  final DateTime? createdDate;
  @MappableField(hook: ForumDateHook())
  final DateTime? lastPostDate;
  final String? lastPostBy;
  final String topicUrl;
  final String? thumbnailPath;
  final DateTime? scrapedAt;
  final bool isWip;
  final int? sourceBoard;

  ForumModIndex({
    required this.topicId,
    required this.title,
    this.category,
    required this.inModIndex,
    required this.isArchivedModIndex,
    this.gameVersion,
    required this.author,
    required this.replies,
    required this.views,
    this.createdDate,
    this.lastPostDate,
    this.lastPostBy,
    required this.topicUrl,
    this.thumbnailPath,
    this.scrapedAt,
    required this.isWip,
    this.sourceBoard,
  });
}
