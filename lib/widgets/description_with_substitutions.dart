import 'package:flutter/material.dart';
import 'package:trios/utils/extensions.dart';

/// Displays a description string with `%s` placeholders highlighted.
/// If any `%s` remain after substitution, shows an explanatory hint below.
class DescriptionWithSubstitutions extends StatelessWidget {
  final String description;
  final String? highlightValues;
  final TextStyle? baseStyle;
  final Color? highlightColor;

  const DescriptionWithSubstitutions({
    super.key,
    required this.description,
    this.highlightValues,
    this.baseStyle,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveHighlightColor =
        highlightColor ?? theme.colorScheme.secondary;
    final effectiveBaseStyle = baseStyle ?? theme.textTheme.bodySmall;

    // Check if there are unsubstituted %s remaining after applying replacements.
    final substituted = description.replaceSubstitutions(highlightValues);
    final hasRawPlaceholders = substituted.contains('%s');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        description.replaceSubstitutionsRich(
          highlightValues,
          highlightColor: effectiveHighlightColor,
          baseStyle: effectiveBaseStyle,
        ),
        if (hasRawPlaceholders)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: 'Values shown as %s are placeholders filled in by game code. Additional text may be entirely added by game code.'
                .replaceSubstitutionsRich(
                  '%s',
                  highlightColor: effectiveHighlightColor,
                  baseStyle: theme.textTheme.labelMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) - 1,
                  ),
                ),
          ),
      ],
    );
  }
}
