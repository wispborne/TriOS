import 'package:material_ui/material_ui.dart';
import 'package:trios/catalog/catalog_mod_card.dart';
import 'package:trios/catalog/details_dialog/details_panel_section.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/catalog/widgets/mod_summary/mod_summary_widget.dart';
import 'package:trios/utils/extensions.dart';

/// The Links panel: the mod's forum, Discord and NexusMods pages, its full
/// changelog, source code, license, and donation links.
class LinksPanel extends StatelessWidget {
  final CatalogMod mod;

  const LinksPanel({super.key, required this.mod});

  /// A license this short is shown in full. A longer one opens in a pop-up.
  static const _shortLicenseLength = 40;

  /// True when the panel has anything to show.
  static bool hasContent(CatalogMod mod) =>
      mod.sourceCodeUrl != null ||
      mod.licenseText != null ||
      mod.supportLinks.isNotEmpty ||
      _pageLinks(mod).isNotEmpty;

  static List<_PageLink> _pageLinks(CatalogMod mod) {
    final urls = mod.entry.urls;
    // The forum index's address is the mod's own thread. The catalog's Forum
    // link sometimes points at a library the mod needs instead.
    final forumUrl = mod.topicUrl ?? urls?[ModUrlType.Forum];
    final discordUrl = urls?[ModUrlType.Discord];
    final nexusUrl = urls?[ModUrlType.NexusMods];
    final changelogUrl = mod.changelog?.link?.trim();
    return [
      if (forumUrl != null && forumUrl.isNotEmpty)
        _PageLink('Open forum page', Icons.public, forumUrl, forumUrl),
      if (discordUrl != null && discordUrl.isNotEmpty)
        _PageLink(
          'Open in Discord',
          Icons.discord,
          discordUrl,
          discordUrl
              .replaceAll('https://', 'discord://')
              .replaceAll('http://', 'discord://'),
        ),
      if (nexusUrl != null && nexusUrl.isNotEmpty)
        _PageLink('Open NexusMods page', Icons.extension, nexusUrl, nexusUrl),
      if (changelogUrl != null && changelogUrl.isNotEmpty)
        _PageLink(
          'Full changelog',
          Icons.format_list_bulleted,
          changelogUrl,
          changelogUrl,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sourceCodeUrl = mod.sourceCodeUrl;
    final license = mod.licenseText;
    final licenseUrl = mod.licenseUrl;

    final showLicenseAsText =
        license != null &&
        licenseUrl == null &&
        license.length <= _shortLicenseLength;

    final links = <Widget>[
      for (final link in _pageLinks(mod))
        SidePanelLink(
          icon: link.icon,
          label: link.label,
          tooltip: link.shownUrl,
          onTap: () => link.openUrl.openAsUriInBrowser(),
        ),
      if (sourceCodeUrl != null)
        SidePanelLink(
          icon: Icons.code,
          label: 'Source code on ${sourceCodeHostName(sourceCodeUrl)}',
          tooltip: sourceCodeUrl,
          onTap: () => sourceCodeUrl.openAsUriInBrowser(),
        ),
      if (license != null && licenseUrl != null)
        SidePanelLink(
          icon: Icons.balance,
          label: 'Read the license',
          tooltip: licenseUrl,
          onTap: () => licenseUrl.openAsUriInBrowser(),
        )
      else if (license != null && !showLicenseAsText)
        SidePanelLink(
          icon: Icons.balance,
          label: 'Read full license',
          tooltip: license.truncate(200),
          onTap: () =>
              showLicenseDialog(context, modTitle: mod.title, license: license),
        ),
      for (final link in mod.supportLinks)
        SidePanelLink(
          icon: DonationLinksSection.iconFor(link.type),
          label: 'Donate on ${link.type.toTitleCase()}',
          tooltip: link.url,
          onTap: () => link.url.openAsUriInBrowser(),
        ),
    ];

    return SidePanelSection(
      title: 'Links',
      children: [
        // One list, with no gap beyond each link's own padding.
        if (links.isNotEmpty)
          Column(crossAxisAlignment: .stretch, children: links),
        if (showLicenseAsText) SidePanelRow.text('License', license),
      ],
    );
  }
}

class _PageLink {
  final String label;
  final IconData icon;

  /// The address shown on hover.
  final String shownUrl;

  /// The address opened on click. Discord links open the Discord app.
  final String openUrl;

  const _PageLink(this.label, this.icon, this.shownUrl, this.openUrl);
}
