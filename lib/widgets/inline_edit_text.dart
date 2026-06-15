import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trios/widgets/text_trios.dart';

/// A text field that displays as read-only text with a small edit icon,
/// switching to a [TextField] when activated.
///
/// In read mode, shows [label] + value (or [placeholder]) with a dotted
/// underline and a pencil icon. Clicking the value text or the icon enters
/// edit mode. Enter / check-icon confirms; Escape / X-icon cancels.
class InlineEditText extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final VoidCallback? onChanged;

  const InlineEditText({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder = '(empty)',
    this.onChanged,
  });

  @override
  State<InlineEditText> createState() => _InlineEditTextState();
}

class _InlineEditTextState extends State<InlineEditText> {
  bool _editing = false;
  late String _savedValue;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    setState(() {
      _savedValue = widget.controller.text;
      _editing = true;
    });
    // Schedule focus request after the TextField is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _confirm() {
    setState(() => _editing = false);
    if (widget.controller.text != _savedValue) {
      widget.onChanged?.call();
    }
  }

  void _cancel() {
    widget.controller.text = _savedValue;
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w100,
    );
    final valueStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.bold,
    );

    if (_editing) {
      return _buildEditMode(theme, labelStyle);
    }
    return _buildReadMode(labelStyle, valueStyle);
  }

  Widget _buildReadMode(TextStyle? labelStyle, TextStyle? valueStyle) {
    final text = widget.controller.text.trim();
    final hasValue = text.isNotEmpty;
    final displayText = hasValue ? text : widget.placeholder;

    final theme = Theme.of(context);
    final dottedStyle =
        (hasValue
                ? valueStyle
                : valueStyle?.copyWith(
                    fontWeight: FontWeight.w100,
                    fontStyle: FontStyle.italic,
                  ))
            ?.copyWith(
              decoration: .underline,
              decorationThickness: 3,
              decorationStyle: .dotted,
              decorationColor: theme.textTheme.bodyMedium?.color,
            );

    return Row(
      children: [
        SelectableText(widget.label, style: labelStyle),
        Flexible(
          child: GestureDetector(
            onTap: _enterEditMode,
            child: TextTriOS(
              displayText,
              style: dottedStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Edit',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _enterEditMode,
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(Icons.edit, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode(ThemeData theme, TextStyle? labelStyle) {
    return Row(
      children: [
        Text(widget.label, style: labelStyle),
        Flexible(
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _cancel();
              }
            },
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              style: theme.textTheme.bodySmall,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _confirm(),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Confirm',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _confirm,
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(Icons.check, size: 14),
            ),
          ),
        ),
        Tooltip(
          message: 'Cancel',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _cancel,
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(Icons.close, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
