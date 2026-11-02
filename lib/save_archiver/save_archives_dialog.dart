import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/save_archiver/archive_folder_mover.dart';
import 'package:trios/save_archiver/archived_save_store.dart';
import 'package:trios/save_archiver/bulk_save_selection_dialog.dart';
import 'package:trios/save_archiver/save_archive_manager.dart';
import 'package:trios/save_archiver/save_archive_runner_dialog.dart';
import 'package:trios/save_archiver/save_archive_selection.dart';
import 'package:trios/save_archiver/save_archiver.dart';
import 'package:trios/save_archiver/size_stat.dart';
import 'package:trios/themes/theme.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/snackbar.dart';

Future<void> showSaveArchivesDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => const SaveArchivesDialog(),
);

Future<void> archiveOneSaveWithConfirmation(
  BuildContext context,
  WidgetRef ref,
  SaveFile save,
) async {
  final blocked = saveArchivingBlockedReason(ref);
  if (blocked != null) {
    showSnackBar(
      context: context,
      type: SnackBarType.warn,
      content: Text(blocked),
    );
    return;
  }

  final archiveFolder = ref.read(saveArchiveFolderProvider);
  final archiveRatio = _estimatedArchiveRatio(
    ref.read(archivedSavesProvider).value ?? [],
  );
  final folderSize = _folderSize(save.folder);
  final portrait = _portraitFile(ref, save.portraitPath);
  var openBulkArchive = false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final mutedColor = theme.textTheme.labelSmall?.color?.withAlpha(180);

      return AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            const Text('Archive this save?'),
            Text(
              'TriOS will compress the save into a .7z file and move it to the archive '
              'folder.\nThe original save folder is deleted. '
              'You can restore the save from Archived Saves.',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.textTheme.labelMedium?.color?.withAlpha(180),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Row(
                children: [
                  FutureBuilder<File?>(
                    future: portrait,
                    builder: (context, snapshot) {
                      final file = snapshot.data;
                      if (file == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const .only(right: 8),
                        child: Image.file(
                          file,
                          width: 48,
                          height: 48,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _saveTitle(save),
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${save.folder.name} · ${_saveSubtitle(save)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              FutureBuilder<int>(
                future: folderSize,
                builder: (context, snapshot) {
                  final size = snapshot.data;
                  final estimate = size == null
                      ? null
                      : (size * archiveRatio.ratio).round();
                  return Row(
                    spacing: 32,
                    children: [
                      SizeStat(
                        label: 'Save size',
                        value: size?.bytesAsReadable() ?? '…',
                      ),
                      MovingTooltipWidget.text(
                        message: _estimateTooltip(archiveRatio),
                        child: Row(
                          spacing: 32,
                          children: [
                            SizeStat(
                              label: 'Archive size (estimate)',
                              value: estimate == null
                                  ? '…'
                                  : '~${estimate.bytesAsReadable()}',
                            ),
                            SizeStat(
                              label: 'Space saved (estimate)',
                              value: size == null || estimate == null
                                  ? '…'
                                  : '~${(size - estimate).bytesAsReadable()}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              Padding(
                padding: const .only(top: 8),
                child: Align(
                  alignment: .centerRight,
                  child: MovingTooltipWidget.text(
                    message: 'Choose several saves to archive at once',
                    child: OutlinedButton.icon(
                      onPressed: () {
                        openBulkArchive = true;
                        Navigator.of(context).pop(false);
                      },
                      style: OutlinedButton.styleFrom(
                        textStyle: theme.textTheme.labelSmall,
                        side: BorderSide(color: theme.colorScheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: .circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.lightbulb_outline, size: 16),
                      label: const Text('Hint: you can bulk-archive saves.'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: .spaceBetween,
        actions: [
          MovingTooltipWidget.text(
            message:
                archiveFolder?.path ?? 'Set the game folder in Settings first.',
            child: Disable(
              isEnabled: archiveFolder != null,
              child: TextButton.icon(
                onPressed: () async {
                  final folder = archiveFolder;
                  if (folder == null) return;
                  await _openFolder(folder);
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Open archive folder'),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton.icon(
                autofocus: true,
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.archive),
                label: const Text('Archive'),
              ),
            ],
          ),
        ],
      );
    },
  );

  if (openBulkArchive && context.mounted) {
    await showBulkArchiveSavesDialog(context, ref);
    return;
  }
  if (confirmed != true || !context.mounted) return;

  await _runArchiveJobs(context, ref, [save]);
}

Future<void> showBulkArchiveSavesDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final blocked = saveArchivingBlockedReason(ref);
  if (blocked != null) {
    showSnackBar(
      context: context,
      type: SnackBarType.warn,
      content: Text(blocked),
    );
    return;
  }

  final saves = savesNewestFirst(ref.read(saveFileProvider).value ?? []);
  if (saves.isEmpty) {
    showSnackBar(
      context: context,
      type: SnackBarType.info,
      content: const Text('There are no saves to archive.'),
    );
    return;
  }

  final sizes = <String, int>{};
  for (final save in saves) {
    sizes[save.id] = await _folderSize(save.folder);
  }
  if (!context.mounted) return;

  final archiveRatio = _estimatedArchiveRatio(
    ref.read(archivedSavesProvider).value ?? [],
  );
  int savingsFor(int size) => size - (size * archiveRatio.ratio).round();

  final picked = await showBulkSaveSelectionDialog(
    context: context,
    title: 'Archive saves',
    explanation: 'Choose which saves to archive.',
    items: [
      for (final save in saves)
        SaveSelectionItem(
          id: save.id,
          title: _saveTitle(save),
          subtitle: '${save.folder.name} · ${_saveSubtitle(save)}',
          sizeInBytes: sizes[save.id] ?? 0,
          estimatedSavingsInBytes: savingsFor(sizes[save.id] ?? 0),
        ),
    ],
    initiallySelected: savesToArchiveByDefault(
      saves,
      now: DateTime.now(),
    ).map((save) => save.id).toSet(),
    confirmLabel: (count) => 'Archive $count save${count == 1 ? '' : 's'}',
    confirmIcon: Icons.archive,
    estimateTooltip: _estimateTooltip(archiveRatio),
  );

  if (picked == null || picked.ids.isEmpty || !context.mounted) return;

  await _runArchiveJobs(
    context,
    ref,
    saves.where((save) => picked.ids.contains(save.id)).toList(),
  );
}

Future<void> showBulkRestoreSavesDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final blocked = saveArchivingBlockedReason(ref);
  if (blocked != null) {
    showSnackBar(
      context: context,
      type: SnackBarType.warn,
      content: Text(blocked),
    );
    return;
  }

  final archives = archivesNewestFirst(
    ref.read(archivedSavesProvider).value ?? [],
  );
  if (archives.isEmpty) {
    showSnackBar(
      context: context,
      type: SnackBarType.info,
      content: const Text('There are no archived saves.'),
    );
    return;
  }

  final liveSaveNames = (ref.read(saveFileProvider).value ?? [])
      .map((save) => save.folder.name.toLowerCase())
      .toSet();

  final picked = await showBulkSaveSelectionDialog(
    context: context,
    title: 'Restore saves',
    explanation: 'Choose which saves to restore.',
    items: [
      for (final archive in archives)
        SaveSelectionItem(
          id: archive.archiveFile.path,
          title: archive.displayName,
          subtitle: _archiveSubtitle(archive),
          sizeInBytes: archive.sizeOnDiskInBytes,
          restoredSizeInBytes: switch (archive.info?.originalSizeInBytes) {
            final size? when size > 0 => size,
            _ => null,
          },
          selectable: !liveSaveNames.contains(
            archive.saveFolderName.toLowerCase(),
          ),
          blockedReason:
              liveSaveNames.contains(archive.saveFolderName.toLowerCase())
              ? 'A save folder named "${archive.saveFolderName}" already exists. '
                    'Move or archive it before restoring this save.'
              : null,
        ),
    ],
    initiallySelected: const {},
    confirmLabel: (count) => 'Restore $count save${count == 1 ? '' : 's'}',
    confirmIcon: Icons.unarchive,
    checkboxLabel: 'Delete the archives afterwards',
  );

  if (picked == null || picked.ids.isEmpty || !context.mounted) return;

  await _runRestoreJobs(
    context,
    ref,
    archives
        .where((archive) => picked.ids.contains(archive.archiveFile.path))
        .toList(),
    removeArchivesAfterwards: picked.checkboxTicked,
  );
}

Future<void> _runArchiveJobs(
  BuildContext context,
  WidgetRef ref,
  List<SaveFile> saves,
) => showSaveArchiveRunnerDialog(
  context: context,
  title: 'Archiving ${saves.length} save${saves.length == 1 ? '' : 's'}',
  finishedTitle: 'Archived ${saves.length} save${saves.length == 1 ? '' : 's'}',
  jobs: [
    for (final save in saves)
      SaveArchiveJobRequest(
        title: _saveTitle(save),
        subtitle: save.folder.name,
        run: (onStep) async {
          final outcome = await archiveOneSave(ref, save, onProgress: onStep);
          return SaveArchiveJobResult(
            succeeded: outcome.archiveCreated,
            needsAttention: !outcome.succeeded,
            // On success the dialog shows the sizes instead of a message.
            message: outcome.succeeded ? '' : outcome.message,
            originalSizeInBytes: outcome.succeeded
                ? outcome.originalSizeInBytes
                : null,
            archiveSizeInBytes: outcome.succeeded
                ? outcome.archiveSizeInBytes
                : null,
          );
        },
      ),
  ],
  onFinished: () {
    ref.invalidate(saveFileProvider);
    ref.read(archivedSavesProvider.notifier).reload();
  },
);

Future<void> _runRestoreJobs(
  BuildContext context,
  WidgetRef ref,
  List<ArchivedSaveEntry> archives, {
  required bool removeArchivesAfterwards,
}) => showSaveArchiveRunnerDialog(
  context: context,
  title: 'Restoring ${archives.length} save${archives.length == 1 ? '' : 's'}',
  finishedTitle:
      'Restored ${archives.length} save${archives.length == 1 ? '' : 's'}',
  jobs: [
    for (final archive in archives)
      SaveArchiveJobRequest(
        title: archive.displayName,
        subtitle: archive.saveFolderName,
        run: (onStep) async {
          final outcome = await restoreOneArchive(
            ref,
            archive,
            removeArchiveAfterwards: removeArchivesAfterwards,
            onProgress: onStep,
          );
          return SaveArchiveJobResult(
            succeeded: outcome.restored,
            needsAttention: outcome.restored && outcome.failure != null,
            message: outcome.message,
          );
        },
      ),
  ],
  onFinished: () {
    ref.invalidate(saveFileProvider);
    ref.read(archivedSavesProvider.notifier).reload();
  },
);

class SaveArchivesDialog extends ConsumerStatefulWidget {
  const SaveArchivesDialog({super.key});

  @override
  ConsumerState<SaveArchivesDialog> createState() => _SaveArchivesDialogState();
}

class _SaveArchivesDialogState extends ConsumerState<SaveArchivesDialog> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final archivesAsync = ref.watch(archivedSavesProvider);
    final archiveFolder = ref.watch(saveArchiveFolderProvider);
    final iconColor = theme.iconTheme.color;

    // Use the normal icon color for every button in the dialog. The outline
    // is a light gray so it shows on the dialog's lighter background; the
    // theme's outline colors are picked for the darker page background.
    return Theme(
      data: theme.copyWith(
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(foregroundColor: iconColor),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            iconColor: iconColor,
          ).merge(theme.outlinedButtonTheme.style),
        ),
      ),
      child: AlertDialog(
        title: Row(
          children: [
            const Text('Archived Saves'),
            const Spacer(),
            MovingTooltipWidget.text(
              message: 'About save archiving',
              child: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => showAlertDialog(
                  context,
                  title: 'Archived Saves',
                  content:
                      'Archiving compresses a save to a .7z file to save disk space.'
                      '\n\nYou can later restore archived saves.'
                      '\nArchiving typically reduces a save to around 10% of its original size (from 10MB to 1MB).',
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 720,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => showBulkArchiveSavesDialog(context, ref),
                    icon: const Icon(Icons.archive),
                    label: const Text('Archive saves…'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showBulkRestoreSavesDialog(context, ref),
                    icon: const Icon(Icons.unarchive),
                    label: const Text('Restore saves…'),
                  ),
                  const Spacer(),
                  MovingTooltipWidget.text(
                    message: 'Reread the archive folder',
                    child: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () =>
                          ref.read(archivedSavesProvider.notifier).reload(),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: archivesAsync.when(
                  data: (archives) => archives.isEmpty
                      ? _buildEmptyState(theme)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            Flexible(
                              child: Scrollbar(
                                thumbVisibility: true,
                                controller: _scrollController,
                                child: ListView.separated(
                                  controller: _scrollController,
                                  shrinkWrap: true,
                                  // Keeps the row buttons clear of the scrollbar.
                                  padding: const .only(right: 16),
                                  itemCount: archives.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) =>
                                      _ArchiveRow(entry: archives[index]),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _ArchiveTotals(archives: archives),
                          ],
                        ),
                  loading: () => const Padding(
                    padding: .symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Padding(
                    padding: const .symmetric(vertical: 32),
                    child: Text('Unable to read the archive folder: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: .spaceBetween,
        actions: [
          _buildFolderButtons(context, ref, archiveFolder),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) => Padding(
    padding: const .symmetric(vertical: 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Icon(Icons.inventory_2_outlined, size: 40, color: theme.disabledColor),
        Text(
          'No archived saves yet.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          'Choose "Archive saves…" to archive saves.',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium,
        ),
      ],
    ),
  );

  Widget _buildFolderButtons(
    BuildContext context,
    WidgetRef ref,
    Directory? archiveFolder,
  ) {
    final usingCustom = ref.watch(
      appSettings.select((settings) => settings.useCustomSavesArchivePath),
    );
    final savesFolder = ref.watch(AppState.savesFolder).value;
    final defaultFolder = savesFolder == null
        ? null
        : defaultSaveArchiveFolder(savesFolder);
    bool isDefaultFolder(Directory? folder) =>
        folder != null &&
        defaultFolder != null &&
        p.equals(folder.normalize.path, defaultFolder.path);
    // A custom folder that points at the default folder is the default.
    final showUseDefault = usingCustom && !isDefaultFolder(archiveFolder);

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        MovingTooltipWidget.text(
          message:
              archiveFolder?.path ?? 'Set the game folder in Settings first.',
          child: Disable(
            isEnabled: archiveFolder != null,
            child: OutlinedButton.icon(
              onPressed: () async {
                final folder = archiveFolder;
                if (folder == null) return;
                await _openFolder(folder);
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('Open archive folder'),
            ),
          ),
        ),
        MovingTooltipWidget.text(
          message: 'Choose archive folder',
          child: OutlinedButton.icon(
            icon: const Icon(Icons.drive_file_move_outline),
            label: const Text('Change folder…'),
            onPressed: () async {
              final picked = await FilePicker.platform.getDirectoryPath(
                dialogTitle: 'Choose archive folder',
                initialDirectory: archiveFolder?.path,
              );
              if (picked == null || !context.mounted) return;
              final newFolder = picked.toDirectory().normalize;
              if (savesFolder != null &&
                  SaveArchiver.isInsideSavesFolder(newFolder, savesFolder)) {
                await showAlertDialog(
                  context,
                  title: 'Unable to use this folder',
                  content:
                      'The archive folder cannot be the saves folder or a '
                      'folder inside it. Pick a folder outside '
                      '${savesFolder.path}.\n\n'
                      'The archive folder was not changed.',
                );
                return;
              }
              await _changeArchiveFolder(
                context,
                ref,
                from: archiveFolder,
                to: newFolder,
                applySetting: () => ref
                    .read(appSettings.notifier)
                    .update(
                      (settings) => isDefaultFolder(newFolder)
                          ? settings.copyWith(useCustomSavesArchivePath: false)
                          : settings.copyWith(
                              customSavesArchivePath: newFolder,
                              useCustomSavesArchivePath: true,
                            ),
                    ),
              );
            },
          ),
        ),
        if (showUseDefault)
          MovingTooltipWidget.text(
            message:
                'Use the default archive folder '
                '(${Constants.savesArchiveFolderName}).',
            child: IconButton(
              icon: const Icon(Icons.settings_backup_restore),
              iconSize: 18,
              onPressed: () async {
                await _changeArchiveFolder(
                  context,
                  ref,
                  from: archiveFolder,
                  to: defaultFolder,
                  applySetting: () => ref
                      .read(appSettings.notifier)
                      .update(
                        (settings) =>
                            settings.copyWith(useCustomSavesArchivePath: false),
                      ),
                );
              },
            ),
          ),
      ],
    );
  }
}

enum _MoveArchivesChoice { cancel, dontMove, move }

/// Switches the archive folder from [from] to [to], first asking whether to
/// move the archives in [from]. The setting only changes once every archive
/// has been moved, so none are left behind in a folder TriOS no longer shows.
Future<void> _changeArchiveFolder(
  BuildContext context,
  WidgetRef ref, {
  required Directory? from,
  required Directory? to,
  required VoidCallback applySetting,
}) async {
  void apply() {
    applySetting();
    ref.read(archivedSavesProvider.notifier).reload();
  }

  if (from == null ||
      to == null ||
      p.equals(from.normalize.path, to.normalize.path)) {
    apply();
    return;
  }

  final List<File> archives;
  try {
    archives = await ArchiveFolderMover.listArchives(from);
  } catch (error, stackTrace) {
    Fimber.w(
      'Unable to list archives in ${from.path}',
      ex: error,
      stacktrace: stackTrace,
    );
    if (context.mounted) {
      await showAlertDialog(
        context,
        title: 'Unable to change the archive folder',
        content:
            'TriOS could not read ${from.path}: $error\n\n'
            'The archive folder was not changed.',
      );
    }
    return;
  }

  if (archives.isEmpty) {
    apply();
    return;
  }
  if (!context.mounted) return;

  final choice = await showDialog<_MoveArchivesChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Move archive folder'),
      content: const Text(
        'Do you also want to move your archived saves to the new folder?',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_MoveArchivesChoice.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_MoveArchivesChoice.dontMove),
          child: const Text("Don't Move"),
        ),
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(_MoveArchivesChoice.move),
          child: const Text('Move'),
        ),
      ],
    ),
  );

  switch (choice) {
    case null || _MoveArchivesChoice.cancel:
      return;
    case _MoveArchivesChoice.dontMove:
      apply();
      return;
    case _MoveArchivesChoice.move:
      break;
  }

  final mover = ArchiveFolderMover(
    fromFolder: from,
    toFolder: to,
    removeFile: moveFileToTrash,
  );

  final problem = await mover.checkCanMove();
  if (problem != null) {
    if (context.mounted) {
      await showAlertDialog(
        context,
        title: 'Unable to move archived saves',
        content:
            '$problem\n\n'
            'Nothing was moved. The archive folder was not changed.',
      );
    }
    return;
  }
  if (!context.mounted) return;

  final namesByPath = {
    for (final entry in ref.read(archivedSavesProvider).value ?? [])
      p.normalize(entry.archiveFile.path): entry.displayName,
  };
  var movedCount = 0;
  final count = archives.length;

  await showSaveArchiveRunnerDialog(
    context: context,
    title: 'Moving $count save${count == 1 ? '' : 's'}',
    finishedTitle: 'Moved $count save${count == 1 ? '' : 's'}',
    jobs: [
      for (final archive in archives)
        SaveArchiveJobRequest(
          title:
              namesByPath[p.normalize(archive.path)] ??
              p.basenameWithoutExtension(archive.path),
          subtitle: p.basename(archive.path),
          run: (onStep) async {
            final outcome = await mover.moveArchive(
              archive,
              onProgress: onStep,
            );
            if (outcome.moved) movedCount++;
            return SaveArchiveJobResult(
              succeeded: outcome.moved,
              needsAttention: outcome.moved && !outcome.originalRemoved,
              message: outcome.message,
            );
          },
        ),
    ],
  );

  if (movedCount == count) {
    apply();
    return;
  }

  ref.read(archivedSavesProvider.notifier).reload();
  if (context.mounted) {
    await showAlertDialog(
      context,
      title: 'Archive folder not changed',
      content:
          '$movedCount of $count archived saves were moved to ${to.path}. '
          'The rest are still in ${from.path}.\n\n'
          'To move the rest, change the folder again.',
    );
  }
}

/// Total archive size, original size, and space saved across all archives.
///
/// Original size and space saved only count archives that recorded their
/// original size.
class _ArchiveTotals extends StatelessWidget {
  final List<ArchivedSaveEntry> archives;

  const _ArchiveTotals({required this.archives});

  @override
  Widget build(BuildContext context) {
    final archivedSize = archives.map((e) => e.sizeOnDiskInBytes).sum;
    final withOriginalSize = archives
        .where((entry) => (entry.info?.originalSizeInBytes ?? 0) > 0)
        .toList();
    final originalSize = withOriginalSize
        .map((entry) => entry.info!.originalSizeInBytes)
        .sum;
    final saved =
        (originalSize - withOriginalSize.map((e) => e.sizeOnDiskInBytes).sum)
            .clamp(0, originalSize);
    final missingCount = archives.length - withOriginalSize.length;

    final originalStats = Row(
      spacing: 32,
      children: [
        SizeStat(
          label: 'Original size',
          value: withOriginalSize.isEmpty
              ? 'Unknown'
              : originalSize.bytesAsReadable(),
        ),
        SizeStat(
          label: 'Space saved',
          value: withOriginalSize.isEmpty
              ? 'Unknown'
              : '${saved.bytesAsReadable()} '
                    '(${(saved * 100 / originalSize).round()}%)',
        ),
      ],
    );

    return Row(
      spacing: 32,
      children: [
        SizeStat(
          label: 'Total archive size',
          value: archivedSize.bytesAsReadable(),
        ),
        if (missingCount == 0)
          originalStats
        else
          MovingTooltipWidget.text(
            message:
                'Leaves out $missingCount archive${missingCount == 1 ? '' : 's'} '
                'with no recorded original size.',
            child: originalStats,
          ),
      ],
    );
  }
}

class _ArchiveRow extends ConsumerWidget {
  final ArchivedSaveEntry entry;

  const _ArchiveRow({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final info = entry.info;
    final saveExists = (ref.watch(saveFileProvider).value ?? []).any(
      (save) =>
          save.folder.name.toLowerCase() == entry.saveFolderName.toLowerCase(),
    );

    return Padding(
      padding: const .symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    if (info?.isIronMode == true)
                      MovingTooltipWidget.text(
                        message: 'Ironmode',
                        child: Icon(
                          Icons.shield,
                          size: 14,
                          color: theme
                              .extension<TriOSThemeExtension>()
                              ?.warning,
                        ),
                      ),
                    if (saveExists)
                      MovingTooltipWidget.text(
                        message:
                            'A save with this folder name is in the saves '
                            'folder, so this archive cannot be restored until '
                            'that one is moved or archived.',
                        child: Icon(
                          Icons.info_outline,
                          size: 14,
                          color: theme.disabledColor,
                        ),
                      ),
                  ],
                ),
                Text(
                  _archiveSubtitle(entry),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.labelSmall?.color?.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
          Text(
            entry.sizeOnDiskInBytes.bytesAsReadable(),
            style: theme.textTheme.labelMedium,
          ),
          MovingTooltipWidget.text(
            message: saveExists
                ? 'A save called "${entry.saveFolderName}" is already there'
                : 'Restore this save',
            child: Disable(
              isEnabled: !saveExists,
              child: IconButton(
                icon: const Icon(Icons.unarchive),
                onPressed: () => _restore(context, ref),
              ),
            ),
          ),
          MovingTooltipWidget.text(
            message: 'Show in folder',
            child: IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: () => entry.archiveFile.showInExplorer(),
            ),
          ),
          MovingTooltipWidget.text(
            message: 'Delete this archive',
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, saveExists),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    var removeAfterwards = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Restore this save?'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  'Restore "${entry.displayName}" to your saves folder as '
                  '${entry.saveFolderName}.',
                ),
                CheckboxListTile(
                  value: removeAfterwards,
                  onChanged: (value) =>
                      setState(() => removeAfterwards = value == true),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Delete the archive afterwards'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.unarchive),
              label: const Text('Restore'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await _runRestoreJobs(context, ref, [
      entry,
    ], removeArchivesAfterwards: removeAfterwards);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    bool saveExists,
  ) async {
    final info = entry.info;
    final portrait = _portraitFile(ref, info?.portraitPath);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final mutedColor = theme.textTheme.labelSmall?.color?.withAlpha(180);
        final warningColor =
            theme.extension<TriOSThemeExtension>()?.warning ?? Colors.amber;
        final originalSize = info?.originalSizeInBytes ?? 0;

        return AlertDialog(
          title: const Text('Delete this archive?'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Row(
                  children: [
                    FutureBuilder<File?>(
                      future: portrait,
                      builder: (context, snapshot) {
                        final file = snapshot.data;
                        if (file == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const .only(right: 8),
                          child: Image.file(
                            file,
                            width: 48,
                            height: 48,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.displayName,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            _archiveSubtitle(entry),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 32,
                  children: [
                    SizeStat(
                      label: 'Archive size',
                      value: entry.sizeOnDiskInBytes.bytesAsReadable(),
                    ),
                    if (originalSize > 0)
                      SizeStat(
                        label: 'Original size',
                        value: originalSize.bytesAsReadable(),
                      ),
                  ],
                ),
                if (!saveExists)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Icon(Icons.warning_amber, size: 20, color: warningColor),
                      Expanded(
                        child: Text(
                          "There doesn't appear to be an unarchived save "
                          'folder for this captain, which means you may be '
                          'about to delete your only copy of the save!',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: warningColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actionsAlignment: .spaceBetween,
          actions: [
            TextButton.icon(
              onPressed: () => entry.archiveFile.showInExplorer(),
              icon: const Icon(Icons.folder_open),
              label: const Text('Show in folder'),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                TextButton(
                  autofocus: true,
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await deleteArchive(entry);
      await ref.read(archivedSavesProvider.notifier).reload();
    } catch (error) {
      if (context.mounted) {
        showSnackBar(
          context: context,
          type: SnackBarType.error,
          content: Text('Unable to delete the archive: $error'),
        );
      }
    }
  }
}

/// Opens [folder] in the OS file manager, creating it first when it is missing.
Future<void> _openFolder(Directory folder) async {
  await folder.create(recursive: true);
  folder.openInExplorer();
}

/// Estimates the folder size for the picker. On a read failure, returns the
/// bytes counted so far so the dialog can still open.
Future<int> _folderSize(Directory folder) async {
  var total = 0;
  try {
    await for (final entity in folder.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) total += await entity.length();
    }
  } catch (error) {
    Fimber.w('Unable to measure ${folder.path}: $error');
  }
  return total;
}

/// Finds a save's portrait in the game or an installed mod, swapped for the
/// user's portrait replacement when there is one. Same lookup as the profile
/// card, so both show the same picture.
Future<File?> _portraitFile(WidgetRef ref, String? portraitPath) async {
  if (portraitPath == null || portraitPath.isEmpty) return null;

  final folders = [
    ref.read(AppState.gameCoreFolder).value,
    ...ref
        .read(AppState.mods)
        .map((mod) => mod.findFirstEnabledOrHighestVersion?.modFolder),
  ].nonNulls;
  final portrait = folders
      .map((dir) => dir.resolve(portraitPath).toFile())
      .firstWhereOrNull((file) => file.existsSync());
  if (portrait == null) return null;

  final replacement = await ref
      .read(AppState.portraitReplacementsManager.notifier)
      .getReplacementByPath(portrait);
  return replacement?.lastKnownFullPath.toFile() ?? portrait;
}

typedef _ArchiveRatio = ({double ratio, bool fromExistingArchives});

/// Archive size divided by original size, totalled over existing archives.
/// Falls back to 0.1 (about 90% smaller) when no archive recorded its sizes.
_ArchiveRatio _estimatedArchiveRatio(List<ArchivedSaveEntry> archives) {
  var original = 0;
  var archived = 0;
  for (final info in archives.mapNotNull((entry) => entry.info)) {
    if (info.originalSizeInBytes <= 0 || info.archiveSizeInBytes <= 0) {
      continue;
    }
    original += info.originalSizeInBytes;
    archived += info.archiveSizeInBytes;
  }
  if (original == 0) return (ratio: 0.1, fromExistingArchives: false);
  return (ratio: archived / original, fromExistingArchives: true);
}

String _estimateTooltip(_ArchiveRatio archiveRatio) =>
    archiveRatio.fromExistingArchives
    ? 'Estimated from your other save archives.'
    : 'Estimated. Archives are usually about 90% smaller than the save.';

String _saveTitle(SaveFile save) =>
    save.characterName.isEmpty ? save.folder.name : save.characterName;

String _saveSubtitle(SaveFile save) {
  final parts = <String>['level ${save.characterLevel}'];
  final saved = save.saveDate;
  if (saved != null) {
    parts.add('saved ${Constants.dateTimeFormat.format(saved.toLocal())}');
  }
  parts.add('${save.mods.length} mods');
  return parts.join(' · ');
}

String _archiveSubtitle(ArchivedSaveEntry entry) {
  final info = entry.info;
  final parts = <String>[entry.saveFolderName];
  if (info != null) {
    if ((info.characterLevel ?? 0) > 0) {
      parts.add('level ${info.characterLevel}');
    }
    final saved = info.saveDate;
    if (saved != null) {
      parts.add('saved ${Constants.dateTimeFormat.format(saved.toLocal())}');
    }
    if (info.modNames.isNotEmpty) {
      parts.add('${info.modNames.length} mods');
    }
  } else {
    parts.add('details unreadable — can still be restored');
  }
  return parts.join(' · ');
}
