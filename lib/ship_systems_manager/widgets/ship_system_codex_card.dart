import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/descriptions/description_entry.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/widgets/description_with_substitutions.dart';
import 'package:trios/widgets/ingame_tooltip_shared.dart';

/// Small in-game-style card for a ship system, following the pattern of
/// [HullmodCodexCard]. Shows the name, a handful of stats, and the description
/// looked up the same way the ship card does its system text.
class ShipSystemCodexCard {
  ShipSystemCodexCard._();

  static Widget create({required ShipSystem system}) {
    return Consumer(
      builder: (context, ref, _) => _buildContent(
        system,
        context,
        description: ref.watch(
          descriptionProvider((system.id, DescriptionEntry.typeShipSystem)),
        ),
      ),
    );
  }

  static Widget _buildContent(
    ShipSystem system,
    BuildContext context, {
    DescriptionEntry? description,
  }) {
    final theme = Theme.of(context);
    final highlightColor = TriOSThemeConstants.vanillaCyanColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tooltipTitle(system.name ?? system.id, theme),
        if ((description?.text2 ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              description!.text2!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 8),

        tooltipSectionHeader('System data', theme, highlightColor),
        const SizedBox(height: 4),
        _spriteRow(
          sprite: _systemSprite(system),
          child: tooltipStatsGrid(theme, [
            if (system.fluxUse != null)
              tooltipRow('Flux per use', tooltipFmt(system.fluxUse)),
            if (system.fluxPerSecond != null)
              tooltipRow('Flux per second', tooltipFmt(system.fluxPerSecond)),
            if (system.maxUses != null)
              tooltipRow('Max uses', tooltipFmt(system.maxUses)),
            if (system.regen != null)
              tooltipRow('Regen', tooltipFmt(system.regen)),
            if (system.cooldown != null)
              tooltipRow('Cooldown', tooltipFmt(system.cooldown)),
            if (system.toggle == true) tooltipRow('Type', 'Toggle'),
            if (system.isPhaseCloak == true)
              tooltipRow('Phase cloak', 'Yes'),
          ]),
        ),
        if (system.modVariant != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Mod: ${system.modVariant?.modInfo.nameOrId ?? "Vanilla"}',
              style: theme.textTheme.bodySmall,
            ),
          ),

        if ((description?.text1 ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          tooltipSectionHeader('Description', theme, highlightColor),
          const SizedBox(height: 4),
          DescriptionWithSubstitutions(
            description: description!.text1!,
            baseStyle: theme.textTheme.bodySmall,
            highlightColor: highlightColor,
          ),
        ],
      ],
    );
  }
}

Widget _spriteRow({required Widget? sprite, required Widget child}) {
  if (sprite == null) return child;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [sprite, Expanded(child: child)],
  );
}

Widget? _systemSprite(ShipSystem system) {
  final icon = system.icon;
  if (icon == null || icon.isEmpty) return null;
  // The manager resolves `icon` to an absolute path. Only show it when the file
  // actually exists (e.g. a mod referencing a vanilla icon won't have it here).
  final file = File(icon);
  return FutureBuilder<bool>(
    future: file.exists(),
    builder: (context, snap) {
      if (snap.data != true) return const SizedBox.shrink();
      return Image.file(file, width: 40, height: 40, fit: BoxFit.scaleDown);
    },
  );
}
