import 'package:flutter/material.dart';
import 'package:trios/themes/theme_manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared visual utilities for ingame-style tooltips (ship, weapon, etc.)
// ─────────────────────────────────────────────────────────────────────────────

Widget tooltipTitle(String text, ThemeData theme) {
  return Text(
    text,
    style: theme.textTheme.titleMedium?.copyWith(
      color: ThemeManager.vanillaCyanColor,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.3,
    ),
  );
}

/// Title block with an optional "Design type:" subtitle beneath.
Widget tooltipTitleWithDesignType(
  String title,
  String? designType,
  bool showDesignTypeLabel,
  ThemeData theme,
) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      tooltipTitle(title, theme),
      if (designType != null)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              if (showDesignTypeLabel)
              Text(
                'Design type: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                ),
              ),
              Text(
                designType,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.80),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Standalone "Design type:" label–value row for use in footer sections.
Widget tooltipDesignTypeRow(String designType, ThemeData theme) {
  return Row(
    spacing: 6,
    children: [
      Text(
        'Design type:',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      Text(
        designType,
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    ],
  );
}

/// Gold-accented section header bar with a left border stripe.
Widget tooltipSectionHeader(
  String text,
  ThemeData theme,
  Color highlightColor,
) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
    decoration: BoxDecoration(
      color: highlightColor.withValues(alpha: 0.10),
    ),
    child: Center(
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: highlightColor,
          letterSpacing: 0.8,
        ),
      ),
    ),
  );
}

/// Thin 1 dp horizontal rule between sections.
Widget tooltipHairline(ThemeData theme) => Divider(
  height: 1,
  thickness: 1,
  color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
);

/// Builds a two-column stat grid from a list of [TooltipStatEntry] items.
///
/// Note entries (isNote=true) are rendered as full-width widgets outside any
/// [Table], since Flutter's Table has no colspan support. Regular and gap
/// entries are grouped into contiguous [Table] blocks.
Widget tooltipStatsGrid(ThemeData theme, List<TooltipStatEntry> entries) {
  final segments = <Widget>[];
  final tableBuffer = <TooltipStatEntry>[];

  void flushTable() {
    if (tableBuffer.isEmpty) return;
    segments.add(
      Table(
        columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
        defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: tableBuffer.map((e) => e.build(theme)).toList(),
      ),
    );
    tableBuffer.clear();
  }

  for (final entry in entries) {
    if (entry.isNote && entry.label.isEmpty) {
      flushTable();
      segments.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            entry.value,
            textAlign: entry.rightAlign ? TextAlign.right : null,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    } else {
      tableBuffer.add(entry);
    }
  }
  flushTable();

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: segments,
  );
}

/// A label–value stat row.
TooltipStatEntry tooltipRow(String label, String value, {Color? color}) =>
    TooltipStatEntry(label: label, value: value, valueColor: color);

/// A full-width informational note (empty label, dimmer italic text).
TooltipStatEntry tooltipNote(String text) =>
    TooltipStatEntry(label: '', value: text, isNote: true);

/// A right-aligned informational note (value column, dimmer italic text).
TooltipStatEntry tooltipNoteRight(String text) =>
    TooltipStatEntry(label: '', value: text, isNote: true, rightAlign: true);

/// An empty separator row.
const tooltipGap = TooltipStatEntry.gap();

/// Formats a number to match the game's display logic.
///
/// Integer-valued numbers render without decimals. Small fractional values
/// show 1–2 decimal places; large ones (|n| > 10) are rounded.
/// [forceDecimal] prevents the integer shortcut (used for ratios like
/// flux-per-damage).
String tooltipFmt(num? n, {bool forceDecimal = false}) {
  if (n == null) return '-';
  final v = n.toDouble();

  if (!forceDecimal && (v.roundToDouble() - v).abs() < 1e-4) {
    return v.round().toString();
  }

  if ((v * 100).round() == (v * 10).round() * 10) {
    return v.abs() > 10 ? v.round().toString() : v.toStringAsFixed(1);
  }

  return v.abs() > 10 ? v.round().toString() : v.toStringAsFixed(2);
}

// ─────────────────────────────────────────────────────────────────────────────

/// Lightweight descriptor for a single stat row or spacer in a [Table].
class TooltipStatEntry {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isNote;
  final bool rightAlign;
  final bool _isGap;

  const TooltipStatEntry({
    required this.label,
    required this.value,
    this.valueColor,
    this.isNote = false,
    this.rightAlign = false,
  }) : _isGap = false;

  const TooltipStatEntry.gap()
    : label = '',
      value = '',
      valueColor = null,
      isNote = false,
      rightAlign = false,
      _isGap = true;

  TableRow build(ThemeData theme) {
    if (_isGap) {
      return const TableRow(
        children: [SizedBox(height: 5), SizedBox(height: 5)],
      );
    }

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 1, bottom: 1),
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              color: valueColor ?? ThemeManager.vanillaYellowGoldColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
