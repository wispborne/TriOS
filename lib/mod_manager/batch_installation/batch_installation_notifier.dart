import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/compression/archive.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation.dart';
import 'package:trios/mod_manager/batch_installation/batch_pre_scanner.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/widgets/mod_install_selection_dialog.dart';
import 'package:trios/mod_manager/widgets/mod_installation_error_dialog.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_record_source.dart';
import 'package:trios/mod_records/mod_records_store.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/trios/activity_panel/activity_entry.dart';
import 'package:trios/trios/activity_panel/activity_panel_controller.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
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

  /// Start a batch installation from a list of local sources (archives or folders).
  ///
  /// [skipConfirmation] suppresses the confirmation dialog and installs every
  /// scanned mod — used when the user has already confirmed the install
  /// upstream (e.g. the deep-link confirmation dialog), so we don't ask again.
  Future<void> create(
    List<FileSystemEntity> sources, {
    Download? download,
    bool skipConfirmation = false,
  }) async {
    if (sources.isEmpty) return;

    // A batch is already running — merge into it instead of replacing it,
    // which would orphan the in-flight batch and hide its UI.
    final existing = state;
    if (existing != null && !existing.isFinished) {
      for (final source in sources) {
        await addLateEntry(
          source,
          download: download,
          skipConfirmation: skipConfirmation,
        );
      }
      return;
    }

    final entries = sources
        .map(
          (s) => BatchEntry(
            id: const Uuid().v4(),
            source: s,
            download: download,
          ),
        )
        .toList();

    final batch = BatchInstallation(id: const Uuid().v4(), entries: entries);

    state = batch;

    try {
      await _runPipeline(batch, skipConfirmation: skipConfirmation);
    } catch (e, st) {
      Fimber.e("Batch installation failed", ex: e, stacktrace: st);
      batch.status = BatchStatus.complete;
      // Settle every entry the pipeline left behind so downloads (toasts)
      // and anyone awaiting [BatchEntry.settled] don't hang forever.
      for (final entry in batch.entries) {
        if (!entry.settledCompleter.isCompleted) {
          if (!entry.status.isTerminal) {
            entry.status = BatchEntryStatus.failed;
            entry.error ??= e;
            entry.errorDetail ??= e.toString();
          }
          _settleEntry(entry);
        }
      }
      _notify();
    }
  }

  /// Add a single source to an active batch (e.g. a URL that just finished
  /// downloading). If no batch is active, creates a new one.
  Future<void> addLateEntry(
    FileSystemEntity source, {
    Download? download,
    bool skipConfirmation = false,
  }) async {
    final batch = state;
    if (batch != null && !batch.isFinished) {
      final entry = BatchEntry(
        id: const Uuid().v4(),
        source: source,
        download: download,
      );
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
      if (entry.status == BatchEntryStatus.failed) {
        // Surface the scan failure on the download (toast/history) instead of
        // silently leaving the entry behind.
        Fimber.w(
          "Late entry '${entry.displayName}' failed scan: ${entry.errorDetail}",
        );
        _settleEntry(entry);
        _notify();
        return;
      }
      // Late entries (e.g. completed URL downloads) install all contained mods.
      entry.selectedMods = entry.scanResult?.allModInfos;
      _notify();

      // If _extractAll is still running, it'll pick up this scanned entry.
      // But if extraction already finished, we must handle it ourselves.
      final extractionDone = batch.status == BatchStatus.installing &&
          !batch.entries.any((e) => e.status == BatchEntryStatus.extracting);
      final batchComplete = batch.status == BatchStatus.complete;

      if ((extractionDone || batchComplete) &&
          entry.status == BatchEntryStatus.scanned) {
        final modsFolder = ref.read(AppState.modsFolder).value!;
        final modManagerNotifier = ref.read(modManager.notifier);
        final folderSetting = ref.read(
          appSettings.select((s) => s.folderNamingSetting),
        );
        entry.status = BatchEntryStatus.extracting;
        _notify();
        await _extractSingleEntry(
          entry,
          modsFolder,
          modManagerNotifier,
          folderSetting,
        );
        _notify();
        await _finalize(batch);
      } else {
        // The running pipeline will extract this entry. Don't return until it
        // has — callers (e.g. the download manager) treat our completion as
        // "the install is finished" and clean up the source archive.
        await entry.settled;
      }
    } else {
      // No active batch — create a batch-of-1, skip dialog.
      await create(
        [source],
        download: download,
        skipConfirmation: skipConfirmation,
      );
    }
  }

  // ── Steps ──────────────────────────────────────────────────────────

  Future<void> _runPipeline(
    BatchInstallation batch, {
    bool skipConfirmation = false,
  }) async {
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

    // Entries that failed the scan are terminal — settle their downloads now
    // so toasts/Activity Panel show the failure instead of spinning forever.
    for (final entry in batch.entries) {
      if (entry.status == BatchEntryStatus.failed) {
        _settleEntry(entry);
      }
    }

    // Phase 2: Confirmation dialog (if 2+ entries, or 1 with problems).
    // When the user already confirmed the install upstream (e.g. the deep-link
    // dialog), skip it entirely and install every scanned mod — same as how a
    // late entry merged into an active batch already behaves.
    final needsDialog =
        !skipConfirmation &&
        (batch.entries.length > 1 ||
            batch.entries.any(
              (e) =>
                  e.hasConflict ||
                  e.status == BatchEntryStatus.failed ||
                  (e.scanResult?.hasMultipleMods ?? false),
            ));

    final scannedEntries = batch.entries
        .where((e) => e.status == BatchEntryStatus.scanned)
        .toList();

    if (needsDialog) {
      batch.status = BatchStatus.confirming;
      _notify();

      final context = ref.read(AppState.appContext);
      if (context == null || !context.mounted) {
        for (final entry in batch.entries.where(
          (e) => e.status == BatchEntryStatus.scanned,
        )) {
          entry.status = BatchEntryStatus.skipped;
          _settleEntry(entry, cancelled: true);
        }
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
                  ? entry.source.uri.pathSegments.last
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
              name: e.source.uri.pathSegments.last,
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
        // User cancelled — skip everything still pending (including late
        // entries added after the dialog opened, so they don't hang).
        for (final entry in batch.entries.where(
          (e) => e.status == BatchEntryStatus.scanned,
        )) {
          entry.status = BatchEntryStatus.skipped;
          _settleEntry(entry, cancelled: true);
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
          // User deselected every mod in this entry — treat as cancelled.
          entry.status = BatchEntryStatus.skipped;
          _settleEntry(entry, cancelled: true);
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
      _settleEntry(entry);
      return;
    }

    final installSource = entry.installSource!;
    final archiveFileList = entry.scanResult!.archiveFileList ?? const [];
    var currentMods = ref.read(AppState.mods);
    // Variants from before this batch; used to check for already-installed mods.
    final existingVariants = ref.read(AppState.modVariants).value ?? [];

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
            entry.error ??= e;
            entry.failedMods.add((modInfo: mod.modInfo, err: e, st: st));
            continue;
          }

          // Remove the deleted variant from currentMods so installMod
          // doesn't see a stale enabled variant and brick the new one.
          currentMods = currentMods.map((m) {
            if (m.id != mod.modInfo.id) return m;
            return m.copyWith(
              modVariants: m.modVariants
                  .where((v) => v.smolId != existingVariant.smolId)
                  .toList(),
            );
          }).toList();
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
            entry.download?.installProgress.value = TriOSDownloadProgress(
              completed,
              total,
              customStatus: "$completed / $total files",
            );
            _notify();
          },
          onPhaseChanged: (phase) {
            entry.extractionPhase = phase;
            _notify();
          },
        );

        if (result.err != null) {
          entry.error ??= result.err;
          entry.failedMods.add((
            modInfo: mod.modInfo,
            err: result.err!,
            st: result.st,
          ));
        } else {
          entry.installedMods.add(mod.modInfo);
          entry.installedFolders.add(
            modsFolder.resolve(targetModFolderName).toDirectory(),
          );
        }
      } catch (e, st) {
        Fimber.e(
          "Error extracting ${mod.modInfo.nameOrId} from ${entry.displayName}",
          ex: e,
          stacktrace: st,
        );
        entry.error ??= e;
        entry.failedMods.add((modInfo: mod.modInfo, err: e, st: st));
      } finally {
        modsDone++;
        entry.extractionProgress = (modsDone, mods.length);
        _notify();
      }
    }

    entry
      ..currentModName = null
      ..errorDetail = entry.failedMods.isNotEmpty
          ? entry.failedMods
              .map((f) => "${f.modInfo.nameOrId}: ${f.err}")
              .join('\n')
          : null
      ..status = entry.failedMods.isNotEmpty
          ? BatchEntryStatus.failed
          : BatchEntryStatus.done;

    // Drive the Download notification immediately after extraction.
    if (entry.download != null && entry.installedMods.isNotEmpty) {
      entry.download!.installProgress.value = TriOSDownloadProgress(
        0,
        0,
        isIndeterminate: true,
        customStatus: "Finalizing...",
      );
      // Only reload the folders this entry installed into — a full rescan per
      // entry races concurrent extractions and is wasted work.
      await ref
          .read(AppState.modVariants.notifier)
          .reloadModVariantsFromFolders(onlyFolders: entry.installedFolders);
      final refreshedVariants = ref.read(AppState.modVariants).value ?? [];
      final installedSmolId = entry.installedMods.first.smolId;
      final variant = refreshedVariants.firstWhereOrNull(
        (v) => v.smolId == installedSmolId,
      );
      if (variant != null) {
        entry.download!.installedVariant.value = variant;
      }
    }
    _settleEntry(entry);
  }

  /// Settles an entry that has reached a terminal status: surfaces a failure
  /// on its [Download] (if any), marks the download finished so the toast and
  /// Activity Panel resolve, and completes [BatchEntry.settled].
  /// Safe to call more than once.
  void _settleEntry(BatchEntry entry, {bool cancelled = false}) {
    final download = entry.download;
    if (download != null) {
      if (entry.status == BatchEntryStatus.failed) {
        download.task.error ??=
            entry.error ?? Exception(entry.errorDetail ?? "Install failed");
      }
      if (cancelled) {
        ref.read(downloadManager.notifier).cancelInstallation(download);
      } else if (!download.installComplete.value) {
        download.installComplete.value = true;
      }
    }
    if (!entry.settledCompleter.isCompleted) {
      entry.settledCompleter.complete();
    }
  }

  Future<void> _finalize(BatchInstallation batch) async {
    // Only process entries whose history hasn't been recorded yet.
    final unrecorded = batch.entries.where((e) => !e.historyRecorded).toList();
    if (unrecorded.isEmpty) return;

    // Reload the mod list once if anything new was actually installed,
    // but skip entries that already did their own reload (Download-bearing).
    final entriesNeedingReload = unrecorded.where(
      (e) => e.download == null && e.installedMods.isNotEmpty,
    );
    final newInstalls = entriesNeedingReload
        .map((e) => e.installedMods.length)
        .fold(0, (a, b) => a + b);

    if (newInstalls > 0) {
      Fimber.i(
        "Batch finalize: $newInstalls new mods installed. Reloading mod list.",
      );
      await ref.read(AppState.modVariants.notifier).reloadModVariants();
    }

    // Activate newly installed variants when the mod was already enabled.
    final allInstalledModInfos =
        unrecorded.expand((e) => e.installedMods).toList();
    if (allInstalledModInfos.isNotEmpty &&
        ref.read(appSettings.select((s) => s.modUpdateBehavior)) ==
            ModUpdateBehavior.switchToNewVersionIfWasEnabled) {
      final mods = ref.read(AppState.mods);
      final refreshedVariants = ref.read(AppState.modVariants).value ?? [];
      final modManagerNotifier = ref.read(modManager.notifier);
      var anyActivated = false;

      for (final modInfo in allInstalledModInfos) {
        final actualVariant = refreshedVariants.firstWhereOrNull(
          (variant) => variant.smolId == modInfo.smolId,
        );
        try {
          if (actualVariant != null &&
              actualVariant.mod(mods)?.isEnabledInGame == true) {
            await modManagerNotifier.changeActiveModVariant(
              actualVariant.mod(mods)!,
              actualVariant,
            );
            anyActivated = true;
          }
        } catch (ex) {
          Fimber.w(
            "Batch finalize: failed to activate ${modInfo.smolId} after installing: $ex",
          );
        }
      }

      if (anyActivated) {
        // Reload again after activation changes.
        await ref.read(AppState.modVariants.notifier).reloadModVariants();
      }
    }

    // Write mod records (InstalledSource + catalog merge) for all installed mods.
    final refreshedVariants = ref.read(AppState.modVariants).value ?? [];
    try {
      final store = ref.read(modRecordsStore.notifier);
      for (final entry in unrecorded) {
        for (final modInfo in entry.installedMods) {
          final modId = modInfo.id;
          final now = DateTime.now();

          final syntheticKey = ModRecord.syntheticKey(modInfo.nameOrId);
          if (store.lookupByModId(modId) == null &&
              store.state.valueOrNull?.records.containsKey(syntheticKey) ==
                  true) {
            await store.mergeSyntheticIntoReal(syntheticKey, modId);
          }

          final variant = refreshedVariants.firstWhereOrNull(
            (v) => v.smolId == modInfo.smolId,
          );
          await store.updateRecord(modId, (existing) {
            final base = existing ??
                ModRecord(recordKey: modId, modId: modId, firstSeen: now);
            final updatedSources = Map<String, ModRecordSource>.of(
              base.sources,
            );
            updatedSources['installed'] = InstalledSource(
              name: modInfo.name,
              author: modInfo.author,
              installPath: variant?.modFolder.path,
              version: modInfo.version?.toString(),
              lastSeen: now,
            );
            return base.copyWith(modId: modId, sources: updatedSources);
          });
        }
      }
    } catch (e) {
      Fimber.w("Failed to update mod records on batch install: $e");
    }

    // Record activity history — skip Download-bearing entries (ToastDisplayer
    // records those).
    final historyStore = ref.read(activityHistoryStore.notifier);
    var recordedCount = 0;

    for (final entry in unrecorded) {
      if (!entry.status.isTerminal) continue;

      // Download-bearing entries have their history recorded by ToastDisplayer.
      if (entry.download != null) {
        entry.historyRecorded = true;
        continue;
      }

      for (final modInfo in entry.installedMods) {
        await historyStore.recordCompletion(
          ActivityEntry(
            id: const Uuid().v4(),
            modName: modInfo.nameOrId,
            modId: modInfo.id,
            modVersion: modInfo.version?.toString(),
            sourceType: ActivitySourceType.archive,
            sourceDetail: entry.source.path,
            timestamp: DateTime.now(),
            status: ActivityStatus.completed,
          ),
        );
        recordedCount++;
      }

      if (entry.status == BatchEntryStatus.failed) {
        await historyStore.recordCompletion(
          ActivityEntry(
            id: const Uuid().v4(),
            modName: entry.displayName,
            modId: entry.scanResult?.modInfo.id,
            modVersion: entry.scanResult?.modInfo.version?.toString(),
            sourceType: ActivitySourceType.archive,
            sourceDetail: entry.source.path,
            timestamp: DateTime.now(),
            status: ActivityStatus.failed,
            errorMessage: entry.errorDetail,
          ),
        );
        recordedCount++;
      }

      entry.historyRecorded = true;
    }

    final isOpen = ref.read(appSettings.select((s) => s.isActivityPanelOpen));
    if (!isOpen && recordedCount > 0) {
      for (var i = 0; i < recordedCount; i++) {
        ref.read(activityUnseenCount.notifier).increment();
      }
    }

    // Show error dialog for failed entries, blaming only the mods that
    // actually failed (not every mod in the archive).
    final failedWithErrors = unrecorded
        .where(
          (e) =>
              e.status == BatchEntryStatus.failed && e.failedMods.isNotEmpty,
        )
        .toList();
    if (failedWithErrors.isNotEmpty) {
      final context = ref.read(AppState.appContext);
      final destinationFolder = ref.read(AppState.modsFolder).value;
      if (context != null && context.mounted && destinationFolder != null) {
        final errorResults = failedWithErrors
            .expand<InstallModResult>(
              (e) => e.failedMods.map((failure) {
                final err = failure.err;
                return (
                  sourceFileEntity: File(e.source.path),
                  destinationFolder: destinationFolder,
                  modInfo: failure.modInfo,
                  err: err is Exception ? err : Exception(err.toString()),
                  st: failure.st,
                );
              }),
            )
            .toList();
        if (errorResults.isNotEmpty) {
          await ModInstallationErrorDialog.show(context, errorResults);
        }
      }
    }
  }

  /// Tell the UI to rebuild with updated state.
  void _notify() {
    state = state;
  }
}
