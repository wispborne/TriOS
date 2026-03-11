import 'package:flutter/material.dart';
import 'package:trios/widgets/disable.dart';

import '../core/models/context_menu_entry.dart';
import '../core/models/context_menu_item.dart';
import '../core/utils/extensions.dart';
import '../widgets/context_menu_state.dart';

/// A menu item with a checkbox that stays open when toggled,
/// allowing multiple selections without closing the menu.
final class CheckableMenuItem extends ContextMenuItem<void> {
  final String label;
  final BoxConstraints? constraints;
  final bool enabled;
  final TextStyle? textStyle;

  /// Current checked state. Mutable so the menu can update visually.
  bool isChecked;

  CheckableMenuItem({
    required this.label,
    required this.isChecked,
    super.onSelected,
    this.constraints,
    this.enabled = true,
    this.textStyle,
  }) : super(keepMenuOpen: true);

  @override
  void handleItemSelection(BuildContext context) {
    isChecked = !isChecked;
    onSelected?.call();
    // Force a visual rebuild even if this entry is already focused.
    ContextMenuState.of(context).notifyListeners();
  }

  @override
  Widget builder(
    BuildContext context,
    ContextMenuState menuState, [
    FocusNode? focusNode,
  ]) {
    bool isFocused = menuState.focusedEntry == this;

    final background = context.colorScheme.surfaceContainerLow;
    final normalTextColor = Color.alphaBlend(
      context.colorScheme.onSurface.withOpacity(0.7),
      background,
    );
    final focusedTextColor = context.colorScheme.onSurface;
    final foregroundColor = isFocused ? focusedTextColor : normalTextColor;
    final usedTextStyle = TextStyle(
      color: foregroundColor,
      height: 1.0,
    ).merge(textStyle);

    return Disable(
      isEnabled: enabled,
      child: ConstrainedBox(
        constraints: constraints ?? const BoxConstraints.expand(height: 32.0),
        child: Material(
          color: isFocused
              ? context.theme.focusColor.withAlpha(20)
              : background,
          borderRadius: BorderRadius.circular(4.0),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => handleItemSelection(context),
            canRequestFocus: false,
            child: DefaultTextStyle(
              style: usedTextStyle,
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 32.0,
                    child: Icon(
                      isChecked
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 16.0,
                      color: foregroundColor,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  String get debugLabel => "[${hashCode.toString().substring(0, 5)}] $label";
}
