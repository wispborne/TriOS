import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/download_manager/download_target.dart';
import 'package:trios/widgets/mod_download/mod_download_status.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Which Material button to draw. Only affects looks.
enum ModDownloadButtonVariant { filled, filledTonal, elevated, outlined }

/// A button that starts a mod download and then shows how it's going.
///
/// While the download is running the icon becomes a progress spinner, clicks
/// are ignored, and the tooltip says what's happening. Every download button in
/// the app that has a label uses this; the few that are only an icon use
/// [ModDownloadStatusBuilder] directly.
class ModDownloadButton extends ConsumerWidget {
  /// What this button is about, so it can find its own download.
  final DownloadTarget target;

  final Widget label;

  /// Shown when nothing is running. Replaced by the spinner while busy.
  final Widget icon;

  /// Runs on click. The button starts showing busy straight away, before the
  /// download has had a chance to register.
  final VoidCallback? onPressed;
  final ModDownloadButtonVariant variant;
  final ButtonStyle? style;

  /// Tooltip when idle. While busy the "Downloading…" text wins.
  final String? tooltip;

  /// A richer idle tooltip, used instead of [tooltip] when set.
  final Widget? tooltipWidget;

  final double spinnerSize;
  final Color? spinnerColor;

  /// Whether clicking should immediately show busy. Turn this off when the
  /// click only opens a menu — the menu item that actually starts the download
  /// marks it instead, using the same target.
  final bool markPendingOnPress;

  const ModDownloadButton({
    super.key,
    required this.target,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.variant = ModDownloadButtonVariant.filled,
    this.style,
    this.tooltip,
    this.tooltipWidget,
    this.spinnerSize = 18,
    this.spinnerColor,
    this.markPendingOnPress = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final press = onPressed == null || !markPendingOnPress
        ? onPressed
        : () {
            ref.read(pendingDownloadClicks.notifier).markClicked(target);
            onPressed!();
          };

    return ModDownloadStatusBuilder(
      target: target,
      builder: (context, status) {
        final effectiveIcon = status.isBusy
            ? SizedBox(
                width: spinnerSize,
                height: spinnerSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: status.progress,
                  color: spinnerColor,
                ),
              )
            : icon;
        final onTap = status.isBusy ? null : press;

        final button = switch (variant) {
          ModDownloadButtonVariant.filled => FilledButton.icon(
            onPressed: onTap,
            style: style,
            icon: effectiveIcon,
            label: label,
          ),
          ModDownloadButtonVariant.filledTonal => FilledButton.tonalIcon(
            onPressed: onTap,
            style: style,
            icon: effectiveIcon,
            label: label,
          ),
          ModDownloadButtonVariant.elevated => ElevatedButton.icon(
            onPressed: onTap,
            style: style,
            icon: effectiveIcon,
            label: label,
          ),
          ModDownloadButtonVariant.outlined => OutlinedButton.icon(
            onPressed: onTap,
            style: style,
            icon: effectiveIcon,
            label: label,
          ),
        };

        if (status.isBusy) {
          return MovingTooltipWidget.text(
            message: status.message!,
            child: button,
          );
        }
        if (tooltipWidget != null) {
          return MovingTooltipWidget.framed(
            tooltipWidget: tooltipWidget,
            child: button,
          );
        }
        if (tooltip != null) {
          return MovingTooltipWidget.text(message: tooltip!, child: button);
        }
        return button;
      },
    );
  }
}
