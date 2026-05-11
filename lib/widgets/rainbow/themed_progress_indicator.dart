import 'package:flutter/material.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/utils/extensions.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/rainbow_accent_bar.dart';

/// Drop-in replacement for [CircularProgressIndicator] that applies a rainbow
/// gradient [ShaderMask] when the current theme has [rainbowAccent] enabled.
class ThemedCircularProgressIndicator extends StatelessWidget {
  final double? value;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;
  final StrokeCap? strokeCap;

  const ThemedCircularProgressIndicator({
    super.key,
    this.value,
    this.strokeWidth = 4.0,
    this.color,
    this.backgroundColor,
    this.strokeCap,
  });

  @override
  Widget build(BuildContext context) {
    if (!context.theme.rainbowAccent) {
      return CircularProgressIndicator(
        value: value,
        strokeWidth: strokeWidth,
        color: color,
        backgroundColor: backgroundColor,
        strokeCap: strokeCap,
      );
    }

    return Stack(
      children: [
        CircularProgressIndicator(
          value: 1.0,
          strokeWidth: strokeWidth,
          color: backgroundColor ??
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
          backgroundColor: Colors.transparent,
          strokeCap: strokeCap,
        ),
        ShaderMask(
          shaderCallback: (bounds) => const SweepGradient(
            colors: rainbowColors,
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.transparent,
            strokeCap: strokeCap,
          ),
        ),
      ],
    );
  }
}

/// Drop-in replacement for [LinearProgressIndicator] that applies a rainbow
/// gradient [ShaderMask] when the current theme has [rainbowAccent] enabled.
class ThemedLinearProgressIndicator extends StatelessWidget {
  final double? value;
  final Color? color;
  final Color? backgroundColor;
  final double minHeight;

  const ThemedLinearProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.minHeight = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!context.theme.rainbowAccent) {
      return LinearProgressIndicator(
        value: value,
        color: color,
        backgroundColor: backgroundColor,
        minHeight: minHeight,
      );
    }

    final trackColor = backgroundColor ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

    return Stack(
      children: [
        LinearProgressIndicator(
          value: 1.0,
          color: trackColor,
          backgroundColor: Colors.transparent,
          minHeight: minHeight,
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: rainbowColors,
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.transparent,
            minHeight: minHeight,
          ),
        ),
      ],
    );
  }
}
