import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/utils/extensions.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/rainbow_accent_bar.dart';

class TriOSAppIcon extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = context.theme;
    final iconAsset = theme.iconAsset;

    if (iconAsset != null) {
      return Image.asset(iconAsset, width: width, height: height);
    }

    final rainbowAccent = theme.rainbowAccent;

    final svg = SvgPicture.asset(
      "assets/images/telos_faction_crest.svg",
      colorFilter: ColorFilter.mode(
        color ?? (rainbowAccent ? Colors.white : theme.colorScheme.primary),
        BlendMode.srcIn,
      ),
      width: width,
      height: height,
    );

    if (!rainbowAccent || color != null) return svg;

    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: rainbowColors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: svg,
    );
  }
}
