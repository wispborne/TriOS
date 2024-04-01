import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Blur extends StatelessWidget {
  const Blur({
    super.key,
    required this.child,
    this.blurX = 5,
    this.blurY = 5,
    this.blurColor = Colors.white,
    this.blurOpacity = 1.0,
    this.colorOpacity = 0.0,
    this.alignment,
  });

  final Widget child;
  final double blurX;
  final double blurY;
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
            imageFilter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
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
