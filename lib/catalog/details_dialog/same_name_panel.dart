import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/catalog/details_dialog/details_panel_section.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/trios/constants_theme.dart';
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
    final mutedStyle = theme.textTheme.labelSmall?.copyWith(
      color: detailsMutedColor(theme),
    );

    // Drawn like the dashboard's warnings: a folding tile with a warning icon.
    return Padding(
      padding: const .fromLTRB(16, 8, 16, 0),
      child: TriOSExpansionTile(
        initiallyExpanded: true,
        leading: Icon(
          Icons.warning_amber_rounded,
          color: TriOSThemeConstants.vanillaWarningColor,
        ),
        title: const Text('Other mods have the same name'),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: const .fromLTRB(16, 0, 16, 8),
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
                  ?other.gameVersion,
                  if (other.modVersion case final version?) 'v$version',
                ].join(' · ');

                return InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const .symmetric(vertical: 2, horizontal: 40),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: other.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: onTap != null
                                  ? TextDecoration.underline
                                  : null,
                            ),
                          ),
                          if (facts.isNotEmpty)
                            TextSpan(text: '   $facts', style: mutedStyle),
                        ],
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
