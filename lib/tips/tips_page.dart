import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/tips/tip.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/mod_icon.dart';
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
                  MovingTooltipWidget.text(
                    message: 'Reload tips',
                    child: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        ref.invalidate(AppState.tipsProvider);
                      },
                    ),
                  ),
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
    return Disable(
      isEnabled: _selectionStates.isNotEmpty,
      child: TextButton.icon(
        onPressed: () {
          final tips = ref.watch(AppState.tipsProvider).valueOrNull ?? [];
          final selectedTips = _selectionStates.entries
              .where((entry) => entry.value)
              .map((entry) =>
                  tips.firstWhere((tip) => tip.hashCode == entry.key))
              .toList();

          if (selectedTips.isNotEmpty) {
            ref
                .read(AppState.tipsProvider.notifier)
                .deleteTips(selectedTips, dryRun: true);
            setState(() {
              for (final key in selectedTips) {
                _selectionStates.remove(key);
              }
            });
          }
        },
        icon: const Icon(Icons.delete),
        label: const Text('Delete Selected'),
      ),
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
            return TipCardView(
                tip: tip,
                isSelected: _selectionStates[tip.hashCode] ?? false,
                onSelected: (selected) {
                  setState(() {
                    _selectionStates[tip.hashCode] = selected;
                  });
                });
          },
        ),
      );
    }
  }

  bool isVariantEnabled(ModVariant? variant) {
    // Example logic: check if the variant is enabled. Possibly watch appSettings.
    return true;
  }
}

class TipCardView extends ConsumerStatefulWidget {
  final ModTip tip;
  final bool isSelected;
  final Function onSelected;

  const TipCardView(
      {super.key,
      required this.tip,
      required this.isSelected,
      required this.onSelected});

  @override
  ConsumerState createState() => _TipCardViewState();
}

class _TipCardViewState extends ConsumerState<TipCardView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tip = widget.tip;
    final isSelected = widget.isSelected;

    final textColor = theme.colorScheme.onSurface.withValues(
      alpha: tip.tipObj.freq?.toDoubleOrNull() == 0.0 ? 0.5 : 1,
    );
    return ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: [
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
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ModIcon(
                          tip.variants.firstOrNull?.iconFilePath,
                          showFullSizeInTooltip: true,
                          size: 24,
                        ),
                      ),
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
                          widget.onSelected(val ?? false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                      child: Text(tip.tipObj.tip ?? '(No tip text)',
                          style: TextStyle(fontSize: 12, color: textColor))),
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
      ),
    );
  }
}
