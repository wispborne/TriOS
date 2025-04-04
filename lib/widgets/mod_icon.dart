import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';

class ModIcon extends ConsumerWidget {
  final String? path;
  final double size;
  final EdgeInsets? padding;
  final bool takeUpSpaceIfNoIcon;
  final bool showFullSizeInTooltip;

  const ModIcon(
    this.path, {
    super.key,
    this.size = 32,
    this.padding,
    this.takeUpSpaceIfNoIcon = false,
    this.showFullSizeInTooltip = false,
  });

  static fromMod(
    Mod mod, {
    double size = 32,
    EdgeInsets? padding,
    bool takeUpSpaceIfNoIcon = false,
    bool showFullSizeInTooltip = false,
  }) => ModIcon(
    mod.findFirstEnabledOrHighestVersion?.iconFilePath,
    size: size,
    padding: padding,
    takeUpSpaceIfNoIcon: takeUpSpaceIfNoIcon,
    showFullSizeInTooltip: showFullSizeInTooltip,
  );

  static fromVariant(
    ModVariant? variant, {
    double size = 32,
    EdgeInsets? padding,
    bool takeUpSpaceIfNoIcon = false,
    bool showFullSizeInTooltip = false,
  }) => ModIcon(
    variant?.iconFilePath,
    size: size,
    padding: padding,
    takeUpSpaceIfNoIcon: takeUpSpaceIfNoIcon,
    showFullSizeInTooltip: showFullSizeInTooltip,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (path == null) {
      return takeUpSpaceIfNoIcon
          ? Padding(
            padding: padding ?? EdgeInsets.zero,
            child: SizedBox(width: size, height: size),
          )
          : const SizedBox.shrink();
    }
    return MovingTooltipWidget.framed(
      tooltipWidget: showFullSizeInTooltip ? Image.file(path!.toFile()) : null,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Image.file(
          path!.toFile(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return takeUpSpaceIfNoIcon
                ? SizedBox(width: size, height: size)
                : const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
