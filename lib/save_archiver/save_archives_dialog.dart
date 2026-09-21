import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/save_archiver/archived_save_store.dart';
import 'package:trios/save_archiver/bulk_save_selection_dialog.dart';
import 'package:trios/save_archiver/save_archive_manager.dart';
import 'package:trios/save_archiver/save_archive_runner_dialog.dart';
import 'package:trios/save_archiver/save_archive_selection.dart';
import 'package:trios/themes/theme.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/snackbar.dart';

/// Opens the list of archived saves, with the bulk actions on it.
Future<void> showSaveArchivesDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => const SaveArchivesDialog(),
);

/// Archives one save, after a confirmation that says exactly what will happen.
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
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Archive this save?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              '"${save.characterName}" (${save.folder.name}) will be '
              'compressed into:',
            ),
            Text(
              archiveFolder?.path ?? '',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const Text(
              'The save folder is only removed after the archive has been '
              'checked file by file. You can put it back at any time.',
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
          icon: const Icon(Icons.archive),
          label: const Text('Archive'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  await _runArchiveJobs(context, ref, [save]);
}

/// Opens the "archive older saves" dialog: pick how many of the newest to keep,
/// then change any of the ticks by hand.
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

  final keepCount = ref
      .read(appSettings)
      .saveArchiveKeepNewestCount
      .clamp(0, saves.length);

  final picked = await showBulkSaveSelectionDialog(
    context: context,
    title: 'Archive saves',
    explanation:
        'Pick how many of the newest saves to keep, then change any of the '
        'ticks yourself. Only what is ticked gets archived.',
    items: [
      for (final save in saves)
        SaveSelectionItem(
          id: save.id,
          title: _saveTitle(save),
          subtitle: _saveSubtitle(save),
          sizeInBytes: sizes[save.id] ?? 0,
        ),
    ],
    initiallySelected: savesToArchiveKeepingNewest(
      saves,
      keepCount,
    ).map((save) => save.id).toSet(),
    countFilter: SaveSelectionCountFilter(
      prefixLabel: 'Keep the newest',
      suffixLabel: saves.length == 1 ? 'save' : 'saves',
      initialValue: keepCount,
      maxValue: saves.length,
      selectionFor: (value) => savesToArchiveKeepingNewest(
        saves,
        value,
      ).map((save) => save.id).toSet(),
      onValueChanged: (value) => ref
          .read(appSettings.notifier)
          .update(
            (settings) => settings.copyWith(saveArchiveKeepNewestCount: value),
          ),
    ),
    confirmLabel: (count) => 'Archive $count save${count == 1 ? '' : 's'}',
    confirmIcon: Icons.archive,
    warning:
        'Each save folder is removed only after its archive has been checked '
        'file by file.',
  );

  if (picked == null || picked.isEmpty || !context.mounted) return;

  await _runArchiveJobs(
    context,
    ref,
    saves.where((save) => picked.contains(save.id)).toList(),
  );
}

/// Opens the "restore saves" dialog: the same shape as the archive one, with
/// the newest archives ticked to start with.
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

  final defaultCount = archives.length < 3 ? archives.length : 3;

  final picked = await showBulkSaveSelectionDialog(
    context: context,
    title: 'Restore saves',
    explanation:
        'Pick how many of the newest archives to put back, then change any of '
        'the ticks yourself. The archives are kept.',
    items: [
      for (final archive in archives)
        SaveSelectionItem(
          id: archive.archiveFile.path,
          title: archive.displayName,
          subtitle: _archiveSubtitle(archive),
          sizeInBytes: archive.sizeOnDiskInBytes,
          selectable: !liveSaveNames.contains(
            archive.saveFolderName.toLowerCase(),
          ),
          blockedReason:
              liveSaveNames.contains(archive.saveFolderName.toLowerCase())
              ? 'A save called "${archive.saveFolderName}" is already there, '
                    'so this one cannot be put back yet.'
              : null,
        ),
    ],
    initiallySelected: archivesToRestoreNewest(
      archives,
      defaultCount,
    ).map((archive) => archive.archiveFile.path).toSet(),
    countFilter: SaveSelectionCountFilter(
      prefixLabel: 'Restore the newest',
      suffixLabel: archives.length == 1 ? 'archive' : 'archives',
      initialValue: defaultCount,
      maxValue: archives.length,
      selectionFor: (value) => archivesToRestoreNewest(
        archives,
        value,
      ).map((archive) => archive.archiveFile.path).toSet(),
    ),
    confirmLabel: (count) => 'Restore $count save${count == 1 ? '' : 's'}',
    confirmIcon: Icons.unarchive,
  );

  if (picked == null || picked.isEmpty || !context.mounted) return;

  await _runRestoreJobs(
    context,
    ref,
    archives
        .where((archive) => picked.contains(archive.archiveFile.path))
        .toList(),
    removeArchivesAfterwards: false,
  );
}

Future<void> _runArchiveJobs(
  BuildContext context,
  WidgetRef ref,
  List<SaveFile> saves,
) => showSaveArchiveRunnerDialog(
  context: context,
  title: 'Archiving ${saves.length} save${saves.length == 1 ? '' : 's'}',
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
            message: outcome.succeeded
                ? '${outcome.originalSizeInBytes.bytesAsReadable()} → '
                      '${outcome.archiveSizeInBytes.bytesAsReadable()}'
                : outcome.message,
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

/// The list of archived saves.
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

    return AlertDialog(
      title: Row(
        children: [
          const Text('Archived Saves'),
          const Spacer(),
          MovingTooltipWidget.text(
            message: 'What is this?',
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => showAlertDialog(
                context,
                title: 'Archived Saves',
                content:
                    'Archiving compresses a save folder into a single file and '
                    'removes the folder, which keeps the game\'s load list '
                    'short and frees up disk space.\n\n'
                    'The folder is only removed once the archive has been '
                    'checked file by file against it, and removal goes to the '
                    'recycle bin where the system allows it. Restoring never '
                    'writes over a save that is already there.',
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
            _buildFolderRow(context, ref, theme, archiveFolder),
            const Divider(height: 8),
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
                    : Scrollbar(
                        thumbVisibility: true,
                        controller: _scrollController,
                        child: ListView.separated(
                          controller: _scrollController,
                          shrinkWrap: true,
                          itemCount: archives.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) =>
                              _ArchiveRow(entry: archives[index]),
                        ),
                      ),
                loading: () => const Padding(
                  padding: .symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const .symmetric(vertical: 32),
                  child: Text('Could not read the archive folder: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) => Padding(
    padding: const .symmetric(vertical: 32),
    child: Column(
      spacing: 8,
      children: [
        Icon(Icons.inventory_2_outlined, size: 40, color: theme.disabledColor),
        Text('No archived saves yet.', style: theme.textTheme.bodyMedium),
        Text(
          'Use "Archive saves…" to compress the ones you are not playing.',
          style: theme.textTheme.labelMedium,
        ),
      ],
    ),
  );

  Widget _buildFolderRow(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Directory? archiveFolder,
  ) {
    final usingCustom = ref.watch(
      appSettings.select((settings) => settings.useCustomSavesArchivePath),
    );

    return Row(
      spacing: 8,
      children: [
        Icon(Icons.folder, size: 18, color: theme.disabledColor),
        Expanded(
          child: Text(
            archiveFolder?.path ?? 'Set the game folder in Settings first.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium,
          ),
        ),
        MovingTooltipWidget.text(
          message: 'Open the archive folder',
          child: Disable(
            isEnabled: archiveFolder != null,
            child: IconButton(
              icon: const Icon(Icons.open_in_new),
              iconSize: 18,
              onPressed: () async {
                if (archiveFolder == null) return;
                await archiveFolder.create(recursive: true);
                archiveFolder.openInExplorer();
              },
            ),
          ),
        ),
        MovingTooltipWidget.text(
          message: 'Keep archives somewhere else',
          child: IconButton(
            icon: const Icon(Icons.drive_file_move_outline),
            iconSize: 18,
            onPressed: () async {
              final picked = await FilePicker.platform.getDirectoryPath(
                dialogTitle: 'Where should archived saves go?',
                initialDirectory: archiveFolder?.path,
              );
              if (picked == null) return;
              ref
                  .read(appSettings.notifier)
                  .update(
                    (settings) => settings.copyWith(
                      customSavesArchivePath: picked.toDirectory().normalize,
                      useCustomSavesArchivePath: true,
                    ),
                  );
              ref.read(archivedSavesProvider.notifier).reload();
            },
          ),
        ),
        if (usingCustom)
          MovingTooltipWidget.text(
            message:
                'Put archives back beside the saves folder '
                '(${Constants.savesArchiveFolderName})',
            child: IconButton(
              icon: const Icon(Icons.settings_backup_restore),
              iconSize: 18,
              onPressed: () {
                ref
                    .read(appSettings.notifier)
                    .update(
                      (settings) =>
                          settings.copyWith(useCustomSavesArchivePath: false),
                    );
                ref.read(archivedSavesProvider.notifier).reload();
              },
            ),
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
                : 'Put this save back',
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
                  '"${entry.displayName}" goes back into your saves folder as '
                  '${entry.saveFolderName}.',
                ),
                CheckboxListTile(
                  value: removeAfterwards,
                  onChanged: (value) =>
                      setState(() => removeAfterwards = value == true),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Delete the archive afterwards'),
                  subtitle: const Text(
                    'Off by default. The archive is only deleted once the '
                    'restored save has been checked.',
                  ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this archive?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text('"${entry.displayName}" (${entry.saveFolderName})'),
              Text(
                saveExists
                    ? 'There is still a save folder of this name in your saves '
                          'folder, so this is not the only copy.'
                    : 'This is the only copy of this save. Once it is gone, it '
                          'is gone.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Text(
                'It goes to the recycle bin where your system allows it.',
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
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
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
          content: Text('Could not delete the archive: $error'),
        );
      }
    }
  }
}

/// Adds up the bytes in a save folder, for showing next to it in the picker.
///
/// A best guess: a folder that can't be read counts as zero rather than
/// stopping the dialog from opening.
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
    Fimber.w('Could not measure ${folder.path}: $error');
  }
  return total;
}

String _saveTitle(SaveFile save) =>
    save.characterName.isEmpty ? save.folder.name : save.characterName;

String _saveSubtitle(SaveFile save) {
  final parts = <String>['Level ${save.characterLevel}'];
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
