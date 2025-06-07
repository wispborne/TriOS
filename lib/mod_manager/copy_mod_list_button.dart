import 'package:flutter/material.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/widgets/moving_tooltip.dart';

class CopyModListButtonLarge extends StatelessWidget {
  const CopyModListButtonLarge({
    super.key,
    required this.mods,
    required this.enabledMods,
  });

  final List<Mod> mods;
  final List<Mod> enabledMods;

  @override
  Widget build(BuildContext context) {
    return MovingTooltipWidget.text(
      message: "Copy mod list to clipboard\n\nRight-click for ALL mods",
      child: Padding(
        padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
        child: GestureDetector(
          onSecondaryTap: () {
            copyModListToClipboardFromMods(mods, context);
          },
          child: OutlinedButton.icon(
            onPressed: () =>
                copyModListToClipboardFromMods(enabledMods, context),
            label: const Text("Copy"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.8),
              side: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            icon: const Icon(Icons.copy, size: 20),
          ),
        ),
      ),
    );
  }
}
