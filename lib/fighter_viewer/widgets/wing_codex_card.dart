import 'package:flutter/material.dart';
import 'package:trios/fighter_viewer/models/wing.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/ingame_tooltip_shared.dart';

/// Small in-game-style card for a fighter wing.
///
/// Wings have no entry in `descriptions.csv`, so there is no long description —
/// the `role desc` column and the link to the ship behind the wing are what
/// there is. Full combat stats come from that ship, not from the wing row.
class WingCodexCard {
  WingCodexCard._();

  /// [onShipTap] is called when the ship link is clicked. When null, or when
  /// the wing's hull did not resolve, the ship is shown as plain text (or
  /// omitted) rather than a link.
  ///
  /// [title] is the name shown at the top — the ship behind the wing. Falls
  /// back to the wing id when not given.
  static Widget create({
    required Wing wing,
    String? title,
    VoidCallback? onShipTap,
  }) {
    return Builder(
      builder: (context) =>
          _buildContent(wing, context, title: title, onShipTap: onShipTap),
    );
  }

  static Widget _buildContent(
    Wing wing,
    BuildContext context, {
    String? title,
    VoidCallback? onShipTap,
  }) {
    final theme = Theme.of(context);
    final highlightColor = TriOSThemeConstants.vanillaCyanColor;

    final roleTitle = wing.role?.toTitleCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tooltipTitle(title ?? wing.id, theme),
        if ((wing.roleDesc ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              wing.roleDesc!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 8),

        tooltipSectionHeader('Wing data', theme, highlightColor),
        const SizedBox(height: 4),
        tooltipStatsGrid(theme, [
          if (roleTitle != null) tooltipRow('Role', roleTitle),
          if (wing.fleetPts != null)
            tooltipRow('Fleet points', tooltipFmt(wing.fleetPts)),
          if (wing.opCost != null)
            tooltipRow('OP cost', tooltipFmt(wing.opCost)),
          if (wing.numCraft != null)
            tooltipRow('Number of craft', tooltipFmt(wing.numCraft)),
          if (wing.tier != null) tooltipRow('Tier', tooltipFmt(wing.tier)),
          if (wing.rarity != null)
            tooltipRow('Rarity', tooltipFmt(wing.rarity)),
          if (wing.refit != null)
            tooltipRow('Refit time', tooltipFmt(wing.refit)),
        ]),
        if (wing.modVariant != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Mod: ${wing.modVariant?.modInfo.nameOrId ?? "Vanilla"}',
              style: theme.textTheme.bodySmall,
            ),
          ),

        if (wing.hullId != null) ...[
          const SizedBox(height: 8),
          tooltipSectionHeader('Ship', theme, highlightColor),
          const SizedBox(height: 4),
          if (onShipTap != null)
            _InlineLink(text: wing.hullId!, onTap: onShipTap)
          else
            Text(wing.hullId!, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// Compact inline text link, sized for use inside a card (unlike the pill-style
/// [TextLinkButton]).
class _InlineLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _InlineLink({required this.text, required this.onTap});

  @override
  State<_InlineLink> createState() => _InlineLinkState();
}

class _InlineLinkState extends State<_InlineLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            decoration: _hovered ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }
}
