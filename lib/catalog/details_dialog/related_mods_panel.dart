import 'package:material_ui/material_ui.dart';
import 'package:trios/catalog/details_dialog/details_header.dart';
import 'package:trios/catalog/details_dialog/details_panel_section.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/summary_resolver.dart';
import 'package:trios/widgets/text_trios.dart';

/// A side panel listing other catalog mods, each opening that mod in the
/// dialog. Used for More by author and Similar mods.
class RelatedModsPanel extends StatelessWidget {
  final String title;
  final List<CatalogMod> mods;
  final void Function(CatalogMod mod) onOpenMod;

  const RelatedModsPanel({
    super.key,
    required this.title,
    required this.mods,
    required this.onOpenMod,
  });

  @override
  Widget build(BuildContext context) {
    return SidePanelSection(
      title: title,
      children: [
        for (final mod in mods)
          _RelatedModRow(mod: mod, onTap: () => onOpenMod(mod)),
      ],
    );
  }
}

class _RelatedModRow extends StatelessWidget {
  final CatalogMod mod;
  final VoidCallback onTap;

  const _RelatedModRow({required this.mod, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameVersion = mod.entry.gameVersionReq?.trim();
    // Only the author's own text: AI text would need the AI settings checked.
    final subtitle =
        resolveAuthorText(mod, authorOrder: AuthorTextOrder.shortFirst)?.text ??
        (mod.authors.isNotEmpty ? 'by ${mod.authors}' : null);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const .symmetric(vertical: 4),
        child: Row(
          spacing: 8,
          children: [
            ModPicture(mod: mod, size: 40),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: 2,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: TextTriOS(
                          mod.extras?.displayName ?? mod.title,
                          maxLines: 1,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (gameVersion != null && gameVersion.isNotEmpty)
                        Text(
                          gameVersion,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: detailsMutedColor(theme),
                          ),
                        ),
                    ],
                  ),
                  if (subtitle != null)
                    TextTriOS(
                      subtitle,
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: detailsMutedColor(theme),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
