import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/mod_manager/homebrew_grid/mod_grid_columns.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_records/mod_records_store.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/modpacks/editor/modpack_editor_logic.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/labeled_text_field.dart';
import 'package:trios/widgets/mod_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';
import 'package:trios/widgets/simple_data_row.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';

class ModpackEditor extends ConsumerStatefulWidget {
  final String packId;
  final VoidCallback onBack;
  final ValueChanged<String> onSaved;

  const ModpackEditor({
    super.key,
    required this.packId,
    required this.onBack,
    required this.onSaved,
  });

  @override
  ConsumerState<ModpackEditor> createState() => _ModpackEditorState();
}

class _EditorRow implements WispGridItem {
  @override
  final String key;
  final ModpackDraftItem item;
  const _EditorRow(this.key, this.item);
}

enum _SaveChoice { copy, update }

class _ModpackEditorState extends ConsumerState<ModpackEditor> {
  ModpackDraft? _draft;
  List<_EditorRow> _rowsBacking = [];

  /// Each row's position, so sorting and the Issues cell can look a row up
  /// instead of scanning the list. Rebuilt only when the rows change.
  Map<String, int> _orderByKey = const {};

  List<_EditorRow> get _rows => _rowsBacking;

  set _rows(List<_EditorRow> value) {
    _rowsBacking = value;
    _orderByKey = {
      for (var i = 0; i < value.length; i++) value[i].key: i,
    };
  }
  int _nextRowKey = 0;
  bool _fieldsExpanded = true;
  bool _busy = false;
  String? _error;
  String _installedSearch = '';
  String _packSearch = '';
  Set<String> _installedSelection = {};
  Set<String> _packSelection = {};
  final Set<String> _expanded = {};
  Future<void> _pendingSave = Future.value();

  String get _installedDrag => 'modpack:${widget.packId}:installed';
  String get _packDrag => 'modpack:${widget.packId}:items';
  ModpackStore get _store => ref.read(modpackStoreProvider.notifier);

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      await ref.read(modpackStoreProvider.future);
      if (!mounted) return;
      final draft = await _store.openDraft(widget.packId);
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _rows = [
          for (final item in draft?.items ?? <ModpackDraftItem>[])
            _newRow(item),
        ];
        _fieldsExpanded =
            draft == null ||
            !draft.isCommittable ||
            ref.read(modpackStoreProvider).value?.packs[widget.packId] == null;
        if (draft == null) {
          _error = 'This modpack is no longer in your library.';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not open this modpack: $e');
    }
  }

  _EditorRow _newRow(ModpackDraftItem item) =>
      _EditorRow('${_nextRowKey++}', item);

  void _change(ModpackDraft draft) {
    setState(() => _draft = draft);
    // Capture the store now so Back may dispose this page while a write waits.
    final store = _store;
    _pendingSave = _pendingSave.then((_) => store.saveDraft(draft)).catchError((
      Object error,
    ) {
      if (mounted) {
        setState(() => _error = 'Could not autosave this draft: $error');
      }
    });
  }

  void _setRows(List<_EditorRow> rows) {
    _rows = rows;
    final keys = rows.map((row) => row.key).toSet();
    _packSelection = _packSelection.intersection(keys);
    _expanded.removeWhere((key) => !keys.contains(key));
    _change(_draft!.copyWith(items: rows.map((row) => row.item).toList()));
  }

  void _editItem(_EditorRow row, ModpackDraftItem item) => _setRows([
    for (final current in _rows)
      current.key == row.key ? _EditorRow(row.key, item) : current,
  ]);

  Future<void> _addVariants(Iterable<ModVariant> variants) async {
    final chosen = variants.toList();
    final records = await ref.read(modRecordsStore.future);
    if (!mounted || _busy) return;
    final ids = _rows.map((row) => row.item.modId).toSet();
    _setRows([
      ..._rows,
      for (final variant in chosen)
        if (ids.add(variant.modInfo.id))
          _newRow(
            discoverModpackItem(variant, records.records[variant.modInfo.id]),
          ),
    ]);
  }

  void _addIds(List<String> ids) {
    final mods = ref.read(AppState.mods);
    _addVariants(
      mods
          .where((mod) => ids.contains(mod.id))
          .map((mod) => mod.findFirstEnabledOrHighestVersion)
          .nonNulls,
    );
  }

  Future<void> _remove(Set<String> keys) async {
    final removedIds = _rows
        .where((row) => keys.contains(row.key))
        .map((row) => row.item.modId)
        .toSet();
    final remainingIds = _rows
        .where((row) => !keys.contains(row.key))
        .map((row) => row.item.modId)
        .toSet();
    final dependents = ref
        .read(AppState.mods)
        .where(
          (mod) =>
              remainingIds.contains(mod.id) &&
              (mod.findFirstEnabledOrHighestVersion?.modInfo.dependencies.any(
                    (dep) => removedIds.contains(dep.id),
                  ) ??
                  false),
        )
        .toList();
    if (dependents.isNotEmpty &&
        !await _confirm(
          'Remove required mods?',
          '${dependents.map((mod) => mod.name).join(', ')} require mods you are removing. You can still save this pack.',
          'Remove',
        )) {
      return;
    }
    if (mounted) {
      _setRows(_rows.where((row) => !keys.contains(row.key)).toList());
    }
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _save() async {
    if (_busy || _draft?.isCommittable != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _pendingSave;
      if (!mounted) return;
      await _store.saveDraft(_draft!);
      if (!mounted) return;
      final saved = ref
          .read(modpackStoreProvider)
          .value
          ?.packs[widget.packId]
          ?.definition;
      _SaveChoice choice = .update;
      if (saved?.updateUrl != null &&
          !modpackSharedContentMatches(
            _draft!.toDefinition(version: saved!.version),
            saved,
          )) {
        final answer = await showDialog<_SaveChoice>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save changes to a hosted modpack?'),
            content: const Text(
              'Save as a new modpack to create your own copy without the original update address, or update this modpack while keeping its ID and update address.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _SaveChoice.copy),
                child: const Text('Save as a new modpack'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _SaveChoice.update),
                child: const Text('Update this modpack'),
              ),
            ],
          ),
        );
        if (answer == null || !mounted) return;
        choice = answer;
      }
      final entry = choice == .copy
          ? await _store.commitDraftAsNewPack(widget.packId)
          : await _store.commitDraft(widget.packId);
      if (mounted) widget.onSaved(entry.definition.id);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save this modpack: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discard() async {
    if (!await _confirm(
      'Discard changes?',
      'Your draft edits will be lost. No installed mods will change.',
      'Discard changes',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await _pendingSave;
      if (!mounted) return;
      await _store.discardDraft(widget.packId);
      if (mounted) widget.onBack();
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not discard this draft: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    if (draft == null) {
      return Column(
        children: [
          TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
          Expanded(
            child: Center(
              child: _error == null
                  ? const ThemedCircularProgressIndicator()
                  : Text(_error!),
            ),
          ),
        ],
      );
    }
    final mods = ref.watch(AppState.mods);
    final dependencies = findModpackDependencies(draft.items, mods);
    final byId = {for (final mod in mods) mod.id: mod};
    final installed = mods
        .where(
          (mod) =>
              '${mod.name} ${mod.id} ${mod.findFirstEnabledOrHighestVersion?.modInfo.author ?? ''}'
                  .toLowerCase()
                  .contains(_installedSearch.toLowerCase()),
        )
        .toList();
    final visible = _rows
        .where(
          (row) =>
              '${row.item.displayName} ${row.item.modId} ${row.item.label ?? ''}'
                  .toLowerCase()
                  .contains(_packSearch.toLowerCase()),
        )
        .toList();
    final normalColumns = ModGridColumns(
      ref: ref,
      theme: Theme.of(context),
      modsMetadata: ref.watch(AppState.modsMetadata).value,
      isGameRunning: ref.watch(AppState.isGameRunning).value == true,
      allMods: mods,
      vramEstState: ref.watch(AppState.vramEstimatorProvider),
      loadOrderNumberLookupByModId: const {},
    ).build();
    final settings = ref.watch(appSettings);
    return AbsorbPointer(
      absorbing: _busy,
      child: Column(
        children: [
          _header(draft),
          if (_error != null)
            Padding(
              padding: const .all(8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (dependencies.warnings.isNotEmpty)
            Padding(
              padding: const .symmetric(horizontal: 16, vertical: 8),
              child: Row(
                spacing: 8,
                children: [
                  MovingTooltipWidget.text(
                    message: dependencies.warnings.join('\n'),
                    child: Row(
                      spacing: 8,
                      children: [
                        const Icon(Icons.warning_amber, size: 18),
                        Text(
                          '${dependencies.warnings.length} dependency warnings',
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: TextButton(
                      onPressed: dependencies.available.isEmpty
                          ? null
                          : () async {
                              if (await _confirm(
                                'Add required dependencies?',
                                dependencies.available
                                    .map((v) => v.modInfo.nameOrId)
                                    .join('\n'),
                                'Add required dependencies',
                              )) {
                                if (mounted) {
                                  await _addVariants(dependencies.available);
                                }
                              }
                            },
                      child: const Text('Add required dependencies'),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Row(
              crossAxisAlignment: .stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _listToolbar(
                        'Installed mods',
                        _installedSearch,
                        (value) => setState(() => _installedSearch = value),
                        [
                          TextButton.icon(
                            onPressed: _installedSelection.isEmpty
                                ? null
                                : () => _addIds(_installedSelection.toList()),
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: const Text('Add selected'),
                          ),
                        ],
                      ),
                      Expanded(
                        child: WispGrid<Mod>(
                          items: installed,
                          columns: [
                            for (final column in normalColumns)
                              _installedColumn(column),
                          ],
                          gridState: settings.modpackInstalledGridState,
                          defaultSortField: 'name',
                          updateGridState: (update) => ref
                              .read(appSettings.notifier)
                              .update(
                                (s) => s.copyWith(
                                  modpackInstalledGridState:
                                      update(s.modpackInstalledGridState) ??
                                      const WispGridState(
                                        columnsState: {},
                                        groupingSetting: null,
                                      ),
                                ),
                              ),
                          checkedItemKeys: _installedSelection,
                          onCheckedItemsChanged: (keys) =>
                              setState(() => _installedSelection = keys),
                          rowDragType: _installedDrag,
                          acceptedRowDragTypes: {_packDrag},
                          onRowsDropped: (payload) =>
                              _remove(payload.itemKeys.toSet()),
                          leadingItemWidth: 32,
                          leadingItemBuilder: (mod, _) => Checkbox(
                            value: _installedSelection.contains(mod.id),
                            onChanged: (checked) => setState(() {
                              _installedSelection = {..._installedSelection};
                              checked == true
                                  ? _installedSelection.add(mod.id)
                                  : _installedSelection.remove(mod.id);
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      _listToolbar(
                        '${_rows.length} mods in pack',
                        _packSearch,
                        (value) => setState(() => _packSearch = value),
                        [
                          TextButton(
                            onPressed: _packSelection.isEmpty
                                ? null
                                : () => _remove({..._packSelection}),
                            child: const Text('Remove selected'),
                          ),
                          _labelMenu(
                            null,
                            (label) => _setRows([
                              for (final row in _rows)
                                _packSelection.contains(row.key)
                                    ? _EditorRow(
                                        row.key,
                                        row.item.copyWith(label: label),
                                      )
                                    : row,
                            ]),
                            enabled: _packSelection.isNotEmpty,
                            title: 'Set label',
                          ),
                          _iconAction(
                            'Expand all',
                            Icons.unfold_more,
                            () => setState(
                              () => _expanded.addAll(visible.map((r) => r.key)),
                            ),
                          ),
                          _iconAction(
                            'Collapse all',
                            Icons.unfold_less,
                            () => setState(
                              () => _expanded.removeAll(
                                visible.map((r) => r.key),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: WispGrid<_EditorRow>(
                          items: visible,
                          columns: _itemColumns(byId, normalColumns),
                          gridState: settings.modpackItemsGridState.copyWith(
                            sortedColumnKey: null,
                            groupingSetting: null,
                          ),
                          updateGridState: (update) => ref
                              .read(appSettings.notifier)
                              .update(
                                (s) => s.copyWith(
                                  modpackItemsGridState:
                                      (update(s.modpackItemsGridState) ??
                                              const WispGridState(
                                                columnsState: {},
                                                groupingSetting: null,
                                              ))
                                          .copyWith(
                                            sortedColumnKey: null,
                                            groupingSetting: null,
                                          ),
                                ),
                              ),
                          preSortComparator: (a, b) => (_orderByKey[a.key] ?? 0)
                              .compareTo(_orderByKey[b.key] ?? 0),
                          checkedItemKeys: _packSelection,
                          onCheckedItemsChanged: (keys) =>
                              setState(() => _packSelection = keys),
                          acceptedRowDragTypes: {_installedDrag},
                          onRowsDropped: (payload) => _addIds(payload.itemKeys),
                          leadingItemWidth: 88,
                          leadingItemBuilder: (row, _) => Row(
                            children: [
                              Checkbox(
                                value: _packSelection.contains(row.key),
                                onChanged: (checked) => setState(() {
                                  _packSelection = {..._packSelection};
                                  checked == true
                                      ? _packSelection.add(row.key)
                                      : _packSelection.remove(row.key);
                                }),
                              ),
                              Draggable<WispGridDragPayload>(
                                data: WispGridDragPayload(
                                  itemKeys: _packSelection.contains(row.key)
                                      ? _packSelection.toList()
                                      : [row.key],
                                  dragDataType: _packDrag,
                                ),
                                feedback: Material(
                                  child: Padding(
                                    padding: const .all(8),
                                    child: Text(row.item.displayName),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.drag_indicator,
                                  size: 16,
                                ),
                              ),
                              SizedBox(
                                width: 24,
                                child: _iconAction(
                                  _expanded.contains(row.key)
                                      ? 'Collapse details'
                                      : 'Expand details',
                                  _expanded.contains(row.key)
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  () => setState(() {
                                    _expanded.contains(row.key)
                                        ? _expanded.remove(row.key)
                                        : _expanded.add(row.key);
                                  }),
                                ),
                              ),
                            ],
                          ),
                          rowBuilder:
                              ({
                                required item,
                                required modifiers,
                                required child,
                              }) => DragTarget<WispGridDragPayload>(
                                onWillAcceptWithDetails: (details) =>
                                    details.data.dragDataType == _packDrag,
                                onAcceptWithDetails: (details) => _reorder(
                                  details.data.itemKeys.toSet(),
                                  item.key,
                                ),
                                builder: (context, candidates, rejected) =>
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color:
                                            _expanded.contains(item.key) ||
                                                modifiers.isHovering
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .onInverseSurface
                                                  .withValues(alpha: 0.2)
                                            : null,
                                        border: candidates.isEmpty
                                            ? null
                                            : Border(
                                                top: BorderSide(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  width: 2,
                                                ),
                                              ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: .stretch,
                                        children: [
                                          child,
                                          if (_expanded.contains(item.key))
                                            _details(
                                              item,
                                              byId[item.item.modId],
                                            ),
                                        ],
                                      ),
                                    ),
                              ),
                        ),
                      ),
                      DragTarget<WispGridDragPayload>(
                        onWillAcceptWithDetails: (details) =>
                            details.data.dragDataType == _packDrag,
                        onAcceptWithDetails: (details) =>
                            _reorder(details.data.itemKeys.toSet(), null),
                        builder: (context, candidates, rejected) => SizedBox(
                          height: 24,
                          width: double.infinity,
                          child: Center(
                            child: Text(
                              candidates.isEmpty
                                  ? 'Drag mods here to add, or use the handles to reorder.'
                                  : 'Move to end',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _reorder(Set<String> keys, String? beforeKey) {
    final before = beforeKey == null
        ? _rows.length
        : _rows.indexWhere((row) => row.key == beforeKey);
    _setRows(
      moveModpackItems(_rows, {
        for (var i = 0; i < _rows.length; i++)
          if (keys.contains(_rows[i].key)) i,
      }, before),
    );
  }

  Widget _header(ModpackDraft draft) {
    final valid = draft.isCommittable;
    final version = valid ? _store.versionAfterSaving(draft) : null;
    return Padding(
      padding: const .fromLTRB(8, 8, 8, 0),
      child: Card(
        margin: .zero,
        child: Padding(
          padding: const .all(8),
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: 8,
            children: [
              SingleChildScrollView(
                scrollDirection: .horizontal,
                child: Row(
                  spacing: 8,
                  children: [
                    _action('Back', Icons.arrow_back, widget.onBack),
                    Text(
                      draft.name.trim().isEmpty ? 'New modpack' : draft.name,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontSize: 20),
                    ),
                    _action(
                      'Save changes${version == null ? '' : ' · v$version'}',
                      Icons.save_outlined,
                      valid ? _save : null,
                    ),
                    _action('Discard changes', Icons.undo, _discard),
                    _action(
                      'Pack details',
                      _fieldsExpanded ? Icons.expand_less : Icons.expand_more,
                      () => setState(() => _fieldsExpanded = !_fieldsExpanded),
                    ),
                  ],
                ),
              ),
              if (_fieldsExpanded)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 248),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const .all(8),
                      child: Column(
                        spacing: 16,
                        children: [
                          Row(
                            crossAxisAlignment: .start,
                            spacing: 16,
                            children: [
                              Expanded(
                                child: _DraftField(
                                  label: 'Name',
                                  value: draft.name,
                                  maxLength: ModpackLimits.maxNameLength,
                                  error: draft.name.trim().isEmpty
                                      ? 'Enter a name.'
                                      : null,
                                  onChanged: (s) =>
                                      _change(_draft!.copyWith(name: s)),
                                ),
                              ),
                              Expanded(
                                child: _DraftField(
                                  label: 'Curated by',
                                  value: draft.author,
                                  maxLength: ModpackLimits.maxAuthorLength,
                                  onChanged: (s) => _change(
                                    _draft!.copyWith(author: _optional(s)),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _DraftField(
                                  label: 'Starsector version',
                                  value: draft.gameVersion,
                                  maxLength: ModpackLimits.maxGameVersionLength,
                                  onChanged: (s) => _change(
                                    _draft!.copyWith(gameVersion: _optional(s)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _DraftField(
                            label: 'Description',
                            value: draft.description,
                            maxLength: ModpackLimits.maxDescriptionLength,
                            maxLines: 3,
                            onChanged: (s) => _change(
                              _draft!.copyWith(description: _optional(s)),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: .start,
                            spacing: 16,
                            children: [
                              Expanded(
                                child: _DraftField(
                                  label: 'Homepage',
                                  value: draft.homepageUrl,
                                  maxLength: ModpackLimits.maxUrlLength,
                                  error: _urlError(
                                    draft.homepageUrl,
                                    optional: true,
                                  ),
                                  onChanged: (s) => _change(
                                    _draft!.copyWith(homepageUrl: _optional(s)),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _DraftField(
                                  label: 'Update URL',
                                  value: draft.updateUrl,
                                  maxLength: ModpackLimits.maxUrlLength,
                                  error: _urlError(
                                    draft.updateUrl,
                                    optional: true,
                                  ),
                                  onChanged: (s) => _change(
                                    _draft!.copyWith(updateUrl: _optional(s)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!_fieldsExpanded)
                Padding(
                  padding: const .all(8),
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: 8,
                    children: [
                      if (draft.description?.isNotEmpty == true)
                        TextTriOS(
                          draft.description!,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      Wrap(
                        spacing: 24,
                        runSpacing: 8,
                        children: [
                          SimpleDataRow(
                            label: 'Curated by: ',
                            value: draft.author ?? 'Not set',
                          ),
                          SimpleDataRow(
                            label: 'Starsector version: ',
                            value: draft.gameVersion ?? 'Not set',
                          ),
                          if (draft.homepageUrl != null)
                            SimpleDataRow(
                              label: 'Homepage: ',
                              value: draft.homepageUrl!,
                            ),
                          if (draft.updateUrl != null)
                            SimpleDataRow(
                              label: 'Update URL: ',
                              value: draft.updateUrl!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              Text(
                valid
                    ? 'Draft saved automatically. Save changes adds it to your library.'
                    : draft.items.isEmpty
                    ? 'Add mods to this pack. Your draft is saved automatically.'
                    : 'Complete the highlighted fields and mod sources to save. Your draft is saved automatically.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listToolbar(
    String title,
    String search,
    ValueChanged<String> onSearch,
    List<Widget> actions,
  ) => Padding(
    padding: const .all(8),
    child: Column(
      crossAxisAlignment: .stretch,
      spacing: 8,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        _DraftField(label: 'Search $title', value: search, onChanged: onSearch),
        SingleChildScrollView(
          scrollDirection: .horizontal,
          child: Row(spacing: 8, children: actions),
        ),
      ],
    ),
  );

  // Rebuilt field by field rather than with copyWith: the generated copyWith
  // on this generic class returns WispGridColumn<WispGridItem>, losing <Mod>.
  WispGridColumn<Mod> _installedColumn(WispGridColumn<Mod> column) =>
      WispGridColumn<Mod>(
        key: column.key,
        name: column.name,
        isSortable: column.isSortable,
        getSortValue: column.getSortValue,
        headerCellBuilder: column.headerCellBuilder,
        itemCellBuilder: column.itemCellBuilder,
        csvValue: column.csvValue,
        defaultState: column.defaultState.copyWith(
          width: column.key == 'version' ? 120 : column.defaultState.width,
          isVisible: {
            'icons',
            'name',
            'author',
            'version',
          }.contains(column.key),
        ),
      );

  List<WispGridColumn<_EditorRow>> _itemColumns(
    Map<String, Mod> mods,
    List<WispGridColumn<Mod>> normal,
  ) {
    // Validating the whole draft is a full pass over every item, so it runs
    // once here rather than inside the Issues cell for each rendered row.
    final issueCountByIndex = <int, int>{};
    for (final issue in _draft?.issues ?? const []) {
      final index = issue.itemIndex;
      if (index != null) {
        issueCountByIndex[index] = (issueCountByIndex[index] ?? 0) + 1;
      }
    }
    final columns = <WispGridColumn<_EditorRow>>[
      _column(
        'icons',
        'Icon',
        32,
        (row) => ModIcon.fromVariant(
          mods[row.item.modId]?.findFirstEnabledOrHighestVersion,
          size: 32,
          takeUpSpaceIfNoIcon: true,
        ),
      ),
      _column(
        'name',
        'Name',
        200,
        (row) => Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextTriOS(
                    row.item.displayName,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: .bold),
                  ),
                ),
                if (row.item.note?.isNotEmpty == true)
                  MovingTooltipWidget.text(
                    message: row.item.note,
                    child: const Icon(Icons.sticky_note_2, size: 14),
                  ),
              ],
            ),
            TextTriOS(
              row.item.modId ?? 'Missing mod ID',
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
      _column(
        'author',
        'Author',
        120,
        (row) => TextTriOS(
          mods[row.item.modId]
                  ?.findFirstEnabledOrHighestVersion
                  ?.modInfo
                  .author ??
              '—',
          maxLines: 1,
        ),
      ),
      _column(
        'label',
        'Label',
        112,
        (row) => TextTriOS(row.item.label ?? '—', maxLines: 1),
      ),
      _column(
        'sourceType',
        'Source type',
        144,
        (row) => TextTriOS(_sourceLabel(row.item.sourceType), maxLines: 1),
      ),
      _column(
        'sourceHost',
        'Source host',
        160,
        (row) => TextTriOS(
          Uri.tryParse(row.item.url ?? '')?.host ?? '',
          maxLines: 1,
        ),
      ),
      _column('issues', 'Issues', 120, (row) {
        final issueCount = issueCountByIndex[_orderByKey[row.key]] ?? 0;
        return issueCount == 0
            ? const SizedBox.shrink()
            : MovingTooltipWidget.text(
                message: 'Expand this mod to complete or repair its fields.',
                child: Row(
                  spacing: 8,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    Expanded(
                      child: TextTriOS('$issueCount issues', maxLines: 1),
                    ),
                  ],
                ),
              );
      }),
    ];
    final keys = columns.map((column) => column.key).toSet();
    for (final column in normal.where((column) => !keys.contains(column.key))) {
      columns.add(
        WispGridColumn<_EditorRow>(
          key: column.key,
          name: column.name,
          isSortable: false,
          csvValue: (row) => mods[row.item.modId] == null
              ? null
              : column.csvValue?.call(mods[row.item.modId]!),
          headerCellBuilder: column.headerCellBuilder,
          itemCellBuilder: (row, modifiers) => mods[row.item.modId] == null
              ? const SizedBox.shrink()
              : column.itemCellBuilder?.call(
                      mods[row.item.modId]!,
                      modifiers,
                    ) ??
                    const SizedBox.shrink(),
          defaultState: column.defaultState.copyWith(
            position: columns.length,
            isVisible: false,
          ),
        ),
      );
    }
    return columns;
  }

  WispGridColumn<_EditorRow> _column(
    String key,
    String name,
    double width,
    Widget Function(_EditorRow) cell,
  ) => WispGridColumn<_EditorRow>(
    key: key,
    name: name,
    isSortable: false,
    csvValue: null,
    headerCellBuilder: (_) => Text(
      name,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: .bold),
    ),
    itemCellBuilder: (row, _) => cell(row),
    defaultState: WispGridColumnState(
      position: [
        'icons',
        'name',
        'author',
        'label',
        'sourceType',
        'sourceHost',
        'issues',
      ].indexOf(key),
      width: width,
    ),
  );

  Widget _details(_EditorRow row, Mod? mod) {
    final item = row.item;
    return Padding(
      padding: const .fromLTRB(24, 8, 24, 16),
      child: Align(
        alignment: .centerLeft,
        child: SizedBox(
          width: 440,
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: 16,
            children: [
              _DraftField(
                key: ValueKey('${row.key}:id'),
                label: 'Mod ID',
                value: item.modId,
                maxLength: ModpackLimits.maxModIdLength,
                error: item.modId?.trim().isNotEmpty != true
                    ? 'Enter the mod_info.json ID.'
                    : _rows.any(
                        (other) =>
                            other.key != row.key &&
                            other.item.modId?.trim() == item.modId?.trim(),
                      )
                    ? 'This mod is already in the pack.'
                    : null,
                onChanged: (s) => _editItem(row, item.copyWith(modId: s)),
              ),
              Row(
                spacing: 8,
                children: [
                  _labelMenu(
                    item.label,
                    (label) => _editItem(row, item.copyWith(label: label)),
                  ),
                  Expanded(
                    child: DropdownButton<ModpackItemSourceType>(
                      value: item.sourceType,
                      isExpanded: true,
                      hint: const Text('Choose source type'),
                      items: [
                        for (final type in ModpackItemSourceType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(_sourceLabel(type)),
                          ),
                      ],
                      onChanged: (type) =>
                          _editItem(row, item.copyWith(sourceType: type)),
                    ),
                  ),
                ],
              ),
              if (item.label != null && modpackLabelError(item.label!) != null)
                Text(
                  modpackLabelError(item.label!)!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              Text(switch (item.sourceType) {
                .versionFile =>
                  'Tracks latest release through Version Checker.',
                .directDownload => 'Fixed download. Publish a new pack version when this address changes.',
                null => 'Choose how TriOS should obtain this mod.',
              }, style: Theme.of(context).textTheme.labelSmall),
              _DraftField(
                key: ValueKey('${row.key}:url'),
                label: 'Download URL',
                value: item.url,
                maxLength: ModpackLimits.maxUrlLength,
                error: _urlError(item.url),
                onChanged: (s) => _editItem(row, item.copyWith(url: s)),
              ),
              _DraftField(
                key: ValueKey('${row.key}:note'),
                label: 'Note',
                value: item.note,
                maxLength: ModpackLimits.maxNoteLength,
                maxLines: 4,
                onChanged: (s) =>
                    _editItem(row, item.copyWith(note: _optional(s))),
              ),
              Row(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: mod == null
                        ? null
                        : () async {
                            final records = await ref.read(
                              modRecordsStore.future,
                            );
                            if (!mounted) return;
                            final current = _rows.firstWhereOrNull(
                              (candidate) => candidate.key == row.key,
                            );
                            final variant =
                                mod.findFirstEnabledOrHighestVersion;
                            if (current == null || variant == null) return;
                            final repaired = discoverModpackItem(
                              variant,
                              records.records[mod.id],
                            );
                            _editItem(
                              current,
                              current.item.copyWith(
                                url: repaired.url,
                                sourceType: repaired.sourceType,
                                catalog: repaired.catalog,
                              ),
                            );
                          },
                    icon: const Icon(Icons.build_outlined, size: 16),
                    label: const Text('Find source again'),
                  ),
                  TextButton.icon(
                    onPressed: () => _remove({row.key}),
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelMenu(
    String? value,
    ValueChanged<String?> onChanged, {
    bool enabled = true,
    String? title,
  }) {
    final labels = {
      ...ModpackItemLabels.standard,
      ..._rows
          .map((row) => row.item.label)
          .nonNulls
          .where((label) => modpackLabelError(label) == null),
    }.toList();
    return PopupMenuButton<int>(
      enabled: enabled,
      tooltip: '',
      onSelected: (selected) async {
        if (selected == -2) {
          final result = await showDialog<String>(
            context: context,
            builder: (context) => const _CustomLabelDialog(),
          );
          if (result != null && mounted) onChanged(result);
        } else {
          onChanged(selected == -1 ? null : labels[selected]);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: -1, child: Text('None')),
        for (var index = 0; index < labels.length; index++)
          PopupMenuItem(value: index, child: Text(labels[index])),
        const PopupMenuItem(value: -2, child: Text('New custom label…')),
      ],
      child: Padding(
        padding: const .all(8),
        child: Text(
          title ?? 'Label: ${value ?? 'None'}',
          style: TextStyle(
            color: enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
          ),
        ),
      ),
    );
  }

  Widget _action(String label, IconData icon, VoidCallback? onPressed) =>
      TriOSToolbarItem(
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label),
        ),
      );
  Widget _iconAction(String label, IconData icon, VoidCallback onPressed) =>
      MovingTooltipWidget.text(
        message: label,
        child: IconButton(
          onPressed: onPressed,
          padding: .zero,
          icon: Icon(icon, size: 18),
        ),
      );
  String? _optional(String value) => value.trim().isEmpty ? null : value;
  String? _urlError(String? value, {bool optional = false}) =>
      value == null || value.trim().isEmpty
      ? (optional ? null : 'Enter a download URL.')
      : isSafeModpackUrl(value)
      ? null
      : 'Enter an HTTP or HTTPS URL.';
  String _sourceLabel(ModpackItemSourceType? type) => switch (type) {
    .versionFile => 'Version Checker',
    .directDownload => 'Fixed download',
    null => 'Needs source',
  };
}

/// Keeps text selection stable while each keystroke autosaves the draft.
class _DraftField extends StatefulWidget {
  final String label;
  final String? value;
  final String? error;
  final int? maxLength;
  final int maxLines;
  final ValueChanged<String> onChanged;
  const _DraftField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.error,
    this.maxLength,
    this.maxLines = 1,
  });
  @override
  State<_DraftField> createState() => _DraftFieldState();
}

class _DraftFieldState extends State<_DraftField> {
  late final _controller = TextEditingController(text: widget.value ?? '');
  @override
  void didUpdateWidget(covariant _DraftField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.value ?? '') != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LabeledTextField(
    controller: _controller,
    label: widget.label,
    errorText: widget.error,
    maxLength: widget.maxLength,
    maxLines: widget.maxLines,
    onChanged: widget.onChanged,
  );
}

class _CustomLabelDialog extends StatefulWidget {
  const _CustomLabelDialog();
  @override
  State<_CustomLabelDialog> createState() => _CustomLabelDialogState();
}

class _CustomLabelDialogState extends State<_CustomLabelDialog> {
  String _value = '';
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New custom label'),
    content: SizedBox(
      width: 320,
      child: _DraftField(
        label: 'Label',
        value: _value,
        maxLength: 40,
        error: _value.isEmpty ? null : modpackLabelError(_value),
        onChanged: (value) => setState(() => _value = value),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: modpackLabelError(_value) != null
            ? null
            : () => Navigator.pop(context, ModpackItemLabels.normalize(_value)),
        child: const Text('Set label'),
      ),
    ],
  );
}
