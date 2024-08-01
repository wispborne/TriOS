import 'package:flutter/material.dart';

import '../themes/theme_manager.dart';

class TriOSExpansionTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final ValueChanged<bool>? onExpansionChanged;
  final List<Widget> children;
  final Widget? trailing;
  final bool initiallyExpanded;
  final bool maintainState;
  final EdgeInsetsGeometry? tilePadding;
  final CrossAxisAlignment? expandedCrossAxisAlignment;
  final Alignment? expandedAlignment;
  final EdgeInsetsGeometry? childrenPadding;
  final Color? backgroundColor;
  final Color? collapsedBackgroundColor;
  final Color? textColor;
  final Color? collapsedTextColor;
  final Color? iconColor;
  final Color? collapsedIconColor;
  final ShapeBorder? shape;
  final ShapeBorder? collapsedShape;
  final Clip? clipBehavior;
  final ListTileControlAffinity? controlAffinity;
  final ExpansionTileController? controller;
  final bool? dense;
  final VisualDensity? visualDensity;
  final double? minTileHeight;
  final bool enableFeedback;
  final bool enabled;
  final AnimationStyle? expansionAnimationStyle;

  const TriOSExpansionTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.onExpansionChanged,
    this.children = const <Widget>[],
    this.trailing,
    this.initiallyExpanded = false,
    this.maintainState = false,
    this.tilePadding,
    this.expandedCrossAxisAlignment,
    this.expandedAlignment,
    this.childrenPadding,
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.textColor,
    this.collapsedTextColor,
    this.iconColor,
    this.collapsedIconColor,
    this.shape,
    this.collapsedShape,
    this.clipBehavior,
    this.controlAffinity,
    this.controller,
    this.dense,
    this.visualDensity,
    this.minTileHeight,
    this.enableFeedback = true,
    this.enabled = true,
    this.expansionAnimationStyle,
  }) : assert(
          expandedCrossAxisAlignment != CrossAxisAlignment.baseline,
          'CrossAxisAlignment.baseline is not supported since the expanded children '
          'are aligned in a column, not a row. Try to use another constant.',
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      onExpansionChanged: onExpansionChanged,
      trailing: trailing,
      initiallyExpanded: initiallyExpanded,
      maintainState: maintainState,
      tilePadding: tilePadding,
      expandedCrossAxisAlignment: expandedCrossAxisAlignment,
      expandedAlignment: expandedAlignment,
      childrenPadding: childrenPadding,
      backgroundColor: backgroundColor ?? theme.colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          collapsedBackgroundColor ?? theme.colorScheme.surfaceContainerLow,
      textColor: textColor,
      collapsedTextColor: collapsedTextColor,
      iconColor: iconColor,
      collapsedIconColor: collapsedIconColor,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
          ),
      collapsedShape: collapsedShape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
          ),
      clipBehavior: clipBehavior,
      controlAffinity: controlAffinity,
      controller: controller,
      dense: dense ?? true,
      visualDensity: visualDensity,
      minTileHeight: minTileHeight,
      enableFeedback: enableFeedback,
      enabled: enabled,
      expansionAnimationStyle: expansionAnimationStyle,
      children: children,
    );
  }
}
