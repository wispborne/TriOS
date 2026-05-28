import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/compression/archive.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation.dart';
import 'package:trios/mod_manager/batch_installation/batch_pre_scanner.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/widgets/mod_install_selection_dialog.dart';
import 'package:trios/trios/activity_panel/activity_entry.dart';
import 'package:trios/trios/activity_panel/activity_panel_controller.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/platform_specific.dart';
import 'package:uuid/uuid.dart';

/// Provider for the active batch installation (null when idle).
final batchInstallationProvider =
    NotifierProvider<BatchInstallationNotifier, BatchInstallation?>(
      BatchInstallationNotifier.new,
    );

/// Identifies one specific mod within a batch entry's archive.
class BatchModRef {
  final BatchEntry entry;
  final ExtractedModInfo modInfo;

  const BatchModRef(this.entry, this.modInfo);
}

/// Manages batch mod installation:
/// scan archives → show confirmation → extract mods → reload mod list.
class BatchInstallationNotifier extends Notifier<BatchInstallation?> {
  @override
  BatchInstallation? build() => null;

  @override
  bool updateShouldNotify(
    BatchInstallation? previous,
    BatchInstallation? next,
  ) => true;

  /// Start a batch installation from a list of local archive files.
  Future<void> create(List<File> files) async {
    if (files.isEmpty) return;

    final entries = files
        .map((f) => BatchEntry(id: const Uuid().v4(), archiveFile: f))
        .toList();

    final batch = BatchInstallation(id: const Uuid().v4(), entries: entries);

    state = batch;

    try {
      await _runPipeline(batch);
    } catch (e, st) {
      Fimber.e("Batch installation failed", ex: e, stacktrace: st);
      batch.status = BatchStatus.complete;
      _notify();
    }
  }

  /// Add a single file to an active batch (e.g. a URL that just finished
  /// downloading). If no batch is active, creates a new one.
  Future<void> addLateEntry(File file) async {
    final batch = state;
    if (batch != null && !batch.isFinished) {
      final entry = BatchEntry(id: const Uuid().v4(), archiveFile: file);
      batch.entries.add(entry);
      _notify();

      // Scan it and add to extraction queue if batch is already installing.
      final archive = ref.read(archiveProvider).requireValue;
      final existingVariants = ref.read(AppState.modVariants).value ?? [];
      final scanner = BatchPreScanner(
        archive: archive,
        existingVariants: existingVariants,
      );
      await scanner.scanArchive(entry);
      // Late entries (e.g. completed URL downloads) install all contained mods.
      entry.selectedMods = entry.scanResult?.allModInfos;
      _notify();

      // If extraction is already running, it'll pick up this new entry next.
    } else {
      // No active batch — create a batch-of-1, skip dialog.
      await create([file]);
    }
  }

  // ── Steps ──────────────────────────────────────────────────────────

  Future<void> _runPipeline(BatchInstallation batch) async {
    // Phase 1: Pre-scan.
    batch.status = BatchStatus.scanning;
    _notify();

    final archive = ref.read(archiveProvider).requireValue;
    final existingVariants = ref.read(AppState.modVariants).value ?? [];
    final scanner = BatchPreScanner(
      archive: archive,
      existingVariants: existingVariants,
    );

    await scanner.scanAll(
      batch.entries,
      concurrency: 6,
      onEntryScanned: (_) => _notify(),
    );

    // Phase 2: Confirmation dialog (if 2+ entries, or 1 with problems).
    final needsDialog =
        batch.entries.length > 1 ||
        batch.entries.any(
          (e) =>
              e.hasConflict ||
              e.status == BatchEntryStatus.failed ||
              (e.scanResult?.hasMultipleMods ?? false),
        );

    final scannedEntries = batch.entries
        .where((e) => e.status == BatchEntryStatus.scanned)
        .toList();

    if (needsDialog) {
      batch.status = BatchStatus.confirming;
      _notify();

      final context = ref.read(AppState.appContext);
      if (context == null || !context.mounted) {
        batch.status = BatchStatus.complete;
        _notify();
        return;
      }

      // Build one choice per mod across all scanned archives.
      final choices = <ModInstallChoice<BatchModRef>>[];
      final showSource =
          batch.entries.length > 1 ||
          scannedEntries.any((e) => e.scanResult!.hasMultipleMods);
      for (final entry in scannedEntries) {
        for (final mod in entry.scanResult!.allModInfos) {
          choices.add(
            ModInstallChoice<BatchModRef>(
              modInfo: mod,
              existingVariant: getModVariantForModInfo(
                mod.modInfo,
                existingVariants,
              ),
              sourceLabel: showSource
                  ? entry.archiveFile.uri.pathSegments.last
                  : null,
              tag: BatchModRef(entry, mod),
            ),
          );
        }
      }

      final invalidItems = batch.entries
          .where((e) => e.status == BatchEntryStatus.failed)
          .map(
            (e) => InvalidInstallItem(
              name: e.archiveFile.uri.pathSegments.last,
              detail: e.errorDetail,
            ),
          )
          .toList();

      final selected = await ModInstallSelectionDialog.show<BatchModRef>(
        context,
        choices: choices,
        invalidItems: invalidItems,
        gameVersion: ref.read(
          appSettings.select((s) => s.lastStarsectorVersion),
        ),
      );

      if (selected == null) {
        // User cancelled — skip everything still pending.
        for (final entry in scannedEntries) {
          entry.status = BatchEntryStatus.skipped;
        }
        batch.status = BatchStatus.complete;
        _notify();
        return;
      }

      // Group selected mods back to their entries.
      for (final entry in scannedEntries) {
        final mods = selected
            .where((ref) => identical(ref.entry, entry))
            .map((ref) => ref.modInfo)
            .toList();
        if (mods.isEmpty) {
          entry.status = BatchEntryStatus.skipped;
        } else {
          entry.selectedMods = mods;
        }
      }
    } else {
      // No dialog: install all mods found in each scanned archive
      // (the no-dialog case is a single clean single-mod archive).
      for (final entry in scannedEntries) {
        entry.selectedMods = entry.scanResult!.allModInfos;
      }
    }

    _notify();

    // Phase 3: Extraction.
    batch.status = BatchStatus.installing;
    _notify();

    final concurrency = ref
        .read(appSettings.select((s) => s.concurrentExtractions))
        .clamp(1, 6);

    await _extractAll(batch, concurrency);

    // Phase 4: Finalize.
    await _finalize(batch);

    batch.status = BatchStatus.complete;
    _notify();
  }

  Future<void> _extractAll(BatchInstallation batch, int concurrency) async {
    final modsFolder = ref.read(AppState.modsFolder).value!;
    final modManagerNotifier = ref.read(modManager.notifier);
    final folderSetting = ref.read(
      appSettings.select((s) => s.folderNamingSetting),
    );

    Fimber.i("Starting batch extraction with concurrency=$concurrency");

    List<BatchEntry> pendingEntries() => batch.entries
        .where((e) => e.status == BatchEntryStatus.scanned)
        .toList();

    final slots = <Completer<void>>[];

    void launchEntry(BatchEntry entry, Completer<void> c) {
      entry.status = BatchEntryStatus.extracting;
      _notify();
      _extractSingleEntry(
        entry,
        modsFolder,
        modManagerNotifier,
        folderSetting,
      ).whenComplete(() {
        _notify();
        c.complete();
      });
    }

    // Fill all available slots. Because launchEntry doesn't await,
    // each extraction is truly fire-and-forget so the loop isn't blocked
    // by synchronous I/O (e.g. moveToTrash) inside _extractSingleEntry.
    while (pendingEntries().isNotEmpty && slots.length < concurrency) {
      final entry = pendingEntries().first;
      final c = Completer<void>();
      slots.add(c);
      launchEntry(entry, c);
    }

    Fimber.i("Started ${slots.length} concurrent extractions");

    // As slots free up, start the next pending entry.
    while (slots.isNotEmpty) {
      await Future.any(slots.map((c) => c.future));
      slots.removeWhere((c) => c.isCompleted);

      while (pendingEntries().isNotEmpty && slots.length < concurrency) {
        final entry = pendingEntries().first;
        final c = Completer<void>();
        slots.add(c);
        launchEntry(entry, c);
      }
    }
  }

  Future<void> _extractSingleEntry(
    BatchEntry entry,
    Directory modsFolder,
    ModManagerNotifier modManagerNotifier,
    FolderNamingSetting folderSetting,
  ) async {
    // Yield so the slot-filling loop can launch all entries before any
    // synchronous I/O (e.g. moveToTrash FFI) blocks the event loop.
    await Future<void>.microtask(() {});

    final mods =
        entry.selectedMods ?? entry.scanResult?.allModInfos ?? const [];
    if (mods.isEmpty) {
      entry.status = BatchEntryStatus.skipped;
      return;
    }

    final installSource = entry.installSource!;
    final archiveFileList = entry.scanResult!.archiveFileList ?? const [];
    final currentMods = ref.read(AppState.mods);
    // Variants from before this batch; used to check for already-installed mods.
    final existingVariants = ref.read(AppState.modVariants).value ?? [];

    var anyFailed = false;
    var modsDone = 0;

    for (final mod in mods) {
      entry.currentModName = mod.modInfo.nameOrId;
      _notify();

      try {
        // If this specific mod is already installed, delete it first (replace).
        final existingVariant = getModVariantForModInfo(
          mod.modInfo,
          existingVariants,
        );
        if (existingVariant != null) {
          try {
            existingVariant.modFolder.moveToTrash(deleteIfFailed: true);
            Fimber.i(
              "Deleted existing variant folder before replacing: ${existingVariant.modFolder}",
            );
          } catch (e, st) {
            Fimber.e(
              "Failed to delete existing variant for replacement",
              ex: e,
              stacktrace: st,
            );
            anyFailed = true;
            entry
              ..error = e
              ..errorDetail = "Failed to remove existing installation: $e";
            continue;
          }
        }

        final fallbackFolderName =
            mod.extractedFile.originalFile.parent.path != "."
            ? mod.extractedFile.originalFile.parent.name
            : mod.modInfo.nameOrId.fixFilenameForFileSystem();

        final targetModFolderName = await modManagerNotifier
            .setUpNewHighestModVersionFolder(
              mod.modInfo,
              fallbackFolderName,
              folderSetting,
              currentMods,
              modsFolder,
            );

        final result = await modManagerNotifier.installMod(
          mod,
          currentMods,
          archiveFileList,
          installSource,
          modsFolder,
          targetModFolderName,
          dryRun: false,
          onProgress: (completed, total) {
            entry.extractionProgress = (completed, total);
            _notify();
          },
          onPhaseChanged: (phase) {
            entry.extractionPhase = phase;
            _notify();
          },
        );

        if (result.err != null) {
          anyFailed = true;
          entry
            ..error = result.err
            ..errorDetail = result.err.toString();
        } else {
          entry.installedMods.add(mod.modInfo);
        }
      } catch (e, st) {
        Fimber.e(
          "Error extracting ${mod.modInfo.nameOrId} from ${entry.displayName}",
          ex: e,
          stacktrace: st,
        );
        anyFailed = true;
        entry
          ..error = e
          ..errorDetail = e.toString();
      } finally {
        modsDone++;
        entry.extractionProgress = (modsDone, mods.length);
        _notify();
      }
    }

    entry
      ..currentModName = null
      ..status = anyFailed ? BatchEntryStatus.failed : BatchEntryStatus.done;
  }

  Future<void> _finalize(BatchInstallation batch) async {
    // Reload the mod list once if anything was actually installed.
    final installedCount = batch.entries
        .map((e) => e.installedMods.length)
        .fold(0, (a, b) => a + b);

    if (installedCount > 0) {
      Fimber.i(
        "Batch complete: $installedCount mods installed. Reloading mod list.",
      );
      await ref.read(AppState.modVariants.notifier).reloadModVariants();
    }

    // Save each installed mod (and each failed archive) to activity history
    // so they show up in the "Recent" section after batch tiles disappear.
    final historyStore = ref.read(activityHistoryStore.notifier);
    var recordedCount = 0;

    for (final entry in batch.entries) {
      // One completed record per successfully installed mod.
      for (final modInfo in entry.installedMods) {
        await historyStore.recordCompletion(
          ActivityEntry(
            id: const Uuid().v4(),
            modName: modInfo.nameOrId,
            modId: modInfo.id,
            modVersion: modInfo.version?.toString(),
            sourceType: ActivitySourceType.archive,
            sourceDetail: entry.archiveFile.path,
            timestamp: DateTime.now(),
            status: ActivityStatus.completed,
          ),
        );
        recordedCount++;
      }

      // One failed record per archive that errored.
      if (entry.status == BatchEntryStatus.failed) {
        await historyStore.recordCompletion(
          ActivityEntry(
            id: const Uuid().v4(),
            modName: entry.displayName,
            modId: entry.scanResult?.modInfo.id,
            modVersion: entry.scanResult?.modInfo.version?.toString(),
            sourceType: ActivitySourceType.archive,
            sourceDetail: entry.archiveFile.path,
            timestamp: DateTime.now(),
            status: ActivityStatus.failed,
            errorMessage: entry.errorDetail,
          ),
        );
        recordedCount++;
      }
    }

    // Update the unread badge if the activity panel is closed.
    final isOpen = ref.read(appSettings.select((s) => s.isActivityPanelOpen));
    if (!isOpen && recordedCount > 0) {
      for (var i = 0; i < recordedCount; i++) {
        ref.read(activityUnseenCount.notifier).increment();
      }
    }
  }

  /// Tell the UI to rebuild with updated state.
  void _notify() {
    state = state;
  }
}
