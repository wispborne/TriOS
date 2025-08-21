import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/chipper/utils.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/portraits/portrait_replacements_manager.dart';
import 'package:trios/portraits/portraits_gridview.dart';
import 'package:trios/thirdparty/dartx/comparable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/search.dart';
import 'package:trios/widgets/MultiSplitViewMixin.dart';
import 'package:trios/widgets/blur.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/overflow_menu_button.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PortraitsPage extends ConsumerStatefulWidget {
  const PortraitsPage({super.key});

  @override
  ConsumerState<PortraitsPage> createState() => _PortraitsPageState();
}

class _PortraitsPageState extends ConsumerState<PortraitsPage>
    with AutomaticKeepAliveClientMixin<PortraitsPage>, MultiSplitViewMixin {
  @override
  bool get wantKeepAlive => true;
  final SearchController _searchController = SearchController();
  final SearchController _leftSearchController = SearchController();
  final SearchController _rightSearchController = SearchController();
  bool showOnlyReplaced = false;
  bool inReplaceMode = false;

  @override
  List<Area> get areas => inReplaceMode
      ? [Area(id: 'left'), Area(id: 'right')]
      : [Area(id: 'main')];

  void _refreshPortraits() {
    // Invalidate the provider to trigger a reload
    ref.invalidate(AppState.portraits);
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
      ),
    );
  }

  List<({Portrait image, ModVariant? variant})> _filterImages(
    List<({Portrait image, ModVariant? variant})> images,
    String query,
  ) {
    if (query.isEmpty) return images;

    return images.where((item) {
      final variant = item.variant;
      final portrait = item.image;

      return (query.toLowerCase() == 'vanilla' && variant == null) ||
          searchModVariants([?variant], query).isNotEmpty ||
          portrait.imageFile.path.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Widget _buildGridSearchBar(SearchController controller, String hintText) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
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
                        padding: EdgeInsets.zero,
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
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('Loading portraits...'),
            ),
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
            ref.watch(AppState.portraitReplacementsManager).valueOrNull ?? {};
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

        if (showOnlyReplaced) {
          sortedImages = sortedImages
              .where((element) => replacements.containsKey(element.image.hash))
              .toList();
        }

        // Apply search filter (only when not in replace mode)
        if (!inReplaceMode) {
          final query = _searchController.value.text;
          sortedImages = _filterImages(sortedImages, query);
        }

        final theme = Theme.of(context);
        final visible = sortedImages.length;
        final total = modsAndImages.length;
        final companionMod = ref
            .watch(AppState.mods)
            .firstWhereOrNull((it) => it.id == Constants.companionModId);
        final isCompanionModEnabled = companionMod?.hasEnabledVariant == true;
        multiSplitController.areas = areas;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: SizedBox(
                height: 50,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(),
                              child: Text(
                                'Portrait${inReplaceMode ? ' Replacer' : ' Viewer'}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            MovingTooltipWidget.text(
                              message:
                                  "Displays images that are *likely* to be portraits from your enabled or highest-version mods.\n\nBecause mods may use any image as a portrait, this is not an exact science, but best guesses.",
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.info),
                              ),
                            ),
                            if (!isCompanionModEnabled)
                              Padding(
                                padding: const EdgeInsets.all(0),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Opacity(
                                        opacity: 0.9,
                                        child: Blur(
                                          blur: 5,
                                          child: Icon(
                                            Icons.warning,
                                            color: theme.colorScheme.error
                                                .darker(20),
                                          ),
                                        ),
                                      ),
                                    ),
                                    MovingTooltipWidget.text(
                                      message: companionMod == null
                                          ? "${Constants.appName} Companion mod not found!"
                                          : "${Constants.appName} Companion mod is not enabled. Portrait replacements will not work.\n\nClick to enable it.",
                                      child: IconButton(
                                        onPressed: () {
                                          if (companionMod == null) return;
                                          ref
                                              .read(modManager.notifier)
                                              .changeActiveModVariant(
                                                companionMod,
                                                companionMod.findHighestVersion,
                                              );
                                        },
                                        icon: Icon(
                                          Icons.warning,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            TextButton.icon(
                              onPressed:
                                  ref
                                      .read(AppState.portraits.notifier)
                                      .isLoadingPortraits
                                  ? null
                                  : _refreshPortraits,
                              style: ButtonStyle(
                                foregroundColor: WidgetStateProperty.all(
                                  theme.colorScheme.onSurface,
                                ),
                              ),
                              icon:
                                  ref
                                      .read(AppState.portraits.notifier)
                                      .isLoadingPortraits
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh),
                              label: const Text('Reload'),
                            ),
                            const SizedBox(width: 8),
                            MovingTooltipWidget.text(
                              message:
                                  "In this mode, drag and drop images from the right pane to replace images on the left pane.",
                              child: TriOSToolbarCheckboxButton(
                                text: "Replace Mode",
                                value: inReplaceMode,
                                onChanged: (value) {
                                  setState(() {
                                    if (_searchController.text.isNotEmpty) {
                                      _leftSearchController.text =
                                          _searchController.text;
                                    }
                                    inReplaceMode = value ?? false;
                                  });
                                },
                              ),
                            ),
                            if (inReplaceMode)
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Text(
                                  "Tip: Drag from right to left",
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            if (Constants.currentVersion <
                                Version.parse("1.3.0"))
                              TextButton.icon(
                                icon: const Icon(Icons.construction),
                                label: const Text("UNDER CONSTRUCTION"),
                                style: ButtonStyle(
                                  foregroundColor: WidgetStateProperty.all(
                                    theme.colorScheme.error,
                                  ),
                                ),
                                onPressed: () => {
                                  showAlertDialog(
                                    context,
                                    title: "Under Construction",
                                    content:
                                        "Portrait Replacement will be fully finished and tested in TriOS v1.3.0!"
                                        "\n\nIf you *really* want to try it now (I tested it quickly and it worked, but I didn't do 'I am confident in releasing this' testing),"
                                        "\ninstall the TriOS Companion Mod from Settings - Debugging - Force Replace TriOS Companion Mod. Portrait replacements won't show ingame without that enabled.",
                                  ),
                                },
                              ),
                            const Spacer(),
                            // Only show center search box when not in replace mode
                            if (!inReplaceMode) Center(child: buildSearchBox()),
                            const SizedBox(width: 8),
                            MovingTooltipWidget.text(
                              message: "Only view images with replacements",
                              child: TriOSToolbarCheckboxButton(
                                text: "Replacements",
                                value: showOnlyReplaced,
                                onChanged: (value) => setState(
                                  () => showOnlyReplaced = value ?? false,
                                ),
                              ),
                            ),
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
                padding: const EdgeInsets.only(left: 8, right: 8),
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
                          padding: const EdgeInsets.only(left: 8, bottom: 6),
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
                                  child: Icon(
                                    Icons.keyboard_double_arrow_left,
                                    color: highlighted
                                        ? theme.colorScheme.onSurface
                                              .withValues(alpha: 1)
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.8),
                                  ),
                                );
                              },
                          builder: (context, area) {
                            switch (area.id) {
                              case 'main':
                                return PortraitsGridView(
                                  modsAndImages: sortedImages,
                                  allPortraits: modsAndImages,
                                  replacements: replacements,
                                  showPickReplacementIcon: true,
                                  onSelectedPortraitToReplace:
                                      _onSelectedPortraitToReplace,
                                  onAddRandomReplacement: _addRandomReplacement,
                                );
                              case 'left':
                                final leftFilteredImages = _filterImages(
                                  sortedImages,
                                  _leftSearchController.value.text,
                                );
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Padding(
                                        //   padding: const EdgeInsets.only(
                                        //     left: 8,
                                        //   ),
                                        //   child: Text(
                                        //     "Portraits",
                                        //     style: theme.textTheme.titleLarge,
                                        //   ),
                                        // ),
                                        // const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildGridSearchBar(
                                            _leftSearchController,
                                            "Filter...",
                                          ),
                                        ),
                                      ],
                                    ),
                                    Align(
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8,
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          '${leftFilteredImages.length} images',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.8),
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
                                        onAddRandomReplacement:
                                            _addRandomReplacement,
                                        onSelectedPortraitToReplace:
                                            _onSelectedPortraitToReplace,
                                        onAcceptDraggable: (original, replacement) {
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
                                );
                              case 'right':
                                final rightFilteredImages = _filterImages(
                                  sortedImages,
                                  _rightSearchController.value.text,
                                );
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: Text(
                                            "Replacements",
                                            style: theme.textTheme.titleLarge,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildGridSearchBar(
                                            _rightSearchController,
                                            "Filter...",
                                          ),
                                        ),
                                      ],
                                    ),
                                    Align(
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8,
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          '${rightFilteredImages.length} images',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.8),
                                              ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: PortraitsGridView(
                                        modsAndImages: rightFilteredImages,
                                        allPortraits: modsAndImages,
                                        replacements: {},
                                        showPickReplacementIcon: false,
                                        onAddRandomReplacement:
                                            _addRandomReplacement,
                                        onSelectedPortraitToReplace:
                                            _onSelectedPortraitToReplace,
                                        isDraggable: true,
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

  SizedBox buildSearchBox() {
    return SizedBox(
      height: 30,
      width: 300,
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
                      padding: EdgeInsets.zero,
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
    super.dispose();
  }

  void _onSelectedPortraitToReplace(Portrait selectedPortrait) {
    setState(() {
      _leftSearchController.text = selectedPortrait.relativePath;
      inReplaceMode = true;
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

  const ReplacementsDialog({
    super.key,
    required this.replacements,
    required this.hashToPortrait,
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
            : ListView.builder(
                itemCount: replacements.length,
                itemBuilder: (context, index) {
                  final entry = replacements.entries.elementAt(index);
                  final originalHash = entry.key;
                  final replacementPath = entry.value;

                  return ReplacementListItem(
                    originalHash: originalHash,
                    replacementPath: replacementPath.imageFile.path,
                    originalPortrait: hashToPortrait[originalHash],
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
  final Portrait? originalPortrait;

  const ReplacementListItem({
    super.key,
    required this.originalHash,
    required this.replacementPath,
    this.originalPortrait,
  });

  @override
  Widget build(BuildContext context) {
    final replacementFile = File(replacementPath);
    final fileExists = replacementFile.existsSync();
    final originalExists = originalPortrait?.imageFile.existsSync() ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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
              child: originalPortrait != null && originalExists
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        originalPortrait!.imageFile,
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
              padding: EdgeInsets.symmetric(vertical: 20),
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
                    'Original: ${originalPortrait?.imageFile.path.split(Platform.pathSeparator).last ?? "Unknown"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (originalPortrait != null && originalExists)
                    Text(
                      'Path: ${originalPortrait!.imageFile.path}',
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
                    'Path: ${replacementFile.path}',
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
                if (originalPortrait != null && originalExists)
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () =>
                        launchUrlString(originalPortrait!.imageFile.path),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
