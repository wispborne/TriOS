import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TriOSAppIcon extends StatelessWidget {
  final double width;
  final double height;

  const TriOSAppIcon({super.key, this.width = 48, this.height = 48});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(("assets/images/telos_faction_crest.svg"),
        colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
        width: width,
        height: height);
  }
}
