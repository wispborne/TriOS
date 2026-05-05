import 'package:flutter/material.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/utils/extensions.dart' show TriOSBuildContext;
import 'package:trios/widgets/blur.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/trios_app_icon.dart';

/// App logo + name + version display, used in both sidebar and top toolbar AppBars.
class AppBrandHeader extends StatelessWidget {
  /// `true` for sidebar AppBar (smaller icon, horizontal baseline row).
  /// `false` for top toolbar (larger icon, stacked column).
  final bool compact;

  const AppBrandHeader({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appName = context.appName;
    final iconSize = compact ? 24.0 : 48.0;
    final blurRadius = compact ? 8.0 : 10.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(right: compact ? 8.0 : 16.0),
          child: MovingTooltipWidget.text(
            message: Constants.appSubtitle,
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.8,
                  child: Blur(
                    blurX: blurRadius,
                    blurY: blurRadius,
                    child: TriOSAppIcon(width: iconSize, height: iconSize),
                  ),
                ),
                GestureDetector(
                  onTap: () => showTriOSAboutDialog(context),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: TriOSAppIcon(width: iconSize, height: iconSize),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (compact)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: 6,
              children: [
                Text(
                  appName,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  "v${Constants.version}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  "v${Constants.version}",
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
