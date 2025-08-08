import 'package:flutter/material.dart';

/// Three-dot icon button that displays a popup menu.
class OverflowMenuButton extends StatelessWidget {
  final List<PopupMenuEntry<int>> menuItems;
  final String tooltip;
  final IconData? buttonIcon;
  final Color? iconColor;
  final double? iconSize;

  const OverflowMenuButton({
    super.key,
    required this.menuItems,
    this.tooltip = "More options",
    this.buttonIcon,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PopupMenuButton<int>(
        tooltip: "",
        icon: Icon(
          buttonIcon ?? Icons.more_vert,
          color: iconColor,
          size: iconSize,
        ),
        itemBuilder: (context) => menuItems,
      ),
    );
  }
}

class OverflowMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? subtitle;

  const OverflowMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  PopupMenuEntry<int> toEntry(int? key) => PopupMenuItem<int>(
    value: key,
    onTap: onTap,
    child: ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
    ),
  );
}

// Alternative version with confirmation dialogs support
class GenericOverflowButtonWithConfirmation extends StatelessWidget {
  final List<OverflowMenuItem> menuItems;
  final String tooltip;
  final IconData? buttonIcon;
  final Color? iconColor;
  final double? iconSize;

  const GenericOverflowButtonWithConfirmation({
    super.key,
    required this.menuItems,
    this.tooltip = "More options",
    this.buttonIcon,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PopupMenuButton<int>(
        tooltip: "",
        icon: Icon(
          buttonIcon ?? Icons.more_vert,
          color: iconColor,
          size: iconSize,
        ),
        itemBuilder: (context) => menuItems
            .asMap()
            .entries
            .map(
              (entry) => PopupMenuItem<int>(
                value: entry.key,
                onTap: entry.value.onTap,
                child: ListTile(
                  dense: true,
                  leading: Icon(entry.value.icon),
                  title: Text(entry.value.title),
                  subtitle: entry.value.subtitle != null
                      ? Text(entry.value.subtitle!)
                      : null,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// Helper class for items that need confirmation dialogs
class ConfirmationOverflowMenuItem extends OverflowMenuItem {
  final String confirmationTitle;
  final Widget confirmationContent;
  final String confirmButtonText;
  final String cancelButtonText;

  const ConfirmationOverflowMenuItem({
    required super.title,
    required super.icon,
    required super.onTap,
    super.subtitle,
    required this.confirmationTitle,
    required this.confirmationContent,
    this.confirmButtonText = "Confirm",
    this.cancelButtonText = "Cancel",
  });

  // Factory method to create a confirmation dialog action
  static OverflowMenuItem withConfirmation({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onConfirm,
    required String confirmationTitle,
    required Widget confirmationContent,
    String? subtitle,
    String confirmButtonText = "Confirm",
    String cancelButtonText = "Cancel",
  }) {
    return OverflowMenuItem(
      title: title,
      icon: icon,
      subtitle: subtitle,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(confirmationTitle),
              content: confirmationContent,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(cancelButtonText),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  child: Text(confirmButtonText),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
