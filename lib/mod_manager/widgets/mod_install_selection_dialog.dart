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

  bool get _hasDuplicateSmolIds {
    final ids = widget.choices.map(_smolIdForChoice).toSet();
    return ids.length != widget.choices.length;
  }

  String _smolIdForChoice(ModInstallChoice<T> c) => c.modInfo.modInfo.smolId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasConflicts = _conflictIndices.isNotEmpty;
    final selectedCount = _selected.length;

    return AlertDialog(
      title: Text(widget.title ?? "Install $selectedCount mods"),
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
                    for (var i = 0; i < widget.choices.length; i++)
                      Builder(
                        builder: (context) {
                          final isSelected = _selected.contains(i);

                          return Card.outlined(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: isSelected
                                    ? theme.colorScheme.primary.withAlpha(200)
                                    : Colors.transparent,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _buildChoiceTile(i, theme),
                          );
                        },
                      ),
                    if (_hasDuplicateSmolIds)
                      Padding(
                        padding: .only(top: 4),
                        child: Text(
                          "Multiple mods have the same id and version. Only one of those may be selected.",
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: TriOSThemeConstants.vanillaWarningColor,
                          ),
                        ),
                      ),
                    if (widget.invalidItems.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: .symmetric(vertical: 8),
                        child: Text(
                          "Invalid",
                          style: theme.textTheme.labelSmall?.copyWith(
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
            "Install $selectedCount mod${selectedCount == 1 ? '' : 's'}",
          ),
        ),
      ],
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
                  ModIcon.fromVariant(choice.existingVariant, size: 16),
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
              leading: Icon(Icons.info, size: iconSize, color: iconColor),
              widget: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "v${modInfo.version}",
                      style: const TextStyle(fontSize: subtitleSize),
                    ),
                    TextSpan(
                      text: " • ",
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
                    : "(already installed${choice.existingVariant!.modInfo.version != null ? ' — v${choice.existingVariant!.modInfo.version}' : ''})",
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
