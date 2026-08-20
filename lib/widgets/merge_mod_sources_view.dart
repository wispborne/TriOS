import 'package:material_ui/material_ui.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Renders mod-attribution lines for the ship and weapon details dialogs.
///
/// Shows a plain "Mod: X" line when one mod supplies everything. When mods
/// overlap, splits into "Stats" and "[fileLabel]" lines with hover breakdowns.
Widget mergeModSourcesView(
  ItemModSources? modSources,
  ThemeData theme, {
  required String fileLabel,
  required String fallbackName,
}) {
  final sources = modSources;
  if (sources == null) return _line(theme, 'Mod', fallbackName);

  final otherFileMods = sources.fileSources
      .where((s) => !s.isWinner && !s.isVanilla)
      .toList();
  final fileWinner = sources.fileWinner;
  final winnersDiffer =
      sources.hasStatsRow &&
      fileWinner != null &&
      fileWinner != sources.statsWinner;
  final isRich =
      sources.statsIgnored.isNotEmpty ||
      otherFileMods.isNotEmpty ||
      winnersDiffer;

  if (!isRich) {
    final name = sources.hasStatsRow
        ? sources.statsWinner
        : (fileWinner ?? fallbackName);
    // Match the old line: no "Mod:" prefix for the game core.
    return _line(theme, name == kVanillaSourceName ? null : 'Mod', name);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (sources.hasStatsRow)
        _line(
          theme,
          'Stats',
          sources.statsWinner,
          suffix: sources.statsIgnored.isEmpty
              ? null
              : '(+${sources.statsIgnored.length} ignored)',
          tooltip: sources.statsIgnored.isEmpty ? null : _statsTooltip(sources),
        ),
      if (fileWinner != null)
        _line(
          theme,
          fileLabel,
          fileWinner,
          suffix: otherFileMods.isEmpty
              ? null
              : '(+${otherFileMods.length} other '
                    'mod${otherFileMods.length == 1 ? '' : 's'})',
          tooltip: otherFileMods.isEmpty
              ? null
              : _fileTooltip(sources, fileLabel),
        ),
    ],
  );
}

Widget _line(
  ThemeData theme,
  String? label,
  String name, {
  String? suffix,
  String? tooltip,
}) {
  final children = <InlineSpan>[
    if (label != null) TextSpan(text: '$label: '),
    TextSpan(
      text: name.isEmpty ? '-' : name,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ];
  if (suffix != null) {
    final suffixText = Text(
      ' $suffix',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationStyle: TextDecorationStyle.dotted,
      ),
    );
    children.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: tooltip == null
            ? suffixText
            : MovingTooltipWidget.text(
                message: tooltip,
                maxWidth: 320,
                child: suffixText,
              ),
      ),
    );
  }
  return Padding(
    padding: const .symmetric(vertical: 2),
    child: Text.rich(
      TextSpan(style: theme.textTheme.bodySmall, children: children),
    ),
  );
}

String _statsTooltip(ItemModSources sources) =>
    "Only ${sources.statsWinner}'s stats are used.\n"
    'Overridden (no effect): ${sources.statsIgnored.join(', ')}';

String _fileTooltip(ItemModSources sources, String fileLabel) {
  final buffer = StringBuffer('$fileLabel — what each mod changes');
  for (final s in sources.fileSources) {
    buffer.write('\n\n${s.sourceName}');
    if (s.isWinner) {
      buffer.write('  (used for most)');
    } else if (s.isVanilla) {
      buffer.write('  (base)');
    }
    if (s.areas.isNotEmpty) {
      final shown = s.areas.take(5).join(' · ');
      final more = s.areas.length > 5 ? ' · …' : '';
      buffer.write('\n  $shown$more');
    }
  }
  return buffer.toString();
}
