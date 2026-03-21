import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';

/// Wrap any widget with [Highlightable] to make it a target for programmatic
/// navigation highlighting. When [AppState.activeHighlightKey] matches
/// [highlightKey], this widget scrolls into view and plays a brief glow.
class Highlightable extends ConsumerStatefulWidget {
  final String highlightKey;
  final Widget child;

  const Highlightable({
    super.key,
    required this.highlightKey,
    required this.child,
  });

  @override
  ConsumerState<Highlightable> createState() => _HighlightableState();
}

class _HighlightableState extends ConsumerState<Highlightable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerHighlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Scroll into view.
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );

      // Play glow animation.
      _controller.forward(from: 0).then((_) {
        if (mounted) {
          _controller.reverse().then((_) {
            if (mounted) {
              ref.read(AppState.activeHighlightKey.notifier).state = null;
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeKey = ref.watch(AppState.activeHighlightKey);

    if (activeKey == widget.highlightKey) {
      _triggerHighlight();
    }

    final highlightColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: highlightColor.withValues(alpha: _animation.value * 0.6),
                blurRadius: 12 * _animation.value,
                spreadRadius: 4 * _animation.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
