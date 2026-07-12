import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/mod_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_with_icon.dart';

/// One selectable mod in the install dialog. [tag] lets the caller identify
/// which of its own objects each choice corresponds to.
class ModInstallChoice<T> {
  final ExtractedModInfo modInfo;

  /// Set when this mod is already installed (same version exists).
  final ModVariant? existingVariant;

  /// Optional source label (e.g. archive filename). Shown when set.
  final String? sourceLabel;

  final T tag;

  const ModInstallChoice({
    required this.modInfo,
    this.existingVariant,
    this.sourceLabel,
    required this.tag,
  });

  bool get hasConflict => existingVariant != null;
}

/// A source that could not be read/parsed (shown as non-selectable).
class InvalidInstallItem {
  final String name;
  final String? detail;

  const InvalidInstallItem({required this.name, this.detail});
}

/// Dialog for choosing which mods to install from one or more archives.
/// Checked mods will be installed (replacing existing ones if needed).
/// Unchecked mods are skipped. Returns null if the user cancelled.
class ModInstallSelectionDialog<T> extends ConsumerStatefulWidget {
  final List<ModInstallChoice<T>> choices;
  final List<InvalidInstallItem> invalidItems;
  final String? gameVersion;
  final String? title;

  const ModInstallSelectionDialog({
    super.key,
    required this.choices,
    this.invalidItems = const [],
    required this.gameVersion,
    this.title,
  });

  static Future<List<T>?> show<T>(
    BuildContext context, {
    required List<ModInstallChoice<T>> choices,
    List<InvalidInstallItem> invalidItems = const [],
    required String? gameVersion,
    String? title,
  }) {
    return showDialog<List<T>>(
      context: context,
      builder: (context) => ModInstallSelectionDialog<T>(
        choices: choices,
        invalidItems: invalidItems,
        gameVersion: gameVersion,
        title: title,
      ),
    );
  }

  @override
  ConsumerState<ModInstallSelectionDialog<T>> createState() =>
      _ModInstallSelectionDialogState<T>();
}

class _ModInstallSelectionDialogState<T>
    extends ConsumerState<ModInstallSelectionDialog<T>> {
  /// Indices into [widget.choices] that are currently selected.
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    // Pre-select non-conflicting choices, deduped by smolId.
    final seenSmolIds = <String>{};
    for (var i = 0; i < widget.choices.length; i++) {
      final choice = widget.choices[i];
      if (choice.hasConflict) continue;
      final smolId = choice.modInfo.modInfo.smolId;
      if (seenSmolIds.add(smolId)) {
        _selected.add(i);
      }
    }
  }

  String _smolIdAt(int index) => widget.choices[index].modInfo.modInfo.smolId;

  /// Choice indices grouped by smolId, in first-appearance order. A group with
  /// more than one entry is a set of mutually exclusive picks (same mod and
  /// version) where only one may be installed.
  List<List<int>> get _choiceGroups {
    final bySmolId = <String, List<int>>{};
    for (var i = 0; i < widget.choices.length; i++) {
      bySmolId.putIfAbsent(_smolIdAt(i), () => []).add(i);
    }
    return bySmolId.values.toList();
  }

  void _toggle(int index, bool selected) {
    setState(() {
      if (selected) {
        // Only one choice per smolId may be selected at a time.
        final smolId = _smolIdAt(index);
        _selected.removeWhere((i) => _smolIdAt(i) == smolId);
        _selected.add(index);
      } else {
        _selected.remove(index);
      }
    });
  }

  List<int> get _conflictIndices => [
    for (var i = 0; i < widget.choices.length; i++)
      if (widget.choices[i].hasConflict) i,
  ];

  /// Checkbox state for the "replace all" toggle: true/false/mixed.
  bool? get _replaceAllValue {
    final conflicts = _conflictIndices;
    if (conflicts.isEmpty) return false;
    final selectedCount = conflicts.where(_selected.contains).length;
    if (selectedCount == 0) return false;
    if (selectedCount == conflicts.length) return true;
    return null;
  }

  void _toggleReplaceAll() {
    final conflicts = _conflictIndices;
    final allSelected = conflicts.every(_selected.contains);
    setState(() {
      if (allSelected) {
        _selected.removeAll(conflicts);
      } else {
        for (final i in conflicts) {
          final smolId = _smolIdAt(i);
          _selected.removeWhere((j) => _smolIdAt(j) == smolId);
          _selected.add(i);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasConflicts = _conflictIndices.isNotEmpty;
    final selectedCount = _selected.length;

    // When nothing could be read there's nothing to "install N of M" — title it
    // as the error it is instead of "Install 0 of 0 mods".
    final defaultTitle =
        widget.choices.isEmpty && widget.invalidItems.isNotEmpty
        ? (widget.invalidItems.length == 1
              ? "Couldn't install this file"
              : "Couldn't install these files")
        : "Install $selectedCount of ${_choiceGroups.length} mods";

    return AlertDialog(
      title: Text(widget.title ?? defaultTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 400,
          maxWidth: 700,
          // maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in _choiceGroups)
                      if (group.length > 1)
                        _buildExclusiveGroup(group, theme)
                      else
                        _buildChoiceCard(group.first, theme),
                    if (widget.invalidItems.isNotEmpty) ...[
                      // Only separate from the list above when there is one;
                      // on its own the divider would just float.
                      if (widget.choices.isNotEmpty) const Divider(height: 24),
                      Padding(
                        padding: .only(left: 4, bottom: 4),
                        child: Text(
                          widget.invalidItems.length == 1
                              ? "Couldn't be installed:"
                              : "Couldn't be installed (${widget.invalidItems.length}):",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                      for (final item in widget.invalidItems)
                        _buildInvalidTile(item, theme),
                    ],
                  ],
                ),
              ),
            ),
            if (hasConflicts) ...[
              const Divider(),
              MovingTooltipWidget.text(
                message:
                    "Toggle whether already-installed mods are replaced by the versions being installed.",
                child: CheckboxWithLabel(
                  value: _replaceAllValue,
                  tristate: true,
                  onChanged: (_) => _toggleReplaceAll(),
                  label: "Replace all already-present mods",
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: selectedCount > 0
              ? () {
                  final tags = _selected
                      .map((i) => widget.choices[i].tag)
                      .toList();
                  Navigator.of(context).pop(tags);
                }
              : null,
          child: Text(
            selectedCount == 0
                ? 'No mods selected'
                : "Install $selectedCount mod${selectedCount == 1 ? '' : 's'}",
          ),
        ),
      ],
    );
  }

  /// A single choice as a selectable, outlined card.
  Widget _buildChoiceCard(int index, ThemeData theme) {
    final isSelected = _selected.contains(index);
    return Card.outlined(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary.withAlpha(200)
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: _buildChoiceTile(index, theme),
    );
  }

  /// A set of mutually exclusive choices (same mod and version) boxed together
  /// with a "pick one" heading, so it's clear only one can be installed.
  Widget _buildExclusiveGroup(List<int> indices, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Text(
              "These mods all have the same id and version, so only one may be selected.",
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final i in indices) _buildChoiceCard(i, theme),
        ],
      ),
    );
  }

  Widget _buildChoiceTile(int index, ThemeData theme) {
    final choice = widget.choices[index];
    final modInfo = choice.modInfo.modInfo;
    final isSelected = _selected.contains(index);
    final iconColor = theme.iconTheme.color?.withValues(alpha: 0.7);
    const iconSize = 20.0;
    const subtitleSize = 14.0;

    return MovingTooltipWidget.framed(
      tooltipWidget: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            Text("mod_info.json"),
            Text(
              modInfo.toMap().prettyPrintJson(),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => _toggle(index, value ?? false),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            // Source label (archive name), if provided.
            // if (choice.sourceLabel != null)
            //   Text(
            //     choice.sourceLabel!,
            //     style: theme.textTheme.bodySmall?.copyWith(
            //       color: iconColor,
            //       fontSize: 11,
            //     ),
            //     maxLines: 1,
            //     overflow: TextOverflow.ellipsis,
            //   ),
            // Mod name.
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                if (choice.existingVariant != null)
                  Padding(
                    padding: const .only(right: 8),
                    child: ModIcon.fromVariant(
                      choice.existingVariant,
                      size: 16,
                    ),
                  ),
                Flexible(
                  child: Text(
                    modInfo.nameOrId,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            // Version + game version.
            TextWithIcon(
              leading: Icon(Icons.numbers, size: iconSize, color: iconColor),
              leadingPadding: const EdgeInsets.only(right: 8),
              widget: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "v${modInfo.version}",
                      style: const TextStyle(fontSize: subtitleSize),
                    ),
                    TextSpan(
                      text: "  •  ",
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: iconColor,
                      ),
                    ),
                    TextSpan(
                      text: modInfo.gameVersion,
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color:
                            (modInfo
                                        .isCompatibleWithGame(
                                          widget.gameVersion,
                                        )
                                        .getGameCompatibilityColor() ??
                                    theme.colorScheme.onSurface)
                                .withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // File path.
            TextWithIcon(
              leading: Icon(Icons.folder, size: iconSize, color: iconColor),
              text: choice.modInfo.extractedFile.relativePath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: subtitleSize),
            ),
            // Description.
            Padding(
              padding: .only(top: 4, left: iconSize + 9),
              child: TextWithIcon(
                text:
                    modInfo.description?.takeWhile(
                      (it) => it != "\n" && it != ".",
                    ) ??
                    "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
            ),
            // Conflict line.
            if (choice.hasConflict)
              Text(
                isSelected
                    ? "(existing mod will be replaced)"
                    : "(already installed${choice.existingVariant!.modInfo.version != null ? ': v${choice.existingVariant!.modInfo.version}' : ''})",
                style: TextStyle(
                  color: TriOSThemeConstants.vanillaWarningColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvalidTile(InvalidInstallItem item, ThemeData theme) {
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.error_outline,
        size: 18,
        color: theme.colorScheme.error,
      ),
      title: Text(
        item.name,
        style: theme.textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: item.detail != null
          ? Text(
              item.detail!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          : null,
    );
  }
}
