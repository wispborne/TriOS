import 'package:material_ui/material_ui.dart';
import 'package:trios/catalog/details_dialog/details_panel_section.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/widgets/mod_summary/mod_summary_widget.dart';

/// True when [changelog] has entries or a link to show.
bool changelogHasContent(ForumLlmChangelog? changelog) {
  if (changelog == null) return false;
  final hasEntries = changelog.entries?.isNotEmpty ?? false;
  final hasLink = changelog.link?.trim().isNotEmpty ?? false;
  return hasEntries || hasLink;
}

/// The Updates tab: the author's changelog, then the release history from the
/// extras record, each in its own card.
class UpdatesTab extends StatelessWidget {
  final CatalogMod mod;

  const UpdatesTab({super.key, required this.mod});

  /// True when the tab has anything to show.
  static bool hasContent(CatalogMod mod) =>
      changelogHasContent(mod.changelog) ||
      (mod.extras?.releases.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final changelog = mod.changelog;
    final releases = mod.extras?.releases ?? const <CatalogRelease>[];

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        if (changelog != null && changelogHasContent(changelog))
          ContentSection(
            iconAsset: 'assets/images/icon-bullhorn-variant.svg',
            title: 'Recent updates',
            child: ChangelogSection(
              changelog: changelog,
              maxEntries: 20,
              interactive: true,
              showHeader: false,
            ),
          ),
        if (releases.isNotEmpty)
          ContentSection(
            icon: Icons.history,
            title: 'Release history',
            child: _ReleaseHistory(releases: releases),
          ),
      ],
    );
  }
}

class _ReleaseHistory extends StatelessWidget {
  final List<CatalogRelease> releases;

  const _ReleaseHistory({required this.releases});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.labelSmall?.copyWith(
      color: detailsMutedColor(theme),
    );

    return Column(
      crossAxisAlignment: .start,
      spacing: 16,
      children: [
        Text(
          'Releases are prone to error.',
          style: mutedStyle?.copyWith(fontStyle: FontStyle.italic),
        ),
        for (final release in releases)
          Column(
            crossAxisAlignment: .start,
            spacing: 4,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    release.oldVersion == null
                        ? release.newVersion
                        : '${release.newVersion} (was ${release.oldVersion})',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    detailsDateFormat.format(release.seenOn),
                    style: mutedStyle,
                  ),
                  if (release.gameVersion case final gameVersion?)
                    Text(gameVersion, style: mutedStyle),
                ],
              ),
              if (release.changelogNotes?.trim() case final notes?
                  when notes.isNotEmpty)
                SelectableText(notes, style: theme.textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}
