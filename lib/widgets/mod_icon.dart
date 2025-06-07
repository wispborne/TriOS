import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';

class ModIcon extends ConsumerStatefulWidget {
  final String? path;
  final double size;
  final EdgeInsets? padding;
  final bool takeUpSpaceIfNoIcon;
  final bool showFullSizeInTooltip;
  final bool showOnClick = false;

  const ModIcon(
    this.path, {
    super.key,
    this.size = 32,
    this.padding,
    this.takeUpSpaceIfNoIcon = false,
    this.showFullSizeInTooltip = false,
    // this.showOnClick = false,
  });

  static fromMod(
    Mod mod, {
    double size = 32,
    EdgeInsets? padding,
    bool takeUpSpaceIfNoIcon = false,
    bool showFullSizeInTooltip = false,
    bool showOnClick = false,
  }) => ModIcon(
    mod.findFirstEnabledOrHighestVersion?.iconFilePath,
    size: size,
    padding: padding,
    takeUpSpaceIfNoIcon: takeUpSpaceIfNoIcon,
    showFullSizeInTooltip: showFullSizeInTooltip,
    // showOnClick: showOnClick,
  );

  static fromVariant(
    ModVariant? variant, {
    double size = 32,
    EdgeInsets? padding,
    bool takeUpSpaceIfNoIcon = false,
    bool showFullSizeInTooltip = false,
    bool showOnClick = false,
  }) => ModIcon(
    variant?.iconFilePath,
    size: size,
    padding: padding,
    takeUpSpaceIfNoIcon: takeUpSpaceIfNoIcon,
    showFullSizeInTooltip: showFullSizeInTooltip,
    // showOnClick: showOnClick,
  );

  @override
  ConsumerState<ModIcon> createState() => _ModIconState();
}

class _ModIconState extends ConsumerState<ModIcon> {
  bool showingFullSize = false;

  @override
  void initState() {
    super.initState();
    showingFullSize = widget.showFullSizeInTooltip;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.path == null) {
      return widget.takeUpSpaceIfNoIcon
          ? Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: SizedBox(width: widget.size, height: widget.size),
            )
          : const SizedBox.shrink();
    }

    Widget imageWidget = Image.file(
      widget.path!.toFile(),
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return widget.takeUpSpaceIfNoIcon
            ? SizedBox(width: widget.size, height: widget.size)
            : const SizedBox.shrink();
      },
    );

    // if (widget.showOnClick) {
    //   imageWidget = GestureDetector(
    //     onTap: () => showingFullSize = !showingFullSize,
    //     child: imageWidget,
    //   );
    // }

    return MovingTooltipWidget.framed(
      tooltipWidget: showingFullSize ? Image.file(widget.path!.toFile()) : null,
      child: Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: imageWidget,
      ),
    );
  }
}
