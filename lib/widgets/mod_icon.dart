import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';

class ModIcon extends ConsumerWidget {
  final String? path;
  final double size;
  final bool takeUpSpaceIfNoIcon;
  final bool showFullSizeInTooltip;

  const ModIcon(
    this.path, {
    super.key,
    this.size = 32,
    this.takeUpSpaceIfNoIcon = false,
    this.showFullSizeInTooltip = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (path == null) {
      return takeUpSpaceIfNoIcon
          ? SizedBox(width: size, height: size)
          : const SizedBox.shrink();
    }
    return MovingTooltipWidget.framed(
        tooltipWidget:
            showFullSizeInTooltip ? Image.file(path!.toFile()) : null,
        child: Image.file(
          path!.toFile(),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ));
  }
}
