import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/modpacks/full_page/modpack_full_page.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/primary_outlined_button.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';

import 'modpack_installation.dart';
import 'modpack_recovery.dart';

import 'package:trios/modpacks/modpack_error_text.dart';

Future<void> showModpackInstallDialog(
  BuildContext context,
  ModpackLibraryEntry entry,
) => showDialog<void>(
  context: context,
  builder: (_) => ModpackInstallDialog(entry: entry),
);

class ModpackInstallDialog extends ConsumerStatefulWidget {
  final ModpackLibraryEntry entry;

  const ModpackInstallDialog({super.key, required this.entry});

  @override
  ConsumerState<ModpackInstallDialog> createState() =>
      _ModpackInstallDialogState();
}

class _ModpackInstallDialogState extends ConsumerState<ModpackInstallDialog> {
  ModpackInstallPlan? plan;
  ModpackInstallRun? run;
  Set<String> selected = {};
  bool enable = false;
  bool recovering = false;
  String? error;

  String get packName => widget.entry.definition.name;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(
      modpackInstallationProvider,
    )[widget.entry.definition.id];
    if (existing != null && !existing.complete) {
      run = existing;
    } else {
      _prepare();
    }
  }

  Future<void> _prepare() async {
    try {
      final prepared = await ref
          .read(modpackInstallationProvider.notifier)
          .prepare(widget.entry);
      if (mounted) {
        setState(() {
          plan = prepared;
          selected = prepared.defaultSelection;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = modpackErrorText(e));
    }
  }

  Future<void> _recover(String id) async {
    final old = plan!.items.firstWhere((c) => c.row.key == id);
    setState(() => recovering = true);
    try {
      final replacement = await chooseModpackRecovery(context, ref, old);
      if (replacement != null && mounted) {
        setState(() {
          plan = ModpackInstallPlan(plan!.entry, [
            for (final c in plan!.items)
              if (c.row.key == id) replacement else c,
          ]);
          selected = {...selected, id};
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = modpackErrorText(e));
    } finally {
      if (mounted) setState(() => recovering = false);
    }
  }

  void _start() {
    try {
      final started = ref
          .read(modpackInstallationProvider.notifier)
          .start(plan!, selected, enableAfterInstallation: enable);
      setState(() {
        run = started;
        error = null;
      });
    } catch (e) {
      setState(() => error = modpackErrorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(
      modpackInstallationProvider,
    )[widget.entry.definition.id];
    if (current != null && !current.complete) run = current;
    final active = run;
    final prepared = plan;

    return Dialog(
      insetPadding: const .all(24),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: 1300,
        height: 800,
        child: prepared == null && active == null
            ? _buildPreparingOrError()
            : Column(
                children: [
                  Expanded(
                    child: _buildPackView(prepared: prepared, active: active),
                  ),
                  _buildFooter(active),
                ],
              ),
      ),
    );
  }

  /// Shows preparation progress or an error before the pack view is available.
  Widget _buildPreparingOrError() {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: .min,
          spacing: 16,
          children: error == null
              ? [
                  Text(
                    'Checking downloads',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    'Looking for downloads for the mods in $packName.',
                    textAlign: .center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(
                    width: 280,
                    child: ThemedLinearProgressIndicator(minHeight: 6),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ]
              : [
                  Icon(
                    Icons.error_outline,
                    size: 40,
                    color: theme.colorScheme.error,
                  ),
                  Text(
                    'Cannot install $packName',
                    style: theme.textTheme.titleMedium,
                    textAlign: .center,
                  ),
                  Text(
                    error!,
                    textAlign: .center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  PrimaryOutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildPackView({
    required ModpackInstallPlan? prepared,
    required ModpackInstallRun? active,
  }) {
    final theme = Theme.of(context);
    final picking = active == null;

    return ModpackFullPage(
      entry: widget.entry,
      onBack: () => Navigator.pop(context),
      checkedItemKeys: picking ? selected : null,
      selectableItemKeys: picking ? _installableKeys(prepared!) : null,
      onCheckedItemsChanged: picking
          ? (keys) => setState(
              () => selected = keys.intersection(_installableKeys(prepared!)),
            )
          : null,
      installationDetails: active?.results ?? _plannedDetails(prepared!),
      onRecoverItem: picking && !recovering ? _recover : null,
      previewToolbar: Padding(
        padding: const .fromLTRB(8, 16, 8, 16),
        child: Column(
          crossAxisAlignment: .start,
          spacing: 4,
          children: [
            Text(
              picking
                  ? 'Install $packName'
                  : active.complete
                  ? packName
                  : 'Installing $packName',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Set<String> _installableKeys(ModpackInstallPlan prepared) => {
    for (final c in prepared.items)
      if (c.installable) c.row.key,
  };

  /// What the "Installation" column shows before anything has been downloaded.
  Map<String, ModpackItemInstallResult> _plannedDetails(
    ModpackInstallPlan prepared,
  ) => {
    for (final c in prepared.items)
      c.row.key: ModpackItemInstallResult(
        c.error == null &&
                (c.recoverySource != null ||
                    widget.entry.itemFailures[c.row.key] == null)
            ? .queued
            : .failed,
        detail:
            c.error ??
            (c.recoverySource == null
                ? widget.entry.itemFailures[c.row.key]?.message
                : null) ??
            (c.recoverySource != null
                ? 'Catalog: ${c.recoverySource!.catalogName}'
                : 'Ready'),
      ),
  };

  Widget _buildFooter(ModpackInstallRun? active) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: modpackHairlineColor(theme))),
      ),
      child: Padding(
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .stretch,
          spacing: 12,
          children: [
            if (error != null || active?.error != null)
              _buildErrorBanner((error ?? active!.error)!),
            Row(
              spacing: 24,
              children: [
                Expanded(
                  child: active == null
                      ? _buildPickingStatus()
                      : _buildRunStatus(active),
                ),
                ..._buildActions(active),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    final theme = Theme.of(context);
    return Container(
      padding: const .symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        spacing: 8,
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: theme.colorScheme.onErrorContainer,
          ),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickingStatus() => Align(
    alignment: .centerLeft,
    child: CheckboxWithLabel(
      value: enable,
      onChanged: (value) => setState(() => enable = value == true),
      label: 'Enable these mods after installing',
    ),
  );

  Widget _buildRunStatus(ModpackInstallRun active) {
    final theme = Theme.of(context);
    final total = active.results.length;

    if (!active.complete) {
      return Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        spacing: 6,
        children: [
          Text(
            active.stopping
                ? 'Stopping after current work finishes…'
                : '${active.finishedCount} of $total finished…',
            style: theme.textTheme.bodyMedium,
          ),
          ThemedLinearProgressIndicator(
            minHeight: 6,
            value: total == 0 ? null : active.finishedCount / total,
          ),
        ],
      );
    }

    int countOf(ModpackItemInstallStatus status) =>
        active.results.values.where((r) => r.status == status).length;
    final installed = countOf(.installed);
    final failed = countOf(.failed);
    final skipped = countOf(.skipped);

    final parts = [
      '$installed installed',
      if (failed > 0) '$failed failed',
      if (skipped > 0) '$skipped skipped',
    ];

    return Row(
      spacing: 8,
      children: [
        Icon(
          failed > 0 ? Icons.warning_amber : Icons.check_circle_outline,
          size: 20,
          color: failed > 0
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
        ),
        Expanded(
          child: Text(parts.join(' · '), style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }

  List<Widget> _buildActions(ModpackInstallRun? active) {
    if (active == null) {
      // Allow an enable-only run when no new mods are selected.
      final enableOnly = selected.isEmpty && enable;
      final canStart = !recovering && (selected.isNotEmpty || enableOnly);
      return [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        PrimaryOutlinedButton.icon(
          onPressed: canStart ? _start : null,
          icon: Icon(enableOnly ? Icons.check_circle_outline : Icons.download),
          label: Text(
            enableOnly
                ? 'Enable installed mods'
                : selected.isEmpty
                ? 'Install'
                : 'Install ${selected.length} ${selected.length == 1 ? 'mod' : 'mods'}',
          ),
        ),
      ];
    }

    return [
      if (!active.complete)
        OutlinedButton(
          onPressed: active.stopping
              ? null
              : () => ref
                    .read(modpackInstallationProvider.notifier)
                    .stop(active.packId),
          child: const Text('Stop'),
        ),
      PrimaryOutlinedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ];
  }
}

class ModpackRunProgress extends StatelessWidget {
  final ModpackInstallRun run;

  const ModpackRunProgress({super.key, required this.run});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .all(8),
    child: Column(
      crossAxisAlignment: .start,
      spacing: 8,
      children: [
        Text(
          run.stopping
              ? (run.complete
                    ? 'Stopped. Completed installs were kept.'
                    : 'Stopping after active work finishes…')
              : '${run.finishedCount} of ${run.results.length} finished${run.complete ? '.' : '…'}',
        ),
        if (!run.complete)
          LinearProgressIndicator(
            value: run.results.isEmpty
                ? null
                : run.finishedCount / run.results.length,
          ),
        if (run.error != null) Text(run.error!),
      ],
    ),
  );
}

Future<void> confirmEnableModpack(
  BuildContext context,
  WidgetRef ref,
  ModpackLibraryEntry entry,
) async {
  final manager = ref.read(modpackInstallationProvider.notifier);
  if (await showConfirmDialog(
    context,
    title: 'Enable installed items?',
    message:
        'Enable every installed mod in ${entry.definition.name}? Normal dependency checks apply.',
    confirmLabel: 'Enable',
  )) {
    try {
      await manager.enableInstalled(entry.definition);
    } catch (error) {
      if (context.mounted) {
        await showAlertDialog(
          context,
          title: 'Could not enable mods',
          content: modpackErrorText(error),
        );
      }
    }
  }
}
