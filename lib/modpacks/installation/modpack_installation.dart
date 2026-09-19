import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/compression/archive.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation_notifier.dart';
import 'package:trios/mod_manager/batch_installation/batch_pre_scanner.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/modpacks/full_page/modpack_item_row_data.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/modpacks/modpack_error_text.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:trios/modpacks/sharing/modpack_source_validator.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/downloader.dart';
import 'package:trios/trios/download_manager/shared_download.dart';
import 'package:trios/utils/fair_work_queue.dart';
import 'package:trios/utils/http_probe.dart';
import 'package:trios/utils/logging.dart';

class ModpackInstallChoice {
  final ModpackItemRowData row;
  final String? downloadUrl;
  final String? error;
  final DownloadSourceHint? recoverySource;
  const ModpackInstallChoice(
    this.row, {
    this.downloadUrl,
    this.error,
    this.recoverySource,
  });
  bool get installable => downloadUrl != null && error == null;
}

class ModpackInstallPlan {
  final ModpackLibraryEntry entry;
  final List<ModpackInstallChoice> items;
  ModpackInstallPlan(this.entry, List<ModpackInstallChoice> items)
    : items = List.unmodifiable(items);
  Set<String> get defaultSelection => {
    for (final choice in items)
      if (choice.installable && !choice.row.isInstalled) choice.row.key,
  };
}

enum ModpackItemInstallStatus {
  queued,
  downloading,
  inspecting,
  installing,
  installed,
  failed,
  skipped,
}

class ModpackItemInstallResult {
  final ModpackItemInstallStatus status;
  final String? detail;
  final double? fraction;
  const ModpackItemInstallResult(this.status, {this.detail, this.fraction});
  bool get finished => {
    ModpackItemInstallStatus.installed,
    ModpackItemInstallStatus.failed,
    ModpackItemInstallStatus.skipped,
  }.contains(status);
  String get text =>
      detail ??
      switch (status) {
        .queued => 'Waiting',
        .downloading => 'Downloading',
        .inspecting => 'Reading archive',
        .installing => 'Installing',
        .installed => 'Installed',
        .failed => 'Failed',
        .skipped => 'Skipped',
      };
}

class ModpackInstallRun {
  final ModpackInstallPlan plan;
  final bool enableAfterInstallation;
  final Map<String, ModpackItemInstallResult> results;
  final _settled = Completer<void>();
  final _archives = <SharedDownload>[];
  bool stopping = false;
  bool complete = false;
  String? error;
  ModpackInstallRun(
    this.plan,
    Set<String> selected,
    this.enableAfterInstallation,
  ) : results = {
        for (final id in selected) id: const ModpackItemInstallResult(.queued),
      };
  String get packId => plan.entry.definition.id;
  int get finishedCount => results.values.where((r) => r.finished).length;
  Future<void> get settled => _settled.future;
}

final modpackInstallationProvider =
    NotifierProvider<
      ModpackInstallationManager,
      Map<String, ModpackInstallRun>
    >(ModpackInstallationManager.new);

/// Owns attempts independently of any widget. Only library definitions enter
/// preparation; selection is fixed before starting downloads.
class ModpackInstallationManager
    extends Notifier<Map<String, ModpackInstallRun>> {
  final _downloads = FairWorkQueue(() => 2);
  @override
  Map<String, ModpackInstallRun> build() => {};

  /// Throws [ModpackInstallBlocked] when mods can't be installed right now.
  void checkCanInstall() {
    if (ref.read(AppState.isGameRunning).value == true) {
      throw const ModpackInstallBlocked(
        'Close Starsector before installing mods.',
      );
    }
    if (ref.read(AppState.modsFolder).value == null) {
      throw const ModpackInstallBlocked(
        'Choose your Starsector mods folder first.',
      );
    }
    if (ref.read(AppState.canWriteToModsFolder).value != true) {
      throw const ModpackInstallBlocked(
        'TriOS cannot write to the mods folder.',
      );
    }
  }

  void checkSaved(ModpackLibraryEntry entry) {
    final saved = ref
        .read(modpackStoreProvider)
        .value
        ?.packs[entry.definition.id];
    if (saved == null ||
        !modpackDefinitionsAreIdentical(saved.definition, entry.definition)) {
      throw StateError(
        'The saved pack changed. Open Install again to prepare it.',
      );
    }
  }

  Future<ModpackInstallPlan> prepare(ModpackLibraryEntry entry) async {
    checkSaved(entry);
    final rows = buildModpackItemRows(
      entry.definition,
      ref.read(AppState.mods),
      ref.read(AppState.modCompatibility),
    );
    final queue = FairWorkQueue(() => 6);
    final choices = await Future.wait(
      rows.map(
        (row) => queue.run(entry.definition.id, () async {
          try {
            return ModpackInstallChoice(
              row,
              downloadUrl: await resolveSource(row.item),
            );
          } catch (error) {
            return ModpackInstallChoice(row, error: modpackErrorText(error));
          }
        }),
      ),
    );
    return ModpackInstallPlan(entry, choices);
  }

  Future<String> resolveSource(ModpackItem item) => ref
      .read(modpackSourceValidatorProvider)
      .resolve(item, HttpProbeCancellation());

  /// Returns the existing run instead of starting a duplicate, including when
  /// two confirmation dialogs race to start the same pack.
  ModpackInstallRun start(
    ModpackInstallPlan plan,
    Set<String> selected, {
    bool enableAfterInstallation = false,
  }) {
    final id = plan.entry.definition.id;
    final current = state[id];
    if (current != null && !current.complete) return current;
    checkSaved(plan.entry);
    checkCanInstall();
    final allowed = plan.items
        .where((c) => c.installable)
        .map((c) => c.row.key)
        .toSet();
    if (!allowed.containsAll(selected)) {
      throw ArgumentError('Selection contains unavailable items.');
    }
    final run = ModpackInstallRun(plan, selected, enableAfterInstallation);
    state = {...state, id: run};
    unawaited(_execute(run));
    return run;
  }

  void stop(String id) {
    final run = state[id];
    if (run == null || run.complete) return;
    run.stopping = true;
    _changed(run);
  }

  void _changed(ModpackInstallRun run) {
    if (ref.mounted) state = {...state, run.packId: run};
  }

  void _report(
    ModpackInstallRun run,
    String id,
    ModpackItemInstallResult result,
  ) {
    run.results[id] = result;
    _changed(run);
  }

  Future<void> _execute(ModpackInstallRun run) async {
    try {
      await Future.wait([
        for (final choice in run.plan.items)
          if (run.results.containsKey(choice.row.key)) _install(run, choice),
      ]);
      if (!run.stopping && run.enableAfterInstallation) {
        await enableInstalled(run.plan.entry.definition);
      }
    } catch (error) {
      run.error = modpackErrorText(error);
    } finally {
      // Keep shared archives through the whole attempt so later selected IDs
      // in a large pack reuse the same transfer and inspection as early ones.
      for (final archive in run._archives) {
        try {
          await archive.release();
        } catch (error) {
          Fimber.w('Could not remove temporary modpack archive: $error');
        }
      }
      run._archives.clear();
      run.complete = true;
      _changed(run);
      if (run.stopping && ref.mounted) {
        state = {...state}..remove(run.packId);
      }
      run._settled.complete();
    }
  }

  Future<void> _install(
    ModpackInstallRun run,
    ModpackInstallChoice choice,
  ) async {
    final id = choice.row.key;
    ModpackItemInstallResult result;
    try {
      result = await installItem(
        run,
        choice,
        (result) => _report(run, id, result),
      );
    } catch (error) {
      // A real failure of active work remains a failure even if Stop was
      // pressed while it ran. Work never started returns skipped instead.
      result =
          _skippedWhileBlocked(error) ??
          ModpackItemInstallResult(.failed, detail: modpackErrorText(error));
    }
    _report(run, id, result);
    try {
      if (result.status == .installed) {
        await clearFailure(run.packId, id);
      } else if (result.status == .failed) {
        await recordFailure(run.packId, choice.row.item, result.text);
      }
    } catch (storageError) {
      // A storage failure cannot undo or misreport a successful installation.
      run.error = 'Could not save installation result: $storageError';
      _changed(run);
    }
  }

  /// An item that failed because the game was opened or the mods folder
  /// became unwritable mid-run was never really attempted, so it is skipped
  /// rather than saved as a failure of its source.
  ModpackItemInstallResult? _skippedWhileBlocked(Object error) {
    if (error is ModpackInstallBlocked) {
      return ModpackItemInstallResult(.skipped, detail: error.message);
    }
    try {
      checkCanInstall();
      return null;
    } on ModpackInstallBlocked catch (blocked) {
      return ModpackItemInstallResult(.skipped, detail: blocked.message);
    }
  }

  Future<ModpackItemInstallResult> installItem(
    ModpackInstallRun run,
    ModpackInstallChoice choice,
    void Function(ModpackItemInstallResult) report,
  ) async {
    SharedDownload? shared;
    Download? activity;
    void transferProgress() {
      final amount = shared!.task.downloaded.value;
      report(
        ModpackItemInstallResult(
          .downloading,
          fraction: amount.totalBytes > 0 ? amount.progressRatio : null,
        ),
      );
    }

    void installProgress() {
      report(
        ModpackItemInstallResult(
          .installing,
          detail: activity!.installProgress.value?.customStatus,
        ),
      );
    }

    try {
      final scanned = await _downloads.run<BatchEntry?>(run.packId, () async {
        if (run.stopping) return null;
        checkCanInstall();
        report(const ModpackItemInstallResult(.downloading));
        shared = await ref
            .read(downloadManagerInstance)
            .acquireShared(choice.downloadUrl!);
        run._archives.add(shared!);
        activity = ref
            .read(downloadManager.notifier)
            .observeSharedDownload(
              choice.row.displayName,
              shared!.task,
              sourceHint: choice.recoverySource,
              onCancel: () => stop(run.packId),
            );
        shared!.task.downloaded.addListener(transferProgress);
        await shared!.completed;
        if (run.stopping) return null;
        report(const ModpackItemInstallResult(.inspecting));
        return shared!.inspect(
          BatchPreScanner(
            archive: await ref.read(archiveProvider.future),
            existingVariants: ref.read(AppState.modVariants).value ?? [],
          ),
        );
      });
      if (scanned == null || run.stopping) {
        if (activity != null) activity!.installCancelled.value = true;
        return const ModpackItemInstallResult(.skipped);
      }
      final found = scanned.scanResult!.allModInfos
          .map((m) => m.modInfo.id)
          .toSet();
      if (!found.contains(choice.row.key)) {
        throw StateError(
          'Archive does not contain declared mod ID ${choice.row.key}. Found: ${found.join(', ')}.',
        );
      }
      final extras = found.difference(run.results.keys.toSet());
      final entry = BatchEntry(
        id: '${run.packId}:${choice.row.key}',
        source: scanned.source,
        scanResult: scanned.scanResult,
        installSource: scanned.installSource,
        download: activity,
      );
      activity!.installProgress.addListener(installProgress);
      final result = await ref
          .read(batchInstallationProvider.notifier)
          .installSelectedArchive(
            entry,
            selectedIds: {choice.row.key},
            owner: run.packId,
            stopped: () => run.stopping,
          );
      if (result.status == BatchEntryStatus.skipped) {
        return const ModpackItemInstallResult(.skipped);
      }
      if (result.status == BatchEntryStatus.failed) {
        throw result.error ?? StateError('Installation failed.');
      }
      return ModpackItemInstallResult(
        .installed,
        detail: extras.isEmpty
            ? null
            : 'Installed; ignored extra mods: ${extras.join(', ')}',
      );
    } catch (error) {
      if (activity != null) activity!.task.error = error;
      rethrow;
    } finally {
      shared?.task.downloaded.removeListener(transferProgress);
      activity?.installProgress.removeListener(installProgress);
      if (activity != null) activity!.installComplete.value = true;
    }
  }

  Future<void> clearFailure(String packId, String id) =>
      ref.read(modpackStoreProvider.notifier).clearItemFailure(packId, id);
  Future<void> recordFailure(String packId, ModpackItem item, String error) =>
      ref
          .read(modpackStoreProvider.notifier)
          .recordItemFailure(
            packId: packId,
            modId: item.modId,
            sourceFingerprint: modpackItemSourceFingerprint(item),
            message: error,
          );

  Future<void> enableInstalled(ModpackDefinition definition) async {
    checkCanInstall();
    final ids = definition.items.map((i) => i.modId).toSet();
    await ref
        .read(modManager.notifier)
        .enableMultiple(
          ref.read(AppState.mods).where((mod) => ids.contains(mod.id)).toList(),
        );
  }
}
