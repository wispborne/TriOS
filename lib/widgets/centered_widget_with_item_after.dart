import 'package:flutter/material.dart';

class CenteredWidgetWithItemAfter extends StatelessWidget {
  final Widget centeredWidget;
  final Widget itemAfter;

  const CenteredWidgetWithItemAfter({
    super.key,
    required this.centeredWidget,
    required this.itemAfter,
  });

  @override
  Widget build(BuildContext context) {
    final LayerLink layerLink = LayerLink();

    return Stack(
      children: [
        Align(
          child: CompositedTransformTarget(
            link: layerLink,
            child: centeredWidget,
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          targetAnchor: Alignment.centerRight,
          followerAnchor: Alignment.centerLeft,
          child: itemAfter,
        ),
      ],
    );
  }
}
