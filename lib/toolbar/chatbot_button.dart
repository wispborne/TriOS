import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trios/chatbot/chatbot_dialog.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/widgets/animated_gradient_border.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Delta Core button with an animated conic-gradient glowing border.
/// Opens the Delta Core dialog when pressed.
class ChatbotButton extends StatefulWidget {
  /// Overall size of the button (width and height).
  final double size;

  /// Horizontal offset for the icon within the circle.
  final double iconOffsetX;

  /// Vertical offset for the icon within the circle.
  final double iconOffsetY;

  final double iconSize;

  const ChatbotButton({
    super.key,
    this.size = 26,
    this.iconSize = 14,
    this.iconOffsetX = -2,
    this.iconOffsetY = 0,
  });

  @override
  State<ChatbotButton> createState() => _ChatbotButtonState();
}

class _ChatbotButtonState extends State<ChatbotButton>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _hoverController;

  static const _normalDuration = Duration(milliseconds: 8000);
  static const _hoverDuration = Duration(milliseconds: 3000);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _normalDuration, vsync: this)
      ..repeat();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool hovering) {
    if (hovering) {
      // Speed up: preserve position in the cycle, just change duration.
      _controller.duration = _hoverDuration;
      _controller.repeat();
      _hoverController.forward();
    } else {
      _controller.duration = _normalDuration;
      _controller.repeat();
      _hoverController.reverse();
    }
  }

  /// Extra space around the circle to prevent the glow from clipping.
  /// Must accommodate: half max stroke (8/2=4) + max blur (5.5) ≈ 10px.
  static const _glowInset = 12.0;

  @override
  Widget build(BuildContext context) {
    final gradientColors = deltaCoreColors;

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: SizedBox(
        width: widget.size + _glowInset * 2,
        height: widget.size + _glowInset * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated glowing border, inset so the glow fits within layout.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(_glowInset),
                child: AnimatedBuilder(
                  animation: _hoverController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _GlowingBorderPainter(
                        animation: _controller,
                        colors: gradientColors,
                        hoverFactor: _hoverController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
            // The icon, optionally offset horizontally.
            Positioned(
              left: widget.iconOffsetX,
              right: -widget.iconOffsetX,
              top: widget.iconOffsetY,
              bottom: -widget.iconOffsetY,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // final iconColor = _lerpThroughColors(
                  //   gradientColors,
                  //   (_controller.value + 0.35) % 1.0,
                  // );
                  return MovingTooltipWidget(
                    tooltipWidget: _AnimatedGradientTooltip(
                      message: "Chat with ${Constants.chatbotName}",
                      colors: gradientColors,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.auto_awesome, size: widget.iconSize),
                      style: IconButton.styleFrom(
                        // Remove default hover/splash overlay.
                        overlayColor: Colors.transparent,
                      ),
                      onPressed: () => ChatbotDialog.show(context),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lerp through a color list by a normalized [t] in [0, 1).
  static Color _lerpThroughColors(List<Color> colors, double t) {
    final count = colors.length - 1;
    final scaled = t * count;
    final index = scaled.floor().clamp(0, count - 1);
    final frac = scaled - index;
    return Color.lerp(colors[index], colors[index + 1], frac)!;
  }
}

/// Paints a rotating conic gradient as a circular border with an outer glow,
/// mimicking the CSS `conic-gradient` + `filter: blur()` pattern.
class _GlowingBorderPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Color> colors;

  /// 0.0 = normal, 1.0 = fully hovered (larger + brighter glow).
  final double hoverFactor;

  _GlowingBorderPainter({
    required this.animation,
    required this.colors,
    this.hoverFactor = 0.0,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 2;
    final angle = animation.value * 2 * pi;

    final gradient = SweepGradient(
      transform: GradientRotation(angle),
      colors: colors,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Outer glow — scales up on hover.
    final glowStroke = 5.0 + hoverFactor * 3.0;
    final glowBlur = 4.0 + hoverFactor * 1.5;

    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowStroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur);

    canvas.drawCircle(center, radius, glowPaint);

    // Crisp border ring on top.
    final borderPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(_GlowingBorderPainter oldDelegate) {
    return oldDelegate.hoverFactor != hoverFactor;
  }
}

/// A tooltip frame with an animated rotating gradient border.
class _AnimatedGradientTooltip extends StatelessWidget {
  final String message;
  final List<Color> colors;

  const _AnimatedGradientTooltip({required this.message, required this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: AnimatedGradientBorder(
        colors: colors,
        borderRadius: ThemeManager.cornerRadius,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(message, style: theme.textTheme.bodySmall),
          ),
        ),
      ),
    );
  }
}
