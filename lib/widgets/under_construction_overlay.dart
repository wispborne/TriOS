import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UnderConstructionOverlay extends StatelessWidget {
  final Widget child;

  const UnderConstructionOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: ClipRRect(
            child: CustomPaint(
              painter: ConstructionTapePainter(),
            ),
          ),
        )
      ],
    );
  }
}

/// https://medium.com/@lanltn/flutter-stripe-pattern-canvas-d5f221869695
class ConstructionTapePainter extends CustomPainter {
  final stripeWidth = 5.0;
  final gapWidth = 5.0;
  final rotateDegree = 45.0;
  final stripeColor = Colors.yellow;
  final bgColor = Colors.transparent;
  final opacity = kDebugMode ? 0.2 : 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    /// Expand canvas size
    const offsetX = 10.0;
    const offsetY = 10.0;
    final width = size.width + offsetX * 2;
    final height = size.height + offsetY * 2;

    /// Shift canvas to top,left with offsetX,Y
    canvas.translate(-offsetX, -offsetY);

    /// Calculate the biggest diagonal of the screen.
    final double diagonal = sqrt(width * width + height * height);

    /// jointSize: distance from right edge of (i) stripe to right one of next stripe
    final double jointSize = stripeWidth + gapWidth;

    /// Calculate the number of iterations needed to cover the diagonal of the screen.
    final int numIterations = (diagonal / jointSize).ceil();

    /// convert degree to radian
    final rotateRadian = pi / 180 * rotateDegree;

    /// calculate the xOffset, yOffset according to the trigonometric formula
    final xOffset = jointSize / sin(rotateRadian);
    final yOffset = jointSize / sin(pi / 2 - rotateRadian);

    /// config stroke paint object
    final paint = Paint()
      ..color = stripeColor.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stripeWidth;
    final path = Path();

    /// setup the path
    for (int i = 0; i < numIterations; i++) {
      /// start point on Y axis -> xStart = 0
      final double yStart = i * yOffset;

      /// end point on X axis -> yEnd = 0
      final double xEnd = i * xOffset;

      /// make line start -> end
      path.moveTo(0, yStart);
      path.lineTo(xEnd, 0);
    }

    /// draw path on canvas by using paint object
    canvas.drawPath(path, paint);

    /// Fill the pattern area background with the patternColor.
    final patternPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, patternPaint);

    // final textPainter = TextPainter(
    //   text: TextSpan(
    //     text: 'Under Construction',
    //     style: TextStyle(
    //       color: Colors.white,
    //       fontSize: size.width * 0.1, // Adjust font size
    //     ),
    //   ),
    //   textDirection: TextDirection.ltr,
    // );
    // textPainter.layout(maxWidth: size.width);
    // textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(ConstructionTapePainter oldDelegate) => false;
}
