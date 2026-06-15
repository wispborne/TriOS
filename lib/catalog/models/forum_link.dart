import 'package:dart_mappable/dart_mappable.dart';

part 'forum_link.mapper.dart';

/// A single link entry within a [ForumModDetails] post, as emitted by the
/// forum data bundle.
@MappableClass()
class ForumLink with ForumLinkMappable {
  final String url;
  final String text;
  final bool isExternal;
  final bool isDownloadable;

  const ForumLink({
    required this.url,
    this.text = '',
    this.isExternal = false,
    this.isDownloadable = false,
  });
}
