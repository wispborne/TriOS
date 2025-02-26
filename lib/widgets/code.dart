import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

/// A widget that styles its child like code, with monospaced font and background.
/// Optionally adds a clipboard button to copy the text.
class Code extends StatelessWidget {
  final Widget child;
  final bool showCopyButton;

  const Code({super.key, required this.child, this.showCopyButton = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DefaultTextStyle.merge(
            style: GoogleFonts.robotoMono().copyWith(fontSize: 14),
            child: child,
          ),
          if (showCopyButton)
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              padding: const EdgeInsets.all(0),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              tooltip: 'Copy to clipboard',
              onPressed: () {
                _copyTextToClipboard(context);
              },
            ),
        ],
      ),
    );
  }

  void _copyTextToClipboard(BuildContext context) {
    String textToCopy = '';

    if (child is Text) {
      textToCopy = (child as Text).data ?? '';
    } else if (child is SelectableText) {
      textToCopy = (child as SelectableText).data ?? '';
    } else {
      // Extract text manually if the child is rich or complex
      final buffer = StringBuffer();
      void extractText(Widget widget) {
        if (widget is Text) {
          buffer.write(widget.data ?? '');
        } else if (widget is SelectableText) {
          buffer.write(widget.data ?? '');
        } else if (widget is RichText) {
          widget.text.visitChildren((span) {
            if (span is TextSpan) {
              buffer.write(span.text ?? '');
            }
            return true;
          });
        }
      }

      extractText(child);
      textToCopy = buffer.toString();
    }

    if (textToCopy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textToCopy));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nothing to copy')));
    }
  }
}
