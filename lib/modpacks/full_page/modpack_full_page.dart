import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/mod_manager/homebrew_grid/mod_grid_columns.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/mod_version_selection_dropdown.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/modpacks/full_page/modpack_item_row_data.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/modpacks/modpack_link_codec.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:trios/modpacks/sharing/modpack_share_controller.dart';
import 'package:trios/modpacks/sharing/modpack_source_check_section.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/mod_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/overflow_menu_button.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';
import 'package:trios/widgets/simple_data_row.dart';
import 'package:trios/widgets/snackbar.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';
import 'package:url_launcher/url_launcher.dart';

const _packOrderColumnKey = 'packOrder';

enum _ShareAction { copyLink, export, publish }

class ModpackFullPage extends ConsumerStatefulWidget {
  final ModpackLibraryEntry entry;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final Future<void> Function() onDuplicate;
  final Future<void> Function() onDelete;

  const ModpackFullPage({
    super.key,
    required this.entry,
    required this.onBack,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  ConsumerState<ModpackFullPage> createState() => _ModpackFullPageState();
}

class _ModpackFullPageState extends ConsumerState<ModpackFullPage> {
  WispGridState _gridState = const WispGridState(
    columnsState: {},
    groupingSetting: null,
  );
  final Set<String> _expandedItemIds = {};
  bool _sharing = false;

  Future<void> _share(_ShareAction action) async {
    if (_sharing) return;
    final snapshot = definition;
    if (snapshot.items.isEmpty) {
      showSnackBar(
        context: context,
        content: const Text('Add at least one mod before sharing this pack.'),
      );
      return;
    }
    setState(() => _sharing = true);
    try {
      final ready = await ref
          .read(modpackShareControllerProvider(snapshot.id).notifier)
          .validate(snapshot);
      if (!mounted || !ready) return;
      if (!modpackDefinitionsAreIdentical(snapshot, definition)) return;
      if (action == _ShareAction.copyLink) {
        final link = buildModpackShareLink(snapshot);
        await Clipboard.setData(ClipboardData(text: link));
        if (mounted) {
          showSnackBar(
            context: context,
            content: const Text('Modpack link copied.'),
          );
        }
        return;
      }
      final previous = widget.entry.lastExportPath;
      final slug = snapshot.name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      final chosen = await FilePicker.platform.saveFile(
        dialogTitle: action == _ShareAction.publish
            ? 'Export modpack update'
            : 'Export modpack',
        initialDirectory: previous == null ? null : p.dirname(previous),
        fileName: previous == null
            ? '${slug.isEmpty ? 'modpack' : slug}.trios-modpack'
            : p.basename(previous),
        type: FileType.custom,
        allowedExtensions: ['trios-modpack'],
        lockParentWindow: true,
      );
      if (!mounted || chosen == null) return;
      final file = File(
        chosen.toLowerCase().endsWith('.trios-modpack')
            ? chosen
            : '$chosen.trios-modpack',
      );
      if (await file.exists()) {
        if (!mounted) return;
        final overwrite = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Replace exported modpack?'),
            content: Text('Replace ${file.path}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Replace'),
              ),
            ],
          ),
        );
        if (!mounted || overwrite != true) return;
      }
      if (!modpackDefinitionsAreIdentical(snapshot, definition)) return;
      await file.writeAsString(
        encodeModpackDefinitionFileJson(snapshot),
        flush: true,
      );
      if (!mounted) return;
      await ref
          .read(modpackStoreProvider.notifier)
          .recordExportLocation(snapshot.id, file.path);
      if (!mounted) return;
      showSnackBar(
        context: context,
        content: Text(
          action == _ShareAction.publish
              ? 'Update exported. Upload this file to ${snapshot.updateUrl}.'
              : 'Modpack exported to ${file.path}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message =
          e is ModpackFormatException &&
              e.error == ModpackFormatError.linkTooLarge
          ? 'This pack is too large for a link. Shorten its description or notes, remove mods, or export a .trios-modpack file instead.'
          : 'Could not share this modpack: $e';
      showSnackBar(
        context: context,
        type: SnackBarType.error,
        content: Text(message),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  ModpackDefinition get definition => widget.entry.definition;

  @override
  Widget build(BuildContext context) {
    final allMods = ref.watch(AppState.mods);
    final modCompatibility = ref.watch(AppState.modCompatibility);
    final rows = buildModpackItemRows(definition, allMods, modCompatibility);
    final columns = _buildColumns(allMods);
    final sharing = ref.watch(modpackShareControllerProvider(definition.id));

    return Column(
      children: [
        Padding(
          padding: const .only(top: 8, left: 8, right: 8),
          child: _buildPackHeader(rows),
        ),
        ModpackSourceCheckSection(
          state: sharing,
          onCancel: () => ref
              .read(modpackShareControllerProvider(definition.id).notifier)
              .cancel(),
          onRepair: widget.onEdit,
        ),
        _buildItemsToolbar(rows),
        Expanded(
          child: Padding(
            padding: const .only(top: 4),
            child: WispGrid<ModpackItemRowData>(
              items: rows,
              columns: columns,
              gridState: _gridState,
              defaultSortField: _packOrderColumnKey,
              updateGridState: (update) {
                setState(() {
                  _gridState =
                      update(_gridState) ??
                      const WispGridState(
                        columnsState: {},
                        groupingSetting: null,
                      );
                });
              },
              // WispGrid uses a non-null selected item to opt into single-row
              // callbacks. The full page uses the callback for expansion, not
              // selection.
              selectedItem: rows.isEmpty ? null : rows.first,
              onRowSelected: _toggleExpanded,
              rowBuilder:
                  ({required item, required modifiers, required child}) =>
                      _buildItemRow(
                        item,
                        child,
                        isHovering: modifiers.isHovering,
                      ),
              leadingItemBuilder: (item, _) => _buildExpansionButton(item),
              leadingItemWidth: 24,
              scrollbarConfig: const ScrollbarConfig(
                showLeftScrollbar: .never,
                showRightScrollbar: .always,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackHeader(List<ModpackItemRowData> rows) {
    final unknownKeys = definition.unknownFields.keys.toList()..sort();
    final installedCount = rows.where((row) => row.isInstalled).length;

    return Card(
      margin: .zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const .symmetric(horizontal: 8),
        child: Column(
          children: [
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  Padding(
                    padding: const .only(right: 16),
                    child: _toolbarAction(
                      label: 'Back',
                      icon: Icons.arrow_back,
                      onPressed: widget.onBack,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: .horizontal,
                      child: Row(
                        spacing: 8,
                        children: [
                          TextTriOS(
                            definition.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontSize: 20),
                            maxLines: 1,
                          ),
                          _MetadataBadge(label: 'v${definition.version}'),
                          _buildCopyablePackId(),
                          _externalLinkAction(
                            url: definition.homepageUrl,
                            icon: Icons.language,
                            message: 'Open homepage',
                          ),
                          _externalLinkAction(
                            url: definition.updateUrl,
                            icon: Icons.refresh,
                            message: 'Check for modpack updates',
                          ),
                        ],
                      ),
                    ),
                  ),
                  _toolbarAction(
                    label: 'Edit',
                    icon: Icons.edit,
                    onPressed: widget.onEdit,
                  ),
                  _toolbarAction(
                    label: 'Copy link',
                    icon: Icons.link,
                    onPressed: _sharing
                        ? null
                        : () => _share(_ShareAction.copyLink),
                  ),
                  _toolbarAction(
                    label: 'Export',
                    icon: Icons.file_download_outlined,
                    onPressed: _sharing
                        ? null
                        : () => _share(_ShareAction.export),
                  ),
                  _toolbarAction(
                    label: 'Install',
                    icon: Icons.download,
                    disabledMessage:
                        'Modpack installation is added in phase 8.',
                  ),
                  OverflowMenuButton(
                    menuItems: [
                      if (definition.updateUrl != null && !_sharing)
                        OverflowMenuItem(
                          title: 'Publish update',
                          icon: Icons.publish,
                          onTap: () => _share(_ShareAction.publish),
                        ).toEntry(2),
                      OverflowMenuItem(
                        title: 'Delete',
                        icon: Icons.delete,
                        onTap: widget.onDelete,
                      ).toEntry(0),
                      OverflowMenuItem(
                        title: 'Duplicate',
                        icon: Icons.copy,
                        onTap: widget.onDuplicate,
                      ).toEntry(1),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const .fromLTRB(8, 8, 8, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final packDetails = _buildPackDetails(unknownKeys);
                  final coverage = _buildCoverage(installedCount, rows.length);

                  if (constraints.maxWidth < 860) {
                    return Column(
                      crossAxisAlignment: .stretch,
                      spacing: 16,
                      children: [packDetails, coverage],
                    );
                  }

                  return Row(
                    crossAxisAlignment: .start,
                    spacing: 24,
                    children: [
                      Expanded(child: packDetails),
                      SizedBox(width: 240, child: coverage),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarAction({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    String? disabledMessage,
  }) {
    return MovingTooltipWidget.text(
      message: onPressed == null ? disabledMessage : null,
      child: TriOSToolbarItem(
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label),
        ),
      ),
    );
  }

  Widget _externalLinkAction({
    required String? url,
    required IconData icon,
    required String message,
  }) {
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null) return const SizedBox.shrink();

    return MovingTooltipWidget.text(
      message: message,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: () => launchUrl(uri),
      ),
    );
  }

  Widget _buildPackDetails(List<String> unknownKeys) {
    final theme = Theme.of(context);
    final updateVersion = widget.entry.onlineVersionAvailable;
    final author = definition.author?.trim();
    final description = definition.description?.trim();

    return Column(
      crossAxisAlignment: .start,
      spacing: 12,
      children: [
        if (updateVersion != null)
          _MetadataBadge(
            label: 'Update v$updateVersion available',
            color: theme.colorScheme.primary,
          ),
        if (description == null || description.isEmpty)
          Text(
            'No description ...yet!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: .italic,
            ),
          )
        else
          SelectableText(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _MetadataFact(
              label: 'Curated by',
              value: author == null || author.isEmpty ? 'Not set' : author,
            ),
            _MetadataFact(
              label: 'Starsector version',
              value: _orNotSet(definition.gameVersion),
            ),
            _MetadataFact(
              label: 'Format',
              value: definition.formatVersion.toString(),
            ),
          ],
        ),
        if (unknownKeys.isNotEmpty)
          SimpleDataRow(
            label: 'Additional fields: ',
            value: unknownKeys.join(', '),
          ),
      ],
    );
  }

  Widget _buildCopyablePackId({Color? color}) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;
    final abbreviatedId = _abbreviatePackId(definition.id);

    return MovingTooltipWidget.text(
      message: 'Copy full pack ID (${definition.id})',
      child: Container(
        padding: const .symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: effectiveColor.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            Clipboard.setData(ClipboardData(text: definition.id));
            showSnackBar(
              context: context,
              type: SnackBarType.info,
              content: const Text('Pack ID copied to clipboard'),
            );
          },
          child: Row(
            mainAxisSize: .min,
            spacing: 4,
            children: [
              Text(
                'ID: $abbreviatedId',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverage(int installedCount, int totalCount) {
    final theme = Theme.of(context);
    final missingCount = totalCount - installedCount;
    final fraction = totalCount == 0 ? 0.0 : installedCount / totalCount;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const .all(16),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                Icon(
                  Icons.playlist_add_check,
                  color: theme.colorScheme.primary,
                ),
                Expanded(
                  child: TextTriOS(
                    'Installed mods',
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            Text(
              totalCount == 0
                  ? 'This modpack is empty'
                  : '$installedCount of $totalCount installed',
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20),
            ),
            ThemedLinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              color: missingCount == 0 && totalCount > 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0.65),
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.1,
              ),
            ),
            Text(
              missingCount == 0
                  ? totalCount == 0
                        ? 'Add mods in the editor to get started.'
                        : 'Everything in this pack is available locally.'
                  : '$missingCount ${missingCount == 1 ? 'mod is' : 'mods are'} missing locally.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsToolbar(List<ModpackItemRowData> rows) {
    final visibleIds = rows.map((row) => row.key).toSet();
    final allExpanded =
        visibleIds.isNotEmpty && visibleIds.every(_expandedItemIds.contains);

    return Padding(
      padding: const .fromLTRB(16, 8, 16, 4),
      child: Row(
        spacing: 8,
        children: [
          Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            spacing: 2,
            children: [
              Text(
                '${rows.length} mods',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: allExpanded || rows.isEmpty
                ? null
                : () => setState(() => _expandedItemIds.addAll(visibleIds)),
            icon: const Icon(Icons.unfold_more, size: 18),
            label: const Text('Expand all'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton.icon(
            onPressed: _expandedItemIds.intersection(visibleIds).isEmpty
                ? null
                : () => setState(() => _expandedItemIds.removeAll(visibleIds)),
            icon: const Icon(Icons.unfold_less, size: 18),
            label: const Text('Collapse all'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<WispGridColumn<ModpackItemRowData>> _buildColumns(List<Mod> allMods) {
    final theme = Theme.of(context);
    final gridTextStyle = GoogleFonts.roboto(
      textStyle: theme.textTheme.labelLarge,
    );
    final gridNameTextStyle = GoogleFonts.roboto(
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
    final gridMutedTextStyle = GoogleFonts.roboto(
      textStyle: theme.textTheme.labelLarge?.copyWith(
        color: theme.textTheme.labelLarge?.color?.withValues(
          alpha: WispGrid.lightTextOpacity,
        ),
      ),
    );
    final normalColumns = ModGridColumns(
      ref: ref,
      theme: theme,
      modsMetadata: ref.watch(AppState.modsMetadata).value,
      isGameRunning: ref.watch(AppState.isGameRunning).value == true,
      allMods: allMods,
      vramEstState: ref.watch(AppState.vramEstimatorProvider),
      loadOrderNumberLookupByModId: _loadOrderNumbers(allMods),
    ).build();

    return [
      WispGridColumn<ModpackItemRowData>(
        key: _packOrderColumnKey,
        name: 'Pack order',
        isSortable: true,
        getSortValue: (row) => row.packOrder,
        headerCellBuilder: (_) => _columnHeader('Pack order'),
        itemCellBuilder: (row, _) => TextTriOS(
          '${row.packOrder + 1}',
          style: gridTextStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        csvValue: (row) => '${row.packOrder + 1}',
        defaultState: const WispGridColumnState(
          position: 0,
          width: 88,
          isVisible: false,
        ),
      ),
      WispGridColumn<ModpackItemRowData>(
        key: 'installed',
        name: 'Installed',
        isSortable: true,
        getSortValue: (row) => row.isInstalled ? 1 : 0,
        headerCellBuilder: (_) => _columnHeader('Installed'),
        itemCellBuilder: (row, modifiers) => row.isInstalled
            ? ModVersionSelectionDropdown(
                mod: row.installedMod!,
                width: modifiers.columnState.width,
                showTooltip: true,
              )
            : Row(
                spacing: 4,
                children: [
                  Icon(
                    row.isInstalled
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    size: 16,
                    color: row.isInstalled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                  Text(
                    row.isInstalled ? 'Installed' : 'Missing',
                    style: gridTextStyle,
                  ),
                ],
              ),
        csvValue: (row) => row.isInstalled ? 'Installed' : 'Missing',
        defaultState: const WispGridColumnState(position: 1, width: 130),
      ),
      WispGridColumn<ModpackItemRowData>(
        key: 'icons',
        name: 'Icon',
        isSortable: true,
        getSortValue: (row) => row.installedVariant?.iconFilePath ?? '',
        headerCellBuilder: (_) => const SizedBox.shrink(),
        itemCellBuilder: (row, _) => ModIcon.fromVariant(
          row.installedVariant,
          size: 32,
          takeUpSpaceIfNoIcon: true,
        ),
        csvValue: (row) => row.installedVariant?.iconFilePath,
        defaultState: const WispGridColumnState(position: 2, width: 32),
      ),
      WispGridColumn<ModpackItemRowData>(
        key: 'name',
        name: 'Name',
        isSortable: true,
        getSortValue: (row) => row.displayName.toLowerCase(),
        headerCellBuilder: (_) => _columnHeader('Name'),
        itemCellBuilder: (row, _) => Row(
          crossAxisAlignment: .start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: TextTriOS(
                          row.displayName,
                          style: gridNameTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (row.item.note != null &&
                          row.item.note.isNotNullOrBlank)
                        Padding(
                          padding: const .only(top: 3, left: 8),
                          child: MovingTooltipWidget.text(
                            message: row.item.note,
                            child: Icon(
                              Icons.sticky_note_2,
                              size: 14,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  TextTriOS(
                    row.item.modId,
                    style: gridMutedTextStyle.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        csvValue: (row) => row.displayName,
        defaultState: const WispGridColumnState(position: 3, width: 240),
      ),
      WispGridColumn<ModpackItemRowData>(
        key: 'author',
        name: 'Author',
        isSortable: true,
        getSortValue: (row) => row.author?.toLowerCase() ?? '',
        headerCellBuilder: (_) => _columnHeader('Author'),
        itemCellBuilder: (row, _) => TextTriOS(
          row.author ?? '—',
          style: gridMutedTextStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        csvValue: (row) => row.author,
        defaultState: const WispGridColumnState(position: 4, width: 160),
      ),
      WispGridColumn<ModpackItemRowData>(
        key: 'label',
        name: 'Label',
        isSortable: true,
        getSortValue: (row) => row.item.label?.toLowerCase() ?? '',
        headerCellBuilder: (_) => _columnHeader('Label'),
        itemCellBuilder: (row, _) => TextTriOS(
          row.item.label ?? '—',
          style: gridTextStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        csvValue: (row) => row.item.label,
        defaultState: const WispGridColumnState(position: 5, width: 120),
      ),
      WispGridColumn<ModpackItemRowData>(
        key: 'version',
        name: 'Version',
        isSortable: true,
        getSortValue: (row) =>
            row.installedVariant?.modInfo.version ?? row.parsedRecordedVersion,
        headerCellBuilder: (_) => _columnHeader('Version'),
        itemCellBuilder: (row, _) {
          final installedVersion = row.installedVersion;
          final recordedVersion = row.recordedVersion;
          if (installedVersion == null) {
            return TextTriOS(
              row.combinedVersion,
              style: gridTextStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          }

          final showsRecordedVersion =
              recordedVersion != null &&
              row.installedVariant?.modInfo.version !=
                  row.parsedRecordedVersion;
          final versionText = Text.rich(
            TextSpan(
              style: gridTextStyle,
              children: [
                TextSpan(
                  text: installedVersion,
                  style: row.installedVersionIsBelowRecordedVersion
                      ? TextStyle(color: theme.triosExtensions.warning)
                      : null,
                ),
                if (showsRecordedVersion)
                  TextSpan(text: ' (modpack: $recordedVersion)'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
          return row.installedVersionIsBelowRecordedVersion
              ? MovingTooltipWidget.text(
                  message:
                      'You have $installedVersion. This modpack calls for '
                      '$recordedVersion or newer.',
                  warningLevel: TooltipWarningLevel.warning,
                  child: versionText,
                )
              : versionText;
        },
        csvValue: (row) => row.combinedVersion,
        defaultState: const WispGridColumnState(position: 6, width: 190),
      ),
      WispGridColumn<ModpackItemRowData>(
        key: 'dependencies',
        name: 'Dependencies',
        isSortable: true,
        getSortValue: (row) => row.dependencyWarnings.length,
        headerCellBuilder: (_) => _columnHeader('Dependencies'),
        itemCellBuilder: (row, _) {
          if (!row.isInstalled || row.dependencyWarnings.isEmpty) {
            return Text('—', style: gridTextStyle);
          }
          final count = row.dependencyWarnings.length;
          return MovingTooltipWidget.text(
            message: row.dependencyWarningText,
            child: Row(
              spacing: 4,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                Text('$count needed', style: gridTextStyle),
              ],
            ),
          );
        },
        csvValue: (row) => row.dependencyWarningText,
        defaultState: const WispGridColumnState(position: 7, width: 160),
      ),
      ..._adaptNormalModColumns(normalColumns),
    ];
  }

  List<WispGridColumn<ModpackItemRowData>> _adaptNormalModColumns(
    List<WispGridColumn<Mod>> normalColumns,
  ) {
    const replacedColumns = {
      'favorites',
      'changeVariantButton',
      'icons',
      'name',
      'author',
      'version',
    };
    final remaining = normalColumns
        .where((column) => !replacedColumns.contains(column.key))
        .toList();

    return [
      for (var index = 0; index < remaining.length; index++)
        _adaptNormalModColumn(remaining[index], 8 + index),
    ];
  }

  WispGridColumn<ModpackItemRowData> _adaptNormalModColumn(
    WispGridColumn<Mod> column,
    int position,
  ) {
    return WispGridColumn<ModpackItemRowData>(
      key: column.key,
      name: column.name,
      isSortable: column.isSortable,
      getSortValue: column.getSortValue == null
          ? null
          : (row) {
              final mod = row.installedMod;
              return mod == null ? null : column.getSortValue!(mod);
            },
      headerCellBuilder: column.headerCellBuilder,
      itemCellBuilder: (row, modifiers) {
        final mod = row.installedMod;
        if (mod == null) return const SizedBox.shrink();
        return column.itemCellBuilder?.call(mod, modifiers) ??
            const SizedBox.shrink();
      },
      csvValue: (row) {
        final mod = row.installedMod;
        return mod == null ? null : column.csvValue?.call(mod);
      },
      defaultState: WispGridColumnState(
        position: position,
        width: column.defaultState.width,
        isVisible: false,
      ),
    );
  }

  Map<String, int> _loadOrderNumbers(List<Mod> allMods) {
    final enabled = allMods.where((mod) => mod.hasEnabledVariant).toList()
      ..sort((left, right) {
        final leftValue = left.getSortValueForLoadOrder() ?? '';
        final rightValue = right.getSortValueForLoadOrder() ?? '';
        return leftValue.toString().compareTo(rightValue.toString());
      });
    return {
      for (var index = 0; index < enabled.length; index++)
        enabled[index].id: index + 1,
    };
  }

  Widget _columnHeader(String label) => Builder(
    builder: (context) => Text(
      label,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildExpansionButton(ModpackItemRowData row) =>
      MovingTooltipWidget.text(
        message: _expandedItemIds.contains(row.key)
            ? 'Collapse details'
            : 'Expand details',
        child: IconButton(
          onPressed: () => _toggleExpanded(row),
          icon: Icon(
            _expandedItemIds.contains(row.key)
                ? Icons.expand_less
                : Icons.expand_more,
            size: 18,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 24, height: 24),
        ),
      );

  Widget _buildItemRow(
    ModpackItemRowData row,
    Widget gridRow, {
    required bool isHovering,
  }) {
    final theme = Theme.of(context);
    final expanded = _expandedItemIds.contains(row.key);
    final background = expanded || isHovering
        ? theme.colorScheme.onInverseSurface.withValues(alpha: 0.2)
        : Colors.transparent;

    return ColoredBox(
      color: background,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [gridRow, if (expanded) _buildExpandedDetails(row)],
      ),
    );
  }

  Widget _buildExpandedDetails(ModpackItemRowData row) {
    final item = row.item;
    final unknownKeys = item.unknownFields.keys.toList()..sort();
    final warnings = row.dependencyWarnings;

    final theme = Theme.of(context);
    return Padding(
      padding: const .fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const .all(12),
        child: Column(
          crossAxisAlignment: .start,
          spacing: 8,
          children: [
            if (item.label.isNotNullOrBlank)
              Text(item.label!, style: theme.textTheme.labelMedium),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                SimpleDataRow(
                  label: 'Installed version: ',
                  value: row.installedVersion ?? 'Not installed',
                ),
                SimpleDataRow(
                  label: 'Modpack version: ',
                  value: row.recordedVersion ?? 'Not recorded',
                ),
              ],
            ),
            Row(
              spacing: 8,
              children: [
                SimpleDataRow(label: 'Download URL: ', value: item.url),
                MovingTooltipWidget.text(
                  message: switch (item.sourceType) {
                    .versionFile =>
                      'This download url uses Version Checker.'
                          '\nIt will always download the latest version of the mod (per Version Checker).',
                    .directDownload =>
                      'This download url was hardcoded.'
                          '\nIt will always download the same file, even if the mod updates.',
                  },
                  child: Icon(
                    switch (item.sourceType) {
                      ModpackItemSourceType.versionFile => Icons.link_off,
                      ModpackItemSourceType.directDownload => Icons.link,
                    },
                    size: 16,
                    color: switch (item.sourceType) {
                      .versionFile => theme.iconTheme.color,
                      .directDownload => theme.triosExtensions.warning,
                    },
                  ),
                ),
              ],
            ),
            if (row.catalogRecoveryText.isNotNullOrBlank)
              SimpleDataRow(
                label: 'Catalog recovery: ',
                value: row.catalogRecoveryText!,
              ),
            if (warnings.isNotEmpty)
              Column(
                crossAxisAlignment: .start,
                spacing: 4,
                children: [
                  Text('Required mods', style: theme.textTheme.labelMedium),
                  for (final warning in warnings)
                    Row(
                      spacing: 8,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 14,
                          color:
                              getStateColorForDependencyText(warning.state) ??
                              theme.colorScheme.error,
                        ),
                        Expanded(
                          child: SelectableText(
                            warning.message,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            if (unknownKeys.isNotEmpty)
              SimpleDataRow(
                label: 'Additional fields: ',
                value: unknownKeys.join(', '),
              ),
            if (item.note.isNotNullOrBlank)
              SimpleDataRow(label: "Note: ", value: item.note!),
          ],
        ),
      ),
    );
  }

  void _toggleExpanded(ModpackItemRowData row) {
    setState(() {
      _expandedItemIds.contains(row.key)
          ? _expandedItemIds.remove(row.key)
          : _expandedItemIds.add(row.key);
    });
  }

  String _orNotSet(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? 'Not set' : trimmed;
  }

  String _abbreviatePackId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 2)}…${id.substring(id.length - 4)}';
  }
}

class _MetadataFact extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: 2,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: theme.textTheme.labelLarge),
      ],
    );
  }
}

class _MetadataBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const _MetadataBadge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const .symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: effectiveColor.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: .ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(color: effectiveColor),
      ),
    );
  }
}
