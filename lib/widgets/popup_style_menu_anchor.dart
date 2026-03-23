import 'package:flutter/material.dart';
import 'package:trios/themes/theme_manager.dart';

/// A wrapper around [MenuAnchor] that applies styling to match [PopupMenuButton]'s
/// visual appearance (padding, elevation, shape).
class PopupStyleMenuAnchor extends StatelessWidget {
  final Widget Function(BuildContext, MenuController, Widget?)? builder;
  final List<Widget> menuChildren;
  final MenuController? controller;
  final Offset? alignmentOffset;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final bool crossAxisUnconstrained;
  final bool consumeOutsideTap;

  const PopupStyleMenuAnchor({
    super.key,
    this.builder,
    required this.menuChildren,
    this.controller,
    this.alignmentOffset,
    this.onOpen,
    this.onClose,
    this.crossAxisUnconstrained = true,
    this.consumeOutsideTap = false,
  });

  /// Returns a [MenuStyle] that matches [PopupMenuButton]'s appearance.
  static MenuStyle popupMenuStyle(BuildContext context) {
    final theme = Theme.of(context);
    return MenuStyle(
      elevation: const WidgetStatePropertyAll(8),
      padding: const WidgetStatePropertyAll(.symmetric(vertical: 8)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
        ),
      ),
      backgroundColor: WidgetStatePropertyAll(
        theme.colorScheme.surfaceContainer,
      ),
    );
  }

  /// Returns a [ButtonStyle] for menu items matching [PopupMenuButton]'s item spacing.
  static ButtonStyle popupMenuItemStyle() {
    return const ButtonStyle(
      padding: WidgetStatePropertyAll(.symmetric(horizontal: 16)),
      minimumSize: WidgetStatePropertyAll(Size(0, 48)),
    );
  }

  /// Wraps a leading icon widget with extra right padding to increase the gap
  /// between the icon and the menu item text.
  ///
  /// Flutter's [MenuItemButton] hardcodes a 12dp icon-to-text gap internally.
  /// Use this to add extra spacing (default 4dp) to match [PopupMenuButton]'s
  /// more generous layout.
  /// The extra dp added by [paddedIcon] and [paddedLabel] to align icons and
  /// checkbox text.
  static const double iconTextGapExtra = 4;

  /// Wraps a [MenuItemButton.leadingIcon] with extra right padding so that
  /// text aligns with [CheckboxMenuButton] children that use [paddedLabel].
  static Widget paddedIcon(Widget icon) {
    return Padding(
      padding: const .only(right: iconTextGapExtra),
      child: icon,
    );
  }

  /// Wraps a [CheckboxMenuButton] child with extra left padding so that
  /// text aligns with [MenuItemButton] items that use [paddedIcon].
  static Widget paddedLabel(Widget label) {
    return Padding(
      padding: const .only(left: iconTextGapExtra),
      child: label,
    );
  }

  /// Builds a [MenuItemButton] styled as a checkbox menu item.
  ///
  /// Use instead of [CheckboxMenuButton] for consistent icon sizing.
  static Widget checkboxItem({
    required bool value,
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return MenuItemButton(
      leadingIcon: paddedIcon(
        Icon(
          value
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          size: 24,
        ),
      ),
      onPressed: onPressed,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        menuButtonTheme: MenuButtonThemeData(style: popupMenuItemStyle()),
      ),
      child: MenuAnchor(
        style: popupMenuStyle(context),
        builder: builder,
        controller: controller,
        alignmentOffset: alignmentOffset ?? Offset.zero,
        onOpen: onOpen,
        onClose: onClose,
        crossAxisUnconstrained: crossAxisUnconstrained,
        consumeOutsideTap: consumeOutsideTap,
        menuChildren: menuChildren,
      ),
    );
  }
}
