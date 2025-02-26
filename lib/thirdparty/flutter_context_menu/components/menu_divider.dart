import 'package:flutter/material.dart';

import '../core/models/context_menu_entry.dart';
import '../widgets/context_menu_state.dart';
import 'menu_header.dart';
import 'menu_item.dart';

/// Represents a divider in a context menu.
///
/// This class is used to define a divider that can be displayed within a context menu.
///
/// #### Parameters:
/// - [height] - The height of the divider.
/// - [thickness] - The thickness of the divider.
/// - [indent] - The indent of the divider.
/// - [endIndent] - The end indent of the divider.
/// - [color] - The color of the divider.
///
/// see:
/// - [ContextMenuEntry]
/// - [MenuHeader]
/// - [MenuItem]
///
final class MenuDivider extends ContextMenuEntry {
  final double? height;
  final double? thickness;
  final double? indent;
  final double? endIndent;
  final Color? color;

  const MenuDivider({
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
  }) : assert(height == null || height >= 0.0),
       assert(thickness == null || thickness >= 0.0),
       assert(indent == null || indent >= 0.0),
       assert(endIndent == null || endIndent >= 0.0);

  @override
  Widget builder(BuildContext context, ContextMenuState menuState) {
    return Divider(
      height: height ?? 8.0,
      thickness: thickness ?? 0.0,
      indent: indent,
      endIndent: endIndent,
      color: color,
    );
  }
}
