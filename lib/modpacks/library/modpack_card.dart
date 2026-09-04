import 'package:material_ui/material_ui.dart';
import 'package:trios/modpacks/library/modpack_card_data.dart';
import 'package:trios/widgets/dense_button.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/overflow_menu_button.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';
import 'package:trios/widgets/text_trios.dart';

/// One pack in the library grid.
///
/// Clicking the card opens it. Everything else is in the overflow menu,
/// except that a running installation shows its progress and a Stop button
/// on the card itself.
class ModpackCard extends StatelessWidget {
  final ModpackCardData card;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  /// Null for a pack that was never saved; there's nothing to copy yet.
  final VoidCallback? onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback? onStopInstallation;

  const ModpackCard({
    super.key,
    required this.card,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    this.onDuplicate,
    this.onStopInstallation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return MovingTooltipWidget.framed(
      tooltipWidgetBuilder: _buildHoverDetails,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: .zero,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const .fromLTRB(12, 8, 4, 12),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  crossAxisAlignment: .center,
                  children: [
                    Expanded(
                      child: TextTriOS(
                        card.name.isEmpty ? '(Unnamed modpack)' : card.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontStyle: card.name.isEmpty ? .italic : null,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    OverflowMenuButton(
                      tooltip: 'More actions',
                      iconSize: 20,
                      menuItems: _buildMenuItems(),
                    ),
                  ],
                ),
                Padding(
                  padding: const .only(right: 8),
                  child: TextTriOS(_subtitle(), style: mutedStyle, maxLines: 1),
                ),
                if (card.labels.isNotEmpty)
                  Padding(
                    padding: const .only(top: 8, right: 8),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final label in card.labels)
                          _CardLabel(label: label),
                      ],
                    ),
                  ),
                Expanded(
                  child: card.description == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const .only(top: 8, right: 8),
                          child: Text(
                            card.description!,
                            maxLines: 2,
                            overflow: .ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                ),
                Padding(
                  padding: const .only(right: 8),
                  child: card.isInstalling
                      ? _buildInstallingBlock(theme, mutedStyle)
                      : _buildInstalledBlock(theme, mutedStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "by Author · v3 · Starsector 0.98a-RC8", leaving out whatever's blank.
  String _subtitle() {
    final parts = [
      if (card.author != null) 'by ${card.author}',
      if (card.packVersion != null) 'v${card.packVersion}',
      if (card.gameVersion != null) 'Starsector ${card.gameVersion}',
    ];
    return parts.isEmpty ? ' ' : parts.join(' · ');
  }

  Widget _buildInstalledBlock(ThemeData theme, TextStyle? mutedStyle) {
    final total = card.totalCount;
    final text = total == 0
        ? 'No mods yet'
        : '${card.installedCount} of $total mods installed';

    return Column(
      crossAxisAlignment: .start,
      spacing: 4,
      children: [
        Text(text, style: mutedStyle),
        ThemedLinearProgressIndicator(
          value: total == 0 ? 0 : card.installedCount / total,
          minHeight: 4,
          color: card.isFullyInstalled
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.6),
          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ],
    );
  }

  Widget _buildInstallingBlock(ThemeData theme, TextStyle? mutedStyle) {
    final progress = card.installProgress!;
    return Column(
      crossAxisAlignment: .start,
      spacing: 4,
      children: [
        Text(
          'Installing ${progress.finishedCount} of ${progress.totalCount}',
          style: mutedStyle,
        ),
        ThemedLinearProgressIndicator(value: progress.fraction, minHeight: 4),
        Align(
          alignment: .centerRight,
          child: DenseButton(
            density: DenseButtonStyle.extraCompact,
            child: OutlinedButton.icon(
              onPressed: onStopInstallation,
              icon: const Icon(Icons.stop, size: 16),
              label: const Text('Stop'),
            ),
          ),
        ),
      ],
    );
  }

  List<PopupMenuEntry<int>> _buildMenuItems() {
    final items = [
      if (!card.isDraftOnly)
        OverflowMenuItem(title: 'Open', icon: Icons.visibility, onTap: onOpen),
      OverflowMenuItem(title: 'Edit', icon: Icons.edit, onTap: onEdit),
      if (onDuplicate != null)
        OverflowMenuItem(
          title: 'Duplicate',
          icon: Icons.copy,
          onTap: onDuplicate!,
        ),
      OverflowMenuItem(title: 'Delete', icon: Icons.delete, onTap: onDelete),
    ];
    return [for (var i = 0; i < items.length; i++) items[i].toEntry(i)];
  }

  Widget _buildHoverDetails(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final valueStyle = theme.textTheme.bodySmall;

    Widget line(String label, String value) => Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label: ', style: labelStyle),
          TextSpan(text: value, style: valueStyle),
        ],
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        spacing: 4,
        children: [
          Text(
            card.name.isEmpty ? '(Unnamed modpack)' : card.name,
            style: theme.textTheme.titleSmall,
          ),
          if (card.description != null)
            Text(card.description!, style: valueStyle),
          if (card.homepageUrl != null) line('Homepage', card.homepageUrl!),
          if (card.updateUrl != null) line('Update URL', card.updateUrl!),
          line(
            'Mods',
            '${card.installedCount} installed, ${card.missingCount} missing, '
                '${card.totalCount} in the pack',
          ),
        ],
      ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  final ModpackCardLabel label;

  const _CardLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (label) {
      ModpackCardLabel.draft => scheme.onSurfaceVariant,
      ModpackCardLabel.unsavedChanges => scheme.secondary,
      ModpackCardLabel.updateAvailable => scheme.primary,
      ModpackCardLabel.failed => scheme.error,
      ModpackCardLabel.installing => scheme.primary,
    };

    return Container(
      padding: const .symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
