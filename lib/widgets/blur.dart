import 'dart:ui';

import 'package:flutter/material.dart';

class Blur extends StatelessWidget {
  const Blur({
    super.key,
    required this.child,
    this.blurX = 5,
    this.blurY = 5,
    this.blurColor = Colors.white,
    this.borderRadius,
    this.colorOpacity = 0.0,
    this.overlay,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final double blurX;
  final double blurY;
  final Color blurColor;
  final BorderRadius? borderRadius;
  final double colorOpacity;
  final Widget? overlay;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      clipBehavior: borderRadius == null ? Clip.none : Clip.antiAlias,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
              child: Container(
                decoration: BoxDecoration(
                  color: blurColor.withOpacity(colorOpacity),
                ),
                alignment: alignment,
                child: overlay,
              ),
            ),
          ),
        ],
      ),
    );
  }
}