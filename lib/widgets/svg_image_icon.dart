import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SvgImageIcon extends StatelessWidget {
  final String assetName;
  final double? width;
  final double? height;
  final Color? color;

  const SvgImageIcon(this.assetName, {super.key, this.width, this.height, this.color});

  @override
  Widget build(BuildContext context) {
    var iconThemeData = IconTheme.of(context);
    return Opacity(
      opacity: iconThemeData.opacity ?? 1,
      child: SvgPicture.asset(assetName, width: width, height: height, color: color ?? iconThemeData.color),
    );
  }
}
