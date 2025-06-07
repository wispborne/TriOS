import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models/context_menu.dart';
import '../core/utils/helpers.dart';
import '../core/utils/menu_route_options.dart';

/// A function that builds the context menu widget.
///
/// - [context] - The build context.
/// - [contextMenu] - The context menu to be built.
/// - [pointerPosition] - The position of the pointer (like mouse or touch) on the screen.
/// - [showMenu] - The function to show the context menu.
/// - [child] - The child widget.
typedef ContextMenuRegionBuilder<T> =
    Widget Function(
      BuildContext context,
      ContextMenu contextMenu,
      Offset pointerPosition,
      void Function() showMenu,
      Widget? child,
    );

/// A widget that shows a context menu when the user long presses or right clicks on the widget.
class ContextMenuRegion<T> extends StatefulWidget {
  const ContextMenuRegion({
    super.key,
    required this.contextMenu,
    this.enableGestures = true,
    this.onItemSelected,
    this.builder,
    this.child,
    this.routeOptions,
  });

  final ContextMenu contextMenu;

  /// Whether to enable built-in gestures on the widget.
  ///
  /// This is helpful when you want to use a custom gesture recognizer for the widget.
  final bool enableGestures;

  final ValueChanged<T>? onItemSelected;
  final ContextMenuRegionBuilder<T>? builder;
  final Widget? child;
  final MenuRouteOptions? routeOptions;

  @override
  State<ContextMenuRegion<T>> createState() => _ContextMenuRegionState<T>();
}

class _ContextMenuRegionState<T> extends State<ContextMenuRegion<T>> {
  @override
  void initState() {
    // BrowserContextMenu.disableContextMenu();
    super.initState();
  }

  @override
  void dispose() {
    // BrowserContextMenu.enableContextMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Offset pointerPosition = Offset.zero;

    final childBuilder =
        widget.builder?.call(
          context,
          widget.contextMenu,
          pointerPosition,
          () => _showMenu(context, pointerPosition),
          widget.child,
        ) ??
        widget.child;

    if (widget.enableGestures) {
      return GestureDetector(
        onLongPressStart: (details) {
          pointerPosition = details.globalPosition;
          _showMenu(context, pointerPosition);
        },
        onSecondaryTapUp: (details) {
          pointerPosition = details.globalPosition;
          _showMenu(context, pointerPosition);
        },
        child: childBuilder,
      );
    } else {
      return childBuilder ?? const SizedBox.expand();
    }
  }

  void _showMenu(BuildContext context, Offset position) async {
    final menu = widget.contextMenu.copyWith(
      position: widget.contextMenu.position ?? position,
    );
    final value = await showContextMenu(
      context,
      contextMenu: menu,
      routeOptions: widget.routeOptions,
    );
    widget.onItemSelected?.call(value);
  }
}
