import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/utils/extensions.dart';
import 'package:trios/trios/app_lifecycle_provider.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/rainbow_accent_bar.dart';

/// A thin accent bar that renders a slowly-animated rainbow gradient when
/// the current theme has [rainbowAccent] enabled. Renders nothing otherwise.
class ThemedAccentBar extends ConsumerStatefulWidget {
  final Axis axis;
  final double thickness;

  const ThemedAccentBar({
    super.key,
    required this.axis,
    this.thickness = 4.0,
  });

  @override
  ConsumerState<ThemedAccentBar> createState() => _ThemedAccentBarState();
}

class _ThemedAccentBarState extends ConsumerState<ThemedAccentBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!context.theme.rainbowAccent) return const SizedBox.shrink();

    final lifecycle = ref.watch(appLifecycleProvider);
    if (lifecycle != AppLifecycleState.resumed) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }

    final isVertical = widget.axis == Axis.vertical;

    return SizedBox(
      width: isVertical ? widget.thickness : double.infinity,
      height: isVertical ? double.infinity : widget.thickness,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Opacity(
            opacity: 0.6,
            child: CustomPaint(
              painter: _FlowingGradientPainter(
                progress: _controller.value,
                axis: widget.axis,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FlowingGradientPainter extends CustomPainter {
  static final _doubled = [...rainbowColors, ...rainbowColors];
  final double progress;
  final Axis axis;
  final _paint = Paint();

  _FlowingGradientPainter({
    required this.progress,
    required this.axis,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isVertical = axis == Axis.vertical;

    final gradient = LinearGradient(
      colors: _doubled,
      begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
      end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
      transform: _SlideGradientTransform(progress),
    );

    _paint.shader = gradient.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, _paint);
  }

  @override
  bool shouldRepaint(_FlowingGradientPainter old) =>
      old.progress != progress;
}

class _SlideGradientTransform extends GradientTransform {
  final double progress;

  const _SlideGradientTransform(this.progress);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * progress, 0, 0);
  }
}
