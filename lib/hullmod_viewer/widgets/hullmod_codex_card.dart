import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/codex/widgets/codex_reference_link.dart';
import 'package:trios/descriptions/description_entry.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/viewer_cache/graphics_index_manager.dart';
import 'package:trios/widgets/description_with_substitutions.dart';
import 'package:trios/widgets/ingame_tooltip_shared.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Builds tooltip content for hullmods, following the same pattern as
/// [ShipCodexCard] and [WeaponCodexCard].
class HullmodCodexCard {
  HullmodCodexCard._();

  static const _maxWidth = 300.0;

  /// Wraps [child] in a [MovingTooltipWidget] that shows hullmod stats on hover.
  ///
  /// When [onEntitySelected] is set (inside the Codex), the child also becomes
  /// clickable and a tap navigates to this hullmod. Null everywhere else, so the
  /// viewer tabs keep their hover-only behaviour.
  static Widget tooltip({
    required Hullmod hullmod,
    required Widget child,
    bool showTitle = true,
    bool showSprite = true,
    bool showDescription = true,
    CodexEntitySelected? onEntitySelected,
  }) {
    return MovingTooltipWidget.starsector(
      tooltipWidgetBuilder: (_) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: SingleChildScrollView(
          child: Consumer(
            builder: (context, ref, _) => _buildHullmodContent(
              hullmod,
              context,
              description: ref.watch(
                descriptionProvider((hullmod.id, DescriptionEntry.typeHullMod)),
              ),
              spritePath: ref
                  .watch(gameFileResolverProvider(false))
                  .resolve(hullmod.sprite),
              showTitle: showTitle,
              showSprite: showSprite,
              showDescription: showDescription,
            ),
          ),
        ),
      ),
      child: asCodexLink(
        child,
        onEntitySelected,
        (CodexEntryType.hullmod, hullmod.id),
      ),
    );
  }

  static Widget create({
    required Hullmod hullmod,
    bool showTitle = true,
    bool showSprite = true,
    bool showDescription = true,
  }) {
    return Consumer(
      builder: (context, ref, _) => _buildHullmodContent(
        hullmod,
        context,
        description: ref.watch(
          descriptionProvider((hullmod.id, DescriptionEntry.typeHullMod)),
        ),
        spritePath: ref.watch(gameFileResolverProvider(false)).resolve(hullmod.sprite),
        showTitle: showTitle,
        showSprite: showSprite,
        showDescription: showDescription,
      ),
    );
  }

  static Widget _buildHullmodContent(
    Hullmod hullmod,
    BuildContext context, {
    DescriptionEntry? description,

    /// The hullmod's icon, already matched to a real file. Null when no mod
    /// and not the game core has it.
    String? spritePath,
    bool showTitle = true,
    bool showSprite = true,
    bool showDescription = true,
  }) {
    final theme = Theme.of(context);
    final highlightColor = TriOSThemeConstants.vanillaCyanColor;

    final hasSmodBonus = (hullmod.sModDesc ?? '').isNotEmpty;
    final hasSmodPlaceholder = hullmod.sModDesc?.contains(
      Constants.substitutionPlaceholder,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Title & tech/manufacturer ──
        if (showTitle) ...[
          tooltipTitleWithDesignType(
            hullmod.name ?? hullmod.id,
            hullmod.techManufacturer,
            true,
            theme,
          ),
          if ((hullmod.shortDescription ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                hullmod.shortDescription!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],

        // ── Hullmod data section ──
        tooltipSectionHeader('Hullmod data', theme, highlightColor),
        const SizedBox(height: 4),
        _spriteRow(
          sprite: showSprite && spritePath != null
              ? _HullmodSpriteImage(spritePath: spritePath, size: 40)
              : null,
          child: tooltipStatsGrid(theme, [
            if (hullmod.costFrigate != null)
              tooltipRow('OP cost (Frigate)', tooltipFmt(hullmod.costFrigate)),
            if (hullmod.costDest != null)
              tooltipRow('OP cost (Destroyer)', tooltipFmt(hullmod.costDest)),
            if (hullmod.costCruiser != null)
              tooltipRow('OP cost (Cruiser)', tooltipFmt(hullmod.costCruiser)),
            if (hullmod.costCapital != null)
              tooltipRow('OP cost (Capital)', tooltipFmt(hullmod.costCapital)),
            if (hullmod.costFrigate == null &&
                hullmod.costDest == null &&
                hullmod.costCruiser == null &&
                hullmod.costCapital == null)
              tooltipRow('OP cost', '-'),
          ]),
        ),
        if ((hullmod.uiTags ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Tags: ${hullmod.uiTags}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (hullmod.modVariant != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Mod: ${hullmod.modVariant?.modInfo.nameOrId ?? "Vanilla"}',
              style: theme.textTheme.bodySmall,
            ),
          ),

        // ── Description ──
        if (showDescription) ...[
          if ((hullmod.desc ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            tooltipSectionHeader('Description', theme, highlightColor),
            const SizedBox(height: 4),
            DescriptionWithSubstitutions(
              description: hullmod.desc!,
              baseStyle: theme.textTheme.bodySmall,
              highlightColor: highlightColor,
              showPlaceholderHintText: hasSmodPlaceholder != true,
            ),
          ],
          if (description?.text1 != null) ...[
            const SizedBox(height: 8),
            tooltipHairline(theme),
            const SizedBox(height: 4),
            DescriptionWithSubstitutions(
              description: description!.text1!,
              baseStyle: theme.textTheme.bodySmall,
            ),
          ],
        ],

        // ── S-Mod bonus ──
        if (hasSmodBonus) ...[
          const SizedBox(height: 8),
          tooltipSectionHeader('S-Mod bonus', theme, highlightColor),
          const SizedBox(height: 4),
          DescriptionWithSubstitutions(
            description: hullmod.sModDesc!,
            baseStyle: theme.textTheme.bodySmall?.copyWith(
              color: TriOSThemeConstants.vanillaYellowGoldColor,
            ),
            highlightColor: highlightColor,
            showPlaceholderHintText: true,
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
    children: [
      sprite,
      Expanded(child: child),
    ],
  );
}

/// Draws a hullmod icon. The path has already been matched to a real file, so
/// there's nothing to check first.
class _HullmodSpriteImage extends StatelessWidget {
  final String spritePath;
  final double size;

  const _HullmodSpriteImage({required this.spritePath, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return MovingTooltipWidget.image(
      path: spritePath,
      child: Image.file(
        File(spritePath),
        width: size,
        height: size,
        fit: BoxFit.scaleDown,
      ),
    );
  }
}
