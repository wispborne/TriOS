import 'package:dart_mappable/dart_mappable.dart';

part 'mod_record_source.mapper.dart';

/// Base class for mod record sources. Each subtype represents a different
/// place where information about a mod was found.
@MappableClass(discriminatorKey: 'sourceType')
sealed class ModRecordSource with ModRecordSourceMappable {
  /// When this source was last updated.
  final DateTime? lastSeen;

  const ModRecordSource({this.lastSeen});
}

/// Source: mod is installed on disk.
@MappableClass(discriminatorValue: 'installed')
class InstalledSource extends ModRecordSource with InstalledSourceMappable {
  final String? installPath;
  final String? version;

  const InstalledSource({this.installPath, this.version, super.lastSeen});
}

/// Source: version checker data from .version files.
@MappableClass(discriminatorValue: 'versionChecker')
class VersionCheckerSource extends ModRecordSource
    with VersionCheckerSourceMappable {
  final String? forumThreadId;
  final String? nexusModsId;
  final String? directDownloadUrl;
  final String? changelogUrl;
  final String? masterVersionFileUrl;

  const VersionCheckerSource({
    this.forumThreadId,
    this.nexusModsId,
    this.directDownloadUrl,
    this.changelogUrl,
    this.masterVersionFileUrl,
    super.lastSeen,
  });
}

/// Source: mod catalog (ModRepo.json).
@MappableClass(discriminatorValue: 'catalog')
class CatalogSource extends ModRecordSource with CatalogSourceMappable {
  final String? catalogName;
  final String? forumUrl;
  final String? nexusUrl;
  final String? discordUrl;
  final String? directDownloadUrl;
  final String? downloadPageUrl;
  final String? forumThreadId;
  final String? nexusModsId;
  final List<String>? categories;

  const CatalogSource({
    this.catalogName,
    this.forumUrl,
    this.nexusUrl,
    this.discordUrl,
    this.directDownloadUrl,
    this.downloadPageUrl,
    this.forumThreadId,
    this.nexusModsId,
    this.categories,
    super.lastSeen,
  });
}

/// Source: download history captured when user downloads a mod.
@MappableClass(discriminatorValue: 'downloadHistory')
class DownloadHistorySource extends ModRecordSource
    with DownloadHistorySourceMappable {
  final String? lastDownloadedFrom;
  final DateTime? lastDownloadedAt;

  const DownloadHistorySource({
    this.lastDownloadedFrom,
    this.lastDownloadedAt,
    super.lastSeen,
  });
}
