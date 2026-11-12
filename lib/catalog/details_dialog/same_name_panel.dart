import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/catalog/details_dialog/details_panel_section.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/widgets/text_link_button.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';

/// The warning under the header when other mods share this mod's name. Each
/// row opens that mod in the dialog, or its forum thread when it isn't in the
/// catalog.
class SameNamePanel extends StatelessWidget {
  final List<CatalogSameNameMod> sameNameMods;

  /// Every catalog mod, for finding each row's mod by its catalog id.
  final List<CatalogMod> allMods;
  final void Function(CatalogMod mod) onOpenMod;
  final void Function(String url) linkLoader;

  const SameNamePanel({
    super.key,
    required this.sameNameMods,
    required this.allMods,
    required this.onOpenMod,
    required this.linkLoader,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: detailsMutedColor(theme),
    );
    final nameStyle = sidePanelLabelStyle(theme);

    // Drawn like the dashboard's warnings: a folding tile with a warning icon.
    return Padding(
      padding: const .fromLTRB(16, 16, 16, 8),
      child: TriOSExpansionTile(
        initiallyExpanded: true,
        leading: Icon(
          Icons.warning_amber_rounded,
          color: TriOSThemeConstants.vanillaWarningColor,
        ),
        title: const Text('Other mods have the same name'),
        subtitle: Text(
          'It may be an older thread for this mod, a fork of it, or a '
          'different mod.',
          style: mutedStyle,
        ),
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        // Lines the rows up with the title, past the warning icon.
        childrenPadding: const .fromLTRB(52, 0, 16, 16),
        children: [
          for (final other in sameNameMods)
            Builder(
              builder: (context) {
                final id = other.id;
                final catalogMod = id == null
                    ? null
                    : allMods.firstWhereOrNull((m) => m.entry.id == id);
                final url = other.url;
                final VoidCallback? onTap = catalogMod != null
                    ? () => onOpenMod(catalogMod)
                    : (url != null && url.isNotEmpty)
                    ? () => linkLoader(url)
                    : null;
                final facts = [
                  if (other.authors.isNotEmpty)
                    'by ${other.authors.join(', ')}',
                  if (other.threadLastPostOn case final date?)
                    'last post ${detailsDateFormat.format(date)}',
                  if (other.gameVersion case final gameVersion?)
                    'for Starsector $gameVersion',
                  if (other.modVersion case final version?) 'v$version',
                ].join(' · ');

                return Padding(
                  padding: const .only(top: 8),
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: 2,
                    children: [
                      onTap == null
                          ? Text(other.title, style: nameStyle)
                          : TextLinkButton(
                              text: other.title,
                              style: nameStyle,
                              onPressed: onTap,
                            ),
                      if (facts.isNotEmpty) Text(facts, style: mutedStyle),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
