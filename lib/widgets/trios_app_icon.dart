import 'dart:math';
import 'dart:ui' as ui;

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

  final double? blurSigma;

  const TriOSAppIcon({
    super.key,
    this.width = 48,
    this.height = 48,
    this.color,
    this.blurSigma,
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
        return _maybeBlur(
          Image.asset(
            "assets/images/hegemony_crest.png",
            width: widget.width,
            height: widget.height,
          ),
        );
      case AppIconOverride.defaultIcon:
        // Fall through to existing theme-driven logic.
        break;
    }

    final iconAsset = theme.iconAsset;
    if (iconAsset != null) {
      _stopController();
      return _maybeBlur(
        Image.asset(iconAsset, width: widget.width, height: widget.height),
      );
    }

    final isRainbow = theme.rainbowAccent && widget.color == null;

    final svg = _buildTelosSvg(
      color:
          widget.color ??
          (isRainbow ? Colors.white : theme.colorScheme.primary),
    );

    if (!isRainbow) {
      _stopController();
      return _maybeBlur(svg);
    }

    return _maybeBlur(_buildAnimatedRainbow(svg));
  }

  Widget _buildRainbowIcon(ThemeData theme) {
    final svg = _buildTelosSvg(color: Colors.white);
    return _maybeBlur(_buildAnimatedRainbow(svg));
  }

  Widget _buildTelosSvg({required Color color}) {
    return SvgPicture.asset(
      "assets/images/telos_faction_crest.svg",
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      width: widget.width,
      height: widget.height,
    );
  }

  /// Wraps [child] in a blur when [TriOSAppIcon.blurSigma] is set, else returns
  /// it unchanged. Applied as the outermost layer (outside any rainbow
  /// [ShaderMask]) so the soft blur isn't clipped to the shader's rectangular
  /// `srcIn` bounds.
  Widget _maybeBlur(Widget child) {
    final sigma = widget.blurSigma;
    if (sigma == null) return child;
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
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
