import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:trios/catalog/widgets/mod_summary/mod_summary_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/settings_group.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';

/// The date format the details dialog uses, e.g. "March 1, 2026".
final DateFormat detailsDateFormat = DateFormat.yMMMMd();

/// The color the dialog uses for labels and secondary text. Brighter than
/// `onSurfaceVariant`, which is hard to read on the dialog's lighter
/// background at small sizes.
Color detailsMutedColor(ThemeData theme) =>
    theme.colorScheme.onSurface.withValues(alpha: 0.7);

/// One panel in the details dialog's side column. Uses the same heading as
/// the settings page and the dashboard.
class SidePanelSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SidePanelSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      name: title,
      padding: 12,
      // The side column is narrow, so the contents line up with the heading.
      contentIndent: 0,
      children: [
        Column(
          crossAxisAlignment: .stretch,
          mainAxisSize: .min,
          spacing: 12,
          children: children,
        ),
      ],
    );
  }
}

/// A label on the left and its value on the right, for the side panels.
class SidePanelRow extends StatelessWidget {
  final String label;
  final Widget value;

  const SidePanelRow({super.key, required this.label, required this.value});

  /// A row whose value is plain text.
  factory SidePanelRow.text(String label, String value) => SidePanelRow(
    label: label,
    value: Text(value, textAlign: TextAlign.end),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: detailsMutedColor(theme),
    );
    return DefaultTextStyle.merge(
      style: theme.textTheme.bodySmall,
      child: Row(
        crossAxisAlignment: .center,
        spacing: 16,
        children: [
          Text(label, style: labelStyle),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
  }
}

/// A small muted label above a group of chips, e.g. "Requires".
class SidePanelLabel extends StatelessWidget {
  final String text;

  const SidePanelLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: detailsMutedColor(theme),
      ),
    );
  }
}

/// A chip for categories, answers and mods. Set up the same way as
/// [DisplayChip], with a few extras.
///
/// [color] tints the chip, e.g. green for "Yes". With [onTap] the chip can be
/// clicked. [faded] draws it disabled, for something that can't be opened.
class DetailsTag extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  /// Shown before the label in place of [icon], e.g. a mod's own icon.
  final Widget? avatar;

  /// Shown after the label, e.g. a check mark or an Install button.
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool faded;

  const DetailsTag({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.avatar,
    this.trailing,
    this.onTap,
    this.tooltip,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color;
    Widget chip = RawChip(
      avatar:
          avatar ?? (icon == null ? null : Icon(icon, size: 16, color: tint)),
      label: Row(
        mainAxisSize: .min,
        spacing: 4,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ?trailing,
        ],
      ),
      labelStyle: theme.textTheme.labelMedium?.copyWith(color: tint),
      // Plain chips use the same fill as the cards in the tab area and the
      // donation chips on the catalog card.
      color: WidgetStatePropertyAll(
        tint?.withValues(alpha: 0.15) ?? theme.colorScheme.surfaceContainerLow,
      ),
      side: BorderSide(
        color:
            tint?.withValues(alpha: 0.5) ??
            theme.colorScheme.onSurface.withValues(alpha: 0.12),
      ),
      isEnabled: !faded,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    if (tooltip != null) {
      chip = MovingTooltipWidget.text(message: tooltip!, child: chip);
    }
    return chip;
  }
}

/// A link in a side panel: an icon and a label. Opens [onTap] on click.
class SidePanelLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Shown on hover, usually the address.
  final String? tooltip;

  const SidePanelLink({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final link = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const .symmetric(vertical: 4),
        child: Row(
          spacing: 8,
          children: [
            Icon(icon, size: 16, color: detailsMutedColor(theme)),
            Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
    if (tooltip == null) return link;
    return MovingTooltipWidget.text(message: tooltip!, child: link);
  }
}

/// A folding panel in the dialog's tab area, with the same heading as the
/// card's hover summary. Starts open.
class ContentSection extends StatelessWidget {
  final IconData? icon;

  /// An SVG icon from the app's assets, used in place of [icon].
  final String? iconAsset;
  final String title;
  final Widget child;

  const ContentSection({
    super.key,
    this.icon,
    this.iconAsset,
    required this.title,
    required this.child,
  }) : assert(icon != null || iconAsset != null);

  @override
  Widget build(BuildContext context) {
    return TriOSExpansionTile(
      initiallyExpanded: true,
      title: SummarySectionHeader(
        icon: icon,
        iconAsset: iconAsset,
        label: title,
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      childrenPadding: const .fromLTRB(16, 0, 16, 16),
      children: [child],
    );
  }
}
