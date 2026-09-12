import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/modpacks/full_page/modpack_full_page.dart';
import 'package:trios/modpacks/editor/modpack_editor.dart';
import 'package:trios/modpacks/incoming/incoming_modpack_handler.dart';
import 'package:trios/modpacks/library/modpack_card.dart';
import 'package:trios/modpacks/library/modpack_card_data.dart';
import 'package:trios/modpacks/library/modpacks_page_controller.dart';
import 'package:trios/modpacks/modpack_link_codec.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/widgets/collapsed_filter_button.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_widget.dart';
import 'package:trios/widgets/labeled_text_field.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';
import 'package:trios/widgets/smart_search/smart_search_bar.dart';
import 'package:trios/widgets/snackbar.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';
import 'package:trios/widgets/trios_dropdown_menu.dart';
import 'package:trios/widgets/viewer_toolbar.dart';
import 'package:trios/widgets/wisp_adaptive_grid_view.dart';

class ModpacksPage extends ConsumerStatefulWidget {
  const ModpacksPage({super.key});

  @override
  ConsumerState<ModpacksPage> createState() => _ModpacksPageState();
}

class _ModpacksPageState extends ConsumerState<ModpacksPage>
    with AutomaticKeepAliveClientMixin<ModpacksPage> {
  @override
  bool get wantKeepAlive => true;

  final _filterScrollController = ScrollController();
  final _gridScrollController = ScrollController();

  @override
  void dispose() {
    _filterScrollController.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(modpacksPageControllerProvider);
    final controller = ref.read(modpacksPageControllerProvider.notifier);

    final openPackId = state.openPackId;
    if (openPackId != null) {
      final card = state.allCards.firstWhereOrNull(
        (card) => card.packId == openPackId,
      );
      if (!state.isEditing) {
        final entry = ref.watch(modpackStoreProvider).value?.packs[openPackId];
        if (entry == null || card == null) {
          return const Center(child: ThemedCircularProgressIndicator());
        }
        return ModpackFullPage(
          key: ValueKey(openPackId),
          entry: entry,
          onBack: controller.closePack,
          onEdit: () => controller.editPack(openPackId),
          onDuplicate: () async {
            await controller.duplicatePack(openPackId);
            if (!context.mounted) return;
            showSnackBar(
              context: context,
              content: const Text('A copy was added to your library.'),
            );
          },
          onDelete: () => _confirmDelete(card, controller),
        );
      }
      return ModpackEditor(
        key: ValueKey(openPackId),
        packId: openPackId,
        onBack: controller.closePack,
        onSaved: controller.viewPack,
      );
    }

    return Column(
      children: [
        ViewerToolbar(
          entityName: 'modpacks',
          total: state.allCards.length,
          visible: state.visibleCards.length,
          isLoading: state.isLoading,
          onRefresh: controller.refresh,
          searchBox: SmartSearchBar(
            fields: controller.searchFieldsMeta,
            recentHistory: ref.watch(
              appSettings.select((s) => s.modpacksSearchHistory),
            ),
            initialValue: state.searchQuery,
            hintText: 'Search modpacks...',
            onChanged: controller.updateSearchQuery,
            onSubmitted: controller.submitSearchQuery,
          ),
          leadingActions: [
            const SizedBox(width: 8),
            _buildSortControls(controller, state),
          ],
          trailingActions: [
            _toolbarButton(
              icon: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              label: 'Create',
              onPressed: () => controller.createNewPack(),
            ),
            const SizedBox(width: 8),
            _toolbarButton(
              tooltip: 'Add a .trios-modpack file to your library.',
              icon: SvgImageIcon(
                'assets/images/icon-import-horiz.svg',
                width: 20,
                height: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              label: 'Import',
              onPressed: _importFile,
            ),
          ],
        ),
        _buildStorageProblemBanner(),
        Expanded(
          child: Row(
            crossAxisAlignment: .start,
            children: [
              _buildFiltersSection(state, controller),
              Expanded(child: _buildBody(state, controller)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toolbarButton({
    String? tooltip,
    required Widget icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return MovingTooltipWidget.text(
      message: tooltip,
      child: TriOSToolbarItem(
        child: TextButton.icon(
          onPressed: onPressed,
          icon: icon,
          label: Text(label, style: TextStyle(color: textColor)),
        ),
      ),
    );
  }

  Widget _buildSortControls(
    ModpacksPageController controller,
    ModpacksPageState state,
  ) {
    return Row(
      mainAxisSize: .min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: TriOSDropdownMenu<ModpackSortField>(
            initialSelection: state.sortField,
            onSelected: (value) =>
                controller.setSortField(value ?? ModpackSortField.name),
            dropdownMenuEntries: [
              for (final field in ModpackSortField.values)
                DropdownMenuEntry(value: field, label: field.label),
            ],
          ),
        ),
        MovingTooltipWidget.text(
          message: state.sortAscending ? 'Ascending' : 'Descending',
          child: IconButton(
            icon: Icon(
              state.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 20,
            ),
            onPressed: controller.toggleSortDirection,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(
    ModpacksPageState state,
    ModpacksPageController controller,
  ) {
    if (!state.showFilters) {
      return Padding(
        padding: const .only(left: 8, top: 4),
        child: CollapsedFilterButton(
          onTap: controller.toggleShowFilters,
          activeFilterCount: controller.activeFilterCount,
        ),
      );
    }

    return Padding(
      padding: const .only(left: 4, top: 4, bottom: 8),
      child: Card(
        child: FiltersPanel(
          onHide: controller.toggleShowFilters,
          scrollController: _filterScrollController,
          activeFilterCount: controller.activeFilterCount,
          showClearAll: controller.filterGroups.any((g) => g.isActive),
          onClearAll: controller.clearAllFilters,
          filterWidgets: [
            for (final group in controller.filterGroups)
              FilterGroupRenderer<ModpackCardData>(
                group: group,
                scope: controller.scope,
                items: state.allCards,
                onChanged: () => controller.onGroupChanged(group.id),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageProblemBanner() {
    // Rebuild when loading finishes.
    ref.watch(modpackStoreProvider);
    final store = ref.read(modpackStoreProvider.notifier);
    final problem = store.storageProblem;
    if (problem == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const .symmetric(horizontal: 4),
      child: Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const .all(12),
          child: Row(
            spacing: 12,
            children: [
              MovingTooltipWidget.text(
                message: 'Your saved modpacks could not be read.',
                child: Icon(
                  Icons.warning_amber,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              Expanded(
                child: Text(
                  '${problem.message}\n'
                  'A copy of the unreadable file was kept at '
                  '${problem.keptCopy.path}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              if (problem.canRestoreBackup)
                OutlinedButton(
                  onPressed: () async {
                    final restored = await store.restoreBackup();
                    if (!mounted) return;
                    if (!restored) {
                      showSnackBar(
                        context: context,
                        type: SnackBarType.error,
                        content: const Text(
                          'The backup could not be read either.',
                        ),
                      );
                    }
                  },
                  child: const Text('Restore backup'),
                ),
              OutlinedButton(
                onPressed: () => _confirmStartEmpty(store, problem),
                child: const Text('Start empty'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmStartEmpty(
    ModpackStore store,
    ModpackStorageProblem problem,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Start with an empty library?',
      message:
          'The unreadable file stays at ${problem.keptCopy.path} in case '
          'you want to recover it by hand.',
      confirmLabel: 'Start empty',
    );
    if (confirmed) await store.startEmptyLibrary();
  }

  Widget _buildBody(
    ModpacksPageState state,
    ModpacksPageController controller,
  ) {
    if (state.isLoading && state.allCards.isEmpty) {
      return const Center(child: ThemedCircularProgressIndicator());
    }
    if (state.allCards.isEmpty) {
      return _EmptyLibrary(
        onNew: () => controller.createNewPack(),
        onImport: _importFile,
      );
    }
    if (state.visibleCards.isEmpty) {
      return _NoMatches(
        onClearSearch: state.searchQuery.isEmpty
            ? null
            : controller.clearSearch,
        onClearFilters: controller.activeFilterCount == 0
            ? null
            : controller.clearAllFilters,
      );
    }

    return WispAdaptiveGridView<ModpackCardData>(
      controller: _gridScrollController,
      items: state.visibleCards,
      minItemWidth: 300,
      horizontalSpacing: 8,
      verticalSpacing: 8,
      padding: const .all(8),
      itemBuilder: (context, card, index) => SizedBox(
        height: 172,
        child: ModpackCard(
          card: card,
          onOpen: () => controller.openCard(card),
          onEdit: () => controller.editPack(card.packId),
          onDuplicate: card.isDraftOnly
              ? null
              : () => controller.duplicatePack(card.packId),
          onDelete: () => _confirmDelete(card, controller),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    ModpackCardData card,
    ModpacksPageController controller,
  ) async {
    final question = switch ((card.isDraftOnly, card.name.isEmpty)) {
      (true, true) => 'Delete this unsaved modpack? Its draft will be lost.',
      (true, false) =>
        "Delete the unsaved modpack '${card.name}'? Its draft will be lost.",
      (false, true) => 'Delete this modpack from your library?',
      (false, false) => "Delete '${card.name}' from your library?",
    };
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete modpack?',
      message: '$question\n\nNo mods will be disabled or uninstalled.',
      confirmLabel: 'Delete',
    );
    if (confirmed) await controller.deletePack(card.packId);
  }

  /// The dialog returns link text or a file URI; both are inputs the incoming
  /// handler already knows how to read.
  Future<void> _importFile() async {
    final input = await showDialog<String>(
      context: context,
      builder: (context) => const _ImportModpackDialog(),
    );
    if (input == null || !mounted) return;
    await ref
        .read(incomingModpackHandlerProvider)
        .receive(input, context: context);
  }
}

class _ImportModpackDialog extends StatefulWidget {
  const _ImportModpackDialog();

  @override
  State<_ImportModpackDialog> createState() => _ImportModpackDialogState();
}

class _ImportModpackDialogState extends State<_ImportModpackDialog> {
  final _textController = TextEditingController();
  bool _hasLink = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fillFromClipboard();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _fillFromClipboard() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (!mounted || text == null) return;
    if (extractModpackLinkPayload(text) == null) return;
    if (_textController.text.isNotEmpty) return;
    _textController.text = text.trim();
    _onChanged(_textController.text);
  }

  void _onChanged(String text) {
    setState(() {
      _hasLink = extractModpackLinkPayload(text) != null;
      _error = text.trim().isEmpty || _hasLink
          ? null
          : 'That is not a modpack link.';
    });
  }

  Future<void> _chooseFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['trios-modpack', 'json', 'hjson'],
      dialogTitle: 'Import modpack',
    );
    final path = picked?.files.firstOrNull?.path;
    if (path == null || !mounted) return;
    Navigator.of(context).pop(File(path).uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import modpack'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 16,
          children: [
            const Text('Paste a modpack link or choose a .trios-modpack file.'),
            LabeledTextField(
              controller: _textController,
              label: 'Modpack link',
              hint: '$trilinkOpenPageUrl#...',
              errorText: _error,
              maxLines: 3,
              autofocus: true,
              onChanged: _onChanged,
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: _chooseFile,
          icon: const Icon(Icons.folder_open),
          label: const Text('Choose file'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _hasLink
              ? () =>
                    Navigator.of(context)
                        .pop(_textController.text)
              : null,
          child: const Text('Import'),
        ),
      ],
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  final VoidCallback onNew;
  final VoidCallback onImport;

  const _EmptyLibrary({required this.onNew, required this.onImport});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: .min,
          spacing: 16,
          children: [
            Icon(
              Icons.inventory_2,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            Text('No modpacks yet', style: theme.textTheme.titleMedium),
            Row(
              mainAxisSize: .min,
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onNew,
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
                OutlinedButton.icon(
                  onPressed: onImport,
                  icon: SvgImageIcon(
                    'assets/images/icon-import-horiz.svg',
                    width: 20,
                    height: 20,
                  ),
                  label: const Text('Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  final VoidCallback? onClearSearch;
  final VoidCallback? onClearFilters;

  const _NoMatches({this.onClearSearch, this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: .min,
        spacing: 16,
        children: [
          Text('No modpacks match.', style: theme.textTheme.titleMedium),
          Row(
            mainAxisSize: .min,
            spacing: 8,
            children: [
              if (onClearSearch != null)
                OutlinedButton.icon(
                  onPressed: onClearSearch,
                  icon: const Icon(Icons.search_off),
                  label: const Text('Clear search'),
                ),
              if (onClearFilters != null)
                OutlinedButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_list_off),
                  label: const Text('Clear filters'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
