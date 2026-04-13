import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';

part 'forum_mod_details.mapper.dart';

/// A single entry from the forum data bundle's `details` map.
/// Contains the full post HTML plus rich metadata about the topic and author.
@MappableClass()
class ForumModDetails with ForumModDetailsMappable {
  final int topicId;
  final String title;
  final String? category;
  final String? gameVersion;
  final String author;
  final String? authorTitle;
  final int? authorPostCount;
  final String? authorAvatarPath;
  @MappableField(hook: ForumDateHook())
  final DateTime? postDate;
  @MappableField(hook: ForumDateHook())
  final DateTime? lastEditDate;
  final String contentHtml;
  final List<String>? images;
  final List<String>? links;
  final DateTime? scrapedAt;
  final bool isPlaceholderDetail;

  ForumModDetails({
    required this.topicId,
    required this.title,
    this.category,
    this.gameVersion,
    required this.author,
    this.authorTitle,
    this.authorPostCount,
    this.authorAvatarPath,
    this.postDate,
    this.lastEditDate,
    required this.contentHtml,
    this.images,
    this.links,
    this.scrapedAt,
    required this.isPlaceholderDetail,
  });
}
