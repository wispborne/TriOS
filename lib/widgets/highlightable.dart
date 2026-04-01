import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';

/// Wrap any widget with [Highlightable] to make it a target for programmatic
/// navigation highlighting. When [AppState.activeHighlightKey] matches
/// [highlightKey], this widget scrolls into view and plays a brief glow.
class Highlightable extends ConsumerStatefulWidget {
  final String highlightKey;
  final Widget child;

  /// Extra outset around the child where the highlight border is drawn.
  /// Does not affect the child's layout.
  final EdgeInsets borderPadding;

  /// Border radius of the highlight outline.
  final BorderRadius borderRadius;

  /// Width of the highlight border.
  final double borderWidth;

  /// Peak opacity of the highlight border (0.0–1.0).
  final double peakOpacity;

  /// Number of times the fade-in/fade-out cycle plays.
  final int repeatCount;

  const Highlightable({
    super.key,
    required this.highlightKey,
    required this.child,
    this.borderPadding = const EdgeInsets.all(4),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.borderWidth = 2,
    this.peakOpacity = 0.6,
    this.repeatCount = 2,
  });

  @override
  ConsumerState<Highlightable> createState() => _HighlightableState();
}

class _HighlightableState extends ConsumerState<Highlightable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _highlightScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerHighlight() {
    if (_highlightScheduled) return;
    _highlightScheduled = true;

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
      _playCycle(0);
    });
  }

  void _playCycle(int iteration) {
    if (!mounted) return;
    _controller.forward(from: 0).then((_) {
      if (!mounted) return;
      _controller.reverse().then((_) {
        if (!mounted) return;
        final next = iteration + 1;
        if (next < widget.repeatCount) {
          _playCycle(next);
        } else {
          _highlightScheduled = false;
          ref.read(AppState.activeHighlightKey.notifier).state = null;
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
        final bp = widget.borderPadding;
        return UnconstrainedBox(
          alignment: AlignmentDirectional.centerStart,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child!,
              Positioned(
                left: -bp.left,
                top: -bp.top,
                right: -bp.right,
                bottom: -bp.bottom,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: widget.borderRadius,
                      border: Border.all(
                        color: highlightColor.withValues(
                          alpha: _animation.value * widget.peakOpacity,
                        ),
                        width: widget.borderWidth,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
