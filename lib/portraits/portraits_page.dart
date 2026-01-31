import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:path/path.dart' as p;
import 'package:trios/companion_mod/companion_mod_manager.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/portraits/portrait_metadata.dart';
import 'package:trios/portraits/portrait_metadata_manager.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/portraits/portrait_replacements_manager.dart';
import 'package:trios/portraits/portrait_scanner.dart';
import 'package:trios/portraits/portraits_gridview.dart';
import 'package:trios/portraits/portraits_page_controller.dart';
import 'package:trios/shipViewer/filter_widget.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/search.dart';
import 'package:trios/widgets/blur.dart';
import 'package:trios/widgets/expanding_constrained_aligned_widget.dart';
import 'package:trios/widgets/mode_switcher.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/multi_split_mixin_view.dart';
import 'package:trios/widgets/overflow_menu_button.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:trios/thirdparty/dartx/range.dart';

class PortraitsPage extends ConsumerStatefulWidget {
  const PortraitsPage({super.key});

  @override
  ConsumerState<PortraitsPage> createState() => _PortraitsPageState();
}

enum _PortraitsMode { viewer, replacer }

/// Identifies which filter pane to use.
enum _FilterPane { main, left, right }

/// Helper class to hold portrait info for filtering.
class _PortraitFilterItem {
  final Portrait portrait;
  final ModVariant? variant;
  final PortraitMetadata? metadata;

  _PortraitFilterItem({
    required this.portrait,
    required this.variant,
    this.metadata,
  });

  String get modName => variant?.modInfo.nameOrId ?? 'Vanilla';

  String get genderString => metadata?.gender?.toString() ?? 'Unknown';
}

class _PortraitsPageState extends ConsumerState<PortraitsPage>
    with AutomaticKeepAliveClientMixin<PortraitsPage>, MultiSplitViewMixin {
  @override
  bool get wantKeepAlive => true;
  final SearchController _searchController = SearchController();
  final SearchController _leftSearchController = SearchController();
  final SearchController _rightSearchController = SearchController();
  final ScrollController _filterScrollController = ScrollController();
  final ScrollController _leftFilterScrollController = ScrollController();
  final ScrollController _rightFilterScrollController = ScrollController();

  bool showOnlyReplaced = false;
  bool showOnlyEnabledMods = false;
  bool showOnlyWithMetadata = true; // "Confirmed Portraits" filter
  bool showFilters = true;
  _PortraitsMode mode = _PortraitsMode.viewer;
  static const double _portraitSizeMin = 64;
  static const double _portraitSizeMax = 192;
  static const double _portraitSizeStep = 8;
  double _portraitSize = 128;

  // Filter categories for the main/viewer sidebar
  late final GridFilter<_PortraitFilterItem> _modFilter;
  late final GridFilter<_PortraitFilterItem> _genderFilter;
  late List<GridFilter<_PortraitFilterItem>> _filterCategories;

  // Filter categories for the left pane (Replacer mode)
  late final GridFilter<_PortraitFilterItem> _leftModFilter;
  late final GridFilter<_PortraitFilterItem> _leftGenderFilter;
  late List<GridFilter<_PortraitFilterItem>> _leftFilterCategories;
  bool _leftShowOnlyWithMetadata = true;
  bool _leftShowOnlyReplaced = false;
  bool _leftShowOnlyEnabledMods = false;
  bool _leftShowFilters = true;

  // Filter categories for the right pane (Replacer mode)
  late final GridFilter<_PortraitFilterItem> _rightModFilter;
  late final GridFilter<_PortraitFilterItem> _rightGenderFilter;
  late List<GridFilter<_PortraitFilterItem>> _rightFilterCategories;
  bool _rightShowOnlyWithMetadata = true;
  bool _rightShowOnlyReplaced = false;
  bool _rightShowOnlyEnabledMods = false;
  bool _rightShowFilters = true;

  @override
  void initState() {
    super.initState();
    // Main/Viewer filters
    _modFilter = GridFilter<_PortraitFilterItem>(
      name: 'Mod',
      valueGetter: (item) => item.modName,
    );
    _genderFilter = GridFilter<_PortraitFilterItem>(
      name: 'Gender',
      valueGetter: (item) => item.genderString,
    );
    _filterCategories = [_modFilter, _genderFilter];

    // Left pane filters (Replacer mode)
    _leftModFilter = GridFilter<_PortraitFilterItem>(
      name: 'Mod',
      valueGetter: (item) => item.modName,
    );
    _leftGenderFilter = GridFilter<_PortraitFilterItem>(
      name: 'Gender',
      valueGetter: (item) => item.genderString,
    );
    _leftFilterCategories = [_leftModFilter, _leftGenderFilter];

    // Right pane filters (Replacer mode)
    _rightModFilter = GridFilter<_PortraitFilterItem>(
      name: 'Mod',
      valueGetter: (item) => item.modName,
    );
    _rightGenderFilter = GridFilter<_PortraitFilterItem>(
      name: 'Gender',
      valueGetter: (item) => item.genderString,
    );
    _rightFilterCategories = [_rightModFilter, _rightGenderFilter];
  }

  bool get inReplaceMode => mode == _PortraitsMode.replacer;

  @override
  List<Area> get areas => inReplaceMode
      ? [Area(id: 'left'), Area(id: 'right')]
      : [Area(id: 'main')];

  void _refreshPortraits() {
    ref.read(AppState.portraitMetadata.notifier).rescan();
    ref.read(AppState.portraits.notifier).rescan();
  }

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

  List<({Portrait image, ModVariant? variant})> _filterImages(
    List<({Portrait image, ModVariant? variant})> images,
    String query,
    Map<String, PortraitMetadata> metadata,
  ) {
    if (query.isEmpty) return images;

    final lowerQuery = query.toLowerCase();

    return images.where((item) {
      final variant = item.variant;
      final portrait = item.image;

      // Check vanilla
      if (lowerQuery == 'vanilla' && variant == null) return true;

      // Check mod name
      if (searchModVariants([?variant], query).isNotEmpty) return true;

      // Check file path
      if (portrait.imageFile.path.toLowerCase().contains(lowerQuery))
        return true;

      // Check portrait metadata (gender, factions, portrait ID)
      final portraitMetadata = metadata.getMetadataFor(portrait.relativePath);
      if (portraitMetadata.hasMetadata) {
        // Check portrait ID (from settings.json)
        if (portraitMetadata.portraitId?.toLowerCase().contains(lowerQuery) ??
            false) {
          return true;
        }

        // Check gender (male, female)
        if (portraitMetadata.gender.toString().toLowerCase().contains(
          lowerQuery,
        )) {
          return true;
        }

        // Check faction names
        for (final faction in portraitMetadata.factions) {
          if (faction.id.toLowerCase().contains(lowerQuery) ||
              (faction.displayName?.toLowerCase().contains(lowerQuery) ??
                  false)) {
            return true;
          }
        }
      }

      return false;
    }).toList();
  }

  /// Returns the filter categories for the specified pane.
  List<GridFilter<_PortraitFilterItem>> _getFilterCategories(_FilterPane pane) {
    return switch (pane) {
      _FilterPane.main => _filterCategories,
      _FilterPane.left => _leftFilterCategories,
      _FilterPane.right => _rightFilterCategories,
    };
  }

  /// Returns the scroll controller for the specified pane.
  ScrollController _getFilterScrollController(_FilterPane pane) {
    return switch (pane) {
      _FilterPane.main => _filterScrollController,
      _FilterPane.left => _leftFilterScrollController,
      _FilterPane.right => _rightFilterScrollController,
    };
  }

  /// Returns whether filters are visible for the specified pane.
  bool _getShowFilters(_FilterPane pane) {
    return switch (pane) {
      _FilterPane.main => showFilters,
      _FilterPane.left => _leftShowFilters,
      _FilterPane.right => _rightShowFilters,
    };
  }

  /// Sets whether filters are visible for the specified pane.
  void _setShowFilters(_FilterPane pane, bool value) {
    setState(() {
      switch (pane) {
        case _FilterPane.main:
          showFilters = value;
        case _FilterPane.left:
          _leftShowFilters = value;
        case _FilterPane.right:
          _rightShowFilters = value;
      }
    });
  }

  /// Returns the "Confirmed Portraits" filter value for the specified pane.
  bool _getShowOnlyWithMetadata(_FilterPane pane) {
    return switch (pane) {
      _FilterPane.main => showOnlyWithMetadata,
      _FilterPane.left => _leftShowOnlyWithMetadata,
      _FilterPane.right => _rightShowOnlyWithMetadata,
    };
  }

  /// Sets the "Confirmed Portraits" filter value for the specified pane.
  void _setShowOnlyWithMetadata(_FilterPane pane, bool value) {
    setState(() {
      switch (pane) {
        case _FilterPane.main:
          showOnlyWithMetadata = value;
        case _FilterPane.left:
          _leftShowOnlyWithMetadata = value;
        case _FilterPane.right:
          _rightShowOnlyWithMetadata = value;
      }
    });
  }

  /// Returns the "View Replaced" filter value for the specified pane.
  bool _getShowOnlyReplaced(_FilterPane pane) {
    return switch (pane) {
      _FilterPane.main => showOnlyReplaced,
      _FilterPane.left => _leftShowOnlyReplaced,
      _FilterPane.right => _rightShowOnlyReplaced,
    };
  }

  /// Sets the "View Replaced" filter value for the specified pane.
  void _setShowOnlyReplaced(_FilterPane pane, bool value) {
    setState(() {
      switch (pane) {
        case _FilterPane.main:
          showOnlyReplaced = value;
        case _FilterPane.left:
          _leftShowOnlyReplaced = value;
        case _FilterPane.right:
          _rightShowOnlyReplaced = value;
      }
    });
  }

  /// Returns the "Only Enabled" filter value for the specified pane.
  bool _getShowOnlyEnabledMods(_FilterPane pane) {
    return switch (pane) {
      _FilterPane.main => showOnlyEnabledMods,
      _FilterPane.left => _leftShowOnlyEnabledMods,
      _FilterPane.right => _rightShowOnlyEnabledMods,
    };
  }

  /// Sets the "Only Enabled" filter value for the specified pane.
  void _setShowOnlyEnabledMods(_FilterPane pane, bool value) {
    setState(() {
      switch (pane) {
        case _FilterPane.main:
          showOnlyEnabledMods = value;
        case _FilterPane.left:
          _leftShowOnlyEnabledMods = value;
        case _FilterPane.right:
          _rightShowOnlyEnabledMods = value;
      }
    });
  }

  /// Apply grid filter categories (mod, gender) to the list of portraits.
  List<({Portrait image, ModVariant? variant})> _applyGridFilters(
    List<({Portrait image, ModVariant? variant})> images,
    Map<String, PortraitMetadata> metadata, {
    _FilterPane pane = _FilterPane.main,
  }) {
    final filterCategories = _getFilterCategories(pane);

    // Convert to filter items for processing
    var items = images.map((item) {
      final portraitMetadata = metadata.getMetadataFor(item.image.relativePath);
      return _PortraitFilterItem(
        portrait: item.image,
        variant: item.variant,
        metadata: portraitMetadata.hasMetadata ? portraitMetadata : null,
      );
    }).toList();

    // Apply each filter category
    for (final filter in filterCategories) {
      if (filter.hasActiveFilters) {
        items = items.where((item) {
          final value = filter.valueGetter(item);
          final filterState = filter.filterStates[value];

          if (filterState == false) return false; // Explicitly excluded

          final hasIncludedValues = filter.filterStates.values.contains(true);
          if (hasIncludedValues) {
            return filterState == true; // Must be explicitly included
          }

          return true; // Only exclusions, allow anything not excluded
        }).toList();
      }
    }

    // Convert back to the original format
    return items
        .map((item) => (image: item.portrait, variant: item.variant))
        .toList();
  }

  void _clearAllFilters(_FilterPane pane) {
    setState(() {
      for (final filter in _getFilterCategories(pane)) {
        filter.filterStates.clear();
      }
    });
  }

  void _updateFilterStates(
    GridFilter<_PortraitFilterItem> filter,
    Map<String, bool?> states,
  ) {
    setState(() {
      filter.filterStates.clear();
      filter.filterStates.addAll(states);
    });
  }

  Widget _buildFiltersSection(
    ThemeData theme,
    List<_PortraitFilterItem> filterItems, {
    _FilterPane pane = _FilterPane.main,
    required bool showOnlyYourChangesFilter,
  }) {
    if (!_getShowFilters(pane)) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Card(
          child: InkWell(
            onTap: () => _setShowFilters(pane, true),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: MovingTooltipWidget.text(
                message: "Show filters",
                child: const Icon(Icons.filter_list, size: 16),
              ),
            ),
          ),
        ),
      );
    }

    return _buildFilterPanel(
      theme,
      filterItems,
      pane: pane,
      showOnlyYourChangesFilter: showOnlyYourChangesFilter,
    );
  }

  Widget _buildFilterPanel(
    ThemeData theme,
    List<_PortraitFilterItem> filterItems, {
    _FilterPane pane = _FilterPane.main,
    required bool showOnlyYourChangesFilter,
  }) {
    final filterCategories = _getFilterCategories(pane);
    final scrollController = _getFilterScrollController(pane);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          child: Scrollbar(
            thumbVisibility: true,
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              child: SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        MovingTooltipWidget.text(
                          message: "Hide filters",
                          child: InkWell(
                            onTap: () => _setShowFilters(pane, false),
                            borderRadius: BorderRadius.circular(
                              ThemeManager.cornerRadius,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  const Icon(Icons.filter_list, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Filters',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (filterCategories.any((f) => f.hasActiveFilters))
                          TriOSToolbarItem(
                            elevation: 0,
                            child: TextButton.icon(
                              onPressed: () => _clearAllFilters(pane),
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Clear'),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Scrollable filter content
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(
                          context,
                        ).copyWith(scrollbars: false),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Checkbox filters section
                              _buildCheckboxFilters(
                                theme,
                                pane: pane,
                                showOnlyYourChangesFilter:
                                    showOnlyYourChangesFilter,
                              ),
                              const SizedBox(height: 8),
                              // Grid filter categories (Mod, Gender)
                              ...filterCategories.map((filter) {
                                return GridFilterWidget<_PortraitFilterItem>(
                                  filter: filter,
                                  items: filterItems,
                                  filterStates: filter.filterStates,
                                  onSelectionChanged: (states) {
                                    _updateFilterStates(filter, states);
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxFilters(
    ThemeData theme, {
    _FilterPane pane = _FilterPane.main,
    required bool showOnlyYourChangesFilter,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Confirmed Portraits" checkbox
            MovingTooltipWidget.text(
              message:
                  "Only show images that are confirmed portraits."
                  "\n\nPortraits defined in .faction files have genders."
                  "\nPortraits from settings.json files do not.",
              child: CheckboxListTile(
                title: const Text('Confirmed Portraits'),
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: EdgeInsets.zero,
                value: _getShowOnlyWithMetadata(pane),
                onChanged: (value) =>
                    _setShowOnlyWithMetadata(pane, value ?? true),
              ),
            ),
            // "View Replaced" checkbox
            if (showOnlyYourChangesFilter)
              MovingTooltipWidget.text(
                message: "Only show images that have replacements",
                child: CheckboxListTile(
                  title: const Text('Only Your Changes'),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  value: _getShowOnlyReplaced(pane),
                  onChanged: (value) =>
                      _setShowOnlyReplaced(pane, value ?? false),
                ),
              ),
            // "Only Enabled" checkbox
            MovingTooltipWidget.text(
              message: "Only show images from enabled mods",
              child: CheckboxListTile(
                title: const Text('Only Enabled Mods'),
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: EdgeInsets.zero,
                value: _getShowOnlyEnabledMods(pane),
                onChanged: (value) =>
                    _setShowOnlyEnabledMods(pane, value ?? false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSearchBar(SearchController controller, String hintText) {
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
                          setState(() {});
                        },
                      ),
              ],
              backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainer,
              ),
              onChanged: (value) {
                setState(() {});
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
                  value: _portraitSize,
                  min: _portraitSizeMin,
                  max: _portraitSizeMax,
                  divisions:
                      ((_portraitSizeMax - _portraitSizeMin) /
                              _portraitSizeStep)
                          .round(),
                  label: _portraitSize.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _portraitSize = value;
                    });
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

    // Watch the portraits provider and loading state
    final portraitsAsync = ref.watch(AppState.portraits);

    return portraitsAsync.when(
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
              onPressed: _refreshPortraits,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (portraits) {
        // TODO There's no way this is fast.
        final loadedReplacements =
            ref.watch(AppState.portraitReplacementsManager).value ?? {};
        final replacements = loadedReplacements
            .hydrateToPortraitMap(
              portraits.convertToPortraitMap(),
              logWarnings: !ref
                  .read(AppState.portraits.notifier)
                  .isLoadingPortraits,
            )
            .entries
            .where((element) => element.value != null)
            .toMap()
            .cast<String, Portrait>();

        // Get portrait metadata for filtering by gender/faction
        final portraitMetadata =
            ref.watch(AppState.portraitMetadata).value ?? {};

        final List<({Portrait image, ModVariant? variant})> modsAndImages =
            portraits.entries
                .expand(
                  (element) => element.value.map(
                    (e) => (variant: element.key, image: e),
                  ),
                )
                .toList();

        var sortedImages = sortModsAndImages(
          modsAndImages,
          r'graphics\\.*portraits\\',
        );

        if (!inReplaceMode && showOnlyReplaced) {
          sortedImages = filterToOnlyReplacedImages(sortedImages, replacements);
        }

        final allMods = ref.watch(AppState.mods);

        if (showOnlyEnabledMods) {
          sortedImages = filterToOnlyEnabledMods(sortedImages, allMods);
        }

        // Apply "Confirmed Portraits" filter (only show portraits with metadata)
        if (showOnlyWithMetadata) {
          sortedImages = sortedImages.where((item) {
            final meta = portraitMetadata.getMetadataFor(
              item.image.relativePath,
            );
            return meta.hasMetadata;
          }).toList();
        }

        // Apply grid filters (mod, gender)
        sortedImages = _applyGridFilters(sortedImages, portraitMetadata);

        // Apply search filter (only when not in replace mode)
        if (!inReplaceMode) {
          final query = _searchController.value.text;
          sortedImages = _filterImages(sortedImages, query, portraitMetadata);
        }

        // Create filter items for the sidebar (before search filter)
        final filterItems = modsAndImages.map((item) {
          final meta = portraitMetadata.getMetadataFor(item.image.relativePath);
          return _PortraitFilterItem(
            portrait: item.image,
            variant: item.variant,
            metadata: meta.hasMetadata ? meta : null,
          );
        }).toList();

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
                                  selected: mode,
                                  modes: {
                                    _PortraitsMode.viewer: 'Viewer',
                                    _PortraitsMode.replacer: 'Replacer',
                                  },
                                  modeIcons: {
                                    _PortraitsMode.viewer: const Icon(
                                      Icons.portrait,
                                    ),
                                    _PortraitsMode.replacer: const Icon(
                                      Icons.swap_horiz,
                                    ),
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      // Copy the Viewer search to the Replacer search if it's not empty
                                      if (_searchController.text.isNotEmpty) {
                                        _leftSearchController.text =
                                            _searchController.text;
                                      }
                                      mode = value;
                                    });
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
                            // if (!inReplaceMode)
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
                                  ref
                                      .read(AppState.portraits.notifier)
                                      .isLoadingPortraits
                                  ? null
                                  : _refreshPortraits,
                              icon:
                                  ref
                                      .watch(AppState.portraits.notifier)
                                      .isLoadingPortraits
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh),
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
                            if (inReplaceMode)
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
                            if (!inReplaceMode)
                              ExpandingConstrainedAlignedWidget(
                                minWidth: 200,
                                maxWidth: 350,
                                alignment: Alignment.centerRight,
                                child: buildSearchBox(),
                              ),
                            const SizedBox(width: 8),
                            const Spacer(),
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
                      if (!inReplaceMode)
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
                                        portraitSize: _portraitSize,
                                        onSelectedPortraitToReplace:
                                            _onSelectedPortraitToReplace,
                                        onAddRandomReplacement:
                                            _addRandomReplacement,
                                      ),
                                    ),
                                  ],
                                );
                              case 'left':
                                // Start with base sorted images
                                var leftSortedImages = modsAndImages.toList();

                                // Apply "Only Enabled" filter
                                if (_getShowOnlyEnabledMods(_FilterPane.left)) {
                                  leftSortedImages = filterToOnlyEnabledMods(
                                    leftSortedImages,
                                    allMods,
                                  );
                                }

                                // Apply "Confirmed Portraits" filter
                                if (_getShowOnlyWithMetadata(
                                  _FilterPane.left,
                                )) {
                                  leftSortedImages = leftSortedImages.where((
                                    item,
                                  ) {
                                    final meta = portraitMetadata
                                        .getMetadataFor(
                                          item.image.relativePath,
                                        );
                                    return meta.hasMetadata;
                                  }).toList();
                                }

                                // Apply grid filters (mod, gender)
                                leftSortedImages = _applyGridFilters(
                                  leftSortedImages,
                                  portraitMetadata,
                                  pane: _FilterPane.left,
                                );

                                // Apply "View Replaced" filter
                                if (_getShowOnlyReplaced(_FilterPane.left)) {
                                  leftSortedImages = filterToOnlyReplacedImages(
                                    leftSortedImages,
                                    replacements,
                                  );
                                }

                                // Apply search filter
                                final leftFilteredImages = _filterImages(
                                  leftSortedImages,
                                  _leftSearchController.value.text,
                                  portraitMetadata,
                                );

                                // Create filter items for left sidebar
                                final leftFilterItems = modsAndImages.map((
                                  item,
                                ) {
                                  final meta = portraitMetadata.getMetadataFor(
                                    item.image.relativePath,
                                  );
                                  return _PortraitFilterItem(
                                    portrait: item.image,
                                    variant: item.variant,
                                    metadata: meta.hasMetadata ? meta : null,
                                  );
                                }).toList();

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFiltersSection(
                                      theme,
                                      leftFilterItems,
                                      pane: _FilterPane.left,
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
                                              portraitSize: _portraitSize,
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
                                // Start with base sorted images
                                var rightSortedImages = modsAndImages.toList();

                                // Apply "Only Enabled" filter
                                if (_getShowOnlyEnabledMods(
                                  _FilterPane.right,
                                )) {
                                  rightSortedImages = filterToOnlyEnabledMods(
                                    rightSortedImages,
                                    allMods,
                                  );
                                }

                                // Apply "Confirmed Portraits" filter
                                if (_getShowOnlyWithMetadata(
                                  _FilterPane.right,
                                )) {
                                  rightSortedImages = rightSortedImages.where((
                                    item,
                                  ) {
                                    final meta = portraitMetadata
                                        .getMetadataFor(
                                          item.image.relativePath,
                                        );
                                    return meta.hasMetadata;
                                  }).toList();
                                }

                                // Apply grid filters (mod, gender)
                                rightSortedImages = _applyGridFilters(
                                  rightSortedImages,
                                  portraitMetadata,
                                  pane: _FilterPane.right,
                                );

                                // Apply "View Replaced" filter
                                if (_getShowOnlyReplaced(_FilterPane.right)) {
                                  rightSortedImages =
                                      filterToOnlyReplacedImages(
                                        rightSortedImages,
                                        replacements,
                                      );
                                }

                                // Apply search filter
                                final rightFilteredImages = _filterImages(
                                  rightSortedImages,
                                  _rightSearchController.value.text,
                                  portraitMetadata,
                                );

                                // Create filter items for right sidebar
                                final rightFilterItems = modsAndImages.map((
                                  item,
                                ) {
                                  final meta = portraitMetadata.getMetadataFor(
                                    item.image.relativePath,
                                  );
                                  return _PortraitFilterItem(
                                    portrait: item.image,
                                    variant: item.variant,
                                    metadata: meta.hasMetadata ? meta : null,
                                  );
                                }).toList();

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFiltersSection(
                                      theme,
                                      rightFilterItems,
                                      pane: _FilterPane.right,
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
                                              portraitSize: _portraitSize,
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
  }

  List<({Portrait image, ModVariant? variant})> filterToOnlyReplacedImages(
    List<({Portrait image, ModVariant? variant})> sortedImages,
    Map<String, Portrait> replacements,
  ) {
    return sortedImages
        .where((element) => replacements.containsKey(element.image.hash))
        .toList();
  }

  List<({Portrait image, ModVariant? variant})> filterToOnlyEnabledMods(
    List<({Portrait image, ModVariant? variant})> sortedImages,
    List<Mod> allMods,
  ) {
    return sortedImages
        .where(
          (element) =>
              element.variant == null ||
              element.variant?.mod(allMods)?.hasEnabledVariant == true,
        )
        .toList();
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
                        setState(() {});
                      },
                    ),
            ],
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainer,
            ),
            onChanged: (value) {
              setState(() {});
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

  List<({Portrait image, ModVariant? variant})> sortModsAndImages(
    List<({Portrait image, ModVariant? variant})> modsAndImages,
    String regexPattern,
  ) {
    final regex = RegExp(regexPattern);

    return modsAndImages..sort((a, b) {
      final aMatches = regex.hasMatch(a.image.imageFile.path);
      final bMatches = regex.hasMatch(b.image.imageFile.path);

      if (aMatches && !bMatches) return -1;
      if (!aMatches && bMatches) return 1;

      final variantComparison =
          a.variant?.modInfo.nameOrId.compareTo(
            b.variant?.modInfo.nameOrId ?? "",
          ) ??
          -1;
      if (variantComparison != 0) return variantComparison;

      return a.image.imageFile.path.compareTo(b.image.imageFile.path);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _leftSearchController.dispose();
    _rightSearchController.dispose();
    _filterScrollController.dispose();
    _leftFilterScrollController.dispose();
    _rightFilterScrollController.dispose();
    super.dispose();
  }

  void _onSelectedPortraitToReplace(Portrait selectedPortrait) {
    setState(() {
      _leftSearchController.text = selectedPortrait.relativePath;
      mode = _PortraitsMode.replacer;
    });
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
