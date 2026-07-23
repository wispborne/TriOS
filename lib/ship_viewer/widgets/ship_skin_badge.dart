import 'package:flutter/material.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Small "Skin" tag shown next to a ship's name when it came from a `.skin`
/// file. Used on the Ships page grid and in the Codex list.
class ShipSkinBadge extends StatelessWidget {
  const ShipSkinBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const .symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: MovingTooltipWidget.text(
        message:
            "This ship comes from a .skin file."
            "\nSkins are variations of standard hulls. For example, the Falcon (P) is a skin of the Falcon.",
        child: Text(
          'Skin',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
