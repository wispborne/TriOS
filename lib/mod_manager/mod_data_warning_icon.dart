import 'package:flutter/material.dart';
import 'package:trios/mod_manager/mod_data_issues.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Small warning icon shown when a mod has data issues.
/// Hover lists the issues; click opens a dialog with details.
class ModDataWarningIcon extends StatelessWidget {
  final String modName;
  final List<ModDataIssue> issues;

  const ModDataWarningIcon({
    super.key,
    required this.modName,
    required this.issues,
  });

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) return const SizedBox.shrink();

    return MovingTooltipWidget.text(
      message: issues.map((issue) => issue.summary).join("\n"),
      warningLevel: TooltipWarningLevel.warning,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (context) =>
                _ModDataIssuesDialog(modName: modName, issues: issues),
          ),
          child: const Icon(
            Icons.sim_card_alert_outlined,
            size: 16,
            color: TriOSThemeConstants.vanillaWarningColor,
          ),
        ),
      ),
    );
  }
}

class _ModDataIssuesDialog extends StatelessWidget {
  final String modName;
  final List<ModDataIssue> issues;

  const _ModDataIssuesDialog({required this.modName, required this.issues});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text("Data issues in $modName"),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16.0,
          children: [
            for (final issue in issues)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4.0,
                children: [
                  Text(
                    issue.summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (issue.detail != null)
                    Text(issue.detail!, style: theme.textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        ),
      ],
    );
  }
}
