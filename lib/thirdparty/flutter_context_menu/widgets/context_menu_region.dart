import 'package:flutter/material.dart';

import '../core/models/context_menu.dart';
import '../core/utils/helpers.dart';

/// A widget that shows a context menu when the user long presses or right clicks on the widget.
class ContextMenuRegion extends StatelessWidget {
  final ContextMenu contextMenu;
  final Widget child;
  final ValueChanged<dynamic>? onItemSelected;

  const ContextMenuRegion({
    super.key,
    required this.contextMenu,
    required this.child,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    Offset mousePosition = Offset.zero;

    return Listener(
      onPointerDown: (event) {
        mousePosition = event.position;
      },
      child: GestureDetector(
        onLongPress: () => _showMenu(context, mousePosition),
        onSecondaryTap: () => _showMenu(context, mousePosition),
        child: child,
      ),
    );
  }

  void _showMenu(BuildContext context, Offset mousePosition) async {
    final menu = contextMenu.copyWith(
      position: contextMenu.position ?? mousePosition,
    );
    final value = await showContextMenu(context, contextMenu: menu);
    onItemSelected?.call(value);
  }
}
