import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/tips/tip.dart';
import 'package:trios/tips/tips_page_controller.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/dense_button.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';
import 'package:trios/widgets/mod_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';
import 'package:trios/widgets/viewer_toolbar.dart';
import 'package:trios/widgets/wisp_adaptive_grid_view.dart';
import 'package:trios/trios/constants_theme.dart';

/// A screen that shows tips in a grid, with optional grouping, selection, etc.
class TipsPage extends ConsumerStatefulWidget {
  const TipsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TipsPageState();
}

class _TipsPageState extends ConsumerState<TipsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final SearchController _searchController = SearchController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(tipsPageControllerProvider);
    final controller = ref.read(tipsPageControllerProvider.notifier);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        ViewerToolbar(
          entityName: 'Tips',
          total: state.allTips.length,
          visible: state.visibleTips.length,
          isLoading: state.isLoading,
          onRefresh: controller.refresh,
          searchBox: buildSearchBox(controller),
          leadingActions: [
            MovingTooltipWidget.text(
              message: 'About Tips Hider',
              child: IconButton(
                icon: const Icon(Icons.info),
                onPressed: () => _showAboutDialog(context),
              ),
            ),
          ],
          trailingActions: [
            TriOSToolbarItem(
              child: PopupMenuButton<TipsGrouping>(
                onSelected: controller.setGrouping,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: TipsGrouping.none,
                    child: Text('No Grouping'),
                  ),
                  PopupMenuItem(
                    value: TipsGrouping.mod,
                    child: Text('Group By Mod'),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list),
                      const SizedBox(width: 4),
                      Text(
                        state.grouping == TipsGrouping.none
                            ? 'No Grouping'
                            : 'Group By Mod',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TriOSToolbarItem(
              child: TextButton.icon(
                onPressed: () => controller.toggleSelectAll(state.visibleTips),
                icon: Icon(Icons.select_all, color: textColor),
                label: Text('Select All', style: TextStyle(color: textColor)),
              ),
            ),
            const SizedBox(width: 8),
            _buildHideButton(context, state, controller),
            const SizedBox(width: 8),
            TriOSToolbarCheckboxButton(
              onChanged: (_) => controller.toggleOnlyEnabledMods(),
              value: state.onlyEnabledMods,
              text: 'Enabled Mods Only',
            ),
            const SizedBox(width: 8),
            MovingTooltipWidget.text(
              message:
                  "Hidden tips are tips that have a freq of 0, so they don't "
                  "appear ingame.",
              child: TriOSToolbarCheckboxButton(
                onChanged: (_) => controller.toggleShowHidden(),
                value: state.showHidden,
                text: 'Show Hidden',
              ),
            ),
          ],
        ),
        Expanded(child: _buildBody(context, state, controller)),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tips Hider'),
          icon: const Icon(Icons.lightbulb),
          iconColor: Theme.of(context).colorScheme.onSurface,
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: const Text(
              "Shows all loading screen tips, which mod adds them, and how often they appear (freq)."
              "\nYou may hide a tip to stop it from showing ingame. TriOS will automatically re-apply your changes if a mod is updated.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHideButton(
    BuildContext context,
    TipsPageState state,
    TipsPageController controller,
  ) {
    final selectedTips = state.selectedTips.toList();
    final hiddenCount = controller.selectedHiddenCount;
    final showUnhide = hiddenCount > selectedTips.length - hiddenCount;

    return Disable(
      isEnabled: selectedTips.isNotEmpty,
      child: TriOSToolbarItem(
        child: TextButton.icon(
          onPressed: () {
            if (showUnhide) {
              controller.unhideTips(selectedTips);
            } else {
              controller.hideTips(selectedTips);
            }
          },
          icon: Icon(showUnhide ? Icons.visibility : Icons.delete),
          label: Text(showUnhide ? 'Unhide Selected' : 'Hide Selected'),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.onSurface,
            ),
            iconColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TipsPageState state,
    TipsPageController controller,
  ) {
    if (state.errorMessage != null) {
      return Center(child: Text('Error: ${state.errorMessage}'));
    }
    if (state.isLoading && state.allTips.isEmpty) {
      return Center(child: ThemedCircularProgressIndicator());
    }
    if (state.visibleTips.isEmpty) {
      return const Center(child: Text('No tips (or mods) found.'));
    }

    final hiddenTips = state.hiddenTips.toSet();

    if (state.grouping == TipsGrouping.mod) {
      final grouped = controller.groupVisibleTipsByMod();

      return Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          primary: false,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ModIcon.fromMod(
                            entry.key,
                            padding: const EdgeInsets.only(left: 4),
                          ),
                        ),
                        Text(
                          '${entry.key.findFirstEnabledOrHighestVersion?.modInfo.nameOrId} (${entry.value.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        DenseButton(
                          density: DenseButtonStyle.compact,
                          child: OutlinedButton(
                            style: ButtonStyle(
                              foregroundColor: WidgetStateProperty.all(
                                Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            onPressed: () =>
                                controller.toggleSelectAll(entry.value),
                            child: Text('Select'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  WispAdaptiveGridView<ModTip>(
                    items: entry.value,
                    minItemWidth: 350,
                    shrinkWrap: true,
                    horizontalSpacing: 8,
                    verticalSpacing: 8,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemBuilder: (context, tip, index) => TipCardView(
                      tip: tip,
                      isSelected: state.selectedTips.contains(tip),
                      isHidden: hiddenTips.contains(tip),
                      showMod: false,
                      onSelected: (selected) =>
                          controller.setSelected(tip, selected),
                      hideTips: () =>
                          controller.hideTips({...state.selectedTips, tip}),
                      unhideTips: () =>
                          controller.unhideTips({...state.selectedTips, tip}),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: WispAdaptiveGridView<ModTip>(
          controller: _scrollController,
          items: state.visibleTips,
          minItemWidth: 350,
          horizontalSpacing: 8,
          verticalSpacing: 8,
          padding: const EdgeInsets.only(bottom: 8),
          itemBuilder: (context, tip, index) => TipCardView(
            tip: tip,
            isSelected: state.selectedTips.contains(tip),
            isHidden: hiddenTips.contains(tip),
            onSelected: (selected) => controller.setSelected(tip, selected),
            hideTips: () => controller.hideTips({...state.selectedTips, tip}),
            unhideTips: () =>
                controller.unhideTips({...state.selectedTips, tip}),
          ),
        ),
      ),
    );
  }

  Widget buildSearchBox(TipsPageController controller) {
    return SizedBox(
      height: 30,
      child: SearchAnchor(
        searchController: _searchController,
        builder: (BuildContext context, SearchController searchController) {
          return SearchBar(
            controller: searchController,
            leading: const Icon(Icons.search),
            hintText: "Filter...",
            trailing: [
              searchController.value.text.isEmpty
                  ? Container()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        searchController.clear();
                        controller.setSearchQuery('');
                      },
                    ),
            ],
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainer,
            ),
            onChanged: controller.setSearchQuery,
          );
        },
        suggestionsBuilder:
            (BuildContext context, SearchController searchController) {
              return [];
            },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class TipCardView extends ConsumerStatefulWidget {
  final ModTip tip;
  final bool isSelected;
  final bool isHidden;
  final Function onSelected;
  final Function hideTips;
  final Function unhideTips;
  final bool showMod;

  const TipCardView({
    super.key,
    required this.tip,
    required this.isSelected,
    required this.isHidden,
    required this.onSelected,
    required this.hideTips,
    required this.unhideTips,
    this.showMod = true,
  });

  @override
  ConsumerState createState() => _TipCardViewState();
}

class _TipCardViewState extends ConsumerState<TipCardView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tip = widget.tip;
    final isSelected = widget.isSelected;
    final isHidden = widget.isHidden;
    final textColor = theme.colorScheme.onSurface.withValues(
      alpha: tip.tipObj.freq?.toDoubleOrNull() == 0.0 ? 0.5 : 1,
    );

    final modName =
        tip.variants.firstOrNull?.modInfo.name ?? '(unknown mod name)';
    return ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: [
          MenuItem(
            label: isHidden ? 'Unhide' : 'Hide',
            onSelected: () {
              if (isHidden) {
                widget.unhideTips();
              } else {
                widget.hideTips();
              }
            },
          ),
          MenuItem(
            label: 'Open Folder',
            onSelected: () {
              tip.tipFile.parent.path.openAsUriInBrowser();
            },
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          widget.onSelected(!isSelected);
        },
        child: IntrinsicHeight(
          child: DefaultTextStyle.merge(
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.2),
                  width: 1,
                ),
                color: isSelected
                    ? theme.colorScheme.surfaceContainer.withOpacity(0.5)
                    : isHidden
                    ? theme.colorScheme.surfaceContainerLowest
                    : theme.colorScheme.surfaceContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(
                  TriOSThemeConstants.cornerRadius,
                ),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (isHidden)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.visibility_off, color: textColor),
                        ),
                      if (widget.showMod)
                        ModIcon.fromVariant(
                          tip.variants.firstOrNull,
                          padding: const EdgeInsets.only(right: 8),
                          size: 24,
                        ),
                      if (widget.showMod)
                        Expanded(
                          child: Text(
                            modName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                      if (widget.showMod)
                        Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            widget.onSelected(val ?? false);
                          },
                        ),
                    ],
                  ),
                  if (widget.showMod) const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          tip.tipObj.tip ?? '(No tip text)',
                          style: TextStyle(fontSize: 13, color: textColor),
                        ),
                      ),
                      if (!widget.showMod)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                widget.onSelected(val ?? false);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      MovingTooltipWidget.text(
                        message:
                            'How likely this tip is to be shown. 1 is normal. Higher is more likely. 0 is never.',
                        child: Text(
                          'Freq: ${widget.isHidden ? "(hidden)" : tip.tipObj.freq ?? '1'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      const Spacer(),
                      MovingTooltipWidget.text(
                        message:
                            'Tip added by ${tip.variants.firstOrNull?.modInfo.nameOrId},'
                            '\nversion(s): '
                            '${tip.variants.joinToString(transform: (v) => v.modInfo.version.toString())}',
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
