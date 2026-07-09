import 'package:flutter/material.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Placeholder shown when a *ship* sprite is missing or can't be decoded:
/// a banana with the broken-image icon layered on top.
///
/// Ships only — the banana is a nod to the ship viewer. Other missing images
/// (portraits, mod icons, etc.) use a plain broken-image icon instead.
///
/// Use as the `errorBuilder` fallback for the ship sprite's `Image.file`. It
/// scales to fit whatever space its parent gives it while keeping the banana's
/// aspect ratio.
class BrokenShipImageWidget extends StatelessWidget {
  const BrokenShipImageWidget({super.key, this.iconColor});

  /// Color of the overlaid broken-image icon. Defaults to the theme's icon
  /// color if null.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: MovingTooltipWidget.text(
        message: "Image not found. This is a banana.",
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/images/banana.png'),
            // Fill 90% of the banana, then scale the icon to fit that box.
            Positioned.fill(
              child: FractionallySizedBox(
                widthFactor: 0.9,
                heightFactor: 0.9,
                child: FittedBox(
                  child: Opacity(
                    opacity: 0.85,
                    child: Icon(Icons.broken_image, color: iconColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
