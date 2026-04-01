import 'package:flutter/material.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/svg_image_icon.dart';

class ModTypeIcon extends StatelessWidget {
  const ModTypeIcon({super.key, required this.modVariant});

  final ModVariant modVariant;

  @override
  Widget build(BuildContext context) {
    return modVariant.modInfo.isTotalConversion || modVariant.modInfo.isUtility
        ? MovingTooltipWidget.text(
            message: getTooltipText(modVariant),
            child: Opacity(
              opacity: 0.7,
              child: SizedBox(
                width: 24,
                height: 24,
                child: modVariant.modInfo.isTotalConversion
                    ? const SvgImageIcon("assets/images/icon-death-star.svg")
                    : modVariant.modInfo.isUtility
                    ? const SvgImageIcon("assets/images/icon-utility-mod.svg")
                    : Container(),
              ),
            ),
          )
        : Container();
  }

  static String getTooltipText(ModVariant modVariant) {
    return modVariant.modInfo.isTotalConversion
        ? "Total Conversion mods should not be run with other mods unless explicitly stated to be compatible."
        : modVariant.modInfo.isUtility
        ? "This mod declares that it may be added to or removed from a save at will."
        : "";
  }
}
