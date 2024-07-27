import 'dart:ui';

import 'package:flutter/material.dart';

class Blur extends StatelessWidget {
  const Blur({
    super.key,
    required this.child,
    this.blurX,
    this.blurY,
    this.blur = 5,
    this.blurColor = Colors.white,
    this.blurOpacity = 1.0,
    this.colorOpacity = 0.0,
    this.alignment,
  }) : assert((blurX != null && blurY != null) || blur != null);

  final Widget child;
  final double? blurX;
  final double? blurY;
  final double? blur;
  final Color blurColor;
  final double blurOpacity;
  final double colorOpacity;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: blurOpacity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
                sigmaX: blurX ?? blur!, sigmaY: blurY ?? blur!),
            child: Container(
              decoration: BoxDecoration(
                color: blurColor.withOpacity(colorOpacity),
              ),
              alignment: alignment,
              child: child,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
