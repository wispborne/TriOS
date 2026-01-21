import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_with_icon.dart';

/// Type alias for a mod installation candidate
typedef ModInstallationCandidate = ({
  ExtractedModInfo modInfo,
  ModVariant? alreadyExistingVariant
});

/// Dialog for selecting which mods to install from a collection of discovered mods.
///
/// Shows mod details including name, version, game version compatibility,
/// description, and whether the mod already exists. Users can select/deselect
/// mods to install, with validation to prevent installing multiple versions
/// of the same mod.
class ModInstallationDialog extends ConsumerStatefulWidget {
  final List<ModInstallationCandidate> candidates;
  final String? gameVersion;

  const ModInstallationDialog({
    super.key,
    required this.candidates,
    this.gameVersion,
  });

  /// Shows the dialog and returns the list of selected mods to install,
  /// or null if cancelled.
  static Future<List<ExtractedModInfo>?> show(
    BuildContext context, {
    required List<ModInstallationCandidate> candidates,
    required String? gameVersion,
  }) {
    return showDialog<List<ExtractedModInfo>>(
      context: context,
      builder: (context) => ModInstallationDialog(
        candidates: candidates,
        gameVersion: gameVersion,
      ),
    );
  }

  @override
  ConsumerState<ModInstallationDialog> createState() =>
      _ModInstallationDialogState();
}

class _ModInstallationDialogState
    extends ConsumerState<ModInstallationDialog> {
  late List<ExtractedModInfo> _selectedMods;

  @override
  void initState() {
    super.initState();
    // Start by selecting to install variants that are not already installed.
    _selectedMods = widget.candidates
        .where((it) => it.alreadyExistingVariant == null)
        .map((it) => it.modInfo)
        .distinctBy((it) => it.modInfo.smolId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDuplicateIds = widget.candidates
            .distinctBy((it) => it.modInfo.modInfo.smolId)
            .length !=
        widget.candidates.length;

    return AlertDialog(
      title: const Text("Install mods"),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...widget.candidates.map(
                (candidate) => _buildModTile(candidate),
              ),
              const SizedBox(height: 16),
              if (hasDuplicateIds)
                Text(
                  "Multiple mods have the same id and version. Only one of those may be selected.",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: ThemeManager.vanillaWarningColor,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(<ExtractedModInfo>[]),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedMods),
          child: const Text("Install"),
        ),
      ],
    );
  }

  Widget _buildModTile(ModInstallationCandidate candidate) {
    final isSelected = _selectedMods.contains(candidate.modInfo);
    final themeData = Theme.of(context);
    final iconColor = themeData.iconTheme.color?.withOpacity(0.7);
    const iconSize = 20.0;
    const subtitleSize = 14.0;

    return MovingTooltipWidget.framed(
      tooltipWidget: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Text(
          candidate.modInfo.modInfo.toMap().prettyPrintJson(),
          style: const TextStyle(fontSize: 12),
        ),
      ),
      child: CheckboxListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mod name
            Text(
              "${candidate.modInfo.modInfo.name}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            // Version and game version
            TextWithIcon(
              leading: Icon(
                Icons.info,
                size: iconSize,
                color: iconColor,
              ),
              widget: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "v${candidate.modInfo.modInfo.version}",
                      style: const TextStyle(fontSize: subtitleSize),
                    ),
                    // bullet separator
                    TextSpan(
                      text: " • ",
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: iconColor,
                      ),
                    ),
                    TextSpan(
                      text: candidate.modInfo.modInfo.gameVersion,
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: (candidate.modInfo.modInfo
                                    .isCompatibleWithGame(widget.gameVersion)
                                    .getGameCompatibilityColor() ??
                                themeData.colorScheme.onSurface)
                            .withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // File path
            TextWithIcon(
              leading: Icon(
                Icons.folder,
                size: iconSize,
                color: iconColor,
              ),
              text: candidate.modInfo.extractedFile.relativePath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: subtitleSize),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.only(
                top: 4,
                left: iconSize + 9,
              ),
              child: TextWithIcon(
                text: candidate.modInfo.modInfo.description?.takeWhile(
                      (it) => it != "\n" && it != ".",
                    ) ??
                    "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: themeData.colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
            ),

            // Already exists warning
            if (candidate.alreadyExistingVariant != null)
              Text(
                isSelected
                    ? "(existing mod will be replaced)"
                    : "(already exists)",
                style: TextStyle(
                  color: ThemeManager.vanillaWarningColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == false) {
              _selectedMods.remove(candidate.modInfo);
            } else {
              // Only allow user to select one mod with the same id and version.
              _selectedMods.removeWhere(
                (existing) =>
                    existing.modInfo.smolId ==
                    candidate.modInfo.modInfo.smolId,
              );
              _selectedMods.add(candidate.modInfo);
            }
          });
        },
      ),
    );
  }
}
