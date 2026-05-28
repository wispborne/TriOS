import 'dart:io';

import 'package:trios/mod_manager/mod_install_source.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';

/// Status of the overall batch operation.
enum BatchStatus { pending, scanning, confirming, installing, complete }

/// Status of a single entry within the batch.
enum BatchEntryStatus {
  queued,
  scanning,
  scanned,
  extracting,
  done,
  failed,
  skipped,
}

/// Result of pre-scanning a single archive.
class ScannedArchive {
  /// First mod found in the archive — used for display.
  final ModInfo modInfo;
  final int fileCount;
  final int? estimatedSizeBytes;

  /// Already-installed version of this mod, if any.
  final ModVariant? existingVariant;
  final bool hasMultipleMods;

  /// All parsed mods found in the archive (always populated; length 1 for a
  /// single-mod archive).
  final List<ExtractedModInfo> allModInfos;

  /// The file listing from the archive (needed later for extraction).
  final List<String>? archiveFileList;

  const ScannedArchive({
    required this.modInfo,
    required this.fileCount,
    this.estimatedSizeBytes,
    this.existingVariant,
    this.hasMultipleMods = false,
    this.allModInfos = const [],
    this.archiveFileList,
  });
}

/// A single entry in a batch installation (one archive).
class BatchEntry {
  final String id;
  final File archiveFile;
  BatchEntryStatus status;
  ScannedArchive? scanResult;
  (int, int)? extractionProgress;
  String? extractionPhase;
  Object? error;
  String? errorDetail;

  /// The install source (archive or directory). Created during scan.
  ModInstallSource? installSource;

  /// Mods within this archive the user chose to install. Set after the
  /// confirmation dialog, or defaulted to all scanned mods when no dialog
  /// is shown (single clean archive).
  List<ExtractedModInfo>? selectedMods;

  /// Name of the mod currently being extracted (for multi-mod archives).
  String? currentModName;

  /// Mods successfully installed from this archive.
  final List<ModInfo> installedMods = [];

  BatchEntry({
    required this.id,
    required this.archiveFile,
    this.status = BatchEntryStatus.queued,
    this.scanResult,
    this.extractionProgress,
    this.error,
    this.errorDetail,
    this.installSource,
    this.selectedMods,
  });

  /// Display name: current mod being extracted, mod name from scan result, or
  /// archive filename as fallback.
  String get displayName =>
      currentModName ??
      scanResult?.modInfo.nameOrId ??
      archiveFile.uri.pathSegments.last;

  /// Whether this mod is already installed.
  bool get hasConflict => scanResult?.existingVariant != null;
}

/// A batch of mod archives being installed together.
class BatchInstallation {
  final String id;
  final List<BatchEntry> entries;
  BatchStatus status;

  BatchInstallation({
    required this.id,
    required this.entries,
    this.status = BatchStatus.pending,
  });

  /// Number of entries that have finished (done, failed, or skipped).
  int get completedCount => entries
      .where(
        (e) =>
            e.status == BatchEntryStatus.done ||
            e.status == BatchEntryStatus.failed ||
            e.status == BatchEntryStatus.skipped,
      )
      .length;

  /// Number of entries that can be installed (not broken from scan).
  int get installableCount => entries
      .where((e) => e.status != BatchEntryStatus.failed || e.scanResult != null)
      .length;

  /// Total entries.
  int get totalCount => entries.length;

  /// Whether every entry is done (installed, failed, or skipped).
  bool get isFinished => entries.every(
    (e) =>
        e.status == BatchEntryStatus.done ||
        e.status == BatchEntryStatus.failed ||
        e.status == BatchEntryStatus.skipped,
  );

  /// Entries that are ready to install (scanned, no problems or user chose to install).
  List<BatchEntry> get entriesToInstall =>
      entries.where((e) => e.status == BatchEntryStatus.scanned).toList();

  /// Entries that failed to scan (corrupt archive, no mod_info.json, etc.).
  List<BatchEntry> get invalidEntries => entries
      .where((e) => e.status == BatchEntryStatus.failed && e.scanResult == null)
      .toList();

  /// Entries where the mod is already installed.
  List<BatchEntry> get conflictEntries =>
      entries.where((e) => e.hasConflict).toList();
}
