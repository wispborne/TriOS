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
  final String? name;
  final String? author;
  final String? installPath;
  final String? version;

  const InstalledSource({
    this.name,
    this.author,
    this.installPath,
    this.version,
    super.lastSeen,
  });

  /// Returns a new [InstalledSource] with override fields winning when non-null.
  InstalledSource applyOverridesFrom(InstalledSource overrides) =>
      InstalledSource(
        name: overrides.name ?? name,
        author: overrides.author ?? author,
        installPath: overrides.installPath ?? installPath,
        version: overrides.version ?? version,
        lastSeen: lastSeen,
      );
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

  /// Returns a new [VersionCheckerSource] with override fields winning when non-null.
  VersionCheckerSource applyOverridesFrom(VersionCheckerSource overrides) =>
      VersionCheckerSource(
        forumThreadId: overrides.forumThreadId ?? forumThreadId,
        nexusModsId: overrides.nexusModsId ?? nexusModsId,
        directDownloadUrl: overrides.directDownloadUrl ?? directDownloadUrl,
        changelogUrl: overrides.changelogUrl ?? changelogUrl,
        masterVersionFileUrl:
            overrides.masterVersionFileUrl ?? masterVersionFileUrl,
        lastSeen: lastSeen,
      );
}

/// Source: mod catalog (ModRepo.json).
@MappableClass(discriminatorValue: 'catalog')
class CatalogSource extends ModRecordSource with CatalogSourceMappable {
  final String? name;
  final List<String>? authors;
  final String? forumUrl;
  final String? nexusUrl;
  final String? discordUrl;
  final String? directDownloadUrl;
  final String? downloadPageUrl;
  final String? forumThreadId;
  final String? nexusModsId;
  final List<String>? categories;

  const CatalogSource({
    this.name,
    this.authors,
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

  /// Returns a new [CatalogSource] with override fields winning when non-null.
  CatalogSource applyOverridesFrom(CatalogSource overrides) => CatalogSource(
    name: overrides.name ?? name,
    authors: overrides.authors ?? authors,
    forumUrl: overrides.forumUrl ?? forumUrl,
    nexusUrl: overrides.nexusUrl ?? nexusUrl,
    discordUrl: overrides.discordUrl ?? discordUrl,
    directDownloadUrl: overrides.directDownloadUrl ?? directDownloadUrl,
    downloadPageUrl: overrides.downloadPageUrl ?? downloadPageUrl,
    forumThreadId: overrides.forumThreadId ?? forumThreadId,
    nexusModsId: overrides.nexusModsId ?? nexusModsId,
    categories: overrides.categories ?? categories,
    lastSeen: lastSeen,
  );
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

  /// Returns a new [DownloadHistorySource] with override fields winning when non-null.
  DownloadHistorySource applyOverridesFrom(DownloadHistorySource overrides) =>
      DownloadHistorySource(
        lastDownloadedFrom:
            overrides.lastDownloadedFrom ?? lastDownloadedFrom,
        lastDownloadedAt: overrides.lastDownloadedAt ?? lastDownloadedAt,
        lastSeen: lastSeen,
      );
}
