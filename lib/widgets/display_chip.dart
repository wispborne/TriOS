import 'package:flutter/material.dart';

/// A non-interactive chip that displays an avatar and a label,
/// styled to look like [ActionChip].
class DisplayChip extends StatelessWidget {
  final Widget? avatar;
  final String label;
  final double avatarSize;
  final TextStyle? labelStyle;

  const DisplayChip({
    super.key,
    this.avatar,
    required this.label,
    this.avatarSize = 20,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveStyle = labelStyle ?? theme.textTheme.labelLarge;

    return RawChip(
      avatar: avatar != null
          ? SizedBox(width: avatarSize, height: avatarSize, child: avatar)
          : null,
      label: Text(label, style: effectiveStyle),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
