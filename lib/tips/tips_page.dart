import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/tips/tip.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/mod_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';
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
  bool _onlyEnabled = false;
  bool _showHidden = false;
  TipsGrouping _grouping = TipsGrouping.none;
  final Map<int, bool> _selectionStates = {};

  @override
  Widget build(BuildContext context) {
    // Watch the tips.
    final tipsAsync = ref.watch(AppState.tipsProvider);
    final textColor = Theme.of(context).colorScheme.onSurface;

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
                  TriOSToolbarCheckboxButton(
                    onChanged: (newValue) =>
                        setState(() => _onlyEnabled = newValue ?? true),
                    value: _onlyEnabled,
                    text: 'Enabled Mods Only',
                  ),
                  SizedBox(width: 8),
                  TriOSToolbarItem(
                    child: PopupMenuButton<TipsGrouping>(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Icon(Icons.filter_list),
                            SizedBox(width: 4),
                            Text("Group By"),
                          ],
                        ),
                      ),
                      onSelected: (value) => setState(() => _grouping = value),
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
                  ),
                  SizedBox(width: 8),
                  TriOSToolbarItem(
                    child: TextButton.icon(
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
                      icon: Icon(Icons.select_all, color: textColor),
                      label: Text(
                        'Select All',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildDeleteButton(context),
                  const Spacer(),
                  TriOSToolbarCheckboxButton(
                    onChanged: (newValue) =>
                        setState(() => _showHidden = newValue ?? true),
                    value: _showHidden,
                    text: 'Show Hidden',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: tipsAsync.when(
          data: (tips) {
            return _buildBody(tips, context);
          },
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
    final allTips = ref.watch(AppState.tipsProvider).valueOrNull ?? [];

    final selectedTips = _selectionStates.entries
        .where((entry) => entry.value)
        .map((entry) =>
            allTips.firstWhereOrNull((tip) => tip.hashCode == entry.key))
        .nonNulls
        .toList();

    final isEnabled = selectedTips.isNotEmpty;

    final hiddenCount = selectedTips.where((t) => t.tipObj.originalFreq != null).length;
    final notHiddenCount = selectedTips.length - hiddenCount;

    final showUnhide = hiddenCount > notHiddenCount;

    final buttonLabel = showUnhide ? 'Unhide Selected' : 'Hide Selected';
    final buttonIcon = showUnhide ? Icons.visibility : Icons.delete;

    return Disable(
      isEnabled: isEnabled,
      child: TriOSToolbarItem(
        child: TextButton.icon(
          onPressed: () {
            if (showUnhide) {
              _unhideSelectedTips(selectedTips);
            } else {
              _hideSelectedTips(selectedTips);
            }
          },
          icon: Icon(buttonIcon),
          label: Text(buttonLabel),
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
  void _hideSelectedTips(List<ModTip> selectedTips) {
    if (selectedTips.isNotEmpty) {
      ref.read(AppState.tipsProvider.notifier).hideTips(selectedTips, dryRun: false);
      setState(() {
        for (final tip in selectedTips) {
          _selectionStates.remove(tip.hashCode);
        }
      });
    }
  }

  void _unhideSelectedTips(List<ModTip> selectedTips) {
    if (selectedTips.isNotEmpty) {
      ref.read(AppState.tipsProvider.notifier).unhideTips(selectedTips);
      setState(() {
        for (final tip in selectedTips) {
          _selectionStates.remove(tip.hashCode);
        }
      });
    }
  }

  Widget _buildBody(List<ModTip> tips, BuildContext context) {
    // Filter tips if onlyEnabled is set.
    List<ModTip> filtered = _onlyEnabled
        ? tips.where((t) => isVariantEnabled(t.variants.firstOrNull)).toList()
        : tips;

    final hiddenTips =
        ref.watch(AppState.tipsProvider.notifier).getHidden(filtered);
    filtered = _showHidden ? tips : tips - hiddenTips;

    if (filtered.isEmpty) {
      return const Center(child: Text('No tips (or mods) found.'));
    }

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
                isHidden: hiddenTips.contains(tip),
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
    return variant?.isEnabled(ref.read(AppState.mods)) ?? false;
  }
}

class TipCardView extends ConsumerStatefulWidget {
  final ModTip tip;
  final bool isSelected;
  final bool isHidden;
  final Function onSelected;

  const TipCardView({
    super.key,
    required this.tip,
    required this.isSelected,
    required this.isHidden,
    required this.onSelected,
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
                    : isHidden
                        ? theme.colorScheme.surfaceContainerLowest
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
                      if (isHidden)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.visibility_off, color: textColor),
                        ),
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
                      'Freq: ${widget.isHidden ? "(hidden)" : tip.tipObj.freq ?? '1'}',
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
