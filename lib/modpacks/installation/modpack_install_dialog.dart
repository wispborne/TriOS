import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/modpacks/full_page/modpack_full_page.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/widgets/checkbox_with_label.dart';

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
      child: SizedBox(
        width: 1300,
        height: 800,
        child: prepared == null && active == null
            ? Padding(
                padding: const .all(24),
                child: Column(
                  mainAxisSize: .min,
                  spacing: 16,
                  children: [
                    Text(error ?? 'Preparing ${widget.entry.definition.name}…'),
                    if (error == null) const LinearProgressIndicator(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              )
            : ModpackFullPage(
                entry: widget.entry,
                onBack: () => Navigator.pop(context),
                checkedItemKeys: active == null ? selected : null,
                onCheckedItemsChanged: active == null
                    ? (keys) => setState(() {
                        selected = keys.intersection(
                          prepared!.items
                              .where((c) => c.installable)
                              .map((c) => c.row.key)
                              .toSet(),
                        );
                      })
                    : null,
                installationDetails:
                    active?.results ??
                    {
                      for (final c in prepared!.items)
                        c.row.key: ModpackItemInstallResult(
                          c.error == null &&
                                  (c.recoverySource != null ||
                                      widget.entry.itemFailures[c.row.key] ==
                                          null)
                              ? .queued
                              : .failed,
                          detail:
                              c.error ??
                              (c.recoverySource == null
                                  ? widget
                                        .entry
                                        .itemFailures[c.row.key]
                                        ?.message
                                  : null) ??
                              (c.recoverySource != null
                                  ? 'Catalog: ${c.recoverySource!.catalogName}'
                                  : 'Ready'),
                        ),
                    },
                onRecoverItem: active == null && !recovering ? _recover : null,
                previewToolbar: Padding(
                  padding: const .all(8),
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: 8,
                    children: [
                      Text(
                        active == null
                            ? 'Install ${widget.entry.definition.name}'
                            : widget.entry.definition.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (active == null) ...[
                        const Text(
                          'Choose mods to install. Labels and dependency warnings are advisory. Expand a row to read its source and notes.',
                        ),
                        CheckboxWithLabel(
                          value: enable,
                          onChanged: (value) =>
                              setState(() => enable = value == true),
                          label: 'Enable installed items after installation',
                        ),
                      ] else
                        ModpackRunProgress(run: active),
                      if (error != null)
                        Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      Row(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(active == null ? 'Cancel' : 'Close'),
                          ),
                          if (active == null)
                            FilledButton(
                              onPressed:
                                  recovering || (selected.isEmpty && !enable)
                                  ? null
                                  : () {
                                      try {
                                        final started = ref
                                            .read(
                                              modpackInstallationProvider
                                                  .notifier,
                                            )
                                            .start(
                                              prepared!,
                                              selected,
                                              enableAfterInstallation: enable,
                                            );
                                        setState(() {
                                          run = started;
                                          error = null;
                                        });
                                      } catch (e) {
                                        setState(
                                          () => error = modpackErrorText(e),
                                        );
                                      }
                                    },
                              child: Text('Install ${selected.length} mods'),
                            )
                          else if (!active.complete)
                            TextButton(
                              onPressed: active.stopping
                                  ? null
                                  : () => ref
                                        .read(
                                          modpackInstallationProvider.notifier,
                                        )
                                        .stop(active.packId),
                              child: const Text('Stop'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
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
