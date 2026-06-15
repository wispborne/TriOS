import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:trios/compression/archive.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation.dart';
import 'package:trios/mod_manager/mod_install_source.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

/// Scans archive files to extract mod metadata without doing a full
/// installation. Used by the batch installer to build a summary before
/// the user commits to extracting everything.
class BatchPreScanner {
  final ArchiveInterface archive;
  final List<ModVariant> existingVariants;

  BatchPreScanner({required this.archive, required this.existingVariants});

  /// Scan a single source (archive or folder). Mutates [entry] in place:
  /// populates [scanResult] on success, or sets [status] to failed with details.
  Future<void> scanArchive(BatchEntry entry) async {
    try {
      entry.status = BatchEntryStatus.scanning;

      final source = entry.source;

      if (!source.existsSync()) {
        entry
          ..status = BatchEntryStatus.failed
          ..errorDetail = "Source does not exist";
        return;
      }

      final ModInstallSource installSource;
      final List<String> filePaths;

      if (source is Directory) {
        // Folder source — use DirectoryModInstallSource.
        installSource = DirectoryModInstallSource(source);
        filePaths = await installSource.listFilePaths(archive);
      } else {
        final file = source as File;
        // Verify it looks like a supported archive.
        if (!Constants.supportedArchiveExtensions.any(
          (ext) => file.path.toLowerCase().endsWith(ext),
        )) {
          entry
            ..status = BatchEntryStatus.failed
            ..errorDetail = "Not a supported archive format";
          return;
        }

        installSource = ArchiveModInstallSource(file);
        final archiveEntries = await archive.listFiles(file);
        filePaths = archiveEntries.map((e) => e.path).toList();
      }

      // Find mod_info.json files.
      final modInfoPaths = filePaths
          .where(
            (path) =>
                path.containsIgnoreCase(Constants.modInfoFileName) &&
                !path.toFile().nameWithExtension.let(
                  (name) => name.startsWith(".") || name.startsWith("_"),
                ),
          )
          .toList();

      if (modInfoPaths.isEmpty) {
        entry
          ..status = BatchEntryStatus.failed
          ..errorDetail = "No mod_info.json found in source";
        return;
      }

      // Extract/read the mod_info.json file(s) for parsing.
      final extractedModInfoFiles = await installSource.getActualFiles(
        modInfoPaths,
        archive,
      );

      // Parse each mod_info.json.
      final List<ExtractedModInfo> parsedModInfos = [];
      for (final sourcedFile in extractedModInfoFiles) {
        try {
          final jsonString = await sourcedFile.extractedFile
              .readAsStringAllowMalformed();
          final modInfo = ModInfoMapper.fromMap(jsonString.parseJsonToMap());
          parsedModInfos.add((extractedFile: sourcedFile, modInfo: modInfo));
        } catch (e) {
          Fimber.w("Failed to parse mod_info.json from ${source.path}: $e");
        }
      }

      if (parsedModInfos.isEmpty) {
        entry
          ..status = BatchEntryStatus.failed
          ..errorDetail = "Could not parse any mod_info.json in source";
        return;
      }

      // Use the first mod as the primary (for display/summary).
      final primaryModInfo = parsedModInfos.first.modInfo;
      final hasMultiple = parsedModInfos.length > 1;

      // Check if the primary mod is already installed.
      final existingVariant = existingVariants.firstWhereOrNull(
        (v) => v.smolId == primaryModInfo.smolId,
      );

      entry
        ..status = BatchEntryStatus.scanned
        ..installSource = installSource
        ..scanResult = ScannedArchive(
          modInfo: primaryModInfo,
          fileCount: filePaths.length,
          existingVariant: existingVariant,
          hasMultipleMods: hasMultiple,
          allModInfos: parsedModInfos,
          archiveFileList: filePaths,
        );
    } catch (e, st) {
      Fimber.e(
        "Error scanning source ${entry.source.path}",
        ex: e,
        stacktrace: st,
      );
      entry
        ..status = BatchEntryStatus.failed
        ..error = e
        ..errorDetail = e.toString();
    }
  }

  /// Scan all entries, up to [concurrency] at a time.
  /// Mutates each entry in place (sets [scanResult], [status], etc.).
  /// Calls [onEntryScanned] after each entry finishes scanning.
  Future<void> scanAll(
    List<BatchEntry> entries, {
    int concurrency = 6,
    void Function(BatchEntry scanned)? onEntryScanned,
  }) async {
    // Run up to [concurrency] scans at a time; start the next as each finishes.
    final completers = <int, Completer<void>>{};
    final queue = List<BatchEntry>.of(entries);
    var slotId = 0;

    while (queue.isNotEmpty || completers.isNotEmpty) {
      // Fill idle slots.
      while (queue.isNotEmpty && completers.length < concurrency) {
        final entry = queue.removeAt(0);
        final id = slotId++;
        final c = Completer<void>();
        completers[id] = c;

        scanArchive(entry).whenComplete(() {
          onEntryScanned?.call(entry);
          c.complete();
        });
      }

      if (completers.isNotEmpty) {
        // Wait for at least one scan to finish.
        await Future.any(completers.values.map((c) => c.future));
        completers.removeWhere((_, c) => c.isCompleted);
      }
    }
  }
}
