import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/utils/extensions.dart';
import 'package:trios/trios/app_lifecycle_provider.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/rainbow_accent_bar.dart';

class TriOSAppIcon extends ConsumerStatefulWidget {
  final double width;
  final double height;
  final Color? color;

  const TriOSAppIcon({
    super.key,
    this.width = 48,
    this.height = 48,
    this.color,
  });

  @override
  ConsumerState<TriOSAppIcon> createState() => _TriOSAppIconState();
}

class _TriOSAppIconState extends ConsumerState<TriOSAppIcon>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  void _ensureController() {
    if (_controller != null) return;
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final iconAsset = theme.iconAsset;

    if (iconAsset != null) {
      return Image.asset(iconAsset, width: widget.width, height: widget.height);
    }

    final isRainbow = theme.rainbowAccent && widget.color == null;

    final svg = SvgPicture.asset(
      "assets/images/telos_faction_crest.svg",
      colorFilter: ColorFilter.mode(
        widget.color ?? (isRainbow ? Colors.white : theme.colorScheme.primary),
        BlendMode.srcIn,
      ),
      width: widget.width,
      height: widget.height,
    );

    if (!isRainbow) return svg;

    _ensureController();

    final lifecycle = ref.watch(appLifecycleProvider);
    if (lifecycle != AppLifecycleState.resumed) {
      _controller!.stop();
    } else if (!_controller!.isAnimating) {
      _controller!.repeat();
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: rainbowColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            transform: GradientRotation(_controller!.value * 2 * pi),
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: child,
        );
      },
      child: svg,
    );
  }
}
