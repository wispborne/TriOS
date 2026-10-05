import 'package:dart_mappable/dart_mappable.dart';

part 'archived_save.mapper.dart';

/// What TriOS knows about a save that has been archived.
///
/// Written next to the archive as a small JSON file so the archive list can be
/// shown without unpacking anything. It is a convenience, never a source of
/// truth: if it is missing or unreadable, the details are read back out of the
/// archive's own `descriptor.xml`, and if that fails too the archive still
/// shows up and can still be restored.
@MappableClass()
class ArchivedSave with ArchivedSaveMappable {
  /// The name of the save folder inside the archive, which is also the name it
  /// gets back when restored.
  final String saveFolderName;

  final String? characterName;
  final int? characterLevel;
  final String? portraitPath;
  final String? saveFileVersion;

  /// When the game wrote the save.
  final DateTime? saveDate;

  /// The in-game date, as a count of seconds.
  final int? gameTimestamp;

  final double? secondsPerDay;
  final String? difficulty;
  final bool? isIronMode;

  /// Names of the mods the save had enabled, for showing in a list.
  final List<String> modNames;

  final int fileCount;

  /// Size of the save folder before it was compressed.
  final int originalSizeInBytes;

  /// Size of the archive on disk when it was written.
  final int archiveSizeInBytes;

  /// When TriOS archived it.
  final DateTime archivedDate;

  ArchivedSave({
    required this.saveFolderName,
    this.characterName,
    this.characterLevel,
    this.portraitPath,
    this.saveFileVersion,
    this.saveDate,
    this.gameTimestamp,
    this.secondsPerDay,
    this.difficulty,
    this.isIronMode,
    this.modNames = const [],
    this.fileCount = 0,
    this.originalSizeInBytes = 0,
    this.archiveSizeInBytes = 0,
    required this.archivedDate,
  });

  /// How much smaller the archive is, as a fraction between 0 and 1.
  ///
  /// Null when the original size wasn't recorded.
  double? get spaceSavedFraction {
    if (originalSizeInBytes <= 0) return null;
    final saved = originalSizeInBytes - archiveSizeInBytes;
    if (saved <= 0) return 0;
    return saved / originalSizeInBytes;
  }
}
