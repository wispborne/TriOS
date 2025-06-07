import 'package:flutter/material.dart';
import 'dart:math';

class WavyLinePainter extends CustomPainter {
  final Color lineColor;
  final double lineHeight;
  final double dashWidth;
  final double dashSpace;

  WavyLinePainter({
    this.lineColor = Colors.black,
    this.lineHeight = 50.0,
    this.dashWidth = 10.0,
    this.dashSpace = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    path.moveTo(0, lineHeight);

    for (int i = 0; i < size.width; i++) {
      path.lineTo(i.toDouble(), lineHeight + sin(i * 0.1) * 0);
    }

    _drawDashedLine(canvas, path, dashWidth, dashSpace, paint);
  }

  void _drawDashedLine(
    Canvas canvas,
    Path path,
    double dashWidth,
    double dashSpace,
    Paint paint,
  ) {
    var pathMetrics = path.computeMetrics();
    for (var metric in pathMetrics) {
      for (double i = 0.0; i < metric.length; i += dashWidth + dashSpace) {
        final extractPath = metric.extractPath(i, i + dashWidth);
        canvas.drawPath(extractPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WavyLineWidget extends StatelessWidget {
  final Color color;
  final double height;

  const WavyLineWidget({
    super.key,
    this.color = Colors.black,
    this.height = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WavyLinePainter(lineColor: color, lineHeight: height),
      child: Container(height: height),
    );
  }
}
