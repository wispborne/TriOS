import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../widgets/context_menu_state.dart';
import '../../models/context_menu_item.dart';

Map<ShortcutActivator, VoidCallback> defaultMenuItemShortcuts(
  BuildContext context,
  ContextMenuItem item,
  ContextMenuState menuState,
) {
  final focusedEntry = menuState.focusedEntry;

  return {
    // opens submenu of the focused item
    const SingleActivator(LogicalKeyboardKey.arrowRight): () {
      if (focusedEntry is ContextMenuItem) {
        final item = focusedEntry;

        final bool isSubmenuOpen = menuState.isSubmenuOpen;
        final focusedItemIsNotTheSelectedItem =
            menuState.focusedEntry != menuState.selectedItem;
        if (item.isSubmenuItem &&
            !isSubmenuOpen &&
            focusedItemIsNotTheSelectedItem) {
          item.handleItemSelection(context);
        }
      }
    },
    const SingleActivator(LogicalKeyboardKey.space): () =>
        item.handleItemSelection(context),
    const SingleActivator(LogicalKeyboardKey.enter): () =>
        item.handleItemSelection(context),
    const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
        item.handleItemSelection(context),
  };
}
