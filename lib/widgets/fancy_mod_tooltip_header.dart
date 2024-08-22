import 'package:flutter/material.dart';
import 'package:trios/widgets/palette_generator_mixin.dart';

import '../themes/theme_manager.dart';

class ModTooltipFancyTitleHeader extends StatefulWidget {
  const ModTooltipFancyTitleHeader({
    super.key,
    required this.iconPath,
    required this.child,
  });

  final String? iconPath;
  final Widget child;

  @override
  State<ModTooltipFancyTitleHeader> createState() =>
      _ModTooltipFancyTitleHeaderState();
}

class _ModTooltipFancyTitleHeaderState extends State<ModTooltipFancyTitleHeader>
    with PaletteGeneratorMixin {
  @override
  String? getIconPath() => widget.iconPath;

  @override
  Widget build(BuildContext context) {
    final paletteTheme = paletteGenerator.createPaletteTheme(context);

    return Theme(
      data: paletteTheme,
      child: Container(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: paletteTheme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(ThemeManager.cornerRadius),
              topRight: Radius.circular(ThemeManager.cornerRadius),
            ),
            border: Border(
              top: BorderSide(
                color: paletteTheme.colorScheme.onSurface.withOpacity(0.15),
                width: 1,
              ),
              left: BorderSide(
                color: paletteTheme.colorScheme.onSurface.withOpacity(0.15),
                width: 1,
              ),
              bottom: BorderSide(
                color: paletteTheme.colorScheme.onSurface.withOpacity(0.15),
                width: 1,
              ),
            ),
          ),
          child: widget.child),
    );
  }
}
