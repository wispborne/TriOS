import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/tips/tip.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/dense_button.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/mod_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';
import 'package:trios/widgets/wisp_adaptive_grid_view.dart';

/// Grouping mode, like in your Kotlin code.
enum TipsGrouping { none, mod }

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

  bool _onlyEnabled = false;
  bool _showHidden = false;
  TipsGrouping _grouping = TipsGrouping.none;
  final Map<ModTip, bool> _selectionStates = {};

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Watch the tips.
    final tipsAsync = ref.watch(AppState.tipsProvider);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 50,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    Text(
                      'Tips',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 20),
                    ),
                    const SizedBox(width: 4),
                    MovingTooltipWidget.text(
                      message: 'About Tips Hider',
                      child: IconButton(
                        icon: const Icon(Icons.info),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Tips Hider'),
                                icon: const Icon(Icons.lightbulb),
                                iconColor: Theme.of(
                                  context,
                                ).colorScheme.onSurface,
                                content: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 900,
                                  ),
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
                        },
                      ),
                    ),
                    MovingTooltipWidget.text(
                      message: 'Reload tips',
                      child: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          ref.invalidate(AppState.tipsProvider);
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    TriOSToolbarCheckboxButton(
                      onChanged: (newValue) =>
                          setState(() => _onlyEnabled = newValue ?? true),
                      value: _onlyEnabled,
                      text: 'Enabled Mods Only',
                    ),
                    const SizedBox(width: 8),
                    TriOSToolbarItem(
                      child: PopupMenuButton<TipsGrouping>(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_list),
                              const SizedBox(width: 4),
                              Text(
                                _grouping == TipsGrouping.none
                                    ? 'No Grouping'
                                    : 'Group By Mod',
                              ),
                            ],
                          ),
                        ),
                        onSelected: (value) =>
                            setState(() => _grouping = value),
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    TriOSToolbarItem(
                      child: TextButton.icon(
                        onPressed: () {
                          // Select or deselect all.
                          final allSelected = _selectionStates.values.every(
                            (v) => v,
                          );
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
                    MovingTooltipWidget.text(
                      message: 'Whether hidden tips are shown',
                      child: TriOSToolbarCheckboxButton(
                        onChanged: (newValue) =>
                            setState(() => _showHidden = newValue ?? true),
                        value: _showHidden,
                        text: 'Show Hidden',
                      ),
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
              return Center(child: Text('Error: $err'));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    final selectedTips = _selectionStates.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final isEnabled = selectedTips.isNotEmpty;

    final hiddenCount = selectedTips
        .where((t) => ref.read(AppState.tipsProvider.notifier).isHidden(t))
        .length;
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
              _unhideTips(selectedTips);
            } else {
              _hideTips(selectedTips);
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

  void _hideTips(List<ModTip> selectedTips) {
    if (selectedTips.isNotEmpty) {
      ref
          .read(AppState.tipsProvider.notifier)
          .hideTips(selectedTips, dryRun: false);
      setState(() {
        for (final tip in selectedTips) {
          _selectionStates.remove(tip);
        }
      });
    }
  }

  void _unhideTips(List<ModTip> selectedTips) {
    if (selectedTips.isNotEmpty) {
      ref.read(AppState.tipsProvider.notifier).unhideTips(selectedTips);
      setState(() {
        for (final tip in selectedTips) {
          _selectionStates.remove(tip);
        }
      });
    }
  }

  Widget _buildBody(List<ModTip> tips, BuildContext context) {
    final allMods = ref.read(AppState.mods);
    // Filter tips if onlyEnabled is set.
    List<ModTip> filtered = _onlyEnabled
        ? tips
              .where(
                (tip) => tip.variants.any(
                  (variant) => variant.isEnabled(allMods) == true,
                ),
              )
              .toList()
        : tips;

    final hiddenTips = ref
        .watch(AppState.tipsProvider.notifier)
        .getHidden(filtered);
    filtered = _showHidden ? filtered : filtered - hiddenTips;

    if (filtered.isEmpty) {
      return const Center(child: Text('No tips (or mods) found.'));
    }

    // Ensure we have an entry in _selectionStates for each tip.
    for (final tip in filtered) {
      _selectionStates.putIfAbsent(tip, () => false);
    }

    if (_grouping == TipsGrouping.mod) {
      // Group tips by mod.
      final Map<Mod, List<ModTip>> grouped = {};
      for (final t in filtered) {
        final mod = t.variants.firstOrNull?.mod(allMods);
        if (mod == null) {
          continue;
        }
        grouped.putIfAbsent(mod, () => []).add(t);
      }
      final List<Mod> sortedKeys = grouped.keys.toList()..sort();

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final mod in sortedKeys) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ModIcon.fromMod(
                          mod,
                          padding: const EdgeInsets.only(left: 4),
                        ),
                      ),
                      Text(
                        '${mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId} (${grouped[mod]?.length ?? 0})',
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
                          onPressed: () {
                            final areAllSelected = grouped[mod]!.every(
                              (t) => _selectionStates[t] ?? false,
                            );
                            setState(() {
                              for (final tip in grouped[mod]!) {
                                _selectionStates[tip] = !areAllSelected;
                              }
                            });
                          },
                          child: Text('Select'),
                        ),
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (context) {
                    final List<ModTip> modTips = grouped[mod]!
                      ..sort(
                        (a, b) =>
                            (b.tipObj.tip?.length ?? 0) -
                            (a.tipObj.tip?.length ?? 0),
                      );
                    return WispAdaptiveGridView<ModTip>(
                      items: modTips,
                      minItemWidth: 350,
                      shrinkWrap: true,
                      horizontalSpacing: 8,
                      verticalSpacing: 8,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemBuilder: (context, tip, index) {
                        return TipCardView(
                          tip: tip,
                          isSelected: _selectionStates[tip] ?? false,
                          isHidden: hiddenTips.contains(tip),
                          showMod: false,
                          onSelected: (selected) {
                            setState(() {
                              _selectionStates[tip] = selected;
                            });
                          },
                          hideTips: () => _hideSelectedAndClickedTip(tip),
                          unhideTips: () => _unhideSelectedAndClickedTip(tip),
                        );
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      // No grouping: show a grid sorted by tip text length (descending).
      final List<ModTip> modTips = filtered
        ..sort(
          (a, b) => (b.tipObj.tip?.length ?? 0) - (a.tipObj.tip?.length ?? 0),
        );

      return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: WispAdaptiveGridView<ModTip>(
          items: modTips,
          minItemWidth: 350,
          horizontalSpacing: 8,
          verticalSpacing: 8,
          padding: const EdgeInsets.only(bottom: 8),
          itemBuilder: (context, tip, index) {
            return TipCardView(
              tip: tip,
              isSelected: _selectionStates[tip] ?? false,
              isHidden: hiddenTips.contains(tip),
              onSelected: (selected) {
                setState(() {
                  _selectionStates[tip] = selected;
                });
              },
              hideTips: () => _hideSelectedAndClickedTip(tip),
              unhideTips: () => _unhideSelectedAndClickedTip(tip),
            );
          },
        ),
      );
    }
  }

  List<ModTip> _getSelectedTips() {
    return _selectionStates.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  void _unhideSelectedAndClickedTip(ModTip tip) {
    _unhideTips(_getSelectedTips() + [tip]);
  }

  void _hideSelectedAndClickedTip(ModTip tip) {
    _hideTips(_getSelectedTips() + [tip]);
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
