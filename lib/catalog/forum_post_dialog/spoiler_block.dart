import 'package:flutter/material.dart';

/// Renders an SMF forum spoiler block as a collapsible section.
/// Starts collapsed when [initiallyCollapsed] is true (SMF's default when
/// the body has `class="... folded"`).
class SpoilerBlock extends StatefulWidget {
  final String label;
  final List<Widget> body;
  final bool initiallyCollapsed;

  const SpoilerBlock({
    super.key,
    required this.label,
    required this.body,
    this.initiallyCollapsed = true,
  });

  @override
  State<SpoilerBlock> createState() => _SpoilerBlockState();
}

class _SpoilerBlockState extends State<SpoilerBlock> {
  late bool _collapsed = widget.initiallyCollapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _collapsed = !_collapsed),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      _collapsed ? Icons.expand_more : Icons.expand_less,
                      size: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      widget.label.isNotEmpty ? widget.label : 'Spoiler',
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
            if (!_collapsed)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.body,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
