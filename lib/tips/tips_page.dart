import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/tips/tip.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/wisp_adaptive_grid_view.dart';

/// Grouping mode, like in your Kotlin code.
enum TipsGrouping {
  none,
  mod,
}

/// A screen that shows tips in a grid, with optional grouping, selection, etc.
class TipsPage extends ConsumerStatefulWidget {
  const TipsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TipsPageState();
}

class _TipsPageState extends ConsumerState<TipsPage> {
  bool _onlyEnabled = false; // Example setting.
  TipsGrouping _grouping = TipsGrouping.none;
  final Map<int, bool> _selectionStates = {};

  @override
  Widget build(BuildContext context) {
    // Watch the tips.
    final tipsAsync = ref.watch(AppState.tipsProvider);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 50,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _onlyEnabled = !_onlyEnabled);
                    },
                    child: Text(
                      _onlyEnabled ? 'Show All' : 'Only Enabled',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  PopupMenuButton<TipsGrouping>(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onSelected: (value) {
                      setState(() => _grouping = value);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: TipsGrouping.none,
                        child: Text('No Grouping'),
                      ),
                      const PopupMenuItem(
                        value: TipsGrouping.mod,
                        child: Text('Group By Mod'),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // Select or deselect all.
                      final allSelected =
                          _selectionStates.values.every((v) => v);
                      setState(() {
                        for (final key in _selectionStates.keys) {
                          _selectionStates[key] = !allSelected;
                        }
                      });
                    },
                    child: const Text(
                      'Select All',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  _buildDeleteButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: tipsAsync.when(
          data: (tips) => _buildBody(tips, context),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) {
            Fimber.e('Error loading tips: $err', ex: err, stacktrace: st);
            return Center(
              child: Text('Error: $err'),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildDeleteButton(BuildContext context) {
    // Calculate how many are selected.
    final tips = ref.watch(AppState.tipsProvider).valueOrNull ?? [];
    final tipsMap = {
      for (final t in tips) t.hashCode: t,
    };

    final selectedCount = _selectionStates.entries
        .where((entry) => entry.value && tipsMap.containsKey(entry.key))
        .length;

    return TextButton.icon(
      onPressed: selectedCount > 0
          ? () {
              final toRemove = <ModTip>[];
              _selectionStates.forEach((hash, selected) {
                if (selected && tipsMap.containsKey(hash)) {
                  toRemove.add(tipsMap[hash]!);
                }
              });
              ref.read(AppState.tipsProvider.notifier).deleteTips(toRemove);
              setState(() {
                // Clear selection of removed items.
                for (final r in toRemove) {
                  _selectionStates.remove(r.hashCode);
                }
              });
            }
          : null,
      icon: const Icon(Icons.delete),
      label: const Text('Delete Selected'),
    );
  }

  Widget _buildBody(List<ModTip> tips, BuildContext context) {
    // Filter tips if onlyEnabled is set.
    final filtered = _onlyEnabled
        ? tips.where((t) => isVariantEnabled(t.variants.firstOrNull)).toList()
        : tips;

    if (filtered.isEmpty) {
      return const Center(child: Text('No tips (or mods) found.'));
    }

    final theme = Theme.of(context);

    // Ensure we have an entry in _selectionStates for each tip.
    for (final tip in filtered) {
      _selectionStates.putIfAbsent(tip.hashCode, () => false);
    }

    if (_grouping == TipsGrouping.mod) {
      // Group tips by mod name.
      final groups = <String, List<ModTip>>{};
      for (final t in filtered) {
        final modName = t.variants.firstOrNull?.modInfo.name ?? '(unknown)';
        groups.putIfAbsent(modName, () => []).add(t);
      }
      final sortedKeys = groups.keys.toList()..sort();

      return ListView.builder(
        itemCount: sortedKeys.length,
        itemBuilder: (context, idx) {
          final modName = sortedKeys[idx];
          final modTips = groups[modName]!;
          return ExpansionTile(
            title: Text('$modName (${modTips.length})'),
            children: modTips.map((t) {
              final hash = t.hashCode;
              final selected = _selectionStates[hash] ?? false;
              return ListTile(
                leading: Checkbox(
                  value: selected,
                  onChanged: (val) {
                    setState(() {
                      _selectionStates[hash] = val ?? false;
                    });
                  },
                ),
                title: Text(t.tipObj.tip ?? '(No tip text)'),
                subtitle: Text('Freq: ${t.tipObj.freq ?? '1'}'),
              );
            }).toList(),
          );
        },
      );
    } else {
      // No grouping: show a grid.
      final modTips = filtered
        ..sort((a, b) =>
            (b.tipObj.tip?.length ?? 0) - (a.tipObj.tip?.length ?? 0));

      return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: WispAdaptiveGridView<ModTip>(
          items: modTips,
          minItemWidth: 350,
          horizontalSpacing: 8,
          verticalSpacing: 8,
          itemBuilder: (context, tip, index) {
            return buildTipCard(tip);
          },
        ),
      );
    }
  }

  Builder buildTipCard(ModTip tip) {
    final theme = Theme.of(context);
    return Builder(builder: (context) {
      final hash = tip.hashCode;
      final isSelected = _selectionStates[hash] ?? false;
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectionStates[hash] = !isSelected;
          });
        },
        child: IntrinsicHeight(
          child: DefaultTextStyle.merge(
            style: theme.textTheme.labelLarge,
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
                    : theme.colorScheme.surfaceContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tip.variants.firstOrNull?.modInfo.name ??
                              '(unknown mod name)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8)),
                        ),
                      ),
                      Checkbox(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            _selectionStates[hash] = val ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(child: Text(tip.tipObj.tip ?? '(No tip text)')),
                  const SizedBox(height: 4),
                  MovingTooltipWidget.text(
                    message:
                        'How likely this tip is to be shown. 1 is normal. Higher is more likely. 0 is never.',
                    child: Text(
                      'Freq: ${tip.tipObj.freq ?? '1'}',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  bool isVariantEnabled(ModVariant? variant) {
    // Example logic: check if the variant is enabled. Possibly watch appSettings.
    return true;
  }
}

/// Simple data class to hold the grid layout parameters.
class GridLayout {
  final int columns;
  final double itemWidth;

  const GridLayout(this.columns, this.itemWidth);

  @override
  String toString() => 'GridLayout(columns: $columns, itemWidth: $itemWidth)';
}

/// Computes how many columns can fit and how wide each item should be
/// so that the grid fills [containerWidth] exactly (except for integer
/// rounding) and each item is at least [minItemWidth] wide.
///
/// - [containerWidth]: total available horizontal space for the grid.
/// - [minItemWidth]: minimum width of each grid item.
/// - [horizontalMargin]: horizontal spacing between items (the “gutter”).
///
/// Returns a [GridLayout] with the chosen number of columns and each item’s width.
GridLayout calculateGridLayout({
  required double containerWidth,
  required double minItemWidth,
  required double horizontalMargin,
}) {
  // 1) Compute the maximum possible columns if each item is minItemWidth wide.
  //    The formula uses (containerWidth + margin) / (minItemWidth + margin)
  //    so we can account for each column plus the spacing after it—except
  //    there's no spacing after the last column, hence the + margin offset.
  int columns =
      ((containerWidth + horizontalMargin) / (minItemWidth + horizontalMargin))
          .floor();

  // 2) Decrease columns until we find a fit where actual itemWidth >= minItemWidth.
  while (columns > 0) {
    // Space taken by margins: (columns - 1) * horizontalMargin
    // Remaining space for items: containerWidth - marginSpace
    // So each item: itemWidth = remainingSpace / columns
    final itemWidth =
        (containerWidth - (columns - 1) * horizontalMargin) / columns;

    if (itemWidth >= minItemWidth) {
      return GridLayout(columns, itemWidth);
    }
    columns--;
  }

  // Fallback: if even 1 column doesn't meet the requirement, just force 1 column
  // (i.e., minItemWidth is bigger than containerWidth).
  return GridLayout(1, containerWidth);
}
