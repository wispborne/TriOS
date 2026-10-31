import 'package:material_ui/material_ui.dart';

/// The Catalog search rules, shown by the search box's info button.
class CatalogSearchHelp extends StatelessWidget {
  const CatalogSearchHelp({super.key});

  /// Each rule's name and its text. Text in backticks is shown as code.
  static const _rules = [
    ['Words', 'every word must match, in any order: `battlestar portrait`'],
    ['Exact phrase', 'in quotes: `"unknown contact"`'],
    ['OR', 'comma-separated: `faction, portrait` matches either term'],
    [
      'Exclude',
      'prefix with `-` to hide results, e.g. `pirate -junk` or '
          '`faction, -portrait`',
    ],
    ['Abbreviations', 'e.g. `swp`, `kol` or `indevo` work'],
    ['Versions', 'e.g. `0.98` matches mods for that release'],
    [
      'Field search',
      '`key:value` syntax, e.g. `author:Wisp`, `category:weapons`, '
          '`version:0.97`, `from:discord`',
    ],
    [
      'Has / is',
      '`has:source`, `has:download`, `is:addable`, `is:wip`, `is:tool`, '
          '`has:ai`, `is:noai`; add `-` to exclude: `-is:wip`',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final codeStyle = TextStyle(
      fontFamily: 'monospace',
      color: theme.colorScheme.primary,
    );

    return SelectionArea(
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        spacing: 8,
        children: [
          Text(
            'Searches mod names and nicknames, authors, categories, versions, '
            'summaries, descriptions and links.',
            style: theme.textTheme.bodyMedium,
          ),
          for (final [name, text] in _rules)
            Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' — '),
                  ..._withCode(text, codeStyle),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// [text] split at backticks, with every second part shown as code.
  static List<TextSpan> _withCode(String text, TextStyle codeStyle) {
    final parts = text.split('`');
    return [
      for (var i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty)
          TextSpan(text: parts[i], style: i.isOdd ? codeStyle : null),
    ];
  }
}
