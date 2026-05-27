import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/utils/extensions.dart';
import 'package:trios/trios/app_lifecycle_provider.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
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

  void _stopController() {
    _controller?.stop();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final iconOverride = ref.watch(
      appSettings.select((s) => s.themeModifiers.appIconOverride),
    );

    // Modifier overrides take priority over theme.
    switch (iconOverride) {
      case AppIconOverride.pride:
        return _buildRainbowIcon(theme);
      case AppIconOverride.hegemony:
        _stopController();
        return Image.asset(
          "assets/images/hegemony_crest.png",
          width: widget.width,
          height: widget.height,
        );
      case AppIconOverride.defaultIcon:
        // Fall through to existing theme-driven logic.
        break;
    }

    final iconAsset = theme.iconAsset;
    if (iconAsset != null) {
      _stopController();
      return Image.asset(iconAsset, width: widget.width, height: widget.height);
    }

    final isRainbow = theme.rainbowAccent && widget.color == null;

    final svg = _buildTelosSvg(
      color: widget.color ?? (isRainbow ? Colors.white : theme.colorScheme.primary),
    );

    if (!isRainbow) {
      _stopController();
      return svg;
    }

    return _buildAnimatedRainbow(svg);
  }

  Widget _buildRainbowIcon(ThemeData theme) {
    final svg = _buildTelosSvg(color: Colors.white);
    return _buildAnimatedRainbow(svg);
  }

  Widget _buildTelosSvg({required Color color}) {
    return SvgPicture.asset(
      "assets/images/telos_faction_crest.svg",
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      width: widget.width,
      height: widget.height,
    );
  }

  Widget _buildAnimatedRainbow(Widget svg) {
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
