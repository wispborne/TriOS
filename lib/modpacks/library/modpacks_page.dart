import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/modpacks/library/modpack_card.dart';
import 'package:trios/modpacks/library/modpack_card_data.dart';
import 'package:trios/modpacks/library/modpacks_page_controller.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/collapsed_filter_button.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_widget.dart';
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
      return _OpenPackPlaceholder(
        card: state.allCards.firstWhereOrNull((c) => c.packId == openPackId),
        isEditing: state.isEditing,
        onBack: controller.closePack,
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
                color: Theme.of(context).colorScheme.primary,
              ),
              label: 'New modpack',
              onPressed: () => controller.createNewPack(),
            ),
            const SizedBox(width: 8),
            _toolbarButton(
              tooltip: 'Add a .trios-modpack file to your library.',
              icon: SvgImageIcon(
                'assets/images/icon-import-horiz.svg',
                width: 20,
                height: 20,
                color: Theme.of(context).colorScheme.primary,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start with an empty library?'),
        content: Text(
          'The unreadable file stays at ${problem.keptCopy.path} in case '
          'you want to recover it by hand.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start empty'),
          ),
        ],
      ),
    );
    if (confirmed == true) await store.startEmptyLibrary();
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete modpack?'),
        content: Text('$question\n\nNo mods will be disabled or uninstalled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deletePack(card.packId);
  }

  Future<void> _importFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['trios-modpack', 'json', 'hjson'],
      dialogTitle: 'Import modpack',
    );
    final path = picked?.files.firstOrNull?.path;
    if (path == null) return;

    final controller = ref.read(modpacksPageControllerProvider.notifier);
    final result = await controller.importFile(File(path));
    if (!mounted) return;

    switch (result.outcome) {
      case ModpackImportOutcome.added:
        showSnackBar(
          context: context,
          content: const Text('Modpack added to your library.'),
        );
      case ModpackImportOutcome.alreadyInLibrary:
        showSnackBar(
          context: context,
          type: SnackBarType.info,
          content: const Text('That modpack is already in your library.'),
        );
        controller.viewPack(result.packId!);
      case ModpackImportOutcome.conflictsWithLibrary:
        showSnackBar(
          context: context,
          type: SnackBarType.warn,
          content: const Text(
            'Your library already has a different version of this modpack. '
            'Delete it first to import this file.',
          ),
        );
      case ModpackImportOutcome.unreadable:
        showSnackBar(
          context: context,
          type: SnackBarType.error,
          content: Text(
            'Could not read that file as a modpack: ${result.error}',
          ),
        );
    }
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
            Text(
              'A modpack is a list of mods and where to download them. '
              'Build one from your installed mods, then share it as a link '
              'or a file.',
              textAlign: .center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              mainAxisSize: .min,
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onNew,
                  icon: const Icon(Icons.add),
                  label: const Text('New modpack'),
                ),
                OutlinedButton.icon(
                  onPressed: onImport,
                  icon: SvgImageIcon(
                    'assets/images/icon-import-horiz.svg',
                    width: 20,
                    height: 20,
                    color: theme.colorScheme.primary,
                  ),
                  label: const Text('Import modpack'),
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

/// Temporary placeholder for unimplemented pack views.
class _OpenPackPlaceholder extends StatelessWidget {
  final ModpackCardData? card;
  final bool isEditing;
  final VoidCallback onBack;

  const _OpenPackPlaceholder({
    required this.card,
    required this.isEditing,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = card?.name.isNotEmpty == true ? card!.name : 'Unnamed modpack';
    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const .all(8),
          child: Row(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              Text(name, style: theme.textTheme.titleLarge),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              isEditing
                  ? 'The modpack editor is not built yet.'
                  : 'The full modpack page is not built yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
