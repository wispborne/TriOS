import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/modpacks/full_page/modpack_full_page.dart';
import 'package:trios/modpacks/incoming/incoming_modpack.dart';
import 'package:trios/modpacks/incoming/modpack_comparison.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/widgets/moving_tooltip.dart';

class IncomingModpackResult {
  final String packId;
  final bool openDraft;
  const IncomingModpackResult(this.packId, {this.openDraft = false});
}

enum _ConflictChoice { replace, copy }

class IncomingModpackDialog extends ConsumerStatefulWidget {
  final ModpackDefinition definition;
  final IncomingModpackFetch? fetch;
  const IncomingModpackDialog({
    super.key,
    required this.definition,
    this.fetch,
  });

  @override
  ConsumerState<IncomingModpackDialog> createState() =>
      _IncomingModpackDialogState();
}

class _IncomingModpackDialogState extends ConsumerState<IncomingModpackDialog> {
  late final IncomingModpackSession session;
  String? error;
  @override
  void initState() {
    super.initState();
    session = IncomingModpackSession(
      widget.definition,
      fetch:
          widget.fetch ??
          (url, cancellation) =>
              fetchHostedModpack(ref.read(triOSHttpClient), url, cancellation),
    );
    session.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (session.acting) return;
    final snapshot = session.beginAction();
    setState(() => error = null);
    try {
      final ModpacksData data =
          ref.read(modpackStoreProvider).value ??
          (await ref.read(modpackStoreProvider.future));
      if (!mounted) return;
      final match = matchIncomingModpack(snapshot, data);
      if (match == .saved || match == .draft) {
        Navigator.of(
          context,
        ).pop(IncomingModpackResult(snapshot.id, openDraft: match == .draft));
        return;
      }
      final existing = data.packs[snapshot.id];
      final draft = data.drafts[snapshot.id];
      var choice = _ConflictChoice.replace;
      if (match == .savedConflict || match == .draftConflict) {
        final selected = await showDialog<_ConflictChoice>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              draft == null
                  ? 'This modpack is already saved'
                  : 'This modpack has an unsaved draft',
            ),
            content: SizedBox(
              width: 700,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 16,
                  children: [
                    if (draft != null)
                      const Text(
                        'Replacing this pack discards your unsaved draft.',
                      ),
                    ModpackComparison(
                      incoming: snapshot,
                      saved: existing?.definition,
                      draft: draft,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _ConflictChoice.copy),
                child: const Text('Add as copy'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, _ConflictChoice.replace),
                child: Text(
                  draft == null
                      ? 'Replace existing'
                      : 'Discard draft and replace',
                ),
              ),
            ],
          ),
        );
        if (selected == null || !mounted) return;
        choice = selected;
      }
      final store = ref.read(modpackStoreProvider.notifier);
      final entry = choice == .copy
          ? await store.saveIncomingDefinitionAsCopy(snapshot)
          : await store.acceptIncomingDefinition(
              snapshot,
              expectedEntry: existing,
              expectedDraft: draft,
              discardDraft: draft != null,
            );
      if (mounted) {
        Navigator.of(context).pop(IncomingModpackResult(entry.definition.id));
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      session.endAction();
    }
  }

  Future<void> _reviewOnline() async {
    final online = session.online;
    if (online == null) return;
    final selected = session.selected;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review online modpack'),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: .start,
              spacing: 16,
              children: [
                if (selected.updateUrl != online.updateUrl)
                  Text(
                    'The update address changes to ${online.updateUrl ?? 'Not set'}. Using this definition accepts that change.',
                  ),
                ModpackComparison(incoming: online, saved: selected),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep embedded definition'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Use online definition'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) session.selectOnline();
  }

  @override
  Widget build(BuildContext context) {
    final definition = session.selected;
    return Dialog(
      insetPadding: const .all(24),
      child: SizedBox(
        width: 1200,
        height: 760,
        child: ModpackFullPage(
          key: ValueKey(definition),
          entry: ModpackLibraryEntry(definition: definition),
          onBack: () => Navigator.pop(context),
          onEdit: () {},
          onDuplicate: () async {},
          onDelete: () async {},
          previewToolbar: Padding(
            padding: const .all(8),
            child: Column(
              crossAxisAlignment: .start,
              spacing: 8,
              children: [
                Text(
                  '${definition.name} · v${definition.version}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SelectableText(
                  'Homepage: ${definition.homepageUrl ?? 'Not set'}\nUpdate address: ${definition.updateUrl ?? 'Not set'}',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: session.acting ? null : _add,
                      child: const Text('Add to library'),
                    ),
                    MovingTooltipWidget.text(
                      message: 'Modpack installation is not available yet.',
                      child: const TextButton(
                        onPressed: null,
                        child: Text('Install'),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          session.acting ||
                              session.checking ||
                              definition.updateUrl == null
                          ? null
                          : session.checkForUpdate,
                      child: Text(
                        session.checking ? 'Checking…' : 'Check for update',
                      ),
                    ),
                    if (session.online != null)
                      TextButton(
                        onPressed: session.acting ? null : _reviewOnline,
                        child: const Text('Review online definition'),
                      ),
                    TextButton(
                      onPressed: session.acting
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                if (session.message != null) Text(session.message!),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
