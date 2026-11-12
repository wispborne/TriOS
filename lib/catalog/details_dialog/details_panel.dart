import 'package:material_ui/material_ui.dart';
import 'package:trios/catalog/ai_use_filter.dart';
import 'package:trios/catalog/details_dialog/details_panel_section.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// The Details panel: mod version, then [compatibility], then categories,
/// dates, and what the author says about AI use.
class DetailsPanel extends StatefulWidget {
  final CatalogMod mod;

  /// Shown after the mod version: the game version, required mods and so on.
  final Widget? compatibility;

  const DetailsPanel({super.key, required this.mod, this.compatibility});

  @override
  State<DetailsPanel> createState() => _DetailsPanelState();
}

class _DetailsPanelState extends State<DetailsPanel> {
  bool _showOriginalCategories = false;

  @override
  Widget build(BuildContext context) {
    final mod = widget.mod;
    final extras = mod.extras;
    final version = mod.entry.modVersion?.trim();
    final categories = mod.categories;
    final rawCategories = extras?.rawCategories ?? const <String>[];
    final hasOriginalCategories =
        rawCategories.isNotEmpty &&
        rawCategories.toSet().difference(categories.toSet()).isNotEmpty;

    final added = extras?.addedOn ?? mod.postDate;
    final edited = extras?.editedOn ?? mod.lastEditDate;
    final released = extras?.lastReleaseDate;
    final lastPost = mod.lastPostDate;

    String date(DateTime value) => detailsDateFormat.format(value);
    final theme = Theme.of(context);
    final linkColor = theme.colorScheme.primary;

    return SidePanelSection(
      title: 'Details',
      children: [
        if (version != null && version.isNotEmpty)
          SidePanelRow.text('Mod version', version, mono: true),
        ?widget.compatibility,
        if (categories.isNotEmpty)
          Column(
            crossAxisAlignment: .stretch,
            spacing: 4,
            children: [
              Row(
                children: [
                  const Expanded(child: SidePanelLabel('Category')),
                  // Switches the tags between the cleaned-up categories and
                  // the ones the mod was posted under.
                  if (hasOriginalCategories)
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => setState(
                        () =>
                            _showOriginalCategories = !_showOriginalCategories,
                      ),
                      child: Row(
                        mainAxisSize: .min,
                        spacing: 4,
                        children: [
                          if (_showOriginalCategories)
                            Icon(Icons.check, size: 14, color: linkColor),
                          Text(
                            'Original categories',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: linkColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Text(
                (_showOriginalCategories ? rawCategories : categories).join(
                  ', ',
                ),
                style: sidePanelValueStyle(theme),
              ),
            ],
          ),
        if (added != null) SidePanelRow.text('Added', date(added)),
        if (edited != null && edited != added)
          SidePanelRow.text('Last edited', date(edited)),
        if (released != null) SidePanelRow.text('Last release', date(released)),
        if (lastPost != null)
          SidePanelRow.text('Thread last posted', date(lastPost)),
        _AiUseRow(aiUse: mod.aiUse),
      ],
    );
  }
}

class _AiUseRow extends StatelessWidget {
  final CatalogAiUse? aiUse;

  const _AiUseRow({required this.aiUse});

  static final Map<String, String> _areaLabels = {
    for (final group in aiUseGroups)
      for (final area in group.areas) area.key: area.label,
  };

  static String _areaLabel(String key) => _areaLabels[key] ?? key.toTitleCase();

  /// The value shown in the row.
  static String _value(CatalogAiUse? aiUse) {
    if (aiUse == null) return 'Not checked yet';
    return switch (aiUse.usesAi) {
      null => 'Unknown',
      false => 'None',
      true => {
        for (final use in aiUse.uses ?? const <CatalogAiUseEntry>[])
          _areaLabel(use.area),
      }.join(', ').let((text) => text.isEmpty ? 'Yes' : text),
    };
  }

  /// The uses, tools and the author's own words, for the hover text.
  static String _details(CatalogAiUse aiUse) {
    final lines = <String>[
      for (final use in aiUse.uses ?? const <CatalogAiUseEntry>[])
        [
          _areaLabel(use.area),
          [
            ?use.how,
            ?use.extent,
            if (use.optional == true) 'optional',
          ].join(', '),
        ].where((part) => part.isNotEmpty).join(': '),
      if (aiUse.tools?.isNotEmpty ?? false) 'Tools: ${aiUse.tools!.join(', ')}',
      if (aiUse.quote?.trim().isNotEmpty ?? false) '"${aiUse.quote!.trim()}"',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final use = aiUse;
    final details = use == null ? '' : _details(use);
    final row = SidePanelRow.text('AI use', _value(use));
    if (details.isEmpty) return row;
    return MovingTooltipWidget.text(message: details, child: row);
  }
}
