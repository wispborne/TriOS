import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Added to the end of a search box's hint text when [SearchHotkey] wraps it.
const searchHotkeyHint = '  (press /)';

/// Pressing `/` puts the cursor in the search box built by [builder] and
/// selects its text.
///
/// The key is ignored while the user is typing in a text field, while the page
/// is a hidden tab, and while a dialog covers the page.
class SearchHotkey extends StatefulWidget {
  final TextEditingController controller;

  /// The search box's focus node. If null, this widget makes one.
  final FocusNode? focusNode;

  /// Set to false when another search box on the same page should get the key.
  final bool enabled;

  /// Builds the search box. It must use the given focus node.
  final Widget Function(BuildContext context, FocusNode focusNode) builder;

  const SearchHotkey({
    super.key,
    required this.controller,
    required this.builder,
    this.focusNode,
    this.enabled = true,
  });

  @override
  State<SearchHotkey> createState() => _SearchHotkeyState();
}

class _SearchHotkeyState extends State<SearchHotkey> {
  FocusNode? _ownFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  /// Hidden tabs have [TickerMode] disabled; their search box must not take
  /// the key.
  bool _isPageVisible = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent || event.character != '/') return false;
    if (!widget.enabled || !mounted || !_isPageVisible) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;

    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed ||
        _isTypingInTextField()) {
      return false;
    }

    _focusNode.requestFocus();
    widget.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.controller.text.length,
    );
    return true;
  }

  bool _isTypingInTextField() =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>() !=
      null;

  @override
  Widget build(BuildContext context) {
    _isPageVisible = TickerMode.valuesOf(context).enabled;
    return widget.builder(context, _focusNode);
  }
}
