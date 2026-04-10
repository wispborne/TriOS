import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';

part 'forum_data_bundle.mapper.dart';

/// Top-level wrapper for the forum data bundle.
/// Only parses `updatedAt` and `index`; `details` and `assumedDownloads`
/// are ignored to avoid loading ~13MB of HTML content.
@MappableClass()
class ForumDataBundle with ForumDataBundleMappable {
  final DateTime updatedAt;
  final List<ForumModIndex> index;

  ForumDataBundle({required this.updatedAt, required this.index});
}
