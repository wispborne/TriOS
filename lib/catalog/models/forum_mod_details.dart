import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/catalog/models/forum_link.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/viewer_cache/packed_bytes.dart';

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
  final Uint8List _contentHtmlZipped;
  String? _contentHtmlText;

  /// The whole forum post, as HTML.
  ///
  /// Held zipped. Every card on the Catalog page reads one of these objects for
  /// the author, the version and the images, so all nine hundred of them are in
  /// memory whenever that page is open — about seven megabytes of HTML, of
  /// which only the post someone actually opens is ever read. Zipped, it is
  /// closer to one megabyte. The first read unzips it and keeps the text, so
  /// rebuilding an open post does not unzip it again.
  String get contentHtml =>
      _contentHtmlText ??= utf8.decode(unsqueeze(_contentHtmlZipped));

  final List<String>? images;
  final List<ForumLink>? links;
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
    required String contentHtml,
    this.images,
    this.links,
    this.scrapedAt,
    required this.isPlaceholderDetail,
  }) : _contentHtmlZipped = squeeze(
         Uint8List.fromList(utf8.encode(contentHtml)),
       );
}
