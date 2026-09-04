import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:trios/dashboard/changelogs.dart';
import 'package:trios/dashboard/mod_list_basic.dart';
import 'package:trios/dashboard/mod_summary_widget.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/mod_data_issues.dart';
import 'package:trios/mod_manager/mod_data_warning_icon.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/mod_version_selection_dropdown.dart';
import 'package:trios/mod_manager/widgets/category_cell.dart';
import 'package:trios/mod_tag_manager/category_manager.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/trios/context_menu_items.dart';
import 'package:trios/trios/mod_metadata.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/graphics_lib_config_provider.dart';
import 'package:trios/vram_estimator/vram_checker_explanation.dart';
import 'package:trios/vram_estimator/vram_estimator_page.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/mod_icon.dart';
import 'package:trios/widgets/mod_type_icon.dart';
import 'package:trios/widgets/mod_download/mod_update_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/tooltip_frame.dart';

import 'package:trios/mod_manager/homebrew_grid/wispgrid_header_row_view.dart';
import 'package:trios/mod_manager/mods_grid_page.dart'
    show FavoriteButton, vramColumnHovered;
import 'package:trios/vram_estimator/vram_estimator_manager.dart';

/// The mod columns shared by the Mod Manager grid and the modpack editor's
/// installed-mod list. Both get the same column set; each page chooses which
/// are visible by default and stores its own column state.
///
/// Page-specific behaviour — context menus, dependency buttons, sidebars —
/// stays with the page.
class ModGridColumns {
  ModGridColumns({
    required this.ref,
    required this.theme,
    required this.modsMetadata,
    required this.isGameRunning,
    required this.allMods,
    required this.vramEstState,
    required this.loadOrderNumberLookupByModId,
    this.checkedModIds = _noCheckedMods,
    this.stateOverrides = const {},
  });

  final WidgetRef ref;
  final ThemeData theme;
  final ModsMetadata? modsMetadata;
  final bool isGameRunning;
  final List<Mod> allMods;
  final AsyncValue<VramEstimatorManagerState> vramEstState;
  final Map<String, int> loadOrderNumberLookupByModId;

  /// The rows currently checked, for cells that act on a whole selection.
  final Set<String> Function() checkedModIds;

  /// Replaces a column's default position, width, or visibility. Keyed by
  /// [ModGridHeader] name.
  final Map<String, WispGridColumnState> stateOverrides;

  static Set<String> _noCheckedMods() => const {};

  List<WispGridColumn<Mod>> build() {
    if (stateOverrides.isEmpty) return _columns();
    return _columns().map((column) {
      final override = stateOverrides[column.key];
      if (override == null) return column;
      return WispGridColumn<Mod>(
        key: column.key,
        name: column.name,
        isSortable: column.isSortable,
        getSortValue: column.getSortValue,
        headerCellBuilder: column.headerCellBuilder,
        itemCellBuilder: column.itemCellBuilder,
        csvValue: column.csvValue,
        defaultState: override,
      );
    }).toList();
  }

  List<WispGridColumn<Mod>> _columns() => [
    WispGridColumn<Mod>(
      key: ModGridHeader.favorites.name,
      name: "Favorite",
      isSortable: false,
      headerCellBuilder: (modifiers) =>
          buildColumnHeader(ModGridHeader.favorites, modifiers).child,
      itemCellBuilder: (mod, modifiers) => Builder(
        builder: (context) {
          final modMetadata = modsMetadata?.userMetadata[mod.id];
          final isFavorited = modMetadata?.isFavorited ?? false;
          return FavoriteButton(
            mod: mod,
            isRowHighlighted: modifiers.isHovering,
            isFavorited: isFavorited,
          );
        },
      ),
      csvValue: (mod) =>
          modsMetadata?.userMetadata[mod.id]?.isFavorited.toString() ?? "false",
      defaultState: WispGridColumnState(position: 0, width: 50),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.changeVariantButton.name,
      name: "Version Select",
      isSortable: false,
      headerCellBuilder: (modifiers) => Container(),
      itemCellBuilder: (mod, modifiers) => Disable(
        isEnabled: !isGameRunning,
        child: ModVersionSelectionDropdown(
          mod: mod,
          width: modifiers.columnState.width,
          showTooltip: true,
        ),
      ),
      csvValue: (mod) =>
          mod.modVariants.map((v) => v.modInfo.version.toString()).join(","),
      defaultState: WispGridColumnState(position: 1, width: 130),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.icons.name,
      name: "Mod Icon",
      isSortable: true,
      getSortValue: (mod) => mod.getSortValueForModIcon(),
      headerCellBuilder: (modifiers) => Container(),
      itemCellBuilder: (mod, modifiers) => Builder(
        builder: (context) {
          String? iconPath = mod.findFirstEnabledOrHighestVersion?.iconFilePath;
          return iconPath != null
              ? ModIcon(iconPath, size: 32)
              : const SizedBox(width: 32, height: 32);
        },
      ),
      csvValue: (mod) => mod.findFirstEnabledOrHighestVersion?.iconFilePath,
      defaultState: WispGridColumnState(position: 2, width: 32),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.modIcon.name,
      name: "Mod Type Icon",
      isSortable: true,
      getSortValue: (mod) => mod.getSortValueForType(),
      headerCellBuilder: (modifiers) => Container(),
      itemCellBuilder: (mod, modifiers) =>
          ModTypeIcon(modVariant: mod.findFirstEnabledOrHighestVersion!),
      csvValue: (mod) => mod.findFirstEnabledOrHighestVersion?.modInfo.modTypes
          .joinToString(transform: (type) => type.name),
      defaultState: WispGridColumnState(position: 3, width: 32),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.loadOrder.name,
      name: "Load #",
      isSortable: true,
      getSortValue: (mod) => mod.getSortValueForLoadOrder(),
      headerCellBuilder: (modifiers) =>
          buildColumnHeader(ModGridHeader.loadOrder, modifiers).child,
      itemCellBuilder: (mod, modifiers) => TextTriOS(
        loadOrderNumberLookupByModId[mod.id]?.toString() ?? "—",
        style: GoogleFonts.roboto(textStyle: theme.textTheme.labelLarge),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      csvValue: (mod) =>
          loadOrderNumberLookupByModId[mod.id]?.toString() ?? "—",
      defaultState: WispGridColumnState(
        position: 4,
        width: 70,
        isVisible: false,
      ),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.name.name,
      name: "Name",
      isSortable: true,
      getSortValue: (mod) => mod.getSortValueForName(),
      headerCellBuilder: (modifiers) =>
          buildColumnHeader(ModGridHeader.name, modifiers).child,
      itemCellBuilder: (mod, modifiers) => buildNameCell(
        mod,
        mod.findFirstEnabledOrHighestVersion!,
        allMods,
        modifiers.columnState,
      ),
      csvValue: (mod) => mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId,
      defaultState: WispGridColumnState(position: 4, width: 200),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.author.name,
      name: "Author",
      isSortable: true,
      getSortValue: (mod) => mod.getSortValueForAuthor(),
      headerCellBuilder: (modifiers) =>
          buildColumnHeader(ModGridHeader.author, modifiers).child,
      itemCellBuilder: (mod, modifiers) => Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final lightTextColor = theme.textTheme.labelLarge?.color?.withValues(
            alpha: WispGrid.lightTextOpacity,
          );
          final bestVersion = mod.findFirstEnabledOrHighestVersion!;
          return TextTriOS(
            bestVersion.modInfo.author?.toString().replaceAll("\n", "   ") ??
                "(no author)",
            maxLines: 1,
            style: theme.textTheme.labelLarge?.copyWith(color: lightTextColor),
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      csvValue: (mod) => mod.findFirstEnabledOrHighestVersion?.modInfo.author,
      defaultState: WispGridColumnState(position: 5, width: 200),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.updateStatus.name,
      name: "Update",
      isSortable: true,
      getSortValue: (mod) => mod.getSortValueForUpdateStatus(ref, modsMetadata),
      itemCellBuilder: (mod, modifiers) => Builder(
        builder: (context) {
          final bestVersion = mod.findFirstEnabledOrHighestVersion!;
          return _buildUpdateCell(
            WispGrid.lightTextOpacity,
            mod,
            isGameRunning,
            bestVersion,
            modifiers.columnState,
            modsMetadata?.getMergedModMetadata(mod.id),
          );
        },
      ),
      csvValue: (mod) => null,
      defaultState: WispGridColumnState(position: 6, width: 65),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.version.name,
      name: "Version",
      isSortable: true,
      getSortValue: (mod) => mod.getSortValueForVersion(),
      itemCellBuilder: (mod, modifiers) => Builder(
        builder: (context) {
          final bestVersion = mod.findFirstEnabledOrHighestVersion!;
          return _buildVersionCell(
            WispGrid.lightTextOpacity,
            mod,
            isGameRunning,
            bestVersion,
            modifiers.columnState,
            modsMetadata?.getMergedModMetadata(mod.id),
          );
        },
      ),
      csvValue: (mod) =>
          mod.findFirstEnabledOrHighestVersion?.modInfo.version.toString(),
      defaultState: WispGridColumnState(position: 7, width: 75),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.vramImpact.name,
      name: "VRAM Est.",
      isSortable: true,
      getSortValue: (mod) => mod.getSortValueForVram(vramEstState.value),
      headerCellBuilder: (modifiers) =>
          buildColumnHeader(ModGridHeader.vramImpact, modifiers).child,
      itemCellBuilder: (mod, modifiers) =>
          buildVramCell(WispGrid.lightTextOpacity, mod, modifiers.columnState),
      csvValue: (mod) => ref
          .read(AppState.vramEstimatorProvider)
          .value
          ?.modVramInfo[mod.findFirstEnabledOrHighestVersion!.smolId]
          ?.bytesNotIncludingGraphicsLib()
          .toString(),
      defaultState: WispGridColumnState(position: 8, width: 128),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.categories.name,
      name: "Category",
      isSortable: true,
      getSortValue: (mod) {
        final notifier = ref.read(categoryManagerProvider.notifier);
        final primary = notifier.getPrimaryCategory(mod.id);
        return primary?.name.toLowerCase() ?? 'zzz';
      },
      headerCellBuilder: (modifiers) =>
          buildColumnHeader(ModGridHeader.categories, modifiers).child,
      itemCellBuilder: (mod, modifiers) =>
          CategoryCell(modId: mod.id, checkedModIds: checkedModIds()),
      csvValue: (mod) {
        final notifier = ref.read(categoryManagerProvider.notifier);
        return notifier
            .getCategoriesForMod(mod.id)
            .map((c) => c.name)
            .join(', ');
      },
      defaultState: WispGridColumnState(position: 9, width: 150),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.gameVersion.name,
      name: "Game Version",
      isSortable: true,
      getSortValue: (mod) => mod.getSortValueForGameVersion(),
      headerCellBuilder: (modifiers) =>
          buildColumnHeader(ModGridHeader.gameVersion, modifiers).child,
      itemCellBuilder: (mod, modifiers) => Builder(
        builder: (context) {
          final bestVersion = mod.findFirstEnabledOrHighestVersion!;
          final originalGameVersion = bestVersion.modInfo.originalGameVersion;

          return MovingTooltipWidget.text(
            message: originalGameVersion != null
                ? "Original game version: $originalGameVersion"
                : null,
            child: Opacity(
              opacity: WispGrid.lightTextOpacity,
              child: Text(
                "${bestVersion.modInfo.gameVersion ?? "(no game version)"}"
                "${originalGameVersion != null ? "**" : ""}",
                style:
                    compareGameVersions(
                          bestVersion.modInfo.gameVersion,
                          ref.watch(appSettings).lastStarsectorVersion,
                        ) ==
                        GameCompatibility.perfectMatch
                    ? theme.textTheme.labelLarge
                    : theme.textTheme.labelLarge?.copyWith(
                        color: TriOSThemeConstants.vanillaErrorColor,
                      ),
              ),
            ),
          );
        },
      ),
      csvValue: (mod) =>
          mod.findFirstEnabledOrHighestVersion?.modInfo.gameVersion,
      defaultState: WispGridColumnState(position: 10, width: 100),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.firstSeen.name,
      name: "First Seen",
      isSortable: true,
      getSortValue: (mod) => mod.getSortValueForFirstSeen(modsMetadata),
      headerCellBuilder: (modifiers) =>
          buildColumnHeader(ModGridHeader.firstSeen, modifiers).child,
      itemCellBuilder: (mod, modifiers) => Opacity(
        opacity: WispGrid.lightTextOpacity,
        child: Text(
          modsMetadata
                  ?.getMergedModMetadata(mod.id)
                  ?.let(
                    (m) => Constants.dateTimeFormat.format(
                      DateTime.fromMillisecondsSinceEpoch(m.firstSeen),
                    ),
                  ) ??
              "",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge,
        ),
      ),
      csvValue: (mod) =>
          modsMetadata
              ?.getMergedModMetadata(mod.id)
              ?.let(
                (m) =>
                    DateTime.fromMillisecondsSinceEpoch(m.firstSeen)
                        .toIso8601String(),
              ) ??
          "",
      defaultState: WispGridColumnState(position: 11, width: 150),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.lastEnabled.name,
      name: "Last Enabled",
      isSortable: true,
      getSortValue: (mod) => mod.getSortValueForLastEnabled(modsMetadata),
      headerCellBuilder: (modifiers) =>
          buildColumnHeader(ModGridHeader.lastEnabled, modifiers).child,
      itemCellBuilder: (mod, modifiers) => Opacity(
        opacity: WispGrid.lightTextOpacity,
        child: Text(
          modsMetadata
                  ?.getMergedModMetadata(mod.id)
                  ?.lastEnabled
                  ?.let(
                    (lastEnabled) => Constants.dateTimeFormat.format(
                      DateTime.fromMillisecondsSinceEpoch(lastEnabled),
                    ),
                  ) ??
              "",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge,
        ),
      ),
      csvValue: (mod) =>
          modsMetadata
              ?.getMergedModMetadata(mod.id)
              ?.lastEnabled
              ?.let(
                (lastEnabled) =>
                    DateTime.fromMillisecondsSinceEpoch(lastEnabled)
                        .toIso8601String(),
              ) ??
          "",
      defaultState: WispGridColumnState(position: 12, width: 150),
    ),
    WispGridColumn<Mod>(
      key: ModGridHeader.lastUpdated.name,
      name: "Last Updated",
      isSortable: true,
      getSortValue: (mod) => mod.getSortValueForLastUpdated(modsMetadata),
      headerCellBuilder: (modifiers) =>
          buildColumnHeader(ModGridHeader.lastUpdated, modifiers).child,
      itemCellBuilder: (mod, modifiers) {
        final ms = mod.getSortValueForLastUpdated(modsMetadata);
        return Opacity(
          opacity: WispGrid.lightTextOpacity,
          child: Text(
            ms > 0
                ? Constants.dateTimeFormat.format(
                    DateTime.fromMillisecondsSinceEpoch(ms),
                  )
                : "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge,
          ),
        );
      },
      csvValue: (mod) {
        final ms = mod.getSortValueForLastUpdated(modsMetadata);
        return ms > 0
            ? DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String()
            : "";
      },
      defaultState: WispGridColumnState(
        position: 13,
        width: 150,
        isVisible: false,
      ),
    ),
  ];

  WispGridHeader buildColumnHeader(
    ModGridHeader header,
    HeaderBuilderModifiers modifiers,
  ) {
    // final state =
    //     ref
    //         .watch(appSettings.select((s) => s.modsGridState))
    //         .columnsState[header.name] ??
    //     WispGridColumnState(position: 0, width: 100);

    final sortField = switch (header) {
      ModGridHeader.favorites => null,
      ModGridHeader.changeVariantButton => null,
      ModGridHeader.icons => ModGridSortField.icons,
      ModGridHeader.modIcon => ModGridSortField.icons,
      ModGridHeader.loadOrder => ModGridSortField.loadOrder,
      ModGridHeader.name => ModGridSortField.name,
      ModGridHeader.author => ModGridSortField.author,
      ModGridHeader.version => ModGridSortField.version,
      ModGridHeader.updateStatus => ModGridSortField.updateStatus,
      ModGridHeader.vramImpact => ModGridSortField.vramImpact,
      ModGridHeader.categories => ModGridSortField.categories,
      ModGridHeader.gameVersion => ModGridSortField.gameVersion,
      ModGridHeader.firstSeen => ModGridSortField.firstSeen,
      ModGridHeader.lastEnabled => ModGridSortField.lastEnabled,
      ModGridHeader.lastUpdated => ModGridSortField.lastUpdated,
    };

    final builder = Builder(
      builder: (context) {
        final headerTextStyle = Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontWeight: FontWeight.bold);

        return switch (header) {
          ModGridHeader.favorites => Container(),
          ModGridHeader.changeVariantButton => Container(),
          ModGridHeader.icons => Container(),
          ModGridHeader.modIcon => Container(),
          ModGridHeader.loadOrder => MovingTooltipWidget.text(
            message: ModListMini.modLoadOrderSettingExplanation,
            child: Text('Load #', style: headerTextStyle),
          ),
          ModGridHeader.name => Text('Name', style: headerTextStyle),
          ModGridHeader.author => Text('Author', style: headerTextStyle),
          ModGridHeader.updateStatus => Text('Update', style: headerTextStyle),
          ModGridHeader.version => Text('Version', style: headerTextStyle),
          ModGridHeader.vramImpact => MovingTooltipWidget.text(
            message:
                'An *estimate* of how much VRAM is used based on the images in the mod folder.'
                '\nThis may be inaccurate.',
            child: Row(
              children: [
                Text('VRAM Est.', style: headerTextStyle),
                const SizedBox(width: 4),
                MovingTooltipWidget.text(
                  message: "About VRAM & VRAM Estimator",
                  child: IconButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => VramCheckerExplanationDialog(),
                    ),
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.info_outline, size: 20),
                  ),
                ),
              ],
            ),
          ),
          ModGridHeader.gameVersion => Text(
            'Game Version',
            style: headerTextStyle,
          ),
          ModGridHeader.firstSeen => Text('First Seen', style: headerTextStyle),
          ModGridHeader.lastEnabled => Text(
            'Last Enabled',
            style: headerTextStyle,
          ),
          ModGridHeader.lastUpdated => Text(
            'Last Updated',
            style: headerTextStyle,
          ),
          ModGridHeader.categories => Text('Category', style: headerTextStyle),
        };
      },
    );

    return WispGridHeader(sortField: sortField?.name, child: builder);
  }

  Builder buildVramCell(
    double lightTextOpacity,
    Mod mod,
    WispGridColumnState state,
  ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final lightTextColor = theme.colorScheme.onSurface.withOpacity(
          lightTextOpacity,
        );
        final bestVersion = mod.findFirstEnabledOrHighestVersion;
        final graphicsLibConfig = ref.watch(graphicsLibConfigProvider);
        if (bestVersion == null) return const SizedBox();

        // Fills the row height. Not an Expanded: the cell's parent is no
        // longer a Column.
        return SizedBox(
          height: double.infinity,
          child: Builder(
            builder: (context) {
              final vramEstimatorState = ref.watch(
                AppState.vramEstimatorProvider,
              );
              final vramProvider = ref.watch(AppState.vramEstimatorProvider);
              final vramMap = vramProvider.value?.modVramInfo ?? {};
              final vramEstimate = vramMap[bestVersion.smolId];
              final biggestFish = vramMap
                  .maxBy((e) => e.value.imagesNotIncludingGraphicsLib().sum())
                  ?.value
                  .imagesNotIncludingGraphicsLib()
                  .sum();
              final ratio = biggestFish == null
                  ? 0.00
                  : (vramMap[bestVersion.smolId]
                                ?.imagesNotIncludingGraphicsLib()
                                .sum()
                                .toDouble() ??
                            0) /
                        biggestFish.toDouble();
              final withoutGraphicsLib = vramEstimate
                  ?.imagesNotIncludingGraphicsLib();

              final isIllustratedEntities =
                  mod.findFirstEnabledOrHighestVersion?.modInfo.id ==
                  Constants.illustratedEntitiesId;

              return MovingTooltipWidget.framed(
                tooltipWidgetBuilder: vramEstimate == null
                    ? null
                    : (_) => IntrinsicWidth(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "VRAM Estimate",
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "${mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId} v${vramEstimate.info.version}"
                              "\n\n${withoutGraphicsLib?.sum().bytesAsReadableMB()} from mod (${withoutGraphicsLib?.length} images)"
                              "\n---"
                              "\n${withoutGraphicsLib?.sum().bytesAsReadableMB()} total"
                              "${isIllustratedEntities ? ""
                                        ""
                                        "\n\nNOTE"
                                        "\nIllustrated Entities dynamically loads and unloads images from VRAM." : ""}",
                              style: theme.textTheme.labelLarge,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Divider(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: .5,
                                ),
                              ),
                            ),
                            VramEstimatorPage.buildVramTopFilesTableWidget(
                              theme,
                              vramEstimate,
                              graphicsLibConfig,
                            ),
                          ],
                        ),
                      ),
                warningLevel: isIllustratedEntities
                    ? TooltipWarningLevel.warning
                    : null,
                child: MouseRegion(
                  onEnter: (_) =>
                      ref.read(vramColumnHovered.notifier).state = true,
                  onExit: (_) =>
                      ref.read(vramColumnHovered.notifier).state = false,
                  child: Align(
                    alignment: .centerLeft,
                    child: Stack(
                      children: [
                        if (vramEstimate != null)
                          Align(
                            alignment: .centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: ThemedLinearProgressIndicator(
                                value: ratio.isNaN || ratio.isInfinite
                                    ? 0
                                    : ratio,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainer,
                              ),
                            ),
                          ),
                        if (vramEstimate?.imagesNotIncludingGraphicsLib() !=
                                null &&
                            ref.watch(vramColumnHovered))
                          Align(
                            alignment: .topLeft,
                            child: Padding(
                              padding: const .only(left: 8, right: 12),
                              child: Text(
                                vramEstimate!
                                    .imagesNotIncludingGraphicsLib()
                                    .sum()
                                    .bytesAsReadableMB(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: lightTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          )
                        else if (vramEstimate == null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Opacity(
                              opacity: 0.5,
                              child: Disable(
                                isEnabled:
                                    vramEstimatorState.value?.isScanning !=
                                    true,
                                child: MovingTooltipWidget.text(
                                  message: "Estimate VRAM usage",
                                  child: IconButton(
                                    icon: const Icon(Icons.memory),
                                    iconSize: 24,
                                    onPressed: () {
                                      ref
                                          .read(
                                            AppState
                                                .vramEstimatorProvider
                                                .notifier,
                                          )
                                          .startEstimating(
                                            variantsToCheck: [
                                              mod.findFirstEnabledOrHighestVersion!,
                                            ],
                                          );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Builder _buildUpdateCell(
    double lightTextOpacity,
    Mod mod,
    bool isGameRunning,
    ModVariant bestVersion,
    WispGridColumnState state,
    ModMetadata? metadata,
  ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final lightTextColor = theme.colorScheme.onSurface.withOpacity(
          lightTextOpacity,
        );
        final versionCheckResultsNew = ref
            .watch(AppState.versionCheckResults)
            .value;
        //
        final versionCheckComparison = mod.updateCheck(versionCheckResultsNew);
        final localVersionCheck =
            versionCheckComparison?.variant.versionCheckerInfo;
        final remoteVersionCheck = versionCheckComparison?.remoteVersionCheck;
        final changelogUrl = ref
            .read(AppState.changelogsProvider.notifier)
            .getChangelogUrl(
              versionCheckComparison?.variant.versionCheckerInfo,
              versionCheckComparison?.remoteVersionCheck,
            );
        final areUpdatesMuted = metadata != null && metadata.areUpdatesMuted;
        final remoteVersion = versionCheckComparison?.remoteVersionString;
        // Only this one version is muted, rather than the mod being silenced.
        final isVersionMuted =
            !areUpdatesMuted &&
            metadata != null &&
            metadata.isUpdateHidden(remoteVersion);

        return mod.modVariants.isEmpty
            ? const Text("")
            : ContextMenuRegion(
                contextMenu: ContextMenu(
                  entries: [
                    if (!areUpdatesMuted)
                      MenuItem(
                        label: 'Recheck',
                        icon: Icons.refresh,
                        onSelected: () {
                          ref
                              .read(AppState.versionCheckResults.notifier)
                              .refresh(
                                skipCache: true,
                                specificVariantsToCheck: [
                                  mod.findFirstEnabledOrHighestVersion!,
                                ],
                              );
                        },
                      ),
                    buildMenuItemToggleMuteUpdates(mod, ref),
                  ],
                ),
                child: Row(
                  children: [
                    if (changelogUrl.isNotNullOrEmpty())
                      MovingTooltipWidget(
                        tooltipWidget: SizedBox(
                          width: 400,
                          height: 400,
                          child: TooltipFrame(
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 4,
                                      top: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          child: SvgImageIcon(
                                            "assets/images/icon-bullhorn-variant.svg",
                                            color: theme.colorScheme.primary,
                                            width: 20,
                                            height: 20,
                                          ),
                                        ),
                                        Text(
                                          "Click horn to see full changelog",
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Changelogs(
                                    mod,
                                    localVersionCheck,
                                    remoteVersionCheck,
                                    showVersionChips: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                content: Changelogs(
                                  mod,
                                  localVersionCheck,
                                  remoteVersionCheck,
                                  showVersionChips: true,
                                ),
                              ),
                            );
                          },
                          child: SvgImageIcon(
                            "assets/images/icon-bullhorn-variant.svg",
                            color: theme.iconTheme.color?.withValues(
                              alpha: 0.7,
                            ),
                            width: 20,
                            height: 20,
                          ),
                        ),
                      )
                    else
                      SizedBox(width: 20),
                    (areUpdatesMuted || isVersionMuted)
                        ? MovingTooltipWidget.text(
                            message: isVersionMuted
                                ? "Update $remoteVersion is muted. You'll be notified for the next version."
                                : "Updates muted",
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 4.0,
                                right: 8,
                              ),
                              child: Icon(
                                isVersionMuted
                                    ? Icons.notifications_paused
                                    : Icons.notifications_off,
                                size: 20.0,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          )
                        : ModUpdateIcon(
                            mod: mod,
                            modInfo: bestVersion.modInfo,
                            comparison: versionCheckComparison,
                            changelogUrl: changelogUrl,
                            isEnabled: !isGameRunning,
                            spinnerSize: 24,
                            spinnerPadding: const .only(left: 2),
                          ),
                  ],
                  // ),
                ),
              );
      },
    );
  }

  Builder _buildVersionCell(
    double lightTextOpacity,
    Mod mod,
    bool isGameRunning,
    ModVariant bestVersion,
    WispGridColumnState state,
    ModMetadata? metadata,
  ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final lightTextColor = theme.textTheme.labelLarge?.color?.withValues(
          alpha: WispGrid.lightTextOpacity,
        );
        final disabledVersionTextColor = lightTextColor?.withOpacity(0.5);
        final enabledVersion = mod.findFirstEnabled;

        return mod.modVariants.isEmpty
            ? const Text("")
            : Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final variantsWithEnabledFirst = mod.modVariants.sorted(
                          (a, b) => a.isModInfoEnabled != b.isModInfoEnabled
                              ? (a.isModInfoEnabled ? -1 : 1)
                              : a.compareTo(b),
                        );

                        final text = RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              for (
                                var i = 0;
                                i < variantsWithEnabledFirst.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  TextSpan(
                                    text: ', ',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: disabledVersionTextColor,
                                    ),
                                  ),
                                TextSpan(
                                  text: variantsWithEnabledFirst[i]
                                      .modInfo
                                      .version
                                      .toString(),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color:
                                        enabledVersion ==
                                            variantsWithEnabledFirst[i]
                                        ? null
                                        : disabledVersionTextColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );

                        return MovingTooltipWidget.framed(
                          tooltipWidgetBuilder: (context) => Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: mod.modVariants
                                .sortedByDescending(
                                  (v) => v.bestVersion ?? Version.zero(),
                                )
                                .map(
                                  (v) => Text(
                                    v.bestVersion?.toString() ?? "",

                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: enabledVersion == v
                                          ? null
                                          : disabledVersionTextColor,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          child: text,
                        );
                      },
                    ),
                  ),
                ],
                // ),
              );
      },
    );
  }

  Builder buildNameCell(
    Mod mod,
    ModVariant bestVersion,
    List<Mod> allMods,
    WispGridColumnState state,
  ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final modColor = ref
            .watch(AppState.modsMetadata)
            .value
            ?.getMergedModMetadata(mod.id)
            ?.color;

        final nameText = Text(
          bestVersion.modInfo.name ?? "(no name)",
          style: GoogleFonts.roboto(
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

        final gameVersion = ref.watch(AppState.starsectorVersion).value;
        final compatWithGame = compareGameVersions(
          bestVersion.modInfo.gameVersion,
          gameVersion,
        );
        final compatTextColor = compatWithGame.getGameCompatibilityColor();

        final showDataWarnings = ref.watch(
          appSettings.select((s) => s.modsGridShowDataWarnings),
        );
        final dataIssues = showDataWarnings
            ? checkModDataIssues(bestVersion)
            : const <ModDataIssue>[];

        final nameWidget = modColor == null && dataIssues.isEmpty
            ? nameText
            : Row(
                spacing: 8.0,
                children: [
                  if (dataIssues.isNotEmpty)
                    ModDataWarningIcon(
                      modName: bestVersion.modInfo.nameOrId,
                      issues: dataIssues,
                    ),
                  if (modColor != null)
                    Container(
                      width: 4.0,
                      height: 16.0,
                      decoration: BoxDecoration(
                        color: modColor,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  Expanded(child: nameText),
                ],
              );

        return MovingTooltipWidget.framed(
          // position: TooltipPosition.topLeft,
          padding: const EdgeInsets.all(0),
          tooltipWidgetBuilder: (context) => SizedBox(
            width: 400,
            child: ModSummaryWidget(
              modVariant: bestVersion,
              compatTextColor: compatTextColor,
              compatWithGame: compatWithGame,
              showIconTip: false,
            ),
          ),
          child: nameWidget,
        );
      },
    );
  }
}
