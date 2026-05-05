import 'package:flutter/material.dart';
import 'package:trios/thirdparty/faded_scrollable/faded_scrollable.dart';

import '../core/utils/shortcuts/menu_shortcuts.dart';
import 'context_menu_provider.dart';
import 'context_menu_state.dart';
import 'menu_entry_widget.dart';

/// Widget that displays the context menu.
///
/// This widget is used internally.
///
/// see:
/// - [ContextMenuState]

class ContextMenuWidget extends StatelessWidget {
  final ContextMenuState menuState;

  const ContextMenuWidget({super.key, required this.menuState});

  @override
  Widget build(BuildContext context) {
    return ContextMenuProvider(
      state: menuState,
      child: Builder(
        builder: (context) {
          final state = ContextMenuState.of(context);
          state.verifyPosition(context);

          return Positioned(
            key: state.key,
            left: state.position.dx,
            top: state.position.dy,
            child: OverlayPortal(
              controller: state.overlayController,
              overlayChildBuilder: state.submenuBuilder,
              child: CallbackShortcuts(
                bindings: defaultMenuShortcuts(context, state)
                  ..addAll(state.shortcuts),
                child: FocusScope(
                  autofocus: true,
                  node: state.focusScopeNode,
                  child: Opacity(
                    opacity: state.isPositionVerified ? 1.0 : 0.0,
                    child: _buildMenuView(context, state),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the context menu view.
  Widget _buildMenuView(BuildContext context, ContextMenuState state) {
    var boxDecoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).shadowColor.withValues(alpha: 0.5),
          offset: const Offset(0.0, 2.0),
          blurRadius: 10,
          spreadRadius: -1,
        ),
      ],
      borderRadius: state.borderRadius ?? BorderRadius.circular(4.0),
      border: Border.all(
        width: 1.0,
        color: Theme.of(
          context,
        ).colorScheme.primaryFixedDim.withValues(alpha: 0.2),
      ),
    );

    // Default to a screen-fit cap so a tall menu becomes scrollable instead
    // of overflowing the viewport. Callers can pass an explicit `maxHeight`
    // (including `double.infinity` to opt out of the cap entirely).
    const safetyMargin = 8.0;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final availableHeight = screenHeight - state.position.dy - safetyMargin;
    final effectiveMaxHeight =
        state.maxHeight ?? (availableHeight > 0 ? availableHeight : 0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 30),
      builder: (context, value, child) {
        final menu = Container(
          padding: state.padding,
          constraints: BoxConstraints(
            maxWidth: state.maxWidth,
            maxHeight: effectiveMaxHeight,
          ),
          clipBehavior: state.clipBehavior,
          decoration: state.boxDecoration ?? boxDecoration,
          child: Material(
            type: MaterialType.transparency,
            child: IntrinsicWidth(
              child: _buildMenuContent(state, effectiveMaxHeight),
            ),
          ),
        );
        return menu;
      },
    );
  }

  Widget _buildMenuContent(ContextMenuState state, double effectiveMaxHeight) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in state.entries) MenuEntryWidget(entry: item),
      ],
    );

    if (effectiveMaxHeight == double.infinity) {
      return column;
    }

    return FadedScrollable(
      child: SingleChildScrollView(child: column),
    );
  }
}
