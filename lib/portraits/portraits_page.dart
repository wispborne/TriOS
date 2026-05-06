import 'dart:io';
import 'dart:math';
import 'package:trios/widgets/snackbar.dart';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/companion_mod/companion_mod_manager.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/portraits/portraits_gridview.dart';
import 'package:trios/portraits/portraits_page_controller.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_widget.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/blur.dart';
import 'package:trios/widgets/expanding_constrained_aligned_widget.dart';
import 'package:trios/widgets/mode_switcher.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/multi_split_mixin_view.dart';
import 'package:trios/widgets/overflow_menu_button.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/thirdparty/dartx/range.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PortraitsPage extends ConsumerStatefulWidget {
  const PortraitsPage({super.key});

  @override
  ConsumerState<PortraitsPage> createState() => _PortraitsPageState();
}

class _PortraitsPageState extends ConsumerState<PortraitsPage>
    with
        AutomaticKeepAliveClientMixin<PortraitsPage>,
        MultiSplitViewMixin,
        SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;
  final SearchController _searchController = SearchController();
  final SearchController _leftSearchController = SearchController();
  final SearchController _rightSearchController = SearchController();
  final ScrollController _filterScrollController = ScrollController();
  final ScrollController _leftFilterScrollController = ScrollController();
  final ScrollController _rightFilterScrollController = ScrollController();

  Widget? _cachedBuild;
  late final AnimationController _refreshSpinController;

  bool _inReplaceMode = false;

  @override
  void initState() {
    super.initState();
    _refreshSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  /// Keep SearchController text in sync with controller state,
  /// without triggering unnecessary rebuilds.
  void _syncSearchController(SearchController controller, String query) {
    if (controller.text != query) {
      controller.text = query;
    }
  }

  @override
  List<Area> get areas => _inReplaceMode
      ? [Area(id: 'left'), Area(id: 'right')]
      : [Area(id: 'main')];

  void _showReplacementsDialog(Map<String, Portrait> replacements) async {
    // Get current portraits to create hash-to-portrait lookup
    final portraitsAsync = ref.read(AppState.portraits);
    final Map<String, Portrait> hashToPortrait = {};

    portraitsAsync.whenData((portraits) {
      for (final entry in portraits.entries) {
        for (final portrait in entry.value) {
          hashToPortrait[portrait.hash] = portrait;
        }
      }
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => ReplacementsDialog(
        replacements: replacements,
        hashToPortrait: hashToPortrait,
        onDelete: (portrait) {
          ref
              .read(AppState.portraitReplacementsManager.notifier)
              .removeReplacement(portrait);
        },
      ),
    );
  }

  /// Returns the scroll controller for the specified pane.
  ScrollController _getFilterScrollController(FilterPane pane) {
    return switch (pane) {
      FilterPane.main => _filterScrollController,
      FilterPane.left => _leftFilterScrollController,
      FilterPane.right => _rightFilterScrollController,
    };
  }

  Widget _buildFiltersSection(
    ThemeData theme,
    List<PortraitFilterItem> filterItems, {
    FilterPane pane = FilterPane.main,
    required bool showOnlyYourChangesFilter,
  }) {
    final controllerState = ref.watch(portraitsPageControllerProvider);
    final notifier = ref.read(portraitsPageControllerProvider.notifier);
    final paneState = controllerState.getPaneState(pane);
    final activeFilterCount = notifier.activeFilterCountFor(pane);

    if (!paneState.showFilters) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Card(
          child: InkWell(
            onTap: () => ref
                .read(portraitsPageControllerProvider.notifier)
                .setShowFilters(pane, true),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: MovingTooltipWidget.text(
                message: "Show filters",
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.filter_list, size: 16),
                    Positioned(
                      top: -12,
                      left: -16,
                      child: ActiveFilterCountPill(count: activeFilterCount),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: _buildFilterPanel(
        theme,
        filterItems,
        pane: pane,
        showOnlyYourChangesFilter: showOnlyYourChangesFilter,
        activeFilterCount: activeFilterCount,
      ),
    );
  }

  Widget _buildFilterPanel(
    ThemeData theme,
    List<PortraitFilterItem> filterItems, {
    FilterPane pane = FilterPane.main,
    required bool showOnlyYourChangesFilter,
    required int activeFilterCount,
  }) {
    final scrollController = _getFilterScrollController(pane);
    final notifier = ref.read(portraitsPageControllerProvider.notifier);
    final scope = notifier.scopeFor(pane);
    final groups = notifier.filterGroupsFor(pane);

    return FiltersPanel(
      onHide: () => notifier.setShowFilters(pane, false),
      scrollController: scrollController,
      width: 200,
      activeFilterCount: activeFilterCount,
      showClearAll: groups.any((g) => g.isActive),
      onClearAll: () => notifier.clearAllFilters(pane),
      filterWidgets: [
        for (final g in groups)
          FilterGroupRenderer<PortraitFilterItem>(
            group: g,
            scope: scope,
            items: filterItems,
            onChanged: () => notifier.onGroupChanged(pane, g.id),
          ),
      ],
    );
  }

  Widget _buildGridSearchBar(
    SearchController controller,
    String hintText,
    FilterPane pane,
  ) {
    return Container(
      padding: const .only(left: 8, right: 8),
      child: SizedBox(
        height: 30,
        child: SearchAnchor(
          searchController: controller,
          builder: (BuildContext context, SearchController controller) {
            return SearchBar(
              controller: controller,
              leading: const Icon(Icons.search),
              hintText: hintText,
              trailing: [
                controller.value.text.isEmpty
                    ? Container()
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        constraints: const BoxConstraints(),
                        padding: .zero,
                        onPressed: () {
                          controller.clear();
                          ref
                              .read(portraitsPageControllerProvider.notifier)
                              .updateSearchQuery(pane, '');
                        },
                      ),
              ],
              backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainer,
              ),
              onChanged: (value) {
                ref
                    .read(portraitsPageControllerProvider.notifier)
                    .updateSearchQuery(pane, value);
              },
            );
          },
          suggestionsBuilder:
              (BuildContext context, SearchController controller) {
                return [];
              },
        ),
      ),
    );
  }

  Widget _buildPortraitSizeControl(ThemeData theme) {
    final portraitSize =
        ref.watch(portraitsPageControllerProvider.select((s) => s.portraitSize));

    return TriOSToolbarItem(
      showOutline: false,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 0,
          children: [
            Icon(Icons.grid_4x4),
            SizedBox(
              width: 160,
              child: SliderTheme(
                data: theme.sliderTheme.copyWith(
                  trackHeight: 2,
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 10,
                  ),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: Slider(
                  value: portraitSize,
                  min: PortraitsPageState.portraitSizeMin,
                  max: PortraitsPageState.portraitSizeMax,
                  divisions:
                      ((PortraitsPageState.portraitSizeMax -
                                  PortraitsPageState.portraitSizeMin) /
                              PortraitsPageState.portraitSizeStep)
                          .round(),
                  label: portraitSize.round().toString(),
                  onChanged: (value) {
                    ref
                        .read(portraitsPageControllerProvider.notifier)
                        .setPortraitSize(value);
                  },
                ),
              ),
            ),
            Icon(Icons.grid_3x3),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isActive =
        ref.watch(appSettings.select((s) => s.defaultTool)) ==
        TriOSTools.portraits;
    if (!isActive && _cachedBuild != null) return _cachedBuild!;

    // Apply pending mod filter from context menu navigation.
    final filterRequest = ref.watch(AppState.viewerFilterRequest);
    if (filterRequest != null &&
        filterRequest.destination == TriOSTools.portraits) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(portraitsPageControllerProvider.notifier)
            .setChipSelections(
              FilterPane.main,
              'mod',
              {filterRequest.modName: true},
            );
        ref.read(AppState.viewerFilterRequest.notifier).state = null;
      });
    }

    final controllerState = ref.watch(portraitsPageControllerProvider);
    final notifier = ref.read(portraitsPageControllerProvider.notifier);
    _inReplaceMode = controllerState.inReplaceMode;

    if (controllerState.isLoading) {
      if (!_refreshSpinController.isAnimating) _refreshSpinController.repeat();
    } else {
      _refreshSpinController.stop();
    }

    // Sync search controllers to controller state (needed for SearchBar widgets)
    _syncSearchController(_searchController, controllerState.mainPaneState.searchQuery);
    _syncSearchController(_leftSearchController, controllerState.leftPaneState.searchQuery);
    _syncSearchController(_rightSearchController, controllerState.rightPaneState.searchQuery);

    // Watch the portraits provider and loading state
    final portraitsAsync = ref.watch(AppState.portraits);

    final result = portraitsAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            Padding(padding: .all(16), child: Text('Loading portraits...')),
          ],
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading portraits: $error',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: notifier.refreshPortraits,
              icon: RotationTransition(
                turns: _refreshSpinController,
                child: const Icon(Icons.refresh),
              ),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (portraits) {
        final replacements = controllerState.replacements;
        final allMods = ref.watch(AppState.mods);

        // Get filtered images for the main/viewer pane
        final sortedImages = notifier.getFilteredImages(
          FilterPane.main,
          allMods,
        );

        // Get all images for counts and filter panels
        final modsAndImages = notifier.getAllImages();

        // Create filter items for the sidebar
        final filterItems = notifier.getFilterItems();

        final theme = Theme.of(context);
        final visible = sortedImages.length;
        final total = modsAndImages.length;
        final companionMod = allMods.firstWhereOrNull(
          (it) => it.id == Constants.companionModId,
        );
        final isCompanionModEnabled = companionMod?.hasEnabledVariant == true;
        multiSplitController.areas = areas;
        final textColor = Theme.of(context).colorScheme.onSurface;
        final replacementPoolString = "Portrait Pool";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const .all(4),
              child: SizedBox(
                height: 50,
                child: Card(
                  child: Padding(
                    padding: const .only(left: 8, right: 8),
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: .center,
                          children: [
                            if (!isCompanionModEnabled)
                              buildCompanionModWarningIcon(theme, companionMod),
                            Padding(
                              padding: const .only(),
                              child: MovingTooltipWidget.text(
                                message:
                                    "Portrait Viewer: View and search portraits from your mods."
                                    "\nPortrait Replacer: Drag and drop portraits from the right pane to replace portraits on the left pane.",
                                child: ModeSwitcher(
                                  selected: controllerState.mode,
                                  modes: {
                                    PortraitsMode.viewer: 'Viewer',
                                    PortraitsMode.replacer: 'Replacer',
                                  },
                                  modeIcons: {
                                    PortraitsMode.viewer: const Icon(
                                      Icons.portrait,
                                    ),
                                    PortraitsMode.replacer: const Icon(
                                      Icons.swap_horiz,
                                    ),
                                  },
                                  onChanged: (value) {
                                    notifier.setMode(value);
                                  },
                                ),
                              ),
                              // Text(
                              //   'Portrait${inReplaceMode ? ' Replacer' : ' Viewer'}',
                              //   style: theme.textTheme.headlineSmall?.copyWith(
                              //     fontSize: 20,
                              //   ),
                              // ),
                            ),
                            // if (!controllerState.inReplaceMode)
                            MovingTooltipWidget.text(
                              message:
                                  "Displays images that are *likely* to be portraits from the highest version of each mod."
                                  "\n\nBecause mods may use any image as a portrait and load images dynamically in code, this is not an exact science, but best guesses."
                                  "\nPortraits must be:"
                                  "\n- Square"
                                  "\n- Between 128x128 and 256x256"
                                  "\n- An image file",
                              child: Padding(
                                padding: const .only(left: 8, right: 8),
                                child: Icon(Icons.info),
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  controllerState.isLoading ? null : notifier.refreshPortraits,
                              icon: RotationTransition(
                                turns: _refreshSpinController,
                                child: const Icon(Icons.refresh),
                              ),
                            ),
                            // const SizedBox(width: 4),
                            // MovingTooltipWidget.text(
                            //   message:
                            //       "In this mode, drag and drop images from the right pane to replace images on the left pane.",
                            //   child: TriOSToolbarCheckboxButton(
                            //     text: "Replace Mode",
                            //     value: inReplaceMode,
                            //     onChanged: (value) {
                            //       setState(() {
                            //         mode = (value ?? false)
                            //             ? _PortraitsMode.replacer
                            //             : _PortraitsMode.viewer;
                            //       });
                            //     },
                            //   ),
                            // ),
                            const SizedBox(width: 8),
                            if (controllerState.inReplaceMode)
                              Padding(
                                padding: const .only(left: 8),
                                child: TriOSToolbarItem(
                                  child: TextButton.icon(
                                    icon: Icon(Icons.help, color: textColor),
                                    label: Text(
                                      "Tutorial",
                                      style: TextStyle(color: textColor),
                                    ),
                                    onPressed: () => showMyDialog(
                                      context,
                                      title: Text("Portrait Replacement"),
                                      body: [
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 800,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: .start,
                                            children: [
                                              Text(
                                                "How To Use",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                              Text(
                                                "On the left side are the portraits that you will see in-game."
                                                "\nOn the right side is the $replacementPoolString - your options for replacing images on the left."
                                                "\n\nGrab portraits from the right side and move them to the left side to replace what you see in-game.",
                                              ),
                                              const SizedBox(height: 24),
                                              TriOSExpansionTile(
                                                leading: const Icon(
                                                  Icons.menu_book,
                                                ),
                                                title: Text("Under the Hood"),
                                                children: [
                                                  Padding(
                                                    padding: const .all(8.0),
                                                    child: Text(
                                                      "A list of portraits to replace is saved as a json file (in the ${Constants.appName} data folder, which is synced one-way to the Companion Mod)."
                                                      "\nThe ${Constants.appName} Companion Mod reads that file when you load your game, then swaps the portraits for that game session only."
                                                      "\nIt does not change any mod files - replacement is all done in-memory, in-game.",
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            // if (Constants.currentVersion <
                            //     Version.parse("1.3.0"))
                            //   TextButton.icon(
                            //     icon: const Icon(Icons.construction),
                            //     label: const Text("UNDER CONSTRUCTION"),
                            //     style: ButtonStyle(
                            //       foregroundColor: WidgetStateProperty.all(
                            //         theme.colorScheme.error,
                            //       ),
                            //     ),
                            //     onPressed: () => {
                            //       showAlertDialog(
                            //         context,
                            //         title: "Under Construction",
                            //         content:
                            //             "Portrait Replacement will be fully finished and tested in TriOS v1.3.0!"
                            //             "\n\nIf you *really* want to try it now (I tested it quickly and it worked, but I didn't do 'I am confident in releasing this' testing),"
                            //             "\ninstall the TriOS Companion Mod from Settings - Debugging - Force Replace TriOS Companion Mod. Portrait replacements won't show ingame without that enabled.",
                            //       ),
                            //     },
                            //   ),
                            const SizedBox(width: 8),
                            // Only show center search box when not in replace mode
                            const Spacer(),
                            if (!controllerState.inReplaceMode)
                              ExpandingConstrainedAlignedWidget(
                                minWidth: 200,
                                maxWidth: 350,
                                alignment: Alignment.centerRight,
                                child: buildSearchBox(),
                              ),
                            const SizedBox(width: 8),
                            _buildPortraitSizeControl(theme),
                            OverflowMenuButton(
                              menuItems: [
                                OverflowMenuItem(
                                  title: "View Replacements",
                                  icon: Icons.swap_horiz,
                                  onTap: () =>
                                      _showReplacementsDialog(replacements),
                                ).toEntry(0),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const .only(left: 8, right: 8),
                child: MultiSplitViewTheme(
                  data: MultiSplitViewThemeData(
                    dividerThickness: 24,
                    // dividerPainter: DividerPainters.grooved1(
                    //   color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    //   highlightedColor: theme.colorScheme.onSurface,
                    //   highlightedThickness: 2,
                    //   backgroundColor: theme.colorScheme.surfaceContainer,
                    //   animationDuration: const Duration(milliseconds: 100),
                    // ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      if (!controllerState.inReplaceMode)
                        Padding(
                          padding: const .only(left: 8, bottom: 6),
                          child: Text(
                            '${total ?? "..."} images${total != visible ? " ($visible shown)" : ""}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: MultiSplitView(
                          controller: multiSplitController,
                          resizable: false,
                          axis: Axis.horizontal,
                          dividerBuilder:
                              (
                                axis,
                                index,
                                resizable,
                                dragging,
                                highlighted,
                                themeData,
                              ) {
                                return Container(
                                  color: dragging
                                      ? theme.colorScheme.surfaceContainer
                                            .withValues(alpha: 1)
                                      : theme.colorScheme.surfaceContainer
                                            .withValues(alpha: 0.8),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: (IntRange(1, 10))
                                        .map(
                                          (i) => Icon(
                                            Icons.keyboard_double_arrow_left,
                                            color: highlighted
                                                ? theme.colorScheme.onSurface
                                                      .withValues(alpha: 1)
                                                : theme.colorScheme.onSurface
                                                      .withValues(alpha: 0.8),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                );
                              },
                          builder: (context, area) {
                            switch (area.id) {
                              case 'main':
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFiltersSection(
                                      theme,
                                      filterItems,
                                      showOnlyYourChangesFilter: true,
                                    ),
                                    Expanded(
                                      child: PortraitsGridView(
                                        modsAndImages: sortedImages,
                                        allPortraits: modsAndImages,
                                        replacements: replacements,
                                        showPickReplacementIcon: true,
                                        portraitSize: controllerState.portraitSize,
                                        onSelectedPortraitToReplace:
                                            _onSelectedPortraitToReplace,
                                        onAddRandomReplacement:
                                            _addRandomReplacement,
                                      ),
                                    ),
                                  ],
                                );
                              case 'left':
                                final leftFilteredImages =
                                    notifier.getFilteredImages(
                                      FilterPane.left,
                                      allMods,
                                    );

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFiltersSection(
                                      theme,
                                      filterItems,
                                      pane: FilterPane.left,
                                      showOnlyYourChangesFilter: true,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: _buildGridSearchBar(
                                                  _leftSearchController,
                                                  "Filter...",
                                                  FilterPane.left,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Align(
                                            alignment: AlignmentDirectional
                                                .centerStart,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                                bottom: 4,
                                              ),
                                              child: Text(
                                                '${leftFilteredImages.length} images',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: PortraitsGridView(
                                              modsAndImages: leftFilteredImages,
                                              allPortraits: modsAndImages,
                                              replacements: replacements,
                                              showPickReplacementIcon: false,
                                              portraitSize: controllerState.portraitSize,
                                              onAddRandomReplacement:
                                                  _addRandomReplacement,
                                              onSelectedPortraitToReplace:
                                                  _onSelectedPortraitToReplace,
                                              onAcceptDraggable:
                                                  (original, replacement) {
                                                    ref
                                                        .read(
                                                          AppState
                                                              .portraitReplacementsManager
                                                              .notifier,
                                                        )
                                                        .saveReplacement(
                                                          original,
                                                          replacement,
                                                        );
                                                  },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              case 'right':
                                final rightFilteredImages =
                                    notifier.getFilteredImages(
                                      FilterPane.right,
                                      allMods,
                                    );

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFiltersSection(
                                      theme,
                                      filterItems,
                                      pane: FilterPane.right,
                                      showOnlyYourChangesFilter: false,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                replacementPoolString,
                                                style:
                                                    theme.textTheme.titleLarge,
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding: const .only(
                                                    left: 8.0,
                                                  ),
                                                  child: _buildGridSearchBar(
                                                    _rightSearchController,
                                                    "Filter...",
                                                    FilterPane.right,
                                                  ),
                                                ),
                                              ),
                                              MovingTooltipWidget.text(
                                                message:
                                                    "Import custom images to use as portrait replacements",
                                                child: IconButton(
                                                  onPressed: () => ref
                                                      .read(
                                                        portraitsPageControllerProvider
                                                            .notifier,
                                                      )
                                                      .importPortraits(context),
                                                  icon: const Icon(
                                                    Icons.add_photo_alternate,
                                                    size: 22,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Align(
                                            alignment: AlignmentDirectional
                                                .centerStart,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                                bottom: 4,
                                              ),
                                              child: Text(
                                                '${rightFilteredImages.length} images',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: PortraitsGridView(
                                              modsAndImages:
                                                  rightFilteredImages,
                                              allPortraits: modsAndImages,
                                              replacements: {},
                                              showPickReplacementIcon: false,
                                              portraitSize: controllerState.portraitSize,
                                              onAddRandomReplacement:
                                                  _addRandomReplacement,
                                              onSelectedPortraitToReplace:
                                                  _onSelectedPortraitToReplace,
                                              isDraggable: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              default:
                                return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    _cachedBuild = result;
    return result;
  }

  Padding buildCompanionModWarningIcon(ThemeData theme, Mod? companionMod) {
    return Padding(
      padding: const .all(0),
      child: Stack(
        children: [
          Padding(
            padding: const .all(8.0),
            child: Opacity(
              opacity: 0.9,
              child: Blur(
                blur: 5,
                child: Icon(
                  Icons.warning,
                  color: theme.colorScheme.error.darker(20),
                ),
              ),
            ),
          ),
          MovingTooltipWidget.text(
            message: companionMod == null
                ? "${Constants.appName} Companion mod not found!\nPortrait Replacement will not work.\n\nClick to install it."
                : "${Constants.appName} Companion mod is not enabled. Portrait replacements will not work.\n\nClick to enable it.",
            child: IconButton(
              onPressed: () {
                if (companionMod == null) {
                  ref
                      .read(companionModManagerProvider)
                      .fullySetUpCompanionMod();
                } else {
                  ref
                      .read(modManager.notifier)
                      .changeActiveModVariant(
                        companionMod,
                        companionMod.findHighestVersion,
                      );
                }
              },
              icon: Icon(Icons.warning, color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  SizedBox buildSearchBox() {
    return SizedBox(
      height: 30,
      child: SearchAnchor(
        searchController: _searchController,
        builder: (BuildContext context, SearchController controller) {
          return SearchBar(
            controller: controller,
            leading: const Icon(Icons.search),
            hintText: "Filter...",
            trailing: [
              controller.value.text.isEmpty
                  ? Container()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      constraints: const BoxConstraints(),
                      padding: .zero,
                      onPressed: () {
                        controller.clear();
                        ref
                            .read(portraitsPageControllerProvider.notifier)
                            .updateSearchQuery(FilterPane.main, '');
                      },
                    ),
            ],
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainer,
            ),
            onChanged: (value) {
              ref
                  .read(portraitsPageControllerProvider.notifier)
                  .updateSearchQuery(FilterPane.main, value);
            },
          );
        },
        suggestionsBuilder:
            (BuildContext context, SearchController controller) {
              return [];
            },
      ),
    );
  }

  @override
  void dispose() {
    _refreshSpinController.dispose();
    _searchController.dispose();
    _leftSearchController.dispose();
    _rightSearchController.dispose();
    _filterScrollController.dispose();
    _leftFilterScrollController.dispose();
    _rightFilterScrollController.dispose();
    super.dispose();
  }

  void _onSelectedPortraitToReplace(Portrait selectedPortrait) {
    final notifier = ref.read(portraitsPageControllerProvider.notifier);
    notifier.updateSearchQuery(
      FilterPane.left,
      selectedPortrait.relativePath,
    );
    notifier.setMode(PortraitsMode.replacer);
  }

  Future<void> _addRandomReplacement(
    Portrait originalPortrait,
    List<({Portrait image, ModVariant? variant})> allPortraits,
  ) async {
    try {
      // Filter out the original portrait and get a random replacement
      final otherPortraits = allPortraits
          .where((item) => item.image.hash != originalPortrait.hash)
          .toList();

      if (otherPortraits.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No other portraits available for replacement'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final random = Random();
      final randomPortrait =
          otherPortraits[random.nextInt(otherPortraits.length)];

      final replacementsManager = ref.read(
        AppState.portraitReplacementsManager.notifier,
      );
      // Save the replacement
      await replacementsManager.saveReplacement(
        originalPortrait,
        randomPortrait.image,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Replacement added: ${originalPortrait.imageFile.path.split('\\').last} -> ${randomPortrait.image.imageFile.path.split('\\').last}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      Fimber.i(
        'Random replacement added: ${originalPortrait.hash} -> ${randomPortrait.image.imageFile.path}',
      );
    } catch (e) {
      Fimber.e('Error adding random replacement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding replacement: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class ReplacementsDialog extends StatelessWidget {
  final Map<String, Portrait> replacements;
  final Map<String, Portrait> hashToPortrait;
  final Function(Portrait)? onDelete;

  const ReplacementsDialog({
    super.key,
    required this.replacements,
    required this.hashToPortrait,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Portrait Replacements'),
      content: SizedBox(
        width: 800,
        height: 600,
        child: replacements.isEmpty
            ? const Center(child: Text('No portrait replacements found.'))
            : StatefulBuilder(
                builder: (context, setState) {
                  return ListView.builder(
                    itemCount: replacements.length,
                    itemBuilder: (context, index) {
                      final entry = replacements.entries.elementAt(index);
                      final originalHash = entry.key;
                      final replacementPath = entry.value;

                      final original = hashToPortrait[originalHash];
                      if (original == null) {
                        return const Center(
                          child: Text('Original portrait not found'),
                        );
                      }
                      return ReplacementListItem(
                        originalHash: originalHash,
                        replacementPath: replacementPath.imageFile.path,
                        originalPortrait: original,
                        onDelete: (portrait) {
                          setState(() {
                            onDelete?.call(portrait);
                            replacements.remove(originalHash);
                          });
                        },
                      );
                    },
                  );
                },
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
}

class ReplacementListItem extends StatelessWidget {
  final String originalHash;
  final String replacementPath;
  final Portrait originalPortrait;
  final Function(Portrait)? onDelete;

  const ReplacementListItem({
    super.key,
    required this.originalHash,
    required this.replacementPath,
    required this.originalPortrait,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final replacementFile = File(replacementPath);
    final fileExists = replacementFile.existsSync();
    final originalExists = originalPortrait.imageFile.existsSync();

    return Card(
      child: Padding(
        padding: const .all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original portrait
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(
                  color: originalExists ? Colors.grey : Colors.red,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: originalExists
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        originalPortrait.imageFile,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, color: Colors.red),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, size: 24),
                          Text('Original', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            // Arrow
            const Padding(
              padding: .symmetric(vertical: 20),
              child: Icon(Icons.arrow_forward, size: 24),
            ),
            const SizedBox(width: 8),
            // Replacement image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(
                  color: fileExists ? Colors.grey : Colors.red,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: fileExists
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        replacementFile,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, color: Colors.red),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.broken_image, color: Colors.red),
                    ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original: ${originalPortrait.imageFile.path.split(Platform.pathSeparator).last ?? "Unknown"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (originalExists)
                    Text(
                      originalPortrait.imageFile.path,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  if (!originalExists)
                    const Text(
                      'Original file not found',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Replacement: ${replacementFile.path.split(Platform.pathSeparator).last}',
                    style: TextStyle(color: fileExists ? null : Colors.red),
                  ),
                  Text(
                    replacementFile.path,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (!fileExists)
                    const Text(
                      'Replacement file not found',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  if (fileExists)
                    Text(
                      'Size: ${replacementFile.lengthSync().bytesAsReadableKB()}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                if (originalExists)
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () =>
                        launchUrlString(originalPortrait.imageFile.path),
                    tooltip: 'Open original image',
                  ),
                if (fileExists)
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => launchUrlString(replacementPath),
                    tooltip: 'Open replacement image',
                  ),
                if (fileExists)
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () =>
                        launchUrlString(replacementFile.parent.path),
                    tooltip: 'Open folder',
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => onDelete?.call(originalPortrait),
                    tooltip: 'Remove replacement',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
