import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:trios/catalog/widgets/mod_summary/mod_summary_widget.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/settings_group.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';

/// The date format the details dialog uses, e.g. "March 1, 2026".
final DateFormat detailsDateFormat = DateFormat.yMMMMd();

/// The color the dialog uses for secondary text. On the Starsector theme's
/// cards this is about 5.5 to 1, the same as Starmodder's grey text.
Color detailsMutedColor(ThemeData theme) =>
    theme.colorScheme.onSurface.withValues(alpha: 0.6);

/// One panel in the details dialog's side column: a card in the same color
/// as the cards in the tab area, with the same heading as the settings page
/// and the dashboard.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
      ),
      child: Padding(
        // With the heading's own left padding of 8, everything sits 16 in.
        padding: const .fromLTRB(8, 0, 16, 0),
        child: SettingsGroup(
          name: title,
          padding: 12,
          // The side column is narrow, so the contents line up with the
          // heading.
          contentIndent: 0,
          children: [
            Column(
              crossAxisAlignment: .stretch,
              mainAxisSize: .min,
              spacing: 12,
              children: children,
            ),
          ],
        ),
      ),
    );
  }
}

/// The bold label style of the side panels. The same as the Mods page's
/// side panel.
TextStyle? sidePanelLabelStyle(ThemeData theme) =>
    theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold);

/// The style for values in the side panels. The same as the Mods page's side
/// panel.
TextStyle? sidePanelValueStyle(ThemeData theme) => theme.textTheme.labelLarge
    ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.92));

/// [sidePanelValueStyle] in the monospace font the Mods page uses for ids and
/// versions.
TextStyle? sidePanelMonoStyle(ThemeData theme) =>
    sidePanelValueStyle(theme)
        ?.copyWith(fontFamily: GoogleFonts.sourceCodePro().fontFamily);

/// A label and its value on one line, e.g. "Added: March 1, 2026".
class SidePanelRow extends StatelessWidget {
  final String label;
  final Widget value;

  const SidePanelRow({super.key, required this.label, required this.value});

  /// A row whose value is plain text. [mono] shows it in the monospace font,
  /// for versions.
  factory SidePanelRow.text(String label, String value, {bool mono = false}) =>
      SidePanelRow(
        label: label,
        value: Builder(
          builder: (context) => Text(
            value,
            style: mono ? sidePanelMonoStyle(Theme.of(context)) : null,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A question reads better without a colon after it.
    final shownLabel = label.endsWith('?') ? label : '$label:';
    return Row(
      crossAxisAlignment: .start,
      spacing: 8,
      children: [
        Text(shownLabel, style: sidePanelLabelStyle(theme)),
        Flexible(
          child: DefaultTextStyle.merge(
            style: sidePanelValueStyle(theme),
            child: value,
          ),
        ),
      ],
    );
  }
}

/// A bold label above a list, e.g. "Requires".
class SidePanelLabel extends StatelessWidget {
  final String text;

  const SidePanelLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: sidePanelLabelStyle(Theme.of(context)));
}

/// A chip for a mod. Set up the same way as [DisplayChip], with a few
/// extras.
///
/// [color] tints the chip, e.g. the warning color for a conflict. With [onTap]
/// the chip can be clicked. [faded] draws it disabled, for something that
/// can't be opened.
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
            theme.colorScheme.onSurface.withValues(alpha: 0.2),
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

/// A link in a side panel: an outlined button with an icon in the accent
/// color, like the Forum Thread button on the Mods page.
class SidePanelLink extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;

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
    final link = OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
      icon: icon == null
          ? null
          : Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Text(label),
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
